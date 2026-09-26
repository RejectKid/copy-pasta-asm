%define WINDOWS 1
%include "abi.inc"
%include "crt.inc"
extern GetCommandLineW, GetModuleHandleW, ExitProcess, CreateDirectoryA
extern RegisterClassExW, CreateWindowExW, ShowWindow, UpdateWindow
extern GetMessageW, TranslateMessage, DispatchMessageW, DefWindowProcW
extern PostQuitMessage, SendMessageW, PostMessageW, MoveWindow, GetClientRect
extern RegisterHotKey, UnregisterHotKey, SetTimer, KillTimer
extern GetAsyncKeyState, SendInput, GetGUIThreadInfo, GetWindowThreadProcessId
extern GetCurrentProcessId, GetCursorPos, GetForegroundWindow
extern LoadCursorW, LoadIconW, SetWindowTextW, SetWindowLongPtrW
extern CreateFontW, DeleteObject, GetStockObject, SetBkColor, SetTextColor, CreateSolidBrush
extern MultiByteToWideChar, WideCharToMultiByte, GetEnvironmentVariableA
extern CoInitializeEx, CoCreateInstance, CoUninitialize, SysFreeString, VariantClear
extern GetDpiForWindow, SetProcessDpiAwarenessContext
extern MoveFileExA
extern SetCapture,ReleaseCapture,SetCursor,ScreenToClient

section .data
w_class dw __utf16__('CopyPastaAssembly'),0
w_title dw __utf16__('Copy Pasta ASM'),0
w_button dw __utf16__('BUTTON'),0
w_static dw __utf16__('STATIC'),0
w_listbox dw __utf16__('LISTBOX'),0
w_edit dw __utf16__('EDIT'),0
w_remove dw __utf16__('Remove'),0
w_clear dw __utf16__('Clear'),0
w_hotkeys dw __utf16__('Ctrl+Alt+C capture | Ctrl+Alt+V type | Ctrl+Alt+X stop'),0
w_history dw __utf16__('History'),0
w_selected dw __utf16__('Selected text'),0
w_segoe dw __utf16__('Segoe UI'),0
w_consolas dw __utf16__('Consolas'),0
w_empty dw 0
w_appdata db 'APPDATA',0
w_history_env db 'COPY_PASTA_HISTORY',0
w_subdir db '\CopyPastaAsm',0
w_filename db '\history.json',0
w_testarg dw __utf16__('--self-test'),0
w_hotkey_error db 'One or more global hotkeys are already in use by another app.',0
w_native_source db 'native edit control',0
w_uia_source db 'UI Automation',0
w_typing_buffer dq 0
w_typing_index dq 0
w_typing_length dq 0
w_typing_state dq 0
w_preview_fg dd 0
w_preview_bg dd 0xffffff
w_instance dq 0
w_window dq 0
w_list dq 0
w_preview dq 0
w_status dq 0
w_details dq 0
w_remove_hwnd dq 0
w_clear_hwnd dq 0
w_help dq 0
w_history_label dq 0
w_preview_label dq 0
w_ui_font dq 0
w_preview_font dq 0
w_preview_brush dq 0
w_uia dq 0
w_walker dq 0
w_process_id dd 0
w_split_width dq 360
w_dragging dq 0
; CLSID_CUIAutomation and IID_IUIAutomation, from the Windows SDK.
w_clsid dd 0xff48dba4
    dw 0x60ef,0x4201
    db 0xaa,0x87,0x54,0x10,0x3e,0xef,0x59,0x4e
w_iid dd 0x30cbe57d
    dw 0xd9d0,0x452a
    db 0xab,0x13,0x7a,0xc5,0xac,0x48,0x25,0xee
section .bss
w_wc resb 80
w_msg resb 48
w_rect resb 16
w_wide resw 1048577
w_capture_wide resw 200005
w_gui resb 72
w_inputs resb 80

section .text
global start
proc start
    invoke SetProcessDpiAwarenessContext,-4
    invoke GetModuleHandleW,0
    mov [w_instance],rax
    invoke GetCurrentProcessId
    mov [w_process_id],eax
    invoke w_init_path
    invoke GetCommandLineW
    mov rsi,rax
