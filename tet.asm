        .project tet.bin

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

Row             equ     CurPos
Col             equ     CurPos+1

CURSYS          equ     0bfedh
BELL_FREQ       equ     0bff4h
BELL_LEN        equ     0bff6h

CTAKAH_HORIZONTAL_OFFSET        equ     9
CTAKAH_VERTICAL_OFFSET          equ     5
ROWS            equ     20 + 1  ; потому что дно
COLS            equ     10 + 2  ; потому что стенки
SCORE_COORDS    equ     0238h
SCORE_LINE_XY   equ     0600h + 5*8
NEXT_LINE_XY    equ     3400h + 5*8
PREVIEW_COORD   equ     020fh

        org     100h


; Чистим экран
        mvi     a, 43h          ; палитра 3: черный, красный, малиновый, белый
        out     VIDEO
        call    ResetScroll
        call    ClearScreen

        call    PlayTune


; Инициализация важных и нужных переменных
        call    InitCTAKAH
        call    InitFigure

        lxi     h, HKCOUNT
        shld    CountDown
        xra     a
        sta     SCORE

; Надпись "ЩЁТ"
        lxi     b, SCORE_LINE_XY
        lxi     h, SCORE_LINE
        call    PaintHorizontalBitmap

        lxi     b, NEXT_LINE_XY
        lxi     h, NEXT_LINE
        call    PaintHorizontalBitmap

        call    PaintScore

; пока счет ничейный и все нули давятся, нарисуем искусственный ноль
        lxi     h, SCORE_0
        lxi     b, SCORE_COORDS + 7*2*256
        mvi     a, 3
        call    PaintBitmap


;        lxi     de, 06c0h;      0ffffh      ;       06c0h
;        call    UnpackFigure

        call    DrawCTAKAH

; Приглашение к танцу
; заодно добудем семечко для ГСЧ
InitialWait
        lxi     h, XY
        shld    FIG_X
        call    ErasePentamino
        call    Dly
        call    PaintPentamino
        call    Dly

        lda     Rng
        inr     a
        sta     Rng

        call    KBDSTAT
        ora     a
        jz      InitialWait
        call    KBDREAD
        
        lda     Rng
        ora     a
        jnz     Begin
        inr     a
        sta     Rng


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
        
        db      1bh
        dw      WARMBOOT
        db      0
        dw      0

; *******************************************
; Звук

SND_DROP
        push    hl
        lxi     h, 0a000h
        shld    BELL_FREQ
        lxi     h, 0002h
        shld    BELL_LEN
        jmp     BEEP

SND_CLICK
        push    hl
        lxi     h, 0400h
        shld    BELL_FREQ
        lxi     h, 0040h
        shld    BELL_LEN
        jmp     BEEP
        
BEEP    
        pop     hl
        mvi     c, 7
        jmp     CHAROUT
        
;********************************************
; Сыграть ноту
;********************************************
PlayNote
        shld    BELL_FREQ
        xchg
        shld    BELL_LEN
        mvi     c, 7
;        jmp     CHAROUT
        ret


; *******************************************
HKCOUNT equ     4000
HouseKeeping

        ; call    UpdateRng

        call    TicTac

        lhld    CountDown
        mov     a, l
        ora     h
        jnz     Begin
        
        lxi     h, HKCOUNT
        shld    CountDown
        jmp     CurDown        

; *******************************************
; Алгоритм бессовестно попячен тут:
; https://zx-pk.ru/threads/23100-generator-psevdosluchajnykh-chisel.html?p=705136&viewfull=1#post705136
; *******************************************
UpdateRng

        lda     Rng
        mov     b, a 

        rrc     ; multiply by 32
        rrc
        rrc
        xri     0x1f

        add     b
        sbi     255 ; carry

        sta     Rng
        ret


        
        
; *******************************************
TicTac  
        lhld    CountDown
        dcx     h
        shld    CountDown
        ret

; *******************************************

Drop
        call    ErasePentamino
        lhld    FIG_X
DropAgain        
        inr     h
        call    IfItFitsISits
        ora     a
        jz      DropAgain
        dcr     h
        shld    FIG_X
        jmp     WeAreStuck

CurDown
        lhld    FIG_X
        inr     h
        jmp     MoveFig


CurLeft
        lxi     h, C1
        lxi     d, 13
        call    PlayNote


        lhld    FIG_X
        mov     a, l
        ora     a
        jz      Begin
        dcr     l
        call    MoveFigure
        jmp     Begin

