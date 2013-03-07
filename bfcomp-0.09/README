
The Brainf*ck Compiler Suite (by Clifford Wolf, http://www.clifford.at/)
========================================================================

The Brainf*ck Compiler Suite consists of 4 parts:

	bfa		The assembler
	bfc		The compiler
	builtins.bfc	The macro package

	bfrun		A brainf*ck runtime

bfc reads a bfc source file from it's stdin and writes the bfa assembler
file to it's stdout. It also expects builtins.bfc in the current working
directory.

bfa reads a bfa assembler source from it's stdin and writes the brainf*ck
program to it's stdout.

So, compiling a program is easy:

	./bfc < hanoi.bfc > hanoi.bfa
	./bfa < hanoi.bfa > hanoi.bf

As also is executing:

	./bfrun hanoi.bf

Note that the 'bfrun' brainf*ck runtime does check for integer overflows
and is only using 8 bit cells. Brainf*ck programs which do run on this
runtime without triggering overflow warnings are very likely to run on a
wide range of brainf*ck runtimes.


The BFC Language
================

BFC has some parallels to the C syntax, but it is a very different
programming language from C.

There are no functions in BFC - instead there are "macros" which behave
like functions but are _always_ inlined. So it is wise to not instantiate a
complex macro to often but instead construct a loop with the macro in it so
it's only instantiated once. All arguments are passed using a call-by-
reference semantic.

A macro is declared with:

	macro my_macro_name(arg1, arg2, arg3)
	{
		...
	}

note that there are no data types in BFC. Everything is an int with the
cell-size of the machine it's running on.

BFC is using the same style of command-scoping with '{' and '}' such as C.
Variables are declared with:

	var a, b, c = 32;
	var x, y, z;

Note that the "32" in the first line is the initializer for a, b and c!

There are also instructions for setting, incrementing and decrementing
variables:

	a, b = c;
	a += x;
	b -= y;

copies the value from c to a and b and then increments a by x and
decrements b by y. BFC has no support for arithmetical expressions
such as "a = c + x".

There is an if statement and a while loop in BFC:

	if (a)
		if (b) { ... }
		else { ... }
	
	while (x) { ... }

The conditional expression must be a single variable. No complex
expressions such as "if (a && b)" are allowed. But it is possible
to use macro calls in if and while statements, such as:

	if _and(a, b) { ... }

where _and() is defined in builtins.bfc as

	macro _and(result, v1, v2)
	{
		result = 0;
		if (v1) if (v2) result = 1;
	}

Note that the 1st parameter always has the return value when using macro
calls as "if" or "while" condition and is not specified in the macro call.

Whenever a '*' is used as 1st character in a variable name, it means that
the compiler is allowed to create code which destroys the value. E.g.

	a += *x;

will produce code might modify 'x' as a side-effect. When '*' is used in a
macro declaration such as in

	macro _mul(result, *v1, v2)
	{
		result = 0;
		while (v1) {
			result += v2;
			v1 -= 1;
		}
	}

means that the compiler should create a local copy of v1, unless the 2nd
argument is also marked with * when calling the macro (or the 2nd argument
is a constant value).

It is also possible to embed BFA assembler code and Brainf*ck code in BFC
programs using double and single quotes:

		"this is BFA assembler";
		'this is Brainf*cl code';

In addition to defining single variables, it is possible to define variable
blocks and access variables in this blocks:

		var x.3;
		x.0 = a;
		x.1 = a;
		x.2 = a;
		x.3 = a;

The number specified when defining the block is the highest allowed index.
The 0th element of the block is the highest (most right) cell in the
brainf*ck code. So setting all members of x in the above example could be
done using:
		"<x.0>";
		'[-]<[-]<[-]<[-]>>>';

But such constructs are usually only needed in low-level macros defined in
the builtins library.


The BFC Builtins Library
========================

The builtins library defines the following macros. More can be defined on
demand based on the examples in the builtins.bfc which comes with this
package.

Writing to the output and reading from the input:

	out(char);
	in(char);

Printing value of a variable as decimal number:

	outnum(n);

Some logical operators (to be used e.g. in "if" and "while" statements):

	_not(result, v1);
	_and(result, v1, v2);
	_or(result, v1, v2);

Multiply, divide and modulo operations:

	_mul(result, v1, v2);
	_div(result, v1, v2);
	_mod(result, v1, v2);

Compare for equal, not equal and less-than:

	_eq(result, v1, v2);
	_neq(result, v1, v2);
	_lt(result, v1, v2);

Arrays (the array must be a variable block with a size of 4 times the
number of array elements):

	a4w(array, pos, val);
	a4r(array, pos, val);

So, a bubble sort can be easily implemented as:

	macro bubble_sort(array, maxidx)
	{
		var keep_running = 1;

		while (keep_running)
		{
			var i0, i1;

			keep_running = 0;

			i0 = 0;
			i1 = 1;

			while _neq(i0, maxidx) {
				var tmp1, tmp2;

				a4r(array, i0, tmp1);
				a4r(array, i1, tmp2);

				if _lt(tmp2, tmp1) {
					a2w(array, i1, tmp1);
					a2w(array, i0, tmp2);
					keep_running = 1;
				}

				i0, i1 += 1;
			}
		}
	}

See the hanoi.bfc example program for a detailed example program using
almost all of the macros defined in the builtins library (including
multiple arrays).


The BFA Assembly Language
=========================

BFA looks pretty familiar to Brainf*ck but has some important differences:

{ ... }
	Defines a scope for variable names.

[ ... ]
	Like the loop in Brainf*ck, but set the data pointer back to it's
	original value at the end.

(varname)
	Define a variable with this name.

(local:parent)
	Define "local" being an alias name for the variable "parent" in
	the enclosing scope (used for the arguments in macros expansion).

<varname>
	Move the data pointer to the position of varname

+ and -
	Do the same things as + and - in Brainf*ck

. and ,
	Do the same things as . and , in Brainf*ck

'brainf*ck'
	The text between the single quotes is embedded brainf*ck code and
	will be passed thru unmodified. Such code must always restore the
	data pointer to the value it has been in the beginning of the
	code block so <varname> statements still work correctly.

/debug label/
	This is a debug label and will be ignored.

# comment
; comment
	This is are comments and will be ignored.

Usually there is no need to write code in BFA or directly in Brainf*ck when
programming with the Compiler.


Finally
=======

Note that the code this compiler produces can easily become quite big. Some
Brainf*ck runtimes are having problems with huge programs - think about it
when you are having troubles with the package. The runtime in this package
has a hard coded data-segment size of 1MB, a hard coded code-segment size of
1MB and can handle 1024 cascaded brainf*ck loops.

I wish you a lot of fun with the Brainf*ck Compiler Suite. More
information about it can be found on the Brainf*ck section of my homepage:

	http://www.clifford.at/bfcpu/

happy hacking,
 - clifford <clifford@clifford.at>

