// Strict, bounded JSON grammar check before Foundation deserialization.
// Internal helpers share x19 cursor, x20 end, x21 nesting depth.
// They return w0 = success and never read at or beyond end.
.p2align 2
json_validate:
 enter
 mov x19,x0
 add x20,x0,x1
 mov x21,#0
 mov x2,#0x4000000
 cmp x1,x2
 b.hi jv_invalid
 bl jv_value
 cbz w0,jv_done
 bl jv_space
 cmp x19,x20
 cset w0,eq
jv_done:
 leave
jv_invalid:
 mov w0,#0
 leave

// Returns the next byte in w2, or zero at end, after JSON whitespace.
jv_space:
 cmp x19,x20
 b.hs jv_eof
 ldrb w2,[x19]
 cmp w2,#32
 b.eq jv_skip
 cmp w2,#9
 b.eq jv_skip
 cmp w2,#10
 b.eq jv_skip
 cmp w2,#13
 b.ne jv_space_done
jv_skip:
 add x19,x19,#1
 b jv_space
jv_eof:
 mov w2,#0
jv_space_done:
 ret

jv_value:
 stp x22,x30,[sp,#-16]!
 bl jv_space
 cmp w2,#34
 b.eq jv_value_string
 cmp w2,#123
 b.eq jv_object
 cmp w2,#91
 b.eq jv_array
 cmp w2,#116
 b.eq jv_true
 cmp w2,#102
 b.eq jv_false
 cmp w2,#110
 b.eq jv_null
 bl jv_number
 b jv_return
jv_value_string:
 bl jv_string
 b jv_return
jv_true:
 addr x3,jv_t
 b jv_literal
jv_false:
 addr x3,jv_f
 b jv_literal
jv_null:
 addr x3,jv_n
jv_literal:
 ldrb w4,[x3],#1
 cbz w4,jv_yes
 cmp x19,x20
 b.hs jv_no
 ldrb w2,[x19],#1
 cmp w2,w4
 b.ne jv_no
 b jv_literal
jv_object:
 mov w22,#125
 b jv_container
jv_array:
 mov w22,#93
jv_container:
 add x21,x21,#1
 cmp x21,#32
 b.hi jv_no
 add x19,x19,#1
 bl jv_space
 cmp w2,w22
 b.eq jv_close
jv_member:
 cmp w22,#125
 b.ne jv_element
 bl jv_string
 cbz w0,jv_no
 bl jv_space
 cmp w2,#58
 b.ne jv_no
 add x19,x19,#1
jv_element:
 bl jv_value
 cbz w0,jv_no
 bl jv_space
 cmp w2,w22
 b.eq jv_close
 cmp w2,#44
 b.ne jv_no
 add x19,x19,#1
 bl jv_space
 // Deliberately require another member; no trailing comma extension.
 b jv_member
jv_close:
 add x19,x19,#1
 sub x21,x21,#1
jv_yes:
 mov w0,#1
 b jv_return
jv_no:
 mov w0,#0
jv_return:
 ldp x22,x30,[sp],#16
 ret

jv_string:
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19],#1
 cmp w2,#34
 b.ne jv_string_bad
jv_string_loop:
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19],#1
 cmp w2,#34
 b.eq jv_string_ok
 cmp w2,#32
 b.lo jv_string_bad
 cmp w2,#92
 b.ne jv_string_loop
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19],#1
 cmp w2,#34
 b.eq jv_string_loop
 cmp w2,#92
 b.eq jv_string_loop
 cmp w2,#47
 b.eq jv_string_loop
 cmp w2,#98
 b.eq jv_string_loop
 cmp w2,#102
 b.eq jv_string_loop
 cmp w2,#110
 b.eq jv_string_loop
 cmp w2,#114
 b.eq jv_string_loop
 cmp w2,#116
 b.eq jv_string_loop
 cmp w2,#117
 b.ne jv_string_bad
 mov w3,#4
jv_hex:
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19],#1
 sub w4,w2,#48
 cmp w4,#9
 b.ls jv_hex_next
 orr w2,w2,#32
 sub w4,w2,#97
 cmp w4,#5
 b.hi jv_string_bad
jv_hex_next:
 subs w3,w3,#1
 b.ne jv_hex
 b jv_string_loop
jv_string_ok:
 mov w0,#1
 ret
jv_string_bad:
 mov w0,#0
 ret

// Number grammar: -?(0|[1-9][0-9]*)(.[0-9]+)?([eE][+-]?[0-9]+)?
jv_number:
 cmp w2,#45
 b.ne jv_integer
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19]
jv_integer:
 cmp w2,#48
 b.eq jv_zero
 sub w3,w2,#49
 cmp w3,#8
 b.hi jv_string_bad
jv_digits:
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_ok
 ldrb w2,[x19]
 sub w3,w2,#48
 cmp w3,#9
 b.ls jv_digits
 b jv_fraction
jv_zero:
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_ok
 ldrb w2,[x19]
jv_fraction:
 cmp w2,#46
 b.ne jv_exponent
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19]
 sub w3,w2,#48
 cmp w3,#9
 b.hi jv_string_bad
jv_fraction_digits:
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_ok
 ldrb w2,[x19]
 sub w3,w2,#48
 cmp w3,#9
 b.ls jv_fraction_digits
jv_exponent:
 orr w3,w2,#32
 cmp w3,#101
 b.ne jv_string_ok
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19]
 cmp w2,#43
 b.eq jv_sign
 cmp w2,#45
 b.ne jv_exponent_first
jv_sign:
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_bad
 ldrb w2,[x19]
jv_exponent_first:
 sub w3,w2,#48
 cmp w3,#9
 b.hi jv_string_bad
jv_exponent_digits:
 add x19,x19,#1
 cmp x19,x20
 b.hs jv_string_ok
 ldrb w2,[x19]
 sub w3,w2,#48
 cmp w3,#9
 b.ls jv_exponent_digits
 b jv_string_ok

.section __TEXT,__cstring,cstring_literals
jv_t: .asciz "true"
jv_f: .asciz "false"
jv_n: .asciz "null"
.text
