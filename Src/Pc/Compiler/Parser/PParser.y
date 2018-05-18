%namespace Microsoft.Pc.Parser
%using Microsoft.Pc.Domains;


%YYSTYPE LexValue
%visibility internal

%partial
%importtokens = tokensTokens.dat
%tokentype PTokens
%parsertype PParser

%union {
	public string str;
}

%%

Program
    : EOF
	| TopDeclList
	| AnnotationSet                { AddProgramAnnots(ToSpan(@1)); }
	| AnnotationSet TopDeclList    { AddProgramAnnots(ToSpan(@1)); }
	;

TopDeclList
    : TopDecl
	| TopDeclList TopDecl 
	;

TopDecl
	: TypeDefDecl
	| InterfaceDecl
	| EventSetDecl
	| EnumTypeDefDecl
	| EventDecl
	| ImplMachineDecl
	| SpecMachineDecl
	| FunDecl
	;


/******************* Annotations *******************/ 
AnnotationSet
    : LBRACKET RBRACKET                  { PushAnnotationSet(); }
	| LBRACKET AnnotationList RBRACKET   { PushAnnotationSet(); }
	;

AnnotationList
    : Annotation
	| AnnotationList COMMA Annotation
	;

Annotation
    : ID ASSIGN NULL    { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.NULL, ToSpan(@1), ToSpan(@3));  }
	| ID ASSIGN TRUE    { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.TRUE, ToSpan(@1), ToSpan(@3));  }
	| ID ASSIGN FALSE   { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.FALSE, ToSpan(@1), ToSpan(@3)); }
	| ID ASSIGN ID      { AddAnnotStringVal($1.str, $3.str, ToSpan(@1), ToSpan(@3));                     }
	| ID ASSIGN INT     { AddAnnotIntVal($1.str, $3.str, ToSpan(@1), ToSpan(@3));                        }
	;

