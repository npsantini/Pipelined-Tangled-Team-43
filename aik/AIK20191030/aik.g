#header <<
typedef	int Attrib;
#define zzdef0(a)		{ *(a)=0; }
#define zzd_attr(a)		{ /* Nothing to do */ }
#define	AST_FIELDS \
	int	sym;

#define zzcr_ast(ast, attr, token_type, text)	 ast->sym = *(attr)

#define	VERSION		 20191030
#define	VERSTRING	"20191030"

extern int	inbraces;
extern FILE	*specin;

#ifdef	CGI
#include "cgic.h"
#define	stderr	cgiOut
#endif

>>

#token "[\ \t]+"
	<< zzskip(); >>
#token EOS "((;(~[\n])*\n)|(\n))"
	<< zzline++;
	   if (inbraces) zzskip();
	>>
#token "\{"
	<< ++inbraces; zzskip(); >>
#token "\}"
	<< inbraces -= (inbraces != 0); zzskip(); >>
#token "\'"
	<< zzreplstr(""); zzmode(LEXSTRING); zzmore(); >>
#token "\""
	<< zzreplstr(""); zzmode(LEXMESG); zzmore(); >>

#token MYEOF "@"
	<< zzreplstr("$EOF"); >>
#token NUM "(([0-9]+)|(0[bBxX][0-9A-Fa-f]+))"
	<< if ((*(zzbegexpr) == '0') &&
	       ((*(zzbegexpr+1) == 'b') ||
		(*(zzbegexpr+1) == 'B'))) {
		zzreplstr( btox(zzbegexpr) );
	   }
	>>

#token IS	":="
#token DEFINED	"?="
#token COLON	":"
#token QUEST	"?"
#token OROR	"\|\|"
#token ANDAND	"&&"
#token OR	"\|"
#token XOR	"^"
#token AND	"&"
#token EQ	"=="
#token NE	"!="
#token MIN	"?\<"
#token MAX	"?\>"
#token LT	"\<"
#token GT	"\>"
#token LE	"\<="
#token GE	"\>="
#token SHR	"\>\>"
#token SHL	"\<\<"
#token ADD	"\+"
#token SUB	"\-"
#token MUL	"\*"
#token DIV	"/"
#token MOD	"\%"
#token LPAREN	"\("
#token RPAREN	"\)"
#token NOT	"\~"
#token LNOT	"!"
#token COMMA	","

#token ASSIGN	"="
#token ASMIN	"?\<="
#token ASMAX	"?\>="
#token ASOROR	"\|\|="
#token ASANDAND	"&&="
#token ASADD	"\+="
#token ASSUB	"\-="
#token ASMUL	"\*="
#token ASDIV	"/="
#token ASMOD	"\%="
#token ASSHR	"\>\>="
#token ASSHL	"\<\<="
#token ASAND	"&="
#token ASXOR	"^="
#token ASOR	"\|="
#token ADDADD	"\+\+"
#token SUBSUB	"\-\-"

#token DOT	"\."

#tokclass BUILTINASSIGN {
	ASSIGN
	ASMIN	ASMAX	ASOROR	ASANDAND
	ASADD	ASSUB
	ASMUL	ASDIV	ASMOD
	ASSHR	ASSHL
	ASAND	ASXOR	ASOR
}

#tokclass BUILTINPUNCT {
	IS	DEFINED
	COLON	QUEST	OROR	ANDAND
	OR	XOR	AND
	EQ	NE	MIN	MAX	LT	GT	LE	GE
	SHR	SHL
	ADD	SUB	MUL	DIV	MOD
	LPAREN	RPAREN	NOT	LNOT
	DOT
	BUILTINASSIGN
	ADDADD	SUBSUB
}

#token EQU	".equate"
#token SET	".set"
#token ORG	".origin"
#token IF	".if"
#token IFREF	".ifref"
#token ELSE	".else"
#token END	".end"
#token DW	".word"
#token DS	".space"
#token ALIAS	".alias"
#token CONST	".const"
#token ALIGN	".align"
#token ERROR	".error"
#token WARN	".warn"

#tokclass WARNERR {
	WARN	ERROR
}

#token SEGMENT	".segment"
#token SEGNAME

#tokclass WORDSEGNAME {
	WORD	SEGNAME
}

#tokclass BUILTINSYM {
	EQU	SET	ORG
	IF	IFREF	ELSE	END
	DW	DS
	ALIAS
	CONST
	WARNERR
}

#tokclass BUILTIN {
	BUILTINPUNCT	BUILTINSYM
}

#token WORD	"{\.}[a-zA-Z_][a-zA-Z_0-9]*"
	<< {
		register int i = findsym(zzbegexpr);
		if (i != -1) {
			NLA = typofsym(i);
		}
	} >>

