[BITS 32]                    ; Protected mode (32-bit)
[ORG 0x1000]                 ; Kernel loaded at 0x1000

; Lightweight GUI OS with VGA Graphics (800x600) + WiFi Support
kernel_start:
    mov esp, 0x90000         ; Set up kernel stack
    call setup_gdt
    call enable_graphics_mode
    call init_mouse
    call init_keyboard
    call wifi_init            ; Initialize WiFi module
    call draw_desktop
    call main_loop
    jmp $

; Constants
VIDEO_MODE_VGA equ 0x103    ; 800x600x256 VESA mode
SCREEN_WIDTH equ 800
SCREEN_HEIGHT equ 600
BYTES_PER_PIXEL equ 1
SCREEN_MEMORY equ 0xA0000

; WiFi Port Constants
WIFI_PORT_DATA equ 0x1000
WIFI_PORT_CMD equ 0x1001
WIFI_PORT_STATUS equ 0x1002

; WiFi Status Constants
WIFI_STATUS_READY equ 0x01
WIFI_STATUS_CONNECTING equ 0x03
WIFI_STATUS_CONNECTED equ 0x04

; WiFi State Variables
wifi_status db 0x00
wifi_connected db 0x00
wifi_ssid db "MinimalOS_Network", 0
wifi_signal_strength db 0x00

; Setup GDT
setup_gdt:
    push eax
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    pop eax
    ret

; Enable VGA Graphics Mode (800x600x256)
enable_graphics_mode:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Set VGA mode to 800x600x256 using INT 0x10
    mov ax, 0x4F02           ; VESA set mode
    mov bx, 0x103            ; 800x600x256
    int 0x10
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Initialize mouse (PS/2)
init_mouse:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Enable auxiliary device (mouse)
    mov al, 0xA8
    out 0x64, al
    call wait_kbd
    
    ; Set defaults
    mov al, 0xF6
    out 0x60, al
    call wait_kbd
    
    ; Enable data reporting
    mov al, 0xF4
    out 0x60, al
    call wait_kbd
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Initialize keyboard
init_keyboard:
    push eax
    
    ; Keyboard already initialized by BIOS
    ; Just enable interrupt handling here
    
    pop eax
    ret

; Wait for keyboard controller
wait_kbd:
    push eax
    
.wait_loop:
    in al, 0x64
    test al, 0x02
    jnz .wait_loop
    
    pop eax
    ret

; Initialize WiFi Module
wifi_init:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Send initialization command to WiFi hardware
    mov al, 0x01             ; WIFI_CMD_INIT
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

; WiFi: Connect to network
wifi_connect_to_network:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Update status
    mov byte [wifi_status], WIFI_STATUS_CONNECTING
    
    ; Send connect command
    mov al, 0x03             ; WIFI_CMD_CONNECT
    out WIFI_PORT_CMD, al
    
    ; Send SSID
    mov al, 18               ; SSID length
    out WIFI_PORT_DATA, al
    
    mov esi, wifi_ssid
    mov ecx, 18
    
.send_ssid:
    mov al, byte [esi]
    out WIFI_PORT_DATA, al
    inc esi
    loop .send_ssid
    
    ; Wait for connection
    mov ecx, 0x100000
    
.connect_wait:
    in al, WIFI_PORT_STATUS
    cmp al, WIFI_STATUS_CONNECTED
    je .connect_success
    
    loop .connect_wait
    
.connect_success:
    mov byte [wifi_status], WIFI_STATUS_CONNECTED
    mov byte [wifi_connected], 0x01
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; WiFi: Get signal strength
wifi_get_signal:
    push ebx
    push ecx
    push edx
    
    mov al, 0x07             ; Signal strength command
    out WIFI_PORT_CMD, al
    
    in al, WIFI_PORT_DATA
    mov byte [wifi_signal_strength], al
    
    pop edx
    pop ecx
    pop ebx
    ret

; WiFi: Wait for response
wifi_wait_response:
    push eax
    push ecx
    
    mov ecx, 0x10000
    
.wait_loop:
    in al, WIFI_PORT_STATUS
    cmp al, 0x00
    je .wait_done
    
    loop .wait_loop
    
