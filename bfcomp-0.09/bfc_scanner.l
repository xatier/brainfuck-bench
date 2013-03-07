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
#include "bfc_parser.tab.h"
%}

%option noyywrap
%option yylineno

%%

"("             { return TK_ARGS_BEGIN; }
")"             { return TK_ARGS_END; }
"{"             { return TK_SCOPE_BEGIN; }
"}"             { return TK_SCOPE_END; }

";"             { return TK_STEND; }
"="             { yylval.txt=strdup(yytext); return TK_ASSIGN; }
"+="            { yylval.txt=strdup(yytext); return TK_ASSIGN; }
"-="            { yylval.txt=strdup(yytext); return TK_ASSIGN; }

\"[^"]+\"	{ yylval.txt=strdup(yytext); return TK_INLINE; }
\'[^']+\'	{ yylval.txt=strdup(yytext); return TK_INLINE; }

"var"           { return TK_VAR;   }
"if"            { return TK_IF;    }
"else"          { return TK_ELSE;  }
"while"         { return TK_WHILE; }
"macro"         { return TK_MACRO; }

[ \n\t,]+       /* whitespaces and "," are just delimiters */
"//"[^\n]+	/* c++ like comments with // are also allowed */
\*?[a-zA-Z0-9_]+(\.[0-9]+)?	{ yylval.txt=strdup(yytext); return TK_STRING; }

%%

