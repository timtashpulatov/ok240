	.project read

HEXOUT          equ     0e003h
COUT            equ     0e00ch
RIN             equ     0e00fh

LENGTH          equ     0b208h  ; use CPP command buffer as var storage  
PARAM           equ     0b20ch  ; optional param after 'READ ' command

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
        jz      Done
Error:        
        lxi     de, ERR
        jmp     PrintDE
Done:   

; Print number of bytes received (in hex)
        lhld    LENGTH
        push    hl
        mov     a, h
        call    HEXOUT
        mov     a, l
        call    HEXOUT

        lxi     de, BytesRead
        call    PrintDE
        pop     hl

; Calculate number of blocks
        mov     a, l
        adi     0ffh
        mov     a, h
        aci     0
        push    psw
        call    HEXOUT

        lxi     de, BlocksRead
        call    PrintDE
        pop     psw

; See if optional filename was given
        call    fillfcb0
        call    setdisk

        lda     COMFCB+1
        cpi     ' '
        jz     Done1

; Create new file
        lxi     d, COMFCB
        mvi     c, F_MAKE
        call    BDOS

; Set DMA address
        lxi     d, 0100h
        mvi     c, SETDMA
        call    BDOS

; Write one sector
        lxi     d, COMFCB
        mvi     c, F_WRITE
        call    BDOS

; Close file
        lxi     d, COMFCB
        mvi     c, F_CLOSE
        call    BDOS

Done1:
        mvi     c, P_TERMCPM
        jmp     BDOS

BytesRead:
        db      'h bytes (','$'
BlocksRead:
        db      ' blocks)',CR,LF,'$'
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
	.project read

HEXOUT          equ     0e003h
COUT            equ     0e00ch
RIN             equ     0e00fh

LENGTH          equ     0b208h  ; use CPP command buffer as var storage  
PARAM           equ     0b20ch  ; optional param after 'READ ' command

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


        .org    0dd1ch  ; Start address of READ user command in REL.8 ROM        

        ; .org 100h

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
        jmp     PrintDE
Done:   

; Print number of bytes received (in hex)
        lhld    LENGTH
        push    hl
        mov     a, h
        call    HEXOUT
        mov     a, l
        call    HEXOUT

        lxi     de, BytesRead
        call    PrintDE
        pop     hl

; Calculate number of blocks
        mov     a, l
        adi     0ffh
        mov     a, h
        aci     0
        push    psw
        call    HEXOUT

        lxi     de, BlocksRead
        call    PrintDE
        pop     psw



; See if optional parameters are given
        lda     PARAM
        cpi     ' '
        jnz     Done1

        mvi     a, '$'
        sta     PARAM+12
        lxi     de, PARAM+1
        call    PrintDE

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

; Set DMA address
        lxi     d, 0100h
        mvi     c, SETDMA
        call    BDOS

; Write one sector
        lxi     d, FCB
        mvi     c, F_WRITE
        call    BDOS

; Close file
        lxi     d, FCB
        mvi     c, F_CLOSE
        call    BDOS

Done1:
        mvi     c, P_TERMCPM
        jmp     BDOS

BytesRead:
        db      'h bytes (','$'
BlocksRead:
        db      ' blocks)',CR,LF,'$'
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


FILEEXT_BEGIN:
        db      0,'12345678SAV'
FILEEXT_END:        

GREETING:
        db      CR,LF,'Read HEX from RS232... ','$'

        end