#token INST
#tokclass WORDINST {
	WORD	INST
}

#lexclass LEXSTRING
#token NUM "~[\'\\]"
	<< { char buf[1024];
	   sprintf(buf, "0x%x", *(zzbegexpr));
	   zzreplstr(buf); }
	>>
#token NUM "\\~[]"
	<< { char buf[1024];
	   sprintf(buf, "0x%x", *(zzbegexpr+1));
	   zzreplstr(buf); }
	>>
#token "\'"
	<< zzreplstr(""); zzmode(START); zzmore(); >>

#lexclass LEXMESG
#token "~[\"\\]"
	<< zzmore(); >>
#token "\\~[]"
	<< zzmore(); >>
#token MESG "\""
	<< zzreplstr(""); zzmode(START); >>

#lexclass START

<<
#define	DEBUG
#undef	DEBUG

#include "asr.h"

#ifdef	CGI
#include "cgic.h"
#define	stderr	cgiOut
#endif

int	inbraces = 0;

#define	MAXPASS	(20)
#define	MAXBUF	(256 * 1024)
#define	SYMS	(256 * 1024)
#define	ALTS	8

typedef struct _sym_t {
	char	*text;		/* lexeme */
	AST	*ast[ALTS];	/* specification ASTs */
	int	val;		/* number value */
	short	typ;		/* token type */
	char	defined;	/* is this object defined? */
	char	refd;		/* is this object referenced? */
} sym_t;

sym_t	sym[SYMS];
int	syms = 0;

AST	**aliasast;
int	aliases;
Attrib	this;

Attrib	aikpasses;
int	pass = 0;		/* How many passes? */
Attrib	aiklowfirst;
Attrib	aikversion;
Attrib	i8hex, srec, mif, vmem;
Attrib	aikrequirecolon;

#define	SEGS	8
#define	MAXHEX	32		/* Bytes per hex record */

typedef struct _seg_t {
	int	name;		/* Segment name (sym) */
	int	format;		/* Format (sym) */
	int	width;
	int	depth;
	int	org;
	int	seglc;
	int	pos;
	FILE	*file;		/* output file pointer */
	char	*outp;		/* Output pointer */
	char	out[MAXBUF];	/* Output buffer */
	int	_hexbase;	/* base addr of current record */
	int	_hexcnt;	/* bytes in this record */
	int	_hexbyt[MAXHEX];	/* current record buffer */
	int	_chksum;	/* checksum for record */
	int	_bytesgen;	/* total bytes generated */
} seg_t;

#define	hexbase		seg[segment]._hexbase
#define	hexcnt		seg[segment]._hexcnt
#define	hexbyt		seg[segment]._hexbyt
#define	chksum		seg[segment]._chksum
#define	bytesgen	seg[segment]._bytesgen

seg_t	seg[SEGS];
int	segs = 0;

AST	*specroot = 0;
AST	*initroot = 0;
AST	*instroot = 0;

int	segment = 0;

#define	lc	seg[segment].seglc

int	disabled = 0;
int	changed = 0;
int	generate = 0;
int	notdefined = 0;

char	*progname = "";
char	*sourcename = "";
int	warncount = 0;
int	errorcount = 0;

void
reference(register int x)
{
	changed += (sym[x].refd == 0);
	sym[x].refd = 1;
}

#define	aikwarnsyn(args...) \
	{ \
		fprintf(stderr, "Warning: "); \
		fprintf(stderr, args); \
		fprintf(stderr, "\n"); \
		++warncount; \
	}

#define	aikwarn(args...) \
	{ \
		if (generate) { \
			fprintf(stderr, "Warning: "); \
			fprintf(stderr, args); \
			fprintf(stderr, "\n"); \
			++warncount; \
		} \
	}

#define	aikerror(args...) \
	{ \
		fprintf(stderr, "Error: "); \
		fprintf(stderr, args); \
		fprintf(stderr, "\n"); \
		++errorcount; \
	}

char *
strsav(register char *s)
{
	extern void *malloc();
	extern char *strcpy();
	register char *p = ((char *) malloc(strlen(s)+1));

	if (!p) {
		aikerror("Out of string memory...!\n");
	}

	strcpy(p,s);
	return(p);
}

int
findsym(register char *text)
{
	register int i;

	for (i=0; i<syms; ++i) {
		if (strcmp(text, sym[i].text) == 0) {
			return(i);
		}
	}

	return(-1);
}

int
typofsym(register int i)
{
	return(sym[i].typ);
}

