// Native Apple Silicon assembly. Cocoa/AX/CG calls, no Objective-C source.
// The Foundation serializer is an OS dependency, just like Cocoa text rendering.
.macro enter
 stp x29,x30,[sp,#-256]!
 mov x29,sp
 stp x19,x20,[sp,#16]
 stp x21,x22,[sp,#32]
 stp x23,x24,[sp,#48]
 stp x25,x26,[sp,#64]
 stp x27,x28,[sp,#80]
.endm
.macro leave
 ldp x19,x20,[sp,#16]
 ldp x21,x22,[sp,#32]
 ldp x23,x24,[sp,#48]
 ldp x25,x26,[sp,#64]
 ldp x27,x28,[sp,#80]
 ldp x29,x30,[sp],#256
 ret
.endm
.macro addr reg,sym
 adrp \reg,\sym@PAGE
 add \reg,\reg,\sym@PAGEOFF
.endm
.macro load reg,sym
 adrp \reg,\sym@PAGE
 ldr \reg,[\reg,\sym@PAGEOFF]
.endm
.macro store reg,sym
 adrp x16,\sym@PAGE
 str \reg,[x16,\sym@PAGEOFF]
.endm
.macro msg sel
 addr x1,\sel
 bl send
.endm
.macro klass name
 addr x0,\name
 bl _objc_getClass
.endm
.macro stringlit name
 addr x0,\name
 bl string
.endm
.macro method sel,fn,enc
 addr x0,\sel
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 addr x2,\fn
 addr x3,\enc
 bl _class_addMethod
.endm
.text
#include "json.inc"
.globl _main
.p2align 2
_main:
 enter
 mov x19,x0
 mov x20,x1
 klass cPool
 msg sAlloc
 msg sInit
 store x0,gPool
 klass cArray
 msg sAlloc
 msg sInit
 store x0,gHistory
 mov x0,#-1
 store x0,gSelected
 bl init_path
 cmp x19,#2
 b.lt 1f
 ldr x0,[x20,#8]
 addr x1,tTest
 bl _strcmp
 cbnz w0,2f
 bl self_test
 leave
2:
 ldr x0,[x20,#8]
 addr x1,tRoundtrip
 bl _strcmp
 cbnz w0,1f
 bl load_history
 bl save_history
 cmp w0,#0
 cset w0,eq
 leave
1:
 klass cApplication
 msg sShared
 store x0,gApp
 mov x2,#0
 msg sPolicy
 bl make_delegate
 klass cWindow
 msg sAlloc
 mov x19,x0
 addr x0,sWindowInit
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 fmov d0,xzr
 fmov d1,xzr
 mov x9,#980
 ucvtf d2,x9
 mov x9,#620
 ucvtf d3,x9
 mov x2,#15
 mov x3,#2
 mov x4,#0
 bl _objc_msgSend
 store x0,gWindow
 stringlit tTitle
 mov x2,x0
 load x0,gWindow
 msg sTitle
 load x2,gDelegate
 load x0,gWindow
 msg sDelegate
 load x0,gWindow
 msg sContent
 store x0,gContent
 store x0,gRoot
 bl make_split
 addr x0,tRemove
 mov x1,#10
 mov x2,#574
 addr x3,sRemove
 bl button
 addr x0,tClear
 mov x1,#100
 mov x2,#574
 addr x3,sClear
 bl button
 addr x0,tHelp
 mov x1,#190
 mov x2,#580
 mov x3,#770
 mov x4,#24
 bl label
 load x0,gLeft
 store x0,gContent
 addr x0,tHistory
 mov x1,#0
 mov x2,#502
 mov x3,#360
 mov x4,#24
 bl label
 load x0,gRight
 store x0,gContent
 addr x0,tPreview
 mov x1,#0
 mov x2,#502
 mov x3,#592
 mov x4,#24
 bl label
 load x0,gRoot
 store x0,gContent
 addr x0,tReady
 mov x1,#8
 mov x2,#4
 mov x3,#960
 mov x4,#24
 bl label
 store x0,gStatus
 load x0,gRight
 store x0,gContent
 addr x0,tZero
 mov x1,#0
 mov x2,#0
 mov x3,#592
 mov x4,#24
 bl label
 store x0,gDetails
 klass cScroll
 msg sAlloc
 mov x1,#0
 mov x2,#0
 mov x3,#360
 mov x4,#496
 bl frame
 mov x19,x0
 mov x2,#1
 msg sVScroll
 mov x0,x19
 mov x2,#18
 msg sAutoresizing
 mov x2,x19
 load x0,gLeft
 msg sAddSubview
 klass cTable
 msg sAlloc
 mov x1,#0
 mov x2,#0
 mov x3,#360
 mov x4,#502
 bl frame
 store x0,gTable
 mov x2,#0
 msg sHeader
 load x0,gTable
 load x2,gDelegate
 msg sDataSource
 load x0,gTable
 load x2,gDelegate
 msg sDelegate
 klass cColumn
 msg sAlloc
 mov x20,x0
 stringlit tHistory
 mov x2,x0
 mov x0,x20
 msg sColumnInit
 mov x21,x0
 addr x0,sWidth
 bl _sel_registerName
 mov x1,x0
 mov x0,x21
 mov x9,#340
 ucvtf d0,x9
 bl _objc_msgSend
 mov x0,x21
 mov x2,x0
 load x0,gTable
 msg sAddColumn
 mov x0,x19
 load x2,gTable
 msg sDocument
 klass cScroll
 msg sAlloc
 mov x1,#0
 mov x2,#34
 mov x3,#592
 mov x4,#462
 bl frame
 mov x19,x0
 mov x2,#1
 msg sVScroll
 mov x0,x19
 mov x2,#1
 msg sHScroll
 mov x0,x19
 mov x2,#18
 msg sAutoresizing
 mov x2,x19
 load x0,gRight
 msg sAddSubview
 klass cTextView
 msg sAlloc
 mov x1,#0
 mov x2,#0
 mov x3,#580
 mov x4,#468
 bl frame
 store x0,gPreview
 mov x2,#0
 msg sEditable
 load x0,gPreview
 mov x2,#1
 msg sHResizable
 load x0,gPreview
 addr x1,sMaxSize
 bl large_size
 load x0,gPreview
 msg sTextContainer
 mov x20,x0
 mov x2,#0
 msg sTracksWidth
 mov x0,x20
 addr x1,sContainerSize
 bl large_size
 load x2,gPreview
 mov x0,x19
 msg sDocument
 bl load_history
 bl refresh
 load x0,gWindow
 msg sCenter
 load x0,gWindow
 mov x2,#0
 msg sShow
 load x0,gApp
 mov x2,#1
 msg sActivate
 bl accessibility_init
 klass cTimer
 mov x19,x0
 addr x0,sTick
 bl _sel_registerName
 mov x20,x0
 addr x0,sTimer
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 load x2,gDelegate
 mov x3,x20
 mov x4,#0
 mov x5,#1
 addr x9,dInterval
 ldr d0,[x9]
 bl _objc_msgSend
 load x0,gApp
 msg sRun
 mov w0,#0
 leave

// x0 receiver, x1 selector C string, x2..x5 method arguments.
send:
 enter
 mov x19,x0
 mov x20,x2
 mov x21,x3
 mov x22,x4
 mov x23,x5
 mov x0,x1
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 mov x2,x20
 mov x3,x21
 mov x4,x22
 mov x5,x23
 bl _objc_msgSend
 leave
string:
 enter
 mov x19,x0
 klass cString
 mov x2,x19
 msg sUTF8
 leave
// NSRect is an HFA of four doubles on AArch64: D0-D3.
frame:
 enter
 mov x19,x0
 mov x20,x1
 mov x21,x2
 mov x22,x3
 mov x23,x4
 addr x0,sFrame
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 scvtf d0,x20
 scvtf d1,x21
 scvtf d2,x22
 scvtf d3,x23
 bl _objc_msgSend
 leave
button:
 enter
 mov x19,x0
 mov x20,x1
 mov x21,x2
 mov x22,x3
 klass cButton
 msg sAlloc
 mov x1,x20
 mov x2,x21
 mov x3,#82
 mov x4,#32
 bl frame
 mov x23,x0
 mov x0,x19
 bl string
 mov x2,x0
 mov x0,x23
 msg sTitle
 mov x0,x23
 mov x2,#1
 msg sBezel
 mov x0,x23
 load x2,gDelegate
 msg sTarget
 mov x0,x22
 bl _sel_registerName
 mov x2,x0
 mov x0,x23
 msg sAction
 mov x0,x23
 mov x2,#8
 msg sAutoresizing
 load x0,gContent
 mov x2,x23
 msg sAddSubview
 mov x0,x23
 leave
label:
 enter
 mov x19,x0
 mov x20,x1
 mov x21,x2
 mov x22,x3
 mov x23,x4
 klass cLabel
 msg sAlloc
 mov x1,x20
 mov x2,x21
 mov x3,x22
 mov x4,x23
 bl frame
 mov x24,x0
 mov x0,x19
 bl string
 mov x2,x0
 mov x0,x24
 msg sValue
 mov x0,x24
 mov x2,#0
 msg sEditable
 mov x0,x24
 mov x2,#0
 msg sBordered
 mov x0,x24
 mov x2,#0
 msg sBackground
 mov x0,x24
 mov x2,#2
 cmp x21,#500
 b.lt 1f
 mov x2,#10
1:
 msg sAutoresizing
 load x0,gContent
 mov x2,x24
 msg sAddSubview
 mov x0,x24
 leave
make_delegate:
 enter
 klass cObject
 addr x1,tDelegate
 mov x2,#0
 bl _objc_allocateClassPair
 mov x19,x0
 method sRemove,remove_click,eVoid
 method sClear,clear_click,eVoid
 method sTick,tick,eVoid
 method sRows,rows,eRows
 method sCell,cell,eCell
 method sChange,selection_changed,eVoid
 method sClose,close_window,eVoid
 mov x0,x19
 bl _objc_registerClassPair
 mov x0,x19
 msg sAlloc
 msg sInit
 store x0,gDelegate
 leave
make_split:
 enter
 klass cSplit
 msg sAlloc
 mov x1,#10
 mov x2,#32
 mov x3,#960
 mov x4,#526
 bl frame
 store x0,gSplit
 mov x2,#1
 msg sVertical
 load x0,gSplit
 mov x2,#1
 msg sDividerStyle
 load x0,gSplit
 mov x2,#18
 msg sAutoresizing
 load x0,gRoot
 load x2,gSplit
 msg sAddSubview
 klass cView
 msg sAlloc
 mov x1,#0
 mov x2,#0
 mov x3,#360
 mov x4,#526
 bl frame
 store x0,gLeft
 mov x2,x0
 load x0,gSplit
 msg sAddSubview
 klass cView
 msg sAlloc
 mov x1,#368
 mov x2,#0
 mov x3,#592
 mov x4,#526
 bl frame
 store x0,gRight
 mov x2,x0
 load x0,gSplit
 msg sAddSubview
 addr x0,sSplitPosition
 bl _sel_registerName
 mov x1,x0
 load x0,gSplit
 mov x2,#0
 mov x9,#360
 ucvtf d0,x9
 bl _objc_msgSend
 addr x0,sMinSize
 bl _sel_registerName
 mov x1,x0
 load x0,gWindow
 mov x9,#760
 ucvtf d0,x9
 mov x9,#480
 ucvtf d1,x9
 bl _objc_msgSend
 leave
init_path:
 enter
 addr x0,tEnv
 bl _getenv
 cbz x0,1f
 bl string
 b 2f
1:
 bl _NSHomeDirectory
 mov x19,x0
 stringlit tDirectory
 mov x2,x0
 mov x0,x19
 msg sAppendPath
 mov x19,x0
 klass cFileManager
 msg sDefaultManager
 mov x2,x19
 mov x3,#1
 mov x4,#0
 mov x5,#0
 msg sCreateDir
 stringlit tFilename
 mov x2,x0
 mov x0,x19
 msg sAppendPath
2:
 msg sRetain
 store x0,gPath
 klass cISO
 msg sAlloc
 msg sInit
 store x0,gISO
 klass cISO
 msg sAlloc
 msg sInit
 store x0,gISOFractional
 mov x2,#3955
 msg sFormatOptions
 klass cDateFormatter
 msg sAlloc
 msg sInit
 store x0,gDateFormatter
 mov x2,#1
 msg sDateStyle
 load x0,gDateFormatter
 mov x2,#1
 msg sTimeStyle
 stringlit kText
 msg sRetain
 store x0,gTextKey
 stringlit kStyle
 msg sRetain
 store x0,gStyleKey
 stringlit kDate
 msg sRetain
 store x0,gDateKey
 leave

// Dictionary field access: x0 entry, x1 retained NSString key.
field:
 enter
 mov x2,x1
 msg sObjectForKey
 leave
selected:
 enter
 load x19,gSelected
 tbnz x19,#63,1f
 load x0,gHistory
 msg sCount
 cmp x19,x0
 b.hs 1f
 load x0,gHistory
 mov x2,x19
 msg sObjectAtIndex
 leave
1:
 mov x0,#0
 leave
// x0 NSString text. Capture on macOS has no style metadata, as in reference.
add_text:
 enter
 mov x19,x0
 cbz x19,9f
 msg sLength
 cbz x0,9f
 load x0,gHistory
 msg sCount
 mov x20,x0
 mov x21,#0
1:
 cmp x21,x20
 b.hs 3f
 load x0,gHistory
 mov x2,x21
 msg sObjectAtIndex
 mov x22,x0
 load x1,gTextKey
 bl field
 mov x2,x19
 msg sEqual
 cbz w0,2f
 mov x0,x22
 bl has_style
 cbz w0,4f
2:
 add x21,x21,#1
 b 1b
4:
 load x0,gHistory
 mov x2,x21
 msg sRemoveIndex
3:
 klass cDictionary
 msg sDictionary
 mov x22,x0
 mov x2,x19
 load x3,gTextKey
 msg sSetObject
 klass cDate
 msg sDate
 mov x2,x0
 load x0,gISO
 msg sStringFromDate
 mov x2,x0
 mov x0,x22
 load x3,gDateKey
 msg sSetObject
 klass cNull
 msg sNull
 mov x2,x0
 mov x0,x22
 load x3,gStyleKey
 msg sSetObject
 load x0,gHistory
 mov x2,x22
 mov x3,#0
 msg sInsert
 load x0,gHistory
 msg sCount
 cmp x0,#50
 b.ls 5f
 load x0,gHistory
 msg sRemoveLast
5:
 mov x0,#0
 store x0,gSelected
9:
 leave
save_history:
 enter
 klass cJSON
 load x2,gHistory
 mov x3,#1
 mov x4,#0
 msg sJSONData
 cbz x0,1f
 load x2,gPath
 mov x3,#1
 msg sWriteFile
 leave
1:
 mov x0,#0
 leave
// NSSize uses the d0/d1 homogeneous aggregate ABI on Apple Silicon.
large_size:
 enter
 mov x19,x0
 mov x0,x1
 bl _sel_registerName
 mov x1,x0
 mov x0,x19
 mov x9,#0x9680
 movk x9,#0x98,lsl #16
 ucvtf d0,x9
 fmov d1,d0
 bl _objc_msgSend
 leave

load_history:
 enter
 klass cData
 load x2,gPath
 msg sReadFile
 cbz x0,9f
 mov x19,x0
 msg sLength
 mov x20,x0
 mov x0,x19
 msg sBytes
 mov x1,x20
 bl json_validate
 cbz w0,9f
 klass cJSON
 mov x2,x19
 mov x3,#0
 mov x4,#0
 msg sJSONObject
 cbz x0,9f
 mov x19,x0
 klass cImmutableArray
 mov x2,x0
 mov x0,x19
 msg sIsKind
 cbz w0,9f
 mov x0,x19
 msg sCount
 mov x20,x0
 mov x21,#0
1:
 cmp x21,x20
 b.hs 8f
 mov x0,x19
 mov x2,x21
 msg sObjectAtIndex
 mov x22,x0
 klass cImmutableDictionary
 mov x2,x0
 mov x0,x22
 msg sIsKind
 cbz w0,7f
 mov x0,x22
 load x1,gTextKey
 bl field
 mov x23,x0
 klass cString
 mov x2,x0
 mov x0,x23
 msg sIsKind
 cbz w0,7f
 mov x0,x23
 msg sLength
 cbz x0,7f
 load x0,gHistory
 mov x2,x22
 msg sAddObject
7:
 add x21,x21,#1
 b 1b
8:
 load x0,gHistory
 addr x2,compare_entries
 mov x3,#0
 msg sSortFunction
81:
 load x0,gHistory
 msg sCount
 cmp x0,#50
 b.ls 82f
 load x0,gHistory
 msg sRemoveLast
 b 81b
82:
 load x0,gHistory
 msg sCount
 cbz x0,9f
 mov x0,#0
 store x0,gSelected
9:
 leave

// Table data source callbacks use the native Objective-C ABI.
rows:
 enter
 load x0,gHistory
 msg sCount
 leave
cell:
 enter
 mov x19,x4
 load x0,gHistory
 msg sCount
 cmp x19,x0
 b.hs 8f
 load x0,gHistory
 mov x2,x19
 msg sObjectAtIndex
 mov x19,x0
 load x1,gTextKey
 bl field
 mov x20,x0
 stringlit tCR
 mov x21,x0
 stringlit tSpace
 mov x3,x0
 mov x2,x21
 mov x0,x20
 msg sReplace
 mov x20,x0
 stringlit tLF
 mov x21,x0
 stringlit tSpace
 mov x3,x0
 mov x2,x21
 mov x0,x20
 msg sReplace
 mov x20,x0
 stringlit tTab
 mov x21,x0
 stringlit tSpace
 mov x3,x0
 mov x2,x21
 mov x0,x20
 msg sReplace
 mov x20,x0
 klass cCharacterSet
 msg sWhitespace
 mov x2,x0
 mov x0,x20
 msg sTrim
 mov x20,x0
 msg sLength
 cbnz x0,1f
 stringlit tWhitespace
 mov x20,x0
1:
 mov x0,x20
 msg sLength
 cmp x0,#76
 b.ls 2f
 mov x0,x20
 mov x2,#73
 msg sSubstring
 mov x20,x0
 stringlit tEllipsis
 mov x2,x0
 mov x0,x20
 msg sAppend
 mov x20,x0
2:
 mov x0,x19
 bl entry_date
 mov x21,x0
 stringlit tTwoSpaces
 mov x2,x0
 mov x0,x21
 msg sAppend
 mov x21,x0
 mov x0,x19
 bl has_style
 cbz w0,3f
 stringlit tRichPrefix
 mov x2,x0
 mov x0,x21
 msg sAppend
 mov x21,x0
3:
 mov x0,x21
 mov x2,x20
 msg sAppend
 leave
8:
 stringlit tEmpty
 leave
entry_date:
 enter
 load x1,gDateKey
 bl field
 cbz x0,1f
 bl parse_date
 cbz x0,1f
 mov x2,x0
 load x0,gDateFormatter
 msg sStringFromDate
 leave
1:
 stringlit tEmpty
 leave
parse_date:
 enter
 mov x19,x0
 cbz x19,1f
 mov x2,x0
 load x0,gISO
 msg sDateFromString
 cbnz x0,1f
 load x0,gISOFractional
 mov x2,x19
 msg sDateFromString
1:
 leave
compare_entries:
 enter
 mov x19,x0
 mov x20,x1
 load x1,gDateKey
 bl field
 bl parse_date
 mov x21,x0
 mov x0,x20
 load x1,gDateKey
 bl field
 bl parse_date
 cbz x0,1f
 cbz x21,2f
 mov x2,x21
 msg sCompare
 leave
1:
 mov x0,#1
 leave
2:
 mov x0,#-1
 leave
refresh:
 enter
 load x0,gTable
 cbz x0,9f
 msg sReload
 load x19,gSelected
 tbnz x19,#63,1f
 klass cIndexSet
 mov x2,x19
 msg sIndexSet
 mov x2,x0
 load x0,gTable
 mov x3,#0
 msg sSelectIndexes
1:
 bl preview_update
9:
 leave
selection_changed:
 enter
 load x0,gTable
 msg sSelectedRow
 store x0,gSelected
 bl preview_update
 leave
preview_update:
 enter
 bl selected
 cbz x0,8f
 mov x19,x0
 load x1,gTextKey
 bl field
 mov x20,x0
 mov x2,x0
 load x0,gPreview
 msg sSetString
 mov x0,x20
 msg sLength
 mov x21,x0
 mov x0,x19
 bl entry_date
 msg sUTF8String
 // Darwin variadic arguments go on stack after the fixed arguments.
 mov x9,x0
 addr x0,gFormatBuffer
 mov x1,#1024
 addr x2,tDetailsFormat
 sub sp,sp,#16
 stp x21,x9,[sp]
 bl _snprintf
 add sp,sp,#16
 addr x0,gFormatBuffer
 bl string
 mov x22,x0
 mov x0,x19
 bl style_details
 mov x2,x0
 mov x0,x22
 msg sAppend
 mov x2,x0
 load x0,gDetails
 msg sValue
 bl preview_font
 leave
8:
 stringlit tEmpty
 mov x2,x0
 load x0,gPreview
 msg sSetString
 stringlit tZero
 mov x2,x0
 load x0,gDetails
 msg sValue
 bl preview_font
 leave
preview_font:
 enter
 bl selected
 bl style_dictionary
 mov x19,x0
 mov x9,#13
 ucvtf d0,x9
 str d0,[sp,#104]
 cbz x19,1f
 mov x0,x19
 addr x1,kFontSize
 bl style_value
 cbz x0,1f
 msg sDouble
 fcmp d0,#0.0
 b.le 1f
 str d0,[sp,#104]
1:
 klass cFont
 mov x20,x0
 cbz x19,2f
 mov x0,x19
 addr x1,kFontName
 bl style_value
 cbz x0,2f
 mov x21,x0
 klass cString
 mov x2,x0
 mov x0,x21
 msg sIsKind
 cbz w0,2f
 addr x0,sNamedFont
 bl _sel_registerName
 mov x1,x0
 mov x0,x20
 mov x2,x21
 ldr d0,[sp,#104]
 bl _objc_msgSend
 cbnz x0,3f
2:
 addr x0,sMonoFont
 bl _sel_registerName
 mov x1,x0
 mov x0,x20
 ldr d0,[sp,#104]
 fmov d1,xzr
 bl _objc_msgSend
3:
 mov x21,x0
 mov x22,#0
 cbz x19,5f
 mov x0,x19
 addr x1,kFontWeight
 bl style_value
 cbz x0,4f
 msg sInteger
 cmp x0,#700
 b.lt 4f
 orr x22,x22,#2
4:
 mov x0,x19
 addr x1,kItalic
 bl style_value
 cbz x0,5f
 msg sBool
 cbz w0,5f
 orr x22,x22,#1
5:
 cbz x22,6f
 klass cFontManager
 msg sFontManager
 mov x2,x21
 mov x3,x22
 msg sConvertFont
 mov x21,x0
6:
 mov x0,x21
 mov x2,x0
 load x0,gPreview
 msg sSetFont
 mov x21,#0
 cbz x19,7f
 mov x0,x19
 addr x1,kForeground
 bl style_value
 cbz x0,7f
 msg sInteger
 mov x21,x0
7:
 mov x0,x21
 bl color_ref
 mov x2,x0
 load x0,gPreview
 msg sTextColor
 mov x21,#0xffffff
 cbz x19,8f
 mov x0,x19
 addr x1,kBackground
 bl style_value
 cbz x0,8f
 msg sInteger
 mov x21,x0
8:
 mov x0,x21
 bl color_ref
 mov x2,x0
 load x0,gPreview
 msg sBackgroundColor
 leave
style_dictionary:
 enter
 cbz x0,9f
 load x1,gStyleKey
 bl field
 mov x19,x0
 klass cImmutableDictionary
 mov x2,x0
 mov x0,x19
 msg sIsKind
 cbz w0,9f
 mov x0,x19
 leave
9:
 mov x0,#0
 leave
// x0 dictionary, x1 C key -> value, mapping NSNull to nil.
style_value:
 enter
 mov x19,x0
 mov x0,x1
 bl string
 mov x2,x0
 mov x0,x19
 msg sObjectForKey
 mov x20,x0
 cbz x20,9f
 klass cNull
 mov x2,x0
 mov x0,x20
 msg sIsKind
 cbnz w0,9f
 mov x0,x20
 leave
9:
 mov x0,#0
 leave
has_style:
 enter
 bl style_dictionary
 mov x19,x0
 cbz x19,9f
 mov x20,#0
 addr x21,style_keys
1:
 mov x0,x19
 ldr x1,[x21,x20,lsl #3]
 bl style_value
 cbz x0,2f
 cbnz x20,8f
 msg sLength
 cbnz x0,8f
2:
 add x20,x20,#1
 cmp x20,#6
 b.lt 1b
9:
 mov x0,#0
 leave
8:
 mov x0,#1
 leave
color_ref:
 enter
 mov x19,x0
 klass cColor
 mov x20,x0
 addr x0,sRGB
 bl _sel_registerName
 mov x1,x0
 mov x0,x20
 mov x9,#255
 ucvtf d4,x9
 and x9,x19,#255
 ucvtf d0,x9
 fdiv d0,d0,d4
 lsr x19,x19,#8
 and x9,x19,#255
 ucvtf d1,x9
 fdiv d1,d1,d4
 lsr x19,x19,#8
 and x9,x19,#255
 ucvtf d2,x9
 fdiv d2,d2,d4
 fmov d3,#1.0
 bl _objc_msgSend
 leave
style_details:
 enter
 bl style_dictionary
 mov x19,x0
 cbz x19,9f
 klass cArray
 msg sArray
 mov x20,x0
 mov x0,x19
 addr x1,kFontName
 bl style_value
 cbz x0,1f
 mov x21,x0
 msg sLength
 cbz x0,1f
 mov x0,x20
 mov x2,x21
 msg sAddObject
1:
 mov x0,x19
 addr x1,kFontSize
 bl style_value
 cbz x0,2f
 msg sDouble
 fcmp d0,#0.0
 b.le 2f
 fcvtas x9,d0
 sub sp,sp,#16
 str x9,[sp]
 addr x0,gStyleNumber
 mov x1,#64
 addr x2,tPointFormat
 bl _snprintf
 add sp,sp,#16
 addr x0,gStyleNumber
 bl string
 mov x2,x0
 mov x0,x20
 msg sAddObject
2:
 mov x0,x19
 addr x1,kFontWeight
 bl style_value
 cbz x0,3f
 msg sInteger
 cmp x0,#700
 b.lt 3f
 stringlit tBold
 mov x2,x0
 mov x0,x20
 msg sAddObject
3:
 mov x0,x19
 addr x1,kItalic
 bl style_value
 cbz x0,4f
 msg sBool
 cbz w0,4f
 stringlit tItalic
 mov x2,x0
 mov x0,x20
 msg sAddObject
4:
 mov x0,x20
 msg sCount
 cbz x0,9f
 stringlit tComma
 mov x2,x0
 mov x0,x20
 msg sJoin
 mov x21,x0
 stringlit tStylePrefix
 mov x2,x21
 msg sAppend
 leave
9:
 stringlit tEmpty
 leave
status:
 enter
 bl string
 mov x2,x0
 load x0,gStatus
 msg sValue
 leave
remove_click:
 enter
 load x19,gSelected
 tbnz x19,#63,9f
 load x0,gHistory
 msg sCount
 cmp x19,x0
 b.hs 9f
 load x0,gHistory
 mov x2,x19
 msg sRemoveIndex
 load x0,gHistory
 msg sCount
 cmp x19,x0
 b.lt 1f
 sub x19,x0,#1
 store x19,gSelected
1:
 bl save_history
 bl refresh
 addr x0,tRemoved
 bl status
9:
 leave
clear_click:
 enter
 load x0,gHistory
 msg sRemoveAll
 mov x0,#-1
 store x0,gSelected
 bl save_history
 bl refresh
 addr x0,tCleared
 bl status
 leave
close_window:
 enter
 bl stop
 load x0,gTap
 cbz x0,1f
 mov x1,#0
 bl _CGEventTapEnable
1:
 load x0,gApp
 mov x2,#0
 msg sTerminate
 leave

accessibility_init:
 enter
 bl _AXIsProcessTrusted
 cbz w0,8f
 mov x0,#0
 mov x1,#0
 mov x2,#0
 mov x3,#1024
 addr x4,event_tap
 mov x5,#0
 bl _CGEventTapCreate
 store x0,gTap
 cbz x0,8f
 mov x1,x0
 mov x0,#0
 mov x2,#0
 bl _CFMachPortCreateRunLoopSource
 store x0,gRunSource
 cbz x0,8f
 bl _CFRunLoopGetCurrent
 load x1,gRunSource
 adrp x2,_kCFRunLoopCommonModes@GOTPAGE
 ldr x2,[x2,_kCFRunLoopCommonModes@GOTPAGEOFF]
 ldr x2,[x2]
 bl _CFRunLoopAddSource
 load x0,gTap
 mov x1,#1
 bl _CGEventTapEnable
 leave
8:
 addr x0,tPermission
 bl status
 leave
event_tap:
 enter
 mov x19,x2
 mov w9,#-2
 cmp w1,w9
 b.eq 7f
 mov w9,#-1
 cmp w1,w9
 b.eq 7f
 cmp w1,#10
 b.ne 9f
 mov x0,x19
 bl _CGEventGetFlags
 and x0,x0,#0xc0000
 mov x9,#0xc0000
 cmp x0,x9
 b.ne 9f
 mov x0,x19
 mov x1,#9
 bl _CGEventGetIntegerValueField
 cmp x0,#8
 b.eq 1f
 cmp x0,#9
 b.eq 2f
 cmp x0,#7
 b.ne 9f
 bl stop
 b 6f
1:
 bl capture
 b 6f
2:
 bl start_typing
6:
 mov x0,#0
 leave
7:
 load x0,gTap
 mov x1,#1
 bl _CGEventTapEnable
9:
 mov x0,x19
 leave
capture:
 enter
 bl _AXUIElementCreateSystemWide
 mov x19,x0
 stringlit tAXFocus
 mov x1,x0
 mov x0,x19
 add x2,sp,#104
 str xzr,[sp,#104]
 bl _AXUIElementCopyAttributeValue
 cbnz w0,7f
 ldr x20,[sp,#104]
 stringlit tAXSelection
 mov x1,x0
 mov x0,x20
 add x2,sp,#112
 str xzr,[sp,#112]
 bl _AXUIElementCopyAttributeValue
 cbnz w0,6f
 ldr x21,[sp,#112]
 cbz x21,6f
 klass cCharacterSet
 msg sWhitespace
 mov x2,x0
 mov x0,x21
 msg sTrim
 msg sLength
 cbz x0,5f
 mov x0,x21
 bl add_text
 bl save_history
 bl refresh
 mov x0,x21
 msg sLength
 sub sp,sp,#16
 str x0,[sp]
 addr x0,gFormatBuffer
 mov x1,#1024
 addr x2,tCapturedFormat
 bl _snprintf
 add sp,sp,#16
 addr x0,gFormatBuffer
 bl status
 mov x0,x21
 bl _CFRelease
 mov x0,x20
 bl _CFRelease
 mov x0,x19
 bl _CFRelease
 leave
5:
 mov x0,x21
 bl _CFRelease
6:
 mov x0,x20
 bl _CFRelease
7:
 mov x0,x19
 bl _CFRelease
 addr x0,tNoSelection
 bl status
 leave
start_typing:
 enter
 load x0,gTypingText
 cbnz x0,9f
 bl selected
 cbz x0,8f
 load x1,gTextKey
 bl field
 msg sRetain
 store x0,gTypingText
 mov x0,#0
 store x0,gTypingIndex
 mov x0,#10
 store x0,gWaitTicks
 addr x0,tRelease
 bl status
 b 9f
8:
 addr x0,tNoItem
 bl status
9:
 leave
stop:
 enter
 load x0,gTypingText
 cbz x0,9f
 msg sRelease
 mov x0,#0
 store x0,gTypingText
 addr x0,tStopped
 bl status
9:
 leave
tick:
 enter
 load x19,gTypingText
 cbz x19,9f
 load x0,gWaitTicks
 cbz x0,1f
 sub x0,x0,#1
 store x0,gWaitTicks
 b 9f
1:
 mov x0,x19
 msg sLength
 mov x20,x0
 load x21,gTypingIndex
 cmp x21,x20
 b.hs 7f
 mov x0,x19
 mov x2,x21
 msg sCharAtIndex
 strh w0,[sp,#104]
 mov x0,#0
 mov x1,#0
 mov x2,#1
 bl _CGEventCreateKeyboardEvent
 mov x22,x0
 mov x0,#0
 mov x1,#0
 mov x2,#0
 bl _CGEventCreateKeyboardEvent
 mov x23,x0
 cbz x22,6f
 cbz x23,6f
 mov x0,x22
 mov x1,#0
 bl _CGEventSetFlags
 mov x0,x23
 mov x1,#0
 bl _CGEventSetFlags
 mov x0,x22
 mov x1,#1
 add x2,sp,#104
 bl _CGEventKeyboardSetUnicodeString
 mov x0,x23
 mov x1,#1
 add x2,sp,#104
 bl _CGEventKeyboardSetUnicodeString
 mov x0,#0
 mov x1,x22
 bl _CGEventPost
 mov x0,#0
 mov x1,x23
 bl _CGEventPost
 mov x0,x22
 bl _CFRelease
 mov x0,x23
 bl _CFRelease
 add x21,x21,#1
 store x21,gTypingIndex
 sub sp,sp,#16
 stp x21,x20,[sp]
 addr x0,gFormatBuffer
 mov x1,#1024
 addr x2,tTypingFormat
 bl _snprintf
 add sp,sp,#16
 addr x0,gFormatBuffer
 bl status
 b 9f
6:
 cbz x22,61f
 mov x0,x22
 bl _CFRelease
61:
 cbz x23,62f
 mov x0,x23
 bl _CFRelease
62:
 bl stop
 addr x0,tFailed
 bl status
 b 9f
7:
 bl stop
 sub sp,sp,#16
 str x20,[sp]
 addr x0,gFormatBuffer
 mov x1,#1024
 addr x2,tTypedFormat
 bl _snprintf
 add sp,sp,#16
 addr x0,gFormatBuffer
 bl status
9:
 leave
self_test:
 enter
 stringlit tTestText
 bl add_text
 stringlit tTestOther
 bl add_text
 stringlit tTestText
 bl add_text
 load x0,gHistory
 msg sCount
 cmp x0,#2
 b.ne 8f
 bl save_history
 cbz w0,8f
 load x0,gHistory
 msg sRemoveAll
 bl load_history
 load x0,gHistory
 msg sCount
 cmp x0,#2
 b.ne 8f
 mov x19,#0
1:
 sub sp,sp,#16
 str x19,[sp]
 addr x0,gFormatBuffer
 mov x1,#1024
 addr x2,tItemFormat
 bl _snprintf
 add sp,sp,#16
 addr x0,gFormatBuffer
 bl string
 bl add_text
 add x19,x19,#1
 cmp x19,#60
 b.lt 1b
 load x0,gHistory
 msg sCount
 cmp x0,#50
 b.ne 8f
 addr x0,tPass
 bl _puts
 mov w0,#0
 leave
8:
 addr x0,tFail
 bl _puts
 mov w0,#1
 leave

.section __TEXT,__cstring,cstring_literals
cObject: .asciz "NSObject"
cApplication: .asciz "NSApplication"
cWindow: .asciz "NSWindow"
cButton: .asciz "NSButton"
cLabel: .asciz "NSTextField"
cScroll: .asciz "NSScrollView"
cTextView: .asciz "NSTextView"
cTable: .asciz "NSTableView"
cColumn: .asciz "NSTableColumn"
cString: .asciz "NSString"
cFont: .asciz "NSFont"
cFontManager: .asciz "NSFontManager"
cColor: .asciz "NSColor"
cTimer: .asciz "NSTimer"
cPool: .asciz "NSAutoreleasePool"
cArray: .asciz "NSMutableArray"
cImmutableArray: .asciz "NSArray"
cDictionary: .asciz "NSMutableDictionary"
cImmutableDictionary: .asciz "NSDictionary"
cNull: .asciz "NSNull"
cDate: .asciz "NSDate"
cISO: .asciz "NSISO8601DateFormatter"
cDateFormatter: .asciz "NSDateFormatter"
cData: .asciz "NSData"
cJSON: .asciz "NSJSONSerialization"
cFileManager: .asciz "NSFileManager"
cIndexSet: .asciz "NSIndexSet"
cCharacterSet: .asciz "NSCharacterSet"
cSplit: .asciz "NSSplitView"
cView: .asciz "NSView"
sAlloc: .asciz "alloc"
sInit: .asciz "init"
sRetain: .asciz "retain"
sRelease: .asciz "release"
sShared: .asciz "sharedApplication"
sPolicy: .asciz "setActivationPolicy:"
sWindowInit: .asciz "initWithContentRect:styleMask:backing:defer:"
sTitle: .asciz "setTitle:"
sFrame: .asciz "initWithFrame:"
sContent: .asciz "contentView"
sAddSubview: .asciz "addSubview:"
sCenter: .asciz "center"
sShow: .asciz "makeKeyAndOrderFront:"
sActivate: .asciz "activateIgnoringOtherApps:"
sRun: .asciz "run"
sTerminate: .asciz "terminate:"
sDelegate: .asciz "setDelegate:"
sTarget: .asciz "setTarget:"
sAction: .asciz "setAction:"
sBezel: .asciz "setBezelStyle:"
sSetString: .asciz "setString:"
sValue: .asciz "setStringValue:"
sUTF8: .asciz "stringWithUTF8String:"
sUTF8String: .asciz "UTF8String"
sEditable: .asciz "setEditable:"
sBordered: .asciz "setBordered:"
sBackground: .asciz "setDrawsBackground:"
sAutoresizing: .asciz "setAutoresizingMask:"
sDocument: .asciz "setDocumentView:"
sVScroll: .asciz "setHasVerticalScroller:"
sHScroll: .asciz "setHasHorizontalScroller:"
sHResizable: .asciz "setHorizontallyResizable:"
sMaxSize: .asciz "setMaxSize:"
sTextContainer: .asciz "textContainer"
sTracksWidth: .asciz "setWidthTracksTextView:"
sContainerSize: .asciz "setContainerSize:"
sColumnInit: .asciz "initWithIdentifier:"
sAddColumn: .asciz "addTableColumn:"
sWidth: .asciz "setWidth:"
sDataSource: .asciz "setDataSource:"
sHeader: .asciz "setHeaderView:"
sReload: .asciz "reloadData"
sSelectedRow: .asciz "selectedRow"
sSelectIndexes: .asciz "selectRowIndexes:byExtendingSelection:"
sIndexSet: .asciz "indexSetWithIndex:"
sMonoFont: .asciz "monospacedSystemFontOfSize:weight:"
sNamedFont: .asciz "fontWithName:size:"
sFontManager: .asciz "sharedFontManager"
sConvertFont: .asciz "convertFont:toHaveTrait:"
sRGB: .asciz "colorWithCalibratedRed:green:blue:alpha:"
sTextColor: .asciz "setTextColor:"
sBackgroundColor: .asciz "setBackgroundColor:"
sDouble: .asciz "doubleValue"
sInteger: .asciz "integerValue"
sBool: .asciz "boolValue"
sArray: .asciz "array"
sJoin: .asciz "componentsJoinedByString:"
sSetFont: .asciz "setFont:"
sRemove: .asciz "removeItem:"
sClear: .asciz "clearItems:"
sTick: .asciz "tick:"
sRows: .asciz "numberOfRowsInTableView:"
sCell: .asciz "tableView:objectValueForTableColumn:row:"
sChange: .asciz "tableViewSelectionDidChange:"
sClose: .asciz "windowWillClose:"
sTimer: .asciz "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:"
sCount: .asciz "count"
sLength: .asciz "length"
sObjectAtIndex: .asciz "objectAtIndex:"
sObjectForKey: .asciz "objectForKey:"
sSetObject: .asciz "setObject:forKey:"
sEqual: .asciz "isEqual:"
sRemoveIndex: .asciz "removeObjectAtIndex:"
sRemoveLast: .asciz "removeLastObject"
sRemoveAll: .asciz "removeAllObjects"
sInsert: .asciz "insertObject:atIndex:"
sAddObject: .asciz "addObject:"
sDictionary: .asciz "dictionary"
sNull: .asciz "null"
sDate: .asciz "date"
sStringFromDate: .asciz "stringFromDate:"
sDateFromString: .asciz "dateFromString:"
sFormatOptions: .asciz "setFormatOptions:"
sSortFunction: .asciz "sortUsingFunction:context:"
sCompare: .asciz "compare:"
sDateStyle: .asciz "setDateStyle:"
sTimeStyle: .asciz "setTimeStyle:"
sAppendPath: .asciz "stringByAppendingPathComponent:"
sDefaultManager: .asciz "defaultManager"
sCreateDir: .asciz "createDirectoryAtPath:withIntermediateDirectories:attributes:error:"
sJSONData: .asciz "dataWithJSONObject:options:error:"
sJSONObject: .asciz "JSONObjectWithData:options:error:"
sBytes: .asciz "bytes"
sWriteFile: .asciz "writeToFile:atomically:"
sReadFile: .asciz "dataWithContentsOfFile:"
sIsKind: .asciz "isKindOfClass:"
sCharAtIndex: .asciz "characterAtIndex:"
sReplace: .asciz "stringByReplacingOccurrencesOfString:withString:"
sTrim: .asciz "stringByTrimmingCharactersInSet:"
sWhitespace: .asciz "whitespaceAndNewlineCharacterSet"
sSubstring: .asciz "substringToIndex:"
sAppend: .asciz "stringByAppendingString:"
sVertical: .asciz "setVertical:"
sDividerStyle: .asciz "setDividerStyle:"
sSplitPosition: .asciz "setPosition:ofDividerAtIndex:"
sMinSize: .asciz "setMinSize:"
eVoid: .asciz "v@:@"
eRows: .asciz "q@:@"
eCell: .asciz "@@:@@q"
tTitle: .asciz "Copy Pasta ASM"
tDelegate: .asciz "CopyPastaAssemblyARM64Delegate"
tRemove: .asciz "Remove"
tClear: .asciz "Clear"
tHelp: .asciz "Ctrl+Alt+C capture | Ctrl+Alt+V type | Ctrl+Alt+X stop"
tHistory: .asciz "History"
tPreview: .asciz "Selected text"
tReady: .asciz "Ready"
tZero: .asciz "0 characters"
tRichPrefix: .asciz "[Rich text] "
tStylePrefix: .asciz " | "
tPointFormat: .asciz "%u pt"
tComma: .asciz ", "
tBold: .asciz "bold"
tItalic: .asciz "italic"
tEmpty: .asciz ""
tCR: .asciz "\r"
tLF: .asciz "\n"
tTab: .asciz "\t"
tSpace: .asciz " "
tTwoSpaces: .asciz "  "
tEllipsis: .asciz "..."
tWhitespace: .asciz "(whitespace)"
tEnv: .asciz "COPY_PASTA_HISTORY"
tDirectory: .asciz "Library/Application Support/CopyPastaAsm"
tFilename: .asciz "history.json"
tTest: .asciz "--self-test"
tRoundtrip: .asciz "--roundtrip"
tTestText: .asciz "Hello\r\nassembly \303\251 \360\237\215\235\t\"\\"
tTestOther: .asciz "Another item"
tItemFormat: .asciz "item %u"
tPass: .asciz "PASS: ARM64 history, promotion, cap, Unicode JSON round trip"
tFail: .asciz "FAIL: ARM64 self-test"
tDetailsFormat: .asciz "%u characters captured %s"
tCapturedFormat: .asciz "Captured %u character text item from macOS Accessibility."
tTypingFormat: .asciz "Typing %u/%u characters..."
tTypedFormat: .asciz "Typed %u characters."
tRemoved: .asciz "Removed history item."
tCleared: .asciz "History cleared."
tPermission: .asciz "macOS Accessibility/Input Monitoring permission is required for capture and typing."
tAXFocus: .asciz "AXFocusedUIElement"
tAXSelection: .asciz "AXSelectedText"
tNoSelection: .asciz "No supported selection found."
tNoItem: .asciz "No history item selected."
tRelease: .asciz "Release Ctrl+Alt+V to continue."
tStopped: .asciz "Typing stopped."
tFailed: .asciz "Typing failed: could not create a keyboard event."
kText: .asciz "Text"
kStyle: .asciz "Style"
kDate: .asciz "CapturedAt"
kFontName: .asciz "FontName"
kFontSize: .asciz "FontSize"
kFontWeight: .asciz "FontWeight"
kItalic: .asciz "IsItalic"
kForeground: .asciz "ForegroundColor"
kBackground: .asciz "BackgroundColor"
.data
.p2align 3
style_keys: .quad kFontName,kFontSize,kFontWeight,kItalic,kForeground,kBackground
dInterval: .double 0.012
gPool: .quad 0
gApp: .quad 0
gWindow: .quad 0
gContent: .quad 0
gRoot: .quad 0
gSplit: .quad 0
gLeft: .quad 0
gRight: .quad 0
gDelegate: .quad 0
gHistory: .quad 0
gSelected: .quad -1
gTable: .quad 0
gPreview: .quad 0
gDetails: .quad 0
gStatus: .quad 0
gPath: .quad 0
gISO: .quad 0
gISOFractional: .quad 0
gDateFormatter: .quad 0
gTextKey: .quad 0
gStyleKey: .quad 0
gDateKey: .quad 0
gTap: .quad 0
gRunSource: .quad 0
gTypingText: .quad 0
gTypingIndex: .quad 0
gWaitTicks: .quad 0
.zerofill __DATA,__bss,gFormatBuffer,1024,3
.zerofill __DATA,__bss,gStyleNumber,64,3
