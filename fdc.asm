
	.project fdc
	.org 100h

CONST           equ     0e006h  ; A = FF if there is keypress
CONIN           equ     0e009h  
CONOUT          equ     0e00ch  ; output symbol from C

VIDEO           equ     0E1h
ENROM           equ     0x10
BANKING         equ     0C1h


PORT_CMD        equ     20h
PORT_TRACK      equ     21h
PORT_SECTOR     equ     22h
PORT_DATA       equ     23h
PORT_FLOPPY     equ     25h

DRIVE_0         equ     1 << 0
DRIVE_1         equ     1 << 1
DRIVE_SELECT    equ     1 << 2
DRIVE_INIT      equ     1 << 3
DRIVE_DDEN      equ     1 << 4  ; not used ?
DRIVE_SIDE      equ     1 << 5

FLAG_UPDATE     equ     10h

CMD_RESTORE     equ     00h
CMD_SEEK        equ     10h
CMD_STEPIN      equ     40h     ; towards center and track 79
CMD_STEPOUT     equ     60h     ; to track 0

ESC             equ     27
CRLF            equ     00d0ah

SCREEN          equ     0c000h

        ; lxi     d, Help
        ; mvi     c, 9
        ; call     5


        ; mvi     c, '?'
        ; call    CONOUT


        lxi     h, MainMenu
        call    PrintString

        mvi     a, 40h
        out     VIDEO



        ; lxi     h, BMP_RDY_ACTIVE
        ; lxi     bc, 0
        ; mvi     a, 3
        ; call    PaintBitmap8x16

        ; ; lxi     h, BMP_RDY_ACTIVE+16
        ; ; lxi     bc, 0200h
        ; ; mvi     a, 3
        ; ; call    PaintBitmap



MenuLoop

        ; call    WaitForKey
        
        call    CONST
        inr     a
        jz      WeHaveKeypress
        
        call    ShowFloppyPort
        call    ShowStatusPort
        call    ShowTrackReg        
		
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
        db      'R' \ dw Restore
        db      '0' \ dw SelectDrive0
        db      '1' \ dw SelectDrive1
        db      'R' \ dw Restore
        db      'E' \ dw End
        db      'M' \ dw MotorStart
        db      '-' \ dw StepOut
        db      '+' \ dw StepIn
        db      'U' \ dw UpperSide
        db      'L' \ dw LowerSide
        db      ESC \ dw Quit
        db      0 \ dw 0

Quit    rst     0        

UpperSide
        xra     a
        jmp     StoreSide
LowerSide
        mvi     a, DRIVE_SIDE
StoreSide
        sta     vSide
        jmp     MenuLoop

_SelectDrive0
        mvi     a, DRIVE_SELECT | DRIVE_0
        sta     vPortFloppy
        out     PORT_FLOPPY
        ret
SelectDrive0
        call    _SelectDrive0
        jmp     MenuLoop

_SelectDrive1
        mvi     a, DRIVE_1
        sta     vPortFloppy
        out     PORT_FLOPPY
        ret
SelectDrive1
        call    _SelectDrive1
        jmp     MenuLoop

_StepOut
        mvi     a, CMD_STEPOUT | FLAG_UPDATE
        out     PORT_CMD
        ret
StepOut
        call    _StepOut
        jmp     MenuLoop

_StepIn
        mvi     a, CMD_STEPIN | FLAG_UPDATE
        out     PORT_CMD
        ret
StepIn
        call    _StepIn
        jmp     MenuLoop

_End
        mvi     a, 79
        call    SeekToTrack
        ret
End    
        call    _End
        jmp     MenuLoop

; ; Seek to track 79
;         mvi     a, 0
;         out     PORT_TRACK

;         mvi     a, 79
;         out     PORT_DATA
        
;         mvi     a, CMD_SEEK
;         out     PORT_CMD
        
;         call    WaitForKey

;         rst      0

; ************************************************************************
; Seek to track in accumulator
; ************************************************************************
_SeekToTrack
        ; push    a
        ; call    _Restore
        
        ; pop     a
        out     PORT_DATA
        xra     a
        out     PORT_TRACK

        mvi     a, CMD_SEEK
        out     PORT_CMD

        
        ; call    WaitForDriveReady
        ; ora     a
        ; jz      MenuLoop
        
        ; lxi    h, aTimeout
        ; call    PrintString
        ret

SeekToTrack
        call    _SeekToTrack
        jmp     MenuLoop

; ************************************************************************
; Restore
; ************************************************************************
_Restore
        mvi     a, CMD_RESTORE
        out     PORT_CMD
        ret
Restore
        call    _Restore
        jmp     MenuLoop

; ************************************************************************
; Запуск двигателя
; ************************************************************************
_MotorStart
        lda     vPortFloppy
        out     PORT_FLOPPY
        ori     DRIVE_INIT
        out     PORT_FLOPPY
        ret
        
MotorStart
        call    _MotorStart
        jmp     MenuLoop

; ************************************************************************
; Ожидаение готовности дисковода или остановки двигателя по таймауту
; Возвращает A=00, если не готов или таймаут
; ************************************************************************
WaitForDriveReady      
        in      PORT_FLOPPY
        ani     80h                     ; check MOTST
        rnz

        in      PORT_CMD
        ani     80h                     ; 0x80 if drive NOT READY
        jnz     WaitForDriveReady
        
        inr     a                       ; A = 1

        ret

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
; Вывести содержимое порта статуса ВГ93
; ************************************************************************
ShowStatusPort
        lxi     h, aPosStatusReg
        call    PrintString

        in      PORT_CMD
        call    PrintBinary
        call    PaintStatusBits
        
        ret

; ************************************************************************
; Вывести содержимое регистра дорожки ВГ93
; ************************************************************************
ShowTrackReg
        ; lxi     h, aPosTrackReg
        ; call    PrintString
        
        lxi     b, 3828h
        mvi     a, 2
        sta     PrintColor
        in      PORT_TRACK
        call    _PrintHex
        ; call    PrintBinary
        
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
        ; db      ESC, '6', '4'
        ; db      ESC, '42'
        ; db      ESC, '8', 03
        ; dw      CRLF
        db      ESC, 5, 22h, 20h
        db      '0 - Select drive 0' \ dw CRLF
        db      '1 - Select drive 1' \ dw CRLF
        db      'M - Motor' \ dw CRLF
        db      'R - Seek to track 00' \ dw CRLF
        db      'E - Seek to track 79' \ dw CRLF
        db      '-/+ - Step Out / Step In' \ dw CRLF
        db      'L/U - Lower Side / Upper Side' \ dw CRLF
        db      'ESC - Quit', \ dw CRLF
        
        ; db      ESC, '5', 20h, 20h, "Pops!"
        
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
        
vPortFloppy     db      0
vSide           db      0

; Цвет выводимых символов
PrintColor      db      3

; Внутренний клипборд для символа из шрифта
TempChar        ds      16