.arg:
    cmp word [rsi],0
    je .gui
    cmp word [rsi],'-'
    jne .argnext
    mov rdi,w_testarg
    mov rcx,11
    push rsi
    repe cmpsw
    pop rsi
    je .test
.argnext:
    add rsi,2
    jmp .arg
.test:
    invoke core_self_test
    invoke ExitProcess,rax
.gui:
    invoke CoInitializeEx,0,2
    invoke CoCreateInstance,w_clsid,0,1,w_iid,w_uia
    mov rcx,[w_uia]
    test rcx,rcx
    jz .window
    mov rax,[rcx]
    invoke qword [rax+14*8],rcx,w_walker
.window:
    mov dword [w_wc],80
    lea rax,[w_wndproc]
    mov [w_wc+8],rax
    mov rax,[w_instance]
    mov [w_wc+24],rax
    invoke LoadCursorW,0,32512
    mov [w_wc+40],rax
    invoke LoadIconW,[w_instance],1
    mov [w_wc+32],rax
    mov [w_wc+72],rax
    mov qword [w_wc+48],6
    lea rax,[w_class]
    mov [w_wc+64],rax
    invoke RegisterClassExW,w_wc
    invoke CreateWindowExW,0,w_class,w_title,0x02cf0000,0x80000000,0x80000000,980,620,0,0,[w_instance],0
    mov [w_window],rax
    test rax,rax
    jz .failed
    invoke core_load
    invoke w_refresh
    invoke ShowWindow,[w_window],5
    invoke UpdateWindow,[w_window]
    xor ebx,ebx
    invoke RegisterHotKey,[w_window],100,0x4003,0x43
    or ebx,eax
    test eax,eax
    jz .hotkey_failed
    invoke RegisterHotKey,[w_window],101,0x4003,0x56
    test eax,eax
    jz .hotkey_failed
    invoke RegisterHotKey,[w_window],102,0x4003,0x58
    test eax,eax
    jnz .loop
.hotkey_failed:
    invoke w_status_set,w_hotkey_error
.loop:
    invoke GetMessageW,w_msg,0,0,0
    test eax,eax
    jle .quit
    invoke TranslateMessage,w_msg
    invoke DispatchMessageW,w_msg
    jmp .loop
.quit:
    invoke core_clear
    invoke w_release,[w_walker]
    invoke w_release,[w_uia]
    invoke CoUninitialize
    invoke ExitProcess,0
.failed:
    invoke ExitProcess,1

proc w_init_path
    ccall getenv,w_history_env
    test rax,rax
    jz .default
    ccall snprintf_fn,history_path,4096,w_path_fmt,rax
    return
.default:
    invoke GetEnvironmentVariableA,w_appdata,history_path,4000
    ccall strcat,history_path,w_subdir
    invoke CreateDirectoryA,history_path,0
    ccall strcat,history_path,w_filename
    return

; UTF-8 to shared UTF-16 scratch buffer. Use immediately, not across calls.
proc w_utf16
    invoke MultiByteToWideChar,65001,0,rcx,-1,w_wide,1048577
    lea rax,[w_wide]
    return
proc w_utf8
    mov rbx,rcx
    invoke WideCharToMultiByte,65001,0,rbx,-1,0,0,0,0
    mov r12,rax
    ccall malloc,r12
    test rax,rax
    jz .done
    mov r13,rax
    invoke WideCharToMultiByte,65001,0,rbx,-1,r13,r12,0,0
    mov rax,r13
.done:
    return
proc w_status_set
    invoke w_utf16,rcx
    invoke SetWindowTextW,[w_status],rax
    return
proc w_release
    test rcx,rcx
    jz .done
    mov rax,[rcx]
    invoke qword [rax+16],rcx
.done:
    return

; Create a child: RCX class, RDX text, R8 style, R9 identifier.
proc w_child
    invoke CreateWindowExW,0,rcx,rdx,r8,0,0,10,10,[w_window],r9,[w_instance],0
    mov rbx,rax
    invoke SendMessageW,rbx,0x30,[w_ui_font],1
    mov rax,rbx
    return

