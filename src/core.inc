; Shared history, UTF-8 processing and JSON persistence; no compiler output.
; Entry/text/font ownership belongs to the history. Typing takes a snapshot.
section .data
history_count dq 0
selected_index dq -1
history times MAX_ITEMS dq 0
history_path times 4096 db 0
history_temp_path times 4128 db 0
core_temp_fmt db '%s.tmp',0
status_buffer times 1024 db 0
display_buffer times 1024 db 0
date_buffer times 128 db 0
details_buffer times 1024 db 0
core_empty db 0
core_ready db 'Ready',0
core_no_selection db 'No supported selection found.',0
core_no_item db 'No history item selected.',0
core_release db 'Release Ctrl+Alt+V to continue.',0
core_stopped db 'Typing stopped.',0
core_failed db 'Typing failed: the operating system rejected keyboard input.',0
core_removed db 'Removed history item.',0
core_cleared db 'History cleared.',0
core_save_failed db 'Could not save history. Check the application data directory.',0
core_capture_fmt db 'Captured %u character %s item from %s.',0
core_type_fmt db 'Typing %u/%u characters...',0
core_typed_fmt db 'Typed %u characters.',0
core_details_fmt db '%u characters captured %s%s',0
core_zero db '0 characters',0
core_style_buffer times 1024 db 0
core_style_number times 64 db 0
core_style_first db ' | ',0
core_style_next db ', ',0
core_style_fmt db '%s%s',0
core_style_pt db '%u pt',0
core_bold db 'bold',0
core_italic db 'italic',0
core_text db 'text',0
core_rich db 'rich text',0
core_rich_prefix db '[Rich text] ',0
core_display_fmt db '%s  %s%s',0
core_whitespace db '(whitespace)',0
core_date_fmt db '%x %H:%M',0
core_iso_fmt db '%Y-%m-%dT%H:%M:%SZ',0
core_iso_base_fmt db '%Y-%m-%dT%H:%M:%S',0
core_iso_precise_fmt db '%s.%07uZ',0
core_file_read db 'rb',0
core_file_write db 'wb',0
core_json_open db '[',10,0
core_json_close db 10,']',10,0
core_json_entry db '  {"Text":',0
core_json_date db ',"CapturedAt":',0
core_json_style db ',"Style":{',0
core_json_endstyle db '}',0
core_json_end db '}',0
core_json_comma db ',',10,0
core_json_font db '"FontName":',0
core_json_size db ',"FontSize":',0
core_json_weight db ',"FontWeight":',0
core_json_italic db ',"IsItalic":',0
core_json_fg db ',"ForegroundColor":',0
core_json_bg db ',"BackgroundColor":',0
core_json_null db 'null',0
core_json_true db 'true',0
core_json_false db 'false',0
core_json_int db '%lld',0
core_json_float db '%.17g',0
core_key_text db 'Text',0
core_key_date db 'CapturedAt',0
core_key_style db 'Style',0
core_key_font db 'FontName',0
core_key_size db 'FontSize',0
core_key_weight db 'FontWeight',0
core_key_italic db 'IsItalic',0
core_key_fg db 'ForegroundColor',0
core_key_bg db 'BackgroundColor',0
core_iso_scan db '%d-%d-%dT%d:%d:%d',0
core_hex db '0123456789abcdef',0
core_test_text db 'Hello',13,10,'assembly ',0xc3,0xa9,' ',0xf0,0x9f,0x8d,0x9d,9,'"\',0
core_test_other db 'Another item',0
core_test_font db 'Consolas',0
core_test_fmt db 'item %u',0
core_test_ok db 'PASS: history, promotion, style identity, cap, removal, Unicode length, JSON round trip',0
core_test_bad db 'FAIL: core assembly self-test',0
section .bss
json_cursor resq 1
json_end resq 1
json_error resq 1
json_token resb 1048577
section .text

proc core_strdup
    mov rbx,rcx
    ccall strlen,rbx
    lea r12,[rax+1]
    ccall malloc,r12
    test rax,rax
    jz .done
    mov r13,rax
    ccall memcpy,r13,rbx,r12
    mov rax,r13
.done:
    return

; Returns UTC epoch seconds in RAX and 100 ns fractional ticks in RDX.
proc core_now
%ifdef WINDOWS
    lea r12,[rbp-80]
    invoke GetSystemTimePreciseAsFileTime,r12
    mov rax,[r12]
    mov r11,0x19db1ded53e8000
    sub rax,r11
    mov r11,10000000
    xor edx,edx
    div r11
%else
    lea r12,[rbp-80]
    ccall gettimeofday,r12,0
    test eax,eax
    jnz .fallback
    mov rax,[r12]
    mov rdx,[r12+8]
    imul rdx,10
    return
.fallback:
    ccall time_fn,0
    xor edx,edx
%endif
    return

