        .project tet.bin

SCROLL_V        equ     0C0h
BANKING         equ     0C1h
SCROLL_VH       equ     0C2h

VIDEO           equ     0E1h

MAP32K          equ     0x01
ENROM           equ     0x10

XY              equ     0005h
SCREEN          equ     0c000h

WARMBOOT        equ     0e003h
KBDSTAT         equ     0e006h
KBDREAD         equ     0e009h
CHAROUT         equ     0e00ch  ; вывести символ из регистра C

Row             equ     CurPos
Col             equ     CurPos+1

CURSYS          equ     0bfedh


CTAKAH_HORIZONTAL_OFFSET        equ     9
CTAKAH_VERTICAL_OFFSET          equ     5
ROWS            equ     20 + 1  ; потому что дно
COLS            equ     10 + 2  ; потому что стенки


        org     1000h


; Чистим экран
        call    ResetScroll
        call    ClearScreen

; Инициализация важных и нужных переменных
        call    InitCTAKAH
        call    InitFigure

        lxi     h, HKCOUNT
        shld    CountDown
        xra     a
        sta     SCORE
        
        call    PaintScore

; пока счет ничейный и все нули давятся, нарисуем искусственный ноль
        lxi     h, SCORE_0
        lxi     b, SCORE_COORDS + 7*2*256
        mvi     a, 3
        call    PaintBitmap


;        lxi     de, 06c0h;      0ffffh      ;       06c0h
;        call    UnpackFigure

        call    DrawCTAKAH
        
        call    PaintPentamino


; Эксперименты с выводом символа без курсора
;        mvi     a, 4
;       sta     0bfech  ; скажем НЕТ курсору
; Вывести справку по командам
        ;call    Help

Begin
        ;call    WorkBitmapPreview



        ; Ввод с клавиатуры
        call    KBDSTAT
        ora     a
        jz     HouseKeeping
        
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

        db      1bh
        dw      WARMBOOT
        db      0
        dw      0

; *******************************************
HKCOUNT equ     4000
HouseKeeping

        call    UpdateRng

        call    TicTac

        lhld    CountDown
        mov     a, l
        ora     h
        jnz     Begin
        lxi     h, HKCOUNT
        shld    CountDown
        jmp     CurDown        

; *******************************************
UpdateRng
        lda     Rng
        inr     a
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
        lhld    FIG_X
        mov     a, l
        ora     a
        jz      Begin
        dcr     l
        call    MoveFigure
        jmp     Begin

CurRight
        lhld    FIG_X
        inr     l
        call    MoveFigure
        jmp     Begin

CurUp
        call    Rotate
        jmp     Begin

MoveFig
        call    MoveFigure
        ora     a
        jnz     WeAreStuck

        jmp     Begin

WeAreStuck
        call    DrawFigure
        call    Annihilate
        call    DrawCTAKAH      ; доооолго
        
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
        lxi     h, XY
        shld    FIG_X

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
        shld    FIG_PTR
        
Same        
        xra     a
        sta     FIG_PHA
        
        call    RenderPhase
        
        ; проверим, есть ли куда ногу поставить
        lhld    FIG_X
        call    IfItFitsISits
        ora     a
        jz      AllGood
        
        pop     a      ; неиспользованный адрес возврата
        jmp     WarmBoot
        
AllGood        
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
        call    SquishRow
        dcr     c
        jnz     Anni

        ret

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
    
        call    PaintScore
        
        pop     hl
        pop     bc
        jmp     SquishRow       ; снова проверим эту же строку
        

SqContinue
        pop     hl
        lxi     bc, -COLS
        dad     b
        pop     bc
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
        call    RenderPhase
; Проверить, помещается ли. Если нет, вернуть предыдущую фазу
        push    hl
        lhld    FIG_X
        call    IfItFitsISits
        pop     hl
        jz      RotateDone
        
        call    PrevPhase
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

