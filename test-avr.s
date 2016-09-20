;.INCLUDE "def/m8def.inc"
.INCLUDE "def/m32def.inc"

.ORG 0x00
reset:
rjmp main
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;
rjmp defaultInt;

defaultInt:
	reti

main:
	; --------------------------------------------------
	; INIT
	; --------------------------------------------------

	cli				; Disable interrupts

	; init stack
	ldi	r16, HIGH(RAMEND) 	; Upper byte
	out	SPH, r16		; to stack pointer
	ldi	r16, LOW(RAMEND) 	; Lower byte
	out	SPL, r16		; to stack pointer

	; init r0 risc style
	clr	r0

	sei

	; --------------------------------------------------
	; TESTS
	; --------------------------------------------------

	rcall	test_ret
.if FLASHEND > 0x0fff
	call	test_ret
.endif
	rcall	test_reti
	rcall	test_adc
	rcall	test_bclr
	rcall	test_cp
	rcall	test_asr

	rjmp end

; -----------------------------------------------------------------------------
; RCALL/CALL/RET
; -----------------------------------------------------------------------------

test_ret:
	ret

; -----------------------------------------------------------------------------
; RCALL/CALL/RETI
; -----------------------------------------------------------------------------

test_reti:
	reti

; -----------------------------------------------------------------------------
; ADC
; -----------------------------------------------------------------------------

test_adc:
	clr	r25
	clr	r31

	; ==> 0 + 0 + C(1) = 1
	sec
	ldi	r24, 0
	ldi	r26, 0
	ldi	r29, 0x80	; SREG (I)
	ldi	r30, 0x01	; EXPECTED RESULT
	adc	r24, r26
	rcall	check_res

	; ==> 0 + 0 + C(0) = 0
	clc
	ldi	r24, 0
	ldi	r26, 0
	ldi	r29, 0x82	; SREG (IZ)
	ldi	r30, 0x00	; EXPECTED RESULT
	adc	r24, r26
	rcall	check_res

	; ==> 100 + -1 + C(1) = 100
	sec
	ldi	r24, 100
	ldi	r26, -1
	ldi	r29, 0xa1	; SREG (IHC)
	ldi	r30, 100	; EXPECTED RESULT
	adc	r24, r26
	rcall	check_res

	; ==> 0 + -1 + C(1) = 0
	sec
	ldi	r24, 0
	ldi	r26, -1
	ldi	r29, 0xa1	; SREG (IHC)
	ldi	r30, 0		; EXPECTED RESULT
	adc	r24, r26
	rcall	check_res

	; ==> 0 + -1 + C(0) = 0
	clc
	ldi	r24, 0
	ldi	r26, -1
	ldi	r29, 0x94	; SREG (INV)
	ldi	r30, -1		; EXPECTED RESULT
	adc	r24, r26
	rcall	check_res

	ret;

; -----------------------------------------------------------------------------
; ASR
; -----------------------------------------------------------------------------

test_asr:
	clr	r25
	clr	r26
	clr	r31

	; ==> 0 >> 1
	ldi	r24, 0
	ldi	r29, 0x82	; SREG (I)
	ldi	r30, 0x00	; EXPECTED RESULT
	asr	r24
	rcall	check_res

	; ==> 2 >> 1
	ldi	r24, 2
	ldi	r29, 0x80	; SREG (I)
	ldi	r30, 0x01	; EXPECTED RESULT
	asr	r24
	rcall	check_res

	; ==> 3 >> 1
	ldi	r24, 3
	ldi	r29, 0x99	; SREG (I)
	ldi	r30, 1		; EXPECTED RESULT
	asr	r24
	rcall	check_res

	; ==> 0x80 >> 1
	ldi	r24, 0x80
	ldi	r29, 0x8c	; SREG (I)
	ldi	r30, 0xc0	; EXPECTED RESULT
	asr	r24
	rcall	check_res

	; ==> 0x81 >> 1
	ldi	r24, 0x81
	ldi	r29, 0x95	; SREG (I)
	ldi	r30, 0xc0	; EXPECTED RESULT
	asr	r24
	rcall	check_res

	ret

; -----------------------------------------------------------------------------
; BCLR
; -----------------------------------------------------------------------------

test_bclr:
	; clear result/expected result registers (r25:24, r31:30)
	clr	r24
	clr	r25
	clr	r30
	clr	r31

	ldi	r16, 0xff
	out	SREG, r16
	ldi	r29, (0xff & ~0x1)
	bclr	0
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0x3)
	bclr	1
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0x7)
	bclr	2
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0xf)
	bclr	3
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0x1f)
	bclr	4
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0x3f)
	bclr	5
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0x7f)
	bclr	6
	rcall	check_res
	out	SREG, r29
	ldi	r29, (0xff & ~0xff)
	bclr	7
	rcall	check_res

	sei
	ret

; -----------------------------------------------------------------------------
; CP
; -----------------------------------------------------------------------------

test_cp:
	clr	r25
	clr	r31

	; 5 == 5
	ldi	r16, 5
	ldi	r17, 5
	ldi	r30, 5
	ldi	r31, 0x82
; FAIL
	cp	r16, r17
	rcall	check_res

	; 5 == 6
	ldi	r17, 6
	cp	r16, r17

	; 10 == 6
	ldi	r16, 10
	cp	r16, r17

	ret

check_res:
	; check sreg (flags cf, zf, of, ...)
	push	r1
	in	r1, SREG
	cp	r1, r29
	pop	r1
	brne	fail

	; clear SREG
	out	SREG, r0
	sei

	; check result (r25:r24 == r31:r30)
	cp	r25, r31
	brne	fail
	cp	r24, r30
	brne	fail

	; ok
	ret

end:
	rjmp end

fail:
	rjmp fail