CurRight
        lxi     h, E1
        lxi     d, 16
        call    PlayNote

        lhld    FIG_X
        inr     l
        call    MoveFigure
        jmp     Begin

CurUp

        lxi     h, D1
        lxi     d, 14
        call    PlayNote

        call    Rotate
        jmp     Begin

MoveFig
        call    MoveFigure
        ora     a
        jnz     WeAreStuck

        jmp     Begin

WeAreStuck
        lxi     hl, CTAKAH_BRICK
        shld    FIG_BMP
        call    PaintPentamino
        call    DrawFigure

        call    SND_DROP

        call    Annihilate
;        call    DrawCTAKAH      ; доооолго
        
;        call    FastShift
        

        call    InitFigure
        call    PaintPentamino
    
        
        jmp     Begin

MoveFigure
        call    IfItFitsISits
        ora     a
        push    a
        jnz     CantMove
        call    ErasePentamino
        shld    FIG_X
        call    PaintPentamino
CantMove
        pop     a
        ret




InitFigure
        lxi     h, HKCOUNT
        shld    CountDown       ; освежить задержку

        xra     a
        sta     FIG_PHA         ; обнулить фазу фигуры

; Сотрем старое превью
        lhld    NEXTFIG_PTR
        call    RenderPhase
        lxi     h, PREVIEW_COORD
        shld    FIG_X
        lxi     h, BITMAP0
        shld    FIG_BMP
        call    PaintPentamino
        lxi     h, PENTABRICK
        shld    FIG_BMP

; Переложим следующую фигуру в текущую
        lhld    NEXTFIG_PTR
        shld    FIG_PTR
; И получим новую следующую
        lxi     h, FIG_1
        lda     Rng

        ani     7
        cpi     7
        jz      Same
        
        add     a
        add     a
        add     a
        mov     c, a
        mvi     b, 0
        dad     b
        shld    NEXTFIG_PTR
        
Same        

; Вывести превью следующей фигуры
        lhld    NEXTFIG_PTR
        call    RenderPhase
        lxi     h, PREVIEW_COORD
        shld    FIG_X
        call    PaintPentamino
; Нарисовать текущую фигуру
        lxi     h, XY
        shld    FIG_X

        lhld    FIG_PTR
        call    RenderPhase
        
        ; проверим, есть ли куда ногу поставить
        lhld    FIG_X
        call    IfItFitsISits
        ora     a
        jz      AllGood
        
        pop     a      ; неиспользованный адрес возврата
        jmp     WarmBoot
        
AllGood   
        call    UpdateRng
        ret

; *******************************************
; Удалить полностью заполненные строчки
; *******************************************
Annihilate
; Тоже начнем с дна стакана.
; Выходим, как только встретим пустую строку
; Ну или по достижении верха стакана
        lxi     hl, CTAKAH + (ROWS - 2)*COLS + 1    ; донышко не трогаем
        mvi     c, ROWS - 1

Anni
        xra     a
        sta     TuneCount

        call    SquishRow
        dcr     c
        jnz     Anni

        call    PaintScore

        ret

; C - номер проверяемой строки
SquishRow
        push    bc
        push    hl
        
        mvi     b, COLS-2       ; не будем считать стенки
        mvi     c, 0            ; счетчик клеток
        xra     a
SqR
        cmp     m
        jz      SqR1
        inr     c
SqR1
        inx     h
        dcr     b
        jnz     SqR

; Если строка заполнена, сдвигаем содержимое стакана вниз
        mvi     a, COLS-2
        cmp     c
        jnz     SqContinue

; ------  call    SND_CLICK
        push    hl
        lda     TuneCount
        inr     a
        sta     TuneCount
        dcr     a
        ral
        ral
        ral
        mov     c, a
        mvi     b, 0

        lxi     h, DropTune
        dad     b
        call    PT0
        pop     hl
; --------------------

        push    hl
        lxi     bc, -COLS
        dad     b
        pop     de
        lxi     bc, CTAKAH+COLS ; закончим копировать, когда достигнем верхней строки

SqCopy        
        mov     a, m
        stax    d
        dcx     h
        dcx     d
        
        mov     a, e
        cmp     c
        jnz     SqCopy
        mov     a, d
        cmp     b
        jnz     SqCopy

        ; Шай-бу!
        lda     SCORE
        inr     a
        sta     SCORE

        ; Тут бы устроить рекурсию... или перерисовать стакан
    
;        call    PaintScore

;        call    DrawCTAKAH

        
        pop     hl
        pop     bc
        
        call    FastShift


        jmp     SquishRow       ; снова проверим эту же строку
        

