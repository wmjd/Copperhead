open Printf
open Expr
open Asm

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

let stackloc si = RegOffset(-8 * si, RSP)
let throw_err code = [IMov(Reg(RDI), Const(code));
                      ICall("error");]
let check_overflow = IJo("overflow_check")
let error_non_int = "error_non_int"
let error_non_bool = "error_non_bool"

(* saves and restores rax *)
let check_bool si =
  [IMov(stackloc si, Reg(RAX));
  IAnd(Reg(RAX), Const(1));
  ICmp(Reg(RAX), Const(0));
  IJne(error_non_bool);
  IMov(Reg(RAX), stackloc si);]

let check_num = [IAnd(Reg(RAX), Const(1));
                 ICmp(Reg(RAX), Const(1));
                 IJne(error_non_int);]


(* assume arg1 is a register *)
let check_nums arg1 arg2 =
  [IAnd(arg1, arg2);
   IAnd(arg1, Const(1));
   ICmp(arg1, Const(1));
   IJne(error_non_int);]


let true_const  = HexConst(0x0000000000000002L)
let false_const = HexConst(0x0000000000000000L)
let tag_mask =    HexConst(0xFFFFFFFFFFFFFFFEL)
                
let rec well_formed_e (e : expr) (env : (string * int) list) : string list =
  let dummy_val = 42
  in let rec ext_env b = 
    match b with
    | [] -> []
    | (x, _)::more -> (x, dummy_val)::(ext_env more)  
  in let check_duplicates b =
    let rec dup b x =
      match b with
      | [] -> []
      | (x_prime, v)::more -> if x_prime = x then ["Multiple bindings for variable identifier " ^ x] else dup more x  
    in let rec walk b env = 
      match b with 
      | [] -> []
      | (x, v)::more -> (dup more x) @ (well_formed_e v env) @ (walk more ((x, dummy_val)::env)) 
    in walk b env
  in let well_formed_body body env =
    let rec aux body =
      match body with
      | [] -> failwith "well_formed_body Error: empty body (should have been detected in parsing)"
      | [e] -> well_formed_e e env
      | e::more -> (well_formed_e e env) @ (aux more)
    in aux body
  in match e with
  | ENumber(_)
  | EBool(_) -> []
  | ELet(binding, body) -> (check_duplicates binding) @ (well_formed_body body ((ext_env binding) @ env)) 
  | EId(x) -> (
    match find env x with
    | None -> ["Variable identifier " ^ x ^ " unbound"] 
    | Some(_) -> [] )
  | EIf(predicate, if_branch, else_branch) -> (well_formed_e predicate env) @ (well_formed_e if_branch env) @ (well_formed_e else_branch env)
  | EPrim1(_, arg1) -> (well_formed_e arg1 env)
  | EPrim2(_, arg1, arg2) -> (well_formed_e arg1 env) @ (well_formed_e arg2 env)
  | ESet(x, e) -> (
    match find env x with
    | None -> ["Variable identifier " ^ x ^ " unbound"] 
    | Some(_) -> [] ) @ well_formed_e e env 
  | EWhile(predicate, body) -> (well_formed_e predicate env) @ (well_formed_body body env)

