        .project ark.bin

;
; TODO:
;       - быстрая прорисовка ракетки
;       - бонусы шириной в кирпич
;       - маска для вывода бонуса по AND+OR
;       + (DONE) внутренний буфер с отрендеренными кирпичами
;       - счетчик ракеток
;	- поле высотой 24 кирпича
;	- упаковка и распаковка уровней

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

WIDTH           equ     24      ;16
HEIGHT          equ     16
SCORE_COORDS    equ     0238h
LEVEL_COORDS    equ     0258h
SCORE_LINE_XY   equ     0600h + 5*8
NEXT_LINE_XY    equ     3400h + 5*8
LEVEL_LINE_XY   equ     0600h + 9*8
PREVIEW_COORD   equ     020fh
HKCOUNT         equ     8000

;DEFAULTBALLDELAY        equ     4
DEFAULTBATTYDELAY       equ     0
BATTY_STOP      equ     0
BATTY_RIGHT     equ     1
BATTY_LEFT      equ     2
DEFAULTBALLX    equ     58h     ;32
DEFAULTBALLY    equ     100     ;12h     ;224
DEFAULTBALLDX   equ     1       ; debug Y first ; 1
DEFAULTBALLDY   equ     1

DefaultDelayDX  equ     1
DefaultDelayDY  equ     1

DEFAULTBATTYPOS equ     80
BATTYDISTANCE   equ     3

        org     100h

    ;    call    NewNoteTest


VeryBegin
; Чистим экран
        mvi     a, 40h          ; палитра 1: черный, красный, зеленый, синий
        ;mvi     a, 43h          ; палитра 3: черный, красный, малиновый, белый
        out     VIDEO
        call    ResetScroll
        call    ClearScreen
        
        call    EraseMongolia
        
; Инициализация важных и нужных переменных
        lxi     hl, HKCOUNT
        shld    SPEED
        shld    CountDown
        xra     a
        sta     SCORE3
        sta     SCORE2
        sta     SCORE1
        sta     X
        sta     Y
        
        mvi     a, 1
        sta     LEVEL

        mvi     a, DEFAULTBATTYPOS
        sta     BattyPos

        mvi     a, BATTYDISTANCE
        sta     BattyDistanceToRun

;        mvi     a, DEFAULTBALLDELAY
;        sta     BallDelay

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

        mvi     a, (DEFAULTBALLX>>2)<<1
        sta     BallX_scr

;        mvi     a, 0 ; TODO
;        sta     BallBrickIndex
        call    BallNewPos2BrickIndex

        lxi     hl, BALL
        shld    BALLPHASE

        mvi     a, DefaultDelayDX
        sta     DelayDX
        sta     CounterDX

        mvi     a, DefaultDelayDY
        sta     DelayDY
        sta     CounterDY

        mvi     a, FX_BUURP
        sta     SoundFX

        mvi     a, 3
        sta     Batties

; Кирпич 1
        lxi     bc, 0400h
        lxi     hl, BONUS16
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

        call    InitBonusList

        call    DrawBatties

   
        call    PaintScore


        call    BumpBitmap8x16
        

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
        mvi     a, BATTYDISTANCE
        sta     BattyDistanceToRun
        jmp     Begin

CurRight
        mvi     a, BATTY_RIGHT
        sta     BattyDirection
        mvi     a, BATTYDISTANCE
        sta     BattyDistanceToRun        
        jmp     Begin

CurUp
        mvi     a, BATTY_STOP
        sta     BattyDirection
        xra     a
        sta     BattyDistanceToRun
        jmp     Begin


; Музло
; *******************************************
; Звук
FX_NONE         equ     0
FX_CLICK        equ     1
FX_BUURP        equ     2

DoSoundFX
        lda     SoundFX
        cpi     FX_CLICK
        jz      SND_CLICK
        cpi     FX_BUURP
        jz      SND_DROP

        ret

SND_DROP
        push    hl
        lxi     h, 0a000h
        shld    BELL_FREQ
        lxi     h, 0004h
        shld    BELL_LEN
        jmp     BEEP

SND_CLICK
        push    hl
        lxi     h, 0200h
        shld    BELL_FREQ
        lxi     h, 0020h
        shld    BELL_LEN
        jmp     BEEP
        
BEEP    
        xra     a
        sta     SoundFX
        
        pop     hl
        mvi     c, 7
        jmp     CHAROUT
      
      
; *************************************************
; Вывести СКОРЕ
; *************************************************
PaintScore
        push    hl
        push    bc

        lda     SCORE3
        lxi     bc, 0x3418
        call    PaintDigit


        lda     SCORE2
        push    a
        rar
        rar
        rar
        rar
        lxi     bc, 0x3618
        call    PaintDigit
        
        pop     a
        lxi     bc, 0x3818
        call    PaintDigit

        lda     SCORE1
        push    a
        rar
        rar
        rar
        rar
        lxi     bc, 0x3a18
        call    PaintDigit
        
        pop     a
        lda     SCORE1
        lxi     bc, 0x3c18
        call    PaintDigit


        pop     bc
        pop     hl
        
        ret
        
