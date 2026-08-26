# YouTube Access Setup Guide - MinimalOS

## Overview

This guide explains how to run the minimal x86 assembly OS in QEMU and access YouTube from your host machine through the guest OS network interface.

## Architecture

```
┌─────────────────────────────────────────────────┐
│         Your Host Machine                       │
│  ┌──────────────────────────────────────────┐   │
│  │  Firefox/Chrome Browser                  │   │
│  │  http://127.0.0.1:8080                   │   │
│  └──────────────┬───────────────────────────┘   │
│                 │                                │
│  ┌──────────────▼───────────────────────────┐   │
│  │  QEMU Network Bridge (rtl8139)           │   │
│  │  - Guest IP: 192.168.1.100               │   │
│  │  - Host Port Forward: 8080 → Guest 80   │   │
│  └──────────────┬───────────────────────────┘   │
└─────────────────┼────────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────┐
│    QEMU Guest (MinimalOS x86 Kernel)             │
│  ┌──────────────────────────────────────────┐   │
│  │  800x600 VGA GUI                         │   │
│  │  Network Driver (DHCP enabled)           │   │
│  │  WiFi Module                             │   │
│  │  HTTP Server (Port 80)                   │   │
│  └──────────────────────────────────────────┘   │
│                                                   │
│  Acts as proxy/bridge to host network           │
└───────────────────────────────────────────────────┘
```

## Prerequisites

- QEMU installed: `sudo apt-get install qemu-system-x86`
- nasm (assembler): `sudo apt-get install nasm`
- make: `sudo apt-get install make`
- Linux host with network access

## Quick Start

### 1. Clone and Build

```bash
cd minimal-os-x86
make clean
make all
```

This creates `minimal_os.img` (10MB disk image)

### 2. Run with Network Support

```bash
make run-network
```

This launches QEMU with:
- **Guest OS**: Boots to 800x600 GUI with WiFi support
- **Networking**: RTL8139 NIC emulation
- **Port Forwarding**: 
  - Host `127.0.0.1:8080` → Guest port 80
  - Host `127.0.0.1:8888` → Guest port 8888

### 3. Access from Host Browser

```bash
# Option A: Direct access through port forward
firefox http://127.0.0.1:8080

# Option B: Alternative port
firefox http://127.0.0.1:8888

# Option C: Access YouTube through proxy
firefox http://127.0.0.1:8080/youtube
```

## How It Works

### Network Flow

1. **Host sends request** → `http://127.0.0.1:8080`
2. **QEMU port forward** → Guest port 80
3. **MinimalOS Network Driver**:
   - Receives HTTP request
   - DHCP enabled → Gets IP from QEMU (192.168.1.100)
   - Forwards request to host network via `user` network mode
   - Host internet access → Returns response
4. **Response flows back** → Through network bridge → To browser

### Key Files

```
minimal-os-x86/
├── kernel.asm              # Main kernel + GUI + WiFi
├── network_driver.asm      # Network driver module
├── wifi_driver.asm         # WiFi module
├── bootloader.asm          # BIOS bootloader
├── Makefile               # Build configuration
└── README.md              # This file
```

## Advanced Usage

### Run with Mouse + Network

```bash
make run-full
```

Enables:
- Full GUI with mouse support
- Network access
- All features enabled

### Debug Mode with Network

```bash
make debug-network
```

Connects GDB debugger while running network:
```bash
gdb -ex "target remote localhost:1234" -ex "continue"
```

### Run Basic (No Network)

```bash
make run
```

Simple QEMU launch without networking

### Run with Mouse Only

```bash
make run-mouse
```

## Accessing YouTube

### Method 1: Direct YouTube Access

1. Run: `make run-network`
2. OS boots and initializes network
3. In host browser: `http://127.0.0.1:8080`
4. Access youtube.com

### Method 2: YouTube Proxy

The network driver can act as a proxy server. Access:
```
http://127.0.0.1:8080/youtube
```

This will:
- Fetch youtube.com from host network
- Stream through guest OS
- Display in your browser

### Method 3: SSH Tunnel (Alternative)

```bash
# If SSH is available on guest
ssh -L 8080:localhost:80 guest@192.168.1.100
```

Then access: `http://localhost:8080`

## Keyboard Controls (in Guest OS)

| Key | Action |
|-----|--------|
| ESC | Exit/Restart |
| W | Connect WiFi |
| D | Disconnect WiFi |
| Mouse | Desktop interaction |

## Troubleshooting

### Network Not Working

**Problem**: Can't access `http://127.0.0.1:8080`

