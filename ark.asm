        .project ark.bin

SCROLL_V        equ     0C0h
BANKING         equ     0C1h
SCROLL_VH       equ     0C2h

VIDEO           equ     0E1h

MAP32K          equ     0x01
ENROM           equ     0x10

XY              equ     0004h
SCREEN          equ     0c000h

WARMBOOT        equ     0e003h
KBDSTAT         equ     0e006h
KBDREAD         equ     0e009h
CHAROUT         equ     0e00ch  ; вывести символ из регистра C

CURSYS          equ     0bfedh
BELL_FREQ       equ     0bff4h
BELL_LEN        equ     0bff6h

WIDTH           equ     16
HEIGHT          equ     16
SCORE_COORDS    equ     0238h
LEVEL_COORDS    equ     0258h
SCORE_LINE_XY   equ     0600h + 5*8
NEXT_LINE_XY    equ     3400h + 5*8
LEVEL_LINE_XY   equ     0600h + 9*8
PREVIEW_COORD   equ     020fh
HKCOUNT         equ     8000

        org     100h

    ;    call    NewNoteTest


VeryBegin
; Чистим экран
        mvi     a, 40h          ; палитра 1: черный, красный, зеленый, синий
        ;mvi     a, 43h          ; палитра 3: черный, красный, малиновый, белый
        out     VIDEO
        call    ResetScroll
        call    ClearScreen




; Инициализация важных и нужных переменных
        ;call    InitCTAKAH
        

        lxi     hl, HKCOUNT
        shld    SPEED
        shld    CountDown
        xra     a
        sta     SCORE
        sta     X
        sta     Y
        
        mvi     a, 1
        sta     LEVEL


; Кирпич 1
        lxi     bc, 0400h
        lxi     hl, BRICK1
        call    PaintBrick

        lxi     bc, 0808h
        lxi     hl, BRICK1
        call    PaintBrick

        lxi     bc, 0c08h
        lxi     hl, BRICK1
        call    PaintBrick

        lxi     bc, 1010h
        lxi     hl, BRICK2
        call    PaintBrick
        
        lxi     bc, 1410h
        lxi     hl, BRICK2
        call    PaintBrick
        
        call    PaintBall

        call    DrawLevel


; *********************************************************************
; Main, как говорится, Loop
; *********************************************************************
Begin
        ; Ввод с клавиатуры
        call    KBDSTAT
        ora     a
        jz      HouseKeeping
        
        call    KBDREAD

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
        db      ' '
        dw      Drop
        db      'F'
        dw      CycleForeColor
        db      'B'
        dw      CycleBackColor
        db      'T'
        dw      Test
        
        db      1bh
        dw      WARMBOOT
        db      0
        dw      0

; *******************************************
Test
        jmp     Begin


; *******************************************

Drop

CurDown


CurLeft
        jmp     Begin

CurRight
        jmp     Begin

CurUp

        jmp     Begin

HouseKeeping
        call    Dly
        call    EraseBall
        lhld    BallCoords
        inr     l
        shld    BallCoords
        call    PaintBall
        jmp     Begin

; *************************************************
; Нарисовать уровень
; *************************************************
DrawLevel
        mvi     b, HEIGHT
        mvi     c, WIDTH
      
        mvi     e, 254
        lxi     hl, LEVEL_1
DLLoop
        mov     a, m
        inx     hl
        push    hl
        lhld    X
        mov     b, l
        mov     c, h

;        lxi     bc, 1800h
        call    PaintBrick1

        lda     X
        adi     4
        sta     X
        mov     b, a
        cpi     64
        jnz     DDL0
        xra     a
        sta     X
        lda     Y
        adi     8
        sta     Y
        mov     c, a
DDL0
        pop     hl
        dcr     e
        jnz     DLLoop
        
        ret
        

; *************************************************
; Отложить кирпич
; A - номер кирпича (0 - пусто и т.д.)
; *************************************************
PaintBrick1
        push    de
        rrc             ; кирпич весит 32 байта
        rrc    
        rrc
        mov     d, a
        ani     0e0h
        mov     e, a
        
        mov     a, d
        ani     1fh
        mov     d, a
;        mvi     d, 0
        lxi     hl, BRICK0
        dad     d
        
        call    PaintBrick
        pop     de
        ret


; *******************************************
; PaintBrick
; *******************************************
PaintBrick
        push    hl
        push    bc
        mvi     a, 3
        call    PaintBitmap

        pop     bc
        inr     b
        inr     b
        lxi     hl, 16
        pop     de
        dad     d

        mvi     a, 3
        call    PaintBitmap

        ret