zzcr_attr(Attrib *a, register int token, register char *text)
{
	register int i;

	if ((i = findsym(text)) != -1) {
		*a = i;
		return;
	}

	switch (token) {
	case NUM:
		sym[syms].val = strtol(text, 0, 0);
		break;
	case EOS:
	case MYEOF:
		*a = 0;
		return;
	default:
		sym[syms].val = 0;
	}
	sym[syms].text = strsav(text);
	for (i=0; i<ALTS; ++i) {
		sym[syms].ast[i] = 0;
	}
	sym[syms].typ = token;
	sym[syms].defined = 0;
	sym[syms].refd = 0;
	*a = syms;
	++syms;
}

AST *
zzmk_ast(register AST* a, register int token, register char *text)
{
	zzcr_attr(&(a->sym), token, text);
	return(a);
}

char charbuf[256];

char *
btox(register char *s)
{
	register int val = 0;

	++s;
	while (*++s) {
		val = (val << 1) + (*s - '0');
	}
	sprintf(&(charbuf[0]), "0x%x", val);
	
	return(&(charbuf[0]));
}

#include "aikout.c"

int
eval(register AST *root)
{
	register int i, j, dsave;

	switch (sym[root->sym].typ) {
	case QUEST:
		return(eval(zzchild(root)) ?
		       eval(zzsibling(zzchild(root))) :
		       eval(zzsibling(zzsibling(zzchild(root)))));
	case OROR:
		return(eval(zzchild(root)) || eval(zzsibling(zzchild(root))));
	case ANDAND:
		return(eval(zzchild(root)) && eval(zzsibling(zzchild(root))));
	case OR:
		return(eval(zzchild(root)) | eval(zzsibling(zzchild(root))));
	case XOR:
		return(eval(zzchild(root)) ^ eval(zzsibling(zzchild(root))));
	case AND:
		return(eval(zzchild(root)) & eval(zzsibling(zzchild(root))));
	case EQ:
		return(eval(zzchild(root)) == eval(zzsibling(zzchild(root))));
	case NE:
		return(eval(zzchild(root)) != eval(zzsibling(zzchild(root))));
	case MIN:
		{
			register int i = eval(zzchild(root));
			register int j = eval(zzsibling(zzchild(root)));
			return((i < j) ? i : j);
		}
	case MAX:
		{
			register int i = eval(zzchild(root));
			register int j = eval(zzsibling(zzchild(root)));
			return((i > j) ? i : j);
		}
	case LT:
		return(eval(zzchild(root)) < eval(zzsibling(zzchild(root))));
	case GT:
		return(eval(zzchild(root)) > eval(zzsibling(zzchild(root))));
	case LE:
		return(eval(zzchild(root)) <= eval(zzsibling(zzchild(root))));
	case GE:
		return(eval(zzchild(root)) >= eval(zzsibling(zzchild(root))));
	case SHR:
		return(eval(zzchild(root)) ASR eval(zzsibling(zzchild(root))));
	case SHL:
		return(eval(zzchild(root)) << eval(zzsibling(zzchild(root))));
	case ADD:
		return(eval(zzchild(root)) + eval(zzsibling(zzchild(root))));
	case SUB:
		/* Is this subtract or negate? */
		if (zzsibling(zzchild(root))) {
			return(eval(zzchild(root)) - eval(zzsibling(zzchild(root))));
		} else {
			return(- eval(zzchild(root)));
		}
	case MUL:
		return(eval(zzchild(root)) - eval(zzsibling(zzchild(root))));
	case DIV:
		return(eval(zzchild(root)) / eval(zzsibling(zzchild(root))));
	case MOD:
		return(eval(zzchild(root)) % eval(zzsibling(zzchild(root))));
	case NOT:
		return(~ eval(zzchild(root)));
	case LNOT:
		return(! eval(zzchild(root)));
	case DOT:
		return(lc);
	case DEFINED:
		return(sym[zzchild(root)->sym].defined != 0);
	case WORD:
		if (sym[root->sym].defined == 0) {
			++notdefined;
		}
		/* Fall through */
	case INST:
	case NUM:
		reference(root->sym);
		return(sym[root->sym].val);
	case ASSIGN:
		dsave = notdefined;
		notdefined = 0;
		i = eval(zzsibling(zzchild(root)));
		sym[zzchild(root)->sym].val = i;
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined = dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASMIN:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val;
		i = ((i < j) ? i : j);
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASMAX:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val;
		i = ((i < j) ? i : j);
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASOROR:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val;
		i = (i || j);
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASANDAND:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val;
		i = (i && j);
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASADD:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val + j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASSUB:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val - j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASMUL:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val * j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASDIV:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val / j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASMOD:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val % j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASSHR:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val ASR j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASSHL:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val << j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASAND:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val & j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASXOR:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val ^ j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ASOR:
		dsave = notdefined;
		notdefined = 0;
		j = eval(zzsibling(zzchild(root)));
		i = sym[zzchild(root)->sym].val | j;
		sym[zzchild(root)->sym].val = i;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		sym[zzchild(root)->sym].defined = (notdefined == 0);
		notdefined += dsave;
		reference(zzchild(root)->sym);
		return(i);
	case ADDADD:
		i = sym[zzchild(root)->sym].val;
		sym[zzchild(root)->sym].val = i + 1;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		reference(zzchild(root)->sym);
		return(i);
	case SUBSUB:
		i = sym[zzchild(root)->sym].val;
		sym[zzchild(root)->sym].val = i - 1;
		notdefined += (sym[zzchild(root)->sym].defined == 0);
		reference(zzchild(root)->sym);
		return(i);
	}
}

