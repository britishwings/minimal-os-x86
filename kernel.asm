[BITS 32]                    ; Protected mode (32-bit)
[ORG 0x1000]                 ; Kernel loaded at 0x1000

; Simple ASCII Art Browser Kernel
kernel_start:
    mov esp, 0x90000         ; Set up kernel stack
    call setup_gdt
    call clear_screen
    call draw_browser_ui
    call draw_welcome_page
    jmp $                    ; Infinite loop

; VGA text buffer constants
VIDEO_MEMORY equ 0xB8000
VIDEO_WIDTH equ 80
VIDEO_HEIGHT equ 25
VIDEO_ATTR equ 0x0F          ; White on black

; Clear screen
clear_screen:
    push eax
    push ecx
    push edi
    
    mov edi, VIDEO_MEMORY
    mov ecx, VIDEO_WIDTH * VIDEO_HEIGHT
    mov ax, 0x0F00           ; Clear with white space
    
.clear_loop:
    mov word [edi], ax
    add edi, 2
    loop .clear_loop
    
    pop edi
    pop ecx
    pop eax
    ret

; Draw browser UI frame
draw_browser_ui:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Draw top border with title bar
    mov edi, VIDEO_MEMORY
    mov al, 0xCD              ; ═
    mov ah, 0x0E              ; Yellow
    mov ecx, 80
    
.top_border:
    mov word [edi], ax
    add edi, 2
    loop .top_border
    
    ; Add title
    mov edi, VIDEO_MEMORY + 2*2
    mov esi, browser_title
    call print_at_edi
    
    ; Draw URL bar row
    mov edi, VIDEO_MEMORY + (1 * VIDEO_WIDTH * 2)
    mov al, 0xB3              ; ║
    mov ah, 0x0E
    mov word [edi], ax
    
    ; URL bar background
    mov edi, VIDEO_MEMORY + (1 * VIDEO_WIDTH * 2) + 2
    mov ax, 0x0700            ; Black on white (URL bar highlight)
    mov ecx, 76
    
.url_bar:
    mov word [edi], ax
    add edi, 2
    loop .url_bar
    
    ; Right border
    mov word [edi], 0x0EB3
    
    ; Draw URL text
    mov edi, VIDEO_MEMORY + (1 * VIDEO_WIDTH * 2) + 4
    mov esi, url_bar_text
    call print_at_edi_black
    
    ; Draw separator
    mov edi, VIDEO_MEMORY + (2 * VIDEO_WIDTH * 2)
    mov al, 0xCC              ; ╬
    mov ah, 0x0E
    mov word [edi], ax
    
    mov al, 0xCD              ; ═
    mov ecx, 78
    add edi, 2
    
.sep_line:
    mov word [edi], ax
    add edi, 2
    loop .sep_line
    
    mov word [edi], 0x0ECC
    
    ; Draw left and right borders for content area
    mov ecx, 21
    mov edx, 3
    
.draw_borders:
    mov edi, VIDEO_MEMORY + (edx * VIDEO_WIDTH * 2)
    mov al, 0xB3
    mov ah, 0x0E
    mov word [edi], ax
    
    mov edi, VIDEO_MEMORY + (edx * VIDEO_WIDTH * 2) + 158
    mov word [edi], ax
    
    inc edx
    loop .draw_borders
    
    ; Draw bottom border
    mov edi, VIDEO_MEMORY + (24 * VIDEO_WIDTH * 2)
    mov al, 0xC8              ; ╚
    mov ah, 0x0E
    mov word [edi], ax
    
    mov al, 0xCD              ; ═
    mov ecx, 78
    add edi, 2
    
