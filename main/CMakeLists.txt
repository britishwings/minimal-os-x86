idf_component_register(
    SRCS "hello_world_main.c"
    INCLUDE_DIRS "."
    PRIV_REQUIRES esp_common esp_hw_support esp_timer freertos log
)
