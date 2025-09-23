        .project io
        .org    100h
 
 ; Read from or write to IO port
 ; If one parameter is given, perform IN <param1> operation
 ; For two parameters, perform OUT <param1>, <param2>
 
        lda     80h     ; FCB
        ora     a
        jnz     Read

        jmp     0b422h  ; CP/M 2.2 REL.8 commerr1 routine

Read:
        cpi     3
        jnz     Write
        
        lda     82h     ; first param first byte
        call    ConvertNibble
        rlc
        rlc
        rlc
        rlc

        mov     c, a
        
        lda     83h
        call    ConvertNibble
        ora     c
        sta     In+1
        
In:
        in      00
        jmp     0e003h

Write:
        rst     0

ConvertNibble:
        sui     '0'
        cpi     10
        rc
        sui     7
        ret
