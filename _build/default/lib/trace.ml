open Robot
open Ast
open Memory

exception NoRuleApplies
(* raised when an expression or instruction cannot take a further step *)

exception WrongArguments of int * int
(* [WrongArguments (n_act, n_exp)] is raised when the number [n_act] of actual
   arguments a function is called with doesn't match the number [n_exp] of
   formal parameters of its definition *)

type state = Memory.env_stack * Memory.memory

type conf =
  | St
  (* the result of instructions that cannot be reduced further *)
  | Ret of int
  (* the result of return statements with an expression *)
  | Instr of Ast.instruction
  (* the result of computations that can be reduced further. *)
(* you may add a state component in each constructor if needed *)


let bool_of_int i = if i = 0 then false else true
let int_of_bool b = if b then 1 else 0

(*let unwrap x = match x with CONST n -> n | _ -> raise (NoRuleApplies) *)


let rec check_params l = match l with
      [] -> true
    | (CONST _)::t -> check_params t
    | _ -> false


let rec check_list l f = match l with
   [] -> []
 | (CONST n)::rest -> (CONST n)::(check_list rest f)
 | exp1::rest -> (f exp1)::rest 

  let rec find_address mem = 
  let r = (Random.int 10000000) in 
  let value = (Hashtbl.find_opt mem r) in 
  match value with 
          None -> r 
        | Some _ -> find_address mem 


 let rec app l1 l2 (mem, stack) = match (l1, l2) with
         ([], []) -> () 
      | ((CONST n)::b, c::d) -> let l = find_address mem in add_env stack c (Loc l); add_mem mem l n; (app b d  (mem, stack))
      | _ -> failwith "Error in app function"

