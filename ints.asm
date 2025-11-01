 	.project okeah

BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео

; делитель на 768 тактовой частоты 1.5МГц канала 0 таймера даст смену палитры каждые 8 строк (ivagor)

; DIV     equ     01e0h    ;       = 480  = 5 lines
; 5 * 64us = 320us
; 1500000 / 15625 = 96 = 1 line
;

DIV     equ     768     ; 768 = 8 lines


	.org    100h

; Clear scroll
        ; mvi     a, 0
        ; out     0c0h
        ; out     0c2h

; ; Timer programming, part I
;         mvi     a, 36h
;         out     63h
;         mvi     a, DIV & 0xff
;         out     60h


; Дождемся кадрового ретрейса
        lxi     b, 0002
WaitForVR
        in      41h
        ana     c
        jz     WaitForVR
; Переждем его
WaitForVRDone
        in      41h
        ana     c
        jnz     WaitForVRDone
WaitForVR1
        in      41h
        ana     c
        jz     WaitForVR1

; WaitForHR
;         in      41h
;         ani      1
;         jz      WaitForHR

; Timer programming, part I
        mvi     a, 36h
        out     63h
        mvi     a, DIV & 0xff
        out     60h

; Timer programming, part II
        mvi     a, DIV >> 8
        out     60h

; Plant interrupt handler
        mvi     a, 0xc3
        sta     0x20
        lxi     h, TimerInterruptHandler
        shld    0x21

; OCW1
        mvi     a, 0b11101111   ; разрешить прерывания от Таймера 0 (RST4)
        out     81h

; Pattern
        mvi     a, 10h
        out     BANKING
        
        lxi     hl, 0c000h
        mvi     c, 254
        
DoPat   
        push    hl
        call    DoPatSub
        call    DoPatSub        
        call    DoPatSub        
        call    DoPatSub        
        pop     hl
        inr     l
        dcr     c
        jnz     DoPat
        
        xra     a
        out     BANKING
        

        ei

        jmp     .

DoPatSub
        mvi     m, 0
        inr     h
        mvi     m, 0
        inr     h

        mvi     m, 255
        inr     h
        mvi     m, 0
        inr     h

        mvi     m, 0
        inr     h
        mvi     m, 0
        inr     h

        mvi     m, 0
        inr     h
        mvi     m, 255
        inr     h

        mvi     m, 0
        inr     h
        mvi     m, 0
        inr     h

        mvi     m, 255
        inr     h
        mvi     m, 255
        inr     h

        ret
        
; Обработчик прерывания от Таймера 0	
; 	.org 20h
TimerInterruptHandler
        push    a
        lda     COLOR
        out     VIDEO

; используем счетчик для выборки очередной палитры
        push    hl

        lhld    COUNT
        inx     h
        mvi     a, COUNT & 0xff
        cmp     l
        jnz     Next
        lxi     h, PALETTE_LIST
Next
        shld    COUNT

        mov     a, m
        sta     COLOR

        pop     hl

; подтверждение прерывания        
	mvi     a, 20h
	out     80h
	pop     a
        ei
	ret


PALETTE_LIST

; Tile lines 12..15
        db      4ch, 4dh, 4eh, 4fh          ; color, blue background
; Tile lines 16..23        
        db      50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h          ; color, green background
; Tile lines 24..31
        db      38h, 39h, 3ah, 3bh, 3ch, 3dh, 3eh, 3fh          ; mono, white background

        ; Retrace zone (tile lines 32..39)        
        db      47h, 47h, 47h, 47h, 47h, 47h, 47h, 47h

; Tile lines 0..7
        db      40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h          ; color, black background
; Tile lines 8..11
        db      48h, 49h, 4ah, 4bh                              ; color, blue background



COUNT   dw      PALETTE_LIST

COLOR   db      40h
        
        
        
