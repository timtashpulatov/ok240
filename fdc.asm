	.project fdc
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

        lxi     d, Help
        mvi     c, 9
        call     5


        mvi     c, '?'
        call    CONOUT

        lxi     h, CurPosTest
        call    PrintString

        
        call    WaitForKey
        

; Select drive 0
        mvi     a, DRIVE_SELECT | DRIVE_0
; Start motor
        out     PORT_FLOPPY
        ori     8
        out     PORT_FLOPPY
        call    WaitForKey
        
; Restore

        mvi     a, CMD_RESTORE
        out     PORT_CMD
        call    WaitForKey

; Seek to track 79
        mvi     a, 0
        out     PORT_TRACK

        mvi     a, 79
        out     PORT_DATA
        
        mvi     a, CMD_SEEK
        out     PORT_CMD
        
        call    WaitForKey

        rst      0

; ************************************************************************
; Запуск двигателя
; ************************************************************************
MotorStart
        lda     vPortFloppy
        out     PORT_FLOPPY
        ori     DRIVE_INIT
        out     PORT_FLOPPY
        ret

; ************************************************************************
; Ожидаение готовности дисковода или остановки двигателя по таймауту
; Возвращает A=00, если не готов или таймаут
; ************************************************************************
WaitForDriveReady      
        in      PORT_FLOPPY
        ani     80h                     ; check MOTST
        rz

        in      PORT_CMD
        ani     80h                     ; 0x80 if drive NOT READY
        jnz     WaitForDriveReady
        
        inr     a                       ; A = 1

        ret



WaitForKey
        mvi     c, 1
        jmp     5


PrintString
        mov     a, m
        ora     a
        rz
        mov     c, a
        call    CONOUT
        inx     h
        jmp PrintString

CurPosTest
        db      1fh
        db      27, '0', 100, 100, 31h
        db      'ABC', 0
        
Help:   db      'FDC v0.1', 10, 13
        db      'Usage:', '$'
        
vPortFloppy     db      0
        
