;.INCLUDE "def/m8def.inc"
.INCLUDE "def/m32def.inc"

.equ	NONE	= (0)
.equ	CF	= (1 << SREG_C)
.equ	ZF	= (1 << SREG_Z)
.equ	HF	= (1 << SREG_H)

.ORG 0x00
reset:
	rjmp main
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

defaultInt:
	reti

main:
	; --------------------------------------------------
	; INIT
	; --------------------------------------------------

	; Disable interrupts - THIS CODE HATES INTERRUPTS
	cli

	; init stack
	ldi	r16, HIGH(RAMEND) 	; Upper byte
	out	SPH, r16		; to stack pointer
	ldi	r16, LOW(RAMEND) 	; Lower byte
	out	SPL, r16		; to stack pointer

	; init r0 risc style
	clr	r0

	; --------------------------------------------------
	; CHECK CALL OPCODES
	; --------------------------------------------------

	rcall	test_ret
.if FLASHEND > 0x0fff
	call	test_ret
.endif
	rcall	test_reti
	cli

	; --------------------------------------------------
	; TESTS
	; --------------------------------------------------

	rcall	test_adc
	rcall	test_asr
	rcall	test_bclr
	rcall	test_bld
	rcall	test_cp
	rcall	test_dec
	rcall	test_sbrx
	rcall	test_mul

	; --------------------------------------------------
	; HAPPY ENDING!
	; --------------------------------------------------

success:			; final loop -- execution was succesful!
	sleep
	rjmp success

; -----------------------------------------------------------------------------
; check_res - checks op result
;	- r17:r16	op result
;	- r31:r30	expected op result
;	- r28 		mask that will be applied to SREG
;	- r29 		expected value after (SREG & r28)
; -----------------------------------------------------------------------------

check_res:
	; check sreg (flags cf, zf, of, ...)
	push	r1
	in	r1, SREG	; save current SREG
	and	r1, r28		; apply mask to SREG
	cp	r1, r29
	pop	r1
	brne	fail

	; clear SREG
	push	r0
	clr	r0
	out	SREG, r0
	pop	r0

	; check result (r17:r16 == r31:r30)
	cp	r17, r31
	brne	fail
	cp	r16, r30
	brne	fail

	; ok
	ret

fail:				; EXECUTION FAILED!
	break			; analyze stack for discovering the faulty op!
	rjmp fail

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
	clr	r17
	clr	r31
	ldi	r28, 0x3f	; check only math flags

	; ==> 0 + 0 + C(1) = 1
	sec
	ldi	r16, 0
	ldi	r26, 0
	ldi	r29, NONE	; EXPECTED FLAGS
	ldi	r30, 0x01	; EXPECTED RESULT
	adc	r16, r26
	rcall	check_res

	; ==> 0 + 0 + C(0) = 0
	clc
	ldi	r16, 0
	ldi	r26, 0
	ldi	r29, ZF		; EXPECTED FLAGS
	ldi	r30, 0x00	; EXPECTED RESULT
	adc	r16, r26
	rcall	check_res

	; ==> 100 + -1 + C(1) = 100
	sec
	ldi	r16, 100
	ldi	r26, -1
	ldi	r29, HF+CF	; SREG (HC)
	ldi	r30, 100	; EXPECTED RESULT
	adc	r16, r26
	rcall	check_res

	; ==> 0 + -1 + C(1) = 0
	sec
	ldi	r16, 0
	ldi	r26, -1
	ldi	r29, 0x21	; SREG (HC)
	ldi	r30, 0		; EXPECTED RESULT
	adc	r16, r26
	rcall	check_res

	; ==> 0 + -1 + C(0) = 0
	clc
	ldi	r16, 0
	ldi	r26, -1
	ldi	r29, 0x14	; SREG (NV)
	ldi	r30, -1		; EXPECTED RESULT
	adc	r16, r26
	rcall	check_res

	ret;

; -----------------------------------------------------------------------------
; ASR
; -----------------------------------------------------------------------------

test_asr:
	clr	r17
	clr	r31
	ldi	r28, 0x3f	; check only math flags

	; ==> 0 >> 1
	ldi	r16, 0
	ldi	r29, 0x02	; SREG (Z)
	ldi	r30, 0x00	; EXPECTED RESULT
	asr	r16
	rcall	check_res

	; ==> 2 >> 1
	ldi	r16, 2
	ldi	r29, 0x00	; SREG ()
	ldi	r30, 0x01	; EXPECTED RESULT
	asr	r16
	rcall	check_res

	; ==> 3 >> 1
	ldi	r16, 3
	ldi	r29, 0x19	; SREG ()
	ldi	r30, 1		; EXPECTED RESULT
	asr	r16
	rcall	check_res

	; ==> 0x80 >> 1
	ldi	r16, 0x80
	ldi	r29, 0x0c	; SREG ()
	ldi	r30, 0xc0	; EXPECTED RESULT
	asr	r16
	rcall	check_res

	; ==> 0x81 >> 1
	ldi	r16, 0x81
	ldi	r29, 0x15	; SREG ()
	ldi	r30, 0xc0	; EXPECTED RESULT
	asr	r16
	rcall	check_res

	ret

; -----------------------------------------------------------------------------
; BCLR
; -----------------------------------------------------------------------------

test_bclr:
	; clear result/expected result registers (r17:16, r31:30)
	clr	r16
	clr	r17
	movw	r31:r30, r17:r16
	ldi	r28, 0xff	; check only math flags

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

	ret

