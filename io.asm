        .project io
        .org    100h
 
 ; Read from or write to IO port
 ; If one parameter is given, perform IN <param1> operation
 ; For two parameters, perform OUT <param1>, <param2>
 
        lda     80h     ; FCB+1
        ora     a
        jnz     In


        jmp     0b422h  ; CP/M 2.2 REL.8 commerr1 routine

;         lxi     de, Help
;         mvi     c, 9
;         call    BDOS
;         rst     0
; Help:
;         db      '?', 13, 10, '$'

In:
        cpi     3
        jnz     Out

Out:
        rst     0
