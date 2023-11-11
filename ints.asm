 	.project okeah

BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео

	
; Обработчик прерывания от Таймера 0	
	.org 20h
	
	mvi     a, 20h
	out     80h
	
; Полезная работа	

;        mvi     a, 40h
;        out     VIDEO
;        mvi     a, 41h
;        out     VIDEO
;        mvi     a, 42h
;        out     VIDEO
;        mvi     a, 43h
;        out     VIDEO
;        mvi     a, 40h
;        out     VIDEO;

        lda     COLOR
        inr     a
        sta     COLOR
        
        ani     3fh
        
        ori     40h
        
        out     VIDEO
        
        
	
NOTYET	
        ei
	ret
	
COUNT   dw      0
COLOR   db      41h
	
;	.org 8000h



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
WaitForVR1
        in      41h
        ani     2
        jz     WaitForVR1

WaitForHR
        in      41h
        ani      1
        jz      WaitForHR


        
        mvi     a, 36h
        out     63h
        mvi     a, 0h
        out     60h
        mvi     a, 03h		; делитель на 768 тактовой частоты 1.5МГц канала 0 таймера даст смену палитры каждые 8 строк (ivagor)
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
        
	jmp	0e003h		; теплый старт "Монитора"

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
        mvi     m, 255
        inr     h
        mvi     m, 255
        inr     h
        mvi     m, 255
        inr     h

        ret

