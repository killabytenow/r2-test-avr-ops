#!/bin/sh

#avr-as -mmcu=attiny15 -o test-avr.o test-avr.s \
avr-as -mmcu=atmega8 --gstabs -o test-avr.o test-avr.s \
&& avr-ld -o test-avr.elf test-avr.o \
&& avr-objcopy --output-target=ihex test-avr.elf test-avr.ihex

