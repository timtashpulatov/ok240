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

DEFAULTBALLDELAY        equ     5
DEFAULTBattyDelay       equ     2
BATTY_STOP      equ     0
BATTY_RIGHT     equ     1
BATTY_LEFT      equ     2
DEFAULTBALLX    equ     28h     ;32
DEFAULTBALLY    equ     18h     ;224
DEFAULTBALLDX   equ     0       ; debug Y first ; 1
DEFAULTBALLDY   equ     1

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
        lxi     hl, HKCOUNT
        shld    SPEED
        shld    CountDown
        xra     a
        sta     SCORE
        sta     X
        sta     Y
        
        mvi     a, 1
        sta     LEVEL

        mvi     a, 10
        sta     BattyPos

        mvi     a, DEFAULTBALLDELAY
        sta     BallDelay

        mvi     a, DEFAULTBATTYDELAY
        sta     BattyDelay
        
        mvi     a, DEFAULTBALLX
        sta     BallX
        mvi     a, DEFAULTBALLY
        sta     BallY
        
        mvi     a, DEFAULTBALLDX
        sta     BallDX
        mvi     a, DEFAULTBALLDY
        sta     BallDY

        lxi     hl, BALL
        shld    BALLPHASE

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

        call    FillBattyBuf
        call    FillBallPhases


;        lxi     bc, 00e8h
 ;       lxi     hl, BATTYBUF-1
  ;      call    PaintHorizontalBitmap



        call    PaintBall

        call    DrawLevel

        call    PaintBatty        


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
        mvi     a, BATTY_LEFT
        sta     BattyDirection
        jmp     Begin

CurRight
        mvi     a, BATTY_RIGHT
        sta     BattyDirection
        jmp     Begin

CurUp
        mvi     a, BATTY_STOP
        sta     BattyDirection
        jmp     Begin

HouseKeeping
        call    Dly
        call    ProcessBall
        call    ProcessBatty
        jmp     Begin

; *************************************************
; Дубопроцессор
; *************************************************
ProcessBatty
        lda     BattyDelay
        ora     a
        jz      L1F2
        dcr     a
        sta     BattyDelay
        ret
L1F2        
        mvi     a, DEFAULTBattyDelay
        sta     BattyDelay

; Камо грядеши
        lda     BattyDirection
        cpi     1
        jz      MoveRight
        cpi     2
        jz      MoveLeft
        ret

MoveRight
        call    EraseBatty
        lda     BattyPos
        cpi     220
        jnz     L20f
        mvi     a, BATTY_STOP
        sta     BattyDirection
MoveDone        
        call    PaintBatty
        ret
L20f
        inr     a
        sta     BattyPos
        jmp     MoveDone

MoveLeft
        call    EraseBatty
        lda     BattyPos
        ora     a
        jnz     MoveLeftJa
        mvi     a, BATTY_STOP   ; Как насчет отталкиваться?
        sta     BattyDirection
        jmp     MoveDone
MoveLeftJa        
        dcr     a
        sta     BattyPos
        jmp     MoveDone


; *************************************************
; Мячевой процессинг
; *************************************************
ProcessBall
        lda     BallDelay
        ora     a
        jz      L1ea
        dcr     a
        sta     BallDelay
        ret
L1ea
        mvi     a, DEFAULTBALLDELAY
        sta     BallDelay
        
        call    EraseBall
; займемся координатой по горизонтали X
        lxi     hl, BallX
        lxi     de, BallDX
        ldax    de
        ora     a
        mvi     b, 32
        jm      DcrX
        mvi     b, 216
DcrX        
        add     m               ; прибавить к X шаг
        mov     m, a            ; и записать
; проверить на границы поля        
        cmp     b
        jz      ReflectX
; проверить на кирпич
        call    CheckBrick      ; TODO не на каждом же шаге?
        jz      CheckY
; выбить кирпич
        rlc                     ; признак очень твердого кирпича
        jc      ReflectX
        mvi     m, 0            ; TODO и пометить где-то, что кирпич надо стереть с экрана
        call    DestroyBrick
        
; изменить направление движения по горизонтали
ReflectX
        ldax    de
        cma
        inr     a
        stax    de

CheckY        
; займемся координатой по вертикали Y
        lxi     hl, BallY
        lxi     de, BallDY
        ldax    de
        ora     a
        mvi     b, 16
        jm      DcrY
        mvi     b, 232