; *************************************************
; Нарисовать цифру из DIGITS
; *************************************************
PaintDigit
        push    bc
        ani     0fh
        ral
        ral
        ral
        ral
        mov     c, a
        mvi     b, 0
        lxi     hl, DIGITS
        dad     bc
        pop     bc


        push    hl
        push    bc
        call    PaintBitmap
        pop     hl
        lxi     bc, 8
        dad     bc
        push    hl
        pop     bc
        
        pop     hl
        inr     h
        call    PaintBitmap
        ret


; *************************************************
; Хаускипинг
; *************************************************
HouseKeeping

; ----- Первый фрейм -----
        call    SyncToRetrace
        
        lda     DebugPalette
        ora     a
        jz      NoPaletteDebug

        mvi     a, 46h          ; зеленый фон
        out     VIDEO
        call    NewProcessBall
        
        mvi     a, 41h          ; белый фон
        out     VIDEO
        call    ProcessBatty
        
        mvi     a, 42h          ; красный фон
        out     VIDEO
        
        call    ProcessBonusList
        call    ProcessBonusList
        call    ProcessBonusList
        
        mvi     a, 40h          ; дефолтный черный фон
        out     VIDEO
        jmp     SecondFrame
        
NoPaletteDebug
        call    NewProcessBall
        call    ProcessBatty
        
        call    ProcessBonusList
        call    ProcessBonusList
        call    ProcessBonusList
        
        jmp     SecondFrame


; ----- Второй фрейм -----
SecondFrame
; добавить нормальную синхронизацию по кадру
 ;       in      41h
 ;       ani     2
 ;       jnz     SecondFrame

        ; странный способ определить, не просран ли мячик
        lda     SoundFX
        cpi     FX_BUURP
        jnz     SecondFrameCont

        ; мяч просран; начинаем все сызнова
        ; инит переменных, декремент стопки дубин и т.д.

        call    EraseBall
        
        mvi     a, DEFAULTBALLX
        sta     BallX
        mvi     a, DEFAULTBALLY
        sta     BallY
        
        mvi     a, DEFAULTBALLDX
        sta     BallDX
        mvi     a, DEFAULTBALLDY
        sta     BallDY

SecondFrameCont        

        call    DoSoundFX

        call    SyncToRetrace



        jmp     Begin

SyncToRetrace
        ; подождем наступления ретрейса
;        in      41h
;        ani     2
;        jz      SyncToRetrace
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
        cpi     200-24
        jnz     L20f
        mvi     a, BATTY_STOP
        sta     BattyDirection
MoveDone        
        call    CalculateBattyPhase
        call    PaintBatty
        
        lda     BattyDistanceToRun
        ora     a
        jnz     MoveDoneDone
        mvi     a, BATTY_STOP
        sta     BattyDirection
        ret
MoveDoneDone        
        dcr     a
        sta     BattyDistanceToRun
        
        ret
L20f
        ;inr     a
        adi     2
        sta     BattyPos
        jmp     MoveDone

MoveLeft
        call    EraseBatty
        lda     BattyPos
        cpi     16
        jnz     MoveLeftJa
        mvi     a, BATTY_STOP   ; Как насчет отталкиваться?
        sta     BattyDirection
        jmp     MoveDone
MoveLeftJa        
        ;dcr     a
        sui     2
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

; ******************************************************************************
; Новый Мячевой Процессинг
; ******************************************************************************

CounterDX       db      0       ; счетчик задержки
CounterDY       db      0
DelayDX         db      2       ; задержка приращения по X
DelayDY         db      2

NewProcessBall
        call    EraseBall
        call    UpdateX
        call    UpdateY
        call    BallNewPos2BrickIndex
        call    PaintBall
        jmp     CheckDone
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
        call    XPlusDX
        call    CheckNew
        call    LetsReflectX
        
        ; собственно прирастим координату
        call    XPlusDX
        sta     BallX

        ; сохранить прекалк X в экранный X
        rar
        rar
        ani     3eh
        sta     BallX_scr
        
        ret

LEFTMARGIN      equ     16
RIGHTMARGIN     equ     200
TOPMARGIN       equ     16
BOTTOMMARGIN    equ     224 ;240
BATTYMARGIN     equ     232

; *************************************************
; Проверим новую координату и отразимся, если нужно
; *************************************************
CheckNew

        xra     a
        sta     BricksHit

; кирпич (newx, newy) проверяем всегда        
        call    BallNewCoords2BrickPtr
        call    DestroyBrickByPlayfieldAddr
        lda     BricksHit
        ora     a
        jnz     CheckNewDone
        
