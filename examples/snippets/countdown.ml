(*
  The countdown problem, with lazy list comprehension, by
  David Teller, released under the BSD License.

  This code is based on Martijn Vermaat's OCaml Countdown problem
  [1], released under the BSD License. In turn, that code is based
  on Graham Hutton's work [2], also released under the BSD License.

  Example problem instance:

    Numbers (1,3,7,10,25,50) with 765 should
    yield:

    (((25-7)-3)*(1+50))
    ((25-(3+7))*(1+50))
    (((25-3)-7)*(1+50))
    ((25-10)*(1+50))
    (3*((7*(50-10))-25))
    [...]

  Note: This example requires OCaml 3.11

*)

open LazyList

(************************************************
  Implementation
************************************************)

let ( !^ ) x = cons x nil

(*
  Return a list of all possible lists resulting
  from inserting e in l.
*)
let rec interleave x = function
  | lazy Nil          -> !^ (!^ x ) 
  | lazy Cons (y, ys) -> ( x ^:^ y ^:^ ys ) ^:^ [? LazyList : y ^:^ l | l <- LazyList : interleave x ys  ]
  
(*
  Return a list of all permutations of l.
*)
let rec perms l = match l with
    lazy Nil          -> !^ nil
  | lazy Cons (x, xs) -> flatten [? LazyList : interleave x l | l <- LazyList : perms xs ] 

(*
  Return a list of all sublists of l.
*)
let rec subs l = match l with
  | lazy Nil           -> !^ nil
  | lazy Cons (x, xs)  -> let ys = subs xs in ys ^@^ [? LazyList :  x ^:^ l | l <- ys  ] 


(*
  Return a list of all permutations of al
  subs lf l.
*)
let subbags l = [^ zs | ys <- subs l; zs <- perms ys ^] 


(*
  Binary operators to use.
*)

type operator = Add | Sub | Mul | Div

let ops = [^ Add; Sub; Mul; Div ^]

(*
  Applying operator o to operands m and n
  yields a natural number.
*)
let valid o m n = match o with
    Add | Mul -> true
  | Sub -> (m > n)
  | Div -> (m mod n) = 0


(*
  Applying operator o to operands m and n
  yields a natural number. (Optimized.)
*)
let valid' o m n = match o with
    Add -> (m <= n)
  | Sub -> (m > n)
  | Mul -> (m <> 1) && (n <> 1) && (m <= n)
  | Div -> (n <> 1) && (m mod n) = 0


(*
  Result of applying operator o to operands
  m and n.
*)
let apply o m n = match o with
    Add -> m + n
  | Sub -> m - n
  | Mul -> m * n
  | Div -> m / n


(*
  An expression is a single natural number or
  an application of an operator to two operands.
*)
type expression =
    Val of int
  | App of operator * expression * expression


(*
  Return a list of all natural numbers used in
  expression e.
*)
let rec values e = match e with
    Val i          -> [^ i ^] 
  | App(_, e1, e2) -> (values e1) ^@^ (values e2)


(*
  Result of evaluating expression e.
  
  Quote from Hutton:
    "Failure within eval is handled by returning
    a list of results, with the convention that a
    singleton list denotes success, and the empty
    list denotes failure."

  Maybe it is more elegant to handle this with
  exceptions.
*)
let rec eval e = match e with
    Val i when i > 0 -> [^ i ^]
  | Val _            -> [^   ^] 
  | App(o, l, r)     -> [^ apply o x y | x <- eval l; y <- eval r; valid o x y ^] 



(*
  Expression e is a solution to the problem with
  numbers and number.
*)
let solution e numbers number =
  (mem (values e) (subbags numbers)) && ((eval e) = [^ number ^] )


(*
  Return a list of all pairs (l,r) where l and r
  appended yield the list l.
*)
let rec split l = match l with
    [^  ^]   -> [^ ( [^  ^] , [^  ^] ) ^] 
  | x ^:^ xs -> ( [^  ^] , l)  ^:^  [^  (x ^:^ ls, rs) | (ls,rs) <-  (split xs)  ^] 

(*
  Lists l and r are both not empty.
*)
let ne (l, r) = not(l = [^  ^] || r = [^  ^] )

