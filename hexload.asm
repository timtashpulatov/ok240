	.project read

HEXOUT          equ     0e003h
COUT            equ     0e00ch
RIN             equ     0e00fh

LENGTH          equ     0b208h  ; use CPP command buffer as var storage
SECTORS           equ     0b20ah  ; ditto
PTR             equ     0b20bh  ; write pointer

FCB             equ     5ch

; specific for CP/M 2.2 REL.8 CCP
fillfcb0        equ     0b45eh
setdisk         equ     0b654h

COMFCB          equ     0b9cdh


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


        .org    0dd1ch  ; Start address of READ user command in REL.8 ROM        

        ; .org 100h

        lxi     de, GREETING
        call    PrintDE

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
        jz      FileReceived
Error:        
        lxi     de, ERR
        jmp     PrintDE

FileReceived:
; Print number of bytes received (in hex) 
        lhld    LENGTH
        mov     a, h
        call    HEXOUT
        mov     a, l
        call    HEXOUT

        lxi     de, BytesRead
        call    PrintDE

; Calculate number of pages
; "<pages> is the number of 256 byte pages starting at address 100(h) to save"
; 1 256-byte page = 2 128 byte sectors
        lhld    LENGTH
        mov     a, l
        adi     0ffh
        mov     a, h
        aci     0
        ral
        sta     SECTORS
        call    HEXOUT
 
        lxi     de, PagesRead
        call    PrintDE

; See if optional filename was given
        call    fillfcb0
        call    setdisk

        lda     COMFCB+1
        cpi     ' '
        jz     Done

; Create new file
        lxi     d, COMFCB
        mvi     c, F_MAKE       ; Returns A=0FFh if the directory is full
        call    BDOS
        inr     a
        jz      Error

        lxi     h, 0100h
        shld    PTR

WriteSectors:
; Set DMA address
        lhld    PTR
        xchg
        mvi     c, SETDMA
        call    BDOS

; Write one sector
        lxi     d, COMFCB
        mvi     c, F_WRITE
        call    BDOS
        
        ora      a
        jnz     Error

        lhld    PTR
        lxi     d, 128
        dad     d
        shld    PTR

        lda     SECTORS
        dcr     a
        sta     SECTORS
        jnz     WriteSectors

; Close file
        lxi     d, COMFCB
        mvi     c, F_CLOSE
        call    BDOS
        
        cpi     0ffh
        jz      Error

Done:
        mvi     c, P_TERMCPM
        jmp     BDOS

BytesRead:
        db      'h bytes (','$'
PagesRead:
        db      ' pages)',CR,LF,'$'
Err:    db      'error!',CR,LF,'$'        
        
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

GREETING:
        db      CR,LF,'Read HEX from RS232... ','$'

        end        