; кирпич (newx+1, newy) проверяем, если 11<=X<15
        lda     BallX_new
        ani     0fh
        cpi     10
        jm      CNX1

        lxi     bc, 01
        dad     bc
        call    DestroyBrickByPlayfieldAddr
        lda     BricksHit
        ora     a
        jnz     CheckNewDone

CNX1
; кирпич (newx, newy+1) проверяем, если 3<=Y<7
        lda     BallY_new
        ani     07h
        cpi     3
        jm      CheckNewDone
        
        call    BallNewCoords2BrickPtr
        lxi     bc, 16
        dad     bc
        call    DestroyBrickByPlayfieldAddr
        lda     BricksHit
        ora     a
        jnz     CheckNewDone

        lda     BallX_new
        ani     0fh
        cpi     10
        jm      CheckNewDone

        lxi     bc, 01
        dad     bc
        call    DestroyBrickByPlayfieldAddr
        lda     BricksHit
        ora     a
        jnz     CheckNewDone

CheckNewDone
        ret


; *************************************************
; Радикально сменить направление по X
; *************************************************
LetsReflectX
        lda     BricksHit
        ora     a
        jnz     LetsReflectXDo

        lda     BallX
        cpi     LEFTMARGIN
        jz      LetsReflectXdo
        cpi     RIGHTMARGIN
        jz      LetsReflectXdo
        ret
        
LetsReflectXDo
        lda     BallDX
        cma
        inr     a
        sta     BallDX
        ; call    SND_CLICK
        mvi     a, FX_CLICK
        sta     SoundFX
        ret

; *************************************************
; Вернуть в аккумуляторе потенциальный X
; *************************************************
XPlusDX
        lda     BallDX
        mov     c, a
        lda     BallX
        add     c
        sta     BallX_new
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
        call    YPlusDY
        call    CheckNew
        call    LetsReflectY

        ; собственно прирастим координату
        call    YPlusDY
        sta     BallY
        
        ret

; *************************************************
; Получить из координат мячика указатель на кирпич в HL
; *************************************************
BallNewCoords2BrickPtr
        call    BallNewPos2BrickIndex
        lhld    BallBrickIndex
        lxi     bc, LEVEL_1
        dad     bc
        ret

LetsReflectY
        lda     BricksHit
        ora     a
        jnz     LetsReflectYDo
        
        lda     BallY
        cpi     TOPMARGIN
        jz      LetsReflectYDo
        cpi     BATTYMARGIN-8
        jz      WhereIsMyBatty
;        cpi     BOTTOMMARGIN
;        jz      LetsReflectYDo
        ret

WhereIsMyBatty
        lda     BattyPos
        mov     c, a
        lda     BallX
        sub     c       ; delta = Xball - Xbatty
        jm      CheckMissLeft

CheckMissRight
        sui     24
        jm      LetsReflectYDo
        jmp     Miss

CheckMissLeft
        adi     6
        jm      Miss
        jmp     LetsReflectYDo
        
Miss            
        ; Ыыыыыыы
        mvi     a, FX_BUURP
        sta     SoundFX

        lda     Batties
        ora     a
        jz      Miss1
        dcr     a
        sta     Batties
        
        call    DrawBatties
Miss1                
        ret
        
LetsReflectYDo        
        lda     BallDY
        cma
        inr     a
        sta     BallDY
        
        mvi     a, FX_CLICK
        sta     SoundFX
        ret

; *************************************************
; Инкрементнём Y
; *************************************************
YPlusDY
        lda     BallDY
        mov     c, a
        lda     BallY
        add     c
        sta     BallY_new
        ret

; ******************************************************************************
; Конец Нового Мячевого Процессинга
; ******************************************************************************




; ****************************************************************************
; Мячевой процессинг
;
; ****************************************************************************

; -------------займемся координатой по вертикали Y
; В фазах 0,1,2 мячик не выходит за пределы 8 пикселей:
;
; ..OO....
; .OOOO...
; OOOOOO..
; OOOOOO..
; .OOOO...
; ..OO....
;
; и проверять нужно только кирпич под ним. 
; Если координата мячика НЕ кратна 16 (8..15, 24..39, 40 и т.д.), то в фазах 3,4,5,6,7 нужно проверять
; кирпич под ним и его соседа справа 

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


; *******************************************************************
; Преобразовать координаты мячика в индекс кирпича в массиве кирпичей
; *******************************************************************
BallNewPos2BrickIndex
        lda     BallY_new

        ani     0b11111000      ; или 0b01111000?
        ral
        mov     c, a

        mvi     a, 0
        adc     a
        mov     b, a

        lda     BallX_new
        ora     a
        rlc
        rlc
        rlc
        rlc
        ani     0fh
        add     c

        sta     BallBrickIndex
        mov     a, b
        sta     BallBrickIndex+1
        ret

