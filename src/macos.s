; Intel macOS: Cocoa through the Objective-C runtime, AX, and Core Graphics.
; NASM --prefix _ emits the Mach-O external-symbol convention.
%include "abi.inc"
%include "crt.inc"
extern mkdir
extern objc_getClass,sel_registerName,objc_msgSend,objc_allocateClassPair
extern objc_registerClassPair,class_addMethod
extern AXIsProcessTrusted,AXUIElementCreateSystemWide,AXUIElementCopyAttributeValue
extern CFStringCreateWithCString,CFStringGetLength,CFStringGetCString,CFStringGetCharacters
extern CFRelease,CFMachPortCreateRunLoopSource,CFRunLoopGetCurrent,CFRunLoopAddSource
extern kCFRunLoopCommonModes
extern fflush
extern CGEventTapCreate,CGEventTapEnable,CGEventGetFlags,CGEventGetIntegerValueField
extern CGEventCreateKeyboardEvent,CGEventKeyboardSetUnicodeString,CGEventPost
section .data
m_title db 'Copy Pasta ASM',0
m_NSObject db 'NSObject',0
m_NSApplication db 'NSApplication',0
m_NSWindow db 'NSWindow',0
m_NSButton db 'NSButton',0
m_NSTextField db 'NSTextField',0
m_NSScrollView db 'NSScrollView',0
m_NSTextView db 'NSTextView',0
m_NSTableView db 'NSTableView',0
m_NSTableColumn db 'NSTableColumn',0
m_NSString db 'NSString',0
m_NSFont db 'NSFont',0
m_NSColor db 'NSColor',0
m_NSFontManager db 'NSFontManager',0
m_NSTimer db 'NSTimer',0
m_NSPool db 'NSAutoreleasePool',0
m_NSSplitView db 'NSSplitView',0
m_NSView db 'NSView',0
m_delegate_name db 'CopyPastaAssemblyDelegate',0
m_alloc db 'alloc',0
m_init db 'init',0
m_release db 'release',0
m_shared db 'sharedApplication',0
m_set_policy db 'setActivationPolicy:',0
m_set_title db 'setTitle:',0
m_frame db 'initWithFrame:',0
m_window_init db 'initWithContentRect:styleMask:backing:defer:',0
m_content db 'contentView',0
m_add db 'addSubview:',0
m_center db 'center',0
m_show db 'makeKeyAndOrderFront:',0
m_activate db 'activateIgnoringOtherApps:',0
m_run db 'run',0
m_terminate db 'terminate:',0
m_set_delegate db 'setDelegate:',0
m_set_target db 'setTarget:',0
m_set_action db 'setAction:',0
m_set_bezel db 'setBezelStyle:',0
m_set_string db 'setString:',0
m_set_value db 'setStringValue:',0
m_utf8 db 'stringWithUTF8String:',0
m_editable db 'setEditable:',0
m_selectable db 'setSelectable:',0
m_bordered db 'setBordered:',0
m_background db 'setDrawsBackground:',0
m_autoresize db 'setAutoresizingMask:',0
m_set_doc db 'setDocumentView:',0
m_vertical db 'setHasVerticalScroller:',0
m_horizontal db 'setHasHorizontalScroller:',0
m_column_init db 'initWithIdentifier:',0
m_add_column db 'addTableColumn:',0
m_data_source db 'setDataSource:',0
m_header db 'setHeaderView:',0
m_reload db 'reloadData',0
m_selected db 'selectedRow',0
m_select_indexes db 'selectRowIndexes:byExtendingSelection:',0
m_index_set_class db 'NSIndexSet',0
m_index_set db 'indexSetWithIndex:',0
m_font_name db 'fontWithName:size:',0
m_font_system db 'monospacedSystemFontOfSize:weight:',0
m_set_font db 'setFont:',0
m_get_string db 'string',0
m_get_utf8 db 'UTF8String',0
m_set_width db 'setWidth:',0
m_shared_font_manager db 'sharedFontManager',0
m_convert_font db 'convertFont:toHaveTrait:',0
m_color_rgb db 'colorWithCalibratedRed:green:blue:alpha:',0
m_text_color db 'setTextColor:',0
m_background_color db 'setBackgroundColor:',0
m_color_scale dq 255.0
m_set_vertical db 'setVertical:',0
m_divider_style db 'setDividerStyle:',0
m_split_position db 'setPosition:ofDividerAtIndex:',0
m_min_size db 'setMinSize:',0
m_remove_sel db 'removeItem:',0
m_clear_sel db 'clearItems:',0
m_tick_sel db 'tick:',0
m_rows_sel db 'numberOfRowsInTableView:',0
m_value_sel db 'tableView:objectValueForTableColumn:row:',0
m_change_sel db 'tableViewSelectionDidChange:',0
m_close_sel db 'windowWillClose:',0
m_void_enc db 'v@:@',0
m_rows_enc db 'q@:@',0
m_value_enc db '@@:@@q',0
m_timer_sel db 'scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:',0
m_remove db 'Remove',0
m_clear db 'Clear',0
m_help db 'Ctrl+Alt+C capture | Ctrl+Alt+V type | Ctrl+Alt+X stop',0
m_history_label db 'History',0
m_preview_label db 'Selected text',0
m_consolas db 'Menlo',0
m_env db 'COPY_PASTA_HISTORY',0
m_home db 'HOME',0
m_dir_fmt db '%s/Library/Application Support/CopyPastaAsm',0
m_file_fmt db '%s/history.json',0
m_str_fmt db '%s',0
m_testarg db '--self-test',0
m_permission db 'macOS Accessibility permission is required for hotkeys, capture, and typing.',0
m_tap_error db 'Could not create keyboard event tap. Check Accessibility/Input Monitoring permissions.',0
m_source db 'macOS Accessibility',0
m_ax_focus db 'AXFocusedUIElement',0
m_ax_selection db 'AXSelectedText',0
m_app dq 0
m_window dq 0
m_content_view dq 0
m_root_view dq 0
m_left_view dq 0
m_right_view dq 0
m_split_view dq 0
m_delegate dq 0
m_table dq 0
m_preview dq 0
m_details dq 0
m_status dq 0
m_tap dq 0
m_run_source dq 0
m_cf_focus dq 0
m_cf_selection dq 0
m_typing dq 0
m_type_ptr dq 0
m_type_index dq 0
m_type_length dq 0
m_wait_ticks dq 0
section .bss
m_path_temp resb 4096
m_char resw 1
section .text
global main
proc main
    mov r12,rdi
    mov r13,rsi
    invoke m_init_path
    cmp r12,2
    jb .gui
    ccall strcmp,[r13+8],m_testarg
    test eax,eax
    jnz .gui
    invoke core_self_test
    return
