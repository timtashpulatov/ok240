        .project tet.bin

BANKING equ     0C1h

MAP32K  equ     0x01
ENROM   equ     0x10

XY      equ     1010h
SCREEN  equ     0c000h

WARMBOOT equ    0e003h
KBDSTAT equ     0e006h
KBDREAD equ     0e009h

Row     equ     CurPos
Col     equ     CurPos+1

        org     1000h

Begin
        ; Ввод с клавиатуры
        call    KBDREAD
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
        
Down    cpi     1bh
        jnz     Begin
        
CurDown lda     Row
        inr     a
        sta     Row
        jmp     Paint
CurLeft
        lda     Col
        dcr     a
        sta     Col
        jmp     Paint
CurRight
        lda     Col
        inr     a
        sta     Col
        jmp     Paint
CurUp
        lda     Row
        dcr     a
        sta     Row
        jmp     Paint
        



        ; Рисуем
Paint
        lhld    CurPos
        mov     b, h
        mov     c, l

        lxi     h, BITMAP1
        lda     INV
        ora     a
        jz      Paint1
        lxi     h, BITMAP0
Paint1        
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
        mov     d, b
        mvi     e, 0
        dad     d       ; hl = SCREEN + X*256
        mvi     d, 0
        mov     e, c
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

BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0        
BITMAP1
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        
INV     db      0

CurPos  dw      0505h
