
        .project graf.bin


#define DBG_START(color)      mvi a, color \ out VIDEO
#define DBG_STOP              mvi a, 40h \ out VIDEO

SCROLL_V        equ     0C0h
BANKING         equ     0C1h
SCROLL_VH       equ     0C2h

VIDEO           equ     0E1h

MAP32K          equ     0x01
ENROM           equ     0x10

ESC             equ     27
CR              equ     13

WALL_OFFSET_HORIZ       equ     4       ; in bytes
WALL_OFFSET_VERT        equ     4*8       ; in pixels


XY              equ     0628h   ; WALL_OFFSET_HORIZ + 256*WALL_OFFSET_VERT        ;0208h

MARGIN_BOT      equ     8*8 + WALL_OFFSET_VERT
MARGIN_LEFT     equ     WALL_OFFSET_HORIZ + 2
MARGIN_RIGHT    equ     WALL_OFFSET_HORIZ + 2 + 8
MARGIN_TOP      equ     8 + WALL_OFFSET_VERT

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CP/M 2 BDOS Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
C_READ   	EQU	1
C_WRITE   	EQU	2
C_RAWIO         EQU     6       ; Entered with C=6, E=FF. Returned values (in A) vary.
C_WRITESTR   	EQU	9
C_STAT   	EQU	11	;CONSOLE STAT
F_OPEN    	EQU	15	;0FFH=NOT FOUND
F_CLOSE   	EQU	16	;   "	"
F_SFIRST        EQU	17	;   "	"
SRCHN	        EQU	18	;   "	"
F_DELETE        EQU	19	        ;NO RET CODE
F_READ	        EQU	20	        ;0=OK, 1=EOF
F_WRITE	        EQU	21	        ;0=OK, 1=ERR, 2=?, 0FFH=NO DIR SPC
F_MAKE	        EQU	22	        ;0FFH=BAD
REN	        EQU	23	        ;0FFH=BAD
F_DMAOFF        EQU	26
BDOS	        EQU	5
REIPL   	EQU	0
FCB     	EQU	5CH	        ;DEFAULT FCB
PARAM1  	EQU	FCB+1	        ;COMMAND LINE PARAMETER 1 IN FCB
PARAM2  	EQU	PARAM1+16	;COMMAND LINE PARAMETER 2
DMA             equ     80h
COMTAIL         EQU     80h



        org     100h

; Демонстративно разместим битмапчики в начале файла

        jmp     Start
        ds      13      ; выравняем до 16 байт

; Pictograms
BMP_ESC db      07ch, 80h, 80h, 0, 80h, 81h, 81h, 3eh
        db      3, 1, 1bh, 0c9h, 5bh, 50h, 58h, 0c0h
BMP_Z   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 1ch, 10h, 8, 4, 1ch, 0, 0
BMP_0   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 8, 14h, 14h, 14h, 8, 0, 0
BMP_1   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 8, 0ch, 8, 8, 1ch, 0, 0
BMP_2   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 0ch, 10h, 0ch, 4, 1ch, 0, 0
BMP_3   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 0ch, 10h, 0ch, 10h, 0ch, 0, 0
BMP_G   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 1ch, 4, 14h, 14h, 1ch, 0, 0
BMP_C   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 1ch, 4, 4, 4, 1ch, 0, 0
BMP_P   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
        db      0, 1ch, 14h, 1ch, 4, 4, 0, 0
        
BMP_BLOB        db      0, 03ch, 72h, 7ah, 7eh, 7eh, 3ch, 0
                db      0, 03ch, 72h, 7ah, 7eh, 7eh, 3ch, 0

BMP_BLOB_INV    db      0ffh, 0c3h, 8dh, 85h, 81h, 81h, 0c3h, 0ffh
                db      0, 0, 0, 0, 0, 0, 0, 0

MANNEKIN        db      0, 10h, 0, 0, 0, 0, 0, 0
                db      0, 0, 4ch, 3ah, 8, 34h, 22h, 0



Start
; Инициализация важных и нужных переменных
        lxi     h, XY
        shld    CurPos
        lxi     h, WORKBMP
        shld    BmpPtr

; Режим экрана
        ; lxi     d, ColorMode
        ; call    Print

        mvi     a, 40h
        out     VIDEO

; Дисковые дела
        lda     COMTAIL
        ora     a
        jz      NoParam         ; если запуск без параметров, используем дефолтное имя SCRATCH.PAD
        call    FileLoad
        jmp     DiskDone
NoParam
        lxi     h, DefaultFN        
        lxi     d, FCB
        mvi     c, 12
NPLoop
        mov     a, m
        stax    d
        inx     h
        inx     d
        dcr     c
        jnz     NPLoop
        
DiskDone

; Чистим экран и рисуем нетленку
        call    ClearScreen
        call    ResetScroll
        call    BuildTheWall
        ; call    DrawPalette
        call    UnpackWorkBitmap
        
;        call    GoFigure

; Своя графониевая печать

        call    MirrorFont      ; вот что лень-матушка делает

        mvi     a, 3
        sta     PrintColor
        