int
dogen(register AST *root,
register AST *spec)
{
	/* Match & generate code for one instruction...
	   returns 0 if pattern is matched
	*/
	register AST *i;
	register AST *s;

	if (spec == 0) {
		aikerror("No specification matched %s\n",
			 sym[root->sym].text);
		return(0);
	}

	/* These roots must match,
	   unless the spec is really an enumerative alias;
	   in either case, no need to check it
	*/
	sym[this].val = sym[root->sym].val;
	i = zzchild(root);
	s = zzchild(spec);

	/* Now walk the root siblings */
	while ((i != 0) &&
	       (s != 0) &&
	       (sym[s->sym].typ != IS)) {
		if (sym[s->sym].typ == QUEST) {
			notdefined = 0;
			if (eval(zzchild(s)) == 0) {
				if (notdefined == 0) {
					return(1);
				}
			}
			s = zzsibling(s);
		} else {
			if (i->sym != s->sym) {
				/* Mismatch; problem or meta symbol? */
				if ((sym[s->sym].typ != WORD) &&
				    (sym[s->sym].typ != INST)) {
/*
					aikerror("Specification for %s does not allow %s\n",
						 sym[root->sym].text,
						 sym[i->sym].text);
*/
					return(1);
				}

				/* Meta symbol; define it...
				   inheriting the "not defined" property
				   from expression evaluation
				*/
				notdefined = 0;
				sym[s->sym].val = eval(i);
				sym[s->sym].defined = (notdefined == 0);
			}

			/* Bump to next sibling */
			i = zzsibling(i);
			s = zzsibling(s);
		}
	}

	if ((s != 0) && (sym[s->sym].typ == QUEST)) {
		notdefined = 0;
		if (eval(zzchild(s)) == 0) {
			if (notdefined == 0) {
				return(1);
			}
		}
		s = zzsibling(s);
	}

	/* Ok; the = part should be all that's left */
	if ((s != 0) && (sym[s->sym].typ == IS)) {
		register long long int output = 0;
		register int totalbits = 0;

		if (i != 0) {
			return(1);
		}

		s = zzsibling(s);
		while (s != 0) {
			register long long int val, bits;

			switch (sym[s->sym].typ) {
			case ERROR:
				notdefined = 0;
				if ((eval(zzchild(s)) != 0) &&
				    (notdefined == 0)) {
					aikerror(sym[zzsibling(zzchild(s))->sym].text);
				}
				goto nextthing;
			case WARN:
				notdefined = 0;
				if ((eval(zzchild(s)) != 0) &&
				    (notdefined == 0)) {
					aikwarn(sym[zzsibling(zzchild(s))->sym].text);
				}
				goto nextthing;
			case COLON:
				val = eval(zzchild(s));
				bits = eval(zzsibling(zzchild(s)));
				break;
			default:
				/* Treat as word-width field */
				val = eval(s);
				bits = seg[segment].width;
			}

			if (bits > 0) {
				output <<= bits;
				output |= (val & ((1LL << bits) - 1LL));
				totalbits += bits;
			}

nextthing:		s = zzsibling(s);
		}

		gen(totalbits, output);
	} else {
		return(1);
	}

	return(0);
}


