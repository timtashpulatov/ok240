        .project io
        .org    100h
 
 ; Read from or write to IO port
 ; If one parameter is given, perform IN <param1> operation
 ; For two parameters, perform OUT <param1>, <param2>
 
        lxi     h, 80h  ; FCB
 
        mov     a, m
        ora     a
        jnz     PortAddr

        jmp     0b422h  ; CP/M 2.2 REL.8 commerr1 routine

PortAddr:
        inx     h       ; FCB+1
        inx     h       ; FCB+2
        call    ConvertNibble   ; 1st param first byte
        rlc
        rlc
        rlc
        rlc
        mov     c, a
        
        inx     h       ; FCB+3
        call    ConvertNibble
        ora     c
        sta     Work+3

PortData:
        inx     h       ; FCB+4
        inx     h       ; FCB+5
        call    ConvertNibble   ; 2nd param first byte
        rlc
        rlc
        rlc
        rlc
        mov     c, a
        
        inx     h       ; FCB+6
        call    ConvertNibble
        ora     c
        sta     Work+1
        
        lda     80h     ; FCB
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
        mov     a, m
        sui     '0'
        cpi     10
        rc
        sui     7
        ret
        
