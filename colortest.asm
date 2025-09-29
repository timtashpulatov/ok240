	.project okeah
	
VSCROLL equ     0c0h            ; vertical scroll
BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VHSCROLL equ    0c2h            ; vertical and horisontal scroll
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео

CI      equ     0e009h
CO      equ     0e00ch          ; print character from A


; Обработчик прерывания от Таймера 0	
	.org 20h
	
        push    hl
        push    bc
     
        lxi     hl, PLIST
        mvi     b, 0
        lda     COUNT
        mov     c, a
        dad     b
        mov     a, m
        out     VIDEO
        
        inr     c
        mov     a, c
        ani     15
        
        sta     COUNT
        
	mvi     a, 20h
	out     80h
	
	pop     bc
	pop     hl
	
        ei
	ret
	
COUNT:   db      0
; Palette list
PLIST:  
        db      40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h
        db      48h, 50h, 58h, 60h, 68h, 70h, 78h, 0

        .org 8000h

; Reset scroll
        xra     a
        out     VSCROLL
        out     VHSCROLL

        lxi     hl, MODE_60
        call    PrintString


; Set palette 0, color mode
        ; mvi     a, 0b01000000
        ; out     VIDEO


	mvi	a, 01
	out	BANKING		; включить отображение старших 32К на младшие

	xra	a		; очистить аккумулятор
	lxi	h, 4000h	; поместить в HL адрес начала экранной области

	lxi	b, 256*64	; экран в "Океане" состоит из вертикальных столбиков по 256 байт в каждом
Loop:	mvi	m, 0
	inx 	h		; двигаться дальше
	dcx 	b		; внимательно следим за длиной столбика
	mov	a, b		; если столбик 
	ora	c		; не дорисован
	jnz	Loop		; продолжаем писать в экран труху


; Color bars
        lxi     h, 4410h
        call    DrawTestBars

        lxi     h, 4c10h
        call    DrawTestBars


        lxi     h, 4430h
        call    DrawTestBars

        lxi     h, 4450h
        call    DrawTestBars

        lxi     h, 4470h
        call    DrawTestBars

        lxi     h, 4490h
        call    DrawTestBars

        lxi     h, 44b0h
        call    DrawTestBars

        lxi     h, 44d0h
        call    DrawTestBars

	xra	a		; экран размалеван
	out	BANKING		; возвращаем его на место


; Print labels
        lxi     h, LABEL
        call    PrintString


; Video interrupts fun

; Init timer
        lxi     h, 01e0h  * 4      ; делитель на 768 тактовой частоты 1.5МГц канала 0 таймера даст смену палитры каждые 8 строк (ivagor)
        
        mvi     a, 36h
        out     63h

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
        ani     1
        jz      WaitForHR

; Finish timer init        
        mov     a, l
        out     60h
        mov     a, h		
        out     60h

; OCW1
        mvi     a, 0b11101111   ; разрешить прерывания от Таймера 0 (RST4)
        out     81h

        ei
        
        jmp     .




Key:	
;         inr	a		; не пропадать же аккумулятору
; 	ani	3fh		; возьмем из него три младших бита переднего плана
; 	ori	40h		; и три старших бита фона
; 	out	VIDEO		; и намажем на кадр

	call	CI		; подождем ввода символа с клавиатуры
	cpi	1bh		; если это не Esc,
	jnz	Key		; продолжим интерактивную раскраску

	jmp	0e003h		; теплый старт "Монитора"

PrintString:
        mov     a, m
        ora     a
        rz
        mov     c, a
        call    CO
        inx     hl
        jmp     PrintString

DrawTestBars:

        lxi     bc, 0000h       ; B = color bits 1, C = color bits 0
        mvi     d, 24
        call    Strip2
        
        lxi     bc, 0ff00h      ; color 01 (RED in journal palette 0)
        mvi     d, 24
        call    Strip2

        lxi     bc, 00ffh       ; color 02 (GREEN)
        mvi     d, 24
        call    Strip2

        lxi     bc, 0ffffh      ; color 03 (BLUE)
        mvi     d, 24
        call    Strip2

        ret


Strip2:
        push    hl

StripLoop:
                mov     m, b
                push    hl
                        inr     h
                        mov     m, c
                pop     hl
                inx     hl
                dcr     d
                jnz     StripLoop
                
        pop     hl
        inr     h
        inr     h
        ret

ESC     equ     1bh

COLOR_0 db      ESC, '40', 0
COLOR_1 db      ESC, '41', 0
COLOR_2 db      ESC, '42', 0
COLOR_3 db      ESC, '43', 0

MODE_60 db      ESC, '60', 0
MODE_61 db      ESC, '61', 0
MODE_62 db      ESC, '62', 0

LABEL:  ; db      ESC, '60'       ; Color mode (61 = mono)
        db      ESC, '40'
        db      '00 '
        db      ESC, '41'
        db      '01 '
        db      ESC, '42'
        db      '02 '
        db      ESC, '43'
        db      '03 '
        db      0        ;
        
        
        