; *******************************************
; PaintBall
; *******************************************
PaintBall
        ;lxi     bc, 0000        ; 1818h
        lhld    BallCoords
        mov     b, h
        mov     c, l
        lxi     hl, BALL
        mvi     a, 3
        call    PaintBitmap
        ret

; *******************************************
; EraseBall
; *******************************************
EraseBall
        lhld    BallCoords
        mov     b, h
        mov     c, l
        lxi     hl, BITMAP0
        mvi     a, 3
        call    PaintBitmap
        ret
        ret


; *******************************************
; *******************************************
CycleForeColor
        lda     FGCOLOR
        inr     a
        ani     7
        sta     FGCOLOR
        jmp     ApplyColors
CycleBackColor
        lda     BGCOLOR
        adi     8
        ani     38h
        sta     BGCOLOR
ApplyColors        
        mov     c, a
        lda     FGCOLOR
        ora     c
        ori     40h
        out     VIDEO
        jmp     Begin
        
DELAY   equ     08000h
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
; Вывести счет
; *************************************************
PaintScore
        
        push    de
        push    bc
        
        xra     a
        sta     SuppressLeadingZeroes
        
        lda     SCORE
        ora     a
        jz      PSDone          ; чего его выводить, если он нулевой
        
        mov     d, a
        mvi     e, 8
        lxi     b, SCORE_COORDS
        call    PSLoop

PSDone        
        pop     bc
        pop     de
        
        ret

; *************************************************
; Вывести уровень
; *************************************************
PaintLevel
        push    de
        push    bc
        
        xra     a
        sta     SuppressLeadingZeroes

        lda     LEVEL        
        mov     d, a
        mvi     e, 8
        lxi     b, LEVEL_COORDS
        call    PSLoop

        pop     bc
        pop     de
        
        ret        
        
PSLoop
        push    hl
PSLoop0        
        lxi     h, SCORE_0      ; а хорошо бы придавить ведущие нули как-то
        lda     SuppressLeadingZeroes
        ora     a
        jnz      PS00
        lxi     h, BITMAP0; CHECKERS
PS00        
        mov     a, d
        rlc
        mov     d, a
        jnc     PS0
        lxi     h, SCORE_1
        ; прекратить дискриминацию ведущих нулей
        ; (но пощадить последний)
        sta     SuppressLeadingZeroes
        
PS0        
        mvi     a, 3
        call    PaintBitmap
        
        inr     b
        inr     b
        
        dcr     e
        jnz     PSLoop0
        
        pop     hl
        ret

; Установить нулевые смещения для вертикальной и горизонтальной прокруток        
ResetScroll
        xra     a
        out     SCROLL_V
        out     SCROLL_VH
        ret


; *************************************************
; Вывести символ С по адресу HL
; *************************************************
MYCHAROUT
        shld    CURSYS  ; координаты текстового курсора
        call    CHAROUT
        ret




; *************************************************
; Вывести горизонтально многоклеточный битмап из HL
; Первый байт - длина
; *************************************************
PaintHorizontalBitmap
        mov     e, m
        inx     h
PHLoop
        push    bc
        push    hl
        mvi     a, 3
        call    PaintBitmap
        pop     hl
        lxi     b, 16
        dad     b
        pop     bc

        inr     b
        inr     b
        dcr     e
        jnz     PHLoop
        ret


; *************************************************
; Битмапчики
; *************************************************
BITMAP0 
BRICK0  ds      32

COOLBRICK
        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
        ds      8
        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
        ds      8
LEFTBRICK
        ds      16
        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
        ds      8
RIGHTBRICK
        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
        ds      24

        db      255, 255, 255, 255, 255, 255, 255, 0
        db      0,0,0,0,0,0,0,0
        db      127, 127, 127, 127, 127, 127, 127, 0
        db      0,0,0,0,0,0,0,0

        db      0,0,0,0,0,0,0,0
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      0,0,0,0,0,0,0,0
        db      127, 127, 127, 127, 127, 127, 127, 0
        
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      127, 127, 127, 127, 127, 127, 127, 0
        db      127, 127, 127, 127, 127, 127, 127, 0


BRICK1  db      0, 54h, 0aah, 54h, 0aah, 54h, 0aah, 0
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      0, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0
        db      7fh, 7fh, 7fh, 7fh, 7fh, 7fh, 7fh, 0