proc core_new
    mov rbx,rcx
    ccall calloc,1,E_BYTES
    test rax,rax
    jz .done
    mov r12,rax
    invoke core_strdup,rbx
    mov [r12+E_TEXT],rax
    test rax,rax
    jz .fail
    invoke core_now
    mov [r12+E_TIME],rax
    mov [r12+E_FRACTION],rdx
    lea rax,[r12+E_TIME]
    ccall gmtime_fn,rax
    lea r13,[rbp-200]
    ccall strftime,r13,128,core_iso_base_fmt,rax
    lea r14,[rbp-360]
    ccall snprintf_fn,r14,128,core_iso_precise_fmt,r13,[r12+E_FRACTION]
    invoke core_strdup,r14
    mov [r12+E_DATE],rax
    mov rax,r12
    jmp .done
.fail:
    ccall free,r12
    xor eax,eax
.done:
    return

proc core_free
    mov rbx,rcx
    test rbx,rbx
    jz .done
    ccall free,[rbx+E_TEXT]
    ccall free,[rbx+E_FONT]
    ccall free,[rbx+E_DATE]
    ccall free,rbx
.done:
    return

; Return the .NET-compatible UTF-16 code-unit count of UTF-8 text.
proc core_length
    xor eax,eax
.loop:
    movzx edx,byte [rcx]
    test edx,edx
    jz .done
    inc rcx
    cmp dl,0x80
    jb .one
    cmp dl,0xc0
    jb .loop
    cmp dl,0xf0
    jb .one
    inc eax
.one:
    inc eax
    jmp .loop
.done:
    return

; Consumes RCX entry, promotes equal text+style, updates time, caps at 50.
proc core_add
    mov rbx,rcx
    test rbx,rbx
    jz .done
    mov rax,[rbx+E_TEXT]
    cmp byte [rax],0
    je .discard
    xor r12d,r12d
.find:
    cmp r12,[history_count]
    jae .insert
    lea rax,[history]
    mov r13,[rax+r12*8]
    ccall strcmp,[rbx+E_TEXT],[r13+E_TEXT]
    test eax,eax
    jnz .next
    mov rax,[rbx+E_FLAGS]
    cmp rax,[r13+E_FLAGS]
    jne .next
    lea rcx,[rbx+E_SIZE]
    lea rdx,[r13+E_SIZE]
    ccall memcmp,rcx,rdx,40
    test eax,eax
    jnz .next
    mov rcx,[rbx+E_FONT]
    mov rdx,[r13+E_FONT]
    test rcx,rcx
    jnz .font1
    lea rcx,[core_empty]
.font1:
    test rdx,rdx
    jnz .font2
    lea rdx,[core_empty]
.font2:
    ccall strcmp,rcx,rdx
    test eax,eax
    jnz .next
    invoke core_remove,r12
    jmp .insert
.next:
    inc r12
    jmp .find
.insert:
    cmp qword [history_count],MAX_ITEMS
    jb .space
    invoke core_remove,MAX_ITEMS-1
.space:
    mov r12,[history_count]
    lea r13,[history]
.shift:
    test r12,r12
    jz .first
    mov rax,[r13+r12*8-8]
    mov [r13+r12*8],rax
    dec r12
    jmp .shift
.first:
    mov [r13],rbx
    inc qword [history_count]
    mov qword [selected_index],0
    mov eax,1
    jmp .done
.discard:
    invoke core_free,rbx
    xor eax,eax
.done:
    return

proc core_remove
    mov rbx,rcx
    cmp rbx,[history_count]
    jae .done
    lea r12,[history]
    invoke core_free,[r12+rbx*8]
    dec qword [history_count]
.loop:
    cmp rbx,[history_count]
    jae .end
    mov rax,[r12+rbx*8+8]
    mov [r12+rbx*8],rax
    inc rbx
    jmp .loop
.end:
    mov qword [r12+rbx*8],0
    mov rax,[history_count]
    cmp [selected_index],rax
    jl .done
    dec rax
    mov [selected_index],rax
.done:
    return

proc core_clear
.loop:
    mov rcx,[history_count]
    test rcx,rcx
    jz .done
    dec rcx
    invoke core_remove,rcx
    jmp .loop
.done:
    mov qword [selected_index],-1
    return

proc core_selected
    mov rax,[selected_index]
    cmp rax,[history_count]
    jae .none
    lea rdx,[history]
    mov rax,[rdx+rax*8]
    return
.none:
    xor eax,eax
    return

; Produces the original 76 UTF-16-unit display preview (73 plus ellipsis).
proc core_display
    mov rbx,rcx
    lea rax,[rbx+E_TIME]
    ccall localtime_fn,rax
    ccall strftime,date_buffer,128,core_date_fmt,rax
    mov rsi,[rbx+E_TEXT]
    lea rdi,[json_token]
