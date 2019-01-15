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
        adi     8
        sta     Row
        jmp     Paint
CurLeft
        lda     Col
        sbi     2
        sta     Col
        jmp     Paint
CurRight
        lda     Col
        adi     2
        sta     Col
        jmp     Paint
CurUp
        lda     Row
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

BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0        
BITMAP1
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        
INV     db      0

CurPos  dw      0808h
