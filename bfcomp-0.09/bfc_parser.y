/*
 *  bfc - high-level language compiler for brainf*ck machines
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

%{
#define _GNU_SOURCE
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern void yyerror(char* text);
extern int yylex();
extern int yylineno;

extern char *filename;

void yyerror(char *text)
{
	fprintf(stderr, "BFC: %s(line %d): %s\n", filename, yylineno, text);
	exit(1);
}

char *debug_info()
{
	static char info[100];
	sprintf(info, "\n/%s:%d/\n", filename, yylineno);
	return info;
}

struct list;
struct list {
	char *txt;
	struct list *next;
};

struct xtxt;
struct xtxt {
	char *body;
	struct xtxt *header, *footer;
};

struct macro;
struct macro {
	char *name;
	struct list *args;
	struct xtxt *code;
	struct macro *next;
};

struct macro *macro_table = 0;

struct xtxt *xprintf(struct xtxt *, struct xtxt *, const char *, ...)
		__attribute__ ((format (printf, 3, 4)));

struct xtxt *xprintf(struct xtxt *header, struct xtxt *footer, const char *fmt, ...)
{
	struct xtxt *ret = malloc(sizeof(struct xtxt));
	va_list ap;

	ret->header = header;
	ret->footer = footer;

	if (fmt) {
		va_start(ap, fmt);
		vasprintf(&ret->body, fmt, ap);
		va_end(ap);
	} else
		ret->body = 0;

	return ret;
}

void xput(struct xtxt *t)
{
	static int blocknr = 0, indent_state = 0;
	int i;

	void print_nl() {
		if (indent_state)
			printf("\n%*s", 2*blocknr, "");
		indent_state = 0;
	}

	if (t->header) xput(t->header);

	if (t->body)
		for (i=0; t->body[i]; i++)
			switch (t->body[i]) {
				case '{':
				case '}':
					blocknr += t->body[i] == '{' ? +1 : -1;
					print_nl(); putchar(t->body[i]);
					blocknr += t->body[i] == '{' ? +1 : -1;
				case '\n':
					indent_state = 2;
					break;
				default:
					if ( indent_state == 2 ) print_nl();
					putchar(t->body[i]); indent_state=1;
					break;
			}

	if (t->footer) xput(t->footer);
}

struct xtxt *set_const(struct list *l, int v, int mode)
{
	
	struct list *n = l, *t;
	struct xtxt *ret = 0;
	int i;

	while ( (t=n) ) {
		ret = xprintf(ret, 0, "%s<%s>", debug_info(), t->txt);
		if (!mode) ret = xprintf(ret, 0, "[-]");
		for (i=0; i<v; i++) ret = xprintf(ret, 0, "%c", mode < 0 ? '-' : '+');
		n=t->next; free(t->txt); free(t);
	}
	return xprintf(ret, 0, "\n");
}

struct xtxt *set_var(struct list *l, char *v, int mode)
{
	struct list *n = l, *t;
	struct xtxt *ret = 0;

	while ( (t=n) ) {
		if (*v == '*') {
			ret = xprintf(ret, 0, "%s\n", debug_info());
			if (!mode) ret = xprintf(ret, 0, "<%s>[-]", t->txt);
			ret = xprintf(ret, 0, "<%s>[-<%s>%c]", v, t->txt, mode < 0 ? '-' : '+');
		} else {
			ret = xprintf(ret, 0, "%s{(#tmp_copy)\n", debug_info());
			ret = xprintf(ret, 0, "<#tmp_copy>[-]<%s>[-<#tmp_copy>+]\n", v);
			if (!mode) ret = xprintf(ret, 0, "<%s>[-]", t->txt);
			ret = xprintf(ret, 0, "<#tmp_copy>[-<%s>+<%s>%c]}", v, t->txt, mode < 0 ? '-' : '+');
		}
		n=t->next; free(t->txt); free(t);
	}
	return ret;
}

struct xtxt *call_macro(struct list *l, char *name)
{
	struct macro *t = macro_table;
	struct xtxt *ret = 0;

	while (t) {
		if ( !strcmp(t->name, name) ) break;
		t = t->next;
	}

	if (t) {
		struct list *t1 = t->args;
		struct list *t2, *n2 = l;

		ret = xprintf(ret, 0, "%s{", debug_info());

		while ( t1 && (t2=n2) ) {
			if ( isdigit(*t2->txt) ) {
				int i = atoi(t2->txt);
				ret = xprintf(ret, 0, "(%s)<%s>[-]", t1->txt, t1->txt);
				while (i--) ret = xprintf(ret, 0, "+");
			} else
			    if ( t1->txt[0] == '*' && t2->txt[0] != '*' ) {
				ret = xprintf(ret, 0, "(%s)(#src_%s:%s)<%s>[-]\n", t1->txt, t1->txt, t2->txt, t1->txt);
				ret = xprintf(ret, 0, "{(#tmp_copy)<#tmp_copy>[-]<#src_%s>[-<#tmp_copy>+]\n", t1->txt);
				ret = xprintf(ret, 0, "<#tmp_copy>[-<%s>+<#src_%s>+]}\n", t1->txt, t1->txt);
			} else
				ret = xprintf(ret, 0, "(%s:%s)", t1->txt, t2->txt);
			n2=t2->next; free(t2->txt); free(t2);
			t1 = t1->next;
		}
		ret = xprintf(ret, t->code, "\n");
		ret = xprintf(ret, 0, "}%s", debug_info());
	} else {
		char *msg;
		asprintf(&msg, "macro %s not defined", name);
		yyerror(msg);
	}

	return ret;
}

%}

%union {
	char *txt;
	struct xtxt *xtxt;
	struct list *lst;
}

%token TK_ARGS_BEGIN TK_ARGS_END TK_SCOPE_BEGIN TK_SCOPE_END
%token TK_STEND TK_VAR TK_IF TK_ELSE TK_WHILE TK_MACRO
%token <txt> TK_STRING TK_ASSIGN TK_INLINE

%type <xtxt> stmts stmt block
%type <xtxt> var_stmt if_stmt while_stmt
%type <xtxt> macro_call assign_stmt inline_stmt

%type <lst> list

// 2 shift/reduce conflicts:
// "else" in if with variable and macro
%expect 2

%%

prog:	|	stmt { if ($1) xput($1); } prog

stmts:		/* empty */	{ $$ = 0; }
	|	stmt stmts	{ $$ = xprintf($1, $2, 0); }
		;