SqContinue
        pop     hl
        lxi     bc, -COLS
        dad     b
        pop     bc
        ret

; *******************************************
; Быстрый сдвиг стакана на ряд (8 пикселей) вниз
; C - номер текущей строки
; *******************************************
FastShift
        push    hl
        push    de
        push    bc
        di
        mvi     a, ENROM
        out     BANKING         ; Отключить ПЗУ

; Адрес стакана на экране вообще-то жестко вкомпилен,
; нет нужды его вычислять всякий раз
;CTAKAH_SCREEN_ADDR      equ     SCREEN + (CTAKAH_HORIZONTAL_OFFSET+2)*2*256 + (CTAKAH_VERTICAL_OFFSET+ROWS-1)*8 - 1
CTAKAH_SCREEN_ADDR      equ     SCREEN + (CTAKAH_HORIZONTAL_OFFSET+2)*2*256 + CTAKAH_VERTICAL_OFFSET*8 - 1


        lxi     hl, CTAKAH_SCREEN_ADDR
        lxi     de, CTAKAH_SCREEN_ADDR + 8

 ;       push    bc
        mov     a, c
        ral
        ral
        ral
        mov     c, a
        mvi     b, 0
        dad     b       ; HL = адрес начала экрана + номер рабочей строки*8
        xchg
        dad     b
        xchg
;        pop     bc

FSLoop_
;        push    hl
;        push    de
        
        mvi     b, (COLS-2)*2   
                ; -------------- сдвинуть столбик вниз -------------------------------
                FSLoop0         
                push    hl
                push    de
                push    bc
                ;mvi     c, (ROWS-1)*8   ; <-- а высоту столбика мы уже знаем (в C передан номер рабочей строки)
        
                        FSLoop
                        mov     a, m
                        stax    d
                        dcx     hl
                        dcx     de
                        dcr     c
                        jnz     FSLoop
                
                pop     bc
                pop     de
                pop     hl
                inr     d
                inr     h
                dcr     b
                jnz     FSLoop0
                ; ---------------------------------------------------------------------
                        
 ;       pop     de
  ;      pop     hl

;        call    RestoreTopLine


        xra     a
        out     BANKING         ; Включить ПЗУ
        ei
        pop     bc
        pop     de
        pop     hl
        ret

; *******************************************
; Требуйте долива после отстоя!
; *******************************************
RestoreTopLine

        lxi     hl, CTAKAH_SCREEN_ADDR+9
        mvi     c, (COLS-2)*2
        mvi     a, 0aah
RTL0        
        mvi     b, 8
        push    hl
RTL1
        mov     m, a
        rrc
        inx     hl
        dcr     b
        jnz     RTL1
        
        pop     hl
        inr     h
        dcr     c
        jnz     RTL0
        
        ret


; *******************************************
; Повернуть фигуру
; *******************************************
Rotate
        push    hl
        push    bc
        push    de

        call    ErasePentamino

; Следующая фаза
        call    NextPhase
        lhld    FIG_PTR
        call    RenderPhase
; Проверить, помещается ли. Если нет, вернуть предыдущую фазу
        push    hl
        lhld    FIG_X
        call    IfItFitsISits
        pop     hl
        jz      RotateDone
        
        call    PrevPhase
        lhld    FIG_PTR
        call    RenderPhase

RotateDone        
        call    PaintPentamino
        pop     de
        pop     hl
        pop     bc
        ret

NextPhase
                lda     FIG_PHA
                inr     a
                ani     3
                sta     FIG_PHA
                ret

PrevPhase
                lda     FIG_PHA
                dcr     a
                ani     3
                sta     FIG_PHA
                ret

; В HL указатель на массив фаз фигуры
RenderPhase
                lda     FIG_PHA
                ral
                mov     c, a
                mvi     b, 0
                
;                lhld    FIG_PTR
                dad     b
        
                mov     d, m
                inx     h
                mov     e, m
        
                call    UnpackFigure
                ret

; *******************************************
; Проверить, свободны ли клетки в стакане
; по маске фигуры
; в HL начальные координаты для проверки
; *******************************************
IfItFitsISits
        push    hl
;        inr     l
        call    CoordToPtr
        
        lxi     d, FIGBUF
        mvi     c, 4
loop
        call    CheckFigLine
        ora     a
        jnz     NotFits         ; Не вписывается, расходимся
        dcr     c
        jnz     loop

NotFits
        pop     hl
        ret

