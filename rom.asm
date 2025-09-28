#define PORTA           00h
#define PORTB           01h
#define PORTC           02h
#define PORT_CTRL       03h

#define PC7             0b10000000

        ; db      'AB'
        ; mov     b, c
        ; mov     b, d
InitUserPort:
        mvi     a, 0ffh  ; port A input (data). ports B and C output (address and paging)
        out     PORT_CTRL
        ret

; Set ROM page (page number in A)
SetPage:        
        ani     0fh             ; pages 0..15
        out     PORTC
        ori     0b10000000      ; strobe high
        out     PORTC
        ani     0b01111111      ; strobe low
        out     PORTC
        ret

; Address in HL
SetAddress:
        mov     a, l
        out     PORTB           ; address bits A7..A0
        mov     a, h
        ani     7fh
        out     PORTC           ; address bits A14..A8
        ret

ReadByte:
        in      PORTA
        ret

; Read block from page 0, address 0
; 
BLOCK_LEN       equ     512
DEST_ADDR       equ     100h
ReadLoader:
        call    InitUserPort
        xra     a
        call    SetPage
        lxi     de, DEST_ADDR
        lxi     bc, BLOCK_LEN

ReadBlockLoop:
        call    SetAddress
        call    ReadByte        ; TODO join with SetAddress
        stax    d
        inx     de
        dcx     bc
        mov     a, b
        ora     c
        jnz     ReadBlockLoop
        ret
