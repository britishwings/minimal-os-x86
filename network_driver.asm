[BITS 32]
[ORG 0x1000]

; Network Driver Module for MinimalOS
; Simple network interface initialization and packet handling
; Enables communication between QEMU guest and host machine

; Network Constants
NET_PORT_DATA equ 0x2000
NET_PORT_CMD equ 0x2001
NET_PORT_STATUS equ 0x2002
NET_PORT_CONFIG equ 0x2003

NET_CMD_INIT equ 0x01
NET_CMD_SET_IP equ 0x02
NET_CMD_GET_IP equ 0x03
NET_CMD_SEND equ 0x04
NET_CMD_RECV equ 0x05
NET_CMD_DHCP equ 0x06

NET_STATUS_READY equ 0x01
NET_STATUS_BUSY equ 0x02
NET_STATUS_ERROR equ 0xFF

; Network State Variables
net_status db 0x00
net_connected db 0x00
net_ip_addr db 192, 168, 1, 100    ; Default IP: 192.168.1.100
net_gateway db 192, 168, 1, 1      ; Gateway: 192.168.1.1
net_dns db 8, 8, 8, 8              ; DNS: 8.8.8.8
net_mac_addr db 0x52, 0x54, 0x00, 0x12, 0x34, 0x56  ; QEMU default MAC

; Network RX/TX Buffers
net_rx_buffer:
    times 2048 db 0

net_tx_buffer:
    times 2048 db 0

; Initialize Network Interface
net_init:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send initialization command
    mov al, NET_CMD_INIT
    out NET_PORT_CMD, al
    
    ; Wait for response
    call net_wait_response
    
    ; Set initial status
    mov byte [net_status], NET_STATUS_READY
    mov byte [net_connected], 0x00
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Enable DHCP to get IP from QEMU host
net_enable_dhcp:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send DHCP command
    mov al, NET_CMD_DHCP
    out NET_PORT_CMD, al
    
    ; Wait for DHCP response
    mov ecx, 0x100000
    
.dhcp_wait:
    in al, NET_PORT_STATUS
    cmp al, NET_STATUS_READY
    je .dhcp_success
    
    loop .dhcp_wait
    
.dhcp_success:
    ; Read assigned IP address
    in al, NET_PORT_DATA
    mov byte [net_ip_addr], al
    in al, NET_PORT_DATA
    mov byte [net_ip_addr + 1], al
    in al, NET_PORT_DATA
    mov byte [net_ip_addr + 2], al
    in al, NET_PORT_DATA
    mov byte [net_ip_addr + 3], al
    
    mov byte [net_connected], 0x01
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Set static IP address
; Input: AL = IP byte 1, BL = IP byte 2, CL = IP byte 3, DL = IP byte 4
net_set_static_ip:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send set IP command
    mov al, NET_CMD_SET_IP
    out NET_PORT_CMD, al
    
    ; Send IP address bytes
    out NET_PORT_DATA, al     ; Byte 1
    mov al, bl
    out NET_PORT_DATA, al     ; Byte 2
    mov al, cl
    out NET_PORT_DATA, al     ; Byte 3
    mov al, dl
    out NET_PORT_DATA, al     ; Byte 4
    
    ; Wait for confirmation
    call net_wait_response
    
    mov byte [net_connected], 0x01
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Get current IP address
; Output: EAX = IP address (format: 192.168.1.100)
net_get_ip:
    push ebx
    push ecx
    push edx
    
    mov al, NET_CMD_GET_IP
    out NET_PORT_CMD, al
    
    ; Read IP address bytes
    in al, NET_PORT_DATA
    mov bl, al                ; Save byte 1
    
    in al, NET_PORT_DATA
    mov cl, al                ; Save byte 2
    
    in al, NET_PORT_DATA
    mov dl, al                ; Save byte 3
    
    in al, NET_PORT_DATA
    ; AL contains byte 4
    
    ; Construct IP in EAX format (192.168.1.100 = 0xC0A80164)
    mov eax, ebx
    shl eax, 8
    add al, cl
    shl eax, 8
    add al, dl
    shl eax, 8
    
    pop edx
    pop ecx
    pop ebx
    ret

