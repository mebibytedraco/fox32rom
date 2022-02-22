; generic text drawing routines

; draw a single font tile to a framebuffer
; inputs:
; r0: tile number
; r1: X coordinate
; r2: Y coordinate
; r3: foreground color
; r4: background color
; r5: pointer to font graphics
; r6: font width
; r7: font height
; r8: pointer to framebuffer
; r9: framebuffer width (pixels)
; outputs:
; none
draw_font_tile_generic:
    push r0
    push r1
    push r2
    push r5
    push r6
    push r7
    push r8
    push r9

    ;movz.8 r0, r0            ; ensure the tile number is a single byte

    ; calculate pointer to the tile data
    push r6
    mul r6, r7
    mul r0, r6
    mul r0, 4                ; 4 bytes per pixel
    add r0, r5               ; r0: pointer to tile data
    pop r6

    ; calculate pointer to the framebuffer
    mul r9, 4                ; 4 bytes per pixel
    mul r2, r9               ; y * width * 4
    mul r1, 4                ; x * 4
    add r1, r2               ; y * width * 4 + (x * 4)
    add r1, r8               ; r1: pointer to framebuffer

    ; r8: font width in bytes
    mov r8, r6
    mul r8, 4

draw_font_tile_generic_y_loop:
    mov r5, r6               ; x counter
draw_font_tile_generic_x_loop:
    mov r2, [r0]
    cmp r2, 0xFF000000
    ifz jmp draw_font_tile_generic_x_loop_background
    ; drawing foreground pixel
    cmp r3, 0x00000000       ; is the foreground color supposed to be transparent?
    ifz jmp draw_font_tile_generic_x_loop_end
    mov [r1], r3             ; draw foreground color
    jmp draw_font_tile_generic_x_loop_end
draw_font_tile_generic_x_loop_background:
    ; drawing background pixel
    cmp r4, 0x00000000       ; is the background color supposed to be transparent?
    ifz jmp draw_font_tile_generic_x_loop_end
    mov [r1], r4             ; draw background color
draw_font_tile_generic_x_loop_end:
    add r0, 4                ; increment tile pointer
    add r1, 4                ; increment framebuffer pointer
    dec r5
    ifnz jmp draw_font_tile_generic_x_loop ; loop if there are still more X pixels to draw
    sub r1, r8               ; return to the beginning of this line
    add r1, r9               ; increment to the next line by adding the framebuffer width in bytes
    dec r7                   ; decrement height counter
    ifnz jmp draw_font_tile_generic_y_loop ; loop if there are still more Y pixels to draw

    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r2
    pop r1
    pop r0
    ret

; draw text to a framebuffer
; inputs:
; r0: pointer to null-terminated string
; r1: X coordinate
; r2: Y coordinate
; r3: foreground color
; r4: background color
; r5: pointer to font graphics
; r6: font width
; r7: font height
; r8: pointer to framebuffer
; r9: framebuffer width
; outputs:
; r1: X coordinate of end of text
draw_str_generic:
    push r0
    push r10
    mov r10, r0
draw_str_generic_loop:
    movz.8 r0, [r10]
    call draw_font_tile_generic
    inc r10
    add r1, r6
    cmp.8 [r10], 0x00
    ifnz jmp draw_str_generic_loop
    pop r10
    pop r0
    ret

; draw a decimal value to a framebuffer
; inputs:
; r0: value
; r1: X coordinate
; r2: Y coordinate
; r3: foreground color
; r4: background color
; r5: pointer to font graphics
; r6: font width
; r7: font height
; r8: pointer to framebuffer
; r9: framebuffer width
; outputs:
; r1: X coordinate of end of text
draw_decimal_generic:
    push r0
    push r10                 ; r10: original stack pointer
    push r11                 ; temp 1
    push r12                 ; temp 2
    push r13                 ; temp 3
    mov r10, rsp
    mov r12, r0

    push.8 0x00              ; end the string with a terminator
draw_decimal_generic_find_loop:
    push r12
    div r12, 10              ; quotient goes into r12
    pop r13
    rem r13, 10              ; remainder goes into r13
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp draw_decimal_generic_find_loop
draw_decimal_generic_print:
    mov r0, rsp              ; point to start of string in the stack
    call draw_str_generic

    mov rsp, r10
    pop r13
    pop r12
    pop r11
    pop r10
    pop r0
    ret