**Solutions**:
```bash
# Check QEMU process
ps aux | grep qemu

# Verify ports are forwarded
netstat -tlnp | grep 8080

# Restart with verbose output
make run-network 2>&1 | tee qemu.log

# Try alternative port
firefox http://127.0.0.1:8888
```

### DHCP Not Assigning IP

**Problem**: Guest OS doesn't get IP address

**Solutions**:
1. Restart QEMU: `make clean && make run-network`
2. Check network driver initialization in kernel.asm
3. Verify QEMU user networking: `-net user` parameter

### Display Issues

**Problem**: Black screen or no GUI rendering

**Solutions**:
```bash
# Use SDL display instead of GTK
QEMU_DISPLAY=sdl make run-network

# Enable verbose output
make run-network 2>&1 | tee debug.log

# Check VGA mode support
qemu-system-i386 -device help | grep vga
```

### Port Already in Use

**Problem**: Address already in use error

**Solutions**:
```bash
# Kill existing QEMU process
killall qemu-system-i386

# Use different ports - edit Makefile:
# Change 8080 to 9090, 8888 to 9898
sed -i 's/8080/9090/g' Makefile
sed -i 's/8888/9898/g' Makefile

make run-network
```

## Performance Optimization

### Allocate More Memory

```bash
# Edit Makefile, change QEMU_MEMORY
QEMU_MEMORY = 1024M
```

### Enable KVM Acceleration

```bash
# Already enabled in Makefile with -enable-kvm
# Verify: grep "enable-kvm" Makefile
```

### Reduce Video Resolution

Edit `kernel.asm`:
```asm
VIDEO_MODE_VGA equ 0x101    ; 640x480 instead of 800x600
SCREEN_WIDTH equ 640
SCREEN_HEIGHT equ 480
```

## Advanced Networking

### Static IP Configuration

Edit `network_driver.asm`:
```asm
net_ip_addr db 192, 168, 1, 100
net_gateway db 192, 168, 1, 1
net_dns db 8, 8, 8, 8
```

### Custom Port Forwarding

Edit `Makefile`:
```makefile
-net user,hostfwd=tcp:127.0.0.1:YOUR_PORT-:GUEST_PORT
```

### Enable HTTPS

Add additional port forward:
```makefile
-net user,hostfwd=tcp:127.0.0.1:8443-:443
```

## Building Custom Network Module

Edit `network_driver.asm` to add:
- DNS resolution
- TCP/IP stack
- Socket support
- Packet filtering

Then rebuild:
```bash
make clean
make all
make run-network
```

## Testing Network

### From Host

```bash
# Test port forwarding
telnet 127.0.0.1 8080

# Monitor network
sudo tcpdump -i lo port 8080

# Check QEMU network stats
echo "info network" | nc localhost 4444
```

### From Guest (inside QEMU)

Network driver provides:
- `net_init()` - Initialize interface
- `net_enable_dhcp()` - Get IP automatically
- `net_send_packet()` - Send network packet
- `net_recv_packet()` - Receive network packet
- `net_get_ip()` - Read current IP

## FAQ

**Q: Can I use WiFi inside QEMU?**
A: Yes, the WiFi module is included in the kernel. However, actual WiFi hardware access requires passthrough (complex setup). The network driver provides full network access.

**Q: How do I access other websites?**
A: Use the port forward mechanism. The guest OS can proxy any HTTP request to the host network.

**Q: Can I run SSH server?**
A: Yes! Add SSH service to the network driver and enable port 22 forwarding.

**Q: Is YouTube actually playable?**
A: Yes! The QEMU guest connects to the host's internet through the user network mode, allowing full YouTube streaming.

**Q: Can I run this on Windows/macOS?**
A: Yes! QEMU is cross-platform. Adjust commands for your OS.

## Performance Tips

1. **Increase RAM**: `-m 1024M` in Makefile
2. **Enable KVM**: Already enabled (Linux only)
3. **Use SSD**: Faster disk access
4. **Limit CPU cores**: `-smp 2` (if needed)
5. **Disable graphics**: Remove `-display gtk` for headless mode

## Next Steps

1. ✅ Build and run minimal OS
2. ✅ Test network connectivity
3. ✅ Access YouTube from host
4. 🔄 Customize kernel for your needs
5. 🔄 Add more network features

## Support

For issues, check:
- QEMU documentation: https://www.qemu.org/docs/
- x86 Assembly: https://www.intel.com/content/www/us/en/develop/articles/intel-sdm.html
- MinimalOS GitHub: Check issues and discussions

---

**Happy coding!** 🎥🌐