; выведем имя файла
        lxi     h, FCB+1 
        lxi     b, 2018h
        mvi     e, 8
        call    _PrintStrN

        mvi     a, '.'
        call    _PrintChar

        lxi     h, FCB+9
        ; lxi     b, 0000h
        mvi     e, 3
        call    _PrintStrN

        mvi     a, 1
        sta     PrintColor

        lxi     h, Version
        lxi     b, 0000h
        call    _PrintStr

        lxi     h, Copyright
        lxi     b, 2800h
        call    _PrintStr
        
        ; lxi     h, Mannekin
        ; lxi     b, 3000h
        ; mvi     a, 3
        ; call    PaintBitmap


        ; mvi     a, 2
        ; sta     PrintColor


        ; lxi     b, 00008h
        ; mvi     a, 0abh
        ; call    _PrintHex


; Вывести справку по командам
        call    Help

; Забавные прерывания!
        call    SetupTimerInterrupt

        call    WorkBitmapPreview

        call    PaintCursor

; ********************************************************************
; Main loop
; ********************************************************************
Begin
; Sync to retrace
        ; call    SyncToRetrace

        call    BlinkCursor

        call    ReadHourGlass
        ani     80h              ; restart timer every 21 milliseconds
        jnz     CheckKeyboard

; Restart timer        
        xra     a
        out     60h
; Do periodic tasks just before incrementing Ticks counter
        call    OnEveryTick
; Increment ticks        
        lda     Ticks
        inr     a
        sta     Ticks


; Ввод с клавиатуры
CheckKeyboard
        mvi     c, C_STAT
        call    BDOS
        ora     a
        jz      Nothing

; Key pressed
        ; call    WorkBitmapPreview
        ; call    EraseCursor

        mvi     e, 255
        mvi     c, C_RAWIO
        call    BDOS
        jmp     Cont
        
Nothing
;        call    BlinkCursor
Cont

        

; Большие или малые буквы, это все равно
        cpi     0x5f
        jc      Next0
        sui     0x20
Next0

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

        db      0ch
        dw      CenterBitmap

        db      18h
        dw      CurRight
        db      19h
        dw      CurUp
        db      1ah
        dw      CurDown
       
        db      09h
        dw      Switch
        
        db      31h
        dw      ColorOne
        db      32h
        dw      ColorTwo
        db      33h
        dw      BothColors
        db      30h
        dw      NoColors
        db      'G'
        dw      Grid
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

        db      'A'
        dw      JumpPlus256
        db      'Q'
        dw      JumpMinus256
        
        db      1bh
        dw      Quit

        db      CR
        dw      CenterBitmap

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
; Управление сеткой
; *************************************************
Grid
        lda     GridType
        inr     a
        ani     3
        sta     GridType
        jmp     RedrawWorkBitmap

; *************************************************
; *************************************************
CenterBitmap
        lxi     h, WORKBMP
        shld    BmpPtr
        jmp     RedrawWorkBitmap


; *************************************************
; Клипборд
; *************************************************
CLIP_X  equ     13      ; координата X положения клипборда по горизонтали
CLIP_Y  equ     3       ; координата Y по вертикали
CLIP_XY equ     ((CLIP_X * 2) << 8) + CLIP_Y * 8

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
        lxi     b, CLIP_XY      ;1800h + 5*8  ; TODO use defines
        mvi     a, 3
        call    PaintBitmap
        
        jmp     RedrawWorkBitmap
Paste
        lhld    BmpPtr
        lxi     d, CLIPBOARD
        xchg
        jmp     CL0

JumpPlus256
        lxi     d, 128  ; 256
        jmp     SNB
        
JumpMinus256
        lxi     d, -128 ; -256
        jmp     SNB

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

; тут вроде бы уместно вывести hex dump

        ; call    HexDump

        jmp     Paint

; ***********************************
; Hex Dump
; Вывести содержимое редактируемого спрайта
; в два столбика
; ***********************************
HEXDUMP_LINE    equ     5
HEXDUMP_COL     equ     13
HexDump
        push    a
        push    bc
        push    de
        push    hl

        mvi     a, 2
        sta     PrintColor

        lhld    BmpPtr
        lxi     b, (HEXDUMP_COL*2 << 8) + (HEXDUMP_LINE*8)
        call    PrintHexColumn
        
        ; lhld    BmpPtr+8
        ; HL естественным путем увеличится на 8 к этому моменту
        lxi     b, ((HEXDUMP_COL+3)*2 << 8) + (HEXDUMP_LINE*8)
        call    PrintHexColumn

        pop     hl
        pop     de
        pop     bc
        pop     a

        ret

PrintHexColumn
        mvi     e, 8
PHC
        mov     a, m
        push    b
        call    _PrintHex
        pop     b

        mov     a, c
        adi     8
        mov     c, a
        
        ; mvi     a, HEXDUMP_COL*2
        mov     a, b
        aci     0
        mov     b, a

        inx     h
        dcr     e
        jnz     PHC
        ret


; ***********************************
; Switch between ??? with Tab key
; ***********************************
Switch
        lda     Tab
        inr     a
        ani     7
        sta     Tab

        ; lxi     hl, 0
        ; lxi     de, 2020h
        ; call    DrawLine

        lxi     hl, 2020h
        lxi     de, 2040h
        call    DrawLine

        lxi     hl, 2040h
        lxi     de, 4040h
        call    DrawLine

        lxi     hl, 4040h
        lxi     de, 4020h
        call    DrawLine

        lxi     hl, 4020h
        lxi     de, 2020h
        call    DrawLine

        jmp     Begin