.gui:
    invoke m_class,m_NSPool
    invoke m_send,rax,m_alloc,0,0
    invoke m_send,rax,m_init,0,0
    mov r15,rax
    invoke m_class,m_NSApplication
    invoke m_send,rax,m_shared,0,0
    mov [m_app],rax
    invoke m_send,rax,m_set_policy,0,0
    invoke m_make_delegate
    invoke m_class,m_NSWindow
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_window_init,0,0,980,620,15
    mov [m_window],rax
    invoke m_string,m_title
    invoke m_send,[m_window],m_set_title,rax,0
    invoke m_send,[m_window],m_set_delegate,[m_delegate],0
    invoke m_send,[m_window],m_content,0,0
    mov [m_content_view],rax
    mov [m_root_view],rax
    invoke m_make_split
    ; Cocoa coordinates start at the bottom left.
    invoke m_button,m_remove,10,574,m_remove_sel
    invoke m_button,m_clear,100,574,m_clear_sel
    invoke m_label,m_help,190,580,770,24
    mov rax,[m_left_view]
    mov [m_content_view],rax
    invoke m_label,m_history_label,0,502,360,24
    mov rax,[m_right_view]
    mov [m_content_view],rax
    invoke m_label,m_preview_label,0,502,592,24
    mov rax,[m_root_view]
    mov [m_content_view],rax
    invoke m_label,core_ready,8,4,960,24
    mov [m_status],rax
    mov rax,[m_right_view]
    mov [m_content_view],rax
    invoke m_label,core_zero,0,0,592,24
    mov [m_details],rax
    invoke m_class,m_NSScrollView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,0,0,360,496,0
    mov r12,rax
    invoke m_send,r12,m_vertical,1,0
    invoke m_send,r12,m_autoresize,18,0
    invoke m_send,[m_left_view],m_add,r12,0
    invoke m_class,m_NSTableView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,0,0,360,502,0
    mov [m_table],rax
    invoke m_send,rax,m_header,0,0
    invoke m_send,[m_table],m_data_source,[m_delegate],0
    invoke m_send,[m_table],m_set_delegate,[m_delegate],0
    invoke m_class,m_NSTableColumn
    invoke m_send,rax,m_alloc,0,0
    mov r13,rax
    invoke m_string,m_history_label
    invoke m_send,r13,m_column_init,rax,0
    mov r13,rax
    ccall sel_registerName,m_set_width
    mov rdi,r13
    mov rsi,rax
    mov eax,340
    cvtsi2sd xmm0,eax
    call objc_msgSend
    mov rax,r13
    invoke m_send,[m_table],m_add_column,rax,0
    invoke m_send,r12,m_set_doc,[m_table],0
    invoke m_class,m_NSScrollView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,0,34,592,462,0
    mov r12,rax
    invoke m_send,r12,m_vertical,1,0
    invoke m_send,r12,m_horizontal,1,0
    invoke m_send,r12,m_autoresize,18,0
    invoke m_send,[m_right_view],m_add,r12,0
    invoke m_class,m_NSTextView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,0,0,580,468,0
    mov [m_preview],rax
    invoke m_send,rax,m_editable,0,0
    invoke m_send,[m_preview],m_selectable,1,0
    invoke m_send,r12,m_set_doc,[m_preview],0
    invoke m_class,m_NSFont
    mov r12,rax
    ccall sel_registerName,m_font_system
    mov rsi,rax
    mov rdi,r12
    mov rax,0x402a000000000000
    movq xmm0,rax
    pxor xmm1,xmm1
    call objc_msgSend
    invoke m_send,[m_preview],m_set_font,rax,0
    invoke core_load
    invoke m_refresh
    invoke m_send,[m_preview],m_get_string,0,0
    invoke m_send,rax,m_get_utf8,0,0
    ccall puts,rax
    ccall fflush,0
    invoke m_send,[m_window],m_center,0,0
    invoke m_send,[m_window],m_show,0,0
    invoke m_send,[m_app],m_activate,1,0
    invoke m_accessibility_init
    invoke m_class,m_NSTimer
    mov r12,rax
    ccall sel_registerName,m_tick_sel
    mov r13,rax
    ccall sel_registerName,m_timer_sel
    mov rsi,rax
    mov rdi,r12
    mov rdx,[m_delegate]
    mov rcx,r13
    xor r8d,r8d
    mov r9d,1
    mov rax,0x3f889374bc6a7efa ; 0.012 seconds
    movq xmm0,rax
    call objc_msgSend
    invoke m_send,[m_app],m_run,0,0
    invoke m_send,r15,m_release,0,0
    xor eax,eax
    return