stmt:		block		{ $$ = $1; }
	|	macro_call	{ $$ = $1; }
	|	macro_def	{ $$ = 0;  }
	|	var_stmt	{ $$ = $1; }
	|	if_stmt		{ $$ = $1; }
	|	while_stmt	{ $$ = $1; }
	|	assign_stmt	{ $$ = $1; }
	|	inline_stmt	{ $$ = $1; }
		;

block:		TK_SCOPE_BEGIN stmts TK_SCOPE_END
				{
					$$ = xprintf(
						xprintf(0, 0, "{"),
						xprintf($2, 0, "}"), 0);
				}
		;

macro_call:	TK_STRING TK_ARGS_BEGIN list TK_ARGS_END TK_STEND
				{
					$$ = call_macro($3, $1);
				}
		;

macro_def:	TK_MACRO TK_STRING TK_ARGS_BEGIN list TK_ARGS_END stmt
				{
					struct macro *t = malloc(sizeof(struct macro));
					t->name = $2; t->args = $4; t->code = $6;
					t->next = macro_table;
					macro_table = t;
				}
		;

var_stmt:	TK_VAR list TK_STEND
				{
					struct list *n = $2, *t;

					$$ = xprintf(0, 0, "%s", debug_info());
					while ( (t=n) ) {
						$$ = xprintf($$, 0, "(%s)", t->txt);
						n=t->next; free(t->txt); free(t);
					}
					$$ = xprintf($$, 0, "\n");
				}
	|	TK_VAR list TK_ASSIGN TK_STRING TK_STEND
				{
					struct list *t = $2;

					$$ = xprintf(0, 0, "%s", debug_info());
					while ( t ) {
						$$ = xprintf($$, 0, "(%s)", t->txt);
						t=t->next;
					}

					if ( isdigit(*$4) ) {
						$$ = xprintf($$, set_const($2, atoi($4), 0), "\n");
					} else {
						$$ = xprintf($$, set_var($2, $4, 0), "\n");
					}
				}
		;

