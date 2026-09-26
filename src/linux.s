; Linux/X11 port. All application code is assembly; GTK3/Pango provide widgets.
%include "abi.inc"
%include "crt.inc"
extern mkdir
extern gtk_init_check,gtk_window_new,gtk_window_set_title,gtk_window_set_default_size
extern gtk_widget_set_size_request,gtk_container_set_border_width,gtk_container_add
extern gtk_box_new,gtk_box_pack_start,gtk_box_pack_end,gtk_button_new_with_label
extern gtk_label_new,gtk_label_set_text,gtk_label_set_xalign,gtk_label_set_ellipsize
extern gtk_paned_new,gtk_paned_pack1,gtk_paned_pack2,gtk_paned_set_position
extern gtk_scrolled_window_new,gtk_scrolled_window_set_policy
extern gtk_list_box_new,gtk_list_box_insert,gtk_list_box_get_row_at_index
extern gtk_list_box_select_row,gtk_list_box_row_get_index,gtk_widget_destroy
extern gtk_text_view_new,gtk_text_view_set_editable,gtk_text_view_set_cursor_visible
extern gtk_text_view_set_monospace,gtk_text_view_get_buffer,gtk_text_buffer_set_text
extern gtk_widget_show_all,gtk_main,gtk_main_quit,g_signal_connect_data
extern g_timeout_add,g_get_monotonic_time
extern XOpenDisplay,XCloseDisplay,XDefaultRootWindow,XCreateSimpleWindow,XDestroyWindow
extern XKeysymToKeycode,XGrabKey,XUngrabKey,XPending,XNextEvent,XFlush,XInternAtom
extern XConvertSelection,XGetWindowProperty,XFree,XTestFakeKeyEvent,XSetErrorHandler
extern XQueryKeymap
section .data
l_title db 'Copy Pasta ASM',0
l_remove db 'Remove',0
l_clear db 'Clear',0
l_help db 'Ctrl+Alt+C capture | Ctrl+Alt+V type | Ctrl+Alt+X stop',0
l_hist_label db 'History',0
l_prev_label db 'Selected text',0
l_clicked db 'clicked',0
l_destroy db 'destroy',0
l_row_selected db 'row-selected',0
l_env db 'COPY_PASTA_HISTORY',0
l_xdg db 'XDG_CONFIG_HOME',0
l_home db 'HOME',0
l_config db '%s/.config',0
l_path_fmt db '%s/CopyPastaAsm',0
l_file_fmt db '%s/history.json',0
l_str_fmt db '%s',0
l_testarg db '--self-test',0
l_no_x11 db 'Global hotkeys require X11; Wayland is not supported.',0
l_hotkey_error db 'One or more global hotkeys are already in use by another app.',0
l_source db 'X11 PRIMARY selection',0
l_primary db 'PRIMARY',0
l_utf8 db 'UTF8_STRING',0
l_property db 'COPY_PASTA_SELECTION',0
l_timeout db 'Timed out waiting for X11 selected text.',0
l_unsupported db 'Linux X11 text output supports common ASCII characters only.',0
l_shifted db '!@#$%^&*()_+{}:"<>?|~',0
l_unshifted db '1234567890-=[];',39,',./\`',0
l_window dq 0
l_list dq 0
l_preview dq 0
l_buffer dq 0
l_status dq 0
l_details dq 0
l_display dq 0
l_root dq 0
l_requestor dq 0
l_atom_primary dq 0
l_atom_utf8 dq 0
l_atom_property dq 0
l_deadline dq 0
l_keys times 3 dq 0
l_typing dq 0
l_type_ptr dq 0
l_type_index dq 0
l_type_length dq 0
l_type_start dq 0
l_refreshing dq 0
l_hotkey_failed dq 0
section .bss
l_event resb 192
l_keymap resb 32
l_path_temp resb 4096
section .text
global main
proc main
    mov r12,rdi
    mov r13,rsi
    invoke l_init_path
    cmp r12,2
    jb .gui
    ccall strcmp,[r13+8],l_testarg
    test eax,eax
    jnz .gui
    invoke core_self_test
    return
