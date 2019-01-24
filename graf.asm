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

WORKBMP         equ     4000h
CURSYS          equ     0bfedh

        org     1000h

; Инициализация важных и нужных переменных
        lxi     h, XY
        shld    CurPos
        lxi     h, WORKBMP
        shld    BmpPtr

; Чистим экран и рисуем нетленку
        call    ResetScroll
        call    ClearScreen
        call    BuildTheWall
        call    DrawPalette
        call    UnpackWorkBitmap
;        call    GoFigure

; Эксперименты с выводом символа без курсора
        mvi     a, 4
        sta     0bfech  ; скажем НЕТ курсору
; Вывести справку по командам
        call    Help

Begin
        call    WorkBitmapPreview
        call    PaintCursor


        ; Ввод с клавиатуры
        call    KBDREAD

        push    a
        call    EraseCursor
        pop     a


;        cpi     0x1b            ; ESC?
;        jnz     Space
;        jmp     WARMBOOT        ; возврат в Монитор

        mov     c, a
        lxi     d, KeyFunctions
Next        
        ldax    d
        ora     a
        jz      Begin
        cmp     c
        jz      Gotcha
        inx     d
        inx     d
        inx     d
        jmp     Next
Gotcha
        inx     d
        ldax    d
        mov     l, a
        inx     d
        ldax    d
        mov     h, a
        mov     a, c
        pchl

; Жумптабле
KeyFunctions
        db      8
        dw      CurLeft
        db      18h
        dw      CurRight
        db      19h
        dw      CurUp
        db      1ah
        dw      CurDown
        
        db      31h
        dw      ColorOne
        db      32h
        dw      ColorTwo
        db      33h
        dw      BothColors
        db      30h
        dw      NoColors
        db      'F'
        dw      CycleForeColor  ; Перебор цветов переднего плана и фона
        db      'B'
        dw      CycleBackColor
        db      'Z'
        dw      Zap
        db      '>'
        dw      SelectNextBitmap
        db      '<'
        dw      SelectPrevBitmap
        db      'C'
        dw      Copy
        db      'P'
        dw      Paste
        
        db      1bh
        dw      WARMBOOT
        db      0
        dw      0


Space   cpi     ' '
;        jnz     Left
;        lda     INV
;        cma
;        sta     INV
        mvi     a, 3
        call    PlaceDot
;        call    WorkBitmapPreview
        jmp     Begin


; *************************************************
; *************************************************
Copy
        lhld    BmpPtr
        lxi     d, CLIPBOARD
CL0        
        mvi     c, 16
CopyLoop
        mov     a, m
        stax    d
        inx     h
        inx     d
        dcr     c
        jnz     CopyLoop
        
        ; Нарисовать клипборд
        lxi     h, CLIPBOARD
        lxi     b, 1800h + 3*8
        mvi     a, 3
        call    PaintBitmap
        
        jmp     RedrawWorkBitmap
Paste
        lhld    BmpPtr
        lxi     d, CLIPBOARD
        xchg
        jmp     CL0

SelectPrevBitmap
        lxi     d, -16
        jmp     SNB
SelectNextBitmap
        lxi     d, 16
SNB        
        lhld    BmpPtr
        dad     d

        shld    BmpPtr
RedrawWorkBitmap        
        lxi     h, XY
        shld    CurPos
        call    UnpackWorkBitmap
        
        jmp     Begin

Zap     lhld    BmpPtr
        mvi     c, 16
Loo     mvi     m, 0
        inx     h
        dcr     c
        jnz     Loo

        lxi     h, XY
        shld    CurPos
        
        call    UnpackWorkBitmap 
        
        jmp     Begin

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
        lhld     BmpPtr
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
        mvi     a, 3
        call    PaintBitmap
        ret

; *************************************************
; Вывести вместо курсора картинку, соответствующую 
; точке из рабочего битмапа
; *************************************************
EraseCursor

        mvi     a, 0
        call    PlaceDot

        lda     Row             ; строка (координата Y)
        sui     8               ; отнять смещение
        rar
        rar
        rar                     ; и поделить на 8
        ani     7
        mov     e, a
        mvi     d, 0
        lhld    BmpPtr
        dad     d               ; hl = WORKBMP + строка

; Адрес нужного байта добыли, займемся номером бита        
        lda     Col             ; координата X
        sui     2               ; минус смещение
        rar                     ; и поделить на 2 для цветного режима
        
        cma
        ani     7

        inr     a
        mov     c, a            ; это будет счетчик для сдвига
        
        mvi     a, 1          ; это будет маска для проверки бита
        
CBLoop        
        rrc
        dcr     c
        jnz     CBLoop
        mov     c, a            ; получили маску в C
        
        mov     a, m
        ana     c
        mvi     a, 1
        jnz     EC2
        xra     a
EC2        
        mov     b, a
        lxi     d, 8
        dad     d
        mov     a, m
        ana     c
        mov     a, b
        jz      EC3
        ori     2
EC3
        call    PlaceDot
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
        lxi     h, BMPDOT
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
Wow0
        
        call    EraseCursor     ; ух ты, стильно!
        
        lda     Col
        adi     2
        cpi     MARGIN_RIGHT+2
        jz      Wow1
        sta     Col
        jmp     Wow0

Wow1
        ;call    Dly
        mvi     a, MARGIN_LEFT
        sta     Col
        lda     Row
        adi     8
        cpi     MARGIN_BOT+8
        jz      Wow2
        sta     Row
        jmp     Wow0