.bottom_border:
    mov word [edi], ax
    add edi, 2
    loop .bottom_border
    
    mov word [edi], 0x0EBC    ; ╝
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw welcome page
draw_welcome_page:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Line 3: Logo
    mov edi, VIDEO_MEMORY + (3 * VIDEO_WIDTH * 2) + 4
    mov esi, logo_line1
    call print_content_line
    
    ; Line 4
    mov edi, VIDEO_MEMORY + (4 * VIDEO_WIDTH * 2) + 4
    mov esi, logo_line2
    call print_content_line
    
    ; Line 5
    mov edi, VIDEO_MEMORY + (5 * VIDEO_WIDTH * 2) + 4
    mov esi, logo_line3
    call print_content_line
    
    ; Blank line
    ; Line 7: Title
    mov edi, VIDEO_MEMORY + (7 * VIDEO_WIDTH * 2) + 4
    mov esi, welcome_title
    call print_content_line
    
    ; Line 9: Content
    mov edi, VIDEO_MEMORY + (9 * VIDEO_WIDTH * 2) + 4
    mov esi, welcome_content1
    call print_content_line
    
    ; Line 10
    mov edi, VIDEO_MEMORY + (10 * VIDEO_WIDTH * 2) + 4
    mov esi, welcome_content2
    call print_content_line
    
    ; Line 11
    mov edi, VIDEO_MEMORY + (11 * VIDEO_WIDTH * 2) + 4
    mov esi, welcome_content3
    call print_content_line
    
    ; Line 13: Features
    mov edi, VIDEO_MEMORY + (13 * VIDEO_WIDTH * 2) + 4
    mov esi, features_title
    call print_content_line
    
    ; Line 14
    mov edi, VIDEO_MEMORY + (14 * VIDEO_WIDTH * 2) + 4
    mov esi, feature1
    call print_content_line
    
    ; Line 15
    mov edi, VIDEO_MEMORY + (15 * VIDEO_WIDTH * 2) + 4
    mov esi, feature2
    call print_content_line
    
    ; Line 16
    mov edi, VIDEO_MEMORY + (16 * VIDEO_WIDTH * 2) + 4
    mov esi, feature3
    call print_content_line
    
    ; Line 18: Status bar
    mov edi, VIDEO_MEMORY + (23 * VIDEO_WIDTH * 2) + 4
    mov esi, status_bar
    call print_content_line
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Print string at EDI position
print_at_edi:
    push eax
    push ecx
    push esi
    push edi
    
    xor ecx, ecx
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0E             ; Yellow
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    inc ecx
    
    cmp ecx, 74
    jl .loop
    
.done:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

; Print string at EDI with black background (for URL bar)
print_at_edi_black:
    push eax
    push ecx
    push esi
    push edi
    
    xor ecx, ecx
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x07             ; Black background, white text
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    inc ecx
    
    cmp ecx, 74
    jl .loop
    
.done:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

; Print content line (with cyan color)
print_content_line:
    push eax
    push ecx
    push esi
    push edi
    
    xor ecx, ecx
    
.loop:
    mov al, byte [esi]
    cmp al, 0
    je .done
    
    mov ah, 0x0B             ; Cyan text
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    inc ecx
    
    cmp ecx, 74
    jl .loop
    
.done:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

; Setup GDT
setup_gdt:
    push eax
    
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    
    pop eax
    ret

; Browser UI Strings
browser_title db " MinimalOS ASCII Browser v1.0 ", 0

url_bar_text db "URL: http://localhost/index.html", 0

logo_line1 db "   __  ___           _   ", 0
logo_line2 db "  / / / _ )___ ___  (_) __ __ __ _____ __  ", 0
logo_line3 db " / /_/ _  / _ / _ \/ / // // // // -_) \\ / ", 0

welcome_title db "Welcome to MinimalOS ASCII Browser!", 0

welcome_content1 db "This is a lightweight text-based web browser running", 0
welcome_content2 db "on a minimal x86 assembly operating system kernel.", 0
welcome_content3 db "Rendered entirely with ASCII characters!", 0

features_title db "Features:", 0
feature1 db " * Pure ASCII Graphics (no pixel mode needed)", 0
feature2 db " * Runs in protected mode on QEMU/KVM", 0
feature3 db " * Lightweight kernel in x86-32 assembly", 0

status_bar db "[Ready] MinimalOS ASCII Browser | Press Ctrl+Q to exit", 0

; Global Descriptor Table
gdt:
    ; Null descriptor
    dq 0x0000000000000000
    
    ; Code segment
    dq 0x00CF9A000000FFFF
    
    ; Data segment
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw $ - gdt - 1
    dd gdt

; Pad kernel
times 4096 - ($ - $$) db 0
