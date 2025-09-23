        .project io
        .org    100h
 
 ; Read from or write to IO port
 ; If one parameter is given, perform IN <param1> operation
 ; For two parameters, perform OUT <param1>, <param2>
 
        lda     80h     ; FCB
        ora     a
        jnz     PortAddr

        jmp     0b422h  ; CP/M 2.2 REL.8 commerr1 routine

PortAddr:
        ; cpi     3
        ; jnz     Write
        
        lda     82h     ; 1st param first byte
        call    ConvertNibble
        rlc
        rlc
        rlc
        rlc

        mov     c, a
        
        lda     83h
        call    ConvertNibble
        ora     c
        sta     Work+3

PortData:
        lda     85h     ; 2nd param first byte
        call    ConvertNibble
        rlc
        rlc
        rlc
        rlc

        mov     c, a
        
        lda     86h
        call    ConvertNibble
        ora     c
        sta     Work+1
        
        lda     80h
        cpi     3
        jnz     Write

Read:
        mvi     a, 0dbh
        sta     Work+2
        jmp     Work

Write:
        mvi     a, 0d3h
        sta     Work+2

Work:        
        mvi     a, 00
        in      00
        jmp     0e003h


ConvertNibble:
        sui     '0'
        cpi     10
        rc
        sui     7
        ret
        
