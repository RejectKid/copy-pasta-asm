; Native COM UI Automation, followed by the original edit-control fallback.
; Vtable indexes audited against Windows SDK UIAutomationClient.h.
section .text
proc w_capture
    mov rbx,[w_uia]
    test rbx,rbx
    jz .native
    mov qword [rbp-64],0
    mov rax,[rbx]
    lea rdx,[rbp-64]
    invoke qword [rax+8*8],rbx,rdx
    invoke w_walk_selection,[rbp-64]
    test rax,rax
    jnz .done
    lea rcx,[rbp-80]
    invoke GetCursorPos,rcx
    test eax,eax
    jz .native
    mov qword [rbp-64],0
    mov rax,[rbx]
    lea r8,[rbp-64]
    invoke qword [rax+7*8],rbx,[rbp-80],r8
    invoke w_walk_selection,[rbp-64]
    test rax,rax
    jnz .done
.native:
    invoke w_native_selection
.done:
    return

; Owns and releases the supplied element reference.
proc w_walk_selection
    mov rbx,rcx
    mov r12d,8
.loop:
    test rbx,rbx
    jz .none
    mov dword [rbp-64],0
    mov rax,[rbx]
    lea rdx,[rbp-64]
    invoke qword [rax+20*8],rbx,rdx
    test eax,eax
    js .parent
    mov eax,[rbp-64]
    cmp eax,[w_process_id]
    je .parent
    invoke w_element_selection,rbx
    test rax,rax
    jnz .found
.parent:
    mov qword [rbp-72],0
    mov rcx,[w_walker]
    test rcx,rcx
    jz .release
    mov rax,[rcx]
    lea r8,[rbp-72]
    invoke qword [rax+3*8],rcx,rbx,r8
.release:
    invoke w_release,rbx
    mov rbx,[rbp-72]
    dec r12d
    jnz .loop
    invoke w_release,rbx
.none:
    xor eax,eax
    return
.found:
    mov r13,rax
    invoke w_release,rbx
    mov rax,r13
    return

proc w_element_selection
    mov rbx,rcx
    mov qword [rbp-64],0 ; text pattern
    mov qword [rbp-72],0 ; range array
    mov qword [rbp-80],0 ; current range
    mov qword [rbp-88],0 ; BSTR
    mov qword [rbp-96],0 ; first range, retained for style
    xor r15d,r15d       ; result
    mov rax,[rbx]
    lea r8,[rbp-64]
    invoke qword [rax+16*8],rbx,10014,r8
    test eax,eax
    js .cleanup
    mov rcx,[rbp-64]
    test rcx,rcx
    jz .cleanup
    mov rax,[rcx]
    lea rdx,[rbp-72]
    invoke qword [rax+5*8],rcx,rdx
    test eax,eax
    js .cleanup
    mov rcx,[rbp-72]
    test rcx,rcx
    jz .cleanup
    mov rax,[rcx]
    lea rdx,[rbp-104]
    mov dword [rbp-104],0
    invoke qword [rax+3*8],rcx,rdx
    xor r12d,r12d
    xor r13d,r13d
    mov word [w_capture_wide],0
.range:
    cmp r12d,[rbp-104]
    jae .collected
    cmp r13d,200000
    jae .collected
    mov rcx,[rbp-72]
    mov rax,[rcx]
    lea r8,[rbp-80]
    invoke qword [rax+4*8],rcx,r12,r8
    test eax,eax
    js .collected
    mov rcx,[rbp-80]
    test rcx,rcx
    jz .collected
    test r12d,r12d
    jnz .gettext
    mov [rbp-96],rcx
    mov rax,[rcx]
    invoke qword [rax+8],rcx
.gettext:
    mov rcx,[rbp-80]
    mov rax,[rcx]
    mov edx,200000
    sub edx,r13d
    lea r8,[rbp-88]
    invoke qword [rax+12*8],rcx,rdx,r8
    test eax,eax
    js .range_end
    mov rsi,[rbp-88]
    test rsi,rsi
    jz .range_end
    cmp word [rsi],0
    je .range_end
    lea rdi,[w_capture_wide]
    lea rdi,[rdi+r13*2]
    test r13d,r13d
    jz .copy
    mov word [rdi],13
    mov word [rdi+2],10
    add rdi,4
    add r13d,2