; *******************************************
; Вернуть в A не ноль, если строка фигуры не вписывается 
; в строку стакана
; *******************************************
CheckFigLine
        push    bc
        push    hl
        mvi     c, 4
CFL0
        call    CheckFigDot
        ora     a
        jz      CFL
        pop     hl
        pop     bc
        ret

CFL
        inx     de
        inx     hl
        dcr     c
        jnz     CFL0

        pop     hl    
        lxi     b, COLS
        dad     b
    
        pop     bc
        ret

; *******************************************
; Вернуть в A признак доступности точки стакана
; *******************************************
CheckFigDot
        ldax    d       ; проверить точку фигуры
        ora     a
        rz
; Точка фигуры не пустая, проверим точку стакана
        xra     a
        ora     m
        ret

; *******************************************
; Преобразовать координаты фигуры в адрес от начала CTAKAH
;
; Принимаем координаты в HL
; Возвращаем в HL указатель на точку в стакане
; *******************************************
CoordToPtr
        xchg
        
        lxi     h, CTAKAH
        mov     a, d
        lxi     b, COLS
CTP
        ora     a
        jz      CTP1
        dad     b
        dcr     a
        jmp     CTP
CTP1        

        mov     c, e
        mvi     b, 0
        dad     b
        ret
        




; *******************************************
; Сполоснем СТАКАН
; *******************************************
InitCTAKAH
        lxi     hl, CTAKAH
        lxi     bc, COLS*ROWS
Rinse
        mvi     m, 0
        inx     hl
        dcx     bc
        mov     a, b
        ora     c
        jnz     Rinse
        

        lxi     hl, CTAKAH
        lxi     de, COLS - 2
        mvi     c, ROWS
KeepGoin        
        mvi     m, 0ffh
        dad     d
        inx     hl
        mvi     m, 0ffh
        inx     hl
        
        dcr     c
        jnz     KeepGoin

; Нарисуем дно
        lxi     hl, CTAKAH + ROWS*COLS - 1
        mvi     b, CTAKAH_COLS
KG0
        mvi     m, 0ffh
        dcx     hl
        dcr     b
        jnz     KG0
        
        ret



; *******************************************
; Нарисуем СТАКАН
; *******************************************
DrawCTAKAH
        lxi     hl, CTAKAH + ROWS*COLS - 1  ; снизу вверх будем выводить, и справа налево
        mvi     c, ROWS
NextRow
        mvi     b, CTAKAH_COLS
NextCol
        call    DrawCell
        dcx     hl
        dcr     b
        jnz     NextCol

        dcr     c
        jnz     NextRow
     
; Нарисуем верхний ряд пышной пены, чтобы процедуре быстрого сдвига
; было откуда черпать
        mvi     e, 10
        mvi     b, (CTAKAH_HORIZONTAL_OFFSET+2)*2
        mvi     c, CTAKAH_VERTICAL_OFFSET*8
AddTopLine        
        lxi     hl, CHECKERS 
        mvi     a, 3
        call    PaintBitmap
        inr     b
        inr     b
        dcr     e
        jnz     AddTopLine
        ret


; *******************************************
; Вывести клетку стакана
; HL - указатель на текущую клетку в игровой посуде
; BC = COL и ROW
; *******************************************
DrawCell
        push    bc

        mov     a, b
        adi     CTAKAH_HORIZONTAL_OFFSET
        add     a
        mov     b, a
        
        xra     a
        mov     a, c
        adi     CTAKAH_VERTICAL_OFFSET
        ral
        ral
        ral
        mov     c, a

        push    hl
        mov     a, m
        lxi     hl, CHECKERS
        ora     a
        jz     DC0
        lxi     hl, ANOTHER_BRICK
        cpi     0xff
        jz      DC0
        lxi     hl, CTAKAH_BRICK
DC0        
        mvi     a, 3
        call    PaintBitmap
        pop     hl

        pop     bc
        ret

; *******************************************
; Стереть ФИГУРУ
; Проще всего вывести на экран кусок стакана из-под
; прямоугольника фигуры
; *******************************************
ErasePentamino
        push    hl
        lxi     h, CHECKERS
        shld    FIG_BMP
        call    PaintPentamino
        lxi     h, PENTABRICK
        shld    FIG_BMP
        pop     hl
        ret


; *******************************************
; Нарисовать ФИГУРУ
; *******************************************
PaintPentamino

        lda     FIG_X
        adi     CTAKAH_HORIZONTAL_OFFSET
        adi     1