proc w_wndproc
    mov rbx,rcx
    mov r12,rdx
    mov r13,r8
    mov r14,r9
    cmp edx,1
    je .create
    cmp edx,5
    je .size
    cmp edx,0x24
    je .minsize
    cmp edx,0x111
    je .command
    cmp edx,0x312
    je .hotkey
    cmp edx,0x113
    je .timer
    cmp edx,0x138
    je .color
    cmp edx,0x133
    je .color
    cmp edx,2
    je .destroy
    cmp edx,0x201
    je .mouse_down
    cmp edx,0x200
    je .mouse_move
    cmp edx,0x202
    je .mouse_up
    invoke DefWindowProcW,rbx,r12,r13,r14
    return
.create:
    mov [w_window],rbx
    invoke CreateFontW,-16,0,0,0,400,0,0,0,1,0,0,5,0,w_segoe
    mov [w_ui_font],rax
    invoke w_child,w_button,w_remove,0x50010000,10
    mov [w_remove_hwnd],rax
    invoke w_child,w_button,w_clear,0x50010000,11
    mov [w_clear_hwnd],rax
    invoke w_child,w_static,w_hotkeys,0x50000000,12
    mov [w_help],rax
    invoke w_child,w_static,w_history,0x50000000,13
    mov [w_history_label],rax
    invoke w_child,w_static,w_selected,0x50000000,14
    mov [w_preview_label],rax
    invoke w_child,w_listbox,w_empty,0x50b10101,15
    mov [w_list],rax
    invoke w_child,w_edit,w_empty,0x50b108c4,16
    mov [w_preview],rax
    invoke SendMessageW,rax,0xc5,0x7ffffffe,0
    invoke w_child,w_static,w_empty,0x50000000,17
    mov [w_details],rax
    invoke w_child,w_static,w_empty,0x50000000,18
    mov [w_status],rax
    invoke w_status_set,core_ready
    invoke w_apply_style,0
    jmp .zero
.mouse_down:
    movzx eax,r14w
    sub rax,[w_split_width]
    cmp rax,10
    jb .zero
    cmp rax,28
    ja .zero
    mov qword [w_dragging],1
    invoke SetCapture,rbx
    jmp .zero
.mouse_move:
    cmp qword [w_dragging],0
    je .zero
    movsx r12,r14w
    sub r12,14
    cmp r12,180
    jl .zero
    invoke GetClientRect,rbx,w_rect
    mov eax,[w_rect+8]
    sub rax,220
    cmp r12,rax
    ja .zero
    mov [w_split_width],r12
    invoke w_layout
    jmp .zero
.mouse_up:
    mov qword [w_dragging],0
    invoke ReleaseCapture
    jmp .zero
.size:
    invoke w_layout
    jmp .zero
.minsize:
    mov dword [r14+24],760
    mov dword [r14+28],480
    jmp .zero
.command:
    mov eax,r13d
    and eax,0xffff
    cmp eax,10
    je .remove
    cmp eax,11
    je .clear
    cmp eax,15
    jne .zero
    shr r13d,16
    cmp r13d,1
    jne .zero
    invoke SendMessageW,[w_list],0x188,0,0
    mov [selected_index],rax
    invoke w_preview_update
    jmp .zero
.remove:
    invoke core_remove,[selected_index]
    invoke core_save
    invoke w_refresh
    invoke w_status_set,core_removed
    jmp .zero
.clear:
    invoke core_clear
    invoke core_save
    invoke w_refresh
    invoke w_status_set,core_cleared
    jmp .zero
.hotkey:
    cmp r13,100
    je .capture
    cmp r13,101
    je .type
    cmp r13,102
    jne .zero
    invoke w_stop_typing
    jmp .zero
.capture:
    invoke w_capture
    test rax,rax
    jz .no_selection
    mov r15,rax
    invoke core_add,r15
    invoke core_save
    mov r15,rax
    invoke w_refresh
    test r15, r15
    jz .save_failed
    mov rbx,[history]
    invoke core_length,[rbx+E_TEXT]
    lea rdx,[core_text]
    cmp qword [rbx+E_FLAGS],0
    je .capture_status
    lea rdx,[core_rich]
.capture_status:
    ccall snprintf_fn,status_buffer,1024,core_capture_fmt,rax,rdx,w_uia_source
    invoke w_status_set,status_buffer
    jmp .zero