/******************* Type Declarations **********************/
TypeDefDecl
	: TYPE ID ASSIGN Type SEMICOLON			{ AddTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	| TYPE ID SEMICOLON                     { AddForeignTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	;

EnumTypeDefDecl
	: ENUM ID LCBRACE EnumElemList RCBRACE	{ AddEnumTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	| ENUM ID LCBRACE NumberedEnumElemList RCBRACE	{ AddEnumTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	;

EnumElemList
	: ID						{ AddEnumElem($1.str, ToSpan(@1)); }									
	| ID COMMA EnumElemList		{ AddEnumElem($1.str, ToSpan(@1)); }
	;

NumberedEnumElemList
	: ID ASSIGN INT									{ AddEnumElem($1.str, ToSpan(@1), $3.str, ToSpan(@3)); }									
	| ID ASSIGN INT COMMA NumberedEnumElemList		{ AddEnumElem($1.str, ToSpan(@1), $3.str, ToSpan(@3)); }
	;

/******************* Event Declarations *******************/ 
EventDecl
	: EVENT ID EvCardOrNone EvTypeOrNone EventAnnotOrNone SEMICOLON { AddEvent($2.str, ToSpan(@2), ToSpan(@1)); }
	;

EvCardOrNone
	: ASSERT INT									{ SetEventCard($2.str, true,  ToSpan(@1)); }
	| ASSUME INT									{ SetEventCard($2.str, false, ToSpan(@1)); }
	|												{ }
	;

EvTypeOrNone
	: COLON Type									{ SetEventType(ToSpan(@1));                }
	|												{ }
	;

EventAnnotOrNone
    : AnnotationSet                                 { AddEventAnnots(ToSpan(@1));              }
	|
	;



/******************* Interface Type and event set Declaration *************/
EventSetDecl
	: EVENTSET ID ASSIGN LCBRACE NonDefaultEventList RCBRACE SEMICOLON		{ AddEventSet($2.str, ToSpan(@2), ToSpan(@2)); }
	;

InterfaceDecl
	: INTERFACE ID LPAREN ConstTypeOrNone RPAREN RECEIVES NonDefaultEventList SEMICOLON	{ AddInterfaceDecl($2.str, true, ToSpan(@2), ToSpan(@7), ToSpan(@1)); } 
	| INTERFACE ID LPAREN ConstTypeOrNone RPAREN SEMICOLON								{ AddInterfaceDecl($2.str, false, ToSpan(@2), ToSpan(@6), ToSpan(@1)); } 
	| INTERFACE ID LPAREN ConstTypeOrNone RPAREN RECEIVES SEMICOLON						{ AddInterfaceDecl($2.str, true, ToSpan(@2), ToSpan(@6), ToSpan(@1)); } 
	;

ConstTypeOrNone
	: Type														{ SetInterfaceDeclConstType(ToSpan(@1));    }
	|												
	;


/******************* Machine Declarations *******************/
ImplMachineDecl
	: ImplMachineNameDecl MachAnnotOrNone  ReceivesSendsList LCBRACE MachineBody RCBRACE { AddMachine(ToSpan(@1), ToSpan(@5), ToSpan(@6)); }
	;

ReceivesSends
	: RECEIVES NonDefaultEventList SEMICOLON        { RecordReceives(); }
	| RECEIVES SEMICOLON							{ RecordReceives(); }
	| SENDS NonDefaultEventList SEMICOLON			{ RecordSends(); }
	| SENDS SEMICOLON								{ RecordSends(); }
	;

ReceivesSendsList
	: ReceivesSends ReceivesSendsList
	|
	;
	
SpecMachineDecl
	: SpecMachineNameDecl LCBRACE MachineBody RCBRACE	{ AddMachine(ToSpan(@1), ToSpan(@2), ToSpan(@4)); } 
	;

ImplMachineNameDecl
	: MACHINE ID { SetMachine(P_Root.UserCnstKind.REAL, $2.str, ToSpan(@2), ToSpan(@1)); } MachCardOrNone
    | QMACHINE ID { SetMachine(P_Root.UserCnstKind.REAL, $2.str, ToSpan(@2), ToSpan(@1)); } MachCardOrNone
	;

SpecMachineNameDecl
	: SPEC ID ObservesList		{ SetMachine(P_Root.UserCnstKind.SPEC, $2.str, ToSpan(@2), ToSpan(@1)); }
	;
	
ObservesList
	: OBSERVES NonDefaultEventList { crntObservesList.AddRange(crntEventList); crntEventList.Clear(); }
	;

MachCardOrNone
	: ASSERT INT									{ SetMachineCard($2.str, true,  ToSpan(@1)); }
	| ASSUME INT									{ SetMachineCard($2.str, false, ToSpan(@1)); }
	|												{ }
	;

MachAnnotOrNone
    : AnnotationSet                                 { AddMachineAnnots(ToSpan(@1));              }
	|
	;

/******************* Machine Bodies *******************/
MachineBody
	: MachineBodyItem												
	| MachineBody MachineBodyItem 					
	;

MachineBodyItem
	: VarDecl
	| FunDecl
	| StateDecl
	| Group
	;

/******************* Variable Declarations *******************/
VarDecl
	: VAR VarList COLON Type SEMICOLON	             { AddVarDecls(false, ToSpan(@1)); }
	| VAR VarList COLON Type AnnotationSet SEMICOLON { AddVarDecls(true,  ToSpan(@5)); }
	;

VarList
	: ID                  { AddVarDecl($1.str, ToSpan(@1)); }									
	| ID COMMA VarList    { AddVarDecl($1.str, ToSpan(@1)); }
	;

LocalVarDecl
	: VAR LocalVarList COLON Type SEMICOLON            { localVarStack.CompleteCrntLocalVarList(); }
	; 

LocalVarDeclList
	: LocalVarDecl LocalVarDeclList
	|
	; 

LocalVarList
	: ID					   { localVarStack.AddLocalVar($1.str, ToSpan(@1)); }									
	| LocalVarList COMMA ID    { localVarStack.AddLocalVar($3.str, ToSpan(@3)); }
	;

PayloadVarDeclOrNone
	: LPAREN ID COLON Type RPAREN { localVarStack.AddPayloadVar($2.str, ToSpan(@2)); localVarStack.Push(); }
	|                             { localVarStack.AddPayloadVar(); localVarStack.Push(); }
	;

PayloadNone
	:                             { localVarStack.AddPayloadVar(); localVarStack.Push(); }
	;

/******************* Function Declarations *******************/
FunDecl
	: FunNameDecl ParamsOrNone RetTypeOrNone FunAnnotOrNone LCBRACE StmtBlock RCBRACE { AddFunction(ToSpan(@1), ToSpan(@5), ToSpan(@7)); }
	| FunNameDecl ParamsOrNone RetTypeOrNone FunAnnotOrNone SEMICOLON { AddForeignFunction(ToSpan(@1)); }
	;

FunNameDecl
	: FUN ID { SetFunName($2.str, ToSpan(@2)); }
	;

FunAnnotOrNone
    : AnnotationSet { AddFunAnnots(ToSpan(@1)); }
	|
	;

ParamsOrNone
    : LPAREN RPAREN
	| LPAREN NmdTupTypeList RPAREN                  { SetFunParams(ToSpan(@1)); }
	;

RetTypeOrNone
    : COLON Type                                    { SetFunReturn(ToSpan(@1)); }
	| 
	;

/*******************       Group        *******************/
Group
    : GroupName LCBRACE RCBRACE             { AddGroup(); }      
    | GroupName LCBRACE GroupBody RCBRACE   { AddGroup(); }
	;

GroupBody
    : GroupItem
	| GroupBody GroupItem 
	;

GroupItem
    : StateDecl
	| Group
	;

GroupName
    : GROUP ID	{ PushGroup($2.str, ToSpan(@2), ToSpan(@1)); }
	;

/******************* State Declarations *******************/
StateDecl
	: IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE RCBRACE                  { AddState($3.str, false, ToSpan(@3), ToSpan(@1)); }
	| IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE StateBody RCBRACE        { AddState($3.str, false, ToSpan(@3), ToSpan(@1)); }	  
	| START IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE RCBRACE            { AddState($4.str, true,  ToSpan(@4), ToSpan(@1)); }
	| START IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE StateBody RCBRACE  { AddState($4.str, true,  ToSpan(@4), ToSpan(@1)); }	  
	;

IsHotOrColdOrNone
	: HOT        { SetStateIsHot(ToSpan(@1)); }
	| COLD		 { SetStateIsCold(ToSpan(@1)); }
	|
	;

StateAnnotOrNone
    : AnnotationSet { AddStateAnnots(ToSpan(@1)); }
	|
	;

StateBody
	: StateBodyItem
	| StateBodyItem StateBody 
	;

StateBodyItem
	: ENTRY PayloadVarDeclOrNone LCBRACE StmtBlock RCBRACE					{ SetStateEntry(ToSpan(@3), ToSpan(@5));                                  }	
	| ENTRY ID SEMICOLON													{ SetStateEntry($2.str, ToSpan(@2)); }			
	| EXIT PayloadNone LCBRACE StmtBlock RCBRACE							{ SetStateExit(ToSpan(@2), ToSpan(@4));                                   }
	| EXIT ID SEMICOLON														{ SetStateExit($2.str, ToSpan(@2));                                 }
	| DEFER NonDefaultEventList TrigAnnotOrNone SEMICOLON					{ AddDefersOrIgnores(true,  ToSpan(@1));            }		
	| IGNORE NonDefaultEventList TrigAnnotOrNone SEMICOLON					{ AddDefersOrIgnores(false, ToSpan(@1));            }
	| OnEventList DO ID TrigAnnotOrNone SEMICOLON							{ AddDoNamedAction($3.str, ToSpan(@3), ToSpan(@1)); }
	| OnEventList DO TrigAnnotOrNone PayloadVarDeclOrNone LCBRACE StmtBlock RCBRACE					{ AddDoAnonyAction(ToSpan(@5), ToSpan(@7), ToSpan(@1)); }
	| OnEventList PUSH StateTarget TrigAnnotOrNone SEMICOLON				{ AddTransition(true, ToSpan(@1));           }
 	| OnEventList GOTO StateTarget TrigAnnotOrNone SEMICOLON				{ AddTransition(false, ToSpan(@1));          } 
	| OnEventList GOTO StateTarget TrigAnnotOrNone WITH PayloadVarDeclOrNone LCBRACE StmtBlock RCBRACE { AddTransitionWithAction(ToSpan(@7), ToSpan(@9), ToSpan(@1));           }
	| OnEventList GOTO StateTarget TrigAnnotOrNone WITH ID SEMICOLON		{ AddTransitionWithAction($6.str, ToSpan(@6), ToSpan(@1));           }
	;

OnEventList
	: ON EventList				{ onEventList = new List<P_Root.EventName>(crntEventList); crntEventList.Clear(); }
	;

NonDefaultEventList
	: NonDefaultEventId
	| NonDefaultEventList COMMA NonDefaultEventId 
	;

EventList
	: EventId
	| EventList COMMA EventId
	;

EventId
	: ID        { AddToEventList($1.str, ToSpan(@1));                      }
	| HALT      { AddToEventList(P_Root.UserCnstKind.HALT, ToSpan(@1));    }
	| NULL      { AddToEventList(P_Root.UserCnstKind.NULL, ToSpan(@1)); }
	;

NonDefaultEventId
	: ID        { AddToEventList($1.str, ToSpan(@1));                      }
	| HALT      { AddToEventList(P_Root.UserCnstKind.HALT, ToSpan(@1));    }
	;

TrigAnnotOrNone
    : AnnotationSet  { SetTrigAnnotated(ToSpan(@1)); }
	|
	;

/******************* Type Expressions *******************/

Type
	: NULL                                  { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.NULL,    ToSpan(@1))); }
	| BOOL                                  { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.BOOL,    ToSpan(@1))); }
	| INT                                   { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.INT,     ToSpan(@1))); }
	| FLOAT                                 { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.FLOAT,     ToSpan(@1))); }
	| EVENT                                 { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.EVENT,   ToSpan(@1))); }
	| MACHINE                               { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.MACHINE, ToSpan(@1))); }	
    | QMACHINE                              { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.MACHINE, ToSpan(@1))); }
	| DATA									{ PushDataType(ToSpan(@1)); }
	| ANY                                   { PushAnyWithPerm(ToSpan(@1)); }
	| ANY LT ID GT							{ PushAnyWithPerm(ToSpan(@1), $3.str, ToSpan(@3)); }
	| ID                                    { PushNameType($1.str, ToSpan(@1)); }
	| SEQ LBRACKET Type RBRACKET            { PushSeqType(ToSpan(@1)); }
	| MAP LBRACKET Type COMMA Type RBRACKET { PushMapType(ToSpan(@1)); }
	| LPAREN TupTypeList RPAREN	
	| LPAREN NmdTupTypeList RPAREN	
	;

