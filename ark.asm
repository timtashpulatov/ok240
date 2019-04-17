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
DEFAULTBALLX    equ     4fh     ;32
DEFAULTBALLY    equ     18h     ;224
DEFAULTBALLDX   equ     1       ; debug Y first ; 1
DEFAULTBALLDY   equ     1

DefaultDelayDX  equ     1
DefaultDelayDY  equ     1

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

        mvi     a, DefaultDelayDX
        sta     DelayDX
        sta     CounterDX

        mvi     a, DefaultDelayDY
        sta     DelayDY
        sta     CounterDY

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


        call    TestPops


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
        db      'D'
        dw      Debug
        db      'P'
        dw      PPPalette

        db      1bh
        dw      WARMBOOT
        db      0
        dw      0

; *******************************************
Test
        jmp     Begin

Debug   
        lda     DebugStepMode
        cma
        sta     DebugStepMode
        jmp     Begin

PPPalette

        lda     DebugPalette
        cma
        sta     DebugPalette
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

; *************************************************
; Хаускипинг
; *************************************************
HouseKeeping
        ;call    Dly
        call    SyncToRetrace
        
        lda     DebugPalette
        ora     a
        jz      NoPaletteDebug
        

        mvi     a, 41h          ; белый фон
        out     VIDEO
        call    ProcessBall
        
        mvi     a, 42h          ; красный фон
        out     VIDEO
        call    ProcessBatty
        
        mvi     a, 46h          ; зеленый фон
        out     VIDEO
        ;call    ProcessBonusList
        
        mvi     a, 40h          ; дефолтный черный фон
        out     VIDEO
        jmp     Begin
        
NoPaletteDebug
        call    BumpBitmap8x8
        call    ProcessBall
        call    ProcessBatty
        ;call    ProcessBonusList
        jmp     Begin

SyncToRetrace
        ; подождем наступления ретрейса
        in      41h
        ani     2
        jnz      SyncToRetrace
        ret

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
        call    CalculateBattyPhase
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


CalculateBattyPhase
        lxi     hl, BATTYPTRARRAY
        lda     BattyPos
        ani     7
        ral
        mov     c, a
        mvi     b, 0
        dad     bc
        
        mov     e, m
        inx     hl
        mov     d, m
        xchg
        
        shld    BattyPtr
        
        ret

; *************************************************
; Новый Мячевой Процессинг
; *************************************************
DelayDX         db      0       ; задержка приращения по X
CounterDX       db      0       ; счетчик задержки
DelayDY         db      0
CounterDY       db      0

NewProcessBall
        call    UpdateX
        ret

; *************************************************
; Приращение по X
; *************************************************
UpdateX
        lda     CounterDX
        dcr     a
        jz      UX1
        sta     CounterDX
        ret
UX1
        ; обновим счетчик
        lda     DelayDX
        sta     CounterDX
        
        ; проверим на отскок
        call    CheckNewX
        
        ; собственно прирастим координату
        call    XPlusDX
        sta     BallX
        
        ret

; *************************************************
; Проверим новую координату и отразимся, если нужно
; *************************************************
CheckNewX
        call    XPlusDX
        call    ShallWeReflectByX
        jnz     .+6
        call    LetsReflectX
        ret

ShallWeReflectByX
        ret

LetsReflectX
        lda     BallDX
        cma
        inr     a
        sta     BallDX
        ret

; *************************************************
; Инкрементнём X
; *************************************************
XPlusDX
        lda     BallDX
        mov     c, a
        lda     BallX
        add     c
        ret

; *************************************************
; Приращение по Y
; *************************************************
UpdateY
        lda     CounterDY
        dcr     a
        jz      UY1             ; пора
        sta     CounterDY
        ret
UY1
        ; обновим счетчик
        lda     DelayDY
        sta     CounterDY

        ; проверим на отскок
        call    CheckNewY

        ; собственно прирастим координату
        call    YPlusDY
        sta     BallY
        
        ret

