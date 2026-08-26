[BITS 32]                    ; Protected mode (32-bit)
[ORG 0x1000]                 ; Kernel loaded at 0x1000

; ASCII Art Graphics Browser Kernel
kernel_start:
    mov esp, 0x90000         ; Set up kernel stack
    call setup_gdt
    call clear_screen
    call draw_browser_frame
    call draw_content
    jmp $                    ; Infinite loop

; VGA text buffer constants
VIDEO_MEMORY equ 0xB8000
VIDEO_WIDTH equ 80
VIDEO_HEIGHT equ 25

; Clear screen
clear_screen:
    push eax
    push ecx
    push edi
    
    mov edi, VIDEO_MEMORY
    mov ecx, VIDEO_WIDTH * VIDEO_HEIGHT
    mov ax, 0x0F00           ; White space on black
    
.clear_loop:
    mov word [edi], ax
    add edi, 2
    loop .clear_loop
    
    pop edi
    pop ecx
    pop eax
    ret

; Draw complete browser frame
draw_browser_frame:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Row 0: Top decorative border
    call draw_top_decoration
    
    ; Row 1: Browser header with logo
    call draw_header
    
    ; Row 2: Toolbar with buttons
    call draw_toolbar
    
    ; Row 3: URL bar
    call draw_urlbar
    
    ; Row 4: Separator
    call draw_h_separator
    
    ; Rows 5-22: Content area
    call draw_content_area
    
    ; Row 23: Status bar
    call draw_statusbar
    
    ; Row 24: Bottom decoration
    call draw_bottom_decoration
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Top decorative border
draw_top_decoration:
    mov edi, VIDEO_MEMORY
    mov cx, 80
    mov ax, 0x0E2A            ; Yellow asterisk
    
.loop:
    mov word [edi], ax
    add edi, 2
    loop .loop
    ret

; Browser header with logo
draw_header:
    mov edi, VIDEO_MEMORY + (1 * VIDEO_WIDTH * 2)
    
    ; Left decoration
    mov ax, 0x0E3E            ; Yellow >
    mov word [edi], ax
    add edi, 2
    
    ; Spaces
    mov ax, 0x0F20
    mov ecx, 3
.header_space1:
    mov word [edi], ax
    add edi, 2
    loop .header_space1
    
    ; Logo text
    mov esi, header_logo
    call print_yellow
    
    ; Right decoration
    mov ax, 0x0E3C            ; Yellow <
    mov word [edi], ax
    ret

; Toolbar with buttons
draw_toolbar:
    mov edi, VIDEO_MEMORY + (2 * VIDEO_WIDTH * 2)
    
    ; Left border
    mov ax, 0x0E5B            ; Yellow [
    mov word [edi], ax
    add edi, 2
    
    ; Back button
    mov ax, 0x0F3C            ; White <
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F2D            ; White -
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F20
    mov word [edi], ax
    add edi, 2
    
    ; Forward button
    mov ax, 0x0F2D            ; White -
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F3E            ; White >
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F20
    mov word [edi], ax
    add edi, 2
    
    ; Reload button
    mov ax, 0x0F4F            ; White O
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F20
    mov word [edi], ax
    add edi, 2
    
    ; Stop button
    mov ax, 0x0FX            ; White X
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F20
    mov word [edi], ax
    add edi, 2
    
    ; Home button
    mov ax, 0x0FH            ; White H
    mov word [edi], ax
    add edi, 2
    
    mov ax, 0x0F20
    mov word [edi], ax
    add edi, 2
    
    ; Right border
    mov ax, 0x0E5D            ; Yellow ]
    mov word [edi], ax
    
    ret

; URL bar
draw_urlbar:
    mov edi, VIDEO_MEMORY + (3 * VIDEO_WIDTH * 2)
    
    ; URL bar box
    mov ax, 0x0E7C            ; Yellow |
    mov word [edi], ax
    add edi, 2
    
    ; URL text background
    mov ax, 0x0720            ; Black background, white text
    mov ecx, 76
    
.urlbar_loop:
    mov word [edi], ax
    add edi, 2
    loop .urlbar_loop
    
    ; Right border
    mov ax, 0x0E7C
    mov word [edi], ax
    
    ; Write URL text
    mov edi, VIDEO_MEMORY + (3 * VIDEO_WIDTH * 2) + 2
    mov esi, url_text
    call print_white
    
    ret

; Horizontal separator
draw_h_separator:
    mov edi, VIDEO_MEMORY + (4 * VIDEO_WIDTH * 2)
    mov ax, 0x0E3D            ; Yellow =
    mov ecx, 80
    
.sep_loop:
    mov word [edi], ax
    add edi, 2
    loop .sep_loop
    
    ret

; Content area (with ASCII art graphics)
draw_content_area:
    ; Line 5: Welcome banner
    mov edi, VIDEO_MEMORY + (5 * VIDEO_WIDTH * 2)
    mov ax, 0x0E20
    mov ecx, 80
