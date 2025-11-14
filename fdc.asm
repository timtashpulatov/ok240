

	.project fdc
	.org 100h

CONST           equ     0e006h  ; A = FF if there is keypress
CONIN           equ     0e009h  
CONOUT          equ     0e00ch  ; output symbol from C


VIDEO           equ     0E1h
ENROM           equ     0x10
SCROLL_V        equ     0C0h
BANKING         equ     0C1h
SCROLL_VH       equ     0C2h


PORT_CMD                equ     20h
PORT_TRACK              equ     21h
PORT_SECTOR             equ     22h
PORT_DATA               equ     23h
PORT_FLOPPY_WAIT        equ     24h
PORT_FLOPPY             equ     25h

DRIVE_0         equ     1 << 0
DRIVE_1         equ     1 << 1
DRIVE_SELECT    equ     1 << 2
DRIVE_INIT      equ     1 << 3
DRIVE_SIDE      equ     1 << 5  ; write to reg 25

DRIVE_MOTST     equ     1 << 7  ; read from reg 25

FLAG_UPDATE     equ     10h

CMD_RESTORE     equ     00h
CMD_SEEK        equ     10h
CMD_STEPIN      equ     40h     ; towards center and track 79
CMD_STEPOUT     equ     60h     ; to track 0
CMD_READADDRESS equ     0c0h    ; read next ID
CMD_READSECTOR  equ     80h

STATUS_NOTREADY equ     80h
STATUS_WPROT    equ     40h
STATUS_NOTFOUND equ     10h
STATUS_CRC      equ     08h
STATUS_BUSY     equ     01h

ESC             equ     27
CRLF            equ     00d0ah

SCREEN          equ     0c000h

        ; lxi     d, Help
        ; mvi     c, 9
        ; call     5


        ; mvi     c, '?'
        ; call    CONOUT


        ; call    ResetScroll

        lxi     h, MainMenu
        call    PrintString

        mvi     a, 40h
        out     VIDEO

        call    PaintBitmapMxN

        call    DrawSideIndicator

        mvi     a, 2
        sta     PrintColor


MenuLoop

        ; call    WaitForKey
        
        call    CONST
        inr     a
        jz      WeHaveKeypress
        
        call    ShowFloppyPort
        call    ShowVG93Regs
		
	jmp     MenuLoop


WeHaveKeypress
        call    CONIN
; Большие или малые буквы, это все равно
        cpi     0x5f
        jc      Next0
        sui     0x20
Next0

        mov     c, a
        lxi     d, MenuKeys
Next        
        ldax    d
        ora     a
        jz      MenuLoop
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

MenuKeys
        db      'H' \ dw RestoreHome
        db      '0' \ dw SelectDrive0
        db      '1' \ dw SelectDrive1
        db      'H' \ dw RestoreHome
        db      'E' \ dw End
        db      'M' \ dw MotorStart
        ; db      '-' \ dw StepOut
        db      1ah \ dw StepOut
        ; db      '+' \ dw StepIn
        db      19h \ dw StepIn
        db      08h \ dw SecPrev
        db      18h \ dw SecNext
        db      'S' \ dw SideToggle
        db      'I' \ dw ReadNextID
        db      'T' \ dw TrackLoop
        db      'R' \ dw SectorRead
        db      'C' \ dw ContinuousDrill
        db      ESC \ dw Quit
        db      0 \ dw 0

Quit    rst     0        


; ************************************************************************
; Continuous drill
; ************************************************************************
ContinuousDrill

ContDrill
        call    _MotorStart
        call    _WaitForIdle
        ora     a
        jz      MenuLoop

        call    PaintSectorTemplate

        lxi     h, DataBuf    
        call    ReadSector

        call    CheckResult
        jnz     CDNext

        call    PaintSectorMarkGood

        call    DumpSector

CDNext
        call    ShowFloppyPort
        call    ShowVG93Regs

        call    _SideToggle
        mvi     a, 50
        call    Delay

        