BRICK2  db      0, 0aah, 54h, 0aah, 54h, 0aah, 54h, 0
        db      0feh, 55h, 0abh, 55h, 0abh, 55h, 0aah, 0
        db      0, 2ah, 55h, 2ah, 55h, 2ah, 15h, 0
        db      3fh, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0

BITMAP1
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255, 255

CTAKAH_BRICK
;        db      0x7e, 0xc0, 128, 128, 128, 128, 128, 0
;        db      0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa          ; второй план отлично подходит от CHECKERS

;        db      0ffh, 1, 7fh, 1, 7fh, 1, 7fh, 1
;        db      0ffh, 1, 7fh, 1, 7fh, 1, 7fh, 1

        db      0feh, 1, 7dh, 7dh, 7dh, 7dh, 7dh, 1
        db      0feh, 1, 7dh, 7dh, 7dh, 7dh, 7dh, 1

ANOTHER_BRICK
        db      0, 0, 0, 0, 0, 0, 0, 0
;        db      0ffh, 0bdh, 43h, 5bh, 4bh, 43h, 3dh, 3
        db      0, 3ch, 42h, 5ah, 4ah, 42h, 3ch, 0

CHECKERS
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55        
CHECKERS1
        db      88h, 0, 22h, 0, 88h, 0, 22h, 0
        db      88h, 0, 22h, 0, 88h, 0, 22h, 0

BMPDOT  db      0, 1, 0, 1, 0, 1, 0, 0x55
        db      0, 1, 0, 1, 0, 1, 0, 0x55

PENTABRICK
        db      7fh, 7fh, 5fh, 5fh, 5fh, 43h, 7fh, 0
        db      0, 1eh, 1eh, 1eh, 1eh, 0, 0, 0

SCORE_LINE   
        db      3
        db64    AAAAAAAAAAAAAMcAJyjHAAAAAAAAAAAAAADMANJSTAAAAAAAAAAAAAAAOQI4CTIA
NEXT_LINE        
        db      2
        db64    AAAAAAAAAAAAAOcI6SnJAAAAAAAAAAAAAADqAERKigA=
LEVEL_LINE
        db      3
        db64    AAAAAAAAAAAAAHEAcRFmAAAAAAAAAAAAAADpAOklwgAAAAAAAAAAAAAAAgACAgwA
SCORE_0
        db      0, 0xfe, 82h, 0bah, 0aah, 0bah, 082h, 07eh
        db      0, 0xfe, 82h, 0bah, 0feh, 0feh, 0feh, 07eh
SCORE_1
        db      0, 3ch, 24h, 2ch, 28h, 0eeh, 82h, 0feh
        db      0, 3ch, 24h, 2ch, 38h, 0feh, 0feh, 0feh


        
        db      0, 0, 0, 0, 0, 0, 0, 0

BALL    db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 18h, 2ch, 52h, 4ah, 34h, 18h, 0



; *********************************************************************
; Кирпичики
; 00 - пустое место
; *********************************************************************

LEVEL_1 
        db      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
        db      0, 2, 4, 5, 6, 4, 5, 6, 4, 5, 6, 4, 5, 6, 3, 0
        db      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
        db      0, 2, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 0, 0, 0
        db      0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0
        db      0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0
        db      0, 2, 0, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 0, 3, 0
        db      0, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0
        db      0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 0
        db      0, 2, 7, 7, 8, 8, 9, 9, 8, 8, 7, 7, 6, 6, 3, 0
LEVEL_1_END
        ds      WIDTH*HEIGHT
        

; *********************************************************************
; Переменные
; *********************************************************************

X             db      0
Y             db      0

BmpPtr          dw      0

; Координаты мячика
BallCoords      dw      0

; Псевдослучайность
RNG             db      0
; Обратный отсчет для хаускипера
CountDown       dw      0
; Score   (.)(.)
SCORE           db      0
; Level
LEVEL           db      1
; Стремительность
SPEED           dw      HKCOUNT
; Регистров вечно не хватает, а давить ведущие нули в счете хочется
SuppressLeadingZeroes   db      0
; Патч для KDE под FreeBSD
AnimeFrame      ds      1
; Палитра
FGCOLOR         db      3
BGCOLOR         db      0
; Градус тюнза
TuneCount       db      0
; Игровое поле
;           1111111111222222222233
; 01234567890123456789012345678901
; ................................
; ....112233445566778899aabbcc....
; ................................
;
GAMEFIELD  equ     .
        
  
