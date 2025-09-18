	.project read.hex

WARMBOOT        equ     0e003h
COUT            equ     0e00ch
RIN             equ     0e00fh

FCB             equ     5ch

BDOS            equ     5

P_TERMCPM       equ     0
C_WRITESTR      equ     9
F_CLOSE         equ     16
F_WRITE         equ     21
F_MAKE          equ     22

SETDMA          equ     26


UART_DATA       equ     0a0h
UART_CTRL       equ     0a1h

CR              equ     10
LF              equ     13

        .org    08000h
;       .org    0dd1ch  ; Start address of READ user command in REL.8 ROM        

#ifdef pops
        lxi     de, GREETING
        mvi     c, C_WRITESTR
        call    BDOS
        
; Fill FCB
        lxi     h, FCB
        push    h
        
        mvi     c, FILEEXT_END-FILEEXT_BEGIN
        lxi     de, FILEEXT_BEGIN
SetFileNameInFCB:
        ldax    d
        mov     m, a
        inx     d
        inx     h
        dcr     c
        jnz     SetFileNameInFCB

; Make new file
        lxi     d, FCB
        mvi     c, F_MAKE
        call    BDOS
        
; Write some garbage
; Set DMA address
        lxi     d, 0c000h
        mvi     c, SETDMA
        call    BDOS

; Write one sector
        lxi     d, FCB
        mvi     c, F_WRITE
        call    BDOS

; Write another sector
        lxi     d, 0c080h
        mvi     c, SETDMA
        call    BDOS


        lxi     d, FCB
        mvi     c, F_WRITE
        call    BDOS
        
; Close file
        lxi     d, FCB
        mvi     c, F_CLOSE
        call    BDOS
        
        jmp     Done

#endif
        
WaitForLineBeginning
        call    RIN
        cpi     ':'
        jnz     WaitForLineBeginning
        
        xra     a
        mov     d, a    ; init checksum
        
        call    RIN_BYTE        ; byte count
        jz      EndOfFile
        mov     e, a    
        call    RIN_BYTE        ; address HI
        mov     h, a    
        call    RIN_BYTE        ; address LO
        mov     l, a    
        call    RIN_BYTE        ; record type
        
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
        mvi     c, P_TERMCPM
        jmp     BDOS

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
        
#ifdef pops        
        
GREETING:
        db      CR,LF,'Pops!',CR,LF,'$'
FILEEXT_BEGIN:
        db      0,'12345678SAV'
FILEEXT_END:        

#endif

        end