; exit on any key        
ContDrillCheckKey
        call    CONST
        inr     a
        jnz     ContDrill
        
        jmp     MenuLoop

; ************************************************************************
; CheckResult
; ************************************************************************
CheckResult
        in      PORT_CMD
        ani     STATUS_NOTFOUND
        ret

; ************************************************************************
; ReadDataLoop
; ************************************************************************
ReadDataLoop
        in      PORT_FLOPPY_WAIT
        rrc
        in      PORT_DATA
        mov     m, a
        inx     h
        jc      ReadDataLoop

        ret


; ************************************************************************
; Prev/Next sector
; ************************************************************************
SecPrev
        in      PORT_SECTOR
        cpi     1
        jz      MenuLoop
        dcr     a
        out     PORT_SECTOR
        jmp     MenuLoop

SecNext
        in      PORT_SECTOR
        cpi     26
        jz      MenuLoop
        inr     a
        out     PORT_SECTOR
        jmp     MenuLoop


; ************************************************************************
; Sector read
; ************************************************************************
SectorRead
        jmp     MenuLoop

; ************************************************************************
; Track read
; ************************************************************************
SECTEMPLATE_ROW equ     18
SECTEMPLATE_COL equ     1

TrackLoop
        call    _MotorStart
        call    _WaitForIdle
        ora     a
        jz      MenuLoop

        call    PaintSectorTemplate
        
        lxi     h, DataBuf
        call    ReadSector

        call    CheckResult
        jnz     MenuLoop

        call    PaintSectorMarkGood

        call    DumpSector

TrackLoopDone
        jmp     MenuLoop

ConvertSideToBinary
        lda     vSide
        ani     DRIVE_SIDE
        rlc     a
        rlc     a
        rlc     a
        mov     c, a
        ret

DumpSector
        lxi     h, DataBuf
        lxi     b, 00b0h
        mvi     e, 64
        call    DumpHexBlock
        ret

PaintSectorMarkGood
        lxi     hl, BMP_SECTOR_GOOD
        jmp     PaintSectorMark

PaintSectorMarkBad
        lxi     hl, BMP_SECTOR_BAD
        jmp     PaintSectorMark

PaintSectorTemplate
        lxi     hl, BMP_SECTOR_UNK
PaintSectorMark
        in      PORT_SECTOR
        mov     b, a
        call    ConvertSideToBinary
        call    _PaintSectorMark
        ret

; ************************************************************************
; Sector read
; HL = data buf addr
; ************************************************************************
ReadSector
; Чтение сектора
; Номер дорожки и номер сектора уже должны быть загружены
; в регистры TRACK и SECTOR
        mvi     a, CMD_READSECTOR
        out     PORT_CMD

        call    ReadDataLoop

        ret

        

; ; Draw 9 sector template
;         lxi     h, BMP_SECTOR_UNK
;         lxi     b, ((SECTEMPLATE_COL*2)<<8) + SECTEMPLATE_ROW*8
;         mvi     e, 9
;         mvi     a, 3
; DrawSectorTemplate
;         call    PaintBitmap
;         inr     b
;         inr     b
;         dcr     e
;         jnz     DrawSectorTemplate


; ; test - paint side 0, sector 1, unk
;         lxi     h, BMP_SECTOR_UNK
;         lxi     b, 0100h
;         call    PaintSectorMark


; ; test - paint side 0, sector 3, good
;         lxi     h, BMP_SECTOR_GOOD
;         lxi     b, 0300h
;         call    PaintSectorMark

; ; test - paint side 1, sector 5, bad
;         lxi     h, BMP_SECTOR_BAD
;         lxi     b, 0501h
;         call    PaintSectorMark

        jmp     MenuLoop

; ********************************************
; Paint sector mark
; HL = bitmap addr (UNK, GOOD, BAD)
; B = sector number (1..9)
; C = side (0, 1)
; ********************************************
_PaintSectorMark
        push    h
        push    b

        push    h
        lxi     h, ((SECTEMPLATE_COL*2)<<8) + SECTEMPLATE_ROW*8
        ; dcr     b       ; sector numbers start from 1

