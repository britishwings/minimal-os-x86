[BITS 32]                    ; Protected mode (32-bit)
[ORG 0x1000]                 ; Kernel loaded at 0x1000

; Simple kernel entry point
kernel_start:
    mov esp, 0x90000         ; Set up kernel stack
    call setup_gdt
    call clear_screen
    call print_kernel_msg
    jmp $                    ; Infinite loop

; VGA text buffer functions
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
    mov al, 0x00
    mov ah, 0x0F             ; White on black
    
.clear_loop:
    mov word [edi], 0x0F00
    add edi, 2
    loop .clear_loop
    
    pop edi
    pop ecx
    pop eax
    ret

; Print kernel message
print_kernel_msg:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    
    mov edi, VIDEO_MEMORY
    mov esi, kernel_message
    xor ecx, ecx
    
.print_loop:
    mov al, byte [esi]
    cmp al, 0
    je .print_done
    
    mov ah, 0x0A             ; Light green on black
    mov word [edi], ax
    
    add esi, 1
    add edi, 2
    inc ecx
    
    cmp ecx, VIDEO_WIDTH
    jl .print_loop
    
    ; Move to next line
    mov ecx, 0
    add edi, (VIDEO_WIDTH - VIDEO_WIDTH) * 2
    jmp .print_loop

.print_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; Setup GDT for kernel
setup_gdt:
    push eax
    
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    
    pop eax
    ret

; Kernel messages
kernel_message db "=== Minimal OS Kernel ===", 0
welcome_kernel db "Kernel loaded successfully!", 0

; Global Descriptor Table
gdt:
    ; Null descriptor
    dq 0x0000000000000000
    
    ; Code segment (Base=0, Limit=0xFFFFF, 4KB granularity)
    dq 0x00CF9A000000FFFF
    
    ; Data segment (Base=0, Limit=0xFFFFF, 4KB granularity)
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw $ - gdt - 1
    dd gdt

; Pad to reasonable kernel size
times 4096 - ($ - $$) db 0
