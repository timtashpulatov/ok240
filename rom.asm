
#define PORTA           00h
#define PORTB           01h
#define PORTC           02h
#define PORT_CTRL       03h


        ; db      'AB'
        ; mov     b, c
        ; mov     b, d

        mvi     a, 0ffh  ; port A input (data). ports B and C output (address and paging)
        out     PORT_CTRL

; Address in HL
SetAddress:
        mov     a, l
        out     PORTB
        mov     a, h
        out     PORTC

; Set ROM page (page number in C)
SetPage:        
        mov     a, c
        ani     0b01111111
        out     PORTC
        ori     0b10000000
        out     PORTC
        ani     0b01111111
        out     PORTC

ReadByte:
        in      PORTA
        ret