.wait_done:
    pop ecx
    pop eax
    ret

; Draw desktop background and UI
draw_desktop:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Fill screen with blue gradient background
    call fill_background
    
    ; Draw taskbar at bottom
    call draw_taskbar
    
    ; Draw window frame
    call draw_window
    
    ; Draw desktop icons
    call draw_icons
    
    ; Draw WiFi status indicator
    call draw_wifi_indicator
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Fill background with gradient
fill_background:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    mov edi, SCREEN_MEMORY
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT / 4
    
.fill_loop:
    mov eax, 0x02020202      ; Blue pixels
    mov dword [edi], eax
    add edi, 4
    
    cmp edi, SCREEN_MEMORY + (SCREEN_WIDTH * 300)
    jl .fill_loop
    
.fill_bottom:
    mov eax, 0x01010101      ; Darker blue
    mov dword [edi], eax
    add edi, 4
    
    cmp edi, SCREEN_MEMORY + (SCREEN_WIDTH * SCREEN_HEIGHT)
    jl .fill_bottom
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw taskbar (at bottom)
draw_taskbar:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    ; Taskbar position: y = 570, height = 30
    mov edi, SCREEN_MEMORY + (570 * SCREEN_WIDTH)
    mov ecx, SCREEN_WIDTH * 30
    mov al, 0x08             ; Gray color
    
.taskbar_loop:
    mov byte [edi], al
    inc edi
    loop .taskbar_loop
    
    ; Draw taskbar border
    mov edi, SCREEN_MEMORY + (570 * SCREEN_WIDTH)
    mov al, 0x0F             ; White
    mov ecx, SCREEN_WIDTH
    
.border_loop:
    mov byte [edi], al
    add edi, 1
    loop .border_loop
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw window frame
draw_window:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Window: x=50, y=50, width=700, height=450
    mov ebx, 50              ; x start
    mov ecx, 50              ; y start
    mov edx, 700             ; width
    mov esi, 450             ; height
    
    call draw_rect_outline
    
    ; Window title bar
    mov edi, SCREEN_MEMORY + (50 * SCREEN_WIDTH) + 50
    mov al, 0x09             ; Light blue
    mov ecx, 700
    
.title_loop:
    mov byte [edi], al
    inc edi
    loop .title_loop
    
    ; Draw title text
    mov edi, SCREEN_MEMORY + (50 * SCREEN_WIDTH) + 60
    mov esi, window_title
    call draw_text_white
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw rectangle outline
; EBX=x, ECX=y, EDX=width, ESI=height
draw_rect_outline:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov al, 0x0F             ; White
    
    ; Top line
    mov edi, SCREEN_MEMORY
    add edi, ecx
    mov ecx, SCREEN_WIDTH
    imul ecx, ebx
    add edi, ecx
    
    mov ecx, edx
.top_line:
    mov byte [edi], al
    inc edi
    loop .top_line
    
    ; Bottom line
    mov edi, SCREEN_MEMORY
    mov ecx, ebx
    add ecx, esi
    mov eax, SCREEN_WIDTH
    imul eax, ecx
    add edi, eax
    add edi, ebx
    
    mov ecx, edx
.bottom_line:
    mov byte [edi], al
    inc edi
    loop .bottom_line
    
    ; Left and right lines
    mov ecx, esi
    
.vertical_loop:
    ; Left line
    mov edi, SCREEN_MEMORY
    mov eax, ecx
    add eax, ebx
    mov edx, SCREEN_WIDTH
    imul edx, eax
    add edi, edx
    add edi, ebx
    mov byte [edi], al
    
    ; Right line
    mov edi, SCREEN_MEMORY
    mov edx, SCREEN_WIDTH
    imul edx, eax
    add edi, edx
    add edi, ebx
    add edi, 700
    mov byte [edi], al
    
    loop .vertical_loop
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw desktop icons
draw_icons:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Draw icon at position (20, 20)
    mov edi, SCREEN_MEMORY + (20 * SCREEN_WIDTH) + 20
    mov esi, icon_data
    call draw_icon
    
    ; Draw icon at position (120, 20)
    mov edi, SCREEN_MEMORY + (20 * SCREEN_WIDTH) + 120
    mov esi, icon_data2
    call draw_icon
    
    ; Draw WiFi icon at position (220, 20)
    mov edi, SCREEN_MEMORY + (20 * SCREEN_WIDTH) + 220
    mov esi, wifi_icon
    call draw_icon
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw WiFi status indicator
draw_wifi_indicator:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Draw WiFi status in top-right corner
    mov edi, SCREEN_MEMORY + (10 * SCREEN_WIDTH) + 700
    
    ; Check if WiFi is connected
    cmp byte [wifi_connected], 0x01
    jne .wifi_disconnected
    
    ; Draw connected indicator (green)
    mov al, 0x02             ; Green
    mov ecx, 50
    