.copy:
    mov al,[rsi]
    test al,al
    jz .end
    lea rdx,[json_token+1048568]
    cmp rdi,rdx
    jae .end
    inc rsi
    cmp al,13
    je .space
    cmp al,10
    je .space
    cmp al,9
    jne .put
.space:
    mov al,' '
.put:
    stosb
    jmp .copy
.end:
    mov byte [rdi],0
    invoke core_trim,json_token
    mov r13,rax
    mov byte [rdx],0
    cmp byte [r13],0
    jne .length
    lea r13,[core_whitespace]
.length:
    invoke core_length,r13
    cmp eax,76
    jbe .prefix
    mov rsi,r13
    xor r14d,r14d
.truncate:
    invoke core_decode,rsi
    mov ecx,1
    cmp eax,0x10000
    jb .units
    inc ecx
.units:
    add r14d,ecx
    cmp r14d,73
    ja .ellipsis
    add rsi,rdx
    cmp r14d,73
    jb .truncate
.ellipsis:
    mov dword [rsi],0x002e2e2e
.prefix:
    lea r12,[core_empty]
    cmp qword [rbx+E_FLAGS],0
    je .format
    lea r12,[core_rich_prefix]
.format:
    ccall snprintf_fn,display_buffer,1024,core_display_fmt,date_buffer,r12,r13
    lea rax,[display_buffer]
    return

; UTF-8 scalar -> EAX and byte length -> EDX. Internal strings are terminated.
proc core_decode
    movzx eax,byte [rcx]
    mov edx,1
    cmp eax,0xc0
    jb .done
    mov r8d,eax
    and eax,31
    cmp r8d,0xe0
    jb .two
    and eax,15
    cmp r8d,0xf0
    jb .three
    and eax,7
    shl eax,6
    movzx r9d,byte [rcx+1]
    and r9d,63
    or eax,r9d
    inc rcx
    inc edx
.three:
    shl eax,6
    movzx r9d,byte [rcx+1]
    and r9d,63
    or eax,r9d
    inc rcx
    inc edx
.two:
    shl eax,6
    movzx r9d,byte [rcx+1]
    and r9d,63
    or eax,r9d
    inc edx
.done:
    return
; IsWhiteSpace-compatible scalar predicate for .NET's Unicode whitespace set.
proc core_space
    cmp ecx,32
    je .yes
    cmp ecx,9
    jb .no
    cmp ecx,13
    jbe .yes
    cmp ecx,0x85
    je .yes
    cmp ecx,0xa0
    je .yes
    cmp ecx,0x1680
    je .yes
    cmp ecx,0x2000
    jb .no
    cmp ecx,0x200a
    jbe .yes
    cmp ecx,0x2028
    je .yes
    cmp ecx,0x2029
    je .yes
    cmp ecx,0x202f
    je .yes
    cmp ecx,0x205f
    je .yes
    cmp ecx,0x3000
    je .yes
.no:
    xor eax,eax
    return
.yes:
    mov eax,1
    return
; Return trimmed bounds RAX=start, RDX=end without modifying the string.
proc core_trim
    mov rbx,rcx
    mov r12,rcx
    mov r13,rcx
    xor r14d,r14d
.loop:
    cmp byte [r12],0
    je .done
    invoke core_decode,r12
    mov r15,rdx
    invoke core_space,rax
    test eax,eax
    jnz .white
    test r14d,r14d
    jnz .end_update
    mov rbx,r12
    mov r14d,1
.end_update:
    lea r13,[r12+r15]
.white:
    add r12,r15
    jmp .loop
.done:
    mov rax,rbx
    mov rdx,r13
    return
proc core_blank
    invoke core_trim,rcx
    cmp rax,rdx
    sete al
    movzx eax,al
    return

proc core_style_details
    mov rbx,rcx
    mov byte [core_style_buffer],0
    test rbx,rbx
    jz .done
    mov rax,[rbx+E_FONT]
    test rax,rax
    jz .size
    cmp byte [rax],0
    je .size
    invoke core_style_append,rax
.size:
    test qword [rbx+E_FLAGS],F_SIZE
    jz .weight
    movq xmm0,[rbx+E_SIZE]
    cvtsd2si r12,xmm0
    test r12,r12
    jle .weight
    ccall snprintf_fn,core_style_number,64,core_style_pt,r12
    invoke core_style_append,core_style_number
.weight:
    cmp qword [rbx+E_WEIGHT],700
    jl .italic
    invoke core_style_append,core_bold
.italic:
    cmp qword [rbx+E_ITALIC],0
    je .done
    invoke core_style_append,core_italic
.done:
    lea rax,[core_style_buffer]
    return
proc core_style_append
    mov rbx,rcx
    ccall strlen,core_style_buffer
    lea rcx,[core_style_buffer]
    add rcx,rax
    mov rdx,1024
    sub rdx,rax
    lea r8,[core_style_next]
    test rax,rax
    jnz .append
    lea r8,[core_style_first]
