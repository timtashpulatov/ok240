S	.project fdc
	.org 100h

CONST           equ     0e006h  ; A = FF if there is keypress
CONIN           equ     0e009h  
CONOUT          equ     0e00ch  ; output symbol from C

PORT_CMD        equ     20h
PORT_TRACK      equ     21h
PORT_SECTOR     equ     22h
PORT_DATA       equ     23h
PORT_FLOPPY     equ     25h

DRIVE_0         equ     1 << 0
DRIVE_1         equ     1 << 1
DRIVE_SELECT    equ     1 << 2
DRIVE_INIT      equ     1 << 3

CMD_RESTORE     equ     00h
CMD_SEEK        equ     10h
CMD_STEPIN      equ     40h     ; towards center and track 79
CMD_STEPOUT     equ     60h     ; to track 0


ESC             equ     27
CRLF            equ     00d0ah

        ; lxi     d, Help
        ; mvi     c, 9
        ; call     5


        ; mvi     c, '?'
        ; call    CONOUT

        lxi     h, MainMenu
        call    PrintString


MenuLoop

        ; call    WaitForKey
        
        call    CONST
        inr     a
        jz      WeHaveKeypress
        
        call    ShowFloppyPort
        call    ShowStatusPort
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
        db      ESC \ dw Quit
        db      0 \ dw 0

Quit    rst     0        

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
        mvi     a, CMD_STEPOUT
        out     PORT_CMD
        ret
StepOut
        call    _StepOut
        jmp     MenuLoop

_StepIn
        mvi     a, CMD_STEPIN
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
        lxi     h, aPosStatusPort
        call    PrintString

        in      PORT_CMD
        call    PrintBinary
        
        ret


; ************************************************************************
; Напечатать А в двоичной форме
; ************************************************************************
PrintBinary
        mvi     l, 8
BitsLoop
        mvi     c, '0'
        ral
        jc      BL1
        inr     c
BL1
        push    h
        push    a
        call    CONOUT
        pop     a
        pop     h
        
        dcr     l
        jnz     BitsLoop
        
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
        ; db      1fh
        ; db      ESC, '61'
        ; db      ESC, '8b'
        ; dw      CRLF
        db      ESC, 5, 22h, 20h
        db      '0 - Select drive 0' \ dw CRLF
        db      '1 - Select drive 1' \ dw CRLF
        db      'M - Motor' \ dw CRLF
        db      'S - Side' \ dw CRLF
        db      'R - Seek to track 00' \ dw CRLF
        db      'E - Seek to track 79' \ dw CRLF
        db      'ESC - Quit', \ dw CRLF
        
        ; db      ESC, '5', 20h, 20h, "Pops!"
        
        db      0
        
aPosFloppyPort
        db      ESC, 5, 20h, 20h+24, 0
aPosStatusPort
        db      ESC, 5, 20h+2, 20h+24, 0
        
vPortFloppy     db      0
        