; convert side (0 or 1) to vertical offset 0 or 8
        mov     a, c
        cma
        ani     1
        ral     a
        ral     a
        ral     a
        mov     c, a
; double sector number for horizontal color offset
        dcr     b

        mov     a, b
        add     b
        mov     b, a
        
        dad     b
        push    h
        pop     b
        pop     h
        
        mvi     a, 3
        call    PaintBitmap
        
        pop     b
        pop     h
        ret


; ************************************************************************
; Read 6 bytes of next ID into DataBuf
; ************************************************************************
ReadNextID
; start motor
; wait for !Busy

        call    _MotorStart
        call    _WaitForIdle
        ora     a
        jz      MenuLoop

; Чтение ID
        lxi     h, DataBuf
        mvi     a, CMD_READADDRESS
        out     PORT_CMD
        nop
        nop

        call    ReadDataLoop

        ; in      PORT_CMD
        ; ani     ~30h ; "Массив не найден", "Тип записи" это нормально

        call    CheckResult

; dump 6 bytes
ReadDone
        lxi     h, DataBuf
        lxi     b, 0080h
        mvi     a, 6

        call    HexDumpN
        jnz     MenuLoop

; FDC зачем-то помещает номер дорожки в регистр сектора, что неудобно для
; последующей работы
        lda     DataBuf+2
        out     PORT_SECTOR

; поставим галочку на прочитанном секторе
        mov     b, a    ; sector number
        call    ConvertSideToBinary
        lxi     h, BMP_SECTOR_GOOD
        call    _PaintSectorMark
        
        jmp     MenuLoop

; ************************************************************************
; Dump an A=number of hex bytes from HL
; BC = screen position
; ************************************************************************
HexDumpN
        push    de
        mov     e, a
HDN
        mov     a, m
        call    _PrintHex
        inx     h
        dcr     e
        jz      HDNDone
        ; mvi     c, ' '
        ; call    CONOUT
        inr     b
        inr     b
        jmp     HDN
HDNDone
        pop     de
        ret
        
        
; ************************************************************************
; Ожидаение готовности контроллера
; Возвращает А=1 при готовности и 0 при таймауте
; ************************************************************************
_WaitForIdle
; wait for MOTST monostable
WMM
        in      PORT_FLOPPY
        ani     DRIVE_MOTST
        jnz     WMM

; now check if MOTST is active
WLoop
        in      PORT_FLOPPY
        ani     DRIVE_MOTST
        jnz     Timeout

        in      PORT_CMD
        ani     STATUS_BUSY | STATUS_NOTREADY
        jnz     WLoop
        
        mvi     a, 1
        ret

Timeout
        xra     a
        ret

; ************************************************************************
; Side Toggle
; ************************************************************************
SideToggle

SIDEINDICATOR_COL       equ     SECTEMPLATE_COL-1
SIDEINDICATOR_ROW       equ     SECTEMPLATE_ROW

        call    _SideToggle
        jmp     MenuLoop

_SideToggle
; erase side bitmap
        call    EraseSideIndicator

; toggle side
        lda     vSide
        cma
        ; ani     DRIVE_SIDE
        sta     vSide

; draw side bitmap
        call    DrawSideIndicator
        ret

DrawSideIndicator
        lxi     h, BMP_SIDE
_DrawSideIndicator
        lxi     bc, ((SIDEINDICATOR_COL*2) << 8) + (SIDEINDICATOR_ROW+1)*8

        lda     vSide

        ora     a
        jz      ST1
        mvi     c, (SIDEINDICATOR_ROW)*8
ST1
        mvi     a, 3
        call    PaintBitmap
        ret

EraseSideIndicator
        lxi     h, BMP_VOID
        jmp     _DrawSideIndicator

; ************************************************************************
; Select drive 0 (B:)
; ************************************************************************
SelectDrive0
        call    _SelectDrive0
        jmp     MenuLoop

_SelectDrive0
        mvi     a, DRIVE_SELECT | DRIVE_0
        sta     vPortFloppy
        jmp     _WriteToFloppyPort