void
dopass(register AST *root)
{
	register AST *child;
	register int val;

	while (root != 0) {
		child = zzchild(root);

		switch (sym[root->sym].typ) {
		case MYEOF:
			return;
		case ORG:
			if (!disabled) {
				lc = eval(child);
			}
			break;
		case IF:
			if ((disabled > 0) ||
			    (eval(child) == 0)) {
				++disabled;
			}
			break;
		case IFREF:
			if ((disabled > 0) ||
			    (sym[child->sym].refd == 0)) {
				++disabled;
			}
			break;
		case ELSE:
			if (disabled < 2) {
				disabled ^= 1;
			}
			break;
		case END:
			disabled -= (disabled > 0);
			break;
		case SEGNAME:
			if (!disabled) {
				segment = sym[root->sym].val;
			}
			break;
		case DW:
			if (!disabled) {
				do {
					gen(seg[segment].width,
					    eval(child));
					child = zzsibling(child);
				} while (child);
			}
			break;
		case DS:
			if (!disabled) {
				val = eval(child);
				while (val > 0) {
					gen(seg[segment].width,
					    0);
					--val;
				}
			}
			break;
		case ALIGN:
			if (!disabled) {
				val = eval(child);
				while ((lc % val) != 0) {
					gen(seg[segment].width,
					    0);
				}
			}
			break;
		case EQU:
			if (!disabled) {
				val = eval(zzsibling(child));
				if (val != sym[child->sym].val) {
					++changed;
				}
				sym[child->sym].val = val;
				sym[child->sym].defined = 1;
				reference(child->sym);
			}
			break;
		case SET:
			if (!disabled) {
				sym[child->sym].val = eval(zzsibling(child));
				sym[child->sym].defined = 1;
				reference(child->sym);
			}
			break;
		case ASSIGN:
		case ASADD:
		case ASSUB:
		case ASMUL:
		case ASDIV:
		case ASMOD:
		case ASSHR:
		case ASSHL:
		case ASAND:
		case ASXOR:
		case ASOR:
		case ADDADD:
		case SUBSUB:
			if (!disabled) {
				eval(root);
			}
			break;
		case WORD:
			if (!disabled) {
				sym[root->sym].val = lc;
				sym[root->sym].defined = 1;
				reference(root->sym);
			}
			break;
		case INST:
			if (!disabled) {
				register int i, j = 1;

				for (i=0; ((j)&&(i<ALTS)); ++i) {
					j = dogen(root, sym[root->sym].ast[i]);
				}
			}
			break;
		}

		/* Go to the next sibling */
		root = zzsibling(root);
	}
}

int
dopasses(register AST *root)
{
	/* Make as many Pass 1 as needed */
	do {
		/* Put a limit on passes... */
		if (++pass > sym[aikpasses].val) return(0);

		for (segment=0; segment<segs; ++segment) {
			seg[segment].seglc = seg[segment].org;
		}
		segment = 0;

		disabled = 0;	/* conditional assembly on */
		changed = 0;	/* no changes yet */
		generate = 0;	/* no output */
		dopass(root);
		if (errorcount > 0) goto passout;
	} while (changed);

	generate = 1;	/* generate output */

	for (segment=0; segment<segs; ++segment) {
		seg[segment].seglc = seg[segment].org;
		beginsegment();
	}
	segment = 0;

	disabled = 0;	/* conditional assembly on */
	changed = 0;	/* no changes yet */
	dopass(root);

	for (segment=0; segment<segs; ++segment) {
		endsegment();
	}

	{
		register int i;

		for (i=0; i<syms; ++i) {
			if (sym[i].refd &&
			    (sym[i].typ == WORD) &&
			    (sym[i].defined == 0)) {
				aikwarn("%s referenced but not defined (treated as %d)",
					sym[i].text,
					sym[i].val);
			}
		}
	}

passout:
	for (segment=0; segment<segs; ++segment) {
		*(seg[segment].outp) = 0;
	}
	return(1);
}

void
initvars(void)
{
	zzcr_attr(&this, WORD, ".this");
	sym[this].defined = 1;
	zzcr_attr(&aikpasses, WORD, ".passes");
	sym[aikpasses].val = 100;
	sym[aikpasses].defined = 1;
	zzcr_attr(&aiklowfirst, WORD, ".lowfirst");
	sym[aiklowfirst].val = 0;
	sym[aiklowfirst].defined = 1;
	zzcr_attr(&aikversion, WORD, ".version");
	sym[aikversion].val = VERSION;
	sym[aikversion].defined = 1;
	zzcr_attr(&aikrequirecolon, WORD, ".requirecolon");
	sym[aikrequirecolon].val = 1;
	sym[aikrequirecolon].defined = 1;

	zzcr_attr(&i8hex, FORMAT, ".I8HEX");	/* Intel Hex */
	zzcr_attr(&srec, FORMAT, ".SREC");	/* Mikbug S Records */
	zzcr_attr(&mif, FORMAT, ".MIF");	/* Memory Image File */
	zzcr_attr(&vmem, FORMAT, ".VMEM");	/* Verilog MEMory image */
}

void
initfix(void)
{
	/* Fix any initialization defaults...
	   If there are no segments defined, define .text and .data
	*/
	if (segs == 0) {
		ANTLRs(specifications(&initroot),
".segment .text 16 0x10000 0 .VMEM\n"
".segment .data 16 0x10000 0 .VMEM\n"
		       );
	}
}

#ifdef	CGI

char	sinput[MAXBUF];
char	iinput[MAXBUF];

int
countlines(register char *s)
{
	register int i = 0;

	while (*s) {
		i += (*s == '\n');
		++s;
	}
	return(i);
}