; *************************************************
; Проверим новую координату Y и отразимся, если нужно
; *************************************************
CheckNewY
        call    YPlusDY
        call    ShallWeReflectY
        jnz     .+6
        call    LetsReflectY
        ret

ShallWeReflectY
        ret

LetsReflectY
        lda     BallDY
        cma
        inr     a
        sta     BallDY
        ret


; *************************************************
; Инкрементнём Y
; *************************************************
YPlusDY
        lda     BallDY
        mov     c, a
        lda     BallY
        add     c
        ret


LEFTMARGIN      equ     32
RIGHTMARGIN     equ     216
TOPMARGIN       equ     16
BOTTOMMARGIN    equ     240
; ****************************************************************************
; Мячевой процессинг
; ****************************************************************************
ProcessBall
        lda     BallDelay
        ora     a
        jz      ProcessBallPlease
        dcr     a
        sta     BallDelay
        ret
ProcessBallPlease
        mvi     a, DEFAULTBALLDELAY
        sta     BallDelay
        
        call    EraseBall

;    jmp CheckY

; ------------- займемся координатой по горизонтали X
        xra     a
        sta     ReflectFlag

        lda     BallY
        ani     7
        cpi     2
        jm      CheckXRight
; кирпич справа внизу
        call    CheckBrickXPlusOne
        lxi     de, BallDX
        jz      CheckXRight
; выбить кирпич справа внизу        
        rlc
        jc      SetReflectFlagX
        mvi     m, 0
        call    DestroyBrickXPlusOne
SetReflectFlagX        
        mvi     a, 1
        sta     ReflectFlag

CheckXRight
; кирпич справа
        call    CheckBrickX
        lxi     de, BallDX
        jz      CheckXMargins
; выбить кирпич
        rlc                     ; признак очень твердого кирпича
        jc      SetReflectFlagX1
        mvi     m, 0
        ;call    DestroyBrick
        call    DestroyBrickX
SetReflectFlagX1
        mvi     a, 1
        sta     ReflectFlag

CheckXMargins
; проверить границы поля
        lda     BallX
        cpi     LEFTMARGIN
        jz      ReflectX
        cpi     RIGHTMARGIN
        jz      ReflectX

; изменить направление движения по горизонтали
        lda     ReflectFlag
        ora     a
        jz      CXNext1
ReflectX
        ldax    de
        cma
        inr     a
        stax    de
CXNext1        
        lxi     hl, BallX
        ldax    de
        add     m               ; прибавить к X шаг
        mov     m, a

;    jmp CheckDone        

CheckY        
; -------------займемся координатой по вертикали Y
        xra     a
        sta     ReflectFlag
        
        lda     BallX
        ani     0fh
        cpi     0bh
        jm      CheckYUnder
; кирпич внизу справа
        call    CheckBrickYPlusOne
        lxi     de, BallDY
        jz      CheckYUnder
; выбить кирпич внизу справа
        rlc
        jc      SetReflectFlag
        mvi     m, 0
        call    DestroyBrickYPlusOne
SetReflectFlag        
        mvi     a, 1
        sta     ReflectFlag

CheckYUnder
; кирпич подо мною
        call    CheckBrickY
        lxi     de, BallDY
        jz      CheckYMargins
; выбить кирпич
        rlc                     ; признак очень твердого кирпича
        jc      SetReflectFlag1
        mvi     m, 0
        ;call    DestroyBrick
        call    DestroyBrickY
SetReflectFlag1        
        mvi     a, 1
        sta     ReflectFlag

CheckYMargins
; проверить границы поля
        lda     BallY
        cpi     TOPMARGIN
        jz      ReflectY
        cpi     BOTTOMMARGIN
        jz      ReflectY

        lda     ReflectFlag
        ora     a
        jz      CYNext1
; change direction
ReflectY
        ldax    de
        cma
        inr     a
        stax    de
        
