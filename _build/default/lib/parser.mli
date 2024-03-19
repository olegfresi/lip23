
(* The type of tokens. *)

type token = 
  | WHILE
  | SEMICOLON
  | RPAREN
  | RETURN
  | RBRACE
  | PLUS
  | NEQ
  | MUL
  | MOD
  | MINUS
  | LT
  | LPAREN
  | LOR
  | LEQ
  | LBRACE
  | LAND
  | INT
  | IF
  | IDE of (string)
  | GT
  | GEQ
  | EQ
  | EOF
  | ELSE
  | DO
  | DIV
  | CONST of (int)
  | COMMA
  | ASSIGN

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val main: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