; *************************************************
; Стереть кирпич по его индексу
; *************************************************
DestroyBrickByIndex

        call    BrickIndexToScreenCoords
        xra   a
        call  PaintBrick1       ; PaintBrick: B=X, C=Y

        ret

; *************************************************
; Стереть кирпич по его адресу в таблице (HL)
; *************************************************
DestroyBrickByPlayfieldAddr

        lda     BricksHit
        ora     m
        sta     BricksHit
        
        mov     a, m
        ora     a
        jnz     DoTheJob
        ret

DoTheJob
        ani     80h
        jz      DoTheJobWillYa
        ret

DoTheJobWillYa


        mvi     m, 0

        mov     a, l
        rar
        ani     78h
        mov     c, a    ; Y
        
        mov     a, l
        ani     0fh
        ral
        ral

        mov     b, a    ; X
    push bc        
        xra     a
        call    PaintBrick1

     pop bc
     call AddBonusToList 


; счет
        lda     SCORE1
        inr     a
        daa
        sta     SCORE1
        jnc     DTJDone

        lda     SCORE2
        inr     a
        daa
        sta     SCORE2

        jnc     DTJDone

        lda     SCORE3
        inr     a
        daa
        sta     SCORE3
        
        
DTJDone        
        call    PaintScore



        ret

; *************************************************
; Преобразовать индекс кирпича (A) в экранные координаты (BC)
; *************************************************
BrickIndexToScreenCoords
        push    a
        ani     0f0h
        rar
        mov     c, a
        
        pop     a
        ani     0fh
        ral
        ral
        mov     b, a
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
        inr     h
        shld    BALLMASKPHASE
        call    RenderBall
GoBall
        lda     BallY
        mov     c, a
        
        ;lda     BallX
        ;rar
        ;rar
        ;ani     3eh
        lda     BallX_scr
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

        ; Маска по AND
        lhld    BALLMASKPHASE
        lxi     de, BALLBUF
        mvi     c, 32

RenderAndLoop        
        ldax    de
        ana     m
        stax    de
        inx     hl
        inx     de
        dcr     c
        jnz     RenderAndLoop


        ; Наложим поверх мячик по OR
        lhld    BALLPHASE
        lxi     de, BALLBUF
        mvi     c, 32
RenderOrLoop        
        ldax    de
        ora     m
        stax    de
        inx     hl
        inx     de
        dcr     c
        jnz     RenderOrLoop

        pop     bc
        pop     de
        pop     hl
        ret

; *************************************************
; Насыпать в мячечный буфер фон и кирпичики
; *************************************************
FillBallBuf
        call    RenderBackground

ret
        
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

; преобразовать пиксельные координаты мячика в экранный адрес
        ;lda     BallX
        ;rar
        ;rar
        ;ani     03eh
        lda     BallX_scr
        mov     b, a
        
        lda     BallY
        mov     c, a

        lxi     hl, MONGOLIA
        dad     bc      ; теперь в HL адрес растровой строки в Монголии
        
;        lxi     de, BALLBUF
;        mvi     b, 32
;        call    Copy_B_Bytes_From_HL_To_DE

        lxi     de, BALLBUF

        push    hl
        call    Copy_Eight_Bytes_From_HL_To_DE
        pop     hl
        inr     h

        push    hl
        call    Copy_Eight_Bytes_From_HL_To_DE
        pop     hl
        inr     h

        push    hl
        call    Copy_Eight_Bytes_From_HL_To_DE
        pop     hl
        inr     h

        push    hl
        call    Copy_Eight_Bytes_From_HL_To_DE
        pop     hl
        
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
; Копировать ВОСЕМЬ байт из HL в DE
; *************************************************
Copy_Eight_Bytes_From_HL_To_DE
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
        mov a, m \ stax de \ inx hl \ inx de
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
        mvi     c, BATTYMARGIN ; 0f0h         ; вертикальная позиция дубины
        lda     BattyPos
        rar
        rar
;        rar
        ani     0b00111110
        mov     b, a

        call    PaintHorizontalBitmap4
        ret

; *************************************************
; Нарисовать стопку дубин
; *************************************************
DrawBatties
        lxi     hl, BATTY1
        lxi     bc, 0x36e0
        call    PaintHorizontalBitmap4

        lxi     hl, BATTY1
        lxi     bc, 0x36e0-10
        call    PaintHorizontalBitmap4

        lxi     hl, BATTY1
        lxi     bc, 0x36e0-20
        call    PaintHorizontalBitmap4


        ret

; *************************************************
; Нарисовать уровень
; *************************************************
DrawLevel
        mvi     b, HEIGHT
        mvi     c, WIDTH
      
        lxi     de, HEIGHT*WIDTH
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
        dcx     de
        mov     a, d
        ora     e
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
        call    RenderBrickToMongolia
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