TupTypeList
	: Type						{ PushTupType(ToSpan(@1), true);  }
	| Type COMMA TupTypeList	{ PushTupType(ToSpan(@1), false); }
	;

QualifierOrNone
	: SWAP		{ qualifier.Push(MkUserCnst(P_Root.UserCnstKind.SWAP, ToSpan(@1))); }
	| MOVE		{ qualifier.Push(MkUserCnst(P_Root.UserCnstKind.MOVE, ToSpan(@1))); }
	|			{ qualifier.Push(P_Root.MkUserCnst(P_Root.UserCnstKind.NONE)); }
	;

NmdTupTypeList
	: ID COLON Type 					  { PushNmdTupType($1.str, ToSpan(@1), true);  }			
	| ID COLON Type COMMA NmdTupTypeList  { PushNmdTupType($1.str, ToSpan(@1), false); }	
	;

/******************* Statements *******************/

Stmt
	: SEMICOLON                                               { PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1));      }
	| LCBRACE RCBRACE                                         { PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1));      }
	| POP SEMICOLON                                           { PushNulStmt(P_Root.UserCnstKind.POP,   ToSpan(@1));      }
	| LCBRACE StmtList RCBRACE                                { }
	| ASSERT Exp SEMICOLON                                    { PushAssert(ToSpan(@1));                                  }
	| ASSERT Exp COMMA STR SEMICOLON                          { PushAssert($4.str.Substring(1,$4.str.Length-2), ToSpan(@4), ToSpan(@1)); }
	| PRINT STR SEMICOLON									  { PushPrint($2.str.Substring(1,$2.str.Length-2), ToSpan(@2), ToSpan(@1), false);  }
	| PRINT STR COMMA ExprArgList SEMICOLON                   { PushPrint($2.str.Substring(1,$2.str.Length-2), ToSpan(@2), ToSpan(@1), true);  }
	| RETURN SEMICOLON                                        { PushReturn(false, ToSpan(@1));                           }
	| RETURN Exp SEMICOLON                                    { PushReturn(true, ToSpan(@1));                            }
	| Exp ASSIGN Exp QualifierOrNone SEMICOLON                { PushBinStmt(P_Root.UserCnstKind.ASSIGN, ToSpan(@1));     }
	| Exp REMOVE Exp SEMICOLON                                { PushBinStmt(P_Root.UserCnstKind.REMOVE, ToSpan(@1));     }
	| Exp INSERT Exp QualifierOrNone SEMICOLON				  { PushBinStmt(P_Root.UserCnstKind.INSERT, ToSpan(@1));	 }
	| WHILE LPAREN Exp RPAREN Stmt                            { PushWhile(ToSpan(@1));                                   }
	| IF LPAREN Exp RPAREN Stmt ELSE Stmt %prec ELSE          { PushIte(true, ToSpan(@1));                               }					
	| IF LPAREN Exp RPAREN Stmt		                          { PushIte(false, ToSpan(@1));                              }
	| NEW ID LPAREN RPAREN SEMICOLON						  { PushNewStmt($2.str, ToSpan(@2), false, ToSpan(@1)); }
	| NEW ID LPAREN ExprArgList RPAREN SEMICOLON 		      { PushNewStmt($2.str, ToSpan(@2), true, ToSpan(@1)); }
	| ID LPAREN RPAREN SEMICOLON                              { PushFunStmt($1.str, false, ToSpan(@1));                  }
	| ID LPAREN ExprArgList RPAREN SEMICOLON                  { PushFunStmt($1.str, true,  ToSpan(@1));                  }						
	| RAISE Exp SEMICOLON                                     { PushRaise(false, ToSpan(@1));                            }
	| RAISE Exp COMMA ExprArgList SEMICOLON                   { PushRaise(true,  ToSpan(@1));                            }
	| SEND Exp COMMA Exp SEMICOLON                            { PushSend(false, ToSpan(@1)); }
	| SEND Exp COMMA Exp COMMA ExprArgList SEMICOLON          { PushSend(true,  ToSpan(@1)); }
	| ANNOUNCE Exp SEMICOLON								  { PushAnnounce(false, $2.str, ToSpan(@1));      }
	| ANNOUNCE Exp COMMA ExprArgList SEMICOLON                { PushAnnounce(true, $2.str, ToSpan(@1));       }
	| ReceiveStmt LCBRACE CaseList RCBRACE					  { PushReceive(ToSpan(@1)); }
	| GOTO GotoTarget SEMICOLON							      { PushGoto(false, ToSpan(@1)); }
	| GOTO GotoTarget COMMA ExprArgList SEMICOLON	          { PushGoto(true, ToSpan(@1)); }
	;