; ************************************************************************
; Select drive 1 (C:)
; ************************************************************************
SelectDrive1
        call    _SelectDrive1
        jmp     MenuLoop

_SelectDrive1
        mvi     a, DRIVE_1
        sta     vPortFloppy
        jmp     _WriteToFloppyPort

_WriteToFloppyPort
        lda     vPortFloppy
        mov     b, a
        lda     vSide
        ani     DRIVE_SIDE
        ora     b
        out     PORT_FLOPPY
        ret
        
        
StepOut
        call    _MotorStart
        call    _WaitForIdle
        call    _StepOut
        jmp     MenuLoop

_StepOut
        mvi     a, CMD_STEPOUT | FLAG_UPDATE
        out     PORT_CMD
        ret

StepIn
        call    _MotorStart
        call    _WaitForIdle
        call    _StepIn
        jmp     MenuLoop

_StepIn
        mvi     a, CMD_STEPIN | FLAG_UPDATE
        out     PORT_CMD
        ret
        
End    
        call    _MotorStart
        call    _WaitForIdle
        call    _End
        jmp     MenuLoop

_End
        mvi     a, 79
        call    SeekToTrack
        ret

; ************************************************************************
; Seek to track in accumulator
; ************************************************************************
SeekToTrack
        call    _SeekToTrack
        jmp     MenuLoop

_SeekToTrack
        out     PORT_DATA
        xra     a
        out     PORT_TRACK

        mvi     a, CMD_SEEK
        out     PORT_CMD

        ret


; ************************************************************************
; Restore
; ************************************************************************
RestoreHome
        call    _MotorStart
        call    _WaitForIdle
        call    _Restore
        jmp     MenuLoop

_Restore
        mvi     a, 1
        out     PORT_SECTOR
        mvi     a, CMD_RESTORE
        out     PORT_CMD
        ret

; ************************************************************************
; Запуск двигателя
; ************************************************************************
MotorStart
        call    _MotorStart
        jmp     MenuLoop
        
_MotorStart
        push    bc
        lda     vPortFloppy
        mov     b, a
        lda     vSide
        ani     DRIVE_SIDE      ; ?
        ora     b
        out     PORT_FLOPPY

        ori     DRIVE_INIT
        out     PORT_FLOPPY
        pop     bc
        ret
        


; ************************************************************************
; Ожидаение готовности дисковода или остановки двигателя по таймауту
; Возвращает A=00, если не готов или таймаут
; ************************************************************************
; WaitForDriveReady      
;         in      PORT_FLOPPY
;         ani     80h                     ; check MOTST
;         rnz

;         in      PORT_CMD
;         ani     80h                     ; 0x80 if drive NOT READY
;         jnz     WaitForDriveReady
        
;         inr     a                       ; A = 1

;         ret

; ************************************************************************
; Вывести содержимое порта 0x25
; ************************************************************************
ShowFloppyPort
        lxi     h, aPosFloppyPort
        call    PrintString

        in      PORT_FLOPPY
        call    PrintBinary
        
        ret

; ************************************************************************
; Вывести содержимое регистров дорожки, сектора и данных ВГ93
; ************************************************************************
ShowVG93Regs
        lxi     h, aPosStatusReg
        call    PrintString

        in      PORT_CMD
        call    PrintBinary
        call    PaintStatusBits

        lxi     b, 3828h
        mvi     a, 2
        sta     PrintColor
        in      PORT_TRACK
        call    _PrintHex

        lxi     b, 3830h
        mvi     a, 2
        sta     PrintColor
        in      PORT_SECTOR
        call    _PrintHex

        lxi     b, 3838h
        mvi     a, 2
        sta     PrintColor
        in      PORT_DATA
        call    _PrintHex

        ret

; *************************************************
; Print hex block of A bytes starting from HL
; *************************************************
DumpHexBlock
        push    de
        push    bc
        mov     a, e
        rar     a
        rar     a
        rar     a
        mov     e, a