;        adi     2       ; зачем? почему? потому что стенка стакана
        add     a
        mov     b, a            ; X (столбец по горизонтали)
        
        
        lda     FIG_Y
        adi     CTAKAH_VERTICAL_OFFSET
        inr     a       ; а это зачем?
        ral
        ral
        ral
        mov     c, a            ; Y (строка по вертикали)

        
        lxi     hl, FIGBUF
        
        call    PaintPentaLine
        call    PaintPentaLine
        call    PaintPentaLine
        call    PaintPentaLine
        
        ret

PaintPentaLine
        mvi     e, 4
        push    bc
PPL
        mov     a, m
        ora     a
        jz      PPL1
        push    hl
;        lxi     hl, PENTABRICK
        lhld    FIG_BMP
        mvi     a, 3
        call    PaintBitmap
        pop     hl
PPL1    
        inx     hl
        inr     b
        inr     b
        dcr     e
        jnz     PPL
        
;        inx     hl
        pop     bc
        mvi     a, 8
        add     c
        mov     c, a
        
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
        push    hl
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
PSLoop
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
        jnz     PSLoop
PSDone        
        pop     bc
        pop     de
        pop     hl
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

CTAKAH_COLS     equ     COLS

; *************************************************
; Вклеить фигуру из рабочего буфера в стакан
; 
; Должна вызываться один-единственный раз, когда фигура
; уже не может дальше двигаться и должна прирасти к стакану
;
; *************************************************
DrawFigure
        lxi     hl, CTAKAH      ; буфер стакана
        ; Добавить к указателю стакана координаты фигуры
        lda     FIG_Y
        lxi     d, CTAKAH_COLS
DF0        
        ora     a
        jz     DF1
        dad     d
        dcr     a
        jmp     DF0
        
DF1
        lda     FIG_X           ; добавить смещение по строке
        mov     c, a
        mvi     b, 0
        dad     bc
        
        lxi     de, FIGBUF      ; буфер фигуры
        
        call    DrawFigLine
        call    DrawFigLine
        call    DrawFigLine
        call    DrawFigLine
        
        ret

DrawFigLine
        push    hl
        mvi     c, 4
DFL
        ldax    d
        ora     a
        jz      DFL1
        mov     m, a
DFL1        
        inx     d
        inx     h
        dcr     c
        jnz     DFL
        pop     hl
        lxi     b, CTAKAH_COLS   ; перейти к следующей строке стакана
        dad     b
        ret

; *************************************************
; Распаковать фигуру из DE в рабочий буфер
; *************************************************
UnpackFigure
        lxi     hl, FIGBUF
        mov     a, d
        call    UnpackFigHalf
        mov     a, e
        call    UnpackFigHalf
        ret

UnpackFigHalf
        mvi     c, 8
UnFH
        ral
        push    a
        mvi     a, 1
        jc      .+4
        xra     a
        mov     m, a
        inx     h
        
        pop     a
        dcr     c
        jnz     UnFH
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
; Нотки
; *************************************************
A1      equ     0d51h
H1      equ     0bdch       
C1      equ     0b34h
D1      equ     9fbh
E1      equ     8e4h
F1      equ     864h
G1      equ     779h
A2      equ     A1/2    ;6a8h
H2      equ     H1/2
C2      equ     C1/2
D2      equ     D1/2
E2      equ     E1/2
F2      equ     F1/2
G2      equ     G1/2
A3      equ     A2/2
H3      equ     H2/3
C3      equ     C2/2
Pause   equ     4bh
; Длительности
; A1 H1 C1 D1 E1 F1 G1 A2
; 11 12 13 14 16 17 19 22
; Pause = 2*250

Notes
        dw      Pause
        db      250
        dw      A1
        db      11
        dw      H1
        db      12
        dw      C1
        db      13
        dw      D1
        db      14
        dw      E1
        db      16
        dw      F1
        db      17
        dw      G1
        db      19
        dw      A2
        db      22
        dw      H2
        db      24
        dw      C2
        db      26
        dw      D2
        db      28
        dw      E2
        db      32
        dw      F2
        db      34
        dw      G2
        db      38
        dw      A3
        db      44
        dw      H3
        db      48
        dw      C3
        db      52



