/*
 *  bfa - meta assembler for brainf*ck programms
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
#include <stdlib.h>
#include <string.h>

#define MAX_VAR_NAME 100
#define MAX_VAR_STACK 1000
#define MAX_LOOP_STACK 1000


// reuse variable slots in different scopes
int config_reuse_slots = 1;

// show variable allocation info
int config_show_var_alloc = 0;

// show data and variable segment size
int config_show_size = 1;

// include debug symbols in output
int config_include_debug = 0;


/* lexer */

enum lexem_type {
	L_ERROR, L_EOF,
	L_PLUS, L_MINUS, L_OUT, L_IN,
	L_LOOP_BEGIN, L_LOOP_END,
	L_SCOPE_BEGIN, L_SCOPE_END,
	L_VAR_DEFINE, L_VAR_GOTO,
	L_DEBUG
};

struct lexem {
	enum lexem_type type;
	char *text;
};

static int linenum = 1;

static int getchar_()
{
	int ch = getchar();
	if (ch == '\n') linenum++;
	return ch;
}

// implemented below, we need it here for '..' inlines
static int putchar_(int ch);

static struct lexem lexer()
{
	int ch;

nextchar:
	ch = getchar_();

	switch (ch) {
		case '+': return (struct lexem) {L_PLUS, 0};
		case '-': return (struct lexem) {L_MINUS, 0};
		case '.': return (struct lexem) {L_OUT, 0};
		case ',': return (struct lexem) {L_IN, 0};
		case '[': return (struct lexem) {L_LOOP_BEGIN, 0};
		case ']': return (struct lexem) {L_LOOP_END, 0};
		case '{': return (struct lexem) {L_SCOPE_BEGIN, 0};
		case '}': return (struct lexem) {L_SCOPE_END, 0};

		case '/':
		case '(':
		case '<': {
			struct lexem lx;
			int i;

			switch (ch) {
				case '(': lx.type = L_VAR_DEFINE; break;
				case '<': lx.type = L_VAR_GOTO;   break;
				default:  lx.type = L_DEBUG;      break;
			}

			lx.text = malloc(MAX_VAR_NAME+1);

			for (i=0; i<MAX_VAR_NAME; i++) {
				do { ch = getchar_(); } while (ch == '*');
				if ( ch == ')' || ch == '>' || ch == '/' || ch == EOF ) break;
				lx.text[i] = ch;
			}
			lx.text[i] = 0;

			return lx;
		}

		case '\'':
			do {
				ch = getchar_();
				switch (ch) {
					case '+': case '-': case '<': case '>':
					case '[': case ']': case '.': case ',':
						putchar_(ch);
				}
			} while (ch != '\'' && ch != EOF);
			goto nextchar;

		case ';':
		case '#':
			do {
				ch = getchar_();
			} while (ch != '\n' && ch != EOF);
			goto nextchar;
		
		case ' ':
		case '"':
		case '\t':
		case '\n':
			goto nextchar;

		case EOF:
			return (struct lexem) {L_EOF, 0};
	}

	return (struct lexem) {L_ERROR, 0};
}


/* compiler */

struct varent {
	char *name;
	int size, pos, scope;
};

static int current_pos = 0;
static int current_scope = 0;
static int current_loop = 0;
static int var_stack_roof = 0;
static int data_roof = 0;

static int max_data_roof = 0;
static int count_out_chars = 0;

static int loop_stack[MAX_LOOP_STACK];
static struct varent var_stack[MAX_VAR_STACK];

static int putchar_count = 0;
static int putchar_(int ch)
{
	int rc = putchar(ch);
	count_out_chars++;

	if (++putchar_count > 75) {
		putchar('\n');
		putchar_count = 0;
	}

	return rc;
}

static int get_var_pos(char *name, int max_scope)
{
	int var_pos;

	for (var_pos=var_stack_roof-1; var_pos>=0; var_pos--)
		if (var_stack[var_pos].scope <= max_scope)
			if (!strcmp(var_stack[var_pos].name, name))
				return var_stack[var_pos].pos;
	return -1;
}

static void goto_pos(int newpos)
{
	while (newpos > current_pos) { putchar_('>'); current_pos++; }
	while (newpos < current_pos) { putchar_('<'); current_pos--; }
}