; ***********************************
; Zap current block
; ***********************************
Zap     lhld    BmpPtr
        mvi     c, 16
Loo     mvi     m, 0
        inx     h
        dcr     c
        jnz     Loo

        lxi     h, XY
        shld    CurPos
        
        call    UnpackWorkBitmap 
        
        jmp     Paint

CycleForeColor
        lda     FORECOLOR
        inr     a
        ani     7
        sta     FORECOLOR
        jmp     WriteToVideoPort

CycleBackColor
        lda     BACKCOLOR
        adi     8
        ani     38h
        sta     BACKCOLOR

WriteToVideoPort
        lda     FORECOLOR
        ani     7
        mov     b, a
        
        lda     BACKCOLOR
        ani     38h
        ora     b
        
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
        jmp     Paint

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
        lda     Row                                             // 28h = 40
;        sui     8       ; опять оффсеты
        sui     WALL_OFFSET_VERT+8
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
;        sui     2               ; отнять смещение (TODO: оформить все эти оффсеты как-то официально)
        sui WALL_OFFSET_HORIZ+2
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

        
CurDown 
        call    EraseCursor

        lda     Row
        cpi     MARGIN_BOT
        jz      Paint
        adi     8
        sta     Row
        jmp     Paint
CurLeft
        call    EraseCursor

        lda     Col
        cpi     MARGIN_LEFT
        jz      Paint
        sbi     2
        sta     Col
        jmp     Paint
CurRight
        call    EraseCursor

        lda     Col
        cpi     MARGIN_RIGHT + 6        ; why 6 ???
        jz      Paint
        adi     2
        sta     Col
        jmp     Paint
CurUp
        call    EraseCursor

        lda     Row
        cpi     MARGIN_TOP
        jz      Paint
        sbi     8
        sta     Row
        jmp     Paint
        

; Рисуем
Paint
        call    WorkBitmapPreview

        jmp     Begin

; *************************************************
; BlinkCursor
; *************************************************
BlinkCursor

        lxi     h, Blink
        mov     b, m            ; Blink
        inx     h
        mov     a, m            ; prev Blink
        xra     b               ; are they the same?
        rz                      ; yes

        mov     m, b            ; save Blink to prev Blink
        
        lda     Blink
        ora     a
        jnz     Show
        call    EraseCursor
        ret
Show    call    PaintCursor
        ret

; *************************************************
; PaintCursor
; *************************************************
PaintCursor

                ; DBG_START(41h)

        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, CURSOR_BITMAP
        mvi     a, 3
        call    PaintBitmap

                ; DBG_STOP

        ret

; *************************************************
; Вывести вместо курсора картинку, соответствующую 
; точке из рабочего битмапа
; *************************************************
EraseCursor

                ; DBG_START(46)

        mvi     a, 0
        call    PlaceDot

        lda     Row             ; строка (координата Y)          28h = 40 (5 blocks)
        sui     WALL_OFFSET_VERT+8               ; отнять смещение
        rar
        rar
        rar                     ; и поделить на 8
        ani     7
        mov     e, a
        mvi     d, 0
        lhld    BmpPtr
        dad     d               ; hl = WORKBMP + строка

; Адрес нужного байта добыли, займемся номером бита        
        lda     Col             ; координата X                  06
        sui     WALL_OFFSET_HORIZ+2
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

                ; DBG_STOP

        ret

; *************************************************
; Точку рисуем
; В аккумуляторе номер плоскости 00, 01, 10 или 11
; *************************************************
PlaceDot
        push    a
; Wipe first
        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, GRID_NONE
        mvi     a, 3
        call    PaintBitmap
        
        pop     a
        push    a

        lhld    CurPos
        mov     c, l
        mov     b, h
        lxi     h, FILLEDBLOCK
        ora     a
        jnz     PDT

; Особый случай - 00 для очистки обоих планов
; Apply grid type
        lda     GridType

        lxi     h, GRID_DOTS
        cpi     1
        jz      PDT0
        
        lxi     h, GRID_LINES
        cpi     2
        jz      PDT0

        lxi     h, GRID_GRID
        cpi     3
        jz      PDT0

        lxi     h, GRID_NONE
PDT0
        mvi     a, 3
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
        cpi     MARGIN_RIGHT + 8        ; why 4 ???
        jz      Wow1
        sta     Col
        jmp     Wow0

Wow1
        ;call    Dly
        mvi     a, MARGIN_LEFT
        sta     Col
        lda     Row
        adi     8
        cpi     MARGIN_BOT + 8
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
        push    hl
        
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
        
        pop     hl
        pop     de
        pop     bc
        ei
        ret

; *************************************************
; Copy 8 bytes from DE to HL
; *************************************************
Copy8
        push    h
        push    d
        push    b
        push    a
     
        mvi     c, 8
C8Loop  ldax    d
        mov     m, a
        inx     d
        inx     h
        dcr     c
        jnz     C8Loop
     
        pop     a
        pop     b
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

        ; mvi     a, 1fh
        ; mvi     c, C_WRITE
        ; jmp    BDOS