.append:
    ccall snprintf_fn,rcx,rdx,core_style_fmt,r8,rbx
    mov byte [core_style_buffer+1023],0
    return

; JSON escaping writes Unicode as UTF-8 and escapes all control bytes.
proc json_write_string
    mov rbx,rcx
    mov r12,rdx
    ccall fputc,34,rbx
.loop:
    movzx r13d,byte [r12]
    test r13d,r13d
    jz .end
    inc r12
    cmp r13d,34
    je .escape
    cmp r13d,92
    je .escape
    cmp r13d,32
    jb .control
    ccall fputc,r13,rbx
    jmp .loop
.escape:
    ccall fputc,92,rbx
    ccall fputc,r13,rbx
    jmp .loop
.control:
    mov dword [rbp-80],0x3030755c
    lea rax,[core_hex]
    mov rdx,r13
    shr rdx,4
    mov dl,[rax+rdx]
    mov [rbp-76],dl
    and r13d,15
    mov dl,[rax+r13]
    mov [rbp-75],dl
    lea rax,[rbp-80]
    ccall fwrite,rax,1,6,rbx
    jmp .loop
.end:
    ccall fputc,34,rbx
    return

proc core_save
    ccall snprintf_fn,history_temp_path,4128,core_temp_fmt,history_path
    ccall fopen,history_temp_path,core_file_write
    test rax,rax
    jz .fail
    mov rbx,rax
    ccall fputs,core_json_open,rbx
    xor r12d,r12d
.loop:
    cmp r12,[history_count]
    jae .end
    test r12,r12
    jz .entry
    ccall fputs,core_json_comma,rbx
.entry:
    lea rax,[history]
    mov r13,[rax+r12*8]
    ccall fputs,core_json_entry,rbx
    invoke json_write_string,rbx,[r13+E_TEXT]
    ccall fputs,core_json_date,rbx
    mov rax,[r13+E_DATE]
    test rax,rax
    jnz .saved_date
    lea rax,[r13+E_TIME]
    ccall gmtime_fn,rax
    ccall strftime,date_buffer,128,core_iso_fmt,rax
    lea rax,[date_buffer]
.saved_date:
    invoke json_write_string,rbx,rax
    ccall fputs,core_json_style,rbx
    ccall fputs,core_json_font,rbx
    mov rax,[r13+E_FONT]
    test rax,rax
    jnz .font
    lea rax,[core_empty]
.font:
    invoke json_write_string,rbx,rax
    ccall fputs,core_json_size,rbx
    test qword [r13+E_FLAGS],F_SIZE
    jz .size_null
    ; Floating varargs use platform-specific ABI registers.
%ifdef WINDOWS
    mov rcx,rbx
    lea rdx,[core_json_float]
    mov r8,[r13+E_SIZE]
    movq xmm2,r8
    call fprintf
%else
    mov rdi,rbx
    lea rsi,[core_json_float]
    movq xmm0,[r13+E_SIZE]
    mov eax,1
    call fprintf
%endif
    jmp .weight
.size_null:
    ccall fputs,core_json_null,rbx
.weight:
    ccall fputs,core_json_weight,rbx
    invoke json_write_number,rbx,r13,F_WEIGHT,E_WEIGHT
    ccall fputs,core_json_italic,rbx
    lea rax,[core_json_null]
    test qword [r13+E_FLAGS],F_ITALIC
    jz .italic
    lea rax,[core_json_false]
    cmp qword [r13+E_ITALIC],0
    je .italic
    lea rax,[core_json_true]
.italic:
    ccall fputs,rax,rbx
    ccall fputs,core_json_fg,rbx
    invoke json_write_number,rbx,r13,F_FG,E_FG
    ccall fputs,core_json_bg,rbx
    invoke json_write_number,rbx,r13,F_BG,E_BG
    ccall fputs,core_json_endstyle,rbx
    ccall fputs,core_json_end,rbx
    inc r12
    jmp .loop
.end:
    ccall fputs,core_json_close,rbx
    ccall ferror,rbx
    mov r12,rax
    ccall fclose,rbx
    or rax,r12
    jnz .fail
%ifdef WINDOWS
    invoke MoveFileExA,history_temp_path,history_path,9
%else
    ccall rename,history_temp_path,history_path
    test eax,eax
    setz al
    movzx eax,al
%endif
    return
.fail:
    xor eax,eax
    return

proc json_write_number
    mov rbx,rcx
    test [rdx+E_FLAGS],r8
    jz .null
    mov rax,[rdx+r9]
    ccall fprintf,rbx,core_json_int,rax
    return
.null:
    ccall fputs,core_json_null,rbx
    return

