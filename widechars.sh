#!/usr/bin/sh
# Copyright (c) 2019 Michał Czarnecki
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This stript downloads and parses these files:
# http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt
# http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
# in order to generate tables of zero-width, and double-width characters.

# Files listed above belong to Unicode. You can find the license here:
# http://www.unicode.org/copyright.html
# or here:
# http://www.unicode.org/terms_of_use.html

# To generate new 'widechars.h':
# $ ./widechars.sh > widechars.h

echo "/*
* This file was generated by a script using these files:
* http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt
* http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
* These files belong to Unicode. You can find the license here:
* http://www.unicode.org/copyright.html
* or here:
* http://www.unicode.org/terms_of_use.html
*/

#ifndef WIDECHARS_H
#define WIDECHARS_H

/* A sorted list of ranges of Unicode codepoints of double-width characters */
static const int double_width[][2] = {"
curl -s http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt \
	| sed '/^#/ d ; /^$/ d' \
	| awk 'match($0,";[A-Z]",a) { if (a[0] == ";F" || a[0] == ";W") print $0}' \
	| awk 'match($0,"^.+;",a) {print a[0]}' \
	| sed 's/\.\./ /g ; s/;//g' \
	| awk '{ if (length($2) == 0) { print "{0x" $1 ", 0x" $1 "}," } \
	         else { print "{0x" $1 ", 0x" $2 "}," } }'
echo "};
static const size_t double_width_len = sizeof(double_width)/sizeof(double_width[0]);

/* A sorted list of ranges of Unicode codepoints of zero-width characters */
static const int zero_width[][2] = {"
cps=$(curl -s http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt | awk 'BEGIN { FS=";" ; } { if ($3 == "Cf" || $3 == "Mn" || $3 == "Me" || $3 ~ "HANGUL JUNGSEONG" || $3 ~ "HANGUL JONGSEONG") {print $1} }')
a=0
b=0
for line in $cps
do
	cp=$(printf "%d" 0x$line)
	if (( cp == a+1 ))
	then
		b=$cp
	else
		printf "{0x%x, 0x%x},\n" $a $b
		a=$cp
		b=$cp
	fi
done
if (( $a != $b ))
then
	printf "{0x%x, 0x%x},\n" $a $b
fi
echo "};
static const size_t zero_width_len = sizeof(zero_width)/sizeof(zero_width[0]);
#endif"
