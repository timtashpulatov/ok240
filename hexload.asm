	.project read

HEXOUT          equ     0e003h
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


        ; .org    0dd1ch  ; Start address of READ user command in REL.8 ROM        

        .org 100h

        lxi     de, GREETING
        call    PrintDE

#ifdef pops
        
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
        
LENGTH  equ     0b208h        
        
        lxi     hl, 0
        shld    LENGTH
        
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
        


        push    hl
        lhld    LENGTH
        mov     a, l
        add     e
        mov     l, a
        mov     a, h
        aci     0
        mov     h,a
        shld    LENGTH
        pop     hl
        
        
        
        
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
        call    PrintDE
Done:        
        lhld    LENGTH
        mov     a, h
        call    HEXOUT
        mov     a, l
        call    HEXOUT

        lxi     de, BytesRead
        call    PrintDE

        mvi     c, P_TERMCPM
        jmp     BDOS

BytesRead:
        db      ' bytes.',CR,LF,'$'
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

PrintDE:
        mvi     c, C_WRITESTR
        jmp    BDOS


#ifdef pops        
MyRIN:
        in      0a1h
        ani     2
        jz      Machine
        
        in      0a0h
        ani     7fh
        ret
        
Machine:
        in      0e1h
        xri     38h
        out     0e1h

        jmp     MyRIN
        
FILEEXT_BEGIN:
        db      0,'12345678SAV'
FILEEXT_END:        
#endif

GREETING:
        db      CR,LF,'Read HEX from RS232... ','$'

        end