proc m_class
    ccall objc_getClass,rcx
    return
proc m_make_split
    invoke m_class,m_NSSplitView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,10,32,960,526,0
    mov [m_split_view],rax
    invoke m_send,rax,m_set_vertical,1,0
    invoke m_send,[m_split_view],m_divider_style,1,0
    invoke m_send,[m_split_view],m_autoresize,18,0
    invoke m_send,[m_root_view],m_add,[m_split_view],0
    invoke m_class,m_NSView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,0,0,360,526,0
    mov [m_left_view],rax
    invoke m_send,[m_split_view],m_add,rax,0
    invoke m_class,m_NSView
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,368,0,592,526,0
    mov [m_right_view],rax
    invoke m_send,[m_split_view],m_add,rax,0
    ccall sel_registerName,m_split_position
    mov rsi,rax
    mov rdi,[m_split_view]
    xor edx,edx
    mov eax,360
    cvtsi2sd xmm0,eax
    call objc_msgSend
    ccall sel_registerName,m_min_size
    mov rsi,rax
    mov rdi,[m_window]
    mov eax,760
    cvtsi2sd xmm0,eax
    mov eax,480
    cvtsi2sd xmm1,eax
    call objc_msgSend
    return
; Internal ABI -> Objective-C dispatch; selectors registered on demand.
proc m_send
    mov rbx,rcx
    mov r12,r8
    mov r13,r9
    mov r14,[rbp+48]
    mov r15,[rbp+56]
    ccall sel_registerName,rdx
    ccall objc_msgSend,rbx,rax,r12,r13,r14,r15
    return
