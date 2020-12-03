#ifndef STDPCCTS_H
#define STDPCCTS_H
/*
 * stdpccts.h -- P C C T S  I n c l u d e
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-2001
 * Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33MR33
 */

#ifndef ANTLR_VERSION
#define ANTLR_VERSION	13333
#endif

#include "pcctscfg.h"
#include "pccts_stdio.h"

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

  
#define LL_K 4
#define GENAST
#define zzSET_SIZE 12
#include "antlr.h"
#include "ast.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
#endif