.wifi_connected_bar:
    mov byte [edi], al
    inc edi
    loop .wifi_connected_bar
    
    jmp .wifi_done
    
.wifi_disconnected:
    ; Draw disconnected indicator (red)
    mov al, 0x04             ; Red
    mov ecx, 50
    
.wifi_disconnected_bar:
    mov byte [edi], al
    inc edi
    loop .wifi_disconnected_bar
    
.wifi_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw single icon (16x16)
draw_icon:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov ecx, 16
    mov edx, 16
    
.icon_row:
    mov ebx, edx
    
.icon_col:
    lodsb
    cmp al, 0x20             ; space = transparent
    je .icon_skip
    
    mov byte [edi], al
    
.icon_skip:
    inc edi
    dec ebx
    jnz .icon_col
    
    add edi, (SCREEN_WIDTH - 16)
    
    loop .icon_row
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw text (white)
draw_text_white:
    push eax
    push ebx
    push ecx
    push edi
    
    mov al, 0x0F
    
.text_loop:
    mov bl, byte [esi]
    cmp bl, 0
    je .text_done
    
    mov byte [edi], al
    inc edi
    inc esi
    jmp .text_loop
    
.text_done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

; Main event loop
main_loop:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Check mouse input
    call check_mouse
    
    ; Check keyboard
    call check_keyboard
    
    ; Update WiFi status periodically
    call wifi_get_signal
    
    jmp main_loop
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Check mouse movement and clicks
check_mouse:
    push eax
    push ebx
    push ecx
    push edx
    
    in al, 0x60
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Check keyboard input
check_keyboard:
    push eax
    
    in al, 0x60
    
    cmp al, 0x01
    je .exit
    
    ; W key = connect WiFi
    cmp al, 0x11
    je .connect_wifi
    
    ; D key = disconnect WiFi
    cmp al, 0x20
    je .disconnect_wifi
    
.keyboard_done:
    pop eax
    ret
    
.exit:
    jmp kernel_start
    
.connect_wifi:
    call wifi_connect_to_network
    jmp .keyboard_done
    
.disconnect_wifi:
    mov byte [wifi_connected], 0x00
    jmp .keyboard_done

; String data
window_title db "MinimalOS GUI + WiFi Support v1.0", 0

; Icon data (simple 16x16 patterns)
icon_data:
    db "  0000000000000   "
    db " 00          0000 "
    db "00     AAAA     00"
    db "0     AAAAAA     0"
    db "0     AAAAAA     0"
    db "0      AAAA      0"
    db " 00          0000 "
    db "  0000000000000   "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "

icon_data2:
    db "  1111111111111   "
    db " 11          1111 "
    db "11     BBBB     11"
    db "1     BBBBBB     1"
    db "1     BBBBBB     1"
    db "1      BBBB      1"
    db " 11          1111 "
    db "  1111111111111   "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "

; WiFi icon (signal bars)
wifi_icon:
    db "          CCCCCC "
    db "        CC    CC "
    db "      CC  CCCC  "
    db "    CC  CC    CC "
    db "  CC  CC  CCCC   "
    db " CC CC CC    CC  "
    db "CC CC  CC  CCCC  "
    db "CCCCCC CCCCCC    "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "
    db "                  "

; Global Descriptor Table
gdt:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw $ - gdt - 1
    dd gdt

; Mouse state
mouse_x dd 400
mouse_y dd 300
mouse_buttons db 0

times 4096 - ($ - $$) db 0