.copy:
    cmp r13d,200000
    jae .terminate
    lodsw
    test ax,ax
    jz .terminate
    stosw
    inc r13d
    jmp .copy
.terminate:
    mov word [rdi],0
.range_end:
    invoke SysFreeString,[rbp-88]
    mov qword [rbp-88],0
    invoke w_release,[rbp-80]
    mov qword [rbp-80],0
    inc r12d
    jmp .range
.collected:
    test r13d,r13d
    jz .cleanup
    invoke w_utf8,w_capture_wide
    mov r14,rax
    test r14,r14
    jz .cleanup
    invoke core_blank,r14
    test eax,eax
    jnz .blank
    invoke core_new,r14
    mov r15,rax
.blank:
    ccall free,r14
    test r15,r15
    jz .cleanup
    invoke w_capture_style,[rbp-96],r15
.cleanup:
    invoke SysFreeString,[rbp-88]
    invoke w_release,[rbp-80]
    invoke w_release,[rbp-96]
    invoke w_release,[rbp-72]
    invoke w_release,[rbp-64]
    mov rax,r15
    return

proc w_capture_style
    mov rbx,rcx
    mov r12,rdx
    test rbx,rbx
    jz .done
    xor r13d,r13d
.loop:
    lea r14,[rbp-96]
    ccall memset,r14,0,24
    lea rax,[w_attributes]
    mov edx,[rax+r13*4]
    mov rax,[rbx]
    invoke qword [rax+9*8],rbx,rdx,r14
    test eax,eax
    js .next
    movzx eax,word [r14]
    test r13d,r13d
    jz .font
    cmp r13d,1
    je .size
    cmp r13d,3
    je .italic
    cmp eax,3
    jne .next
    movsxd rax,dword [r14+8]
    jmp .store
.italic:
    cmp eax,11
    jne .next
    xor eax,eax
    cmp word [r14+8],0
    setne al
    jmp .store
.size:
    cmp eax,5
    jne .next
    mov rax,[r14+8]
    jmp .store
.font:
    cmp eax,8
    jne .next
    invoke w_utf8,[r14+8]
    test rax,rax
    jz .next
.store:
    mov [r12+r13*8+E_FONT],rax
    mov ecx,r13d
    mov eax,1
    shl rax,cl
    or [r12+E_FLAGS],rax
.next:
    invoke VariantClear,r14
    inc r13d
    cmp r13d,6
    jb .loop
.done:
    return

proc w_native_selection
    mov dword [w_gui],72
    invoke GetGUIThreadInfo,0,w_gui
    test eax,eax
    jz .none
    mov rbx,[w_gui+16]
    test rbx,rbx
    jz .none
    lea rdx,[rbp-64]
    invoke GetWindowThreadProcessId,rbx,rdx
    mov eax,[rbp-64]
    cmp eax,[w_process_id]
    je .none
    invoke SendMessageW,rbx,0xd2,0,0
    test rax,rax
    jnz .none
    mov qword [rbp-72],0
    lea r8,[rbp-72]
    lea r9,[rbp-68]
    invoke SendMessageW,rbx,0xb0,r8,r9
    mov r12d,[rbp-72]
    mov r13d,[rbp-68]
    cmp r12d,r13d
    je .none
    jb .length
    xchg r12d,r13d
.length:
    invoke SendMessageW,rbx,0xe,0,0
    test eax,eax
    jle .none
    cmp eax,200000
    jbe .capacity
    mov eax,200000
.capacity:
    cmp r12d,eax
    jae .none
    cmp r13d,eax
    jbe .read
    mov r13d,eax
.read:
    inc eax
    invoke SendMessageW,rbx,0xd,rax,w_capture_wide
    lea rax,[w_capture_wide]
    mov word [rax+r13*2],0
    lea rcx,[rax+r12*2]
    invoke w_utf8,rcx
    mov rbx,rax
    test rbx,rbx
    jz .none
    invoke core_blank,rbx
    test eax,eax
    jnz .blank
    invoke core_new,rbx
    mov r12,rax
    ccall free,rbx
    mov rax,r12
    return
.blank:
    ccall free,rbx
.none:
    xor eax,eax
    return
section .data
w_attributes dd 40005,40006,40007,40014,40008,40001
