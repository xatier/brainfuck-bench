/*
 *  bfrun - interpreter for brainf*ck programms
 *  Copyright (C) 2004  Clifford Wolf <clifford@clifford.at>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <stdio.h>

// create debug output while executing
int config_debug = 0;

// activate runtime checks
int config_checks = 1;

#define DATA_SIZE (1024*1024)
#define CODE_SIZE (1024*1024)
#define BPST_SIZE 1024

unsigned char data[DATA_SIZE];
unsigned char code[CODE_SIZE];
unsigned int bpst[BPST_SIZE];

static char c2ch(int i)
{
	if (i>=0 && i<CODE_SIZE)
		switch (code[i]) {
			case '+': case '-': case '[': case ']':
			case '<': case '>': case ',': case '.':
				return code[i];
		}
	return '?';
}

int main(int argc, char **argv)
{
	FILE *f = argc > 1 ? fopen(argv[1], "r") : 0;
	int ch, ip, sp, dp;

	if (!f) {
		fprintf(stderr, "Usage: %s program.bf\n", argv[0]);
		return 1;
	}

	/* read and backpatch */
	for (ip=sp=0; (ch = fgetc(f)) != EOF && ip<DATA_SIZE-1; ip++)
		switch ( (code[ip] = ch) ) {
			case '[':
				bpst[sp++] = ip+=4;
				break;
			case ']':
				*((int*)(code+ip+1)) = bpst[sp-1];
				*((int*)(code+bpst[--sp]-3)) = ip+=4;
				break;
			case '+': case '-': case ',':
			case '<': case '>': case '.':
				break;
			default:
				ip--;
		}
	code[ip] = 0;

	/* execute */
	for (ip=dp=0; code[ip]; ip++) {
		if (config_debug)
			fprintf(stderr, "%c%c%c%c%c%c%c%c%c %c %c%c%c%c%c%c%c%c%c: "
					"ip = %4d, dp = %4d, *dp = %3u\n",  c2ch(ip-9),
					c2ch(ip-8), c2ch(ip-7), c2ch(ip-6), c2ch(ip-5),
					c2ch(ip-4), c2ch(ip-3), c2ch(ip-2), c2ch(ip-1),
					c2ch(ip-0), c2ch(ip+1), c2ch(ip+2), c2ch(ip+3),
					c2ch(ip+4), c2ch(ip+5), c2ch(ip+6), c2ch(ip+7),
					c2ch(ip+8), c2ch(ip+9), ip, dp, data[dp]);
		switch (code[ip]) {
			case '+': data[dp]++; break;
			case '-': data[dp]--; break;
			case '<': dp--; break;
			case '>': dp++; break;
			case ',':
				ch = getchar();
				data[dp] = ch < 0 ? 0 : ch;
				break;
			case '.':
				putchar(data[dp]);
				fflush(stdout);
				break;
			case '[':
			case ']':
				ip = (!data[dp]) == (code[ip] == '[') ?
					*((int*)(code+ip+1)) : ip + 4;
				break;
		}
		if ( config_checks && data[dp] == 255 )
			fprintf(stderr, "Overflow Detected!\n");
	}

	putchar('\n');
	return 0;
}

