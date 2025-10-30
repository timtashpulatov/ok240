 	.project okeah

BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео

; делитель на 768 тактовой частоты 1.5МГц канала 0 таймера даст смену палитры каждые 8 строк (ivagor)

; DIV     equ     01e0h    ;       = 480  = 5 lines
; 5 * 64us = 320us
; 1500000 / 15625 = 96 = 1 line
;

DIV     equ     768     ; = 8 lines


	.org    100h

; Clear scroll
        ; mvi     a, 7
        ; out     0c0h
        ; out     0c2h

; Timer programming, part I
        mvi     a, 36h
        out     63h
        mvi     a, DIV & 0xff
        out     60h


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
        mvi     c, 250
        
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
        lda     COLOR
        out     VIDEO
        ; inr     a
        ; ; ani     3fh
        ; ani     7
        ; ; ori     40h
        ; ori     48h
        ; sta     COLOR
        
; счетчик
        lda     COUNT
        inr     a
        ani     15
        sta     COUNT

; используем счетчик для выборки очередной палитры
        push    hl
        push    bc
        
        lxi     hl, PALETTE_LIST
        lxi     bc, 0
        lda     COUNT
        mov     c, a
        dad     b
        mov     a, m
        sta     COLOR
        
        pop     bc
        pop     hl

; подтверждение прерывания        
	mvi     a, 20h
	out     80h
        ei
	ret

PALETTE_LIST
        db      40h, 40h, 42h, 43h, 44h, 45h, 46h, 47h
        db      48h, 48h, 49h, 49h, 4ah, 4ah, 4bh, 4bh
        db      40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h
        db      40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h


COUNT   db      0
COLOR   db      40h
        
        
        
