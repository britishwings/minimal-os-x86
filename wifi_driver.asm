[BITS 32]
[ORG 0x1000]

; WiFi Driver Module for MinimalOS
; Simple WiFi interface initialization and packet handling

; WiFi Constants
WIFI_PORT_DATA equ 0x1000
WIFI_PORT_CMD equ 0x1001
WIFI_PORT_STATUS equ 0x1002
WIFI_PORT_CONFIG equ 0x1003

WIFI_CMD_INIT equ 0x01
WIFI_CMD_SCAN equ 0x02
WIFI_CMD_CONNECT equ 0x03
WIFI_CMD_DISCONNECT equ 0x04
WIFI_CMD_SEND equ 0x05
WIFI_CMD_RECV equ 0x06

WIFI_STATUS_READY equ 0x01
WIFI_STATUS_SCANNING equ 0x02
WIFI_STATUS_CONNECTING equ 0x03
WIFI_STATUS_CONNECTED equ 0x04
WIFI_STATUS_ERROR equ 0xFF

; WiFi State Variables
wifi_status db 0x00
wifi_signal_strength db 0x00
wifi_connected db 0x00
wifi_ssid_length db 0x00
wifi_ssid db "MinimalOS_Network", 0
wifi_passphrase db "DefaultPass123", 0

; Initialize WiFi Module
wifi_init:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send initialization command to WiFi hardware
    mov al, WIFI_CMD_INIT
    out WIFI_PORT_CMD, al
    
    ; Wait for response
    call wifi_wait_response
    
    ; Set initial status
    mov byte [wifi_status], WIFI_STATUS_READY
    mov byte [wifi_connected], 0x00
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Scan for available WiFi networks
wifi_scan_networks:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Update status
    mov byte [wifi_status], WIFI_STATUS_SCANNING
    
    ; Send scan command
    mov al, WIFI_CMD_SCAN
    out WIFI_PORT_CMD, al
    
    ; Wait for scan results
    mov ecx, 0x10000         ; Timeout counter
    
.scan_wait:
    in al, WIFI_PORT_STATUS
    cmp al, WIFI_STATUS_READY
    je .scan_complete
    
    loop .scan_wait
    
.scan_complete:
    ; Read number of networks found
    in al, WIFI_PORT_DATA
    mov ecx, eax             ; Number of networks
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Connect to WiFi network
; Input: ESI = SSID, EDI = Passphrase
wifi_connect:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Update status
    mov byte [wifi_status], WIFI_STATUS_CONNECTING
    
    ; Copy SSID to buffer
    mov ecx, 32
    mov edi, wifi_ssid
    
.copy_ssid:
    mov al, byte [esi]
    cmp al, 0
    je .ssid_done
    
    mov byte [edi], al
    inc esi
    inc edi
    loop .copy_ssid
    
.ssid_done:
    mov byte [edi], 0
    
    ; Send connect command with SSID
    mov al, WIFI_CMD_CONNECT
    out WIFI_PORT_CMD, al
    
    ; Send SSID length
    mov al, byte [edi]
    out WIFI_PORT_DATA, al
    
    ; Send SSID
    mov esi, wifi_ssid
    mov ecx, 32
    
.send_ssid:
    mov al, byte [esi]
    out WIFI_PORT_DATA, al
    inc esi
    loop .send_ssid
    
    ; Wait for connection
    mov ecx, 0x100000        ; Longer timeout for connection
    
.connect_wait:
    in al, WIFI_PORT_STATUS
    cmp al, WIFI_STATUS_CONNECTED
    je .connect_success
    
    cmp al, WIFI_STATUS_ERROR
    je .connect_error
    
    loop .connect_wait
    
.connect_error:
    mov byte [wifi_status], WIFI_STATUS_ERROR
    mov byte [wifi_connected], 0x00
    jmp .connect_done
    
.connect_success:
    mov byte [wifi_status], WIFI_STATUS_CONNECTED
    mov byte [wifi_connected], 0x01
    
