        .project tet.bin

SCROLL_V equ    0C0h
BANKING equ     0C1h
SCROLL_VH equ   0C2h

MAP32K  equ     0x01
ENROM   equ     0x10

XY      equ     0308h
SCREEN  equ     0c000h

WARMBOOT equ    0e003h
KBDSTAT equ     0e006h
KBDREAD equ     0e009h

OFFSET_X equ    2
OFFSET_Y equ    2

Row     equ     CurPos
Col     equ     CurPos+1

        org     1000h

; Инициализация важных и нужных переменных
        lxi     h, XY
        shld    CurPos

; Чистим экран и рисуем нетленку
        call    ResetScroll
        call    ClearScreen
        call    BuildTheWall
        call    UnpackWorkBitmap

Begin

        call    PaintCursor


        ; Ввод с клавиатуры
        call    KBDREAD

        push    a
        call    EraseCursor
        pop     a


        cpi     0x1b            ; ESC?
        jnz     Space
        jmp     WARMBOOT        ; возврат в Монитор

Space   cpi     ' '
        jnz     Left
;        lda     INV
;        cma
;        sta     INV
        call    InvertDot
        call    PackWorkBitmap
        call    PaintWorkBitmap
        jmp     Begin

Left    cpi     8
        jz      CurLeft

Right   cpi     18h
        jz      CurRight
        
Up      cpi     19h
        jz      CurUp
        
Down    cpi     1ah
        jnz     Begin

; *************************************************
; * Правим координаты курсора
; *************************************************
MARGIN_BOT      equ     8*8
MARGIN_LEFT     equ     1+2
MARGIN_RIGHT    equ     1+16
MARGIN_TOP      equ     8
        
CurDown lda     Row
        cpi     MARGIN_BOT
        jz      Paint
        adi     8
        sta     Row
        jmp     Paint
CurLeft
        lda     Col
        cpi     MARGIN_LEFT
        jz      Paint
        sbi     2
        sta     Col
        jmp     Paint
CurRight
        lda     Col
        cpi     MARGIN_RIGHT
        jz      Paint
        adi     2
        sta     Col
        jmp     Paint
CurUp
        lda     Row
        cpi     MARGIN_TOP
        jz      Paint
        sbi     8
        sta     Row
        jmp     Paint
        

; Рисуем
Paint
        call    PaintCursor
        jmp     Begin

; *************************************************
; PaintCursor
; *************************************************
PaintCursor
        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, BITMAP55
        call    PaintBitmap
        ret
; *************************************************
; Вывести вместо курсора картинку, соответствующую 
; точке из рабочего битмапа
; *************************************************
EraseCursor

        lda     Row             ; строка (координата Y)
        sui     8               ; отнять смещение
        rar
        rar
        rar                     ; и поделить на 8
        ani     7
        mov     l, a
        mvi     h, 0
        lxi     d, WORKBMP
        dad     d               ; hl = WORKBMP + строка
        
        lda     Col             ; координата X
        sui     2               ; минус смещение
        rar                     ; и поделить на 2 для цветного режима
        
        sui     0fh             ; отзеркалить
        ani     7
        dcr     a
        mov     c, a            ; это будет счетчик для сдвига
        
        mov     a, m            ; добыли нужную строчку пикселей
ECLoop
        dcr     c
        jm      ECNext
        rar
        jmp     ECLoop

ECNext  
        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, BMPDOT
        ani     0x01
        jz      ECNextNext
        lxi     h, BITMAP1
ECNextNext                
        
        call    PaintBitmap
        ret

; *************************************************
; InvertDot
; Точку рисуем в первой цветовой плоскости (курсор во второй)
; *************************************************
InvertDot
        lhld    CurPos
        mov     c, l
        mov     b, h
        dcr     b
        lxi     h, BITMAP1
        call    PaintBitmap
        ret

; *************************************************
; Собрать рабочий битмап из экранной области
; *************************************************
PackWorkBitmap
        ret

; *************************************************
; Распаковать рабочий битмап в экран
;       (нарисовать биты квадратиками)
; *************************************************
UnpackWorkBitmap
        lxi     b, 0x0308
        mvi     e, 8
        lxi     h, COOLBRICK
UnpLoop        
        mov     a, m
        call    PaintByteWithBitmaps
        mvi     a, 8
        add     c
        mov     c, a
        inx     h
        dcr     e
        jnz     UnpLoop
        
        ret

; *************************************************
; Нарисовать байт битмапами
; *************************************************
PaintByteWithBitmaps
        push    bc
        push    de
        push    hl
        mvi     e, 8   
Loopp        
        rrc
        lxi     h, BMPDOT
        jnc     Looppp
        lxi     h, BITMAP1
Looppp
        push    a
        call    PaintBitmap
        pop     a
        
        inr     b
        inr     b
        
        dcr     e
        jnz     Loopp

        pop     hl
        pop     de
        pop     bc
        ret



; *************************************************
; PaintBitmap - нарисовать битмап 8х8
; HL - адрес битмапа
; BC - X и Y
; *************************************************
PaintBitmap
        di
        push    a
        push    bc
        push    de
        ; Отключаем ПЗУ для доступа к экранному ОЗУ
        mvi     a, ENROM
        out     BANKING
        
        push    h
        lxi     h, SCREEN
;        lda     Col
        mov     d, b
        mvi     e, 0
        dad     d       ; hl = SCREEN + X*256
        mvi     d, 0
;        lda     Row
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
        
        pop     de
        pop     bc
        pop     a
        ei
        ret

; *************************************************
; ClearScreen
; *************************************************
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
; *************************************************
; BuildTheWall
; *************************************************
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
        lxi     h, COOLBRICK
        call    PaintBitmap
        pop     h
        ret

; Установить нулевые смещения для вертикальной и горизонтальной прокруток        
ResetScroll
        xra     a
        out     SCROLL_V
        out     SCROLL_VH
        ret

; *************************************************
; Вывести рабочий битмап
; *************************************************
PaintWorkBitmap
        mvi     b, 12*2
        mvi     c, 8
        lxi     h, COOLBRICK    ;WORKBMP
        call    PaintBitmap
        ret

BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0
BITMAP1
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
BITMAP55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55        
BMPDOT  db      0, 1, 0, 1, 0, 1, 0, 0x55
        
BRICK   db      0b00000000
        db      0b01111110
        db      0b01000010
        db      0b01000010
        db      0b01000010
        db      0b01000010
        db      0b01111110
        db      0b00000000
        
COOLBRICK
        db      0b11111110
        db      0b11111100
        db      0b10000000
        db      0b00000000
        db      0b11101111
        db      0b11001111
        db      0b00001000
        db      0b00000000

; Рабочий битмап
WORKBMP
        db      0b11111110
        db      0b11111100
        db      0b10000000
        db      0b00000000
        db      0b11101111
        db      0b11001111
        db      0b00001000
        db      0b00000000


WALL    db      0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0
        db      9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9, 9
        db      0, 9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9
        db      0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8
        db      0ffh, 0ffh
        
        
; Зажечь/погасить квадратик
INV     db      0

; Координаты курсора
CurPos  dw      0