proc m_string
    mov rbx,rcx
    invoke m_class,m_NSString
    invoke m_send,rax,m_utf8,rbx,0
    return
; NSRect is a 32-byte aggregate passed on the x64 stack (not XMM arguments).
proc m_rect
    mov rbx,rcx
    mov r12,r8
    mov r13,r9
    mov r14,[rbp+48]
    mov r15,[rbp+56]
    mov rax,[rbp+64]
    mov [rbp-64],rax
    ccall sel_registerName,rdx
    mov rsi,rax
    mov rdi,rbx
    cvtsi2sd xmm0,r12
    movq [rsp],xmm0
    cvtsi2sd xmm0,r13
    movq [rsp+8],xmm0
    cvtsi2sd xmm0,r14
    movq [rsp+16],xmm0
    cvtsi2sd xmm0,r15
    movq [rsp+24],xmm0
    mov rdx,[rbp-64]
    mov ecx,2
    xor r8d,r8d
    call objc_msgSend
    return
proc m_button
    mov rbx,rcx
    mov r12,rdx
    mov r13,r8
    mov r14,r9
    invoke m_class,m_NSButton
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,r12,r13,82,32,0
    mov r15,rax
    invoke m_string,rbx
    invoke m_send,r15,m_set_title,rax,0
    invoke m_send,r15,m_set_bezel,1,0
    invoke m_send,r15,m_set_target,[m_delegate],0
    ccall sel_registerName,r14
    invoke m_send,r15,m_set_action,rax,0
    invoke m_send,r15,m_autoresize,8,0
    invoke m_send,[m_content_view],m_add,r15,0
    mov rax,r15
    return
proc m_label
    mov rbx,rcx
    mov r12,rdx
    mov r13,r8
    mov r14,r9
    mov r15,[rbp+48]
    invoke m_class,m_NSTextField
    invoke m_send,rax,m_alloc,0,0
    invoke m_rect,rax,m_frame,r12,r13,r14,r15,0
    mov r15,rax
    invoke m_string,rbx
    invoke m_send,r15,m_set_value,rax,0
    invoke m_send,r15,m_editable,0,0
    invoke m_send,r15,m_bordered,0,0
    invoke m_send,r15,m_background,0,0
    mov r12,2
    cmp r13,500
    jb .anchor
    or r12,8
.anchor:
    invoke m_send,r15,m_autoresize,r12,0
    invoke m_send,[m_content_view],m_add,r15,0
    mov rax,r15
    return
proc m_make_delegate
    invoke m_class,m_NSObject
    ccall objc_allocateClassPair,rax,m_delegate_name,0
    mov rbx,rax
    ccall sel_registerName,m_remove_sel
    ccall class_addMethod,rbx,rax,m_remove_click,m_void_enc
    ccall sel_registerName,m_clear_sel
    ccall class_addMethod,rbx,rax,m_clear_click,m_void_enc
    ccall sel_registerName,m_tick_sel
    ccall class_addMethod,rbx,rax,m_tick,m_void_enc
    ccall sel_registerName,m_rows_sel
    ccall class_addMethod,rbx,rax,m_rows,m_rows_enc
    ccall sel_registerName,m_value_sel
    ccall class_addMethod,rbx,rax,m_value,m_value_enc
    ccall sel_registerName,m_change_sel
    ccall class_addMethod,rbx,rax,m_selection_changed,m_void_enc
    ccall sel_registerName,m_close_sel
    ccall class_addMethod,rbx,rax,m_close,m_void_enc
    ccall objc_registerClassPair,rbx
    invoke m_send,rbx,m_alloc,0,0
    invoke m_send,rax,m_init,0,0
    mov [m_delegate],rax
    return
