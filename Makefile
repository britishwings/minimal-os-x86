.PHONY: all clean run debug run-network help

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

# QEMU Configuration
QEMU_MEMORY = 512M
QEMU_CPU = qemu32
QEMU_MACHINE = pc

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

# Run in QEMU (basic)
run: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-machine $(QEMU_MACHINE) \
		-display gtk \
		-enable-kvm

# Run in QEMU with networking enabled (for YouTube access from host)
run-network: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-machine $(QEMU_MACHINE) \
		-display gtk \
		-enable-kvm \
		-net nic,model=rtl8139 \
		-net user,hostfwd=tcp:127.0.0.1:8080-:80,hostfwd=tcp:127.0.0.1:8888-:8888

# Run with debugging support
debug: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-s -S \
		-display gtk

# Run with network and debugging
debug-network: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-net nic,model=rtl8139 \
		-net user,hostfwd=tcp:127.0.0.1:8080-:80,hostfwd=tcp:127.0.0.1:8888-:8888 \
		-s -S \
		-display gtk

# Run with mouse support
run-mouse: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-machine $(QEMU_MACHINE) \
		-display gtk \
		-enable-kvm \
		-mouse

# Run with network and mouse
run-full: $(OS_IMAGE)
	$(QEMU) \
		-drive format=raw,file=$(OS_IMAGE) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-machine $(QEMU_MACHINE) \
		-display gtk \
		-enable-kvm \
		-mouse \
		-net nic,model=rtl8139 \
		-net user,hostfwd=tcp:127.0.0.1:8080-:80,hostfwd=tcp:127.0.0.1:8888-:8888

# Clean build artifacts
clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(OS_IMAGE)

# Help
help:
	@echo "Minimal OS x86 Assembly Build System"
	@echo "====================================="
	@echo ""
	@echo "BUILD TARGETS:"
	@echo "  make all              - Build the OS image"
	@echo ""
	@echo "RUN TARGETS:"
	@echo "  make run              - Run OS in QEMU (basic, no network)"
	@echo "  make run-network      - Run OS with networking enabled"
	@echo "  make run-mouse        - Run OS with mouse support"
	@echo "  make run-full         - Run OS with network + mouse + GUI"
	@echo ""
	@echo "DEBUGGING TARGETS:"
	@echo "  make debug            - Run OS in QEMU with GDB support"
	@echo "  make debug-network    - Run with network + GDB support"
	@echo ""
	@echo "CLEANUP:"
	@echo "  make clean            - Remove build artifacts"
	@echo "  make help             - Show this message"
	@echo ""
	@echo "NETWORKING SETUP:"
	@echo "  When running with -network flag, use these from host:"
	@echo "  - HTTP Server:  http://127.0.0.1:8080"
	@echo "  - Alt Port:     http://127.0.0.1:8888"
	@echo ""
	@echo "ACCESSING YOUTUBE FROM HOST:"
	@echo "  1. Run: make run-network"
	@echo "  2. Open browser on host: http://127.0.0.1:8080"
	@echo "  3. OS will proxy requests from QEMU to host network"
	@echo "  4. Access youtube.com through the bridge"