ReceiveStmt
	: RECEIVE												  { localVarStack.PushCasesList(); }
	;

Case 
	: CaseEventList PayloadVarDeclOrNone LCBRACE StmtBlock RCBRACE 		{ AddCaseAnonyAction(ToSpan(@1), ToSpan(@3), ToSpan(@5)); }
	;

CaseEventList
	: CASE EventList COLON
	;

CaseList
	: Case	
	| CaseList Case
	;
	 
StmtBlock
	: LocalVarDeclList			{ PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1)); }    
    | LocalVarDeclList StmtList
	;

StmtList
	: Stmt
	| Stmt StmtList    { PushSeq(); }													
	;

StateTarget
    : ID                  { QualifyStateTarget($1.str, ToSpan(@1)); }
	| StateTarget DOT ID   { QualifyStateTarget($3.str, ToSpan(@3)); }
	;

GotoTarget
    : ID                  { QualifyGotoTarget($1.str, ToSpan(@1)); }
	| GotoTarget DOT ID   { QualifyGotoTarget($3.str, ToSpan(@3)); }
	;

/******************* Value Expressions *******************/

Exp
  : Exp_8
  ;

Exp_8 
	: Exp_8 LOR Exp_7	{ PushBinExpr(P_Root.UserCnstKind.OR, ToSpan(@2)); }
	| Exp_7
	;

