char	cgispec[MAXBUFF];
char	cgiinst[MAXBUFF];

int
cgiMain(void)
{
	register int i;
	int haveinput = 0;

	cgiFormInteger("haveinput", &haveinput, 0);

	if (haveinput == 0) {
		/* Load a demo program... */
		strcpy(&(cgispec[0]),
"ONEARG addr = THIS:3 addr:13\n"
"= ONEARG PUSH POP JUMP JNEG JZER JPOS CALL\n"
"NOARG = 7:3 THIS:13\n"
"= NOARG ADD SUB MUL DIV RETURN\n"
		       );
		strcpy(&(cgiinst[0]),
"PUSH 1\n"
"POP 1\n"
"JUMP x\n"
"JNEG x\n"
"JZER x\n"
"JPOS x\n"
"CALL x\n"
"ADD\n"
"SUB\n"
"MUL\n"
"DIV\n"
"x: RETURN\n"
		       );
	} else {
		/* Parse the input */
		cgiFormString("specifications", &(cgispec[0]), (sizeof(cgispec)-1));
		cgiFormString("instructions", &(cgiinst[0]), (sizeof(cgiinst)-1));
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
"\n"
"Enter/edit your SPECIFICATIONS here:\n"
"<BR>\n"
"<TEXTAREA NAME=\"specifications\" ROWS=25 COLS=64>\n"
"%s"
"</TEXTAREA>\n"
"<P>\n"
"\n"
"Enter/edit your INSTRUCTIONS here:\n"
"<BR>\n"
"<TEXTAREA NAME=\"instructions\" ROWS=25 COLS=64>\n"
"%s"
"</TEXTAREA>\n"
"<P>\n"
"<INPUT TYPE=\"SUBMIT\" VALUE=\"Interpretively Assemble\">\n"
"<INPUT TYPE=\"RESET\" VALUE=\"Reset\">\n"
"</FORM>\n"
"<P>\n"
"<HR>\n"
"<P>\n",
		&(cgispec[0]),
		&(cgiinst[0]));

	/* Parse the specifications & instructions */
	ANTLRs(cgispecifications(&specroot), &(cgispec[0]));
	ANTLRs(cgiinstructions(&instroot), &(cgiinst[0]));

	if (dopasses()) {
		*(outp[0]) = 0;
		*(outp[1]) = 0;
		fprintf(cgiOut,
"<H2>Generated TEXT Segment</H2>\n"
"<P>\n"
"<PRE>\n"
"%s\n"
"</PRE>\n"
"<P>\n"
"<H2>Generated DATA Segment</H2>\n"
"<P>\n"
"<PRE>\n"
"%s\n"
"</PRE>\n",
			textout,
			dataout);
	} else {
		fprintf(cgiOut,
"<P>\n"
"Analysis fails after %d passes\n",
			MAXPASS);
	}
	
	/* Output bottom of form */
	fprintf(cgiOut,
"<P>\n"
"<HR>\n"
"<P>\n"
"The C program that generated this page was written by\n"
"<A HREF=\"http://aggregate.org/hankd/\">Hank Dietz</A>\n"
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
