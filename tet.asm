        .project tet.bin

BANKING equ     0C1h

MAP32K  equ     0x01
ENROM   equ     0x10

XY      equ     1010h
SCREEN  equ     0c000h

WARMBOOT equ    0e003h
KBDSTAT equ     0e006h
KBDREAD equ     0e009h

OFFSET_X equ    2
OFFSET_Y equ    2

Row     equ     CurPos
Col     equ     CurPos+1

        org     1000h

        call    ClearScreen
        call    BuildTheWall

Begin

        lxi     h, BITMAP1
        call    PaintCursor

        ; Ввод с клавиатуры
        call    KBDREAD

        push    a
        lxi     h, BITMAP0
        call    PaintCursor
        pop     a


        cpi     0x1b            ; ESC?
        jnz     Space
        jmp     WARMBOOT        ; возврат в Монитор

Space   cpi     ' '
        jnz     Left
        lda     INV
        cma
        sta     INV
        jmp     Paint

Left    cpi     8
        jz      CurLeft

Right   cpi     18h
        jz      CurRight
        
Up      cpi     19h
        jz      CurUp
        
Down    cpi     1ah
        jnz     Begin

        
CurDown lda     Row
        cpi     8*8
        jz      Paint
        adi     8
        sta     Row
        jmp     Paint
CurLeft
        lda     Col
        cpi     2
        jz      Paint
        sbi     2
        sta     Col
        jmp     Paint
CurRight
        lda     Col
        cpi     16
        jz      Paint
        adi     2
        sta     Col
        jmp     Paint
CurUp
        lda     Row
        cpi     8
        jz      Paint
        sbi     8
        sta     Row
        jmp     Paint
        

        ; Рисуем
Paint

        lxi     h, BITMAP1
        call    PaintCursor
        jmp     Begin

; PaintCursor - нарисовать битмап 8х8
; HL - адрес битмапа
; BC - X и Y
PaintCursor
        di
        ; Отключаем ПЗУ для доступа к экранному ОЗУ
        mvi     a, ENROM
        out     BANKING
        
        push    h
        lxi     h, SCREEN
        lda     Col
        mov     d, a
        mvi     e, 0
        dad     d       ; hl = SCREEN + X*256
        mvi     d, 0
        lda     Row
        mov     e, a
        dad     d       ; hl = hl + Y
        pop     d       ; de = адрес битмапа

        mvi     c, 8
PBLoop  ldax    d
        mov     m, a
        inx     d
        inx     h
        dcr     c
        jnz     PBLoop

        ; Включаем ПЗУ обратно
        xra     a
        out     BANKING
        
        ei
        ret

; ClearScreen
ClearScreen
        di
        mvi     a, ENROM
        out     BANKING
        
        lxi     h, SCREEN
        lxi     b, 256*64
        
Cls     mvi     m, 0
        inx     h
        dcx     b
        mov     a, b
        ora     c
        jnz     Cls
        
        xra     a
        out     BANKING
        ei
        ret

; BuildTheWall
BuildTheWall
        lxi     h, WALL
BTW        
        mov     a, m
        cpi     0ffh
        jz      WallDone
        
        ora     a
        ral
        ral
        ral
        mov     c, a
        inx     h
        mov     a, m
        ral
        mov     b, a
        inx     h
        call    DoBlock
        jmp     BTW
WallDone        
        ret

DoBlock
        push    h
        lxi     h, BRICK
        call    PaintBlock
        pop     h
        ret

; PaintBlock
PaintBlock
        di

        mvi     a, ENROM
        out     BANKING
        
        push    h
        lxi     h, SCREEN
        mov     d, b
        mvi     e, 0
        dad     d       ; hl = SCREEN + X*256
        mvi     d, 0
        mov     e, c
        dad     d       ; hl = hl + Y
        pop     d       ; de = адрес битмапа

        mvi     c, 8
BlockLoop
        ldax    d
        mov     m, a
        inx     d
        inx     h
        dcr     c
        jnz     PBLoop

        xra     a
        out     BANKING
        
        ei
        ret


BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0        
BITMAP1
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        
BRICK   db      0b00000000
        db      0b01111110
        db      0b01000010
        db      0b01000010
        db      0b01000010
        db      0b01000010
        db      0b01111110
        db      0b00000000

WALL    db      0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0
        db      9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9, 9
        db      0, 9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9
        db      0ffh, 0ffh
        
INV     db      0

CurPos  dw      0808h