proc m_init_path
    ccall getenv,m_env
    test rax,rax
    jz .default
    ccall snprintf,history_path,4096,m_str_fmt,rax
    return
.default:
    ccall getenv,m_home
    test rax,rax
    jz .done
    ccall snprintf,m_path_temp,4096,m_dir_fmt,rax
    ccall mkdir,m_path_temp,0x1c0
    ccall snprintf,history_path,4096,m_file_fmt,m_path_temp
.done:
    return
proc m_status_set
    invoke m_string,rcx
    invoke m_send,[m_status],m_set_value,rax,0
    return
proc m_rows
    mov rax,[history_count]
    return
proc m_value
    cmp r8,[history_count]
    jae .empty
    lea rax,[history]
    invoke core_display,[rax+r8*8]
    invoke m_string,rax
    return
.empty:
    invoke m_string,core_empty
    return
proc m_refresh
    invoke m_send,[m_table],m_reload,0,0
    cmp qword [selected_index],0
    jl .preview
    invoke m_class,m_index_set_class
    invoke m_send,rax,m_index_set,[selected_index],0
    invoke m_send,[m_table],m_select_indexes,rax,0
.preview:
    invoke m_preview_update
    return
proc m_selection_changed
    invoke m_send,[m_table],m_selected,0,0
    mov [selected_index],rax
    invoke m_preview_update
    return
proc m_preview_update
    invoke core_selected
    test rax,rax
    jz .empty
    mov rbx,rax
    invoke m_string,[rbx+E_TEXT]
    invoke m_send,[m_preview],m_set_string,rax,0
    invoke m_apply_style,rbx
    lea rax,[rbx+E_TIME]
    ccall localtime,rax
    ccall strftime,date_buffer,128,core_date_fmt,rax
    invoke core_style_details,rbx
    mov r12,rax
    invoke core_length,[rbx+E_TEXT]
    ccall snprintf,details_buffer,1024,core_details_fmt,rax,date_buffer,r12
    invoke m_string,details_buffer
    invoke m_send,[m_details],m_set_value,rax,0
    return
.empty:
    invoke m_string,core_empty
    invoke m_send,[m_preview],m_set_string,rax,0
    invoke m_string,core_zero
    invoke m_send,[m_details],m_set_value,rax,0
    invoke m_apply_style,0
    return
proc m_apply_style
    mov rbx,rcx
    lea rcx,[m_consolas]
    mov r12,0x402a000000000000
    test rbx,rbx
    jz .font
    test qword [rbx+E_FLAGS],F_FONT
    jz .size
    mov rcx,[rbx+E_FONT]
.size:
    test qword [rbx+E_FLAGS],F_SIZE
    jz .font
    mov r12,[rbx+E_SIZE]
.font:
    invoke m_string,rcx
    mov r13,rax
    invoke m_class,m_NSFont
    mov r14,rax
    ccall sel_registerName,m_font_name
    mov rdi,r14
    mov rsi,rax
    mov rdx,r13
    movq xmm0,r12
    call objc_msgSend
    test rax,rax
    jnz .traits
    ccall sel_registerName,m_font_system
    mov rdi,r14
    mov rsi,rax
    movq xmm0,r12
    pxor xmm1,xmm1
    call objc_msgSend
.traits:
    mov r15,rax
    xor r12d,r12d
    test rbx,rbx
    jz .set
    cmp qword [rbx+E_WEIGHT],700
    jl .italic
    or r12d,2
.italic:
    cmp qword [rbx+E_ITALIC],0
    je .convert
    or r12d,1
.convert:
    test r12,r12
    jz .set
    invoke m_class,m_NSFontManager
    invoke m_send,rax,m_shared_font_manager,0,0
    invoke m_send,rax,m_convert_font,r15,r12
    mov r15,rax
