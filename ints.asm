 	.project okeah
	
; Обработчик прерывания от Таймера 0	
	.org 20h
	
	mvi     a, 20h
	out     80h
	
; Полезная работа	

        lda     COLOR
        inr     a
        ani     7
        sta     COLOR
        ori     40h
        
        out     0e1h
	
NOTYET	
        ei
	ret
	
COUNT   dw      0
COLOR   db      41h
	
;	.org 8000h

BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео


; Дождемся кадрового ретрейса
WaitForVR
        in      41h
        ani     2
        jz     WaitForVR
; Переждем его
WaitForVRDone
        in      41h
        ani     2
        jnz     WaitForVRDone
        
        mvi     a, 36h
        out     63h
        mvi     a, 0h
        out     60h
        mvi     a, 05h
        out     60h

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
        mvi     m, 0
        inr     h
        mvi     m, 0
        inr     h
        mvi     m, 0
        inr     h
        mvi     m, 255
        inr     h
        mvi     m, 255
        inr     h
        mvi     m, 0
        inr     h
        mvi     m, 255
        inr     h
        mvi     m, 255
        
        pop     hl
        inr     l
        dcr     c
        jnz     DoPat
        
        xra     a
        out     BANKING
        

        ei

        jmp     .
        
	jmp	0e003h		; теплый старт "Монитора"