; Tokenizer: RAX token type (string=256, number=257, true=258, false=259,
; null=260, punctuation=ASCII, EOF=0); UTF-8 string/number at json_token.
proc json_next
    mov rsi,[json_cursor]
.space:
    cmp rsi,[json_end]
    jae .eof
    movzx eax,byte [rsi]
    inc rsi
    cmp al,32
    jbe .space
    cmp al,34
    je .string
    cmp al,'-'
    je .number
    cmp al,'0'
    jb .punct
    cmp al,'9'
    jbe .number
    cmp al,'t'
    je .true
    cmp al,'f'
    je .false
    cmp al,'n'
    je .null
.punct:
    mov [json_cursor],rsi
    return
.true:
    lea rax,[rsi+3]
    cmp rax,[json_end]
    ja .error
    cmp word [rsi],'ru'
    jne .error
    cmp byte [rsi+2],'e'
    jne .error
    add rsi,3
    mov eax,258
    jmp .punct
.false:
    lea rax,[rsi+4]
    cmp rax,[json_end]
    ja .error
    cmp dword [rsi],'alse'
    jne .error
    add rsi,4
    mov eax,259
    jmp .punct
.null:
    lea rax,[rsi+3]
    cmp rax,[json_end]
    ja .error
    cmp word [rsi],'ul'
    jne .error
    cmp byte [rsi+2],'l'
    jne .error
    add rsi,3
    mov eax,260
    jmp .punct
.number:
    lea rdi,[json_token]
    stosb
.digit:
    cmp rsi,[json_end]
    jae .numend
    mov al,[rsi]
    cmp al,','
    je .numend
    cmp al,'}'
    je .numend
    cmp al,']'
    je .numend
    cmp al,32
    jbe .numend
    lea rdx,[json_token+127]
    cmp rdi,rdx
    jae .error
    inc rsi
    stosb
    jmp .digit
.numend:
    mov byte [rdi],0
    mov eax,257
    jmp .punct
.string:
    lea rdi,[json_token]
.char:
    cmp rsi,[json_end]
    jae .error
    lea rax,[json_token+1048568]
    cmp rdi,rax
    jae .error
    lodsb
    cmp al,34
    je .strend
    cmp al,32
    jb .error
    cmp al,92
    je .escape
    stosb
    jmp .char
.escape:
    cmp rsi,[json_end]
    jae .error
    lodsb
    cmp al,'u'
    je .unicode
    cmp al,'n'
    je .lf
    cmp al,'r'
    je .cr
    cmp al,'t'
    je .tab
    cmp al,'b'
    je .bs
    cmp al,'f'
    je .ff
    cmp al,34
    je .escaped
    cmp al,92
    je .escaped
    cmp al,'/'
    jne .error
    jmp .escaped
.lf: mov al,10
    jmp .escaped
.cr: mov al,13
    jmp .escaped
.tab: mov al,9
    jmp .escaped
.bs: mov al,8
    jmp .escaped
.ff: mov al,12
.escaped:
    stosb
    jmp .char
.unicode:
    invoke json_hex4,rsi
    test edx,edx
    jnz .error
    add rsi,4
    mov ebx,eax
    cmp eax,0xd800
    jb .encode
    cmp eax,0xdbff
    ja .encode
    lea rax,[rsi+6]
    cmp rax,[json_end]
    ja .error
    cmp word [rsi],0x755c
    jne .error
    add rsi,2
    invoke json_hex4,rsi
    test edx,edx
    jnz .error
    add rsi,4
    cmp eax,0xdc00
    jb .error
    cmp eax,0xdfff
    ja .error
    sub ebx,0xd800
    shl ebx,10
    sub eax,0xdc00
    lea ebx,[rbx+rax+0x10000]
.encode:
    test ebx,ebx
    jz .error
    cmp ebx,0x80
    jb .u1
    cmp ebx,0x800
    jb .u2
    cmp ebx,0x10000
    jb .u3
    mov eax,ebx
    shr eax,18
    or al,0xf0
    stosb
    mov eax,ebx
    shr eax,12
    and al,63
    or al,0x80
    stosb
    jmp .tail2
.u3:
    mov eax,ebx
    shr eax,12
    or al,0xe0
    stosb
.tail2:
    mov eax,ebx
    shr eax,6
    and al,63
    or al,0x80
    stosb
    jmp .tail1
.u2:
    mov eax,ebx
    shr eax,6
    or al,0xc0
    stosb
.tail1:
    mov eax,ebx
    and al,63
    or al,0x80
    stosb
    jmp .char
.u1:
    mov eax,ebx
    stosb
    jmp .char
.strend:
    mov byte [rdi],0
    mov eax,256
    jmp .punct
.error:
    mov qword [json_error],1
.eof:
    xor eax,eax
    jmp .punct

; Parse exactly four hexadecimal digits; EDX=1 on invalid input.
proc json_hex4
    lea rax,[rcx+4]
    cmp rax,[json_end]
    ja .bad
    xor eax,eax
    mov r8d,4
