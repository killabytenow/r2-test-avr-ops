#!/bin/sh

get_symbol_addr()
{
	local SYM="$1"
	ADDR="0x`grep "^$SYM\>" test-avr.map | cut -f 4`"
	if [ "$ADDR" = "0x" ]; then
		echo "Symbol '$SYM' does not exist." 1>&2
		ADDR="0"
	fi
	echo $(($ADDR*2))
}

tag_sym_func()
{
	local SYM="$1"
	echo "f sym.$SYM 0 `get_symbol_addr "$SYM"`"
}

get_test_symbol_names()
{
	grep "^test_" test-avr.map \
	| cut -f 1
}

avra \
	-l test-avr.list \
	-m test-avr.map \
	test-avr.s \
&& echo "Success"

cat > test-avr.r2 <<EOF
# configure memory layout
aeim 0x00010000 0x01ff avr_eeprom
aeim 0x00010200 0x01ff avr_io
aeim 0x00010400 0xffff avr_sram

# export symbols
EOF
tag_sym_func "main"      >> test-avr.r2
tag_sym_func "success"   >> test-avr.r2
tag_sym_func "check_res" >> test-avr.r2
tag_sym_func "fail"      >> test-avr.r2
for f in `get_test_symbol_names`; do
	tag_sym_func "$f"
done >> test-avr.r2

echo "# add code" >> test-avr.r2
grep "^C:" test-avr.list \
| while read L; do
	ADDR="0x`echo "$L" | cut -f 1 | sed -e 's#^C:##' -e 's# .*$##'`"
	CODE="`echo "$L" | sed 's#^[^\t]*\t##'`"
	if echo "$CODE" | grep '^[^ ]*\(jmp\|call\)' > /dev/null 2>&1; then
		echo "CC $CODE @$(($ADDR*2))" | sed 's#\t# #g'
	fi
done >> test-avr.r2

echo "Success"
exit 0