; *******************************************
; Нарисовать кирпич вовнутрь
; HL - указатель на битмап кирпича
; BC - экранные координаты кирпича
; *******************************************
RenderBrickToMongolia
        push    hl
        push    de
        
        push    hl
        lxi     hl, MONGOLIA
        dad     bc
        
        pop     de       ; de = адрес битмапа

        push    bc

        call    Copy8

        ; Второй план битмапа
        push    h
        lxi     h, 8
        dad     d
        xchg            ; de = битмап + 8

        ; Перейдем ко второму плану экрана
        pop     h
        inr     h
        call    Copy8
        
        push    h
        lxi     h, 8
        dad     d
        xchg
        pop     h
        inr     h
        call    Copy8
        
        push    h
        lxi     h, 8
        dad     d
        xchg
        pop     h
        inr     h
        call    Copy8

        pop     bc
        pop     de
        pop     hl
        ret

; *******************************************
; Зачистить внутреннюю Монголию
; *******************************************
EraseMongolia
        lxi     hl, Mongolia
EraseMongoliaLoop
        mvi     m, 0
        inx     hl
        mov     a, h
        cpi     0x80
        jnz     EraseMongoliaLoop
        ret


; ****************************************************************************
; Процессинг списка спрайтов бонусов
; ****************************************************************************
; Список фиксированный
; элемент списка: 
; Off   Descr
; ----- --------
; 00    - Тип бонуса (1 байт), 00h = пустой слот
; 01    - Текущая скорость падения (1 байт) - возобновляемая задержка
; 02    - Начальная скорость падения (1 байт) - для (пере)инициализации текущей
; 03    - Координата Y (1 байт)
; 04    - Координата X (1 байт)
; 05    - Зарезервировано (2 байта)
; 07    - лдпушный бонус-буфер (128 байт) - адская смесь кода и данных


MAXBONUSNUM     equ     5       ; 10      ; а что, тоже неплохое число
BONUSDEFAULTSPEED       equ     0
BonusListIndex  db      0

;                       Ptr     Cur.Speed Init.Speed    Y       X       Reserved
;-----------------      ---     --------- ----------    ---     ---     --------
;                       4000h   0          1            0       0       0000h

;BonusList       ds      40 ; MAXBONUSNUM*8


InitBonusList

        call    TestPops        ; создадим 4 буфера с адреса 4000h

;        lxi     bc, 0711h
;        call    AddBonusToList

        ret

ProcessBonusList
        lda     BonusListIndex
        cpi     MAXBONUSNUM
        jnz     ProcessBonusItem
        xra     a
        sta     BonusListIndex
ProcessBonusItem
        call    ProcessBonus
; перейти к следующему бонусу в листе
        lxi     hl, BonusListIndex
        inr     m
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
        
        mvi     m, 5   ; текущая скорость бонуса
        inx     hl
        
        mvi     m, 5   ; начальная скорость
        inx     hl

; преобразуем координаты выбитого кирпича в начальный экранный адрес бонуса

        push    hl

        lxi     h, SCREEN+8
        dad     bc
        
        xchg    ; в DE теперь экранный адрес бонуса
        
        pop     hl
        
        lxi     bc, 10h ; магическое смещение от начала бонус-буфера
        dad     bc
        
        mov     m, e
        inx     hl
        mov     m, d

        ret
        
NextSlotPlease
        ;lxi     de, 256 ; размер буфера с бонусом
        ;dad     de
        inr     h
        dcr     c
        jnz     FindEmptySlot
        pop     bc
        ret

; ************************************************
; ProcessBonus
; A = индекс в листе
; ************************************************
ProcessBonus
        lxi     hl, BonusList
        add     h
        mov     h, a ; теперь в HL указатель на заголовок бонуса (слот)
; проверить слот
        mov     a, m
        ora     a
        jnz     ProcessBonus1  
        ret     ; пустой слот оказался
ProcessBonus1        
; проверить скорость падения, если пора, обновить координату
        inx     hl      ; указатель на 2й байт (задержка)
        mov     a, m
        ora     a
        jz      TimeToMove
        dcr     m
        ret
TimeToMove
        mvi     m, BONUSDEFAULTSPEED    ; снова взведем задержку
; сотрем на старом месте (достаточно стереть только байт хвоста)
        ;inx     hl      ; указатель на 3й байт (координата Y)
        mvi     l, 13h  ; смещение от заголовка бонус-буфера до экранного адреса

        inr     m       ; прирастим координату
        mov     a, m
        cpi     BATTYMARGIN+8     ;BOTTOMMARGIN
        jnz     ContinueMoving
; прекратить жизненный цикл бонуса в силу разных причин