.gui:
    ccall gtk_init_check,0,0
    test eax,eax
    jz .failure
    ccall gtk_window_new,0
    mov [l_window],rax
    ccall gtk_window_set_title,rax,l_title
    ccall gtk_window_set_default_size,[l_window],980,620
    ccall gtk_widget_set_size_request,[l_window],760,480
    ccall gtk_box_new,1,10
    mov rbx,rax
    ccall gtk_container_set_border_width,rbx,10
    ccall gtk_container_add,[l_window],rbx
    ccall gtk_box_new,0,8
    mov r12,rax
    ccall gtk_box_pack_start,rbx,r12,0,0,0
    ccall gtk_button_new_with_label,l_remove
    mov r13,rax
    ccall gtk_box_pack_start,r12,r13,0,0,0
    ccall g_signal_connect_data,r13,l_clicked,l_remove_click,0,0,0
    ccall gtk_button_new_with_label,l_clear
    mov r13,rax
    ccall gtk_box_pack_start,r12,r13,0,0,0
    ccall g_signal_connect_data,r13,l_clicked,l_clear_click,0,0,0
    ccall gtk_label_new,l_help
    ccall gtk_box_pack_start,r12,rax,0,0,8
    ccall gtk_label_new,core_ready
    mov [l_status],rax
    ccall gtk_box_pack_end,rbx,rax,0,0,0
    mov rdi,[l_status]
    pxor xmm0,xmm0
    call gtk_label_set_xalign
    ccall gtk_paned_new,0
    mov r12,rax
    ccall gtk_box_pack_start,rbx,r12,1,1,0
    ccall gtk_paned_set_position,r12,360
    ccall gtk_box_new,1,6
    mov r13,rax
    ccall gtk_paned_pack1,r12,r13,0,0
    ccall gtk_label_new,l_hist_label
    ccall gtk_box_pack_start,r13,rax,0,0,0
    ccall gtk_scrolled_window_new,0,0
    mov r14,rax
    ccall gtk_scrolled_window_set_policy,r14,1,1
    ccall gtk_box_pack_start,r13,r14,1,1,0
    ccall gtk_list_box_new
    mov [l_list],rax
    ccall gtk_container_add,r14,rax
    ccall g_signal_connect_data,[l_list],l_row_selected,l_selection_changed,0,0,0
    ccall gtk_box_new,1,6
    mov r13,rax
    ccall gtk_paned_pack2,r12,r13,1,0
    ccall gtk_label_new,l_prev_label
    ccall gtk_box_pack_start,r13,rax,0,0,0
    ccall gtk_label_new,core_zero
    mov [l_details],rax
    ccall gtk_box_pack_end,r13,rax,0,0,0
    ccall gtk_scrolled_window_new,0,0
    mov r14,rax
    ccall gtk_box_pack_start,r13,r14,1,1,0
    ccall gtk_text_view_new
    mov [l_preview],rax
    ccall gtk_container_add,r14,rax
    ccall gtk_text_view_set_editable,[l_preview],0
    ccall gtk_text_view_set_cursor_visible,[l_preview],0
    ccall gtk_text_view_set_monospace,[l_preview],1
    ccall gtk_text_view_get_buffer,[l_preview]
    mov [l_buffer],rax
    ccall g_signal_connect_data,[l_window],l_destroy,l_quit,0,0,0
    invoke core_load
    invoke l_refresh
    ccall gtk_widget_show_all,[l_window]
    invoke l_x11_init
    ccall g_timeout_add,12,l_tick,0
    ccall gtk_main
    invoke core_clear
    xor eax,eax
    return
.failure:
    ccall puts,l_no_x11
    mov eax,1
    return

proc l_init_path
    ccall getenv,l_env
    test rax,rax
    jz .default
    ccall snprintf,history_path,4096,l_str_fmt,rax
    return
.default:
    ccall getenv,l_xdg
    test rax,rax
    jz .home
    cmp byte [rax],0
    jne .config
.home:
    ccall getenv,l_home
    test rax,rax
    jz .done
    ccall snprintf,l_path_temp,4096,l_config,rax
    lea rax,[l_path_temp]
.config:
    mov rbx,rax
    ccall mkdir,rbx,0x1c0
    ccall snprintf,history_path,4096,l_path_fmt,rbx
    ccall mkdir,history_path,0x1c0
    ccall snprintf,l_path_temp,4096,l_file_fmt,history_path
    ccall strcpy,history_path,l_path_temp
.done:
    return
proc l_status_set
    ccall gtk_label_set_text,[l_status],rcx
    return
proc l_refresh
    mov qword [l_refreshing],1
.remove:
    ccall gtk_list_box_get_row_at_index,[l_list],0
    test rax,rax
    jz .fill
    ccall gtk_widget_destroy,rax
    jmp .remove
.fill:
    xor r12d,r12d
.loop:
    cmp r12,[history_count]
    jae .done
    lea rax,[history]
    invoke core_display,[rax+r12*8]
    ccall gtk_label_new,rax
    mov r13,rax
    mov rdi,rax
    pxor xmm0,xmm0
    call gtk_label_set_xalign
    ccall gtk_label_set_ellipsize,r13,3
    ccall gtk_container_set_border_width,r13,6
    ccall gtk_list_box_insert,[l_list],r13,-1
    inc r12
    jmp .loop
