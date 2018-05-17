%namespace Microsoft.Pc.Parser
%visibility internal
%tokentype PTokens

%x COMMENT

%{
		 private Dictionary<string, int> keywords = null;

		 internal Microsoft.Formula.API.ProgramName SourceProgram
		 {
			get;
			set;
		 }

		 internal List<Microsoft.Formula.API.Flag> Flags
		 {
			get;
			set;
		 }

		 internal bool Failed
		 {
			 get;
			 set;
		 }

         override public void yyerror(string message, params object[] args)
         {
		   var errFlag = new Microsoft.Formula.API.Flag(
							Microsoft.Formula.API.SeverityKind.Error,
							new Microsoft.Formula.API.Span(yylloc.StartLine, yylloc.StartColumn, yylloc.EndLine, yylloc.StartColumn + yyleng, SourceProgram),
							Microsoft.Formula.API.Constants.BadSyntax.ToString(string.Format(message, args)),
							Microsoft.Formula.API.Constants.BadSyntax.Code,
							SourceProgram);
		   Failed = true;
		   Flags.Add(errFlag);
         }

		 private void MkKeywords()
		 {   
		     if (keywords != null)
			 {
				return;
			 }

			 keywords = new Dictionary<string, int>(100);

			 keywords.Add("while", (int)PTokens.WHILE);
			 keywords.Add("if", (int)PTokens.IF);
			 keywords.Add("else", (int)PTokens.ELSE);
			 keywords.Add("return", (int)PTokens.RETURN);
			 keywords.Add("new", (int)PTokens.NEW);
			 keywords.Add("this", (int)PTokens.THIS);
			 keywords.Add("null", (int)PTokens.NULL);
			 keywords.Add("pop", (int)PTokens.POP);
			 keywords.Add("true", (int)PTokens.TRUE);
			 keywords.Add("false", (int)PTokens.FALSE);
			 keywords.Add("swap", (int)PTokens.SWAP);
			 keywords.Add("move", (int)PTokens.MOVE);
			 keywords.Add("sizeof", (int)PTokens.SIZEOF);
			 keywords.Add("keys", (int)PTokens.KEYS);
			 keywords.Add("values", (int)PTokens.VALUES);

			 keywords.Add("assert", (int)PTokens.ASSERT);
			 keywords.Add("print", (int)PTokens.PRINT);
			 keywords.Add("send", (int)PTokens.SEND);
			 keywords.Add("announce", (int)PTokens.ANNOUNCE);
			 keywords.Add("spec", (int)PTokens.SPEC);
			 keywords.Add("enum", (int)PTokens.ENUM);
			 keywords.Add("observes", (int)PTokens.OBSERVES);
			 keywords.Add("raise", (int)PTokens.RAISE);
			 keywords.Add("halt", (int)PTokens.HALT);

			 keywords.Add("int", (int)PTokens.INT);
			 keywords.Add("bool", (int)PTokens.BOOL);
			 keywords.Add("any", (int)PTokens.ANY);
			 keywords.Add("seq", (int)PTokens.SEQ);
			 keywords.Add("map", (int)PTokens.MAP);

			 keywords.Add("type", (int)PTokens.TYPE);
			 keywords.Add("include", (int)PTokens.INCLUDE);
			 keywords.Add("main", (int)PTokens.MAIN);
			 keywords.Add("event", (int)PTokens.EVENT);
			 keywords.Add("eventset", (int)PTokens.EVENTSET);
			 keywords.Add("machine", (int)PTokens.MACHINE);
			 keywords.Add("assume", (int)PTokens.ASSUME);
			 keywords.Add("default", (int)PTokens.DEFAULT);

			 keywords.Add("var", (int)PTokens.VAR);
			 keywords.Add("start", (int)PTokens.START);
			 keywords.Add("hot", (int)PTokens.HOT);
			 keywords.Add("cold", (int)PTokens.COLD);
			 keywords.Add("fun", (int)PTokens.FUN);
			 keywords.Add("action", (int)PTokens.ACTION);
			 keywords.Add("state", (int)PTokens.STATE);
			 keywords.Add("group", (int)PTokens.GROUP);

			 keywords.Add("entry", (int)PTokens.ENTRY);
			 keywords.Add("exit", (int)PTokens.EXIT);
			 keywords.Add("defer", (int)PTokens.DEFER);
			 keywords.Add("ignore", (int)PTokens.IGNORE);
			 keywords.Add("goto", (int)PTokens.GOTO);
			 keywords.Add("push", (int)PTokens.PUSH);
			 keywords.Add("on", (int)PTokens.ON);
			 keywords.Add("do", (int)PTokens.DO);
			 keywords.Add("with", (int)PTokens.WITH);

			 keywords.Add("receive", (int)PTokens.RECEIVE);
			 keywords.Add("case", (int)PTokens.CASE);

			 keywords.Add("in", (int)PTokens.IN);
			 keywords.Add("as", (int)PTokens.AS);
			 keywords.Add("receives", (int)PTokens.RECEIVES);
			 keywords.Add("sends", (int)PTokens.SENDS);
			 keywords.Add("creates", (int)PTokens.CREATES);
			 
			 keywords.Add("module", (int)PTokens.MODULE);
			 keywords.Add("compose", (int)PTokens.COMPOSE);
			 keywords.Add("union", (int)PTokens.UNION);
			 keywords.Add("hidee", (int)PTokens.HIDEE);
			 keywords.Add("hidei", (int)PTokens.HIDEI);
			 keywords.Add("export", (int)PTokens.EXPORT);
			 keywords.Add("safe", (int)PTokens.SAFE);
			 keywords.Add("rename", (int)PTokens.RENAME);
			 keywords.Add("to", (int)PTokens.TO);
			 keywords.Add("private", (int)PTokens.PRIVATE);
			 keywords.Add("implementation", (int)PTokens.IMPLEMENTATION);
			 keywords.Add("test", (int)PTokens.TEST);
			 keywords.Add("refines", (int)PTokens.REFINES);
			 keywords.Add("data", (int)PTokens.DATA);
			 keywords.Add("float", (int)PTokens.FLOAT);
			 keywords.Add("interface", (int)PTokens.INTERFACE);

             keywords.Add("qmachine", (int)PTokens.QMACHINE);
             keywords.Add("topic", (int)PTokens.TOPIC);
             keywords.Add("atleastnew", (int)PTokens.ATLEASTNEW);
             keywords.Add("atmostlose", (int)PTokens.ATMOSTLOSE);
             keywords.Add("publish", (int)PTokens.PUBLISH);
             keywords.Add("read", (int)PTokens.READ);
             keywords.Add("publishes", (int)PTokens.PUBLISHES);
             keywords.Add("subscribes", (int)PTokens.SUBSCRIBES);
             keywords.Add("topic", (int)PTokens.PERIOD);
		 }

         int GetIdToken(string txt)
         {
		    MkKeywords();

		    int tokId;
			if (keywords.TryGetValue(txt, out tokId))
			{
			   return tokId;
			}
			else 
			{
			   return (int)PTokens.ID;
			}
		}

       internal void LoadYylval()
       {
            // Trigger lazy evaluation of yytext
            int dummy = yytext.Length;
            
            yylval.str = tokTxt;
            yylloc = new QUT.Gppg.LexLocation(tokLin, tokCol, tokELin, tokECol);
       }
%}

