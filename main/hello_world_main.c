#include <math.h>
#include <inttypes.h>
#include <stdint.h>

#include "esp_attr.h"
#include "esp_clk.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"

#define TAG "cpu_benchmark"

/* Change this value to scale the test. Keep the batch size unchanged. */
#define BENCHMARK_ITERATIONS 1000000UL
#define YIELD_BATCH 10000UL
#define MEMORY_BUFFER_WORDS 4096UL
#define BENCHMARK_TASK_STACK 8192U
#define BENCHMARK_TASK_PRIORITY 1U
#define ROUND_DELAY_MS 2000U

#define CORE0_READY BIT0
#define CORE1_READY BIT1
#define BOTH_CORES_READY (CORE0_READY | CORE1_READY)

static EventGroupHandle_t s_start_barrier;
/* Separate buffers prevent the two cores from contending for one data set. */
static DRAM_ATTR uint32_t s_memory_buffers[2][MEMORY_BUFFER_WORDS];

static void benchmark_yield(uint32_t iteration)
{
    if (((iteration + 1U) % YIELD_BATCH) == 0U) {
        /*
         * A real delay, rather than only taskYIELD(), gives IDLE0/IDLE1 a
         * scheduling opportunity even while both benchmark tasks are ready.
         */
        vTaskDelay(1);
    }
}

static void log_result(uint32_t core, const char *test_name, uint64_t operations,
                       int64_t elapsed_us, double checksum)
{
    const double elapsed_seconds = (double)elapsed_us / 1000000.0;
    const double operations_per_second =
        (elapsed_us > 0) ? ((double)operations * 1000000.0 / (double)elapsed_us) : 0.0;

    ESP_LOGI(TAG,
             "core=%" PRIu32 " test=%s operations=%" PRIu64
             " time=%" PRId64 " us (%.6f s) ops/s=%.3f checksum=%.9g"
             " timing=includes_scheduler_yields",
             core, test_name, operations, elapsed_us, elapsed_seconds,
             operations_per_second, checksum);
}

static void run_integer_benchmark(uint32_t core)
{
    volatile uint32_t checksum = 0x13579BDFU;
    const int64_t start_us = esp_timer_get_time();

    for (uint32_t i = 0; i < BENCHMARK_ITERATIONS; ++i) {
        checksum = (checksum * 1664525U) + 1013904223U + i;
        checksum ^= (checksum >> 13);
        checksum += i * 3U;
        benchmark_yield(i);
    }

    log_result(core, "integer", (uint64_t)BENCHMARK_ITERATIONS * 4U,
               esp_timer_get_time() - start_us, (double)checksum);
}

static void run_float_benchmark(uint32_t core)
{
    volatile float checksum = 0.125F;
    const int64_t start_us = esp_timer_get_time();

    for (uint32_t i = 0; i < BENCHMARK_ITERATIONS; ++i) {
        const float value = (float)(i & 1023U) * 0.001F + 1.0F;
        checksum = checksum * 1.000001F + value;
        checksum = checksum - value * 0.000001F;
        checksum = checksum / 1.0000001F;
        benchmark_yield(i);
    }

    log_result(core, "floating-point", (uint64_t)BENCHMARK_ITERATIONS * 4U,
               esp_timer_get_time() - start_us, (double)checksum);
}

static void run_math_benchmark(uint32_t core)
{
    volatile float checksum = 0.25F;
    const int64_t start_us = esp_timer_get_time();

    for (uint32_t i = 0; i < BENCHMARK_ITERATIONS; ++i) {
        const float value = (float)(i & 4095U) * 0.001F + 0.001F;
        checksum += sinf(value) + cosf(value) + sqrtf(value);
        benchmark_yield(i);
    }

    log_result(core, "sinf-cosf-sqrtf", (uint64_t)BENCHMARK_ITERATIONS * 3U,
               esp_timer_get_time() - start_us, (double)checksum);
}

static void run_memory_benchmark(uint32_t core,
                                 volatile uint32_t *buffer)
{
    volatile uint32_t checksum = 0U;
    const int64_t start_us = esp_timer_get_time();

    for (uint32_t i = 0; i < BENCHMARK_ITERATIONS; ++i) {
        const uint32_t index = i % MEMORY_BUFFER_WORDS;
        const uint32_t value = buffer[index] + i + 0x9E3779B9U;
        buffer[index] = value;
        checksum ^= value;
        benchmark_yield(i);
    }

    log_result(core, "internal-RAM", (uint64_t)BENCHMARK_ITERATIONS * 3U,
               esp_timer_get_time() - start_us, (double)checksum);
}

static void benchmark_task(void *arg)
{
    const intptr_t core_arg = (intptr_t)arg;
    const uint32_t core = (uint32_t)core_arg;
    const EventBits_t ready_bit = (core == 0U) ? CORE0_READY : CORE1_READY;

    ESP_LOGI(TAG, "benchmark task started on core %" PRIu32, core);

    for (;;) {
        /*
         * Both tasks leave this barrier only after both cores are ready.
         * The barrier is reused at the start of every round.
         */
        (void)xEventGroupSync(s_start_barrier, ready_bit, BOTH_CORES_READY,
                              portMAX_DELAY);

        run_integer_benchmark(core);
        run_float_benchmark(core);
        run_math_benchmark(core);
        run_memory_benchmark(core, s_memory_buffers[core]);

        ESP_LOGI(TAG, "core %" PRIu32 " completed benchmark round", core);
        vTaskDelay(pdMS_TO_TICKS(ROUND_DELAY_MS));
    }
}

void app_main(void)
{
    const uint32_t cpu_frequency_mhz = esp_clk_cpu_freq() / 1000000U;
    TaskHandle_t core0_task = NULL;
    TaskHandle_t core1_task = NULL;

    ESP_LOGI(TAG, "ESP32 dual-core CPU benchmark starting");
    ESP_LOGI(TAG, "CPU frequency: %" PRIu32 " MHz", cpu_frequency_mhz);
    ESP_LOGI(TAG, "iterations=%lu, yield batch=%lu, round delay=%u ms",
             (unsigned long)BENCHMARK_ITERATIONS,
             (unsigned long)YIELD_BATCH, ROUND_DELAY_MS);

    s_start_barrier = xEventGroupCreate();
    if (s_start_barrier == NULL) {
        ESP_LOGE(TAG, "failed to create start barrier");
        return;
    }

    const BaseType_t core0_result = xTaskCreatePinnedToCore(
        benchmark_task, "benchmark_core0", BENCHMARK_TASK_STACK,
        (void *)(intptr_t)0, BENCHMARK_TASK_PRIORITY, &core0_task, 0);
    if (core0_result != pdPASS) {
        ESP_LOGE(TAG, "failed to create benchmark task on core 0");
        vEventGroupDelete(s_start_barrier);
        s_start_barrier = NULL;
        return;
    }

    const BaseType_t core1_result = xTaskCreatePinnedToCore(
        benchmark_task, "benchmark_core1", BENCHMARK_TASK_STACK,
        (void *)(intptr_t)1, BENCHMARK_TASK_PRIORITY, &core1_task, 1);
    if (core1_result != pdPASS) {
        ESP_LOGE(TAG, "failed to create benchmark task on core 1");
        vTaskDelete(core0_task);
        vEventGroupDelete(s_start_barrier);
        s_start_barrier = NULL;
        return;
    }

    ESP_LOGI(TAG, "benchmark tasks created on core 0 and core 1");
}
