# Minimal OS - Lightweight x86 Assembly Operating System

A lightweight, minimal operating system written entirely in x86-32 assembly language. Designed for educational purposes and virtualization testing on Linux systems.

## Features

- **Pure x86 Assembly**: Written entirely in NASM assembly (no C/C++)
- **Lightweight**: Minimal bootloader + simple kernel (~6KB total)
- **Protected Mode**: Transitions from real mode to 32-bit protected mode
- **VGA Text Output**: Basic screen output capabilities
- **QEMU Compatible**: Runs on QEMU/KVM virtualization
- **Linux-Native**: Build and run on Linux systems

## Project Structure

```
minimal-os-x86/
├── bootloader.asm    # 512-byte BIOS bootloader
├── kernel.asm        # Minimal kernel in protected mode
├── Makefile          # Build automation
└── README.md         # This file
```

## Prerequisites

Install required tools on Linux:

```bash
# Ubuntu/Debian
sudo apt-get install nasm qemu-system-x86 build-essential

# Fedora/RHEL
sudo dnf install nasm qemu-system-x86 gcc

# Arch Linux
sudo pacman -S nasm qemu-system-x86
```

## Building

Clone and build:

```bash
git clone https://github.com/britishwings/minimal-os-x86.git
cd minimal-os-x86
make all
```

This creates:
- `bootloader.bin` - Compiled bootloader
- `kernel.bin` - Compiled kernel
- `minimal_os.img` - Complete disk image (10MB)

## Running

### Quick Start with QEMU

```bash
make run
```

This launches the OS in QEMU with 256MB RAM.

### Debugging with GDB

```bash
# Terminal 1: Start QEMU with debugging
make debug

# Terminal 2: Connect GDB
gdb
(gdb) target remote :1234
(gdb) break kernel_start
(gdb) continue
```

### Custom QEMU Options

```bash
# With more memory
qemu-system-i386 -drive format=raw,file=minimal_os.img -m 512M

# With KVM acceleration (Linux)
qemu-system-i386 -drive format=raw,file=minimal_os.img -m 256M -enable-kvm

# With network enabled
qemu-system-i386 -drive format=raw,file=minimal_os.img -m 256M -net user -net nic

# Display and monitor
qemu-system-i386 -drive format=raw,file=minimal_os.img -m 256M -monitor stdio
```

## Architecture

### Boot Process

1. **BIOS loads bootloader** at memory address 0x7C00
2. **Real mode execution**:
   - Initializes registers and stack
   - Prints welcome message
   - Loads kernel from disk sector 2
   - Builds GDT (Global Descriptor Table)

3. **Protected mode transition**:
   - Enables CPU protection
   - Sets up segment descriptors
   - Jumps to kernel at 0x1000

4. **Kernel execution**:
   - Sets up kernel stack
   - Clears VGA text screen
   - Displays kernel message
   - Infinite loop (halt)

### Memory Layout

```
0x00000000 - 0x000003FF  | IVT (Interrupt Vector Table)
0x00000400 - 0x000004FF  | BDA (BIOS Data Area)
0x00007C00 - 0x00007DFF  | Bootloader (loaded by BIOS)
0x00001000 - 0x00002000  | Kernel
0x00090000              | Kernel stack
0xB8000                 | VGA text buffer
```

### Protected Mode Features

- **32-bit addressing**: Access full 4GB memory space
- **GDT**: Global Descriptor Table with code/data segments
- **Flat memory model**: No segmentation overhead

## Code Overview

### bootloader.asm

```nasm
; Key sections:
- Video mode setup (80x25 text)
- Disk read operations (INT 0x13)
- String printing to screen (INT 0x10)
- GDT setup for protected mode
- Transition to protected mode
```

### kernel.asm

```nasm
; Key sections:
- Stack initialization
- Screen clearing (VGA memory)
- Kernel message display
- GDT reloading in protected mode
- Infinite loop (HLT alternative)
```

## Customization

### Add More Boot Messages

Edit `bootloader.asm`:
```nasm
my_message db "Your text here", 0x0D, 0x0A, 0
```

### Change Memory Addresses

- Modify `[ORG 0x...]` directives
- Update stack pointers in code

### Extend Kernel Functions

Add new functions to `kernel.asm` and call from `kernel_start`

## Troubleshooting

### QEMU won't start
```bash
# Check if qemu is installed
which qemu-system-i386

# Try with explicit path
/usr/bin/qemu-system-i386 -drive format=raw,file=minimal_os.img
```

### Bootloader not found
```bash
# Rebuild everything
make clean
make all

# Check file sizes
ls -la *.bin
# bootloader.bin should be 512 bytes
# kernel.bin should be 4096 bytes
```

### Screen output issues
- Ensure VGA memory at 0xB8000 is accessible
- Check kernel stack doesn't overflow (set to 0x90000)

## Learning Resources

- [Intel x86 Reference](https://en.wikibooks.org/wiki/X86_Assembly)
- [NASM Assembly](https://www.nasm.us/)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [OSDev.org](https://wiki.osdev.org/)

## Performance Notes

- **Boot time**: ~1-2 seconds on modern hardware
- **Memory usage**: ~10MB disk image, 256MB RAM in QEMU
- **CPU**: Minimal - mostly in infinite loop

## Safety & Security

This is educational software:
- No isolation guarantees
- No security hardening
- For testing/learning only
- Run in isolated virtual machines

## License

This project is provided as-is for educational purposes.

## Future Enhancements

- [ ] Interrupt handlers (IDT setup)
- [ ] Memory management (paging)
- [ ] Simple shell/commands
- [ ] File system support
- [ ] Multi-tasking support
- [ ] Keyboard input handling

## Support

For issues or questions:
1. Check the OSDev wiki
2. Review NASM documentation
3. Test with different QEMU versions

---

**Happy Kernel Hacking!** 🐧