int
cgiMain(void)
{
	AST *root = 0;
	int haveinput = 0;

	stderr = cgiOut;
	initvars();

	cgiFormInteger("haveinput", &haveinput, 0);

	if (haveinput == 0) {
		/* Load a demo program... */
		strcpy(&(sinput[0]),
".ONEARG .a := .this:3 .a:13\n"
".alias .ONEARG PUSH POP JUMP JNEG JZER JPOS CALL\n"
".NOARG := 7:3 .this:13\n"
".alias .NOARG ADD SUB MUL DIV RETURN\n"
		       );
		strcpy(&(iinput[0]),
"z:\tPUSH 1\n"
"\tPOP 1\n"
"\tJUMP x\n"
".origin 0x42\n"
"\tJNEG x+1\n"
"\tJZER y\n"
"y\tJPOS y-1\n"
"\tCALL z\n"
"\tADD\n"
"\tSUB\n"
"\tMUL\n"
"\tDIV\n"
"x:\tRETURN\n"
		       );
	} else {
		/* Parse the input...
		   Add newline on the end if user didn't
		*/
		register int len;

		cgiFormString("sinput", &(sinput[0]), (sizeof(sinput)-2));
		len = strlen(sinput);
		if (sinput[len-1] != '\n') {
			sprintf(&(sinput[len]), "\n");
		}

		cgiFormString("iinput", &(iinput[0]), (sizeof(iinput)-2));
		len = strlen(iinput);
		if (iinput[len-1] != '\n') {
			sprintf(&(iinput[len]), "\n");
		}
	}

	/* Output top of form... */
	cgiHeaderContentType("text/html");
	fprintf(cgiOut,
"<HTML>\n"
"<HEAD>\n"
"<TITLE>The Aggregate: AIK Assembler Interpreter from Kentucky</TITLE>\n"
"</HEAD>\n"
"<BODY>\n"
"<H1>AIK Assembler Interpreter from Kentucky</H1>\n"
"<FORM METHOD=\"POST\" ACTION=\"/cgi-bin/aik.cgi\">\n"
"<INPUT NAME=\"haveinput\" TYPE=\"hidden\" VALUE=\"1\">\n"
"<P>\n"
"\n"
"AIK implements an assembler for the instruction set of your choice\n"
"by interpretively executing a set of specifications as described at\n"
"<A HREF=\"http://aggregate.org/AIK/\"\n"
"><TT>http://aggregate.org/AIK/</TT></A>.\n"
"<P>\n"
"<H2>Your AIK " VERSTRING " Specification</H2>\n"
"<BR>\n"
"<TEXTAREA NAME=\"sinput\" ROWS=%d COLS=80>\n"
"%s"
"</TEXTAREA>\n"
"<P>\n"
"<H2>Your Assembly Language Input</H2>\n"
"<BR>\n"
"<TEXTAREA NAME=\"iinput\" ROWS=%d COLS=80>\n"
"%s"
"</TEXTAREA>\n"
"<P>\n"
"<INPUT TYPE=\"SUBMIT\" VALUE=\"Interpretively Assemble\">\n"
"</FORM>\n"
"<P>\n"
"<HR>\n"
"<P>\n",
		countlines(&(sinput[0])) + 2,
		&(sinput[0]),
		countlines(&(iinput[0])) + 2,
		&(iinput[0]));

	fprintf(cgiOut,
"<H2>Specification Parsing Messages</H2>\n"
"<P>\n"
"<PRE>\n");

	/* Parse the specifications & instructions */
	ANTLRs(specifications(&specroot), &(sinput[0]));
	initfix();

	if (errorcount > 0) {
		fprintf(cgiOut,
"</PRE>\n"
"<P>\n"
"<HR>\n"
"<P>\n");
		goto endit;
	}

	fprintf(cgiOut,
"</PRE>\n"
"<P>\n"
"<H2>Assembly Code Parsing Messages</H2>\n"
"<P>\n"
"<PRE>\n");

	ANTLRs(instructions(&instroot), &(iinput[0]));

	if (errorcount > 0) {
		fprintf(cgiOut,
"</PRE>\n"
"<P>\n"
"<HR>\n"
"<P>\n");
		goto endit;
	}

	fprintf(cgiOut,
"</PRE>\n"
"<P>\n"
"<H2>Multi-Pass Analysis Messages</H2>\n"
"<P>\n"
"<PRE>\n");

	if (dopasses(instroot)) {
		fprintf(cgiOut,
"</PRE>\n"
"<P>\n"
"<H2>Assembly Completed In %d Passes</H2>\n"
"<P>\n"
"<HR>\n",
			(pass + 1));

		for (segment=0; segment<segs; ++segment) {
			*(seg[segment].outp) = 0;
		fprintf(cgiOut,
"<P>\n"
"<H2>Generated <TT>%s</TT> Segment</H2>\n"
"<P>\n"
"<PRE>\n"
"%s\n"
"</PRE>\n",
			sym[seg[segment].name].text,
			&(seg[segment].out[0]));
		}

	} else {
		fprintf(cgiOut,
"<P>\n"
"Analysis fails after %d passes\n",
			sym[aikpasses].val);
	}
	
	/* Output bottom of form */
endit:
	fprintf(cgiOut,
"<P>\n"
"<HR>\n"
"<P>\n"
"The C program that generated this page was written by\n"
"<A HREF=\"http://aggregate.org/hankd/\">Hank Dietz</A>\n"
"using Antlr version 1.33MR33 to construct the parser and\n"
"using the <A HREF=\"http://www.boutell.com/cgic/\">CGIC</A>\n"
"library to implement the CGI interface.\n"
"<P>\n"
"<HR>\n"
"<P>\n"
"<A HREF=\"http://aggregate.org/\"\n"
"><IMG SRC=\"/IMG/talogos.jpg\" WIDTH=160 HEIGHT=32 ALT=\"The Aggregate.\"\n"
"></A> The <EM>only</EM> thing set in stone is our name.\n"
"</BODY>\n"
"</HTML>\n"
		);

	exit(0);
}
#else

