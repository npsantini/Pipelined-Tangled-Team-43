#
# PCCTS makefile for: aik.g
#
DLG_FILE = parser.dlg
ERR_FILE = err.c
HDR_FILE = stdpccts.h
TOK_FILE = tokens.h
K = 1

# Location of PCCTS header files
ANTLR_H=pccts/h

# Location of PCCTS executables
DLG=pccts/bin/dlg
ANTLR=pccts/bin/antlr

CFLAGS = -I. -I$(ANTLR_H)
AFLAGS = -gt -ck 4 -fe err.c -fh stdpccts.h -fl parser.dlg -ft tokens.h -k $(K)
DFLAGS = -C2 -i
GRM = aik.g
CGISRC = scan.c aik.c err.c cgic.c
SRC = scan.c aik.c err.c
OBJ = scan.o aik.o err.o

aik: $(OBJ) $(SRC)
	cc -o aik $(CFLAGS) $(OBJ)

aik.cgi: $(CGIOBJ) $(CGISRC)
	cc -o aik.cgi $(CFLAGS) $(CGISRC) -DCGI=1
	chmod +s aik.cgi

aik.c parser.dlg : aik.g aikout.c pccts/bin/antlr
	$(ANTLR) $(AFLAGS) aik.g

scan.c : parser.dlg
	$(DLG) $(DFLAGS) parser.dlg scan.c

pccts/bin/antlr:
	(cd pccts ; make clean ; make)

clean:
	rm -f aik.c parser.dlg scan.c *.o aik aik.cgi
	(cd pccts ; make clean)