DcrY        
        add     m               ; прибавить к X шаг
        mov     m, a
; проверить на границы поля        
        cmp     b
        jz      ReflectY
; проверить на кирпич        
        call    CheckBrick
        jz      CheckDone
; выбить кирпич
        rlc                     ; признак очень твердого кирпича
        jc      ReflectY
        mvi     m, 0
        call    DestroyBrick
        
ReflectY        
        ldax    de
        cma
        inr     a
        stax    de

CheckDone

;        lda     BallY
;        ani     7
;        jnz      CheckDone1
        
         call    PaintBall
        call    KBDSTAT
        jz      CheckDone
        call    KBDREAD
        cpi     1bh
        jnz     CheckDone1
        call    PaintBall
        pop     a
        jmp     WARMBOOT
        
        
;        call    CheckBrick      ; оптимизировать вывод, чтобы не на каждом шаге проверять, а только при пересечении
                                ; границы кирпичной сетки
CheckDone1                                
        
        call    PaintBall
        ret

; *************************************************
; Вот сошлись кирпич и мяч
; *************************************************
CheckBrick
        lxi     hl, LEVEL_1

; hack
        mvi     c, 0
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 7

        lda     BallY
        add     c               ; hack
        
        rlc
        push    a
        
        mvi     a, 0
        adc     h
        mov     h, a
        
        pop     a
        ani     0b11110000
        add     l
        mov     l, a
        mvi     a, 0
        adc     h
        mov     h, a
; теперь в HL указатель на строку с кирпичом
        mvi     c, 0
        lda     BallDX
        rlc
        jc      .+5
        mvi     c, 7
        
        lda     BallX
        add     c
        
        rar
        rar
        rar
        rar

        ani     0fh

        add     l
        mov     l, a
        mvi     a, 0
        adc     h
        mov     h, a
; а теперь в HL указатель на конкретный кирпич
        mov     a, m
        ora     a
        ret

; *************************************************
; 
; *************************************************
        
; *************************************************
; Стереть кирпич
; *************************************************
DestroyBrick
        push    hl
        push    bc

; hack
        mvi     c, 0
        lda     BallDX
        rlc
        jc      .+5
        mvi     c, 7

        
        lda     BallX
        add     c       ; hack
        rar
        rar
        
        ani     03ch
        mov     b, a

; hack
        mvi     c, 0
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 7


        
        lda     BallY
        add     c       ; hack
        

        
        ani     0f8h
        mov    c, a
        ;mvi    c, 0     
        
        xra   a
        call  PaintBrick1

        pop     bc
        pop     hl
        ret

; *************************************************
; А мячик скиньте?
; *************************************************
EraseBall

       ;lxi     hl, NOBATTY+1
       ;jmp     GoBall
       call     RenderNoBall
       lxi      hl, BALLBUF
       jmp      GoBall

 
PaintBall

        lxi     hl, BALL
        lda     BallX
        ani     7
        jz      GoBall0
        
        lxi     hl, BALLPHASES
        lxi     bc, 32
PaintBallLoop
        dcr     a
        jz      GoBall0
        dad     bc
        jmp     PaintBallLoop
GoBall0 
        shld    BALLPHASE

          call        RenderBall
          lxi   hl, BALLBUF


GoBall
        lda     BallY
        mov     c, a
        lda     BallX
        rar
        rar
        ani     3eh
        mov     b, a
        
        call    PaintHorizontalBitmap2

        ret

; *************************************************
; Отрендерить мячик в буфер
; *************************************************
RenderBall
        push    hl
        push    de
        push    bc
        
        ; TODO отрендерить в буфер кусок фона
        call    RenderBackground



        lda     BallY
        ani     7
        sta     BmpHeight1
        mov     c, a
        mvi     a, 8
        sub     c
        sta     BmpHeight2

        
        ;lxi     hl, BRICK1      ;COOLBRICK
        lxi     hl, LEVEL_1
        call    GetRightBrickPtr
        
        ; lda     BallY
        ; ani     0f8h
        ; ral
        ; ral
        
        ; mov     c, a
        ; mvi     b, 0
        ; dad     bc
        
        push    hl
        
        lxi     de, BALLBUF+16
        ;mvi     b, 4
        lda     BmpHeight2
        mov     b, a
;        mvi     c, 0
        lda     BmpHeight1
        mov     c, a
        call    PartialCopy
        
 ; нижний кирпич       
