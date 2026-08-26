# Minimal OS - Quick Start Guide

## Installation (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install nasm qemu-system-x86 build-essential
```

## Build & Run

```bash
# Clone repository
git clone https://github.com/britishwings/minimal-os-x86.git
cd minimal-os-x86

# Build
make all

# Run in QEMU
make run
```

## What You'll See

When running:
1. QEMU window opens with black screen
2. Bootloader prints: "Minimal OS Bootloader"
3. Bootloader prints: "Loading kernel..."
4. Bootloader prints: "Ready to boot kernel"
5. Green kernel message appears: "=== Minimal OS Kernel ==="
6. System loops infinitely (waiting for next step)

## Key Files

| File | Purpose |
|------|---------|
| `bootloader.asm` | BIOS bootloader (512 bytes) |
| `kernel.asm` | Protected mode kernel |
| `Makefile` | Build automation |
| `minimal_os.img` | Disk image (created after build) |

## Commands

```bash
make all      # Build OS image
make run      # Run in QEMU
make debug    # Run with GDB debugging
make clean    # Remove build files
make help     # Show available commands
```

## Architecture Overview

```
Real Mode (Bootloader)
  ↓
Load Kernel from Disk
  ↓
Setup GDT (Global Descriptor Table)
  ↓
Enable Protected Mode
  ↓
Protected Mode (Kernel)
  ↓
Display Messages + Loop
```

## Memory Map

```
0x7C00 - Bootloader (512 bytes)
0x1000 - Kernel (4KB)
0x90000 - Kernel Stack
0xB8000 - VGA Text Buffer
```

## Exiting QEMU

- Press `Ctrl+Alt+Q` 
- Or close the QEMU window
- Or in QEMU monitor: `quit`

## Next Steps

1. **Modify kernel messages**: Edit `kernel.asm` strings
2. **Add interrupt handlers**: Implement IDT (Interrupt Descriptor Table)
3. **Add keyboard input**: Handle INT 0x09
4. **Implement memory paging**: Virtual memory management
5. **Build file system**: Disk I/O operations

## Common Issues

### Make: command not found
```bash
sudo apt-get install build-essential
```

### NASM: command not found
```bash
sudo apt-get install nasm
```

### QEMU won't run
```bash
# Check installation
which qemu-system-i386

# Install if missing
sudo apt-get install qemu-system-x86
```

### Bootloader not loading
```bash
make clean
make all
# Ensure bootloader.bin is exactly 512 bytes
ls -l bootloader.bin
```

## Testing in Virtual Machines

### VirtualBox
```bash
# Convert image to VDI format
VBoxManage convertfromraw minimal_os.img minimal_os.vdi --format VDI

# Create VM and attach VDI
```

### KVM/Libvirt
```bash
# Copy image to libvirt directory
sudo cp minimal_os.img /var/lib/libvirt/images/

# Create VM with virt-manager GUI
virt-manager
```

## Resource Usage

- **Disk**: 10 MB (configurable in Makefile)
- **RAM**: 256 MB (in QEMU, configurable)
- **CPU**: Minimal (mostly idle loop)
- **Boot Time**: 1-2 seconds

## Educational Value

Learn:
- x86 assembly fundamentals
- Bootloader mechanics
- Real mode → Protected mode transition
- GDT and segmentation
- VGA text output
- BIOS interrupts
- Disk I/O operations

---

For detailed documentation, see `README.md`