DHB
        mvi     a, 8
        push    bc
        call    HexDumpN
        pop     bc

        mov     a, c
        adi     8
        mov     c, a
        
        dcr     e
        jnz     DHB

        pop     bc
        pop     de
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


FillTempChar
; DE = битмап нужной буквы
; перегрузим во времянку
        lxi     h, TempChar
        call    CopyFromDEtoHL8
        
        lxi     h, TempChar+8
        call    CopyFromDEtoHL8
        ret

PrintTempChar
        lxi     h, TempChar
        
        lda     PrintColor
        call    PaintBitmap

        ret

; ************************************************************************
; Напечатать А в двоичной форме
; ************************************************************************
PrintBinary
        push    a
        mvi     l, 8
BitsLoop
        mvi     c, '0'
        rlc
        jnc      BL1
        inr     c
BL1
        push    h
        push    a
        call    CONOUT
        pop     a
        pop     h
        
        dcr     l
        jnz     BitsLoop
        
        pop     a
        ret

PaintStatusBits
        push    a
        lxi     h, BMP_RDY_ACTIVE
        ani     80h
        jz      PSB7
        lxi     h, BMP_RDY_INACTIVE
PSB7        
        lxi     bc, 0000
        mvi     a, 3
        call    PaintBitmap8x16
        pop     a

        push    a
        lxi     h, BMP_WP_ACTIVE
        ani     40h
        jnz     PSB6
        lxi     h, BMP_WP_INACTIVE
PSB6        
        lxi     bc, 0400h
        mvi     a, 3
        call    PaintBitmap8x16
        pop     a

        push    a
        lxi     h, BMP_ERR_ACTIVE
        ani     10h
        jnz     PSB4
        lxi     h, BMP_ERR_INACTIVE
PSB4        
        lxi     bc, 0c00h
        mvi     a, 3
        call    PaintBitmap8x16
        pop     a

        push    a
        lxi     h, BMP_IDX_ACTIVE
        ani     02h
        jnz     PSB1
        lxi     h, BMP_IDX_INACTIVE
PSB1        
        lxi     bc, 24 << 8
        mvi     a, 3
        call    PaintBitmap8x16
        pop     a

        push    a
        lxi     h, BMP_BSY_ACTIVE
        ani     01h
        jnz     PSB0
        lxi     h, BMP_BSY_INACTIVE
PSB0        
        lxi     bc, 28 << 8
        mvi     a, 3
        call    PaintBitmap8x16
        pop     a
        
        
        ret


; ************************************************************************
; Вывод Z-terminated строки
; ************************************************************************
PrintString
        mov     a, m
        ora     a
        rz
        mov     c, a
        call    CONOUT
        inx     h
        jmp     PrintString

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
        call    CopyFromDEtoHL8
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
        call    CopyFromDEtoHL8

PlaneDone
        ; Включаем ПЗУ обратно
        xra     a
        out     BANKING
        
        pop     a
        pop     hl
        pop     de
        pop     bc
        ei
        ret



PaintBitmap8x16

        call    PaintBitmap

        inr     b
        inr     b
        
        lxi     d, 16
        dad     d


        ; lxi     h, BMP_RDY_ACTIVE+16
        ; lxi     bc, 0200h
        ; mvi     a, 3

        call    PaintBitmap
        
        ret

        ; lxi     h, BMP_RDY_INACTIVE+16
        ; lxi     bc, 0200h
        ; mvi     a, 3
        ; call    PaintBitmap

; *************************************************
; Paint M columns by N rows bitmap
; *************************************************
PaintBitmapMxN
        lxi     h, BMP_ID
        lxi     b, 3220h
        
        mvi     d, 4
PBMN        
        mvi     e, 6
        call    PaintBitmapRow
        
        ; push    de
        ; lxi     d, 0800h
        ; dad     d
        ; pop     de

        mov     a, c
        adi     8
        mov     c, a
        mov     a, b
        aci     0
        mov     b, a

        

        
        dcr     d
        jnz     PBMN
        
        ret