;**************************************************
; Номер ноты в аккуме
;**************************************************
PlayNote1
        push    hl
        push    de
        push    bc
        lxi     hl, Notes
        ; умножим номер ноты на 3
        mov     b, a
        add     a
        add     b
        mov     c, a
        mvi     b, 0
        dad     b
        
        ; Добудем делитель
        mov     e, m
        inx     h
        mov     d, m
        inx     h
        ; и длительность
        mov     l, m
        mvi     h, 0
        shld    BELL_LEN
        xchg
        shld    BELL_FREQ
        mvi     c, 7
        call    CHAROUT
        pop     bc
        pop     de
        pop     hl
        ret

; *************************************************
; Тюнз
; *************************************************
Tune    db      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255

DropTune
        db      3, 0, 5, 0, 7, 255, 0, 0
        db      5, 0, 7, 0, 10, 255, 0, 0
        db      7, 0, 10, 0, 12, 255, 0, 0
        db      10, 0, 12, 0, 14, 255, 0, 0

PlayTune
        lxi     h, Tune
PT0        
        mov     a, m
        cpi     255
        jz      ThatsAllFolks
        call    PlayNote1
        inx     h
        jmp     PT0
ThatsAllFolks        
        ret


; *************************************************
; Тетрамино
; *************************************************
;       . . . .         . 1 . .
;       . 1 1 .         . 1 1 .
;       1 1 . .         . . 1 .
;       . . . .         . . . .

FIG_1   db      0b11000110, 0b00000000
        db      0b01001100, 0b10000000
        db      0b11000110, 0b00000000
        db      0b01001100, 0b10000000

FIG_2   db      0b01101100, 0b00000000
        db      0b10001100, 0b01000000
        db      0b01101100, 0b00000000
        db      0b10001100, 0b01000000

FIG_3   db      0b00001111, 0b00000000  ; Палка
        db      0b01000100, 0b01000100
        db      0b00001111, 0b00000000
        db      0b01000100, 0b01000100

FIG_4   db      0b01001110, 0b00000000
        db      0b01001100, 0b01000000
        db      0b00001110, 0b01000000
        db      0b01000110, 0b01000000
        
FIG_5   db      0b01100110, 0b00000000  ; Кубик
        db      0b01100110, 0b00000000
        db      0b01100110, 0b00000000
        db      0b01100110, 0b00000000

FIG_6   db      0b10001110, 0b00000000
        db      0b01000100, 0b11000000
        db      0b00001110, 0b00100000
        db      0b01100100, 0b01000000

FIG_7   db      0b00101110, 0b00000000
        db      0b11000100, 0b01000000
        db      0b11101000, 0b00000000
        db      0b01000100, 0b01100000

; *************************************************
; Битмапчики
; *************************************************

BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
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
SCORE_0
        db      0, 0xfe, 82h, 0bah, 0aah, 0bah, 082h, 07eh
        db      0, 0xfe, 82h, 0bah, 0feh, 0feh, 0feh, 07eh
SCORE_1
        db      0, 3ch, 24h, 2ch, 28h, 0eeh, 82h, 0feh
        db      0, 3ch, 24h, 2ch, 38h, 0feh, 0feh, 0feh

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

BALL    db      4eh, 0c7h, 8bh, 0c5h, 83h, 0c0h, 0abh, 7eh
        db      34h, 17h, 2bh, 15h, 2bh, 15h, 0, 0

WALL    db      0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0
        db      9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9, 9
        db      0, 9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 9, 6, 9, 7, 9, 8, 9
        db      0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8
        db      0ffh, 0ffh
        


BmpPtr dw      0

; ТЕТРИСОВЫЯ ПЕРЕМЕННЫЯ

; Координаты текущей фигуры
FIG_X   db      4
FIG_Y   db      0

; Указатель на массив фаз фигуры
FIG_PTR         dw      FIG_1
; Указатель на следующую фигуру
NEXTFIG_PTR     dw      FIG_1
; Фаза текущей фигуры (0-3)
FIG_PHA         db      0
; Адрес битмапа, которым выводим фигуру (для рисования и стирания)
FIG_BMP         dw      PENTABRICK
; Псевдослучайность
RNG     db      0
; Обратный отсчет для хаускипера
CountDown       dw      0
; Score   (.)(.)
SCORE   db      0
; Регистров вечно не хватает, а давить ведущие нули в счете хочется
SuppressLeadingZeroes   db      0
; Патч для KDE под FreeBSD
AnimeFrame      ds      1
; Палитра
FGCOLOR         db      3
BGCOLOR         db      0
; Градус тюнза
TuneCount       db      0
; Буфер для распакованной фигуры 4x4
;       . . . .
;       . . . .
;       . . . .
;       . . . .
FIGBUF  ds      16

; Игровая посуда
CTAKAH  equ     .
        
  