CYNext1
        lxi     hl, BallY
        ldax    de
        add     m               ; прибавить к Y шаг
        mov     m, a
; проверить на границы поля        
;        cmp     b
;        jz      ReflectY
; проверить на кирпич        
;        call    CheckBrick
;        jz      CheckDone
        
        

CheckDone

;        lda     BallY
;        ani     7
;        jnz      CheckDone1

        lda     DebugStepMode
        ora     a
        jz      CheckDone1
        
        call    PaintBall
        call    KBDSTAT
        jz      CheckDone
        
        call    KBDREAD
        cpi     'D'
        jnz     CheckEsc
        xra     a
        sta     DebugStepMode
        jmp     CheckDone1
        
CheckEsc        
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
; *************************************************
CheckBrickX
        lxi     hl, LEVEL_1
        lda     BallY
        call    CheckBrickXCommon
        ret
; *************************************************
; *************************************************
CheckBrickXPlusOne
        lxi     hl, LEVEL_1
        lda     BallY
        adi     8
        call    CheckBrickXCommon
        ret
; *************************************************
; *************************************************
CheckBrickXCommon
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
        mvi     c, -1
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
; Проверить кирпич снизу или сверху
; NB: Только если мячик не на сетке кирпичей (16), т.е. сдвинут на пол-кирпича:
;     если фаза мячика 0,1,2 - проверяем только кирпич в этом ряду
;     для остальных фаз проверяем кирпич в этом ряду и в соседнем
; *************************************************
CheckBrickY
        lxi     hl, LEVEL_1
; hack        
        mvi     c, 0
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 8

        lda     BallY
        add     c               ; hack

        mov     c, a
        lda     BallDY
        add     c

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
        lda     BallX
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


CheckBrickYPlusOne
        lxi     hl, LEVEL_1
; hack        
        mvi     c, 0
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 8

        lda     BallY
        add     c               ; hack

        mov     c, a
        lda     BallDY
        add     c

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
        lda     BallX
        rar
        rar
        rar
        rar

        ani     0fh
        inr     a

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
DestroyBrickY
        push    hl
        push    de
        push    bc

        lda     BallX
        rar
        rar
        
        ani     03ch
        mov     b, a

; hack
        mvi     c, -8
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 16

        lda     BallY
        add     c       ; why?
        
        ani     0f8h
        mov     c, a

        xra     a
        call    PaintBrick1

        pop     bc
        pop     de
        pop     hl
        
        ret
        
; *************************************************
; 
; *************************************************
DestroyBrickYPlusOne
        push    hl
        push    de
        push    bc

        lda     BallX
        adi     8
        rar
        rar
        
        ani     03ch
        mov     b, a

; hack
        mvi     c, -8
        lda     BallDY
        rlc
        jc      .+5
        mvi     c, 16

        lda     BallY
        add     c       ; why?
        
        ani     0f8h
        mov     c, a

        xra     a
        call    PaintBrick1

        pop     bc
        pop     de
        pop     hl
        
        ret

; *************************************************
; *************************************************
DestroyBrickX
        push    hl
        push    de
        push    bc

; hack
        mvi     c, -1
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

        lda     BallY
        ani     0f8h
        mov    c, a

     push bc
        
        xra   a
        call  PaintBrick1

     pop bc
     call AddBonusToList 

        pop     bc
        pop     de
        pop     hl

        ret

; *************************************************
; *************************************************
DestroyBrickXPlusOne
        push    hl
        push    de
        push    bc

; hack
        mvi     c, -1
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

        lda     BallY
        
        adi     8
        
        ani     0f8h
        mov    c, a
        
        xra   a
        call  PaintBrick1

        pop     bc
        pop     de
        pop     hl

        ret
  
        
; *************************************************
; Стереть кирпич
; *************************************************
DestroyBrick
        push    hl
        push    de
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
        mvi     c, 8

        lda     BallY
        add     c       ; hack

        ani     0f8h
        mov    c, a
        
        xra   a
        call  PaintBrick1

        pop     bc
        pop     de
        pop     hl
        ret