; *************************************************
; Paint row of tiles
; E = number of tiles
; *************************************************
PaintBitmapRow
        ; push    hl
        push    bc
        
        mvi     a, 3
PBR
        call    PaintBitmap
        inr     b
        inr     b
        push    de
        lxi     d, 16
        dad     d
        pop     de
        
        dcr     e
        jnz     PBR
        
        pop     bc
        ; pop     hl
        ret

; *************************************************
; Copy 8 bytes from DE to HL
; *************************************************
CopyFromDEtoHL8
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

; ************************************************************************
; Delay synched with Vertical Retrace
; ************************************************************************
Delay
        push    bc
        mov     c, a
WaitForVR
        in      41h
        ani     2
        jz     WaitForVR        ; Дождемся кадрового ретрейса
        
WaitForVRDone
        in      41h
        ani     2
        jnz     WaitForVRDone

        dcr     c
        jnz     WaitForVR
        
        pop     bc
        ret


; ; *************************************************
; ; Установить нулевые смещения для вертикальной и горизонтальной прокруток        
; ; *************************************************
; ResetScroll
;         xra     a
;         out     SCROLL_V
;         out     SCROLL_VH
;         ret


; ************************************************************************
; Константы и переменные
; ************************************************************************
CurPosTest
        db      1fh
        db      27, '0', 100, 100, 31h
        db      'ABC', 0
        
Help:   db      1fh
        db      'FDC v0.1', 10, 13
        db      'Usage:', '$'

aTimeout
        db      'Timeout!', 7, 0

MainMenu
        db      1fh
        db      ESC, '6', '4'
        db      ESC, '43'
        ; db      ESC, '8', 03
        ; dw      CRLF
        db      ESC, 5, 22h, 20h
        db      '0 - Select drive 0' \ dw CRLF
        db      '1 - Select drive 1' \ dw CRLF
        db      'S - Side toggle' \ dw CRLF
        db      'M - Motor' \ dw CRLF
        db      'H - Home (seek to track 00)' \ dw CRLF
        db      'E - Seek to track 79' \ dw CRLF
        db      'I - Read next ID' \ dw CRLF
        db      'T - Track read' \ dw CRLF
        db      'R - Sector read' \ dw CRLF
        db      'C - Continuous drill' \ dw CRLF
        
        db      'ESC - Quit', \ dw CRLF
        
        ; db      ESC, '5', 20h, 20h, "Pops!"
        
        ; db      ESC, 5, 20h+16, 20h
        ; db      'DATA FIELD'
        
        db      0

; ************************************************************************
; Битмапчики
; ************************************************************************
BMP_RDY_ACTIVE          
                        db      0, 0, 0, 0, 0, 0, 0, 0
                        db      0ffh, 033h, 0abh, 0b3h, 0abh, 2bh, 0ffh, 0
                        db      0, 0, 0, 0, 0, 0, 0, 0
                        db      7fh, 6bh, 6ah, 76h, 76h, 77h, 7fh, 0

BMP_RDY_INACTIVE        
        db      0, 0cch, 54h, 4ch, 54h, 0d4h, 0, 0
                        db      0, 0cch, 54h, 4ch, 54h, 0d4h, 0, 0
                        db      0, 14h, 15h, 9, 9, 8, 0, 0
                        db      0, 14h, 15h, 9, 9, 8, 0, 0

BMP_BSY_ACTIVE          
        db      0, 0, 0, 0, 0, 0, 0, 0
                        db      0ffh, 73h, 0abh, 33h, 0ebh, 33h, 255, 0
                        db      0, 0, 0, 0, 0, 0, 0, 0
                        db      7fh, 6ah, 6bh, 76h, 76h, 77h, 7fh, 0

BMP_BSY_INACTIVE        
        db      0, 8ch, 54h, 0cch, 14h, 0cch, 0, 0                        
                        db      0, 8ch, 54h, 0cch, 14h, 0cch, 0, 0
                        db      0, 15h, 14h, 9, 9, 8, 0, 0
                        db      0, 15h, 14h, 9, 9, 8, 0, 0

