.PHONY: all clean run debug

# Compiler and tools
ASM = nasm
LD = ld
QEMU = qemu-system-i386

# Flags
ASM_FLAGS = -f bin
LD_FLAGS = -Ttext 0x0 --oformat binary

# Files
BOOTLOADER = bootloader.asm
KERNEL = kernel.asm
BOOT_BIN = bootloader.bin
KERNEL_BIN = kernel.bin
OS_IMAGE = minimal_os.img

# Build targets
all: $(OS_IMAGE)

$(BOOT_BIN): $(BOOTLOADER)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(KERNEL_BIN): $(KERNEL)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	# Create a 10MB disk image
	dd if=/dev/zero of=$@ bs=1M count=10
	# Write bootloader to first sector
	dd if=$(BOOT_BIN) of=$@ bs=512 count=1 conv=notrunc
	# Write kernel starting at sector 2
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc

# Run in QEMU
run: $(OS_IMAGE)
	$(QEMU) -drive format=raw,file=$(OS_IMAGE) -m 256M

# Run with debugging support
debug: $(OS_IMAGE)
	$(QEMU) -drive format=raw,file=$(OS_IMAGE) -m 256M -s -S

# Clean build artifacts
clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(OS_IMAGE)

# Help
help:
	@echo "Minimal OS x86 Assembly Build System"
	@echo "===================================="
	@echo "make all   - Build the OS image"
	@echo "make run   - Run OS in QEMU"
	@echo "make debug - Run OS in QEMU with GDB debugging"
	@echo "make clean - Remove build artifacts"
	@echo "make help  - Show this message"