.save_failed:
    invoke w_status_set,core_save_failed
    jmp .zero
.no_selection:
    invoke w_status_set,core_no_selection
    jmp .zero
.type:
    invoke w_start_typing
    jmp .zero
.timer:
    invoke w_type_tick
    jmp .zero
.color:
    cmp r14,[w_preview]
    jne .default_color
    invoke SetTextColor,r13,[w_preview_fg]
    invoke SetBkColor,r13,[w_preview_bg]
    mov rax,[w_preview_brush]
    return
.default_color:
    invoke DefWindowProcW,rbx,r12,r13,r14
    return
.destroy:
    invoke w_stop_typing
    invoke UnregisterHotKey,rbx,100
    invoke UnregisterHotKey,rbx,101
    invoke UnregisterHotKey,rbx,102
    invoke DeleteObject,[w_ui_font]
    invoke DeleteObject,[w_preview_font]
    invoke DeleteObject,[w_preview_brush]
    invoke PostQuitMessage,0
.zero:
    xor eax,eax
    return

proc w_layout
    invoke GetClientRect,[w_window],w_rect
    mov r12d,[w_rect+8]
    mov r13d,[w_rect+12]
    invoke MoveWindow,[w_remove_hwnd],10,10,82,32,1
    invoke MoveWindow,[w_clear_hwnd],100,10,72,32,1
    lea rax,[r12-194]
    invoke MoveWindow,[w_help],190,17,rax,24,1
    mov r14,[w_split_width]
    lea r15,[r14+28]
    mov rbx,r12
    sub rbx,r15
    sub rbx,10
    invoke MoveWindow,[w_history_label],10,64,r14,22,1
    invoke MoveWindow,[w_preview_label],r15,64,rbx,22,1
    lea rax,[r13-128]
    invoke MoveWindow,[w_list],10,90,r14,rax,1
    lea rdx,[r13-160]
    invoke MoveWindow,[w_preview],r15,90,rbx,rdx,1
    lea rax,[r13-62]
    invoke MoveWindow,[w_details],r15,rax,rbx,26,1
    lea rax,[r13-26]
    lea rdx,[r12-16]
    invoke MoveWindow,[w_status],8,rax,rdx,22,1
    return

proc w_refresh
    invoke SendMessageW,[w_list],0x184,0,0
    xor r12d,r12d
.loop:
    cmp r12,[history_count]
    jae .done
    lea rax,[history]
    invoke core_display,[rax+r12*8]
    invoke w_utf16,rax
    invoke SendMessageW,[w_list],0x180,0,rax
    inc r12
    jmp .loop
.done:
    invoke SendMessageW,[w_list],0x186,[selected_index],0
    invoke w_preview_update
    return

proc w_preview_update
    invoke core_selected
    mov rbx,rax
    test rbx,rbx
    jz .empty
    invoke w_utf16,[rbx+E_TEXT]
    invoke SetWindowTextW,[w_preview],rax
    invoke w_apply_style,rbx
    lea rax,[rbx+E_TIME]
    ccall localtime_fn,rax
    ccall strftime,date_buffer,128,core_date_fmt,rax
    invoke core_length,[rbx+E_TEXT]
    ccall snprintf_fn,details_buffer,1024,core_details_fmt,rax,date_buffer,core_empty
    invoke w_utf16,details_buffer
    invoke SetWindowTextW,[w_details],rax
    return
.empty:
    invoke SetWindowTextW,[w_preview],w_empty
    invoke w_utf16,core_zero
    invoke SetWindowTextW,[w_details],rax
    invoke w_apply_style,0
    return

proc w_apply_style
    mov rbx,rcx
    mov r12,-17
    mov r13,400
    xor r14d,r14d
    lea r15,[w_consolas]
    mov dword [w_preview_fg],0
    mov dword [w_preview_bg],0xffffff
    test rbx,rbx
    jz .font
    test qword [rbx+E_FLAGS],F_FONT
    jz .size
    invoke w_utf16,[rbx+E_FONT]
    mov r15,rax
