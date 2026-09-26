; Handwritten x86-64 assembly. Internal ABI: RCX, RDX, R8, R9.
; Every procedure preserves all Win64 and SysV nonvolatile GP registers.
; 16-byte call alignment, 128 bytes of outgoing arguments, 240 bytes of locals.
bits 64
default rel
%macro proc 1
%ifdef WINDOWS
%ifdef LAST_PROC_END
LAST_PROC_END:
%endif
%endif
%1:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 328
%ifdef WINDOWS
    ; Win64 non-leaf routines require unwind metadata for native stack walkers.
    ; Prologue: eight saved registers followed by a 328-byte allocation.
    section .xdata rdata align=4
    align 4
%%unwind:
    db 1,22,10,0
    db 22,1
    dw 41
    db 15,0xf0,13,0xe0,11,0xd0,9,0xc0
    db 7,0x70,6,0x60,5,0x30,1,0x50
    section .pdata rdata align=4
    dd %1 wrt ..imagebase, %%end wrt ..imagebase, %%unwind wrt ..imagebase
    section .text
    %xdefine LAST_PROC_END %%end
%endif
%endmacro
%macro return 0
    add rsp, 328
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret
%endmacro
; Arguments are first staged so permutations of argument registers are safe.
; R11 is the macro scratch register and must never be an argument.
%macro args 1-16
    %assign %%i 0
    %rep %0
        mov r11, %1
        mov [rsp+%%i*8], r11
        %assign %%i %%i+1
        %rotate 1
    %endrep
%endmacro
%macro invoke 1-17
    %define %%fn %1
    %rotate 1
    %assign %%n %0-1
    %assign %%i 0
    %rep %%n
        mov r11, %1
        mov [rsp+%%i*8], r11
        %assign %%i %%i+1
        %rotate 1
    %endrep
    mov rcx,[rsp]
    mov rdx,[rsp+8]
    mov r8,[rsp+16]
    mov r9,[rsp+24]
    call %%fn
%endmacro
%macro ccall 1-17
    %define %%fn %1
    %rotate 1
    %assign %%n %0-1
    %assign %%i 0
    %rep %%n
        mov r11,%1
        mov [rsp+%%i*8],r11
        %assign %%i %%i+1
        %rotate 1
    %endrep
%ifdef WINDOWS
    mov rcx,[rsp]
    mov rdx,[rsp+8]
    mov r8,[rsp+16]
    mov r9,[rsp+24]
    call %%fn
%else
    mov rdi,[rsp]
    mov rsi,[rsp+8]
    mov rdx,[rsp+16]
    mov rcx,[rsp+24]
    mov r8,[rsp+32]
    mov r9,[rsp+40]
    %assign %%i 6
    %rep 10
        mov r11,[rsp+%%i*8]
        mov [rsp+(%%i-6)*8],r11
        %assign %%i %%i+1
    %endrep
    xor eax,eax
    call %%fn
%endif
%endmacro
; Platform sources define external names before including this file.
%define E_TEXT 0
%define E_TIME 8
%define E_FLAGS 16
%define E_FONT 24
%define E_SIZE 32
%define E_WEIGHT 40
%define E_ITALIC 48
%define E_FG 56
%define E_BG 64
%define E_DATE 72
%define E_FRACTION 80
%define E_BYTES 88
%define MAX_ITEMS 50
%define F_FONT 1
%define F_SIZE 2
%define F_WEIGHT 4
%define F_ITALIC 8
%define F_FG 16
%define F_BG 32