.loop:
    movzx edx,byte [rcx]
    inc rcx
    cmp dl,'0'
    jb .bad
    cmp dl,'9'
    jbe .decimal
    or dl,32
    sub dl,'a'
    cmp dl,5
    ja .bad
    add dl,10
    jmp .add
.decimal:
    sub dl,'0'
.add:
    shl eax,4
    or eax,edx
    dec r8d
    jnz .loop
    xor edx,edx
    return
.bad:
    mov edx,1
    return

proc core_load
    ccall fopen,history_path,core_file_read
    test rax,rax
    jz .done
    mov rbx,rax
    ccall fseek,rbx,0,2
    ccall ftell,rbx
    mov r12,rax
    cmp r12,67108864
    ja .close
    ccall fseek,rbx,0,0
    lea rax,[r12+1]
    ccall malloc,rax
    test rax,rax
    jz .close
    mov r13,rax
    ccall fread,r13,1,r12,rbx
    mov r12,rax
    ccall fclose,rbx
    mov byte [r13+r12],0
    mov [json_cursor],r13
    lea rax,[r13+r12]
    mov [json_end],rax
    mov qword [json_error],0
    xor ebx,ebx
    xor r14d,r14d
    invoke json_next
    cmp eax,'['
    jne .invalid
    invoke json_validate_value,rax,0
    test eax,eax
    jz .invalid
    invoke json_next
    test eax,eax
    jnz .invalid
    cmp qword [json_error],0
    jne .invalid
    mov [json_cursor],r13
    invoke json_next
    cmp eax,'['
    jne .invalid
.next:
    invoke json_next
    test eax,eax
    jz .invalid
    cmp eax,']'
    je .complete
    cmp eax,','
    je .next
    cmp eax,'{'
    jne .invalid
    invoke core_new,core_empty
    mov rbx,rax
    test rbx,rbx
    jz .invalid
    mov r14d,1
.field:
    invoke json_next
    cmp eax,'}'
    je .end_object
    cmp eax,','
    je .field
    cmp eax,256
    jne .invalid
    ; Map recognized keys to entry offsets; unknown properties are skipped.
    mov r15,-1
    ccall strcmp,json_token,core_key_text
    test eax,eax
    jz .textkey
    ccall strcmp,json_token,core_key_date
    test eax,eax
    jz .datekey
    ccall strcmp,json_token,core_key_style
    test eax,eax
    jz .stylekey
    ccall strcmp,json_token,core_key_font
    test eax,eax
    jz .fontkey
    ccall strcmp,json_token,core_key_size
    test eax,eax
    jz .sizekey
    ccall strcmp,json_token,core_key_weight
    test eax,eax
    jz .weightkey
    ccall strcmp,json_token,core_key_italic
    test eax,eax
    jz .italickey
    ccall strcmp,json_token,core_key_fg
    test eax,eax
    jz .fgkey
    ccall strcmp,json_token,core_key_bg
    test eax,eax
    jz .bgkey
    jmp .value
.textkey: mov r15,E_TEXT
    jmp .value
.datekey: mov r15,E_TIME
    jmp .value
.stylekey: mov r15,100
    jmp .value
.fontkey: mov r15,E_FONT
    jmp .value
.sizekey: mov r15,E_SIZE
    jmp .value
.weightkey: mov r15,E_WEIGHT
    jmp .value
.italickey: mov r15,E_ITALIC
    jmp .value
.fgkey: mov r15,E_FG
    jmp .value
.bgkey: mov r15,E_BG
.value:
    invoke json_next
    cmp eax,':'
    jne .invalid
    invoke json_next
    cmp r15,100
    je .stylevalue
    cmp r15,-1
    je .skip_unknown
    cmp eax,260
    je .field
    cmp r15,E_TIME
    je .datevalue
    cmp r15,E_TEXT
    je .stringvalue
    cmp r15,E_FONT
    je .stringvalue
    cmp r15,E_ITALIC
    je .boolvalue
    cmp eax,257
    jne .invalid
    cmp r15,E_SIZE
    je .floatvalue
    ccall strtoll_fn,json_token,0,10
    mov [rbx+r15],rax
    jmp .flag
.floatvalue:
    ccall strtod,json_token,0
    movq [rbx+E_SIZE],xmm0
    jmp .flag
.boolvalue:
    cmp eax,258
    je .truevalue
    cmp eax,259
    jne .invalid
    mov qword [rbx+E_ITALIC],0
    jmp .flag
.truevalue:
    mov qword [rbx+E_ITALIC],1
    jmp .flag
.stringvalue:
    cmp eax,256
    jne .invalid
    ccall free,[rbx+r15]
    invoke core_strdup,json_token
    mov [rbx+r15],rax
    test rax,rax
    jz .invalid
    cmp r15,E_TEXT
    je .field
    cmp byte [rax],0
    je .field