; *************************************************
; Графические функцыи
;
; DrawLine - нарисовать линию
; HL = координаты начала Y1X1, DE = координаты конца Y2X2
; *************************************************
DrawLine
        mvi     a, '2'
DrawCommon
        sta     ESC_COMMAND
        shld    ESC_PARAM1
        xchg
        shld    ESC_PARAM3
        lxi     d, ESC_SEQUENCE
        jmp     Print

; TODO move working RAM area to the end of program
ESC_SEQUENCE    db      ESC
ESC_COMMAND     db      '2'
ESC_PARAM1      db      0
ESC_PARAM2      db      0
ESC_PARAM3      db      0
ESC_PARAM4      db      0
                db      '$'

; *************************************************
; DrawFilledRectangle - нарисовать прямоугольник с заливкой
; HL = координаты начала Y1X1, DE = координаты конца Y2X2
; *************************************************
DrawFilledRectangle
        mvi     a, '1'
        jmp     DrawCommon

; *************************************************
; DrawRectangle - нарисовать прямоугольник
; HL = координаты начала Y1X1, DE = координаты конца Y2X2
; *************************************************
DrawRectangle
        ; push    de
        ; mov     d, h
        ; call    DrawLine
        ; pop     de
        
        ; push    de
        ; mov     e, l
        ; call    DrawLine
        ; pop     de
        
        ; push    hl
        ; mov     h, d
        ; call    DrawLine
        ; pop     hl

        ; push    hl
        ; mov     l, e
        ; call    DrawLine
        ; pop     hl
        
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
        
; add vertical offset
        adi     WALL_OFFSET_VERT
        mov     c, a
        
        inx     h
        mov     a, m
        ral
        
; add horizontal offset
        adi     WALL_OFFSET_HORIZ
        
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
; Нарисовать блок 8х8 пикселей в полноцвете
; HL - адрес битмапа (?)
; DE - смещение относительно центрального блока (??)
; *************************************************
PaintBlock
        push    h
        push    d
        lhld    BmpPtr
        dad     d
        mvi     a, 3
        call    PaintBitmap
        pop     d
        pop     h
        ret

; *************************************************
; Визуализировать ряд из N битмапов
; BC = начальные координаты
; *************************************************
PaintNBlocks
        push    hl
        push    de
        push    bc
        mvi     l, 8    ; положим N=8
        ; lxi     d, 0
PNBLoop

        call    PaintBlock

; движемся вправо по памяти
        mov     a, e
        adi     16
        mov     e, a
        mov     a, d
        aci     0
        mov     d, a

; движемся вправо по экрану
        inr     b
        inr     b

; счетчик цикла
        dcr     l
        jnz     PNBLoop
        
        pop     bc
        pop     de
        pop     hl
        ret
        
; *************************************************
; Показать рабочий битмап в натуральную величину
; *************************************************
PREVIEW_X       equ     20
PREVIEW_Y       equ     5
PREVIEW_XY      equ     PREVIEW_X*512 + PREVIEW_Y*8

WorkBitmapPreview

        call    HexDump


        lxi     b, PREVIEW_XY
        lxi     d, 0
        mvi     l, 8
WBPLoop
        call    PaintNBlocks
        
        mov     a, c
        adi     8
        mov     c, a

;        inr     d
; скачем секторами по 128 байт
        push    hl
        lxi     hl, 128
        dad     d
        xchg
        pop     hl

        dcr     l
        jnz     WBPLoop

; Нарисуем красивую полосочку сверху        

PREVIEW_HORIZ           equ     16      ; in 8x8 pixel blocks
PREVIEW_VERT            equ     4       ; in 8x8 pixel blocks
PREVIEW_HORIZ_PIXELS    equ     PREVIEW_HORIZ * 8
PREVIEW_VERT_PIXELS     equ     255-(PREVIEW_VERT * 8)  // 0.0 is in left bottom corner
PREVIEW_LINE_LEN        equ     8
PREVIEW_LINE_LEN_PIXELS equ     PREVIEW_LINE_LEN * 8

PREVIEW_BOT_LINE_Y      equ     PREVIEW_VERT_PIXELS-(10*8)

;         lxi     hl, (PREVIEW_VERT_PIXELS << 8) + (PREVIEW_HORIZ_PIXELS)
;         lxi     de, (PREVIEW_VERT_PIXELS << 8) + (PREVIEW_HORIZ_PIXELS + PREVIEW_LINE_LEN_PIXELS)
;         call    DrawLine

; ; И снизу        

;         lxi     hl, (PREVIEW_BOT_LINE_Y << 8) + PREVIEW_HORIZ_PIXELS
;         lxi     de, (PREVIEW_BOT_LINE_Y << 8) + (PREVIEW_HORIZ_PIXELS + PREVIEW_LINE_LEN_PIXELS)
;         call    DrawLine

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

        ret

; GoFigure
;         lxi     b, 1600h + 11*8
;         lxi     h, BALL
;         mvi     a, 3
;         call    PaintBitmap

;         lxi     b, 1800h + 11*8
;         lxi     h, BALL
;         mvi     a, 3
;         call    PaintBitmap
        
;         lxi     b, 1800h + 10*8
;         lxi     h, BALL
;         mvi     a, 3
;         call    PaintBitmap