;        lxi     hl, BALLBUF
;        mvi     b, 0
;        lda     BmpHeight1
;        mov     c, a
;        dad     bc
;        xchg
        
        pop     hl
        
        lda     BmpHeight1
        ora     a
        jz      NoNeed
        ;jmp NoNeed
        
        

        
        ;push    hl
        lxi     hl, BALLBUF+16
        lda     BmpHeight1
        cma
        inr     a
        ani     7
        mov     c, a
        mvi     b, 0
        dad     bc
        xchg

        ;pop     hl
        ;lxi     bc, 32
        ;dad     bc
        
        push    de
        lxi     hl, LEVEL_1+16
        call    GetRightBrickPtr                
        pop     de
        
        ;mvi     b, 2
        lda     BmpHeight1
        mov     b, a
        ;mov     b, a
        mvi     c, 0
        ; lda     BmpHeight1
        ; mov     c, a
;        lxi     hl, BRICK2      ;COOLBRICK
        call    PartialCopy

NoNeed        
       



                
        ; TODO отрендерить в буфер кирпич
;        call    RenderBricks
        
        ; TODO отрендерить в буфер злецов (if any)
      
        ; Наложим поверх мячик (по OR)
        lhld    BALLPHASE        ; TODO адрес текущей фазы мячика BALLPHASE
        lxi     de, BALLBUF
        mvi     c, 32
RBLoop        
        ldax    de
        ora     m
        stax    de
        inx     hl
        inx     de
        dcr     c
        jnz     RBLoop
 RBDone       
        pop     bc
        pop     de
        pop     hl
        ret

RenderNoBall
        push    hl
        push    de
        push    bc
        
        ; TODO отрендерить в буфер кусок фона
        call    RenderBackground

        lda     BallY
        ani     7
        sta     BmpHeight1
        mov     c, a
        mvi     a, 8
        sub     c
        sta     BmpHeight2

        lxi     hl, LEVEL_1
        call    GetRightBrickPtr
        
        push    hl
        
        lxi     de, BALLBUF+16
        lda     BmpHeight2
        mov     b, a
        lda     BmpHeight1
        mov     c, a
        call    PartialCopy
        
 ; нижний кирпич       

        pop     hl
        
        lda     BmpHeight1
        ora     a
        jz      NoNeedNoBall


        lxi     hl, BALLBUF+16
        lda     BmpHeight1
        cma
        inr     a
        ani     7
        mov     c, a
        mvi     b, 0
        dad     bc
        xchg

        push    de
        lxi     hl, LEVEL_1+16
        call    GetRightBrickPtr                
        pop     de
        
        lda     BmpHeight1
        mov     b, a
        mvi     c, 0
        call    PartialCopy
NoNeedNoBall
        pop     bc
        pop     de
        pop     hl

        ret


; *************************************************
; Вернуть в HL указатель на битмап кирпича справа от мячика
; *************************************************
GetRightBrickPtr
;        lxi     hl, LEVEL_1

        lda     BallY
        ani     0f8h
        
        ral     
        ;ani     0f8h
        ; теперь в аккумуляторе начало строки игрового поля

        
        
        mov     c, a
        mvi     b, 0
        dad     bc


        lda     BallX
        
        adi     8       ; схерали?
        
        rar
        rar
        rar
        rar     
        ani     0fh     ; теперь в аккумуляторе столбец игрового поля


        mov     c, a
        mvi     b, 0
        dad     bc

        mov     a, m

  ;      mvi     a, 1
        
        call    BrickNo2Ptr
        
        
        ret

; *************************************************
; Вернуть в HL указатель на битмап кирпича по его номеру из A
; *************************************************
BrickNo2Ptr
        ani     7fh     ; отбросим крепкость (а позже и иные атрибуты)
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

        ret

; *************************************************
; Отрендерить кирпичи в буфер
; *************************************************
RenderBricks
        ;lxi     hl, LEVEL_1
        lxi     hl, BRICK0

        lda     BallX
        ani     0f0h
        ral
        mov     c, a
        mvi     b, 0
        dad     bc
        
        ; определим, рендерить ли целый кирпич или по пол-кирпича слева и справа
        lda     BallX
        ani     8
        jnz      RenderHalfBrick        

        call    RenderFullBrick
        ret
        