; стереть с экрана TODO
; тупо нарисуем пустое место
        push    hl
        mov     a, m
        sui     9
        mov     c, a
        inx     hl
        mov     a, m
        sui     0c0h
        mov     b, a
        lxi     hl, BITMAP0
        call    PaintBitmap
        pop     hl

        mvi     l, 0    ; в начало заголовка (бонус-буфер лежит на границе 256)
        mvi     m, 0    ; обнулим слот

        ret

ContinueMoving
        ; добудем из Монголии байт для восстановления
        ; TODO это можно сделать (делать) в процессе декремента задержки
        push    de
        push    hl
        
        
        mov     e, m
        inx     hl
        mov     d, m
        xchg

        lxi     bc, 7ff6h       ; -8009h
        dad     bc
        ;mvi     h, 40h  ; монгольский адрес
        
        mov     d, m    ; байт первого плана
        inr     h
        mov     e, m    ; байт второго плана
        
        pop     hl
        
        mvi     l, 27h   ; смещение от заголовка бонус-буфера до девятого байта
        mov     m, d
        mvi     l, 3dh   ; смещение до девятого байта второго плана
        mov     m, e
        
        pop     de
        
        
        ; call    PaintBonus
        mvi     l, 8    ; начало кода самовывода в бонус-буфере
        pchl

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
        dad     bc
        
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
; Скопировать 8 байт битмапа из DE в HL
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
;PaintScore
        
;        push    de
;        push    bc
        
;        xra     a
;        sta     SuppressLeadingZeroes
        
;        lda     SCORE
;        ora     a
;        jz      PSDone          ; чего его выводить, если он нулевой
        
;        mov     d, a
;        mvi     e, 8
;        lxi     b, SCORE_COORDS
;        call    PSLoop

;PSDone        
;        pop     bc
;        pop     de
        
;        ret

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
        
        xra     a       ; NOP opcode
        sta     SBPop
        
        call    ShiftBitmap
 
        lxi     hl, BALLPHASES+32
        lxi     de, BALLPHASES+64
        mvi     a, 7       

        call    FBPLoop

; И восемь фаз маски
        lxi     hl, BALLMASK
        lxi     de, BALLMASKPHASES
        mvi     b, 32
        call    Copy_B_Bytes_From_HL_To_DE

; а теперь семь сдвинутых фаз
        mvi     a, 2
        sta     BitmapWidth

        mvi     a, 32
        sta     PhaseSize

        lxi     hl, BALLMASKPHASES
        lxi     de, BALLMASKPHASES+32

        mvi     a, 37h  ; STC opcode
        sta     SBPop
        
        call    ShiftBitmap
 
        lxi     hl, BALLMASKPHASES+32
        lxi     de, BALLMASKPHASES+64
        mvi     a, 7       
        call    FBPLoop
        
        ret

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
SBPOp   nop     ; для сдвига масок нужно заполнение единицами
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

; создадим 5 буферов по образу и подобию BumpBitmap8x8
TestPops

        ;call    RenderBonus     ; тоже тест
        ;call    RenderBonusII

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, BONUSLIST
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, BONUSLIST+100h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, BONUSLIST+200h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, BONUSLIST+300h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

        lxi     hl, BumpBitmap8x8Hdr
        lxi     de, BONUSLIST+400h
        mvi     b, BumpBitmap8x8_end-BumpBitmap8x8Hdr
        call    Copy_B_Bytes_From_HL_To_DE

; и еще шестой, для мячика как бы

        lxi     hl, BumpBitmap8x16
        lxi     de, BONUSLIST+500h
        mvi     b, BumpBitmap8x16_end-BumpBitmap8x16
        call    Copy_B_Bytes_From_HL_To_DE

        ret

;BONUS   db      0fch, 1eh, 47h, 23h, 43h, 21h, 42h, 0fch
;        db      0, 1ch, 0a6h, 42h, 0a2h, 40h, 20h, 0

        
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
        sphl
        lxi     bc, 0fc1eh
        push    bc
        lxi     bc, 4723h
        push    bc
        lxi     bc, 4321h
        push    bc
        lxi     bc, 42fch
        push    bc
; это бонусный битмап, он ползет сверху вниз, а выводится снизу вверх
; что весьма удобно для затирания следа сверху
        lxi     bc, 0000h       ; только учтем, что выводятся две строчки
        push    bc
; выводим второй столбик
        inr     h
        sphl
        lxi     bc, 001ch
        push    bc
        lxi     bc, 0a642h
        push    bc
        lxi     bc, 0a240h
        push    bc
        lxi     bc, 2000h        
        push    bc
; затираем след во втором плане
        lxi     bc, 0000h
        push    bc
        
; восстановить SP
        xchg
        sphl
; постамбула
        xra     a
        out     BANKING
        ei
        ret
BumpBitmap8x8_end