let apply_intrinsic vals i = match i with
  | SCAN -> (match vals with 
      x1::x2::[] -> Some (scan x1 x2)
    | _ -> raise (WrongArguments (List.length vals, 2)))
  | CANNON -> (match vals with 
      x1::x2::[] -> Some (cannon x1 x2)
    | _ -> raise (WrongArguments (List.length vals, 2)))
  | DRIVE -> (match vals with 
      x1::x2::[] -> (drive x1 x2); None
    | _ -> raise (WrongArguments (List.length vals, 2)))
  | DAMAGE -> (match vals with 
      [] -> Some (damage ())
    | _ -> raise (WrongArguments (List.length vals, 0)))
  | SPEED -> (match vals with 
      [] -> Some (speed ())
    | _ -> raise (WrongArguments (List.length vals, 0)))
  | LOC_X -> (match vals with 
      [] -> Some (loc_x ())
    | _ -> raise (WrongArguments (List.length vals, 0)))
  | LOC_Y -> (match vals with 
      [] -> Some (loc_y ())
    | _ -> raise (WrongArguments (List.length vals, 0)))
  | RAND -> (match vals with 
      x::[] -> Some (rand x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
  | SQRT -> (match vals with 
      x::[] -> Some (sqrt x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
  | SIN -> (match vals with 
      x::[] -> Some (sin x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
  | COS -> (match vals with 
      x::[] -> Some (cos x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
  | TAN -> (match vals with 
      x::[] -> Some (tan x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
  | ATAN -> (match vals with 
      x::[] -> Some (atan x)
    | _ -> raise (WrongArguments (List.length vals, 1)))
(* [apply_intrinsic vals i] applies the list of values [vals] to the instrinsic
   function of the Robot module matching the constructor [i], and returns
   [Some v] if the instrinsic returns a value [v], or None if the intrinsic returns unit. *)


let rec trace1_expr (stack, mem) expr = match expr with
      NIL -> raise (NoRuleApplies)
    | IDE ide -> let value = (find_env stack ide) in (match value with
            Loc loc -> CONST (find_mem mem loc)
          | _ -> raise (UndeclaredVariable ide))
    | ASSIGN(ide, CONST n) -> let value = (find_env stack ide) in (match value with
            Loc loc -> (update_mem mem loc n); CONST n
          | _ -> raise (UndeclaredVariable ide))
    | ASSIGN(ide, expr) -> let value = trace1_expr(stack, mem) expr in ASSIGN (ide, value) 
    | CONST _ -> raise (NoRuleApplies) 
    | UNARY_EXPR(UMINUS, CONST i) -> CONST(-i)    
    | UNARY_EXPR(op, expr) -> let value = trace1_expr(stack, mem) expr in UNARY_EXPR(op, value)
    | BINARY_EXPR(CONST i, op, CONST j) -> (match op with 
                  ADD -> CONST(i + j)
                | SUB -> CONST(i - j)
                | MUL -> CONST(i * j)
                | DIV -> CONST(i / j)
                | MOD -> CONST(i mod j)
                | EQ -> CONST(int_of_bool (i = j))
                | NEQ -> CONST(int_of_bool (i <> j))
                | GT -> CONST(int_of_bool (i > j))
                | LT -> CONST(int_of_bool (i < j))
                | GEQ -> CONST(int_of_bool (i >= j))
                | LEQ -> CONST(int_of_bool (i <= j))
                | LAND -> let b1 = bool_of_int i in let b2 = bool_of_int j in CONST(int_of_bool( b1 && b2))
                | LOR -> let b1 = bool_of_int i in let b2 = bool_of_int j in CONST(int_of_bool( b1 || b2)))
    | BINARY_EXPR(CONST i, op, expr) -> let value = (trace1_expr(stack, mem) expr) in BINARY_EXPR(CONST i, op, value)
    | BINARY_EXPR(exp1, op, exp2) -> let value = (trace1_expr(stack, mem) exp1) in BINARY_EXPR(value, op, exp2)
    | CALL(ide, a_params) when check_params a_params -> add_frame stack; let e = (find_env stack ide) in (match e with 
                  Loc _ -> raise (UndeclaredVariable ide)
                | Intrinsic i -> let value = (apply_intrinsic (List.map(fun x -> (match x with 
                                                                    (CONST n) -> n 
                                                                | _ -> failwith "Error in instrinsic i")) a_params) i)
                                                                        in (match value with 
                                                                          None -> NIL 
                                                                        | Some e -> (CONST e))
                | Fun(f_params, inst) when (List.length a_params) = 
                    (List.length f_params) -> add_frame stack; app a_params f_params (mem, stack); (CALL_EXEC inst)
                | Fun(f_params, _) -> raise (WrongArguments ((List.length a_params), (List.length f_params))))
    | CALL(ide, a_params) -> let l = (check_list a_params (trace1_expr (stack, mem)))  in (CALL(ide, l))
    | CALL_EXEC(inst) -> let value = (trace1_instr (stack, mem) (Instr inst)) in (match value with 
                                      St -> let _ = pop_frame stack in NIL 
                                    | Ret i -> let _ = pop_frame stack in (CONST i)
                                    | Instr i -> CALL_EXEC i)
(* you may add a state in the return type *)
(* performs one step of small-step semantics for an expression in a certain state *)
and 
 trace1_instr (stack, mem) conf = match conf with
    | St -> raise (NoRuleApplies)
    | Ret _ -> raise (NoRuleApplies)
    | Instr instr -> (match instr with 
                    EMPTY -> St
                  | IF(CONST 0, _) -> St
                  | IF(CONST _, inst) -> Instr inst
                  | IF(exp, inst) -> let value = trace1_expr (stack, mem) exp in Instr (IF(value, inst))
                  | IFE(CONST 0, _, inst2) -> Instr inst2
                  | IFE(CONST _, inst1, _) -> Instr inst1
                  | IFE(expr, inst1, inst2) -> let value = (trace1_expr (stack, mem) expr) in (Instr (IFE(value, inst1, inst2)))
                  | WHILE(x, inst) -> Instr (WHILE_EXEC(x, inst, x))
                  | WHILE_EXEC(CONST 0, _, _) -> St
                  | WHILE_EXEC(CONST _, inst, expr) -> Instr (SEQ(inst, WHILE_EXEC(expr, inst, expr)))
                  | WHILE_EXEC(expr1, inst, expr2) ->  let value = trace1_expr(stack, mem) expr1 in Instr(WHILE_EXEC(value, inst, expr2))
                  | EXPR(NIL) | EXPR(CONST _) -> St
                  | EXPR(expr) -> let value = trace1_expr (stack, mem) expr in Instr (EXPR(value))
                  | RET(None) -> St
                  | RET(Some (CONST x)) -> Ret x
                  | RET(Some x) -> let value = trace1_expr (stack, mem) x in Instr(RET(Some value))
                  | BLOCK(instr) -> add_frame stack; Instr(BLOCK_EXEC(instr))
                  | BLOCK_EXEC(instr) -> let value = trace1_instr (stack, mem) (Instr instr) in (match value with St -> let _ = pop_frame stack in St | Ret i -> let _ = pop_frame stack in Ret i | Instr i -> Instr (BLOCK_EXEC(i)))                  | VARDECL(ide) -> let l = find_address mem in add_env stack ide (Loc l); add_mem mem l 0; St
                  | VARDECL_INIT(ide, CONST n) -> let l = find_address mem in add_env stack ide (Loc l); add_mem mem l n; St
                  | VARDECL_INIT(ide, expr) -> let value = (trace1_expr(stack, mem) expr) in Instr (VARDECL_INIT(ide, value))
                  | FUNDECL(ide, params, inst) -> (match ide with 
                                                    "main" -> (match params with 
                                                                [] -> (add_env stack ide (Fun(params, inst))); St
                                                              | _ -> raise (WrongArguments (List.length params, 0)))
                                                    | "scan" | "cannon" | "drive" | "damage" | "speed" | "loc_x" | "loc_y"
                                                    | "rand" | "sqrt" | "sin" | "cos" | "tan" | "atan" -> raise (IntrinsicOverride)
                                                    | _ -> (add_env stack ide (Fun(params, inst)); St))
                  | SEQ(instr1, instr2) -> let value = (trace1_instr (stack, mem) (Instr instr1)) in (match value with 
                                                                              Ret i -> (Ret i)
                                                                            | St -> (Instr instr2)
                                                                            | Instr i -> Instr (SEQ(i, instr2))))
(* you may add a state in the return type *)
(* performs one step of small-step semantics for an instruction in a certain state *)


let rec trace_instr st conf = try let conf' = (trace1_instr st conf) in conf::(trace_instr st conf') with NoRuleApplies -> [conf]
(* performs multiple steps of small-step semantics for an instruction,
   recording each step in a list *)


let rec trace_expr st expr = try let expr' = (trace1_expr st expr) in expr::(trace_expr st expr') with NoRuleApplies -> [expr]
(* performs multiple steps of small-step semantics for an expression, recording each step in a list *)


let trace prog = 
  let mem = init_memory () in
  let stack = init_stack () in
  let _ = (trace_instr (stack, mem) (Instr prog)) in (trace_expr (stack, mem) (CALL("main", [])))
(* [trace p] parses the program [p], records its global declarations in a 
   first environment and traces the program from the entry point [main()] *) 

(*
open Crobots.Main
open Crobots.Ast
open Crobots.Trace
open Crobot_tests.Tests

"main() { int x = 21; if (x < 0) x = x * -1; return x; }" |> parse |> trace |> last
*)