RenderPhase
                lda     FIG_PHA
                ral
                mov     c, a
                mvi     b, 0
                
                lhld    FIG_PTR
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
        lxi     hl, CTAKAH_BRICK ; BITMAP1
        ora     a
        jnz     DC0
        lxi     hl, CHECKERS; BITMAP0     ; CHECKERS
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

ErasePentamino0
        push    hl
        lhld    FIG_X
        inr     l
        call    CoordToPtr      ; --- ok

        lda     FIG_X
        inr     a
        inr     a
        mov     b, a
        lda     FIG_Y
        inr     a
        mov     c, a

; К этому моменту в HL указатель на фрагмент стакана,
; а в BC - координаты (COL, ROW)
        
        mvi     d, 4    ; четыре строки в пентамино
EP0
        push    bc
        push    hl
        mvi     e, 4    ; в каждой по четыре клетки
EP
        push    de
        call    DrawCell
        pop     de
        inr     b
        inx     hl
        dcr     e
        jnz     EP
        
        pop     hl
        lxi     b, CTAKAH_COLS
        dad     b
        
        pop     bc
        inr     c
        dcr     d
        jnz     EP0

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
        
DELAY   equ     4000
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

SCORE_COORDS    equ     0208h
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


Help
        lxi     b, 1a00h + 11*8
        lxi     h, ONE
        mvi     a, 3
        call    PaintBitmap

        lxi     b, 1a00h + 12*8+2
        lxi     h, TWO
        mvi     a, 3
        call    PaintBitmap

        lxi     b, 1a00h + 13*8+4
        lxi     h, THREE
        mvi     a, 3
        call    PaintBitmap

        ret

Anime   
        lda     AnimeFrame
        inr     a
        ani     3
        sta     AnimeFrame

        lxi     h, AnimeFrame1
        cpi     1
        jz      AnimeHai
        lxi     h, AnimeFrame2
        cpi     2
        jz      AnimeHai
        lxi     h, AnimeFrame3
AnimeHai
        lxi     b, 0
        call    PaintBitmap
        
        ret

AnimeFrame1     equ     ONE
AnimeFrame2     equ     TWO
AnimeFrame3     equ     THREE


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
; Тетрамино
; *************************************************
;       . . . .         . 1 . .
;       . 1 1 .         . 1 1 .
;       1 1 . .         . . 1 .
;       . . . .         . . . .

FIG_1   db      0b00000110, 0b11000000
        db      0b01000110, 0b00100000
        db      0b00000110, 0b11000000
        db      0b01000110, 0b00100000

FIG_2   db      0b00000110, 0b00110000
        db      0b00100110, 0b01000000
        db      0b00000110, 0b00110000
        db      0b00100110, 0b01000000
        
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


CHECKERS
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
THREE   db      0ffh, 0e3h, 0ddh, 0e7h, 0ffh, 0ddh, 0e3h, 0ffh
        db      1ch, 22h, 18h, 20h, 22h, 1ch, 0, 0

PENTABRICK
        db      7fh, 7fh, 5fh, 5fh, 5fh, 43h, 7fh, 0
        db      0, 1eh, 1eh, 1eh, 1eh, 0, 0, 0

SCORE_0
        db      0, 0xfe, 82h, 0bah, 0aah, 0bah, 082h, 0feh
        db      0, 0xfe, 82h, 0bah, 0feh, 0feh, 0feh, 0feh
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
        


BmpPtr dw      0

; ТЕТРИСОВЫЯ ПЕРЕМЕННЫЯ

; Координаты текущей фигуры
FIG_X   db      4
FIG_Y   db      0

; Указатель на массив фаз фигуры
FIG_PTR dw      FIG_1
; Фаза текущей фигуры (0-3)
FIG_PHA db      0
; Адрес битмапа, которым выводим фигуру (для рисования и стирания)
FIG_BMP dw      PENTABRICK
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

; Буфер для распакованной фигуры 4x4
;       . . . .
;       . . . .
;       . . . .
;       . . . .
FIGBUF  ds      16

; Игровая посуда
CTAKAH  equ     .
        
  
