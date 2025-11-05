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
        ; db      50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h          ; color, green background
        db      40h, 48h, 50h, 58h, 60h, 68h, 70h, 78h
; Tile lines 24..31
        db      00h, 08h, 10h, 18h, 20h, 28h, 30h, 38h          ; mono, white background

        ; Retrace zone (tile lines 32..39)        
        db      47h, 47h, 47h, 47h, 47h, 47h, 47h, 47h

; Tile lines 0..7
        db      40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h          ; color, black background
; Tile lines 8..11
        db      48h, 49h, 4ah, 4bh                              ; color, blue background



COUNT   dw      PALETTE_LIST

COLOR   db      40h

; OKEAH
; 240
;00000000:  3E 77 77 77 7F 7F 7F 00 00 00 00 00 00 00 00 00
;00000010:  36 77 7F 3F 77 77 77 00 00 00 00 00 00 00 00 00
;00000020:  3E 6F 6F 7F 0F 7F 7F 00 00 00 00 00 00 00 00 00
;00000030:  3E 7B 7B 7F 7F 7B 7B 00 00 00 00 00 00 00 00 00
;00000040:  36 77 7F 7F 77 77 77 00 00 00 00 00 00 00 00 00
;00000050:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;00000060:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;00000070:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;00000080:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;00000090:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;000000A0:  7F 7F 70 7F 7F 07 7F 7F 00 00 00 00 00 00 00 00
;000000B0:  77 77 77 7F 7F 70 70 70 00 00 00 00 00 00 00 00
;000000C0:  7F 77 77 77 77 77 77 7F 00 00 00 00 00 00 00 00
;000000D0:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;000000E0:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
;000000F0:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        
        
