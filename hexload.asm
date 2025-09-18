	.project pops

WARMBOOT        equ     0e003h
COUT            equ     0e00ch
RIN             equ     0e00fh

BDOS            equ     5

C_WRITESTR      equ     9

UART_DATA       equ     0a0h
UART_CTRL       equ     0a1h

CR              equ     10
LF              equ     13

        .org    1000h
        

        lxi     de, GREETING
        mvi     c, C_WRITESTR
        call    BDOS
        
WaitForLineBeginning
        call    RIN
        cpi     ':'
        jnz     WaitForLineBeginning
        
        xra     a
        mov     d, a    ; init checksum
        
        call    RIN_BYTE
        jz      EndOfFile
        mov     e, a    ; byte count
        call    RIN_BYTE
        mov     h, a    ; address HI
        call    RIN_BYTE
        mov     l, a    ; address LO
        call    RIN_BYTE
        
        mov     c, e
ReceiveRecord
        call    RIN_BYTE
        mov     m, a
        inx     hl
        dcr     e
        jnz     ReceiveRecord
        
        call    RIN_BYTE        ; checksum
        jnz     Error
        jmp     WaitForLineBeginning
        
EndOfFile:
        call    RIN_BYTE
        call    RIN_BYTE
        call    RIN_BYTE
        call    RIN_BYTE
        jz      Done
Error:        
        lxi     de, ERR
        mvi     c, C_WRITESTR
        call    BDOS
Done:        
        jmp     WARMBOOT
Err:    db      CR,LF,'?Err',CR,LF,'$'        
        
RIN_BYTE:
        push    b
        call    RIN
        call    CharToNibble
        rlc
        rlc
        rlc
        rlc
        mov     c, a
        
        call    RIN
        call    CharToNibble
        ora     c
        mov     c, a
        
        add     d
        mov     d, a
        
        mov     a, c
        pop     b
        ret

CharToNibble:
        sui     30h
        rc
        adi     0e9h
        rc
        adi     6
        jp      CTN
        adi     7
        rc
CTN:
        adi     10
        ora     a
        ret
        
        
GREETING:
        db      CR,LF,'Pops!',CR,LF,'$'