.flag:
    mov rcx,r15
    sub rcx,E_FONT
    shr rcx,3
    mov eax,1
    shl rax,cl
    or [rbx+E_FLAGS],rax
    jmp .field
.skip_unknown:
    invoke json_validate_value,rax,0
    jmp .field
.datevalue:
    cmp eax,256
    jne .invalid
    ccall free,[rbx+E_DATE]
    invoke core_strdup,json_token
    mov [rbx+E_DATE],rax
    test rax,rax
    jz .invalid
    invoke core_date_fraction,json_token
    mov [rbx+E_FRACTION],rax
    invoke core_parse_date,json_token
    mov [rbx+E_TIME],rax
    jmp .field
.stylevalue:
    cmp eax,260
    je .field
    cmp eax,'{'
    jne .invalid
    inc r14d
    cmp r14d,2
    ja .invalid
    jmp .field
.end_object:
    dec r14d
    jnz .field
    mov rax,[rbx+E_TEXT]
    cmp byte [rax],0
    je .discard
    invoke core_load_insert,rbx
    xor ebx,ebx
    jmp .next
.discard:
    invoke core_free,rbx
    xor ebx,ebx
    jmp .next
.complete:
    cmp qword [json_error],0
    jne .invalid
    cmp qword [history_count],0
    je .free
    mov qword [selected_index],0
    jmp .free
.invalid:
    invoke core_free,rbx
    invoke core_clear
.free:
    ccall free,r13
    jmp .done
.close:
    ccall fclose,rbx
.done:
    return

; Load preserves duplicates and selects the newest 50, matching OrderByDescending.
proc core_load_insert
    mov rbx,rcx
    lea r12,[history]
    xor r13d,r13d
.find:
    cmp r13,[history_count]
    jae .insert
    mov rax,[r12+r13*8]
    mov rdx,[rax+E_TIME]
    cmp [rbx+E_TIME],rdx
    jg .insert
    jl .older
    mov rdx,[rax+E_FRACTION]
    cmp [rbx+E_FRACTION],rdx
    jg .insert
.older:
    inc r13
    jmp .find
.insert:
    cmp r13,MAX_ITEMS
    jae .discard
    cmp qword [history_count],MAX_ITEMS
    jb .shift
    invoke core_remove,MAX_ITEMS-1
.shift:
    mov r14,[history_count]
.move:
    cmp r14,r13
    jbe .place
    mov rax,[r12+r14*8-8]
    mov [r12+r14*8],rax
    dec r14
    jmp .move
.place:
    mov [r12+r13*8],rbx
    inc qword [history_count]
    return
.discard:
    invoke core_free,rbx
    return

; Seven decimal digits represent the reference DateTimeOffset tick precision.
proc core_date_fraction
    mov rbx,rcx
    ccall strlen,rbx
    cmp rax,20
    jb .zero
    cmp byte [rbx+19],'.'
    jne .zero
    lea rcx,[rbx+20]
    xor eax,eax
    mov r8d,7
.digit:
    movzx edx,byte [rcx]
    sub edx,'0'
    cmp edx,9
    ja .pad
    imul eax,10
    add eax,edx
    inc rcx
    dec r8d
    jnz .digit
    return
.pad:
    imul eax,10
    dec r8d
    jnz .pad
    return
.zero:
    xor eax,eax
    return

proc core_parse_date
    mov rbx,rcx
    ccall strlen,rbx
    cmp rax,19
    jb .bad
    lea r12,[rbp-160]
    ccall memset,r12,0,64
    lea rax,[r12+20]
    lea rcx,[r12+16]
    lea rdx,[r12+12]
    lea r8,[r12+8]
    lea r9,[r12+4]
    ccall sscanf,rbx,core_iso_scan,rax,rcx,rdx,r8,r9,r12
    cmp eax,6
    jne .bad
    sub dword [r12+20],1900
    dec dword [r12+16]
    ccall timegm_fn,r12
    mov r13,rax
    ; ISO offsets begin after seconds/fraction. Convert local timestamp to UTC.
    lea rsi,[rbx+19]
.seek:
    mov al,[rsi]
    test al,al
    jz .done
    cmp al,'Z'
    je .done
    cmp al,'+'
    je .offset
    cmp al,'-'
    je .offset
    inc rsi
    jmp .seek
.offset:
    mov r14d,1
    cmp al,'+'
    je .digits
    mov r14d,-1
.digits:
    movzx eax,byte [rsi+1]
    sub eax,'0'
    imul eax,10
    movzx edx,byte [rsi+2]
    lea eax,[rax+rdx-'0']
    imul eax,60
    movzx edx,byte [rsi+4]
    sub edx,'0'
    imul edx,10
    add eax,edx
    movzx edx,byte [rsi+5]
    lea eax,[rax+rdx-'0']
    imul eax,60
    imul eax,r14d
    cdqe
    sub r13,rax