BMP_WP_ACTIVE
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0ffh, 55h, 55h, 55h, 55h, 6bh, 0ffh, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      7fh, 7eh, 7dh, 7eh, 7fh, 7fh, 7fh, 0

BMP_WP_INACTIVE
        db      0, 0aah, 0aah, 0aah, 0aah, 94h, 0, 0
        db      0, 0aah, 0aah, 0aah, 0aah, 94h, 0, 0
        db      0, 1, 2, 1, 0, 0, 0, 0
        db      0, 1, 2, 1, 0, 0, 0, 0

BMP_IDX_ACTIVE
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0ffh, 23h, 0b7h, 0b7h, 0b7h, 23h, 255, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      7fh, 6bh, 6ah, 76h, 6ah, 6bh, 7fh, 0
        
BMP_IDX_INACTIVE
        db      0, 0dch, 48h, 48h, 48h, 0dch, 0, 0
        db      0, 0dch, 48h, 48h, 48h, 0dch, 0, 0
        db      0, 14h, 15h, 9, 15h, 14h, 0, 0
        db      0, 14h, 15h, 9, 15h, 14h, 0, 0
        
BMP_ERR_ACTIVE
        db      0ffh, 23h, 0bbh, 0a3h, 0bbh, 0a3h, 0ffh, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      7fh, 62h, 7bh, 7bh, 7bh, 7bh, 7fh, 0
        db      0, 0, 0, 0, 0, 0, 0, 0

BMP_ERR_INACTIVE
        db      0, 0dch, 44h, 5ch, 44h, 5ch, 0, 0
        db      0, 0dch, 44h, 5ch, 44h, 5ch, 0, 0
        db      0, 1dh, 4, 4, 4, 4, 0, 0
        db      0, 1dh, 4, 4, 4, 4, 0, 0

BMP_SECTOR_UNK
        ; db      00, 28h, 2Ah, 2Ah, 4Ah, 28h, 7Fh, 7Fh
        ; db      00, 7Fh, 7Fh, 7Fh, 7Fh, 7Fh, 7Fh, 7Fh
        db      00, 7Fh, 5Fh, 5Fh, 5Fh, 5Fh, 41h, 7Fh
        db      00, 7Fh, 5Fh, 5Fh, 5Fh, 5Fh, 41h, 7Fh
BMP_SECTOR_BAD
        db      00, 7Fh, 5Fh, 5Fh, 5Fh, 5Fh, 41h, 7Fh
        db      00, 7Fh, 41h, 41h, 41h, 41h, 41h, 7Fh
BMP_SECTOR_GOOD
        db      00, 7Fh, 41h, 41h, 41h, 41h, 41h, 7Fh
        db      00, 7Fh, 5Fh, 5Fh, 5Fh, 5Fh, 41h, 7Fh

BMP_SIDE
        db      0, 10h, 3ch, 7ch, 7ch, 3ch, 10h, 0
        db      18h, 2eh, 42h, 82h, 0feh, 7eh, 3eh, 18h

