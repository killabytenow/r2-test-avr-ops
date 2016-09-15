.equ PORTB,0x18
.equ DDRB, 0x17
.equ SREG, 0x3f

.org 0x00
reset:
rjmp main;
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
	#sbi DDRB, 0;
	#cbi DDRB, 0;

	rcall	test_cp
	rjmp end

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