; *************************************************
; А мячик скиньте?
; *************************************************
EraseBall
       call     RenderNoBall
       jmp      GoBall

PaintBall
        lda     BallX
        ani     7
        lxi     hl, BALLPHASES
        rrc
        rrc
        rrc
        mov     c, a
        mvi     b, 0
        dad     bc

        shld    BALLPHASE
        call    RenderBall
GoBall
        lda     BallY
        mov     c, a
        
        lda     BallX
        rar
        rar
        ani     3eh
        mov     b, a
        
        lxi     hl, BALLBUF
        call    PaintHorizontalBitmap2

        ret

; *************************************************
; Отрендерить мячик в буфер
; *************************************************
RenderBall
        push    hl
        push    de
        push    bc

        call    FillBallBuf

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

; *************************************************
; Насыпать в мячечный буфер фон и кирпичики
; *************************************************
FillBallBuf
        call    RenderBackground

; кирпичей может быть не больше 16 слоев (плюс верхние 2 служебных слоя)
        lda     BallY
        ani     128
        jz      .+4
        ret


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
        jz      NoNeed

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
NoNeed        

        ; TODO отрендерить в буфер кирпич
;        call    RenderBricks
        
        ; TODO отрендерить в буфер злецов (if any)

        ret

; *************************************************
; Отрендерить в буфер все, кроме собственно мячика
; *************************************************
RenderNoBall
        push    hl
        push    de
        push    bc
        call    FillBallBuf        
        pop     bc
        pop     de
        pop     hl

        ret


; *************************************************
; Вернуть в HL указатель на битмап кирпича справа от мячика
; *************************************************
GetRightBrickPtr
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
; Копировать блок из HL в DE длиной B
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

        lhld    BattyPtr
GoBatty        
        mvi     c, 0f0h         ; вертикальная позиция дубины
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
        call    PaintBitmap

        pop     bc
        inr     b
        inr     b
        lxi     hl, 16
        pop     de
        dad     d

        call    PaintBitmap

        ret


; ****************************************************************************
; Процессинг списка спрайтов бонусов
; ****************************************************************************
; Список фиксированный
; элемент списка: 
; - Тип бонуса (1 байт), 00h = пустой слот
; - Текущая скорость падения (1 байт) - возобновляемая задержка
; - Начальная скорость падения (1 байт) - для (пере)инициализации текущей
; - Координата Y (1 байт)
; - Координата X (1 байт)
; - Зарезервировано (2 байта)
; - лдпушный бонус-буфер (128 байт) - адская смесь кода и данных


MAXBONUSNUM     equ     5       ; 10      ; а что, тоже неплохое число
BONUSDEFAULTSPEED       equ     1
BonusListIndex  db      0

;                       Ptr     Cur.Speed Init.Speed    Y       X       Reserved
;-----------------      ---     --------- ----------    ---     ---     --------
;                       4000h   0          1            0       0       0000h

;BonusList       ds      40 ; MAXBONUSNUM*8


InitBonusList

        call    TestPops        ; создадим 4 буфера с адреса 4000h

        lxi     bc, 0711h
        call    AddBonusToList

        ret


ProcessBonusList
        lda     BonusListIndex
        cpi     MAXBONUSNUM
        jnz     ProcessBonusItem
        xra     a
        sta     BonusListIndex
ProcessBonusItem
        call    ProcessBonus
        ret

; ************************************************
; BC - координаты только что выбитого кирпича
; ************************************************
AddBonusToList
        push    bc      ; сохраним координаты
        mvi     c, MAXBONUSNUM
        lxi     hl, BONUSLIST
FindEmptySlot
        mov     a, m
        ora     a
        jnz     NextSlotPlease
        
        pop     bc      ; восстановим координаты
        mvi     m, 1    ; тип бонуса (TODO rnd)
        inx     hl
        
        mvi     m, 10   ; текущая скорость бонуса
        inx     hl
        
        mvi     m, 10   ; начальная скорость
        inx     hl
        
        mov     m, c    ; Y
        inx     hl
        
        mov     m, b    ; X

        ret
        