;         lxi     b, 1a00h + 11*8
;         lxi     h, BALL
;         mvi     a, 3
;         call    PaintBitmap

;         ret

; *************************************************
; HELP
; *************************************************
HelpX   equ     0       ; 1ah
HelpY   equ     16
HelpXY  equ     (HelpX<<8) + HelpY*8

Help

        mvi     a, 3
        sta     PrintColor
        
        lxi     b, HelpXY
        lxi     h, HelpText
        call    _PrintStr        

; нарисуем иконки

        call    PaintIconsFromList

        ret

; ************************************************
; Нарисуем битмапчики из списка
; Формат списка: битмапчик1, координаты1, color1, ..., 0
; ************************************************
PaintIconsFromList
        lxi     h, IconList
PIFLoop
        mov     e, m    ; адрес битмапчика
        inx     h
        mov     d, m
        inx     h
        
        mov     c, m    ; координаты битмапчика
        inx     h
        mov     b, m
        inx     h
        
        mov     a, d    ; если конец списка,
        ora     e       ; закончим работу
        rz
        
        mov     a, m    ; цвет
        inx     h
        
        xchg
        call    PaintBitmap
        xchg
        jmp     PIFLoop

IconList
        dw Mannekin     \ db 0, 30h, 3
        dw BMP_1        \ db (HelpY + 2)*8, HelpX + 32, 3
        dw BMP_BLOB     \ db (HelpY + 1)*8, HelpX + 32, 1
        dw BMP_2        \ db (HelpY + 2)*8, HelpX + 36, 3
        dw BMP_BLOB     \ db (HelpY + 1)*8, HelpX + 36, 2
        dw BMP_3        \ db (HelpY + 2)*8, HelpX + 40, 3
        dw BMP_BLOB     \ db (HelpY + 1)*8, HelpX + 40, 3
        dw BMP_0        \ db (HelpY + 2)*8, HelpX + 44, 3
        dw BMP_BLOB_INV \ db (HelpY + 1)*8, HelpX + 44, 3
        dw BMP_G        \ db (HelpY + 3)*8, HelpX + 32, 3
        dw BMP_C        \ db (HelpY + 4)*8, HelpX + 32, 3
        dw BMP_P        \ db (HelpY + 5)*8, HelpX + 32, 3
        dw BMP_Z        \ db (HelpY + 6)*8, HelpX + 32, 3
        dw BMP_ESC      \ db (HelpY + 8)*8, HelpX + 32, 3

        dw 0


HelpText
        db      'KEYS', CR, '------------', CR
        db      'SELECT COLOR', CR
        db      'GRID', CR
        db      'COPY', CR, 'PASTE', CR
        db      'ZAP', CR, CR
        db      'EXIT'
        db      0

; *************************************************
; Закончить работу
; *************************************************
Quit
        lxi     de, SaveYN
        call    Print

QuitLoop
        call    KBDREAD
        cpi     1bh
        jz      Begin
        
        ani     ~00100000b
        cpi     'N'
        jz      QuitQuit
        cpi     'Y'
        jnz     QuitLoop
        
        call    FileSave
QuitQuit        
        rst     0




; *************************************************
; Вывести символ С по адресу HL
; *************************************************
MYCHAROUT
        shld    CURSYS  ; координаты текстового курсора
        call    CHAROUT
        ret

; *************************************************
; Позиционировать курсор
; HL - координаты курсора (H= , L= )
; *************************************************
; PositionCursor
;         shld    SetCursorPosRow
;         lxi     d, SetCursorPosition
;         jmp     Print

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

; *************************************************
; Вывести строку в формате BDOS
; DE - адрес строки с $ в конце
; *************************************************

Print
        mvi    c, C_WRITESTR
        jmp    BDOS


; *************************************************
; Find file
; Z if not found
; *************************************************
FileFind
        lxi     d, FCB
        mvi     c, F_SFIRST
        call    BDOS
        inr     a
        ret

; *************************************************
; Delete existing file
; *************************************************
EraseOldFile
        call    FileFind
        rz

        LXI	D,FCB
	MVI	C,F_DELETE
	CALL	BDOS
	RET

; *************************************************
; Open file
; *************************************************
FileOpen
        lxi     d, FCB
        mvi     c, F_OPEN
        call    BDOS            ; On return, A is 0FFh for error, or 0-3 for success
        inr     a
        ret


; *************************************************
; Close file
; *************************************************
FileClose
        lxi     d, FCB
        mvi     c, F_CLOSE
        call    BDOS
        ret

; *************************************************
; Reset DMA address
; *************************************************
ResetDMA
        lxi     d, DMA
        jmp SetDMA1

; *************************************************
; Set DMA address
; *************************************************
SetDMA
        lxi     d, WORKBMP
SetDMA1
        mvi     c, F_DMAOFF
        call    BDOS
        ret        

; *************************************************
; Load file
; *************************************************
FileLoad
        ;call    ResetDMA

        ; call    FileFind
        ; rz
        
        call    FileOpen
        rz
        
        call    SetDMA
        
        mvi     c, 8            ; sector count
        lxi     d, WORKBMP
LoadSectorLoop
        push    bc
        push    de
        
        mvi     c, F_DMAOFF
        call    BDOS

        lxi     d, FCB
        mvi     c, F_READ
        call    BDOS