.done:
    ccall gtk_widget_show_all,[l_list]
    ccall gtk_list_box_get_row_at_index,[l_list],[selected_index]
    ccall gtk_list_box_select_row,[l_list],rax
    mov qword [l_refreshing],0
    invoke l_preview_update
    return
proc l_selection_changed
    cmp qword [l_refreshing],0
    jne .done
    test rsi,rsi
    jz .done
    ccall gtk_list_box_row_get_index,rsi
    cdqe
    mov [selected_index],rax
    invoke l_preview_update
.done:
    return
proc l_preview_update
    invoke core_selected
    test rax,rax
    jz .empty
    mov rbx,rax
    ccall gtk_text_buffer_set_text,[l_buffer],[rbx+E_TEXT],-1
    lea rax,[rbx+E_TIME]
    ccall localtime,rax
    ccall strftime,date_buffer,128,core_date_fmt,rax
    invoke core_length,[rbx+E_TEXT]
    ccall snprintf,details_buffer,1024,core_details_fmt,rax,date_buffer,core_empty
    ccall gtk_label_set_text,[l_details],details_buffer
    return
.empty:
    ccall gtk_text_buffer_set_text,[l_buffer],core_empty,-1
    ccall gtk_label_set_text,[l_details],core_zero
    return
proc l_remove_click
    invoke core_remove,[selected_index]
    invoke core_save
    invoke l_refresh
    invoke l_status_set,core_removed
    return
proc l_clear_click
    invoke core_clear
    invoke core_save
    invoke l_refresh
    invoke l_status_set,core_cleared
    return
proc l_quit
    ccall free,[l_type_ptr]
    mov rbx,[l_display]
    test rbx,rbx
    jz .done
    ccall XDestroyWindow,rbx,[l_requestor]
    ccall XCloseDisplay,rbx
.done:
    ccall gtk_main_quit
    return
proc l_xerror
    mov qword [l_hotkey_failed],1
    xor eax,eax
    return
proc l_x11_init
    ccall XOpenDisplay,0
    mov [l_display],rax
    test rax,rax
    jz .unavailable
    ccall XSetErrorHandler,l_xerror
    ccall XDefaultRootWindow,[l_display]
    mov [l_root],rax
    ccall XCreateSimpleWindow,[l_display],rax,0,0,1,1,0,0,0
    mov [l_requestor],rax
    ccall XInternAtom,[l_display],l_primary,0
    mov [l_atom_primary],rax
    ccall XInternAtom,[l_display],l_utf8,0
    mov [l_atom_utf8],rax
    ccall XInternAtom,[l_display],l_property,0
    mov [l_atom_property],rax
    xor r12d,r12d
.key:
    lea rax,[l_keysyms]
    mov esi,[rax+r12*4]
    ccall XKeysymToKeycode,[l_display],rsi
    movzx ebx,al
    lea rax,[l_keys]
    mov [rax+r12*8],rbx
    ; Grab with CapsLock and NumLock variants as well as plain Ctrl+Alt.
    xor r13d,r13d
.locks:
    lea rax,[l_modifiers]
    mov edx,[rax+r13*4]
    ccall XGrabKey,[l_display],rbx,rdx,[l_root],1,1,1
    inc r13
    cmp r13,4
    jb .locks
    inc r12
    cmp r12,3
    jb .key
    ccall XFlush,[l_display]
    return
.unavailable:
    invoke l_status_set,l_no_x11
    return

proc l_tick
    mov rbx,[l_display]
    test rbx,rbx
    jz .done
    cmp qword [l_hotkey_failed],0
    je .pending
    mov qword [l_hotkey_failed],0
    invoke l_status_set,l_hotkey_error
.pending:
    ccall XPending,rbx
    test eax,eax
    jz .timeout
    ccall XNextEvent,rbx,l_event
    cmp dword [l_event],2
    je .key
    cmp dword [l_event],31
    je .selection
    jmp .pending
.key:
    mov eax,[l_event+80]
    and eax,12
    cmp eax,12
    jne .pending
    mov eax,[l_event+84]
    cmp rax,[l_keys]
    je .capture
    cmp rax,[l_keys+8]
    je .type
    cmp rax,[l_keys+16]
    jne .pending
    invoke l_stop
    jmp .pending
.capture:
    ccall XConvertSelection,rbx,[l_atom_primary],[l_atom_utf8],[l_atom_property],[l_requestor],0
    ccall XFlush,rbx
    ccall g_get_monotonic_time
    add rax,2000000
    mov [l_deadline],rax
    jmp .pending
.type:
    invoke l_start
    jmp .pending