; Send network packet
; Input: ESI = packet data, ECX = packet length
net_send_packet:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Check connection status
    cmp byte [net_connected], 0x01
    jne .send_error
    
    ; Send command
    mov al, NET_CMD_SEND
    out NET_PORT_CMD, al
    
    ; Send packet length (2 bytes)
    mov al, ch
    out NET_PORT_DATA, al
    mov al, cl
    out NET_PORT_DATA, al
    
    ; Send packet data
.send_loop:
    mov al, byte [esi]
    out NET_PORT_DATA, al
    inc esi
    loop .send_loop
    
    ; Wait for confirmation
    call net_wait_response
    
    jmp .send_done
    
.send_error:
    mov eax, 0xFFFFFFFF
    
.send_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Receive network packet
; Input: EDI = buffer to store packet
; Output: ECX = bytes received
net_recv_packet:
    push eax
    push ebx
    push edx
    push esi
    push edi
    
    ; Check connection status
    cmp byte [net_connected], 0x01
    jne .recv_error
    
    ; Send receive command
    mov al, NET_CMD_RECV
    out NET_PORT_CMD, al
    
    ; Wait for data with timeout
    mov eax, 0x100000
    
.recv_wait:
    in al, NET_PORT_STATUS
    cmp al, NET_STATUS_READY
    je .recv_data
    
    dec eax
    jnz .recv_wait
    
    ; Timeout - no data
    mov ecx, 0
    jmp .recv_done
    
.recv_data:
    ; Read packet length
    in al, NET_PORT_DATA
    mov ch, al
    in al, NET_PORT_DATA
    mov cl, al
    
    ; Read packet data
    mov esi, edi
    
.recv_loop:
    in al, NET_PORT_DATA
    mov byte [edi], al
    inc edi
    cmp ecx, 0
    je .recv_done
    
    dec ecx
    jmp .recv_loop
    
.recv_error:
    mov ecx, 0
    
.recv_done:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret

; Get network status
; Output: AL = status byte
net_get_status:
    push ebx
    push ecx
    push edx
    
    in al, NET_PORT_STATUS
    mov byte [net_status], al
    
    pop edx
    pop ecx
    pop ebx
    ret

; Wait for network response
net_wait_response:
    push eax
    push ecx
    
    mov ecx, 0x10000
    
.wait_loop:
    in al, NET_PORT_STATUS
    cmp al, NET_STATUS_READY
    je .wait_done
    
    loop .wait_loop
    
.wait_done:
    pop ecx
    pop eax
    ret

; Get MAC address
; Output: ESI = 6-byte MAC address
net_get_mac:
    push eax
    
    mov esi, net_mac_addr
    
    pop eax
    ret

; Enable network interface
net_enable:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Initialize network
    call net_init
    
    ; Enable DHCP for automatic IP assignment
    call net_enable_dhcp
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Disable network interface
net_disable:
    push eax
    push ebx
    push ecx
    push edx
    
    mov byte [net_connected], 0x00
    mov byte [net_status], 0x00
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Get network info string
; Output: ESI = info string
net_get_info:
    push eax
    
    cmp byte [net_connected], 0x01
    jne .info_disconnected
    
    mov esi, net_connected_msg
    jmp .info_done
    
.info_disconnected:
    mov esi, net_disconnected_msg
    
.info_done:
    pop eax
    ret

; Network Info Messages
net_connected_msg db "Network: Connected | IP: ", 0
net_disconnected_msg db "Network: Disconnected", 0
net_error_msg db "Network: Error - Check Hardware", 0

; HTTP Server Port Configuration (for hosting local page)
HTTP_PORT equ 80
HTTP_LISTEN_PORT equ 8080        ; Alternative port to avoid conflicts

; Simple HTTP Server Variables
http_server_enabled db 0x00
http_connections db 0x00
