(* File automatically generated by Hacspec *)
Set Warnings "-notation-overridden,-ambiguous-paths".
From Crypt Require Import choice_type Package Prelude.
Import PackageNotation.
From extructures Require Import ord fset.
From mathcomp Require Import word_ssrZ word.
From Jasmin Require Import word.

From Coq Require Import ZArith.
From Coq Require Import Strings.String.
Import List.ListNotations.
Open Scope list_scope.
Open Scope Z_scope.
Open Scope bool_scope.

From Hacspec Require Import ChoiceEquality.
From Hacspec Require Import LocationUtility.
From Hacspec Require Import Hacspec_Lib_Comparable.
From Hacspec Require Import Hacspec_Lib_Pre.
From Hacspec Require Import Hacspec_Lib.

Open Scope hacspec_scope.
Import choice.Choice.Exports.

Obligation Tactic := (* try timeout 8 *) solve_ssprove_obligations.

Require Import Rng.
Export Rng.

Notation "'t_Nat'" := int64.

(*Not implemented yet? todo(item)*)

(*Not implemented yet? todo(item)*)

Equations main {L1 : {fset Location}} {I1 : Interface} (_ : both L1 I1 'unit) : both L1 I1 'unit :=
  main _  :=
    solve_lift (ret_both (tt : 'unit)) : both L1 I1 'unit.
Fail Next Obligation.

Definition t_State : choice_type :=
  (t_Option int64).
Equations f_sk {L : {fset Location}} {I : Interface} (s : both L I t_State) : both L I (t_Option int64) :=
  f_sk s  :=
    bind_both s (fun x =>
      solve_lift (ret_both (x : (t_Option int64)))) : both L I (t_Option int64).
Fail Next Obligation.
Equations Build_t_State {L0 : {fset Location}} {I0 : Interface} {f_sk : both L0 I0 (t_Option int64)} : both L0 I0 (t_State) :=
  Build_t_State  :=
    bind_both f_sk (fun f_sk =>
      solve_lift (ret_both ((f_sk) : (t_State)))) : both L0 I0 (t_State).
Fail Next Obligation.
Notation "'Build_t_State' '[' x ']' '(' 'f_sk' ':=' y ')'" := (Build_t_State (f_sk := y)).

Equations impl__State__apply {L1 : {fset Location}} {L2 : {fset Location}} {I1 : Interface} {I2 : Interface} {v_F : _} `{ t_Sized v_F} `{ t_FnOnce v_F int64} (self : both L1 I1 t_State) (f : both L2 I2 v_F) : both (L1 :|: L2) (I1 :|: I2) int64 :=
  impl__State__apply self f  :=
    matchb f_sk self with
    | Option_Some_case sk =>
      letb sk := ret_both ((sk) : (int64)) in
      solve_lift (f_call_once f sk)
    | Option_None_case  =>
      solve_lift (never_to_any (panic_fmt (impl_2__new_const (unsize (array_from_list [ret_both (State not initialized : chString)])))))
    end : both (L1 :|: L2) (I1 :|: I2) int64.
Fail Next Obligation.

Equations impl__State__init {L1 : {fset Location}} {I1 : Interface} (_ : both L1 I1 'unit) : both L1 I1 t_State :=
  impl__State__init _  :=
    letb '(_,out) := f_gen (thread_rng (ret_both (tt : 'unit))) in
    letb sk := Option_Some out in
    solve_lift (Build_t_State (f_sk := sk)) : both L1 I1 t_State.
Fail Next Obligation.

Equations impl__State__key_gen {L1 : {fset Location}} {I1 : Interface} (self : both L1 I1 t_State) : both L1 I1 (t_State × int64) :=
  impl__State__key_gen self  :=
    letb '(_,out) := f_gen (thread_rng (ret_both (tt : 'unit))) in
    letb pk := out in
    letb hax_temp_output := pk in
    solve_lift (prod_b (self,hax_temp_output)) : both L1 I1 (t_State × int64).
Fail Next Obligation.