char	srcname[4 * 1024];
char	namebuf[4 * 1024];

FILE	*specin;
FILE	*progin;

int
main(register int argc,
register char **argv)
{
	AST *root = 0;

	progname = argv[0];
	if ((argc != 2) && (argc != 3)) {
		fprintf(stderr,
			"Usage: %s specificationfile {assemblyfile}\n",
			progname);
		exit(1);
	}

	initvars();

	/* Process the specifications file */
	specin = fopen(argv[1], "r");
	if (specin == NULL) {
		fprintf(stderr,
			"%s: cannot read specification file %s\n",
			progname,
			argv[1]);
		exit(2);
	}

	ANTLR(specifications(&specroot), specin);
	initfix();

	/* Open the instructions file */
	if ((argc == 2) ||
	    (strcmp("-", argv[2]) == 0)) {
		/* Use standard in */
		progin = stdin;
		sprintf(srcname, "stdin");
	} else {
		/* Get the actual file */
		register int l;
		register int i;

		/* Open the source file */
		sprintf(srcname, "%s", argv[2]);
		l = strlen(srcname);
		progin = fopen(srcname, "r");
		if (progin == NULL) {
			fprintf(stderr,
				"%s: cannot read specification file %s\n",
				progname,
				srcname);
			exit(2);
		}

		/* Strip any trailing .ext from source filename */
		for (i=l-1; ((i>0)&&(srcname[i]!='.')); --i) ;
		if (srcname[i]=='.') srcname[i] = 0;
	}

	/* open each output segment */
	for (segment=0; segment<segs; ++segment) {
		sprintf(namebuf,
			"%s%s%s",
			srcname,
			((*(sym[seg[segment].name].text) == '.') ? "" : "."),
			sym[seg[segment].name].text);
		seg[segment].file = fopen(namebuf, "w");
		if (seg[segment].file == NULL) {
			fprintf(stderr,
				"%s: cannot open output file %s for .segment  %s\n",
				progname,
				namebuf,
				sym[seg[segment].name].text);
			exit(2);
		}
	}

	ANTLR(instructions(&instroot), progin);

	if (dopasses(instroot)) {
		for (segment=0; segment<segs; ++segment) {
			*(seg[segment].outp) = 0;
			fprintf(seg[segment].file,
				"%s\n",
				&(seg[segment].out[0]));
			fflush(seg[segment].file);
		}
	} else {
		fprintf(stderr,
			"%s: analysis fails after %d passes\n",
			progname,
			sym[aikpasses].val);
			exit(1);
	}

	exit(0);
}
#endif

>>

specifications
	:	( { specification } EOS! )* MYEOF
	;

specification
	:	WORDINST^
<<
	{
		register int i;

		sym[$1].typ = INST;
		for (i=0; ((i<ALTS)&&(sym[$1].ast[i])); ++i) ;
		if (i == ALTS) {
			aikwarnsyn("Too many alternatives for %s",
				   sym[$1].text);
		} else {
			sym[$1].ast[i] = #1;
		}
	}
>>
		(punct | WORDINST | testexpr)* IS (field {COMMA!})+
	|	ALIAS^ BUILTIN .
<< {
		sym[$3].typ = sym[$2].typ;
} >>
	|	ALIAS^ WORDINST
<<
		sym[$2].typ = INST;
		aliasast = &(sym[$2].ast[0]);
		aliases = 0;
