#!/bin/bash

# Name of your output file
OFILE="output.bin"

# A goofy ahh wrapper to convert a sequence of 8 1s and 0s into a 8-bit number, expressed in hex
function bstr_to_byte()
{
    echo "obase=16;ibase=2;$1" | bc
}


# Build input string from stdin
#   This can be done using pipes ( echo "1010101..." | ./binstr.sh
#   Or "interactively", so long as you enter q on it's own line when you are done entering your
#       binary string.
ISTR=""
while read data; do
    if [[ ${data} != "q" ]] ; then
        ISTR="${ISTR}${data}"
    else
        break
    fi
done

# Byte-by-byte conversion
while [[ $(expr length ${ISTR}) -ge 8 ]] ; do
    # Copy the first 8 characters
    BSTR=${ISTR:0:8}
    # Drop them from the input string
    ISTR=${ISTR:8}
    # Convert the byte-string into a byte
    BYTE=$(bstr_to_byte $BSTR)

    # Debug print
    ##echo "$BSTR => [ ${BYTE} ]"

    # Write character to file
    echo -en "\x${BYTE}" >> ${OFILE}

    # Check for empty ISTR, which will cause error on iteration
    if [[ -z ${ISTR} ]] ; then
        ##echo "String parsed evenly"
        break
    fi
done

##echo "Remaining, unparsed characters: ${ISTR}"