BMP_ID
        db      0FEh, 01h, 0A9h, 55h, 0A9h, 55h, 0A9h, 0fdh
        db      0FEh, 01h, 0A9h, 55h, 0A9h, 55h, 0A9h, 0fdh
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      0FFh, 00h, 0AAh, 55h, 0AAh, 55h, 0AAh, 0FFh 
        db      7Fh, 80h, 0AAh, 0D5h, 0AAh, 0D5h, 0AAh, 0FFh
        db      7Fh, 80h, 0AAh, 0D5h, 0AAh, 0D5h, 0AAh, 0FFh

        db      0FDh, 45h, 6Dh, 6Dh, 6Dh, 6Dh, 0FDh, 0FDh 
        db      0FDh, 45h, 6Dh, 6Dh, 6Dh, 6Dh, 0FDh, 0FDh
        db      0FFh, 44h, 55h, 54h, 46h, 55h, 0FFh, 0FFh
        db      0FFh, 44h, 55h, 54h, 46h, 55h, 0FFh, 0FFh
        db      0FFh, 0D4h, 0D7h, 0E7h, 0D7h, 0D4h, 0FFh, 0FFh
        db      0FFh, 0D4h, 0D7h, 0E7h, 0D7h, 0D4h, 0FFh, 0FFh
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
        
        db      0FDh, 4Dh, 75h, 45h, 5Dh, 65h, 0FDh, 0FDh 
        db      0FDh, 4Dh, 75h, 45h, 5Dh, 65h, 0FDh, 0FDh 
        db      0FFh, 44h, 0F7h, 0F4h, 0F7h, 0C4h, 0FFh, 0FFh
        db      0FFh, 44h, 0F7h, 0F4h, 0F7h, 0C4h, 0FFh, 0FFh
        db      0FFh, 0FCh, 0FEh, 0FEh, 0FEh, 0FEh, 0FFh, 0FFh
        db      0FFh, 0FCh, 0FEh, 0FEh, 0FEh, 0FEh, 0FFh, 0FFh
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh

        db      0FDh, 65h, 55h, 55h, 55h, 65h, 0FDh, 0FFh 
        db      0FDh, 65h, 55h, 55h, 55h, 65h, 0FDh, 0FFh
        db      0FFh, 44h, 6Dh, 6Dh, 6Ch, 6Dh, 0FFh, 0FFh
        db      0FFh, 44h, 6Dh, 6Dh, 6Ch, 6Dh, 0FFh, 0FFh
        db      0FFh, 0FCh, 0FDh, 0FDh, 0FCh, 0FDh, 0FFh, 0FFh
        db      0FFh, 0FCh, 0FDh, 0FDh, 0FCh, 0FDh, 0FFh, 0FFh
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0, 0, 0, 0, 0, 0, 0, 0
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
        db      0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh

BMP_VOID        dw      0, 0, 0, 0, 0, 0, 0, 0


HEXFONT 
        db      38h, 44h, 44h, 0, 44h, 44h, 38h, 0      // 0
        db      0, 40h, 40h, 0, 0, 40h, 40h, 0          // 1
        db      38h, 40h, 40h, 38h, 4, 4, 38h, 0        // 2 
        db      38h, 40h, 40h, 38h, 40h, 40h, 38h, 0    // 3
        db      0, 44h, 44h, 38h, 40h, 40h, 0, 0        // 4
        db      38h, 4, 4, 38h, 40h, 40h, 38h, 0        // 5
        db      38h, 4, 4, 38h, 44h, 44h, 38h, 0        // 6
        db      38h, 40h, 40h, 0, 40h, 40h, 0, 0        // 7
        db      38h, 44h, 44h, 38h, 44h, 44h, 38h, 0    // 8
        db      38h, 44h, 44h, 38h, 40h, 40h, 38h, 0    // 9
        db      38h, 44h, 44h, 38h, 44h, 44h, 0, 0      // a
        db      0, 4, 4, 38h, 44h, 44h, 38h, 0          // b
        db      38h, 4, 4, 0, 4, 4, 38h, 0              // c
        db      0, 40h, 40h, 38h, 44h, 44h, 38h, 0      // d
        db      38h, 4, 4, 38h, 4, 4, 38h, 0            // e
        db      38h, 4, 4, 38h, 4, 4, 0, 0              // f


aPosFloppyPort
        db      ESC, 5, 20h, 20h+30, 0
aPosStatusReg
        db      ESC, 5, 20h+2, 20h+30, 0
; aPosTrackReg
;         db      ESC, 5, 20h+4, 20h+28, 'Track', 0
        
vPortFloppy     db      DRIVE_SELECT | DRIVE_0  ; дисковод B: по умолчанию (а мог бы быть C:)
vSide           db      0

; Цвет выводимых символов
PrintColor      db      3

; Внутренний клипборд для символа из шрифта
TempChar        ds      16

; Буфер данных (Шесть байт для команды READ ADDRESS, например, или 1024 байт сектора, или вся дорожка)
DataBuf  db      0, 0, 0xde, 0xad, 0xbe, 0xef
