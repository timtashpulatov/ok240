        .project graf.bin

SCROLL_V        equ     0C0h
BANKING         equ     0C1h
SCROLL_VH       equ     0C2h

VIDEO           equ     0E1h

MAP32K          equ     0x01
ENROM           equ     0x10

XY              equ     0208h
SCREEN          equ     0c000h

WARMBOOT        equ     0e003h
KBDSTAT         equ     0e006h
KBDREAD         equ     0e009h
CHAROUT         equ     0e00ch  ; вывести символ из регистра C

OFFSET_X        equ    2
OFFSET_Y        equ    2

Row             equ     CurPos
Col             equ     CurPos+1

        org     1000h

; Инициализация важных и нужных переменных
        lxi     h, XY
        shld    CurPos

; Чистим экран и рисуем нетленку
        call    ResetScroll
        call    ClearScreen
        call    BuildTheWall
        call    DrawPalette
        call    UnpackWorkBitmap

Begin
        call    WorkBitmapPreview
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
        mvi     a, 3
        call    PlaceDot
        call    WorkBitmapPreview
        jmp     Begin

Left    cpi     8
        jz      CurLeft

Right   cpi     18h
        jz      CurRight
        
Up      cpi     19h
        jz      CurUp
        
Down    cpi     1ah
        jz      CurDown

One     cpi     31h
        jz      ColorOne
        
Two     cpi     32h
        jz      ColorTwo
        
Three   cpi     33h
        jz      BothColors
        
Zero    cpi     30h
        jz      NoColors

; Перебор цветов переднего плана и фона
        cpi     'F'
        jz      CycleForeColor
        cpi     'B'
        jz      CycleBackColor

        jmp     Begin

; *************************************************
; *************************************************
CycleForeColor
        in      VIDEO
        inr     a
        ani     7
        ori     40h
        out     VIDEO
        jmp     Begin   ; неэкономно. C9 наше всё
CycleBackColor
        in      VIDEO
        adi     8
        ani     3fh
        ori     40h
        out     VIDEO
        jmp     Begin
        

; *************************************************
; * Правим точку цветом 01, 10 или 11
; *************************************************
NoColors
ColorOne
ColorTwo
BothColors
        ani     3
        call    PlaceDot
        call    UpdateWorkBitmap        
        jmp     Begin

; *************************************************
; * Проапдейтить рабочий битмап точкой
; *************************************************
UpdateWorkBitmap
        push    a
        call    GetBitmapRowPtr
        call    GetBitmapColBitMask
        call    Pops
        lxi     d, 8
        dad     d
        rrc
        call    Pops
        pop     a
        ret

Pops
        push    a
        rrc
        mov     a, c
        jnc     USP1
        ora     m
        ; Установить бит
        jmp     USPDone
USP1    ; Сбросить бит
        cma
        ana     m
USPDone
        mov     m, a
        pop     a
        ret

; *************************************************
; * Вернуть в HL указатель на текущую строчку битмапа
; *************************************************
GetBitmapRowPtr
        push    a
        lxi     b, 0
        lda     Row
        sui     8       ; опять оффсеты
        rar             ; поделить на 8, см. скачки курсора
        rar
        rar
        mov     c, a
        lxi     h, WORKBMP
        dad     b
        pop     a
        ret

; *************************************************
; * Установить в C бит, соответствующий текущему столбцу
; *************************************************
GetBitmapColBitMask
        push    a
        lda     Col
        sui     2               ; отнять смещение (TODO: оформить все эти оффсеты как-то официально)
        rar                     ; поделить на два, т.к. курсор перемещается скачками по 2 (TODO: переделать)
        cma
        ani     7
        inr     a
        mov     c, a
        mvi     a, 0b10000000
GBCLoop
        dcr     c
        jz      GBCDone
        rar
        jmp     GBCLoop
        
GBCDone    
        mov     c, a
        pop     a
        ret

; *************************************************
; * Правим координаты курсора
; *************************************************
MARGIN_BOT      equ     8*8
MARGIN_LEFT     equ     2
MARGIN_RIGHT    equ     16
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
;        call    PaintCursor
        jmp     Begin

; *************************************************
; PaintCursor
; *************************************************
PaintCursor
        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, BITMAP55
        mvi     a, 1
        call    PaintBitmap
        ret
; *************************************************
; Вывести вместо курсора картинку, соответствующую 
; точке из рабочего битмапа
; *************************************************
EraseCursor0
        ret

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

; Адрес нужного байта добыли, займемся номером бита        
        lda     Col             ; координата X
        sui     2               ; минус смещение
        rar                     ; и поделить на 2 для цветного режима
        cma
        ani     7

        inr     a
        mov     c, a            ; это будет счетчик для сдвига
        
        mov     a, m            ; добыли нужную строчку пикселей
