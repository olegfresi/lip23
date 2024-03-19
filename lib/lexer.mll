{
    open Parser
    exception Error of string
}


let white = [' ' '\t''\n']+
let num = ['0'-'9']|['1'-'9']['0'-'9']*
let ide = ['a'-'z']['a'-'z' 'A'-'Z' '0'-'9' '_']*
let single_comment = "//"[^'\n']*
let multi_comment = "/*"('*'[^'/']|[^'*'])*"*/"


rule read_token =
  parse
  | white { read_token lexbuf }  
  | single_comment { read_token lexbuf } 
  | multi_comment { read_token lexbuf } 
  | "(" { LPAREN }
  | ")" { RPAREN }
  | "+" { PLUS }
  | "-" { MINUS} 
  | "*" { MUL }
  | "/" { DIV }
  | "%" { MOD }
  | "==" { EQ}
  | "!=" { NEQ }
  | "=" { ASSIGN }
  | ">" { GT }
  | "<" { LT }
  | ">=" { GEQ }
  | "<=" { LEQ }
  | "&&" { LAND }
  | "||" { LOR }
  | "{" { LBRACE }
  | "}" { RBRACE }
  | "," { COMMA }
  | ";" { SEMICOLON }
  | "if" { IF }
  | "else" { ELSE }
  | "do" { DO }
  | "while" { WHILE }
  | "return" { RETURN }
  | "int" {INT}
  | ide { IDE (Lexing.lexeme lexbuf) }
  | num { CONST (int_of_string (Lexing.lexeme lexbuf)) }
  | eof { EOF }
  | _  {raise (Error (Lexing.lexeme lexbuf)) }