#define ERROR(f, ...) \
		({ fprintf(stderr, f, ##__VA_ARGS__); goto got_error; })

int main()
{
	struct lexem lx;
	char *dbginfo = strdup("none");

	while (1) {
		lx = lexer();

		switch (lx.type) {
			case L_PLUS:	putchar_('+'); break;
			case L_MINUS:	putchar_('-'); break;
			case L_OUT:	putchar_('.'); break;
			case L_IN:	putchar_(','); break;

			case L_DEBUG:
				if (config_include_debug) {
					int i;
					putchar_('/');
					for (i=0; lx.text[i]; i++)
						putchar_(lx.text[i]);
					putchar_('/');
				}
				free(dbginfo);
				dbginfo = lx.text;
				break;

			case L_VAR_DEFINE: {
				char *parent = "";
				int offset = 0;

				if ( strchr(lx.text, '.') ) {
					char *t = strchr(lx.text, '.'); *(t++) = 0;
					if ( sscanf(t, "%d", &offset) != 1 )
						ERROR("Can't parse offset in var define: %s\n", t);
				}

				if ( strchr(lx.text, ':') ) {
					parent = strchr(lx.text, ':');
					*(parent++) = 0;
				}

				if ( parent[0] ) {
					var_stack[var_stack_roof].pos = get_var_pos(parent, current_scope-1);
					if (var_stack[var_stack_roof].pos < 0)
						ERROR("Can't find parent symbol in var define: %s\n", parent);
					var_stack[var_stack_roof].pos -= offset;
					var_stack[var_stack_roof].size = 0;
				} else {
					var_stack[var_stack_roof].pos = (data_roof += (offset + 1));
					var_stack[var_stack_roof].size = offset + 1;
				}

				var_stack[var_stack_roof].name = lx.text;
				var_stack[var_stack_roof].scope = current_scope;

				if (config_show_var_alloc)
					fprintf(stderr, "%2d -> %-10s -> %3d(%d) [%s]\n", current_scope,
							lx.text, var_stack[var_stack_roof].pos, offset, parent);

				var_stack_roof++;
				if ( data_roof > max_data_roof )
					max_data_roof = data_roof;
				break;
			}

			case L_VAR_GOTO: {
				int var_pos, offset = 0;

				if ( strchr(lx.text, '.') ) {
					char *t = strchr(lx.text, '.'); *(t++) = 0;
					if ( sscanf(t, "%d", &offset) != 1 )
						ERROR("Can't parse size/offset in var goto: %s\n", t);
				}

				var_pos = get_var_pos(lx.text, current_scope);
				if (var_pos < 0)
					ERROR("Can't find symbol in var goto: %s\n", lx.text);
				goto_pos(var_pos - offset);
				free(lx.text);
				break;
			}

			case L_LOOP_BEGIN:
				loop_stack[current_loop++] = current_pos;
				putchar_('[');
				break;

			case L_LOOP_END:
				goto_pos(loop_stack[--current_loop]);
				putchar_(']');
				break;

			case L_SCOPE_BEGIN:
				current_scope++;
				break;

			case L_SCOPE_END: {
				while (var_stack_roof > 0 && var_stack[var_stack_roof-1].scope == current_scope) {
					free(var_stack[--var_stack_roof].name);
					if (config_reuse_slots)
						data_roof -= var_stack[var_stack_roof].size;
				}
				current_scope--;
				break;
			}

			case L_EOF:
				if (current_scope != 0)
					ERROR("Unbalanced scopes at EOF.\n");
				if (current_loop != 0)
					ERROR("Unbalanced loops at EOF.\n");
				goto reached_eof;
			default:
				ERROR("Parse error.\n");
		}
	}

reached_eof:
	while(putchar_count) putchar_('>');
	if (config_show_size)
		fprintf(stderr, "Code: %d bytes, Data: %d bytes.\n",
				count_out_chars, max_data_roof);
	return 0;

got_error:
	while(putchar_count) putchar_('>');
	fprintf(stderr, "BFA: Got an error at line %d (%s).\n",
			linenum, dbginfo);
	return 1;
}

