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
CONOUT          equ     0d60ch
SELDSK          equ     0d61bh
SETTRK          equ     0d61eh
SETSEC          equ     0d621h
SETDMA          equ     0d624h  ; bc = DMA address
READ            equ     0d627h

; CCP vars
v_arg_0         equ     0bfe1h
v_arg_1         equ     0bfe2h
v_arg_2         equ     0bfe3h
v_arg_3         equ     0bfe4h
v_arg_4         equ     0bfe5h


        ; db      'AB'
        ; mov     b, c
        ; mov     b, d
        
; Read block from page 0, address 0
; 
NBYTES          equ     512
DEST_ADDR       equ     8000h


InitUserPort:
        mvi     a, 90h  ; port A input (data). ports B and C output (address and paging)
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

; Graffffffun

; Clear screen
        mvi     c, 1fh
        call    CONOUT
        
; Set color
        lxi     hl, COLOR
        mvi     b, 3
        call    PrintNChars

; Draw line
        lxi     hl, LINE
        mvi     b, 10
        call    PrintNChars



        ; mvi     e, 0    ; drive A:
        ; BDOS(14)        ; reset disk
        
        mvi     c, 0
        call    SELDSK  ; returns DPH in HL, or 0
        
        mvi     c, 0
        call    SETTRK
        
        mvi     c, 1    ; on RAM disk, directory starts here
        call    SETSEC
        
        lxi     bc, 8000h
        call    SETDMA
        
        call    READ
        
; Scan sector for filenames

        lxi     hl, 8000h
Loop
        mov     a, m
        cpi     0e5h
        jz      Done
    
        call    PrintFN
        call    CRLF
        
        lxi     bc, 32  ; dir entry size
        dad     bc
        jmp     Loop
        
Done        
        jmp     0e003h  ; warm boot


PrintFN
        push    bc
        push    hl       
        
        inx     hl
        mvi     b, 8

        call    PrintNChars
        mvi     c, '.'
        call    CONOUT

        mvi     b, 3
        call    PrintNChars
        
        pop     hl
        pop     bc
        ret

PrintNChars
        mov     c, m
        call    CONOUT
        inx     hl
        dcr     b
        rz
        jmp     PrintNChars

CRLF    
        mvi     c, 10
        call    CONOUT
        mvi     c, 13
        jmp     CONOUT
        
LINE    db      27, '2', '0010', 'ff10'

COLOR   db      27, '4', '1'
        