NextSlotPlease
        lxi     de, 128 ; размер буфера с бонусом
        dad     de
        dcr     c
        jnz     FindEmptySlot
        pop     bc
        ret

; ************************************************
; ProcessBonus
; A = индекс в листе
; ************************************************
ProcessBonus
        ora     a
        ral
        ral
        mov     c, a
        mvi     b, 0
        lxi     hl, BonusList
        dad     bc      ; указатель на 1й байт (тип бонуса, он же слот)
; проверить слот
        mov     a, m
        ora     a
        jz      PBDone  ; пустой слот оказался
; проверить скорость падения, если пора, обновить координату
        inx     hl      ; указатель на 2й байт (задержка)
        mov     a, m
        ora     a
        jz      TimeToMove
        dcr     m
        jmp     PBDone
TimeToMove
        mvi     m, BONUSDEFAULTSPEED    ; снова взведем задержку
; сотрем на старом месте
        inx     hl      ; указатель на 3й байт (координата Y)
        call    EraseBonus
        inr     m       ; прирастим координату
        mov     a, m
        cpi     BOTTOMMARGIN
        jnz     ContinueMoving
; прекратить жизненный цикл бонуса в силу разных причин
        dcx     hl
        dcx     hl
        mvi     m, 0    ; обнулим слот
        jmp     PBDone
ContinueMoving
        call    PaintBonus
; перейти к следующему бонусу в листе
PBDone
        lxi     hl, BonusListIndex
        inr     m
        ret
        
; *******************************************
; PaintBonus
; *******************************************
PaintBonus
        mov     c, m
        inx     hl
        mov     b, m
        lxi     hl, BONUS
        call    PaintBitmap
        ret
; *******************************************
; EraseBonus
; *******************************************
EraseBonus
        push    hl
        mov     c, m
        inx     hl
        mov     b, m
        lxi     hl, NOBATTY+1   ; просто удобно, там куча нулей
        call    PaintBitmap
        pop     hl
        ret
; ****************************************************************************

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

        call    Copy8

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
Copy8
        push    h
        push    d

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a
        inx     d
        inx     h

        ldax    d
        mov     m, a

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
; нулевую фазу тоже скопируем
        lxi     hl, BALL
        lxi     de, BALLPHASES
        mvi     b, 32
        call    Copy_B_Bytes_From_HL_To_DE

; а теперь семь сдвинутых фаз
        mvi     a, 2
        sta     BitmapWidth

        mvi     a, 32
        sta     PhaseSize

        lxi     hl, BALLPHASES
        lxi     de, BALLPHASES+32
        call    ShiftBitmap
 
        lxi     hl, BALLPHASES+32
        lxi     de, BALLPHASES+64
        mvi     a, 7       
        jmp     FBPLoop

; *************************************************
; Заполнить Буфер Сдвинутых Ракеток
; *************************************************
FillBattyBuf
; нулевая фаза
        lxi     hl, BATTY1+1
        lxi     de, BATTYBUF
        mvi     b, 64
        call    Copy_B_Bytes_From_HL_To_DE

; а теперь семь фаз ракетки
        mvi     a, 4
        sta     BitmapWidth

        lxi     hl, 64
        shld    PhaseSize

        lxi     hl, BATTYBUF
        lxi     de, BATTYBUF+64
        call    ShiftBitmap

        lxi     hl, BATTYBUF+64
        lxi     de, BATTYBUF+128
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
; Простор для экспериментов
; *************************************************

; создадим 4 буфера по образу и подобию BumpBitmap8x8
TestPops
        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, 4000h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, 4100h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, 4200h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, 4300h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        ret
        
; Заголовок бонуса        
BumpBitmap8x8Hdr        
        db      0, 1, 2, 3, 4, 5, 6, 7
