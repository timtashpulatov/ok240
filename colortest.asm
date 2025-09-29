	.project okeah
	.org 8000h
VSCROLL equ     0c0h            ; vertical scroll
BANKING	equ	0c1h		; регистр управления банками ОЗУ и ПЗУ
VHSCROLL equ    0c2h            ; vertical and horisontal scroll
VIDEO	equ	0e1h		; регистр управления цветом и режимами видео

CI      equ     0e009h
CO      equ     0e00ch          ; print character from A


; Reset scroll
        xra     a
        out     VSCROLL
        out     VHSCROLL

; Set palette 0, color mode
        mvi     a, 0b01000000
        out     VIDEO


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
        lxi     h, 4810h
        call    DrawTestBars

        lxi     h, 4830h
        call    DrawTestBars

        lxi     h, 4850h
        call    DrawTestBars

        lxi     h, 4870h
        call    DrawTestBars

        lxi     h, 4890h
        call    DrawTestBars

        lxi     h, 48b0h
        call    DrawTestBars

        lxi     h, 48d0h
        call    DrawTestBars

	xra	a		; экран размалеван
	out	BANKING		; возвращаем его на место


; Print labels
        lxi     h, LABEL
        call    PrintString




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

LABEL:  ; db      ESC, '60'       ; Color mode (61 = mono)
        db      ESC, '40'
        db      '00 '
        db      ESC, '41'
        db      '01 '
        db      ESC, '42'
        db      '02 '
        db      ESC, '43'
        db      '03 '
        db      0