.set:
    invoke m_send,[m_preview],m_set_font,r15,0
    xor ecx,ecx
    test rbx,rbx
    jz .fg
    test qword [rbx+E_FLAGS],F_FG
    jz .fg
    mov ecx,[rbx+E_FG]
.fg:
    invoke m_color,rcx
    invoke m_send,[m_preview],m_text_color,rax,0
    mov ecx,0xffffff
    test rbx,rbx
    jz .bg
    test qword [rbx+E_FLAGS],F_BG
    jz .bg
    mov ecx,[rbx+E_BG]
.bg:
    invoke m_color,rcx
    invoke m_send,[m_preview],m_background_color,rax,0
    return
proc m_color
    mov rbx,rcx
    invoke m_class,m_NSColor
    mov r12,rax
    ccall sel_registerName,m_color_rgb
    mov rsi,rax
    mov rdi,r12
    movzx eax,bl
    cvtsi2sd xmm0,eax
    divsd xmm0,[m_color_scale]
    shr ebx,8
    movzx eax,bl
    cvtsi2sd xmm1,eax
    divsd xmm1,[m_color_scale]
    shr ebx,8
    movzx eax,bl
    cvtsi2sd xmm2,eax
    divsd xmm2,[m_color_scale]
    mov rax,0x3ff0000000000000
    movq xmm3,rax
    call objc_msgSend
    return
proc m_remove_click
    invoke core_remove,[selected_index]
    invoke core_save
    invoke m_refresh
    invoke m_status_set,core_removed
    return
proc m_clear_click
    invoke core_clear
    invoke core_save
    invoke m_refresh
    invoke m_status_set,core_cleared
    return
proc m_close
    invoke m_stop
    mov rbx,[m_tap]
    test rbx,rbx
    jz .done
    ccall CGEventTapEnable,rbx,0
    ccall CFRelease,rbx
    ccall CFRelease,[m_run_source]
.done:
    invoke core_clear
    invoke m_send,[m_app],m_terminate,0,0
    return
proc m_accessibility_init
    ccall CFStringCreateWithCString,0,m_ax_focus,0x08000100
    mov [m_cf_focus],rax
    ccall CFStringCreateWithCString,0,m_ax_selection,0x08000100
    mov [m_cf_selection],rax
    ccall AXIsProcessTrusted
    test al,al
    jz .permission
    ccall CGEventTapCreate,0,0,0,1024,m_event_tap,0
    mov [m_tap],rax
    test rax,rax
    jz .failed
    ccall CFMachPortCreateRunLoopSource,0,rax,0
    mov [m_run_source],rax
    test rax,rax
    jz .failed
    ccall CFRunLoopGetCurrent
    mov rdx,[rel kCFRunLoopCommonModes wrt ..gotpcrel]
    mov rdx,[rdx]
    ccall CFRunLoopAddSource,rax,[m_run_source],rdx
    ccall CGEventTapEnable,[m_tap],1
    return
.permission:
    invoke m_status_set,m_permission
    return
.failed:
    invoke m_status_set,m_tap_error
    return
proc m_event_tap
    mov rbx,rdx
    cmp esi,0xfffffffe
    je .enable
    cmp esi,0xffffffff
    je .enable
    cmp esi,10
    jne .passthrough
    ccall CGEventGetFlags,rbx
    and eax,0xc0000
    cmp eax,0xc0000
    jne .passthrough
    ccall CGEventGetIntegerValueField,rbx,9
    cmp eax,8
    je .capture
    cmp eax,9
    je .type
    cmp eax,7
    jne .passthrough
    invoke m_stop
    jmp .consume
.capture:
    invoke m_capture
    test rax,rax
    jz .none
    invoke core_add,rax
    invoke core_save
    invoke m_refresh
    invoke core_selected
    test rax,rax
    jz .none
    invoke core_length,[rax+E_TEXT]
    ccall snprintf,status_buffer,1024,core_capture_fmt,rax,core_text,m_source
    invoke m_status_set,status_buffer
    jmp .consume
.none:
    invoke m_status_set,core_no_selection
    jmp .consume
.type:
    invoke m_start
.consume:
    xor eax,eax
    return