; следующие 128 байт
        pop     hl
        lxi     b, 128
        dad     b
        xchg

        pop     bc
        dcr     c
        jnz     LoadSectorLoop

        call    ResetDMA

        call    FileClose
        
        ret

; *************************************************
; Save file
; *************************************************
FileSave
        ; call    ResetDMA

        call    EraseOldFile
        
; for some reason, we need to clean FCB after deletion
        call    ClearFCB
        
; create new file
        lxi     d, FCB
        mvi     c, F_MAKE
        call    BDOS            ; Returns A=0FFh if the directory is full
        inr     a
        rz

        call    FileOpen
        rz

        call    SetDMA
        
        mvi     c, 8            ; sector count
        lxi     d, WORKBMP
SaveSectorLoop        
        push    bc
        push    de

        mvi     c, F_DMAOFF
        call    BDOS

        lxi     d, FCB
        mvi     c, F_WRITE
        call    BDOS

; следующие 128 байт
        pop     hl
        lxi     b, 128
        dad     b
        xchg

        pop     bc
        dcr     c
        jnz     SaveSectorLoop

        call    ResetDMA

        call    FileClose
        
        ret


; *************************************************
; Clear FCB after deletion
; *************************************************
ClearFCB
        lxi     d, FCB+0ch      ; EXTENT
        mvi     c, 23
        xra     a
ClearFCBLoop
        stax    d
        inx     d
        dcr     c
        jnz     ClearFCBLoop
        ret

; *************************************************
; Timer 0 interrupt handler
; *************************************************
TimerHandler
        push    a
        lda     TimCount
        inr     a
        cpi     50
        jnz     THAck
        
        xra     a
        sta     TimCount

        lda     Fun
        inr     a
        ani     3fh
        ori     40h
        sta     Fun

        ; mvi     a, 4ah

        out     VIDEO
        
; Acknowledge interrupt
THAck
	mvi     a, 20h
	out     80h
; Enable interrupts and return
        pop     a
        ei
        ret

; *************************************************
; Настроить таймер, контроллер прерываний, обработчик
; *************************************************
TIM0_DIV        equ     30000
SetupTimerInterrupt
; Init timer

        ; lxi     h, TIM0_DIV      ; тактовая частота таймера 1.5МГц. настроим прерывания 50 раз в секунду
        ; mvi     a, 36h
        ; out     63h
        ; mov     a, l
        ; out     60h
        ; mov     a, h		
        ; out     60h


; Mode 4 - Software triggered strobe, MSB only

        ; mvi     a, 0b00101000
        mvi     a, 26h
        out     63h
        
        mvi     a, 0    ; max count value (2^16)
        out     60h
  

; ; Interrupt controller
;         mvi     a, 0b11101111   ; разрешить прерывания от Таймера 0 (RST4)
;         out     81h
; ; Plant interrupt handler
;         mvi     a, 0c3h
;         sta     20h
;         lxi     h, TimerHandler
;         shld    21h
; ; GO11!!
;         ei
        ret

; *************************************************
; Игры с таймером
; *************************************************
; Чтение таймера 0 (который free running с частотой 22, что ли, Герц)
ReadHourGlass
        mvi     a, 0
        out     63h     ; latch counter value for reading

        in      60h     ; read MSB
        sta     HourGlass
        sta     HourGlass+8
        ret

; *************************************************
; Отобразить счетчик песчинок
; *************************************************
PaintHourGlass
        lxi     h, HourGlass
        lxi     b, 0
        mvi     a, 3
        call    PaintBitmap
        ret

; *************************************************
; 
; *************************************************
OnEveryTick

; моргание курсора
        lda     Ticks
        ani     80h
        sta     Blink

        ret

; *************************************************
; подождем наступления ретрейса
; *************************************************
SyncToRetrace
        in      41h
        ani     2
        rnz
        jmp     SyncToRetrace

; *************************************************
; Задолбался, пытаясь понять, как работает печать в графическом режиме
; Будем юзать свое, посконное (цельнотянутое из вселенной ZX)
; *************************************************
; *************************************************
; _PrintStr
; HL = null-terminated string
; BC = XY
; *************************************************
_PrintStr
        mov     a, m
        ora     a
        rz
        call    _PrintChar
        inx     h
        jmp     _PrintStr

; *************************************************
; _PrintStrN
; HL = string
; BC = XY
; E = length
; *************************************************
_PrintStrN
        mov     a, m
        call    _PrintChar
        inx     h
        dcr     e
        jnz     _PrintStrN
        ret

; *************************************************
; _PrintChar
; A = char [32h..7fh]
; BC = XY
; *************************************************
_PrintChar
        ; cpi     32h
        ; rm
        ; cpi     7fh
        ; rp

        cpi     CR
        jnz     PC0
; Next line        
        mov     a, c
        adi     8
        mov     c, a
; Reset col
        xra     a
        mov     b, a
        
        ret
PC0
        push    h
        push    d

        sui     ' '
        mov     l, a
        xra     a
        mov     h, a
        
        ; multiply by 8
        
        dad     h
        dad     h
        dad     h
        
        lxi     d, FONT
        dad     d
        xchg
        
        call    FillTempChar

        call    PrintTempChar
        