.selection:
    cmp qword [l_deadline],0
    je .pending
    mov qword [l_deadline],0
    cmp qword [l_event+56],0
    je .no_selection
    lea rax,[rbp-64]
    lea rcx,[rbp-72]
    lea rdx,[rbp-80]
    lea r8,[rbp-88]
    lea r9,[rbp-96]
    mov qword [rbp-96],0
    ccall XGetWindowProperty,rbx,[l_requestor],[l_atom_property],0,1048576,1,0,rax,rcx,rdx,r8,r9
    test eax,eax
    jnz .no_selection
    mov r12,[rbp-96]
    test r12,r12
    jz .no_selection
    cmp dword [rbp-72],8
    jne .free_selection
    cmp qword [rbp-88],0
    jne .free_selection
    invoke core_new,r12
    invoke core_add,rax
    invoke core_save
    invoke l_refresh
    invoke core_selected
    test rax,rax
    jz .free_selection
    invoke core_length,[rax+E_TEXT]
    ccall snprintf,status_buffer,1024,core_capture_fmt,rax,core_text,l_source
    invoke l_status_set,status_buffer
.free_selection:
    ccall XFree,r12
    jmp .pending
.no_selection:
    invoke l_status_set,core_no_selection
    jmp .pending
.timeout:
    cmp qword [l_deadline],0
    je .typing
    ccall g_get_monotonic_time
    cmp rax,[l_deadline]
    jb .typing
    mov qword [l_deadline],0
    invoke l_status_set,l_timeout
.typing:
    invoke l_type_tick
.done:
    mov eax,1
    return
proc l_start
    cmp qword [l_typing],0
    jne .done
    invoke core_selected
    test rax,rax
    jz .empty
    invoke core_strdup,[rax+E_TEXT]
    test rax,rax
    jz .done
    mov [l_type_ptr],rax
    invoke core_length,rax
    mov [l_type_length],rax
    mov qword [l_type_index],0
    mov qword [l_typing],1
    ccall g_get_monotonic_time
    add rax,120000
    mov [l_type_start],rax
    invoke l_status_set,core_release
    jmp .done
.empty:
    invoke l_status_set,core_no_item
.done:
    return
proc l_stop
    cmp qword [l_typing],0
    je .done
    mov qword [l_typing],0
    ccall free,[l_type_ptr]
    mov qword [l_type_ptr],0
    invoke l_status_set,core_stopped
.done:
    return
proc l_type_tick
    cmp qword [l_typing],0
    je .done
    ccall g_get_monotonic_time
    cmp rax,[l_type_start]
    jb .done
    mov rbx,[l_display]
    mov rax,[l_type_ptr]
    mov rdx,[l_type_index]
    movzx r12d,byte [rax+rdx]
    test r12d,r12d
    jz .finished
    cmp r12d,127
    jae .unsupported
    xor r13d,r13d
    cmp r12d,13
    je .enter
    cmp r12d,10
    je .enter
    cmp r12d,9
    je .tab
    cmp r12d,'A'
    jb .punct
    cmp r12d,'Z'
    ja .punct
    add r12d,32
    mov r13d,1
    jmp .send
.punct:
    lea rsi,[l_shifted]
    xor ecx,ecx
.search:
    mov al,[rsi+rcx]
    test al,al
    jz .send
    cmp al,r12b
    je .shift
    inc rcx
    jmp .search
.shift:
    lea rax,[l_unshifted]
    movzx r12d,byte [rax+rcx]
    mov r13d,1
    jmp .send
.enter:
    mov r12d,0xff0d
    jmp .send
.tab:
    mov r12d,0xff09
.send:
    ccall XKeysymToKeycode,rbx,r12
    movzx r14d,al
    test r14d,r14d
    jz .unsupported
    ccall XKeysymToKeycode,rbx,0xffe1
    movzx r15d,al
    test r13d,r13d
    jz .key
    ccall XTestFakeKeyEvent,rbx,r15,1,0
.key:
    ccall XTestFakeKeyEvent,rbx,r14,1,0
    ccall XTestFakeKeyEvent,rbx,r14,0,0
    test r13d,r13d
    jz .flush
    ccall XTestFakeKeyEvent,rbx,r15,0,0
.flush:
    ccall XFlush,rbx
    inc qword [l_type_index]
    ccall snprintf,status_buffer,1024,core_type_fmt,[l_type_index],[l_type_length]
    invoke l_status_set,status_buffer
    jmp .done
.finished:
    invoke l_stop
    ccall snprintf,status_buffer,1024,core_typed_fmt,[l_type_length]
    invoke l_status_set,status_buffer
    jmp .done
.unsupported:
    invoke l_stop
    invoke l_status_set,l_unsupported
.done:
    return
section .data
l_keysyms dd 'c','v','x'
l_modifiers dd 12,14,28,30
%include "core.inc"
section .note.GNU-stack noalloc noexec nowrite progbits
