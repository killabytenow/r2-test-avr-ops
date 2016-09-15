.INCLUDE "/usr/share/avra/m8def.inc"

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

	sei

	; --------------------------------------------------
	; TESTS
	; --------------------------------------------------

	rcall   test_ret
	rcall   test_reti
	rcall	test_cp

	rjmp end

test_ret:
	ret

test_reti:
	reti

test_cp:
	; 5 == 5
	ldi	r16, 5
	ldi	r17, 5
	ldi	r31, 0x02
	cp	r16, r17
	rcall	check_sreg

	; 5 == 6
	ldi	r17, 6
	cp	r16, r17

	; 10 == 6
	ldi	r16, 10
	cp	r16, r17

	ret

check_sreg:
	push	r1
	in	r1, SREG
	cp	r1, r31
	pop	r1
	brne	fail
	clr	r1
	out	SREG, r1
	ret

end:
	rjmp end

fail:
	rjmp fail