;        lda     BallY
;        ani     7
;        jz      RenderBricks0   ; рендерим кирпич целиком из текущего ряда
        ; иначе рендерим часть кирпича из верхнего ряда и часть кирпича из нижнего ряда

RenderHalfBrick
        lxi     bc, 16  ; возьмем вторые пол-кирпича слева --]
        dad     bc
        push    hl

        lxi     de, BALLBUF
        mvi     b, 16
        call    Copy_B_Bytes_From_HL_To_DE

        pop     hl
        
        lxi     bc, 16  ; и первые пол-кирпича справа [--
        dad     bc

;        mvi     c, 16
        call    Copy_B_Bytes_From_HL_To_DE

        ret

; *************************************************
; В HL указатель на битмап кирпича
; *************************************************
RenderFullBrick

        ;lda     BallY
        ;ani     7

        lxi     de, BALLBUF
        mvi     b, 32
        call    Copy_B_Bytes_From_HL_To_DE
        ret

; *************************************************
; Скопировать в буфер несколько строк битмапа
; HL - битмап
; DE - буфер
; B - количество строк
; C - смещение
; *************************************************
PartialCopy
        mov     a, b    ; сохранить B
        mvi     b, 0
        dad     bc      ; добавить смещение к HL
        mov     b, a    ; восстановить B

; первый битплан        
        push    bc
        push    hl
        push    de
        call    Copy_B_Bytes_From_HL_To_DE        
        pop     hl
        
; второй битплан
        lxi     bc, 8
        dad     bc
        xchg
        pop     hl
        dad     bc

        pop     bc
        call    Copy_B_Bytes_From_HL_To_DE
        ret

; *************************************************
; Отрендерить фон (пока просто чистим буфер)
; *************************************************
RenderBackground
        lxi     hl, NOBATTY+1
        lxi     de, BALLBUF
        mvi     b, 32
        call    Copy_B_Bytes_From_HL_To_DE
        ret
        

; *************************************************
; Копировать блок из HL в DE длиной C
; *************************************************
Copy_B_Bytes_From_HL_To_DE
        mov     a, m
        stax    de
        inx     hl
        inx     de
        dcr     b
        jnz     Copy_B_Bytes_From_HL_To_DE

        ret


; *************************************************
; Нарисовать/стереть дубину
; *************************************************
EraseBatty
        lxi     hl, NOBATTY+1
        jmp     GoBatty
PaintBatty
        lxi     hl, BATTY1+1
        lda     BattyPos
        ani     7
        jz      GoBatty
        lxi     hl, BATTYBUF
        lxi     bc, 64
PaintBattyLoop        
        dcr     a
        jz      GoBatty
        dad     bc
        jmp     PaintBattyLoop
        
GoBatty        
        mvi     c, 0f0h
        lda     BattyPos
        rar
        rar
;        rar
        ani     0b00111110
        mov     b, a

        call    PaintHorizontalBitmap4
        ret

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
        
        ani     0fh
        
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
; BC - координаты кирпича на экране
; *************************************************
PaintBrick1
        push    de

        call    BrickNo2Ptr
        
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
; PaintBall
;         ;lxi     bc, 0000        ; 1818h
;         lhld    BallCoords
;         mov     b, h
;         mov     c, l
;         lxi     hl, BALL
;         mvi     a, 3
;         call    PaintBitmap
;         ret

; *******************************************
; EraseBall
; *******************************************
; EraseBall
;         lhld    BallCoords
;         mov     b, h
;         mov     c, l
;         lxi     hl, BITMAP0
;         mvi     a, 3
;         call    PaintBitmap
;         ret
;         ret


; *******************************************
; *******************************************
CycleForeColor
        lda     PALETTE
        inr     a
        ani     7
        sta     PALETTE
        jmp     ApplyColors
CycleBackColor
        lda     BGCOLOR
        adi     8
        ani     38h
        sta     BGCOLOR
ApplyColors        
        mov     c, a
        lda     PALETTE
        ora     c
        ori     40h
        out     VIDEO
        jmp     Begin
        
DELAY   equ     0100h
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

; *************************************************
; Скопировать 8 байт битмапа с разными логическими функциями
; *************************************************
OP_NOP  equ     000h
OP_OR   equ     0b6h
OP_XOR  equ     0aeh
Copy8
        push    h
        push    d
        push    a
        mvi     c, 8
PBLoop  ldax    d

;OPERATION
;        db      OP_NOP
        
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
;        out     SCROLL_VH
        ret


; *************************************************
; Вывести символ С по адресу HL
; *************************************************
MYCHAROUT
        shld    CURSYS  ; координаты текстового курсора
        call    CHAROUT
        ret

PaintHorizontalBitmap1
        mvi     e, 1
        jmp     PHLoop
        
PaintHorizontalBitmap2
        mvi     e, 2
        jmp     PHLoop

PaintHorizontalBitmap4
        mvi     e, 4
        jmp     PHLoop

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
; Породить фазы мячика
; *************************************************
FillBallPhases

        mvi     a, 2
        sta     BitmapWidth

        mvi     a, 32
        sta    PhaseSize

        lxi     hl, BALL
        lxi     de, BALLPHASES
        call    ShiftBitmap
 
        lxi     hl, BALLPHASES
        lxi     de, BALLPHASES+32
        mvi     a, 7       
        jmp     FBPLoop
;  L3b6
;          push    a
;          push    hl
;          push    de
;          call    ShiftBitmap
;          lxi     bc, 32
;          pop     hl
;          dad     bc
;          xchg
;          pop     hl
;          dad     bc
        
;          pop     a
;          dcr     a
;          jnz     L3b6
        
;         ret


; *************************************************
; Заполнить Буфер Сдвинутых Ракеток
; *************************************************
FillBattyBuf

        mvi     a, 4
        sta     BitmapWidth

        lxi     hl, 64
        shld    PhaseSize


        lxi     hl, BATTY1+1
        lxi     de, BATTYBUF
        call    ShiftBitmap

        lxi     hl, BATTYBUF
        lxi     de, BATTYBUF+64
        mvi     a, 7
 FBPLoop
        push    a
        push    hl
        push    de
        call    ShiftBitmap
        lda     PhaseSize
        mov     c, a
        mvi     b, 0
        pop     hl
        dad     bc
        xchg
        pop     hl
        dad     bc
        
        pop     a
        dcr     a
        jnz     FBPLoop
        
        ret

; *************************************************
; Сдвинуть битмап на 1 бит
; *************************************************
ShiftBitmap        
        push    hl
        push    de
        call    ShiftBitmapPlane
        lxi     bc, 8
        pop     hl
        dad     bc
        xchg
        pop     hl
        dad     bc
        call    ShiftBitmapPlane
        ret

ShiftBitmapPlane
        lxi     bc, 16  ; инкремент к следующему байту в растровой строке

        mvi     a, 8
        sta     Count   ; 
     
SBPLoop
        push    hl
        push    de

        lda     BitmapWidth
        sta     Count1  ; счетчик байт в растровой строке битмапа (ширина битмапа в байтах)

        ora     a
        push    a
        
SBPLoop1        
        pop     a
        mov     a, m
        ral
        stax    de
        push    a 
        
        ; перейдем к следующему байту в растровой строке битмапа
        dad     bc
        xchg
        dad     bc
        xchg

        lda     Count1
        dcr     a
        sta     Count1
        jnz     SBPLoop1

;
        pop     a

        pop     de
        pop     hl                

        ; перейдем к следующей растровой строке
        inx     hl
        inx     de
        
        lda     Count
        dcr     a
        sta     Count
        
        jnz     SBPLoop

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
;        ds      16
;        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
;        ds      8
        ds      16
        db      3ch, 42h, 81h, 81h, 81h, 81h, 42h, 3ch
        db      3ch, 42h, 89h, 85h, 85h, 81h, 42h, 3ch

RIGHTBRICK
;        db      0feh, 0fch, 80h, 0, 0efh, 0cfh, 8, 0
;        ds      24
POPS    db      3ch, 42h, 81h, 81h, 81h, 81h, 42h, 3ch
        db      3ch, 42h, 89h, 85h, 85h, 81h, 42h, 3ch
        ds      16



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

BRICK3  db      0ffh, 55h, 0abh, 55h, 0abh, 55h, 0abh, 0
	ds      8
	db      7fh, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0
	ds      8

BRICK4  ds      8
        db      0ffh, 55h, 0abh, 55h, 0abh, 55h, 0abh, 0
        ds      8
        db      7fh, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0

BRICK5  db      0ffh, 55h, 0abh, 55h, 0abh, 55h, 0abh, 0
        db      0ffh, 55h, 0abh, 55h, 0abh, 55h, 0abh, 0
        db      7fh, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0
        db      7fh, 55h, 2ah, 55h, 2ah, 55h, 2ah, 0

BRICK6  db      255, 255, 255, 255, 255, 255, 255, 0
        db      0, 0aah, 54h, 0aah, 54h, 0aah, 54h, 0      
        db      7fh, 7fh, 7fh, 7fh, 7fh, 7fh, 7fh, 0
        db      0, 2ah, 55h, 2ah, 55h, 2ah, 55h, 0

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
        db      0, 12, 1ah, 39h, 3dh, 1eh, 12, 0
        ds      16

; Дубина
BATTY   db      3
	db64    /AIBBQWpAvwAAAAAAAAAAAD/AAAA/wD/AAAAAAAAAAAAAP+AgEAgHwAAAAAAAAAA

BATTY1  db      4
        ; db      18h, 0fch, 0ach, 5ch, 0ach, 0fch, 18h, 0
        ; db      0, 0, 0f0h, 0f0h, 0f0h, 0, 0, 0
        ; db      0, 255, 0aah, 55h, 0aah, 255, 0, 0
        ; db      0, 0, 255, 255, 255, 0, 0, 0
        ; db      18h, 3fh, 3ah, 35h, 3ah, 3fh, 18h, 0
        ; db      0, 0, 15, 15, 15, 0, 0, 0
        ; ds      16

        db      6, 255, 57h, 0abh, 57h, 255, 6, 0
        db      0, 0, 0fch, 0fch, 0fch, 0, 0, 0
        db      0, 255, 55h, 0aah, 55h, 255, 0, 0
        db      0, 0, 255, 255, 255, 0, 0, 0
        db      6, 15, 13, 14, 13, 15, 6, 0
        db      0, 0, 3, 3, 3, 0, 0, 0
        ds      16

; Нет дубины
NOBATTY db      4
        ds      64

        .org 0B00h
; *********************************************************************
; Кирпичики
; 00 - пустое место
; *********************************************************************

LEVEL_1 
        db      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
        db      0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0
        db      0, 2, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0
        db      0, 2, 5, 5, 0, 0, 81h, 0, 81h, 0, 0, 0, 0, 0, 3, 0
        db      0, 2, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0
        db      0, 2, 7, 4, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 3, 0
        db      0, 2, 8, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 0
        db      0, 2, 9, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 0
        db      0, 2, 10,10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 0
        db      0, 2, 11,11,11,11,11,11,11,11,11,11,11,11,3, 0
        db      0, 2, 9, 12, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 3, 0
        db      0, 2, 6, 13, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 0        
        db      0, 2, 7, 7, 8, 8, 9, 9, 8, 8, 7, 7, 6, 6, 3, 0
        db      0, 2, 9,10,11,12, 9,10,11,12, 9,10,11,12, 3, 0
        db      0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0
        db      0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0

LEVEL_1_END
        ds      WIDTH*HEIGHT
        

; *********************************************************************
; Переменные
; *********************************************************************

X             db      0
Y             db      0


; Переменная
Count           db      0
Count1          db      0
BitmapWidth     db      0
PhaseSize       db      0

BmpPtr          dw      0


BallCoords      dw      0                       ; Координаты мячика
BallX           db      0
BallY           db      0
BallDelay       db      DEFAULTBALLDELAY        ; Скорость мячика
BallDX          db      0
BallDY          db      0
BallPhase       dw      BALL

BattyPos        db      10                      ; Позиция ракетки
BattyDelay      db      DEFAULTBattyDelay       ; Скорость ракетки
BattyDirection  db      0

BmpHeight1      ds      1
BmpHeight2      ds      1


; Псевдослучайность
RNG             db      0
; Обратный отсчет для хаускипера
CountDown       dw      0
; Score
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
PALETTE         db      3
BGCOLOR         db      0
; Градус тюнза
TuneCount       db      0

; *********************************************************************
; Буфера (.)(.)
; *********************************************************************
;        db      24        
; Буфер мячика
BALLBUF         ds      32      ; сюда будут отрисовываться фон, кирпичики и сам мячик для последующего вывода

; Буфер Сдвинутых Ракеток
BATTYBUF        ds      64*8
; Фазы мячика
BALLPHASES      ds      16*8

; Игровое поле
;           1111111111222222222233
; 01234567890123456789012345678901
; ................................
; ....112233445566778899aabbcc....
; ................................
;
GAMEFIELD  equ     .
        
  