CmntStart       \/\*
CmntEnd         \*\/
CmntStartAlt    \/\/
LF              [\n\r]
NonLF           [^\n\r]*

White0          [ \t\r\f\v]
White           {White0}|\n
Id              [A-Za-z_]([A-Za-z_0-9]*)

%%

{CmntStartAlt}{NonLF}{LF}                  { return (int)PTokens.LEX_COMMENT; }
{CmntStartAlt}{NonLF}                      { return (int)PTokens.LEX_COMMENT; }
{CmntStart}                                { BEGIN(COMMENT); return (int)PTokens.LEX_COMMENT; }
<COMMENT>{CmntEnd}                         { BEGIN(INITIAL); return (int)PTokens.LEX_COMMENT; }
<COMMENT>[.]*{LF}                          { return (int)PTokens.LEX_COMMENT; }
<COMMENT>[.]*                              { return (int)PTokens.LEX_COMMENT; }

[A-Za-z_][A-Za-z_0-9]*  			       { return GetIdToken(yytext);  }
[0-9]+									   { return (int)PTokens.INT;     }

[\"][^\"\n\r]*[\"]						   { return (int)PTokens.STR; }

[\.]                                       { return (int)PTokens.DOT;     }
[:]                                        { return (int)PTokens.COLON;   }

[,]                                        { return (int)PTokens.COMMA;     }
[;]                                        { return (int)PTokens.SEMICOLON; }

"->"                                       { return (int)PTokens.BIND;   }
"=="                                       { return (int)PTokens.EQ;     }
"="                                        { return (int)PTokens.ASSIGN; }
"+="									   { return (int)PTokens.INSERT; }
"-="                                       { return (int)PTokens.REMOVE; }
"!="                                       { return (int)PTokens.NE;     }
"<="                                       { return (int)PTokens.LE;     }
">="                                       { return (int)PTokens.GE;     }
[<]                                        { return (int)PTokens.LT;     }
[>]                                        { return (int)PTokens.GT;     }

[+]                                        { return (int)PTokens.PLUS;  }
[\-]                                       { return (int)PTokens.MINUS; }
[*]                                        { return (int)PTokens.MUL;   }
[\/]                                       { return (int)PTokens.DIV;   }

[!]										   { return (int)PTokens.LNOT;   }
"&&"									   { return (int)PTokens.LAND;   }
"||"									   { return (int)PTokens.LOR;    }

"$"									       { return (int)PTokens.NONDET; }
"$$"    							       { return (int)PTokens.FAIRNONDET; }

[{]                                        { return (int)PTokens.LCBRACE;  }
[}]                                        { return (int)PTokens.RCBRACE;  }
[\[]                                       { return (int)PTokens.LBRACKET; }
[\]]                                       { return (int)PTokens.RBRACKET; }
[(]                                        { return (int)PTokens.LPAREN;   }
[)]                                        { return (int)PTokens.RPAREN;   }

%{
    LoadYylval();
%}

%%
