%{
open Ast

let rec ast_of_list_init_declarator dl = match dl with
    [] -> EMPTY
  | elem::[] -> elem
  | elem::tail -> SEQ(elem, ast_of_list_init_declarator tail);;
%}

%token <int> CONST
%token <string> IDE 
%token INT
%token PLUS
%token MINUS
%token MUL
%token DIV
%token MOD
%token EQ
%token NEQ
%token ASSIGN
%token LT
%token GT
%token LEQ
%token GEQ
%token LAND
%token LOR
%token IF
%token ELSE
%token DO
%token WHILE
%token RETURN
%token LPAREN
%token RPAREN
%token COMMA
%token SEMICOLON
%token LBRACE
%token RBRACE
%token EOF

%left LOR
%left LAND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left MUL DIV MOD
%nonassoc THEN
%nonassoc ELSE


%start <program> main

%%

main:
    l = list(istr); EOF { ast_of_list_init_declarator l }

istr: 
    f = function_definition {f}
  | dec = declaration {dec}

declaration:
  INT; dl = separated_nonempty_list(COMMA, init_declarator); SEMICOLON { ast_of_list_init_declarator dl }

init_declarator:
  id = IDE; value = option(ASSIGN; expr = expression{expr})
  {
      match value with
          None -> VARDECL(id)
        | Some e -> VARDECL_INIT(id, e)
  }

function_definition:
  id = IDE; LPAREN; params = separated_list(COMMA,IDE); RPAREN; instr = compound_statement { FUNDECL(id, params, instr) }

compound_statement:
  LBRACE; decls = list(declaration); stats = list(statement); RBRACE { ast_of_list_init_declarator(decls@stats) } 

statement: 
  SEMICOLON; { EMPTY }
| expr = expression; SEMICOLON; { EXPR(expr) }
| s = conditional_statement { s }
| i = iterative_statement { i }
| j = jump_statement { j }
| c = compound_statement 
  { 
    match c with 
      EMPTY -> EMPTY
    | _ -> BLOCK(c) 
  }

conditional_statement: 
  IF; LPAREN; expr = expression; RPAREN; stat = statement %prec THEN { IF(expr, stat) }
| IF; LPAREN; expr = expression; RPAREN; stat1 = statement; ELSE; stat2 = statement { IFE(expr, stat1, stat2) }

iterative_statement: 
  WHILE; LPAREN; expr = expression; RPAREN; stat = statement { WHILE(expr, stat) }
| DO; stat = statement; WHILE; LPAREN; expr = expression; RPAREN; SEMICOLON { SEQ(stat, WHILE(expr, stat)) }

jump_statement: 
  RETURN; value = option(expression); SEMICOLON { RET(value) }

expression: 
  b = binary_expression { b }
| ide = IDE; ASSIGN; expr = expression { ASSIGN(ide,expr) }

binary_expression: 
  u = unary_expression { u }
| b1 = binary_expression; bop = binary_operator; b2 = binary_expression { BINARY_EXPR(b1, bop, b2) }

unary_expression:
  pexp = primary_expression { pexp }
| uop = unary_operator; uexp = unary_expression { UNARY_EXPR(uop, uexp) }

primary_expression: 
  id = IDE { IDE(id) }
| c = CONST { CONST(c) }
| id = IDE; LPAREN; vals = separated_list(COMMA, expression); RPAREN { CALL(id, vals) }
| LPAREN; expr = expression; RPAREN { expr }

%inline unary_operator: 
  MINUS { UMINUS }

%inline binary_operator: 
  MUL { MUL }
| DIV { DIV }
| PLUS { ADD }
| MINUS { SUB }
| MOD {MOD}
| LT { LT }
| GT { GT }
| LEQ { LEQ }
| GEQ { GEQ }
| EQ { EQ }
| NEQ { NEQ }
| LAND { LAND }
| LOR { LOR }