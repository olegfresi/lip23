exception IntrinsicOverride
(* raised when a user program attempts to redefine an intrinsic function *)

exception UndeclaredVariable of string
(* [UndeclaredVariable x] is raised when a user program attempts to use the
   undeclared variable [x] *)

type loc = int
(* the type of memory locations or addresses *)

type ide = string
(* the type of variable names *)

type memval = int
(* the type of memory items *)

type envval =
  | Loc of loc
  | Fun of (Ast.parameters * Ast.instruction)
  | Intrinsic of Ast.intrinsic
(* the type of environment items *)

type memory = (loc, memval) Hashtbl.t
(* a map from loc to memval *)

type environment = (ide, envval) Hashtbl.t
(* a map from ide to envval *)

type stackval = environment
(* the type of stack items *)

type env_stack = stackval Stack.t
(* a stack of stackval *)

(* you may expose these types for debugging/convenience *)


let init_memory () = Hashtbl.create 0
(* initializes an empty memory *)

let init_stack () = let stack = Stack.create () in let env = Hashtbl.create 0 in 
                    Hashtbl.add env "scan" (Intrinsic SCAN);
                    Hashtbl.add env "cannon" (Intrinsic CANNON);
                    Hashtbl.add env "drive" (Intrinsic DRIVE); 
                    Hashtbl.add env "damage" (Intrinsic DAMAGE);
                    Hashtbl.add env "speed" (Intrinsic SPEED); 
                    Hashtbl.add env "loc_x" (Intrinsic LOC_X); 
                    Hashtbl.add env "loc_y" (Intrinsic LOC_Y);
                    Hashtbl.add env "rand" (Intrinsic RAND);
                    Hashtbl.add env "sqrt" (Intrinsic SQRT);
                    Hashtbl.add env "cos" (Intrinsic COS);
                    Hashtbl.add env "sin" (Intrinsic SIN);
                    Hashtbl.add env "tan" (Intrinsic TAN);
                    Hashtbl.add env "atan" (Intrinsic ATAN);

                    Stack.push env stack; stack
(* initializes a stack with an environment defining the intrinsic functions *) 


let find_mem mem loc = Hashtbl.find mem loc
(* memory lookup *)


let add_mem mem loc mval = Hashtbl.add mem loc mval
(* return type depends on your memory type *)
(* [add_mem mem loc n] binds the memory location [loc] to the value [n] *)


let update_mem mem loc mval = Hashtbl.replace mem loc mval
(* return type depends on your memory type *)
(* [update_mem mem loc n] updates the value bound to [loc] to [n] *)


let find_env envs x = let top = Stack.top envs in 
    let res = Hashtbl.find_opt top x in 
        match res with 
          None -> raise (UndeclaredVariable "Undeclared variable")
        | Some e -> e                
(* [find_env env x] reads the environemnt value bound to the name [x] in the current environment *)


let add_env (stack : env_stack) (key : ide) (value : envval) = (Hashtbl.add (Stack.top stack) key value)
(* return type depends on your stack type *)
(* [add_env env x v] binds the name [x] to the environment value [v] in the current environment *)


let add_frame es = let top = Hashtbl.copy (Stack.top es) in Stack.push top es
(* return type depends on your stack type *)
(* pushes a copy of the top environment to the stack *)


let pop_frame es = Stack.pop es
(* pops and returns the top environment *)