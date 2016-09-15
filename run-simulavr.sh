#!/bin/bash

( simulavr -d atmega8 -g test-avr.elf ) &

gdb 

kill -9 %1