Wow2
        ret

DELAY   equ     2000
; *********************
; Маленькая задержечка
; *********************
Dly
        push    hl
        lxi     h, DELAY
Dly0
        dcx     h
        mov     a, h
        ora     l
        jnz     Dly0
        pop     hl
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
PREVIEW_X       equ     11
PREVIEW_Y       equ     1
WorkBitmapPreview

        lxi     h, (PREVIEW_X-1)*512+PREVIEW_Y*8
        mvi     c, '<'
        call    MYCHAROUT
        lxi     h, (PREVIEW_X+3)*512+PREVIEW_Y*8
        mvi     c, '>'
        call    MYCHAROUT

        lxi     b, PREVIEW_X*512+PREVIEW_Y*8
        lhld    BmpPtr
        push    h
        lxi     d, -16
        dad     d
        mvi     a, 3
        call    PaintBitmap
 
        lxi     b, (PREVIEW_X+1)*512+PREVIEW_Y*8
        pop     hl
        mvi     a, 3
        push    hl
        call    PaintBitmap

        lxi     b, (PREVIEW_X+2)*512+PREVIEW_Y*8
        pop     hl
        lxi     d, 16
        dad     d
        mvi     a, 3
        call    PaintBitmap

; Нарисуем красивую полосочку сверху        
        lxi     b, PREVIEW_X*512
        lxi     h, BOTLINE
        mvi     a, 3
        push    hl
        call    PaintBitmap
        
        lxi     b, (PREVIEW_X+1)*512
        mvi     a, 3
        pop     hl
        push    hl
        call    PaintBitmap        

        lxi     b, (PREVIEW_X+2)*512
        mvi     a, 3
        pop     hl
        call    PaintBitmap        

; И снизу        
        lxi     b, PREVIEW_X*512+(PREVIEW_Y+1)*8
        lxi     h, TOPLINE
        mvi     a, 3
        push    hl
        call    PaintBitmap        

        lxi     b, (PREVIEW_X+1)*512+(PREVIEW_Y+1)*8
        mvi     a, 3
        pop     hl
        push    hl
        call    PaintBitmap        
        
        lxi     b, (PREVIEW_X+2)*512+(PREVIEW_Y+1)*8
        mvi     a, 3
        pop     hl
        call    PaintBitmap        
        ret


PALETTE_X       equ     2
PALETTE_Y       equ     11
; *************************************************
; Нарисовать палитру
; *************************************************
DrawPalette
        lxi     h, 0400h + 11*8
        mvi     c, '1'
        call    MYCHAROUT
; Второй цвет        
        lxi     h, 0900h + 11*8
        inr     c
        call    MYCHAROUT
; Оба цвета
        lxi     h, 0c00h + 11*8
        inr     c
        call    MYCHAROUT
        lxi     h, 0d00h + 11*8
        call    MYCHAROUT

; Подписать
;        mvi     a, 4
;        sta     0xbfec
;        lxi     h, String
;        call    PrintString
        ret

GoFigure
        lxi     b, 1600h + 11*8
        lxi     h, BALL
        mvi     a, 3
        call    PaintBitmap

        lxi     b, 1800h + 11*8
        lxi     h, BALL
        mvi     a, 3
        call    PaintBitmap
        
        lxi     b, 1800h + 10*8
        lxi     h, BALL
        mvi     a, 3
        call    PaintBitmap

        lxi     b, 1a00h + 11*8
        lxi     h, BALL
        mvi     a, 3
        call    PaintBitmap

        ret

Help
        lxi     b, 1a00h + 11*8
        lxi     h, ONE
        mvi     a, 3
        call    PaintBitmap

        lxi     b, 1a00h + 12*8+2
        lxi     h, TWO
        mvi     a, 3
        call    PaintBitmap

        ret


; *************************************************
; Вывести символ С по адресу HL
; *************************************************
MYCHAROUT
        shld    CURSYS  ; координаты текстового курсора
        call    CHAROUT
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

String  ;  db      1bh, 35h, 10, 10
        db      '1 2 3 4 5 6 7 8 9 0', 0


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
        
ONE     db      0ffh, 0efh, 0efh, 0efh, 0efh, 0ffh, 83h, 0ffh
        db      8, 12, 8, 8, 8, 3eh, 0, 0
TWO     db      0ffh, 0e3h, 0ddh, 0efh, 0f7h, 0ffh, 0c1h, 0ffh
        db      1ch, 22h, 10h, 8, 4, 3eh, 0, 0

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

TOPLINE db      0, 255, 0, 0, 0, 0, 0, 0
        db      0, 255, 0, 0, 0, 0, 0, 0
        
BOTLINE db      0, 0, 0, 0, 0, 0, 255, 0
        db      0, 0, 0, 0, 0, 0, 255, 0

BALL    db      4eh, 0c7h, 8bh, 0c5h, 83h, 0c0h, 0abh, 7eh
        db      34h, 17h, 2bh, 15h, 2bh, 15h, 0, 0

WALL    db      0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0
        db      9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9, 9
        db      0, 9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9
        db      0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8
        db      0ffh, 0ffh
        
        
; Зажечь/погасить квадратик
INV     db      0

; Координаты курсора
CurPos  dw      0

BmpPtr dw      0

; Клипборд
CLIPBOARD       equ     .
        