.connect_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Disconnect from WiFi
wifi_disconnect:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send disconnect command
    mov al, WIFI_CMD_DISCONNECT
    out WIFI_PORT_CMD, al
    
    ; Wait for confirmation
    call wifi_wait_response
    
    ; Update status
    mov byte [wifi_status], WIFI_STATUS_READY
    mov byte [wifi_connected], 0x00
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Send data packet over WiFi
; Input: ESI = data buffer, ECX = data length
wifi_send_packet:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Check connection status
    cmp byte [wifi_connected], 0x01
    jne .send_error
    
    ; Send command
    mov al, WIFI_CMD_SEND
    out WIFI_PORT_CMD, al
    
    ; Send packet length
    mov al, cl
    out WIFI_PORT_DATA, al
    
    ; Send packet data
.send_loop:
    mov al, byte [esi]
    out WIFI_PORT_DATA, al
    inc esi
    loop .send_loop
    
    jmp .send_done
    
.send_error:
    mov eax, 0xFFFFFFFF      ; Error code
    
.send_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Receive data packet from WiFi
; Input: EDI = buffer to store data
; Output: ECX = bytes received
wifi_recv_packet:
    push eax
    push ebx
    push edx
    push esi
    push edi
    
    ; Check connection status
    cmp byte [wifi_connected], 0x01
    jne .recv_error
    
    ; Send receive command
    mov al, WIFI_CMD_RECV
    out WIFI_PORT_CMD, al
    
    ; Wait for data
    mov eax, 0x100000
    
.recv_wait:
    in al, WIFI_PORT_STATUS
    cmp al, 0x00             ; 0x00 = data available
    je .recv_data
    
    dec eax
    jnz .recv_wait
    
    ; Timeout - no data received
    mov ecx, 0
    jmp .recv_done
    
.recv_data:
    ; Read packet length
    in al, WIFI_PORT_DATA
    mov ecx, eax             ; Number of bytes
    
    ; Read packet data
    mov esi, edi
    
.recv_loop:
    in al, WIFI_PORT_DATA
    mov byte [edi], al
    inc edi
    loop .recv_loop
    
    jmp .recv_done
    
.recv_error:
    mov ecx, 0               ; 0 bytes received
    
.recv_done:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret

; Get WiFi signal strength
; Output: AL = signal strength (0-100)
wifi_get_signal_strength:
    push ebx
    push ecx
    push edx
    
    ; Read from hardware
    mov al, 0x07             ; Signal strength command
    out WIFI_PORT_CMD, al
    
    ; Read response
    in al, WIFI_PORT_DATA
    mov byte [wifi_signal_strength], al
    
    pop edx
    pop ecx
    pop ebx
    ret

; Get WiFi connection status
; Output: AL = status byte
wifi_get_status:
    push ebx
    push ecx
    push edx
    
    in al, WIFI_PORT_STATUS
    mov byte [wifi_status], al
    
    pop edx
    pop ecx
    pop ebx
    ret

; Wait for WiFi response
wifi_wait_response:
    push eax
    push ecx
    
    mov ecx, 0x10000         ; Timeout
    
.wait_loop:
    in al, WIFI_PORT_STATUS
    cmp al, 0x00             ; Check if ready
    je .wait_done
    
    loop .wait_loop
    
.wait_done:
    pop ecx
    pop eax
    ret

; Get WiFi module info
; Output: ESI = info string
wifi_get_info:
    push eax
    
    cmp byte [wifi_connected], 0x01
    jne .info_disconnected
    
    mov esi, wifi_connected_msg
    jmp .info_done
    
.info_disconnected:
    mov esi, wifi_disconnected_msg
    
.info_done:
    pop eax
    ret

; WiFi Info Messages
wifi_connected_msg db "WiFi: Connected (Signal: ", 0
wifi_disconnected_msg db "WiFi: Disconnected", 0
wifi_error_msg db "WiFi: Error - Check Hardware", 0

; WiFi Buffer for network data
wifi_rx_buffer:
    times 1024 db 0

wifi_tx_buffer:
    times 1024 db 0

; WiFi Network List (for scan results)
wifi_networks:
    times 10 * 32 db 0       ; 10 networks, 32 bytes each
