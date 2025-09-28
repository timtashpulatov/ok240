#define PORTA           00h
#define PORTB           01h
#define PORTC           02h
#define PORT_CTRL       03h

#define PC7             0b10000000

        ; db      'AB'
        ; mov     b, c
        ; mov     b, d

        mvi     a, 0ffh  ; port A input (data). ports B and C output (address and paging)
        out     PORT_CTRL

; Set ROM page (page number in C)
SetPage:        
        mov     a, c
        ani     0fh             ; pages 0..15
        out     PORTC
        ori     0b10000000      ; strobe high
        out     PORTC
        ani     0b01111111      ; strobe low
        out     PORTC

; Address in HL
SetAddress:
        mov     a, l
        out     PORTB           ; address bits A7..A0
        mov     a, h
        ani     7fh
        out     PORTC           ; address bits A14..A8

ReadByte:
        in      PORTA
        ret