.fill_line5:
    mov word [edi], ax
    add edi, 2
    loop .fill_line5
    
    ; Line 6: ASCII art scene
    mov edi, VIDEO_MEMORY + (6 * VIDEO_WIDTH * 2) + 4
    mov esi, ascii_art_line1
    call print_cyan
    
    ; Line 7
    mov edi, VIDEO_MEMORY + (7 * VIDEO_WIDTH * 2) + 4
    mov esi, ascii_art_line2
    call print_cyan
    
    ; Line 8
    mov edi, VIDEO_MEMORY + (8 * VIDEO_WIDTH * 2) + 4
    mov esi, ascii_art_line3
    call print_cyan
    
    ; Line 9
    mov edi, VIDEO_MEMORY + (9 * VIDEO_WIDTH * 2) + 4
    mov esi, ascii_art_line4
    call print_cyan
    
    ; Line 10: Title
    mov edi, VIDEO_MEMORY + (10 * VIDEO_WIDTH * 2) + 4
    mov esi, page_title
    call print_green
    
    ; Line 12: Content text
    mov edi, VIDEO_MEMORY + (12 * VIDEO_WIDTH * 2) + 4
    mov esi, content_line1
    call print_cyan
    
    ; Line 13
    mov edi, VIDEO_MEMORY + (13 * VIDEO_WIDTH * 2) + 4
    mov esi, content_line2
    call print_cyan
    
    ; Line 14
    mov edi, VIDEO_MEMORY + (14 * VIDEO_WIDTH * 2) + 4
    mov esi, content_line3
    call print_cyan
    
    ; Line 15: Divider
    mov edi, VIDEO_MEMORY + (15 * VIDEO_WIDTH * 2) + 4
    mov esi, ascii_divider
    call print_yellow
    
    ; Line 17: Features
    mov edi, VIDEO_MEMORY + (17 * VIDEO_WIDTH * 2) + 4
    mov esi, feature_header
    call print_green
    
    ; Line 18
    mov edi, VIDEO_MEMORY + (18 * VIDEO_WIDTH * 2) + 4
    mov esi, feature_item1
    call print_cyan
    
    ; Line 19
    mov edi, VIDEO_MEMORY + (19 * VIDEO_WIDTH * 2) + 4
    mov esi, feature_item2
    call print_cyan
    
    ; Line 20
    mov edi, VIDEO_MEMORY + (20 * VIDEO_WIDTH * 2) + 4
    mov esi, feature_item3
    call print_cyan
    
    ; Line 21
    mov edi, VIDEO_MEMORY + (21 * VIDEO_WIDTH * 2) + 4
    mov esi, feature_item4
    call print_cyan
    
    ret

; Status bar
draw_statusbar:
    mov edi, VIDEO_MEMORY + (23 * VIDEO_WIDTH * 2)
    mov ax, 0x0E3D            ; Yellow =
    mov ecx, 80
    
.status_sep:
    mov word [edi], ax
    add edi, 2
    loop .status_sep
    
    ; Status text
    mov edi, VIDEO_MEMORY + (23 * VIDEO_WIDTH * 2) + 2
    mov esi, status_text
    call print_white
    
    ret

; Bottom decorative border
draw_bottom_decoration:
    mov edi, VIDEO_MEMORY + (24 * VIDEO_WIDTH * 2)
    mov ax, 0x0E2A            ; Yellow asterisk
    mov ecx, 80
    
.bottom_loop:
    mov word [edi], ax
    add edi, 2
    loop .bottom_loop
    
    ret

; Draw content (main page)
draw_content:
    ret

; Print yellow string at EDI
print_yellow:
    push eax
    push ecx
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0E
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    
    loop .loop
    
.done:
    pop ecx
    pop eax
    ret

; Print white string at EDI
print_white:
    push eax
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0F
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    jmp .loop
    
.done:
    pop eax
    ret

; Print cyan string at EDI
print_cyan:
    push eax
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0B
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    jmp .loop
    
.done:
    pop eax
    ret

; Print green string at EDI
print_green:
    push eax
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0A
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    jmp .loop
    
.done:
    pop eax
    ret

; String data
header_logo db "MinimalOS Browser 1.0", 0

url_text db "file:///home/minimal/index.html", 0

ascii_art_line1 db "       ___         ", 0
ascii_art_line2 db "      /   \\    ::  ", 0
ascii_art_line3 db "     | O_O |    |  ", 0
ascii_art_line4 db "      \\   /    ::  ", 0

page_title db "Welcome to MinimalOS ASCII Browser", 0

content_line1 db "A lightweight text-based web browser running on x86 assembly", 0
content_line2 db "kernel in protected mode. All graphics rendered with ASCII art.", 0
content_line3 db "", 0

ascii_divider db "--------------------------------------------", 0

feature_header db "[ Features ]", 0

feature_item1 db "[*] Pure x86-32 Assembly Kernel", 0
feature_item2 db "[*] ASCII Art Graphics Rendering", 0
feature_item3 db "[*] Protected Mode Protected Execution", 0
feature_item4 db "[*] Lightweight & Educational", 0

status_text db "[OK] Page Loaded | Memory: 256MB | CPU: Ready", 0

; Global Descriptor Table
gdt:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw $ - gdt - 1
    dd gdt

times 4096 - ($ - $$) db 0