Exp_7
	: Exp_7 LAND Exp_6	{ PushBinExpr(P_Root.UserCnstKind.AND, ToSpan(@2)); }
	| Exp_6
	;

Exp_6 
	: Exp_5 EQ Exp_5 { PushBinExpr(P_Root.UserCnstKind.EQ,  ToSpan(@2)); }
	| Exp_5 NE Exp_5 { PushBinExpr(P_Root.UserCnstKind.NEQ, ToSpan(@2)); }
	| Exp_5
	;

Exp_5 
	: Exp_4 LT Exp_4 { PushBinExpr(P_Root.UserCnstKind.LT, ToSpan(@2)); }
	| Exp_4 LE Exp_4 { PushBinExpr(P_Root.UserCnstKind.LE, ToSpan(@2)); }
	| Exp_4 GT Exp_4 { PushBinExpr(P_Root.UserCnstKind.GT, ToSpan(@2)); }
	| Exp_4 GE Exp_4 { PushBinExpr(P_Root.UserCnstKind.GE, ToSpan(@2)); }
	| Exp_4 IN Exp_4 { PushBinExpr(P_Root.UserCnstKind.IN, ToSpan(@2)); }
	| Exp_4
	;

Exp_4 
	: Exp_4 AS Type { PushCast(ToSpan(@2)); }
	| Exp_4 TO Type { PushConvert(ToSpan(@2)); }	
	| Exp_3
	;

