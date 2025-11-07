	.project fdc
	.org 100h

PORT_CMD        equ     20h
PORT_TRACK      equ     21h
PORT_SECTOR     equ     22h
PORT_DATA       equ     23h
PORT_FLOPPY     equ     25h

DRIVE_0         equ     1 << 0
DRIVE_1         equ     1 << 1
DRIVE_SELECT    equ     1 << 2

CMD_RESTORE     equ     00h
CMD_SEEK        equ     10h

        lxi     d, Help
        mvi     c, 9
        call     5
        
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
        out     PORT_CMDe
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

WaitForKey
        mvi     c, 1
        jmp     5
        
        
Help:   db      'FDC v0.1', 10, 13
        db      'Usage:', '$'