.enable:
    ccall CGEventTapEnable,[m_tap],1
.passthrough:
    mov rax,rbx
    return
proc m_capture
    ccall AXUIElementCreateSystemWide
    mov rbx,rax
    xor r15d,r15d
    mov qword [rbp-64],0
    mov qword [rbp-72],0
    lea rdx,[rbp-64]
    ccall AXUIElementCopyAttributeValue,rbx,[m_cf_focus],rdx
    test eax,eax
    jnz .system_end
    mov r12,[rbp-64]
    lea rdx,[rbp-72]
    ccall AXUIElementCopyAttributeValue,r12,[m_cf_selection],rdx
    test eax,eax
    jnz .focus_end
    mov r13,[rbp-72]
    ccall CFStringGetLength,r13
    lea r14,[rax*4+1]
    ccall malloc,r14
    test rax,rax
    jz .selection_end
    mov [rbp-80],rax
    ccall CFStringGetCString,r13,rax,r14,0x08000100
    test al,al
    jz .free
    invoke core_blank,[rbp-80]
    test eax,eax
    jnz .free
    invoke core_new,[rbp-80]
    mov r15,rax
.free:
    ccall free,[rbp-80]
.selection_end:
    ccall CFRelease,r13
.focus_end:
    ccall CFRelease,r12
.system_end:
    ccall CFRelease,rbx
    mov rax,r15
    return
proc m_start
    cmp qword [m_typing],0
    jne .done
    invoke core_selected
    test rax,rax
    jz .empty
    ccall CFStringCreateWithCString,0,[rax+E_TEXT],0x08000100
    mov rbx,rax
    test rbx,rbx
    jz .done
    ccall CFStringGetLength,rbx
    mov [m_type_length],rax
    lea rax,[rax*2+2]
    ccall malloc,rax
    mov [m_type_ptr],rax
    test rax,rax
    jz .release
    ; CFRange {location,length} is two integer register arguments on x64.
    ccall CFStringGetCharacters,rbx,0,[m_type_length],rax
    mov qword [m_typing],1
    mov qword [m_type_index],0
    mov qword [m_wait_ticks],10
    invoke m_status_set,core_release
.release:
    ccall CFRelease,rbx
    jmp .done
.empty:
    invoke m_status_set,core_no_item
.done:
    return
proc m_stop
    cmp qword [m_typing],0
    je .done
    ccall free,[m_type_ptr]
    mov qword [m_type_ptr],0
    mov qword [m_typing],0
    invoke m_status_set,core_stopped
.done:
    return
proc m_tick
    cmp qword [m_typing],0
    je .done
    cmp qword [m_wait_ticks],0
    je .type
    dec qword [m_wait_ticks]
    jmp .done
.type:
    mov rbx,[m_type_index]
    cmp rbx,[m_type_length]
    jae .finished
    mov rax,[m_type_ptr]
    mov ax,[rax+rbx*2]
    mov [m_char],ax
    ccall CGEventCreateKeyboardEvent,0,0,1
    mov r12,rax
    ccall CGEventCreateKeyboardEvent,0,0,0
    mov r13,rax
    test r12,r12
    jz .failed
    test r13,r13
    jz .failed
    ccall CGEventKeyboardSetUnicodeString,r12,1,m_char
    ccall CGEventKeyboardSetUnicodeString,r13,1,m_char
    ccall CGEventPost,0,r12
    ccall CGEventPost,0,r13
    ccall CFRelease,r12
    ccall CFRelease,r13
    inc qword [m_type_index]
    ccall snprintf,status_buffer,1024,core_type_fmt,[m_type_index],[m_type_length]
    invoke m_status_set,status_buffer
    jmp .done
.finished:
    invoke m_stop
    ccall snprintf,status_buffer,1024,core_typed_fmt,[m_type_length]
    invoke m_status_set,status_buffer
    jmp .done
.failed:
    test r12,r12
    jz .free_up
    ccall CFRelease,r12
.free_up:
    test r13,r13
    jz .error
    ccall CFRelease,r13
.error:
    invoke m_stop
    invoke m_status_set,core_failed
.done:
    return
%include "core.inc"