Exp_3 
	: Exp_3 PLUS Exp_2   { PushBinExpr(P_Root.UserCnstKind.ADD, ToSpan(@2)); }	
	| Exp_3 MINUS Exp_2  { PushBinExpr(P_Root.UserCnstKind.SUB, ToSpan(@2)); }
	| Exp_2
	;

Exp_2 
	: Exp_2 MUL Exp_1  { PushBinExpr(P_Root.UserCnstKind.MUL,    ToSpan(@2)); }	
	| Exp_2 DIV Exp_1  { PushBinExpr(P_Root.UserCnstKind.DIV, ToSpan(@2)); }
	| Exp_1
	;

Exp_1 
	: MINUS Exp_0 { PushUnExpr(P_Root.UserCnstKind.NEG, ToSpan(@1)); }
	| LNOT  Exp_0 { PushUnExpr(P_Root.UserCnstKind.NOT, ToSpan(@1)); }
	| Exp_0
	;

Exp_0 
    : TRUE                                   { PushNulExpr(P_Root.UserCnstKind.TRUE,       ToSpan(@1)); }
    | FALSE                                  { PushNulExpr(P_Root.UserCnstKind.FALSE,      ToSpan(@1)); }
    | THIS                                   { PushNulExpr(P_Root.UserCnstKind.THIS,       ToSpan(@1)); }
    | NONDET                                 { PushNulExpr(P_Root.UserCnstKind.NONDET,     ToSpan(@1)); }
    | FAIRNONDET                             { PushNulExpr(P_Root.UserCnstKind.FAIRNONDET, ToSpan(@1)); }
    | NULL                                   { PushNulExpr(P_Root.UserCnstKind.NULL,       ToSpan(@1)); }
    | HALT                                   { PushNulExpr(P_Root.UserCnstKind.HALT,       ToSpan(@1)); }
	| INT                                    { PushIntExpr($1.str,  ToSpan(@1));                        }
	| Exp_float                              
    | ID                                     { PushName($1.str,     ToSpan(@1));                        }         
	| Exp_0 DOT ID                           { PushField($3.str,    ToSpan(@3));                        }   
	| Exp_0 DOT INT                          { PushFieldInt($3.str, ToSpan(@3));                        }   
	| Exp_0 LBRACKET Exp RBRACKET            { PushBinExpr(P_Root.UserCnstKind.IDX,        ToSpan(@2)); }
	| LPAREN Exp RPAREN                      { }
    | KEYS LPAREN Exp RPAREN                 { PushUnExpr(P_Root.UserCnstKind.KEYS,   ToSpan(@1));      }
    | VALUES  LPAREN Exp RPAREN              { PushUnExpr(P_Root.UserCnstKind.VALUES, ToSpan(@1));      }
    | SIZEOF  LPAREN Exp RPAREN              { PushUnExpr(P_Root.UserCnstKind.SIZEOF, ToSpan(@1));      }
    | DEFAULT LPAREN Type RPAREN             { PushDefaultExpr(ToSpan(@1));                             }
	| NEW ID LPAREN RPAREN					 { PushNewExpr($2.str, ToSpan(@2), false, ToSpan(@1)); }
	| NEW ID LPAREN ExprArgList RPAREN		 { PushNewExpr($2.str, ToSpan(@2), true, ToSpan(@1)); }
	| LPAREN Exp COMMA             RPAREN    { PushTupleExpr(true);                                     }
	| LPAREN Exp COMMA ExprArgList RPAREN    { PushTupleExpr(false);                                    }
	| ID LPAREN RPAREN                       { PushFunExpr($1.str, false, ToSpan(@1));                  }
	| ID LPAREN ExprArgList RPAREN           { PushFunExpr($1.str, true, ToSpan(@1));                   }
	| LPAREN ID ASSIGN Exp COMMA RPAREN      { PushNmdTupleExpr($2.str, ToSpan(@2), true);              }
	| LPAREN ID ASSIGN Exp COMMA 
	  NmdExprArgList       RPAREN            { PushNmdTupleExpr($2.str, ToSpan(@2), false);             }
	;

Exp_float
	: DOT INT                                                  { PushFloatExpr("0", $2.str, ToSpan(@1));    }
	| INT DOT INT					                           { PushFloatExpr($1.str, $3.str, ToSpan(@1));    }
	;

// An arg list that is always packed into an exprs.
ExprArgList
	: Exp QualifierOrNone					{ MoveValToExprs(true);  }
	| Exp QualifierOrNone COMMA ExprArgList { PushExprs();           }
	;

// A named arg list that is always packed into named exprs.
NmdExprArgList
	: ID ASSIGN Exp		                 { MoveValToNmdExprs($1.str, ToSpan(@1));  }
	| ID ASSIGN Exp COMMA NmdExprArgList { PushNmdExprs($1.str, ToSpan(@1));       }
	;

%%