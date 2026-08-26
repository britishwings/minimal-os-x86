; Minimal x86 Bootloader
; This is a 512-byte bootloader that loads a kernel into memory
; Assembled for BIOS-based systems

[BITS 16]                    ; Real mode (16-bit)
[ORG 0x7C00]                 ; BIOS loads bootloader at 0x7C00

start:
    jmp boot                 ; Jump over data

; Data section
welcome_msg db "Minimal OS Bootloader", 0x0D, 0x0A, 0
kernel_msg db "Loading kernel...", 0x0D, 0x0A, 0
ready_msg db "Ready to boot kernel", 0x0D, 0x0A, 0

boot:
    cli                      ; Disable interrupts
    xor ax, ax              ; Clear AX
    mov ds, ax              ; Set data segment
    mov es, ax              ; Set extra segment
    mov ss, ax              ; Set stack segment
    mov sp, 0x7C00          ; Set stack pointer

    ; Clear screen
    mov ah, 0x00            ; Set video mode function
    mov al, 0x03            ; 80x25 text mode
    int 0x10                ; Video BIOS interrupt

    ; Print welcome message
    mov si, welcome_msg
    call print_string

    ; Print kernel loading message
    mov si, kernel_msg
    call print_string

    ; Load kernel from disk (simplified - assumes kernel at sector 2)
    mov ah, 0x02            ; Read sectors function
    mov al, 10              ; Read 10 sectors
    mov ch, 0               ; Cylinder 0
    mov cl, 2               ; Sector 2
    mov dh, 0               ; Head 0
    mov bx, 0x1000          ; Load to memory address 0x1000
    int 0x13                ; Disk BIOS interrupt

    ; Check for read error
    jc disk_error

    ; Print ready message
    mov si, ready_msg
    call print_string

    ; Enter protected mode
    call enter_protected_mode

    ; This should not return
    jmp $

disk_error:
    mov si, error_msg
    call print_string
    jmp $

error_msg db "Disk read error!", 0x0D, 0x0A, 0

; Print string function
; Input: DS:SI = pointer to null-terminated string
print_string:
    push ax
    push bx

.loop:
    lodsb                   ; Load byte from DS:SI into AL
    cmp al, 0               ; Check for null terminator
    je .done
    mov ah, 0x0E            ; Teletype output
    mov bx, 0x0007          ; Page 0, light gray color
    int 0x10                ; Video BIOS interrupt
    jmp .loop

.done:
    pop bx
    pop ax
    ret

; Enter protected mode
enter_protected_mode:
    cli                      ; Disable interrupts
    
    ; Load GDT
    lgdt [gdt_descriptor]
    
    ; Set PE (Protection Enable) bit in CR0
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    
    ; Far jump to flush prefetch queue and enter protected mode
    jmp 0x08:protected_mode

[BITS 32]                   ; Protected mode (32-bit)

protected_mode:
    mov ax, 0x10            ; Data segment selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    ; Jump to kernel
    jmp 0x1000              ; Jump to loaded kernel at 0x1000

; GDT (Global Descriptor Table)
gdt:
    ; Null descriptor
    dq 0x0000000000000000
    
    ; Code segment descriptor (Base=0, Limit=0xFFFFF)
    dq 0x00CF9A000000FFFF
    
    ; Data segment descriptor (Base=0, Limit=0xFFFFF)
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw $ - gdt - 1          ; GDT limit
    dd gdt                  ; GDT base address

; Boot signature (required for bootable disk)
times 510 - ($ - $$) db 0
dw 0xAA55