.done:
    mov rax,r13
    return
.bad:
    xor eax,eax
    return

; Validate the entire JSON grammar before interpreting any entries. Depth is
; bounded, strings are bounds-checked by json_next, numbers follow RFC 8259.
proc json_validate_value
    mov rbx,rcx
    mov r12,rdx
    cmp r12,32
    ja .bad
    inc r12
    cmp ebx,256
    je .good
    cmp ebx,258
    je .good
    cmp ebx,259
    je .good
    cmp ebx,260
    je .good
    cmp ebx,257
    je .number
    cmp ebx,'['
    je .array
    cmp ebx,'{'
    jne .bad
    invoke json_next
    cmp eax,'}'
    je .good
.key:
    cmp eax,256
    jne .bad
    invoke json_next
    cmp eax,':'
    jne .bad
    invoke json_next
    invoke json_validate_value,rax,r12
    test eax,eax
    jz .bad
    invoke json_next
    cmp eax,'}'
    je .good
    cmp eax,','
    jne .bad
    invoke json_next
    jmp .key
.array:
    invoke json_next
    cmp eax,']'
    je .good
.item:
    invoke json_validate_value,rax,r12
    test eax,eax
    jz .bad
    invoke json_next
    cmp eax,']'
    je .good
    cmp eax,','
    jne .bad
    invoke json_next
    jmp .item
.number:
    lea rsi,[json_token]
    cmp byte [rsi],'-'
    jne .integer
    inc rsi
.integer:
    mov al,[rsi]
    cmp al,'0'
    je .zero
    cmp al,'1'
    jb .bad
    cmp al,'9'
    ja .bad
.digits:
    inc rsi
    mov al,[rsi]
    cmp al,'0'
    jb .fraction
    cmp al,'9'
    jbe .digits
    jmp .fraction
.zero:
    inc rsi
.fraction:
    cmp byte [rsi],'.'
    jne .exponent
    inc rsi
    mov al,[rsi]
    cmp al,'0'
    jb .bad
    cmp al,'9'
    ja .bad
.fraction_digits:
    inc rsi
    mov al,[rsi]
    cmp al,'0'
    jb .exponent
    cmp al,'9'
    jbe .fraction_digits
.exponent:
    mov al,[rsi]
    or al,32
    cmp al,'e'
    jne .number_end
    inc rsi
    cmp byte [rsi],'+'
    je .sign
    cmp byte [rsi],'-'
    jne .exp_digit
.sign:
    inc rsi
.exp_digit:
    mov al,[rsi]
    cmp al,'0'
    jb .bad
    cmp al,'9'
    ja .bad
.exponent_digits:
    inc rsi
    mov al,[rsi]
    cmp al,'0'
    jb .number_end
    cmp al,'9'
    jbe .exponent_digits
.number_end:
    cmp byte [rsi],0
    jne .bad
.good:
    mov eax,1
    return
.bad:
    xor eax,eax
    return

proc core_self_test
    invoke core_clear
    invoke core_new,core_test_text
    mov rbx,rax
    invoke core_add,rbx
    invoke core_length,core_test_text
    cmp eax,23
    jne .bad
    invoke core_new,core_test_other
    invoke core_add,rax
    invoke core_new,core_test_text
    invoke core_add,rax
    cmp qword [history_count],2
    jne .bad
    mov rbx,[history]
    invoke core_strdup,core_test_font
    mov [rbx+E_FONT],rax
    mov qword [rbx+E_FLAGS],63
    mov rax,0x402a000000000000
    mov [rbx+E_SIZE],rax
    mov qword [rbx+E_WEIGHT],700
    mov qword [rbx+E_ITALIC],1
    mov qword [rbx+E_FG],0x332211
    mov qword [rbx+E_BG],0xffffff
    invoke core_save
    test eax,eax
    jz .bad
    invoke core_clear
    invoke core_load
    cmp qword [history_count],2
    jne .bad
    mov rbx,[history]
    ccall strcmp,[rbx+E_TEXT],core_test_text
    test eax,eax
    jnz .bad
    cmp qword [rbx+E_FLAGS],63
    jne .bad
    cmp qword [rbx+E_WEIGHT],700
    jne .bad
    xor r12d,r12d
.cap:
    ccall snprintf_fn,display_buffer,1024,core_test_fmt,r12
    invoke core_new,display_buffer
    invoke core_add,rax
    inc r12
    cmp r12,60
    jb .cap
    cmp qword [history_count],50
    jne .bad
    invoke core_remove,0
    cmp qword [history_count],49
    jne .bad
    invoke core_clear
    ccall puts,core_test_ok
    xor eax,eax
    return
.bad:
    ccall puts,core_test_bad
    mov eax,1
    return
