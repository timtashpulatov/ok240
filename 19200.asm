        .project 19200
        .org    100h
 
 ; Set UART clock to 19200
 ; Fosc = 12,228,000 Hz
 ; 
 
        mvi     a, 5
        out     61h
        mvi     a, 0
        out     61h
        rst     0
 