BumpBitmap8x16
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
        sphl
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
; выводим второй столбик
        inr     h
        sphl
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
; третий
        inr     h
        sphl
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
; четвертый
        inr     h
        sphl
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
        lxi bc, 5555h \ push bc \ lxi bc, 5555h \ push bc
; восстановить SP
        xchg
        sphl
; постамбула
        xra     a
        out     BANKING
        ei
        ret
BumpBitmap8x16_end


; Стереть цветной байт с экрана
; HL = экранный адрес
EraseColorByteFromScreen
        di
        mvi     a, ENROM
        out     BANKING
        xra     a
        mov     m, a
        inr     h
        mov     m, a
        out     BANKING
        ei
        ret

; Рендер бонуса в лдпушбуфер, вариант 1
RenderBonus

; сохранить SP в HL
        lxi     hl, 0
        dad     sp
        xchg    ; теперь старый указатель стека в DE
        
        lxi     hl, BumpBitmap8x8+1dh   ;40a5h       ; приемник (лдпушбуфер)
        sphl

        lxi     hl, BONUS+7
; первый столбик
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc
;        dcx sp \ dcx sp

; второй столбик
        lxi     hl, BumpBitmap8x8+33h   ;40bbh
        sphl

        lxi     hl, BONUS+15

        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc \ dcx sp \ dcx sp
        mov c, m \ dcx hl \ mov b, m \ dcx hl \ push bc
;        dcx sp \ dcx sp

; восстановить SP
        xchg
        sphl
        
        ret

; Рендер, вариант 2. Нацелить SP на стек с адресами (или смещениями) в лдпуш, куда надо писать
RenderBonusII
; сохранить SP в HL
        lxi     hl, 0
        dad     sp
        shld    OldSP

        lxi     hl, RB2Offsets
        sphl
        
        lxi     de, BONUS+15

        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de

        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de
        pop     bc
        ldax de \ stax bc \ dcx de \ dcx bc
        ldax de \ stax bc \ dcx de

; восстановить SP
        lhld    OldSP
        sphl
        ret

RB2Offsets
        dw      BumpBitmap8x8Hdr+24h, BumpBitmap8x8Hdr+20h, BumpBitmap8x8Hdr+1ch, BumpBitmap8x8Hdr+18h
        dw      BumpBitmap8x8Hdr+3ah, BumpBitmap8x8Hdr+36h, BumpBitmap8x8Hdr+32h, BumpBitmap8x8Hdr+2eh
        


OldSP   ds      2

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


REDBRICK
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      0,0,0,0,0,0,0,0
        db      127, 127, 127, 127, 127, 127, 127, 0
        db      0,0,0,0,0,0,0,0


        
GREENBRICK
        db      0,0,0,0,0,0,0,0
        db      255, 255, 255, 255, 255, 255, 255, 0
        db      0,0,0,0,0,0,0,0
        db      127, 127, 127, 127, 127, 127, 127, 0
BLUEBRICK        
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

DBGBRICK
        db      1, 1, 1, 1, 1, 1, 1, 1
        db      2, 2, 2, 2, 2, 2, 2, 2
        db      3, 3, 3, 3, 3, 3, 3, 3
        db      4, 4, 4, 4, 4, 4, 4, 4

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

DIGITS  
        db64    Pj5nZ2dnZ2cAAAAAAAAAAB4eHBwcHBwcAAAAAAAAAAA+PnNzcHA+PgAAAAAAAAAAPj5zc3BwPj4A
        db64    AAAAAAAAAD4+Ozs7Ozs7AAAAAAAAAAB/f2dnBwc/PwAAAAAAAAAAPj5nZwcHPz8AAAAAAAAAAH9/
        db64    c3NwcDg4AAAAAAAAAAA+PmdnZ2c+PgAAAAAAAAAAPj5nZ2dnfn4AAAAAAAAAAAAAAAAAAAAAAAAA
        db64    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        db64    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZ2dnZz4+AAAAAAAAAAAAABwcHBwc
        db64    HAAAAAAAAAAAAAADA3Nzf38AAAAAAAAAAAAAcHBzcz4+AAAAAAAAAAAAAH9/ODg4OAAAAAAAAAAA
        db64    AABgYGdnPj4AAAAAAAAAAAAAZ2dnZz4+AAAAAAAAAAAAADg4HBwcHAAAAAAAAAAAAABnZ2dnPj4A
        db64    AAAAAAAAAAAAYGBnZz4+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        db64    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=

; Верхний и нижний ряды у мячика можно срезать и выводить только ШЕСТЬ строк

BALL    db      0, 0, 0, 0, 0, 0, 0, 0
        db      12, 1ah, 39h, 3dh, 1eh, 12, 0, 0
        ds      16

BALLMASK
        db      0b11110011
        db      0b11100001
        db      0b11000000
        db      0b11000000
        db      0b11100001
        db      0b11110011
        db      0b11111111
        db      0b11111111
        
        db      0f3h, 0e1h, 0c0h, 0c0h, 0e1h, 0f3h, 0ffh, 0ffh
        
        db      255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255

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