(*
  Return a list of all pairs (l,r) where l and r
  appended yield the list l and l and r are not
  empty.
*)  
let ne_split  (l:'a t) = filter ne (split l)

(*
  Given two lists L1 and L2, return a list of all
  pairs (l,r) where l is an element of L1 and r
  is an element of L2.
*)
let rec combine l r = [^  App(o, l, r) | o <- ops  ^] 



(*
  Generate a list of all possible expressions
  over the natural numbers in list l.
*)
let rec exprs ns = match ns with
    [^   ^]       -> [^  ^] 
  | [^ (n:int) ^] -> [^ Val n ^] 
  |    _          -> [^ e | (ls,rs) <- ne_split ns ;
	              l      <- exprs ls ;
		      r      <- exprs rs ;
		      e      <- combine l r  ^] 


(*
  A list of expressions using only values from
  numbers and whose evaluated value is number.
*)
let solutions numbers number =
  [^  e | ns' <- subbags numbers; e <- exprs ns' ; eval e = [^ number ^]  ^] 




(************************************************
  Below is the first optimization as suggested
  by Hutton.
************************************************)


(*
  This optimization is a real must-have in
  languages with strict evaluation like OCaml
  (and unlike Haskell).
  Invalid expressions are now filtered out
  earlier, so there will not be a lot of time
  spent on evaluating them.
  In a lazy language, a lot of this work will
  be suspended (but the optimization is still
  worth quite a bit).
*)


(*
  A result is an expression and its evaluation.
*)
type result = (expression * int)


(*
  List of possible results of applying an
  operator to l and r.
*)
let combine' (l, x) (r, y) =
    [^ (App(o, l, r), apply o x y) | o <- ops ; valid' o x y ^]

(*
  Return list of possible results for list of
  natural numbers l.
  Excuse me for the (especially in this function)
  unreadable source code due to the flatten's and
  map's. I tried to translate the list
  comprehensions of Hutton as directly as
  possible. I admit this is ugly.
*)
let rec results ns = match ns with
    [^  ^]             -> [^  ^] 
  | [^ n ^] when n > 0 -> [^ (Val n, n) ^]
  | [^ _ ^]            -> [^ ^]
  | _       -> [^ res | (ls,rs) <- ne_split ns
               ; lx      <- results ls
               ; ry      <- results rs
               ; res     <- combine' lx ry ^]




(*
  A list of expressions over numbers that yield
  number on evaluation.
*)
let solutions' numbers number =
  [^ e | ns' <- subbags numbers ; (e,m) <- results ns' ; m = number ^]



(************************************************
  Below is the second optimization as suggested
  by Hutton.

 ************************************************)


let rec eval' = function
    Val n when n>0 -> [^ n ^]
  | Val _          -> [^   ^]
  | App (o, l, r)  -> [^ apply o x y | x <- eval' l ; y <- eval' r ; valid' o x y ^]

let solution' e ns n  = mem (values e) (subbags ns) && eval' e = [^ n ^]


let combine'' (l,x) (r,y) = [^ (App (o, l, r), apply o x y) | o <- ops ; valid' o x y ^]

let rec results' = function
    [^   ^]          -> [^ ^]
  | [^ n ^] when n>0 -> [^ (Val n,n) ^]
  | [^ _ ^]          -> [^ ^]
  | ns               -> [^ res | (ls,rs) <- ne_split ns
                             ; lx      <- results' ls
                             ; ry      <- results' rs
                             ; res     <- combine'' lx ry ^]

let solutions'' ns n  = [^ e | ns' <- subbags ns ; (e,m) <- results' ns' ; m = n ^]

(************************************************
  What is left is a way to work with al this.
************************************************)


(*
  String representation of expression e.
*)
let rec expression_to_string e = 

  (*
    String representation of operator o.
  *)
  let operator_to_string o = match o with
      Add -> "+"
    | Sub -> "-"
    | Mul -> "*"
    | Div -> "/"
  in

    match e with
        Val n        -> string_of_int n
      | App(o, l, r) ->
          begin
            match l with
                Val _ -> expression_to_string l
              | _     -> "(" ^ (expression_to_string l) ^ ")"
          end
          ^ " " ^ (operator_to_string o) ^ " " ^
          begin
            match r with
                Val _ -> expression_to_string r
              | _     -> "(" ^ (expression_to_string r) ^ ")"
          end


(**
   Reads numbers into a stream
*)
let rec int_reader () = 
  match try Some (read_int ()) with _ -> None with
      Some n -> [< 'n; int_reader () >]
    | None   -> [< >]

(*
  Reads a number and a list of numbers from
  stdin and prints all solutions to that
  instance of the countdown problem.
*)
let countdown () =

  Printf.printf "The Countdown Problem\nPlease enter a positive natural number:\n ";
  
  let number = read_int () in
    
    Printf.printf "\nPlease enter some positive natural numbers ";
    Printf.printf "(each on its own line) ending\n";
    Printf.printf "with end-of-file:\n";

    let numbers = [^ n | (MoreStream) n <- int_reader () ^] in

    Printf.printf "I can make %d from these numbers in the following ways:\n" number;
    flush stdout;

    let s = solutions'' numbers number in 
      for each e in LList s do Printf.printf "\t %s\n" (expression_to_string e) done;
      let answer = 
      match length s with
	  0 -> "Sorry, there are no solutions to this problem."
	| 1 -> "This was the only solution."
	| n -> Printf.sprintf "There were %d solutions." n
      in Printf.printf "%s\n" answer


(*
  Start main program.
*)
let _ = countdown ()