; move 'cursor' to the right
        inr     b
        inr     b
        
        pop     d
        pop     h
        ret


FillTempChar
; DE = битмап нужной буквы
; перегрузим во времянку
        lxi     h, TempChar
        call    Copy8
        lxi     h, TempChar+8
        call    Copy8
        ret

PrintTempChar
        lxi     h, TempChar
        
        lda     PrintColor
        call    PaintBitmap

        ret

; Спектрумовские шрифты на "Океане" отображаются зеркально :-(
;
;       00000001 ---> 10000000
MirrorDtoE
        ; D = src, E = dst
        push    b
        mvi     c, 8
MirrorLoop
        mov     a, d
        rar     a
        mov     d, a
        
        mov     a, e
        ral     a
        mov     e, a

        dcr     c
        jnz     MirrorLoop
        pop     b
        ret

MirrorFont
        lxi     h, FONT
        lxi     b, 768
MFLoop
        mov     d, m
        mvi     e, 0
        
        call    MirrorDtoE
        
        mov     m, e
        
        inx     h
        dcx     b
        mov     a, b
        ora     c
        jnz     MFLoop

        ret


; *************************************************
; _PrintHex
; *************************************************
_PrintHex
        push    a
        rar
        rar
        rar
        rar
        call    _PrintHexNibble
        pop     a
        call    _PrintHexNibble
        ret


; *************************************************
; _PrintHexNibble
; *************************************************
_PrintHexNibble
        push    hl
        push    de
        
        lxi     h, 0
        ani     0fh
        mov     l, a

        ; multiply by 8
        
        dad     h
        dad     h
        dad     h        

        lxi     d, HEXFONT
        dad     d
        xchg

        call    FillTempChar
        
        call    PrintTempChar
        
        inr     b
        inr     b
        
        pop     de
        pop     hl
        ret

; *************************************************
; Различные константы
; *************************************************
DefaultFN
        db      0,'SCRATCH PAD'

ColorMode
        db      ESC, '64',      ; hide cursor
        db      ESC, '8c'    ; черный фон
        db      ESC, '42'    ; желтый передний план
        db      '$'

; SetCursorPosition
;         db      1bh, '5'
; SetCursorPosRow
;         db      0, 0
;         db      '$'

Hello
        db      ESC, '5', 32 + 2, 32 + 2        ; position cursor

        ; db      ESC, '4', 3                     ; select color

        db      'Hello', '$'

SaveYN
        db      'Save [Y/N]?', '$'

; String  ;  db      1bh, 35h, 10, 10
;         db      '1 2 3 4 5 6 7 8 9 0', 0

Version         db      'GRAF v0.2', 0
Copyright       db      '2025 TNT23', 0


BITMAP0 db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
FILLEDBLOCK
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
BITMAP55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55
        db      0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55        

BMPGRID db      0, 1, 0, 1, 0, 1, 0, 0x55
        db      0, 1, 0, 1, 0, 1, 0, 0x55
        
BMPGRID1
        db      0, 0, 0, 0, 8, 0, 0, 0
        db      0, 0, 0, 0, 8, 0, 0, 0

BMPDOT  db      0, 0, 0, 1, 0, 0, 0, 0x11
        db      0, 0, 0, 1, 0, 0, 0, 0x11

CURSOR_BITMAP   equ     BITMAP55
GRID_NONE       equ     BITMAP0
GRID_LINES      equ     BMPGRID
GRID_DOTS       equ     BMPDOT
GRID_GRID       equ     BMPGRID1


MAZOK   db      255, 255, 255, 255, 255, 255, 255, 255, 255
        db      255, 255, 255, 255, 255, 255, 255, 255, 255
        
ONE     db      0ffh, 0efh, 0efh, 0efh, 0efh, 0ffh, 83h, 0ffh
        db      8, 12, 8, 8, 8, 3eh, 0, 0
TWO     db      0ffh, 0e3h, 0ddh, 0efh, 0f7h, 0ffh, 0c1h, 0ffh
        db      1ch, 22h, 10h, 8, 4, 3eh, 0, 0
THREE   db      0ffh, 0e3h, 0ddh, 0e7h, 0ffh, 0ddh, 0e3h, 0ffh
        db      1ch, 22h, 18h, 20h, 22h, 1ch, 0, 0

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


; Шрифт(ы) слямзен(ы) со странички https://www.jimblimey.com/blog/24-zx-spectrum-fonts/
FONT        
        db64    AAAAAAAAAAA4ODg4OAA4AGxsJEgAAAAARP5ERET+RAAQfEB8BHwQAOKk6BAuSo4A
        db64    MEhAIFBIdAA4OAgwAAAAABgwYGBgMBgAYDAYGBgwYAAgqHAgcKggAAAQEHwYGAAA
        db64    AAAAADg4CDAAAAB8fAAAAAAAAAA4ODgAAgQIECBAgAD4iJioyMj4AOAgICAgIPgA
        db64    /AQE/MDA/AB4CAh4GBj4AIiIiIj8GBgA+ICA+BiY+AD4iID4yMj4APiIECBgYGAA
        db64    +IiI+MjI+AD4iIj4GJj4AAA4OAA4OAAAADg4ADg4CDAIECDAIBAIAAB8fAB8fAAA
        db64    gEAgGCBAgAB+QgIeEAAQADwkPAAAAAAA+Ij8hMTExAD4iPyExMT8APyEgMDAxPwA
        db64    +ISExMTE+AD8gPCAwMD8APyA+IDAwMAA/ISAnMTE/ACEhPyExMTEACAgIDAwMDAA
        db64    BAQEDAyMeACEiJDwyMTEAICAgMDAwPwA/JKSktLS0gDklJSU1NTMAPyEhITExPwA
        db64    /ISE/MDAwAD8hISU1Mj0APyEhPzIxMQA/ICA/AwM/AD8ICAgMDAwAISEhMTExPwA
        db64    hITExEQoEACCgpKS0tL+AIRIMDBIhIQAhISE/CAwMAD8CBAgQMD8AHhAQEBAQHgA
        db64    gEAgEAgEAgA8BAQEBAQ8AAAQOGzGAAAAAAAAAAAAAAAAAAAAAAAAAAAAfAR8RHwA
        db64    QEB8REREfAAAAHxAQEB8AAQEfERERHwAAAB8RHxAfAA8IHggICAgAAAAfEREfAR8
        db64    QEB8RERERAAYABgYGBgYAAAIAAgICEh4QEBIUGBQSAAYGBgYGBgYAAAA/pKSkpIA
        db64    AAB8RERERAAAAHxERER8AAAAfEREfEBAAAB8RER8BAQAAHxEQEBAAAAAfEB8BHwA
        db64    ACB8ICAgPAAAACQkJCQ8AAAAREREKBAAAACCkpKS/gAAAEQoEChEAAAAREREfAR8
        db64    AAB8CBAgfAAAAAAAAAAAAAAQEBAQEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

HEXFONT 
        db      38h, 44h, 44h, 0, 44h, 44h, 38h, 0      // 0
        db      0, 40h, 40h, 0, 0, 40h, 40h, 0          // 1
        db      38h, 40h, 40h, 38h, 4, 4, 38h, 0        // 2 
        db      38h, 40h, 40h, 38h, 40h, 40h, 38h, 0    // 3
        db      0, 44h, 44h, 38h, 40h, 40h, 0, 0        // 4
        db      38h, 4, 4, 38h, 40h, 40h, 38h, 0        // 5
        db      38h, 4, 4, 38h, 44h, 44h, 38h, 0        // 6
        db      38h, 40h, 40h, 0, 40h, 40h, 0, 0        // 7
        db      38h, 44h, 44h, 38h, 44h, 44h, 38h, 0        // 8
        db      38h, 44h, 44h, 38h, 40h, 40h, 38h, 0        // 9
        db      38h, 44h, 44h, 38h, 44h, 44h, 0, 0      // a
        db      0, 4, 4, 38h, 44h, 44h, 38h, 0          // b
        db      38h, 4, 4, 0, 4, 4, 38h, 0              // c
        db      0, 40h, 40h, 38h, 44h, 44h, 38h, 0      // d
        db      38h, 4, 4, 38h, 4, 4, 38h, 0            // e
        db      38h, 4, 4, 38h, 4, 4, 0, 0              // f

; ; Pictograms
; BMP_ESC db      07ch, 80h, 80h, 0, 80h, 81h, 81h, 3eh
;         db      3, 1, 1bh, 0c9h, 5bh, 50h, 58h, 0c0h
; BMP_Z   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 1ch, 10h, 8, 4, 1ch, 0, 0
; BMP_1   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 8, 0ch, 8, 8, 1ch, 0, 0
; BMP_2   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 0ch, 10h, 0ch, 4, 1ch, 0, 0
; BMP_3   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 0ch, 10h, 0ch, 10h, 0ch, 0, 0
; BMP_G   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 1ch, 4, 14h, 14h, 1ch, 0, 0
; BMP_C   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 1ch, 4, 4, 4, 1ch, 0, 0
; BMP_P   db      0, 0, 40h, 81h, 81h, 81h, 81h, 7eh
;         db      0, 1ch, 14h, 1ch, 4, 4, 0, 0
        
; BMP_BLOB        db      0, 03ch, 72h, 7ah, 7eh, 7eh, 3ch, 0
;                 db      0, 03ch, 72h, 7ah, 7eh, 7eh, 3ch, 0

; MANNEKIN        db      0, 10h, 0, 0, 0, 0, 0, 0
;                 db      0, 0, 4ch, 3ah, 8, 34h, 22h, 0

; Зажечь/погасить квадратик
INV     db      0

; Координаты курсора
CurPos  dw      0

BmpPtr dw      0

FORECOLOR       db      0
BACKCOLOR       db      0

; Переключатель Tab
Tab     db      0

; Переменная для развлекухи
Fun     db      40h
TimCount
        db      0

Ticks   db      0

Blink           db      0
BlinkPrev       db      0

GridType        db      2

HourGlass       db      0, 0, 3ch, 18h, 3ch, 7eh, 255, 255
                db      0, 0, 3ch, 18h, 3ch, 7eh, 255, 255

; Цвет выводимых символов
PrintColor      db      3

; Внутренний клипборд для символа из шрифта
TempChar        db      16

; Клипборд
CLIPBOARD       equ     .
        
