#ifndef tokens_h
#define tokens_h
/* tokens.h -- List of labelled tokens and stuff
 *
 * Generated from: aik.g
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-2001
 * Purdue University Electrical Engineering
 * ANTLR Version 1.33MR33
 */
#define zzEOF_TOKEN 1
#define MYEOF 1
#define EOS 3
#define NUM 8
#define IS 9
#define DEFINED 10
#define COLON 11
#define QUEST 12
#define OROR 13
#define ANDAND 14
#define OR 15
#define XOR 16
#define AND 17
#define EQ 18
#define NE 19
#define MIN 20
#define MAX 21
#define LT 22
#define GT 23
#define LE 24
#define GE 25
#define SHR 26
#define SHL 27
#define ADD 28
#define SUB 29
#define MUL 30
#define DIV 31
#define MOD 32
#define LPAREN 33
#define RPAREN 34
#define NOT 35
#define LNOT 36
#define COMMA 37
#define ASSIGN 38
#define ASMIN 39
#define ASMAX 40
#define ASOROR 41
#define ASANDAND 42
#define ASADD 43
#define ASSUB 44
#define ASMUL 45
#define ASDIV 46
#define ASMOD 47
#define ASSHR 48
#define ASSHL 49
#define ASAND 50
#define ASXOR 51
#define ASOR 52
#define ADDADD 53
#define SUBSUB 54
#define DOT 55
#define EQU 58
#define SET 59
#define ORG 60
#define IF 61
#define IFREF 62
#define ELSE 63
#define END 64
#define DW 65
#define DS 66
#define ALIAS 67
#define CONST 68
#define ALIGN 69
#define ERROR 70
#define WARN 71
#define SEGMENT 73
#define SEGNAME 74
#define WORD 76
#define INST 79
#define MESG 84
#define FORMAT 86

#ifdef __USE_PROTOS
void specifications(AST**_root);
#else
extern void specifications();
#endif

#ifdef __USE_PROTOS
void specification(AST**_root);
#else
extern void specification();
#endif

#ifdef __USE_PROTOS
void testexpr(AST**_root);
#else
extern void testexpr();
#endif

#ifdef __USE_PROTOS
void field(AST**_root);
#else
extern void field();
#endif

#ifdef __USE_PROTOS
void instructions(AST**_root);
#else
extern void instructions();
#endif

#ifdef __USE_PROTOS
void instruction(AST**_root);
#else
extern void instruction();
#endif

#ifdef __USE_PROTOS
void generator(AST**_root);
#else
extern void generator();
#endif

#ifdef __USE_PROTOS
void expr0(AST**_root);
#else
extern void expr0();
#endif

#ifdef __USE_PROTOS
void expr(AST**_root);
#else
extern void expr();
#endif

#ifdef __USE_PROTOS
void expr1(AST**_root);
#else
extern void expr1();
#endif

#ifdef __USE_PROTOS
void expr2(AST**_root);
#else
extern void expr2();
#endif

#ifdef __USE_PROTOS
void expr3(AST**_root);
#else
extern void expr3();
#endif

#ifdef __USE_PROTOS
void expr4(AST**_root);
#else
extern void expr4();
#endif

#ifdef __USE_PROTOS
void expr5(AST**_root);
#else
extern void expr5();
#endif

#ifdef __USE_PROTOS
void expr6(AST**_root);
#else
extern void expr6();
#endif

#ifdef __USE_PROTOS
void expr7(AST**_root);
#else
extern void expr7();
#endif

#ifdef __USE_PROTOS
void expr8(AST**_root);
#else
extern void expr8();
#endif

#ifdef __USE_PROTOS
void expr9(AST**_root);
#else
extern void expr9();
#endif

#ifdef __USE_PROTOS
void expra(AST**_root);
#else
extern void expra();
#endif

#ifdef __USE_PROTOS
void punct(AST**_root);
#else
extern void punct();
#endif

#endif
extern SetWordType zzerr1[];
extern SetWordType WORDINST_set[];
extern SetWordType WORDINST_errset[];
extern SetWordType setwd1[];
extern SetWordType zzerr4[];
extern SetWordType BUILTIN_set[];
extern SetWordType BUILTIN_errset[];
extern SetWordType WildCard_set[];
extern SetWordType WildCard_errset[];
extern SetWordType zzerr9[];
extern SetWordType zzerr10[];
extern SetWordType zzerr11[];
extern SetWordType WORDSEGNAME_set[];
extern SetWordType WORDSEGNAME_errset[];
extern SetWordType zzerr14[];
extern SetWordType zzerr15[];
extern SetWordType setwd2[];
extern SetWordType zzerr16[];
extern SetWordType WARNERR_set[];
extern SetWordType WARNERR_errset[];
extern SetWordType zzerr19[];
extern SetWordType zzerr20[];
extern SetWordType setwd3[];
extern SetWordType zzerr21[];
extern SetWordType zzerr22[];
extern SetWordType zzerr23[];
extern SetWordType zzerr24[];
extern SetWordType setwd4[];
extern SetWordType zzerr25[];
extern SetWordType BUILTINASSIGN_set[];
extern SetWordType BUILTINASSIGN_errset[];
extern SetWordType zzerr28[];
extern SetWordType zzerr29[];
extern SetWordType zzerr30[];
extern SetWordType setwd5[];
extern SetWordType zzerr31[];
extern SetWordType setwd6[];
extern SetWordType setwd7[];
extern SetWordType setwd8[];
extern SetWordType setwd9[];
extern SetWordType setwd10[];
extern SetWordType setwd11[];
extern SetWordType zzerr32[];
extern SetWordType zzerr33[];
extern SetWordType zzerr34[];
extern SetWordType zzerr35[];
extern SetWordType setwd12[];
extern SetWordType BUILTINPUNCT_set[];
extern SetWordType BUILTINSYM_set[];