>>
		(((WORD
<<
	{
		register int i;

		sym[$1].typ = INST;
		for (i=0; i<ALTS; ++i) {
			sym[$1].ast[i] = aliasast[i];
		}
		sym[$1].val = aliases;
		++aliases;
	}
>>
		  ) | (NUM
<<
		aliases = sym[$1].val;
>>
		)))*
	|	CONST^
<<
		aliases = 0;
>>
		({(NUM
<<
		aliases = sym[$1].val;
>>
		   )|(LPAREN expr RPAREN
<<
		aliases = eval(#2);
>>
		  )} ((WORD
<<
		sym[$1].val = aliases;
		sym[$1].defined = 1;
		++aliases;
>>
		      ) | ( SUB
<<
		++aliases;
>>
			  )))+
	|	WORD SET^ expr
<<
		sym[$1].val = eval(#3);
		sym[$1].defined = 1;
>>
	|	WORD ASSIGN^ expr
<<
		sym[$1].val = eval(#3);
		sym[$1].defined = 1;
>>
	|	WORD EQU^ expr
<<
		sym[$1].val = eval(#3);
		sym[$1].defined = 1;
>>
	|	SEGMENT^ WORDSEGNAME expr expr expr FORMAT
<< {
		/* .segment name width depth base format */
		register int s;

		s = ((sym[$2].typ == SEGNAME) ?
		     sym[$2].val :
		     segs++);

		seg[s].name = $2;
		seg[s].format = $6;
		seg[s].width = eval(#3);
		seg[s].depth = eval(#4);
		seg[s].org = eval(#5);
		seg[s].seglc = seg[s].org;
		seg[s].pos = (seg[s].org - 1);
		seg[s].file = 0; /* bad FILE * */
		seg[s].outp = &(seg[s].out[0]);
		seg[s]._hexbase = 0;
		seg[s]._hexcnt = 0;
		seg[s]._chksum = 0;
		seg[s]._bytesgen = 0;
		sym[$2].val = s;
		sym[$2].typ = SEGNAME;
} >>
	;

testexpr
	:	QUEST^ expr
	;

field
	:	expr { COLON^ expr }
	|	WARNERR^ LPAREN! expr {COMMA!} MESG RPAREN!
	;


instructions
	:	( { instruction } EOS! )* MYEOF!
	;

instruction
	:	((WORD COLON!) | (WORD
<<
		if (sym[aikrequirecolon].val != 0) {
			aikwarnsyn("missing : for defining label %s", sym[$1].text);
		}
>>
		  ))* { generator }
	|	WORD EQU^ expr
	|	WORD SET^ expr
	|	WORD ADDADD^
	|	WORD SUBSUB^
	|	WORD BUILTINASSIGN^ expr
	|	ORG^ expr
	|	IF^ expr
	|	IFREF^ WORD
	|	ELSE
	|	END
	|	SEGNAME
	;

generator
	:	INST^ (punct | expr)*
	|	DW^ ( expr )+
	|	DS^ expr
	|	ALIGN^ expr
	;

expr0
	:	expr { QUEST^ expr COLON! expr }
	;

expr
	:	expr1 ( OROR^ expr1 )*
	;

expr1
	:	expr2 ( ANDAND^ expr2 )*
	;

expr2
	:	expr3 ( OR^ expr3 )*
	;

expr3
	:	expr4 ( XOR^ expr4 )*
	;

expr4
	:	expr5 ( AND^ expr5 )*
	;

expr5
	:	expr6 ( ( EQ^ expr6 ) | ( NE^ expr6 ) )*
	;

expr6
	:	expr7 ( ( MIN^ expr7 ) |
			( MAX^ expr7 ) |
			( LT^ expr7 ) |
			( GT^ expr7 ) |
			( LE^ expr7 ) |
			( GE^ expr7 ) )*
	;

expr7
	:	expr8 ( ( SHR^ expr8 ) | ( SHL^ expr8 ) )*
	;

expr8
	:	expr9 ( ( ADD^ expr9 ) | ( SUB^ expr9 ) )*
	;

expr9
	:	expra ( ( MUL^ expra ) | ( DIV^ expra ) | ( MOD^ expra ) )*
	;

expra
	:	LPAREN! expr0 RPAREN!
	|	ADD! expra
	|	SUB^ expra
	|	NOT^ expra
	|	LNOT^ expra
	|	NUM
	|	INST
	|	WORD ADDADD^
	|	WORD SUBSUB^
	|	WORD {BUILTINASSIGN^ expr}
	|	DOT
	|	DEFINED^ WORD
        ;

punct
	:	"\$"
	|	"\#"
	|	"\["
	|	"\]"
	|	"\@"
	|	COMMA
	;