type typ = Num | Bool
let rec tc (e : expr) (typ_env : (string * typ) list) : typ = 
  let type_mismatch str = failwith ("Type mismatch " ^ str)
  in let tc_prim2 op typ_env= 
    match op with
    | (Plus, e1, e2) | (Minus, e1, e2) | (Times, e1, e2) -> (
      match (tc e1 typ_env, tc e2 typ_env) with
      | (Num, Num) -> Num
      | _ -> type_mismatch "prim2 arith")
    | (Less, e1, e2) | (Greater, e1, e2) -> (
      match (tc e1 typ_env, tc e2 typ_env) with
      | (Num, Num) -> Bool
      | _ -> type_mismatch "prim2 compare")
    | (Equal, e1, e2) -> (
      match (tc e1 typ_env, tc e2 typ_env) with
      | (t1, t2) when t1 = t2 -> Bool
      | _ -> type_mismatch "prim2 equal")
  in let tc_prim1 op typ_env= 
    match op with 
	| (Add1, x) | (Sub1, x) -> (
      match (tc x typ_env) with
      | Num -> Num
      | _ -> type_mismatch "prim1 arith")
   | (IsNum, x) | (IsBool, x) -> (
      match (tc x typ_env) with
      | _ -> Bool )
  in let rec tc_body body env =
    let rec aux body =
      match body with
      | [] -> failwith "tc_body Error: empty body (should have been detected in parsing)"
      | [e] -> tc e env
      | e::more -> let _ = tc e env in aux more
    in aux body
  in let rec ext_typ_env binding (env : (string * typ) list) = 
    match binding with
    | [] -> env
    | (x, e)::more -> (ext_typ_env more ((x, tc e env)::env))
  in match e with
  | EPrim1(prim, arg1) -> tc_prim1 (prim, arg1)  typ_env
  | EPrim2(prim, arg1, arg2) -> tc_prim2 (prim, arg1, arg2) typ_env
  | EBool _ -> Bool
  | ENumber _ -> Num
  | EIf(pred, then_expr, else_expr) -> (
    match (tc pred typ_env, tc then_expr typ_env, tc else_expr typ_env) with
    | (Bool, t1, t2) when t1 = t2 -> t1
    | _ -> type_mismatch "EIf")
  | EId(x) -> (
    match (find typ_env x) with
    | Some(t) -> t
    | _ -> type_mismatch "EId" )
  | ESet(x, e) -> (
    match (tc (EId x) typ_env, tc e typ_env) with
    | (t1, t2) when t1 = t2 -> t1
    | _ -> type_mismatch "ESet")
  | EWhile(pred, body) -> (
    match (tc pred typ_env, tc_body body typ_env) with
    | Bool, t -> t
    | _ -> type_mismatch "EWhile")
  | ELet(binding, body) ->
    let new_typ_env = ext_typ_env binding typ_env
    in tc_body body new_typ_env

let check (e : expr) : string list =
  match well_formed_e e [("input", -1)] with
  | [] -> []
  | errs -> failwith (String.concat "\n" errs)

let rec compile_expr (e : expr) (si : int) (env : (string * int) list) : instruction list =
  match e with
  | EPrim1(op, e) -> compile_prim1 op e si env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si env
  | ELet(binding, body) -> 
    let vis, ext_env = compile_binding binding si env in
	let bis = compile_body body (si + List.length binding) ext_env in
	vis @ bis
  | ENumber(i) -> [IMov(Reg RAX, Const64 (Int64.add (Int64.mul i 2L) 1L) )]
  | EBool(true) -> [IMov(Reg RAX, true_const)]
  | EBool(false) -> [IMov(Reg RAX, false_const)]
  | EId(x) -> (
    match find env x with
    | None -> failwith ("compile_expr: Unbound variable identifier " ^ x) (* this should be caught before compilation in check and should never execute here *)
    | Some(i) -> [IMov(Reg RAX, stackloc i)] )
  | EIf(predicate, then_expr,else_expr) ->
    let test_bool = check_bool si in
    let pred = compile_expr predicate si env in
    let then_branch = compile_expr then_expr si env in
    let else_branch = compile_expr else_expr si env in
    let else_label = gen_temp "else" in
    let end_label = gen_temp "end_if" in
    pred @
    test_bool @
    [ ICmp(Reg(RAX), true_const);
      IJne(else_label);] @
    then_branch @
    [ IJmp(end_label);
      ILabel(else_label);] @
    else_branch @
    [ILabel(end_label)]
  | ESet(id, e) -> (match find env id with
    | None -> failwith ("compile_expr: Unbound variable identifier " ^ id) (* this should be caught before compilation in check and should never execute here *)
    | Some(i) -> let vis = compile_expr e si env in
      vis @ [IMov(stackloc i, Reg RAX)])
  | EWhile(predicate, body) ->
    let test_bool = check_bool si in
    let pred_is = compile_expr predicate si env in
    let body_is = compile_body body si env in   
    let loop_pred_label = gen_temp "loop_pred" in
    let after_loop_label = gen_temp "after_loop" in
    [ ILabel(loop_pred_label)] @
    pred_is @
    test_bool @
    [ ICmp(Reg(RAX), true_const);
      IJne(after_loop_label);] @
    body_is @
    [ IJmp(loop_pred_label);
      ILabel(after_loop_label);] 

and compile_body expr_ls si env =
  let rec aux ls =
  	match ls with
    | [] -> []
    | e::more -> (compile_expr e si env) @ (aux more)
  in aux expr_ls