BONUS16 db      0f0h, 8, 24h, 14h, 54h, 0a4h, 58h, 0f0h
        db      0f0h, 8, 04h, 04h, 44h, 0a4h, 58h, 0f0h
        db      0fh, 10h, 20h, 20h, 25h, 2ah, 15h, 0fh
        db      0fh, 10h, 20h, 20h, 25h, 2ah, 15h, 0fh

; Нет дубины
NOBATTY db      4
        ds      64

; Массив указателей на фазы дубины
BATTYPTRARRAY   dw      BATTYBUF,       BATTYBUF+40h,   BATTYBUF+80h,   BATTYBUF+0c0h
                dw      BATTYBUF+100h,  BATTYBUF+140h,  BATTYBUF+180h,  BATTYBUF+1c0h
; Массив указателей на фазы мячика
BALLPTRARRAY    dw      BALLPHASES,     BALLPHASES+32,  BALLPHASES+64,  BALLPHASES+96
                dw      BALLPHASES+128,  BALLPHASES+160,  BALLPHASES+192,  BALLPHASES+224                



        .org 1300h
; *********************************************************************
; Кирпичики
; 00 - пустое место
; *********************************************************************
PLAYFIELD
LEVEL_1 
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0
        db      82h, 81h,81h,81h,81h,81h,81h,81h,81h,81h,81h,81h,83h, 0, 0, 0
        db      82h, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 5, 5, 0, 0, 81h, 0, 81h, 0, 0, 0,0,83h, 0, 0, 0
        db      82h, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 7, 4, 8, 8, 8, 8, 8, 8, 8, 8, 8, 83h, 0, 0, 0
        db      82h, 8, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 83h, 0, 0, 0
        db      82h, 9, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 83h, 0, 0, 0
        db      82h, 10,10, 5, 5, 5, 5, 5, 5, 5, 5, 5,83h, 0, 0, 0
        db      82h, 11,11,11,11,11,11,11,11,11,11,11,83h, 0, 0, 0
        db      82h, 9, 12, 9, 9, 9, 9, 9, 9, 9, 9, 9,83h, 0, 0, 0
        db      82h, 6, 13, 6, 6, 6, 6, 6, 6, 6, 6, 6,83h, 0, 0, 0
        db      82h, 7, 7, 8, 8, 9, 9, 8, 8, 7, 7, 6, 83h, 0, 0, 0
        db      82h, 9,10,11,12, 9,10,11,12, 9,10,11, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0

        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0        
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0        
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0        
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0

        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0
        db      82h, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83h, 0, 0, 0

LEVEL_1_END

; Типичный уровень - 22 ряда по 11 кирпичей в ряду
LEVEL_2
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
        db      3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        db      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11


; *************************************************
; Распаковать уровень (HL) в игровое поле
; заодно подсчитать количество кирпичей
; *************************************************
UnpackLevel
        xra     a
        sta     BricksToGo
        mvi     c, 22*11
UnpackLevelLoop
        mov     a, m
        ora     a
        jz      ULCont          ; пустое место
        ani     0x80
        jnz     ULCont          ; бетон
        lda     BricksToGo
        inr     a
        sta     BricksToGo
ULCont
        dcr     c
        jnz     UnpackLevelLoop
        ret

LEVELS_END        

        .org    LEVELS_END+100h ;1100h

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
BallX_new       db      0
BallY_new       db      0
BallX_scr       db      0                       ; Старший байт экранного адреса
BallBrickIndex  dw      0                       ; Кирпичная позиция на игровом поле
;BallDelay       db      DEFAULTBALLDELAY        ; Скорость мячика
BallDX          db      0
BallDY          db      0
BallPhase       dw      BALL
BallMaskPhase   dw      BALLMASK

ReflectFlag     db      0
BricksHit       db      0

BattyPos        db      10                      ; Позиция ракетки
BattyDelay      db      DEFAULTBattyDelay       ; Скорость ракетки
BattyDirection  db      0
BattyDistanceToRun      db      0

BmpHeight1      ds      1
BmpHeight2      ds      1


; Псевдослучайность
RNG             db      0
; Обратный отсчет для хаускипера
CountDown       dw      0
; Score - храним в BCD формате, 99 99 99 макс
SCORE3          db      0
SCORE2          db      0
SCORE1          db      0
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

DebugStepMode   db      0       ; 1
DebugPalette    db      0

SoundFX         db      0

; Счетчик ракеток
Batties         db      3

BattyPtr        dw      BATTYBUF

BricksToGo      db      0       ; счетчик кирпичиков в уровне


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
BALLMASKPHASES  equ     BALLPHASES+32*8

MONGOLIA        equ     4000h

BONUSLIST       equ     8000h