if_stmt:	TK_IF TK_ARGS_BEGIN TK_STRING TK_ARGS_END stmt
				{
					$$ = xprintf(0, 0, "%s{", debug_info());
					$$ = xprintf($$, $5, "(#tmp_if)<#tmp_if>[-]<%s>[-<#tmp_if>+]"
					                     "<#tmp_if>[[-<%s>+]\n", $3, $3);
					$$ = xprintf($$, 0, "]}");
				}
	|	TK_IF TK_STRING TK_ARGS_BEGIN list TK_ARGS_END stmt
				{
					struct list* para = malloc(sizeof(struct list));

					para->txt = strdup("#tmp_if");
					para->next = $4;

					$$ = xprintf(0, 0, "%s{(#tmp_if)\n", debug_info());
					$$ = xprintf($$, call_macro(para, $2), 0);
					$$ = xprintf($$, $6, "\n<#tmp_if>[[-]\n");
					$$ = xprintf($$, 0, "]}");
				}
	|	TK_IF TK_ARGS_BEGIN TK_STRING TK_ARGS_END stmt TK_ELSE stmt
				{
					$$ = xprintf(0, 0, "%s{", debug_info());
					$$ = xprintf($$, $5, "(#tmp_if)<#tmp_if>[-]<%s>[-<#tmp_if>+]"
					                     "(#tmp_else)<#tmp_else>[-]+"
					                     "<#tmp_if>[[-<%s>+]\n", $3, $3);
					$$ = xprintf($$, $7, "\n<#tmp_else>-]<#tmp_else>[[-]\n");
					$$ = xprintf($$, 0, "]}");
				}
	|	TK_IF TK_STRING TK_ARGS_BEGIN list TK_ARGS_END stmt TK_ELSE stmt
				{
					struct list* para = malloc(sizeof(struct list));

					para->txt = strdup("#tmp_if");
					para->next = $4;

					$$ = xprintf(0, 0, "%s{(#tmp_if)\n", debug_info());
					$$ = xprintf($$, call_macro(para, $2), 0);
					$$ = xprintf($$, $6, "\n(#tmp_else)<#tmp_else>[-]+"
					                     "<#tmp_if>[[-]\n");
					$$ = xprintf($$, $8, "\n<#tmp_else>-]<#tmp_else>[[-]\n");
					$$ = xprintf($$, 0, "]}");
				}
		;

while_stmt:	TK_WHILE TK_ARGS_BEGIN TK_STRING TK_ARGS_END stmt
				{
					$$ = xprintf(
						xprintf(0, 0, "%s{<%s>[\n", debug_info(), $3),
						xprintf($5, 0, "]}"), 0);
				}
	|	TK_WHILE TK_STRING TK_ARGS_BEGIN list TK_ARGS_END stmt
				{
					struct list* para = malloc(sizeof(struct list));
					struct xtxt *m;

					para->txt = strdup("#tmp_while");
					para->next = $4;

					m = call_macro(para, $2);
					$$ = xprintf(0, m, "%s{\n(#tmp_while)\n", debug_info());
					$$ = xprintf($$, $6, "<#tmp_while>[\n");
					$$ = xprintf($$, m, 0);
					$$ = xprintf($$, 0, "]}\n");
				}
		;

assign_stmt:	list TK_ASSIGN TK_STRING TK_STEND
				{
					int mode = 0;
					if ( !strcmp($2, "+=") ) mode = +1;
					if ( !strcmp($2, "-=") ) mode = -1;
					if ( isdigit(*$3) ) {
						$$ = set_const($1, atoi($3), mode);
					} else {
						$$ = set_var($1, $3, mode);
					}
				}
		;

inline_stmt:	TK_INLINE TK_STEND
				{
					$$ = xprintf(0, 0, "%s%s\n", debug_info(), $1);
				}
		;

list:		/* empty */	{ $$ = 0; }
	|	TK_STRING list	{ $$ = malloc(sizeof(struct list)); $$->txt = $1; $$->next = $2; }
		;

