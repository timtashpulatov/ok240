        .project rom.com
        .org    100h

#define bdos            5

#define BDOS(fn) mvi c, fn \ call bdos
#define WRITESTR(str) lxi d, str \ BDOS(9)

#define PORTA           00h
#define PORTB           01h
#define PORTC           02h
#define PORT_CTRL       03h

#define PC7             0b10000000

#define WBOOT           0e003h


; Internal CP/M calls
SELDSK          equ     0d61bh
SETTRK          equ     0d61eh
SETSEC          equ     0d621h
SETDMA          equ     0d624h  ; bc = DMA address
READ            equ     0d627h

        ; db      'AB'
        ; mov     b, c
        ; mov     b, d
        
; Read block from page 0, address 0
; 
NBYTES          equ     512
DEST_ADDR       equ     8000h


InitUserPort:
        mvi     a, 0ffh  ; port A input (data). ports B and C output (address and paging)
        out     PORT_CTRL

        xra     a
        mov     h, a
        mov     l, a
        lxi     bc, 807fh       ; b = strobe high, c = strobe low
; Set ROM page (page number in A)
SetPage:        
        ; ani     0fh             ; pages 0..15
        out     PORTC
        ora     b               ; strobe high
        out     PORTC
        ana     c               ; strobe low
        out     PORTC

ReadLoader:        
        lxi     de, DEST_ADDR
        lxi     bc, NBYTES

ReadBlockLoop:
        mov     a, l
        out     PORTB           ; address bits A7..A0
        mov     a, h
        ani     7fh
        out     PORTC           ; address bits A14..A8
        in      PORTA

        stax    d
        inx     de
        inx     hl
        dcx     bc
        mov     a, b
        ora     c
        jnz     ReadBlockLoop
        
        jmp     WBOOT
        
        
        .org    200h

        ; mvi     e, 0    ; drive A:
        ; BDOS(14)        ; reset disk
        
        mvi     c, 0
        call    SELDSK  ; returns DPH in HL, or 0
        
        mvi     c, 0
        call    SETTRK
        
        mvi     c, 0
        call    SETSEC
        
        lxi     bc, 8000h
        call    SETDMA
        
        call    READ
        
        
        
        jmp     0e003h  ; warm boot