(* Tail Recursive implementation needs to *reverse* the instruction list as usual trick. 
In this case, it is a little tricky because ins is built hierarchically in sections and subsections which must remain ordered *)
and compile_binding b si env = 
  let rec iter b si env ins =
    match b with
    | [] -> (List.rev ins, env)
    | (x,v)::more -> 
      let vis = compile_expr v si env in 
      let sis = [IMov(stackloc si, Reg RAX)] in
      iter more (si+1) ((x,si)::env) (sis @ (List.rev vis) @ ins)  
  in iter b si env []

and compile_prim1 op e si env =
  let prelude = compile_expr e si env in
  let instrs = match op with
    | Add1 ->
      IMov(stackloc si, Reg(RAX))::
      check_num @
      [IMov(Reg(RAX), stackloc si);
       IAdd(Reg(RAX),Const(2));
       check_overflow]
    | Sub1 ->
      IMov(stackloc si, Reg(RAX))::
      check_num @
      [IMov(Reg(RAX), stackloc si);
       ISub(Reg(RAX),Const(2));
       check_overflow]
    | IsNum ->
       [IAnd(Reg(RAX), Const(1));
       IShl(Reg(RAX), Const(1))]
    | IsBool ->
      [IAnd(Reg(RAX), Const(1));
       IXor(Reg(RAX), Const(1));
       IShl(Reg(RAX), Const(1))]
  in
  prelude @ instrs

and compile_prim2 op e1 e2 si env =
  let first_op = compile_expr e1 si env in
  let second_op = compile_expr e2 (si + 1) env in
  (* assume first arg is in rax, and in stackloc si, and second arg in stackloc si+1 *)
  let instrs,numr = match op with
    | Plus ->
      [IAnd(Reg(RAX), tag_mask);
       IAdd(Reg(RAX), stackloc (si + 1)); check_overflow],true
    | Minus ->
      [IAnd(Reg(RAX), tag_mask);
       ISub(Reg(RAX), stackloc (si + 1)); check_overflow],true
    | Times ->
      [IAnd(Reg(RAX), tag_mask);
       IMov(stackloc si, Reg(RAX));
       IMov(Reg(RAX), stackloc (si + 1));
       ISar(Reg(RAX), Const(1));
       IMul(Reg(RAX), stackloc si);
       check_overflow;
       IAdd(Reg(RAX), Const(1));],true
    | Less ->
      let less = gen_temp "less" in
      let end_label = gen_temp "end" in
      [ICmp(Reg(RAX),(stackloc (si + 1)));
       IJl(less);
       IMov(Reg(RAX), false_const);
       IJmp(end_label);
       ILabel(less);
       IMov(Reg(RAX), true_const);
       ILabel(end_label);],true
    | Greater ->
      let greater = gen_temp "greater" in
      let end_label = gen_temp "end" in
      [ICmp(Reg(RAX),(stackloc (si + 1)));
       IJg(greater);
       IMov(Reg(RAX), false_const);
       IJmp(end_label);
       ILabel(greater);
       IMov(Reg(RAX), true_const);
       ILabel(end_label);],true
    | Equal ->
      let not_equal = gen_temp "not_equal" in
      let end_label = gen_temp "end" in
      [ICmp(Reg(RAX),(stackloc (si + 1)));
       IJne(not_equal);
       IMov(Reg(RAX), true_const);
       IJmp(end_label);
       ILabel(not_equal);
       IMov(Reg(RAX), false_const);
       ILabel(end_label);],false in
  if numr then
    first_op @ [IMov((stackloc si),Reg(RAX))] @ second_op @
    (IMov(stackloc (si + 1), Reg(RAX))::
     (check_nums (Reg(RAX)) (stackloc si))) @
    (IMov(Reg(RAX), (stackloc si))::instrs)
  else
    first_op @ [IMov((stackloc si),Reg(RAX))] @ second_op @
    instrs

let compile_to_string prog =
  let _ = check prog in
  let _ = tc prog [("input", Num)] in
  let prelude = "  section .text\n" ^
                "  extern error\n" ^
                "  global our_code_starts_here\n" ^
                "our_code_starts_here:\n" ^
                "  mov [rsp - 8], rdi\n" in
  let postlude = [IRet]
                 @ [ILabel("overflow_check")] @ (throw_err 3)
                 @ [ILabel(error_non_int)] @ (throw_err 1)
                 @ [ILabel(error_non_bool)] @ (throw_err 2) in
  let compiled = (compile_expr prog 2 [("input", 1)]) in
  let as_assembly_string = (to_asm (compiled @ postlude)) in
  sprintf "%s%s\n" prelude as_assembly_string