; -----------------------------------------------------------------------------
; BLD
; -----------------------------------------------------------------------------

test_bld:
	; clear result/expected result registers (r17:16, r31:30)
	clr	r17
	clr	r30
	clr	r31
	; this instruction does not update any flag
	clr	r28

	; ==> r16.0(0) = T(1)
	clr	r16
	ldi	r29, 0x40	; SREG (T)
	ldi	r30, 0x01	; EXPECTED RESULT
	clr	r0
	out	SREG, r0
	set
	bld	r16, 0
	rcall	check_res

	; ==> r16.0(0) = T(0)
	clr	r16
	ldi	r29, 0x00	; SREG ()
	ldi	r30, 0x00	; EXPECTED RESULT
	out	SREG, r0
	clt
	bld	r16, 0
	rcall	check_res

	; ==> r16.0(0xff) = T(1)
	ser	r16
	ldi	r29, 0x40	; SREG (T)
	ldi	r30, 0xff	; EXPECTED RESULT
	out	SREG, r0
	set
	bld	r16, 0
	rcall	check_res

	; ==> r16.0(0xff) = T(0)
	ser	r16
	ldi	r29, 0x00	; SREG (T)
	ldi	r30, 0xfe	; EXPECTED RESULT
	out	SREG, r0
	clt
	bld	r16, 0
	rcall	check_res

	; ==> r16.3(0) = T(1)
	clr	r16
	ldi	r29, 0x40	; SREG (T)
	ldi	r30, 0x08	; EXPECTED RESULT
	out	SREG, r0
	set
	bld	r16, 3
	rcall	check_res

	; ==> r16.3(0) = T(0)
	clr	r16
	ldi	r29, 0x00	; SREG ()
	ldi	r30, 0x00	; EXPECTED RESULT
	out	SREG, r0
	clt
	bld	r16, 3
	rcall	check_res

	ret

; -----------------------------------------------------------------------------
; CP
; -----------------------------------------------------------------------------

test_cp:
	clr	r17
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

; -----------------------------------------------------------------------------
; DEC
; -----------------------------------------------------------------------------

test_dec:
	; clear result/expected result registers (r17:16, r31:30)
	clr	r17
	clr	r31

	; ==> r16(0)--
	clr	r16
	ser	r30
	ldi	r29, 0x14
	out	SREG, r0
	dec	r16
	rcall	check_res

	; ==> r16(1)--
	ldi	r16, 1
	clr	r30
	ldi	r29, 0x2
	out	SREG, r0
	dec	r16
	rcall	check_res

	; ==> r16(0x80)--
	ldi	r16, 0x80
	ldi	r30, 0x7f
	ldi	r29, 0x18
	out	SREG, r0
	dec	r16
	rcall	check_res

	ret

; -----------------------------------------------------------------------------
; FMUL/MUL
; -----------------------------------------------------------------------------

test_mul:
	; clear result/expected result registers (r17:16, r31:30)
	clr	r16
	clr	r17
	clr	r30
	clr	r31
	clr	r29

	; unsigned(0.039370079) * unsigned(1.00)
	ldi	r16, 0x05
	ldi	r17, 0x80
	fmul	r17, r16
	movw	r17:r16, r1:r0
	ldi     r31, 0x00
	ldi     r30, 0x05

	; unsigned(0.039370079) * signed(-1.00)
	ldi	r16, 0x05
	ldi	r17, 0x80
	fmuls	r17, r16
	movw	r17:r16, r1:r0
	ldi     r31, 0x80
	ldi     r30, 0x05

	; unsigned(0.039370079) * signed(-1.00)
	ldi	r16, 0x80
	ldi	r17, 0x05
	fmuls	r17, r16
	movw	r17:r16, r1:r0
	ldi     r31, 0x80
	ldi     r30, 0x05

	ret

; -----------------------------------------------------------------------------
; SBRC/SBRS
; -----------------------------------------------------------------------------

test_sbrx:
	; clear result/expected result registers (r17:16, r31:30)
	clr	r17
	clr	r30
	clr	r31
	clr	r29

	; ==> r16.0(0) == 0
	ldi	r16, 0x00
	sbrc	r16, 0
	ldi	r16, 0xff
	rcall	test_sbrx_check_zero

	; ==> r16.0(1) == 0
	ldi	r16, 0x01
	sbrc	r16, 0
	ldi	r16, 0x00
	rcall	test_sbrx_check_zero

	; ==> r16.0(1) == 0
	ldi	r16, 0x01
	sbrc	r16, 0
	call	test_sbrx_set_zero
	rcall	test_sbrx_check_zero

	; ==> r16.4(0xff) != 0
	ldi	r16, 0xff
	sbrs	r16, 4
	ldi	r16, 0x00
	rcall	test_sbrx_check_no_zero

	; ==> r16.0(1) != 0
	ldi	r16, 0x08
	sbrs	r16, 3
	ldi	r16, 0x00
	rcall	test_sbrx_check_no_zero

	; ==> r16.0(1) != 0
	ser	r16
	sbrs	r16, 0
	call	test_sbrx_set_zero
	rcall	test_sbrx_check_no_zero

	ret

test_sbrx_set_zero:
	clr	r16
	ret

test_sbrx_set_one:
	ser	r16
	ret

test_sbrx_check_zero:
	tst	r16
	breq	test_sbrx_ok
	jmp	fail

test_sbrx_check_no_zero:
	tst	r16
	brne	test_sbrx_ok
	jmp	fail

test_sbrx_ok:
	ret