; Тело бонуса
BumpBitmap8x8
; преамбула
        di
        mvi     a, ENROM
        out     BANKING
; сохранить SP в HL
        lxi     hl, 0
        dad     sp
        xchg    ; теперь старый указатель стека в DE
        lxi     hl, SCREEN+8
; выводим первый столбик, снизу вверх
        ;lxi     sp, SCREEN+8
        sphl
        lxi     bc, 0102h
        push    bc
        lxi     bc, 0304h
        push    bc
        lxi     bc, 0506h
        push    bc
        lxi     bc, 0708h
        push    bc
; выводим второй столбик
        ;lxi     sp, SCREEN+8+256
        inr     h
        sphl
        lxi     bc, 090ah
        push    bc
        lxi     bc, 0b0ch
        push    bc
        lxi     bc, 0d0eh
        push    bc
        lxi     bc, 0f00h        
        push    bc
; восстановить SP
        xchg
        sphl
; постамбула
        xra     a
        out     BANKING
        ret
BumpBitmap8x8_end

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

BONUS   db      0fch, 1eh, 47h, 23h, 43h, 21h, 42h, 0fch
        db      0, 1ch, 0a6h, 42h, 0a2h, 40h, 20h, 0

; Нет дубины
NOBATTY db      4
        ds      64

        .org 0e00h
; *********************************************************************
; Кирпичики
; 00 - пустое место
; *********************************************************************

LEVEL_1 
        db      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
        db      0, 82h, 81h,81h,81h,81h,81h,81h,81h,81h,81h,81h,81h,81h,83h, 0
        db      0, 82h, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,83h, 0
        db      0, 82h, 5, 5, 0, 0, 81h, 0, 81h, 0, 0, 0, 0, 0,83h, 0
        db      0, 82h, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0
        db      0, 82h, 7, 4, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 83h, 0
        db      0, 82h, 8, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 83h, 0
        db      0, 82h, 9, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 83h, 0
        db      0, 82h, 10,10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 83h, 0
        db      0, 82h, 11,11,11,11,11,11,11,11,11,11,11,11,83h, 0
        db      0, 82h, 9, 12, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 83h, 0
        db      0, 82h, 6, 13, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 83h, 0        
        db      0, 82h, 7, 7, 8, 8, 9, 9, 8, 8, 7, 7, 6, 6, 83h, 0
        db      0, 82h, 9,10,11,12, 9,10,11,12, 9,10,11,12, 83h, 0
        db      0, 82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0
        db      0, 82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0

;LEVEL_1_END
;        ds      WIDTH*HEIGHT
        

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

ReflectFlag     db      0

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

DebugStepMode   db      1
DebugPalette    db      0

; Массив указателей на фазы дубины
BATTYPTRARRAY   dw      BATTYBUF,       BATTYBUF+40h,   BATTYBUF+80h,   BATTYBUF+0c0h
                dw      BATTYBUF+100h,  BATTYBUF+140h,  BATTYBUF+180h,  BATTYBUF+1c0h
; Массив указателей на фазы мячика
BALLPTRARRAY    dw      BALLPHASES,     BALLPHASES+32,  BALLPHASES+64,  BALLPHASES+96
                dw      BALLPHASES+128,  BALLPHASES+160,  BALLPHASES+192,  BALLPHASES+224                

BattyPtr        dw      BATTYBUF                

; *********************************************************************
; Буфера (.)(.)
; *********************************************************************
BOOPHERS        equ     .
; Буфер мячика
; сюда будут отрисовываться фон, кирпичики и сам мячик для последующего вывода
BALLBUF         equ     BOOPHERS        ;ds      32      

; Буфер Сдвинутых Ракеток
BATTYBUF        equ     BALLBUF+32      ;ds      64*8

; Фазы мячика
BALLPHASES      equ     BATTYBUF+64*8   ;ds      16*8


BONUSLIST       equ     4000h
        
  