ECLoop
        rlc
        dcr     c
        jnz     ECLoop

        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, BMPDOT
        jnc     ECNextNext
        lxi     h, BITMAP1
ECNextNext                
        mvi     a, 3
        call    PaintBitmap
        ret

; *************************************************
; Точку рисуем
; В аккумуляторе номер плоскости 00, 01, 10 или 11
; *************************************************
PlaceDot
        push    a
        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, BITMAP1
; Особый случай - для очистки обоих планов
        ora     a
        jnz     PDT
        lxi     h, BITMAP0
        cma
PDT        
        call    PaintBitmap
        pop     a
        ret


; *************************************************
; Распаковать рабочий битмап в экран
;       (нарисовать биты квадратиками)
; *************************************************
UnpackWorkBitmap
        lxi     b, 0x0208
        call    UnWorBit
;        lxi     b, 0x0308
;        call    UnWorBit
        ret
        
UnWorBit        
        mvi     e, 8
        lxi     h, WORKBMP
UnpLoop        
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
        mov     a, m
Loopp        
        rrc
        lxi     h, BMPDOT
        jnc     Looppp
        lxi     h, BITMAP1
Looppp
        push    a
        mvi     a, 3
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
; A - биты плоскостей
; *************************************************
PaintBitmap
        di
        push    bc
        push    de
        
        push    a
        ; Отключаем ПЗУ для доступа к экранному ОЗУ
        mvi     a, ENROM
        out     BANKING
        
        push    hl
        lxi     h, SCREEN
        mov     d, b
        mvi     e, 0
        dad     d       ; hl = SCREEN + X*256
        mvi     d, 0
        mov     e, c
        dad     d       ; hl = hl + Y
        pop     de       ; de = адрес битмапа

        pop     a       ; плоскости
        
Plane1
        rrc
        jnc     Plane2
        call    Copy8
Plane2        
        rrc
        jnc     PlaneDone

        ; Второй план битмапа
        push    h
        lxi     h, 8
        dad     d
        xchg

        ; Перейдем ко второму плану экрана
        pop     h
        inr     h
        call    Copy8

PlaneDone
        ; Включаем ПЗУ обратно
        xra     a
        out     BANKING
        
        pop     de
        pop     bc
        ei
        ret

Copy8
        push    h
        push    d
        push    a
        mvi     c, 8
PBLoop  ldax    d
        mov     m, a
        inx     d
        inx     h
        dcr     c
        jnz     PBLoop
        pop     a
        pop     d
        pop     h
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
        call    LayBrick
        jmp     BTW
WallDone        
        ret

LayBrick
        push    h
        lxi     h, COOLBRICK
        mvi     a, 1
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
; Показать рабочий битмап в натуральную величину
; *************************************************
WorkBitmapPreview
        mvi     b, 12*2
        mvi     c, 8
        lxi     h, WORKBMP
        mvi     a, 3
        call    PaintBitmap
        ret

; *************************************************
; Нарисовать палитру
; *************************************************
DrawPalette
        lxi     b, 0400h + 11*8
        lxi     h, MAZOK
        mvi     a, 1
        call    PaintBitmap
; Второй цвет        
        lxi     b, 0800h + 11*8
        lxi     h, MAZOK
        mvi     a, 2
        call    PaintBitmap
; Оба цвета
        lxi     b, 0c00h + 11*8
        lxi     h, MAZOK
        mvi     a, 3
        call    PaintBitmap
; Подписать
;        lxi     h, POPS
;        call    PrintString
        ret

; *************************************************
; Напечатать ASCIIZ строчку
; HL - начало строки
; *************************************************
PrintString
        mov     a, m
        ora     a
        jz      PrtStrDone
        mov     c, a
        call    CHAROUT
        inx     h
        jmp     PrintString
PrtStrDone        
        ret

;POPS    db      1bh, 35h, 10, 10,
;        db      '1 2 3', 0

BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
BITMAP1
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
BITMAP55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55        

BMPDOT  db      0, 1, 0, 1, 0, 1, 0, 0x55
        db      0, 1, 0, 1, 0, 1, 0, 0x55

MAZOK   db      255, 255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
        
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
        
        db      0, 0, 0, 0, 0, 0, 0, 0

; Рабочий битмап
WORKBMP
        ; Первый план
        db      0b11111110
        db      0b11111100
        db      0b10000000
        db      0b00000000
        db      0b11101111
        db      0b11001111
        db      0b00001000
        db      0b00000000
        ; Второй план
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