.size:
    test qword [rbx+E_FLAGS],F_SIZE
    jz .weight
    movq xmm0,[rbx+E_SIZE]
    cvttsd2si r12,xmm0
    imul r12,r12,-4
    mov rax,r12
    cqo
    mov ecx,3
    idiv rcx
    mov r12,rax
    cmp r12,-200
    jl .default_size
    cmp r12,-1
    jle .weight
.default_size:
    mov r12,-17
.weight:
    cmp qword [rbx+E_WEIGHT],700
    jl .italic
    mov r13,700
.italic:
    mov r14,[rbx+E_ITALIC]
    test qword [rbx+E_FLAGS],F_FG
    jz .bg
    mov eax,[rbx+E_FG]
    mov [w_preview_fg],eax
.bg:
    test qword [rbx+E_FLAGS],F_BG
    jz .font
    mov eax,[rbx+E_BG]
    mov [w_preview_bg],eax
.font:
    invoke CreateFontW,r12,0,0,0,r13,r14,0,0,1,0,0,5,0,r15
    mov rbx,rax
    invoke SendMessageW,[w_preview],0x30,rbx,1
    invoke DeleteObject,[w_preview_font]
    mov [w_preview_font],rbx
    invoke DeleteObject,[w_preview_brush]
    invoke CreateSolidBrush,[w_preview_bg]
    mov [w_preview_brush],rax
    return

proc w_start_typing
    cmp qword [w_typing_state],0
    jne .done
    invoke core_selected
    test rax,rax
    jz .empty
    mov rbx,rax
    invoke w_utf16,[rbx+E_TEXT]
    invoke core_length,[rbx+E_TEXT]
    mov [w_typing_length],rax
    lea r12,[rax*2+2]
    ccall malloc,r12
    test rax,rax
    jz .done
    mov [w_typing_buffer],rax
    ccall memcpy,rax,w_wide,r12
    mov qword [w_typing_index],0
    mov qword [w_typing_state],1
    invoke w_status_set,core_release
    invoke SetTimer,[w_window],1,12,0
    jmp .done
.empty:
    invoke w_status_set,core_no_item
.done:
    return
proc w_stop_typing
    cmp qword [w_typing_state],0
    je .done
    invoke KillTimer,[w_window],1
    ccall free,[w_typing_buffer]
    mov qword [w_typing_buffer],0
    mov qword [w_typing_state],0
    invoke w_status_set,core_stopped
.done:
    return
proc w_type_tick
    cmp qword [w_typing_state],0
    je .done
    cmp qword [w_typing_state],1
    jne .type
    invoke GetAsyncKeyState,0x11
    test ax,0x8000
    jnz .done
    invoke GetAsyncKeyState,0x12
    test ax,0x8000
    jnz .done
    invoke GetAsyncKeyState,0x56
    test ax,0x8000
    jnz .done
    mov qword [w_typing_state],2
.type:
    mov rbx,[w_typing_index]
    cmp rbx,[w_typing_length]
    jae .finished
    ccall memset,w_inputs,0,80
    mov dword [w_inputs],1
    mov dword [w_inputs+40],1
    mov rax,[w_typing_buffer]
    movzx r12d,word [rax+rbx*2]
    inc qword [w_typing_index]
    cmp r12d,13
    je .cr
    cmp r12d,10
    je .enter
    mov [w_inputs+10],r12w
    mov [w_inputs+50],r12w
    mov dword [w_inputs+12],4
    mov dword [w_inputs+52],6
    jmp .send
.cr:
    cmp word [rax+rbx*2+2],10
    jne .enter
    inc qword [w_typing_index]
.enter:
    mov word [w_inputs+8],13
    mov word [w_inputs+48],13
    mov dword [w_inputs+52],2
.send:
    invoke SendInput,2,w_inputs,40
    cmp eax,2
    jne .failed
    ccall snprintf_fn,status_buffer,1024,core_type_fmt,[w_typing_index],[w_typing_length]
    invoke w_status_set,status_buffer
    jmp .done
.finished:
    invoke w_stop_typing
    ccall snprintf_fn,status_buffer,1024,core_typed_fmt,[w_typing_length]
    invoke w_status_set,status_buffer
    jmp .done
.failed:
    invoke w_stop_typing
    invoke w_status_set,core_failed
.done:
    return

%include "windows-capture.inc"
%include "core.inc"
section .data
w_path_fmt db '%s',0
