From Relational Require Import OrderEnrichedCategory GenericRulesSimple.

Set Warnings "-notation-overridden,-ambiguous-paths".

From mathcomp Require Import all_ssreflect all_algebra reals distr realsum
  fingroup.fingroup solvable.cyclic prime ssrnat ssreflect ssrfun ssrbool ssrnum
  eqtype choice seq fintype zmodp prime finset.

Set Warnings "notation-overridden,ambiguous-paths".

From extra Require Import rsa.

From Crypt Require Import Axioms ChoiceAsOrd SubDistr Couplings
  UniformDistrLemmas FreeProbProg Theta_dens RulesStateProb UniformStateProb
  pkg_core_definition choice_type pkg_composition pkg_rhl Casts
  Package Prelude RandomOracle.

From Coq Require Import Utf8.
From extructures Require Import ord fset fmap ffun.

From Equations Require Import Equations.
Require Equations.Prop.DepElim.
Require Import Coq.Init.Logic.
Require Import List.

Set Equations With UIP.
Set Equations Transparent.

Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

Import Num.Def.
Import Num.Theory.
Import Order.POrderTheory.

From vRATLS Require Import Signature.

Import PackageNotation.

Obligation Tactic := idtac.

Local Open Scope package_scope.


Module Type RSA_params <: SignatureParams.

  (* Message space *)
  Variable w : nat.

  (* Sampling space *)
  Variable n : nat.

  Definition pos_n : nat := 2^n.

  Definition r₀ : nat := n.+4. (* We need to have at least two primes [p] and [q]. *)
  Definition R₀ : Type := 'I_r₀.
  Definition r : nat := r₀ * r₀.
  Definition R : Type := 'I_r.

  (* the set of prime numbers. *)
  Definition prime_num : finType := {x: R₀  | prime x}.
  Definition P : {set prime_num} := [set : prime_num].

  Definition P' (y : prime_num) := (P :\ y)%SET.

  Lemma P_P'_neq : forall y, y \in P -> P :!=: P' y.
  Proof.
    unfold P'. intros.
    apply properD1 in H.
    rewrite eqtype.eq_sym.
    apply proper_neq.
    exact H.
  Qed.

  Lemma p_q_neq p q (p_in_P: p \in P) : q \in P' p -> p <> q.
  Proof.
    by rewrite /P' in_setD1; move/andP; case; move/eqP/nesym.
  Qed.

  Lemma two_ltn_r₀ : 2 < r₀.
  Proof. by rewrite /r₀; case: n. Qed.

  Definition two : R₀ := Ordinal two_ltn_r₀.
  Lemma prime2ord : prime two. Proof. by []. Qed.
  Definition two' : prime_num := exist _ two prime2ord.

  Lemma three_ltn_r₀ : 3 < r₀.
  Proof. by rewrite /r₀; case: n. Qed.

  Definition three : R₀ := Ordinal three_ltn_r₀.
  Lemma prime3ord : prime three. Proof. by []. Qed.
  Definition three' : prime_num := exist _ three prime3ord.

  Definition i_P := #|P|.
  Instance pos_i_P : Positive i_P.
  Proof.
    apply /card_gt0P. by exists two'.
  Qed.

  #[export] Instance positive_P' `(p:prime_num) : Positive #|(P' p)|.
  Proof.
    apply/card_gt0P.
    case H: (p == two'); move/eqP: H.
    - move => H; rewrite H; exists three'.
      rewrite /P' in_setD1 //=.
      apply in_setT.
    - move => H; exists two'.
      rewrite /P' in_setD1 //=.
      apply/andP; split.
      + by apply/eqP/nesym.
      + apply in_setT.
  Qed.

  Lemma p_q_neq' (p: 'fin P) (q: 'fin (P' (enum_val p))) : enum_val p != enum_val q.
  Proof.
    Search enum_val.
    apply/eqP.
    case.
    case: (enum_val q) => [p' p_prime].
    case: (enum_val p) => [q' q_prime].
    move => H.
    injection H.

  Definition R' : finType := {x:R | 0 < x}.

  Definition wf_type p q pq e d := [&& prime p, prime q, p != q,
      0 < pq, p.-1 %| pq, q.-1 %| pq &
                            e * d == 1 %[mod pq]].

  Definition Z_n_prod : finType := prod_finType R' R₀.

  Definition SecKey := Z_n_prod.
  Definition PubKey : finType := Z_n_prod.
  Definition Signature : finType := R.
  Definition Message : finType := R. (* TODO should just be [nat] *)
  Definition Challenge : finType := R.
  Definition Sample_space : finType := R₀.

End RSA_params.

Module RSA_KeyGen (π1  : RSA_params)
    <: KeyGenParams π1.

  Import π1.

  (* Encryption *)
  Definition encrypt' e p q w : nat := w ^ e %% (p * q ).

  Theorem enc_eq {p q pq d e : nat} (wf : wf_type p q pq d e) w :
    let r := Build_rsa wf in
    encrypt' d p q w = encrypt r w.
  Proof.
    by rewrite /encrypt/encrypt'/r.
  Qed.

  (* Decryption *)
  Definition decrypt' d p q w := w ^ d %% (p * q).

  Theorem dec_eq {p q pq d e : nat} (wf : wf_type p q pq d e) w :
    let r := Build_rsa wf in
    decrypt' e p q w = decrypt r w.
  Proof.
    by rewrite /encrypt/encrypt'/r.
  Qed.

  Theorem rsa_correct' {p q pq d e : nat} (wf : wf_type p q pq d e) w :
    let r := Build_rsa wf in
    decrypt' e p q (encrypt' d p q w)  = w %[mod p * q].
  Proof.
    rewrite (enc_eq wf) (dec_eq wf) /=.
    apply rsa_correct.
  Qed.

   (* Encryption *)
   Definition encrypt'' e pq w : nat := w ^ e %% pq.

   (* Decryption *)
   Definition decrypt'' d pq w := w ^ d %% pq.

   Lemma eq_dec (p q pq d w: nat) (H: pq = (p * q)%nat) : decrypt'' d pq w = decrypt' d p q w.
   Proof.
     by rewrite /decrypt''/decrypt' H.
   Qed.

   Lemma eq_enc (p q pq d w: nat) (H: pq = (p * q)%nat) : encrypt'' d pq w = encrypt' d p q w.
   Proof.
     by rewrite /encrypt''/encrypt' H.
   Qed.

   Theorem rsa_correct'' {p q pq d e : nat} (H: pq = (p * q)%nat) (wf : wf_type p q pq d e) w :
    let r := Build_rsa wf in
    decrypt'' e pq (encrypt'' d pq w)  = w %[mod pq].
  Proof.
    rewrite (eq_dec p q _ _ _ H).
    rewrite (eq_enc p q _ _ _ H).
    rewrite (enc_eq wf) (dec_eq wf) /=.
    rewrite [X in _ %% X = _ %% X]H.
    apply rsa_correct.
  Qed.

  Definition sk0 : SecKey := (exist _ 1%R (ltn0Sn 0), 1)%g.
  Definition pk0 : PubKey := (exist _ 1%R (ltn0Sn 0), 1)%g.
  Definition sig0 : Signature := 1%g.
  Definition m0 : Message := 1%g.
  Definition chal0 : Challenge := 1%g.
  Definition ss0 :Sample_space := 1%g.


  #[export] Instance positive_SecKey : Positive #|SecKey|.
  Proof.
    apply /card_gt0P. exists sk0. auto.
  Qed.
  Definition SecKey_pos : Positive #|SecKey| := _ .

  #[export] Instance positive_PubKey : Positive #|PubKey|.
  Proof.
    apply /card_gt0P. exists pk0. auto.
  Qed.
  Definition PubKey_pos : Positive #|PubKey| := _.

  #[export] Instance positive_Sig : Positive #|Signature|.
  Proof.
    apply /card_gt0P. exists sig0. auto.
  Qed.
  Definition Signature_pos: Positive #|Signature| := _.

  #[export] Instance positive_Message : Positive #|Message|.
  Proof.
    apply /card_gt0P. exists m0. auto.
  Qed.
  Definition Message_pos : Positive #|Message| := _.

  #[export] Instance positive_Chal : Positive #|Challenge|.
  Proof.
    apply /card_gt0P. exists chal0. auto.
  Qed.
  Definition Challenge_pos : Positive #|Challenge| := _.

  #[export] Instance positive_Sample : Positive #|Sample_space|.
  Proof.
    apply /card_gt0P. exists ss0. auto.
  Qed.
  Definition Sample_pos : Positive #|Sample_space| := _.


  Definition chSecKey  : choice_type := 'fin #|SecKey|.
  Definition chPubKey : choice_type := 'fin #|PubKey|.
  Definition chSignature : choice_type := 'fin #|Signature|.
  Definition chMessage : choice_type := 'fin #|Message|.
  Definition chChallenge : choice_type := 'fin #|Challenge|.

  Definition i_sk := #|SecKey|.
  Definition i_pk := #|SecKey|.
  Definition i_sig := #|Signature|.
  Definition i_ss := #|Sample_space|.

End RSA_KeyGen.

Module RSA_KeyGen_code (π1  : RSA_params) (π2 : KeyGenParams π1)
    <: KeyGen_code π1 π2.

  Import π1 π2.
  Module KGP := KeyGenParams_extended π1 π2.
  Module KG := RSA_KeyGen π1.
  Import KGP KG.

  Import PackageNotation.
  Local Open Scope package_scope.


  Fail Definition cast (p : Arit (uniform i_P) ) :=
    otf p.

  Definition cast (p : prime_num ) : R₀ :=
    match p with
    | exist x _ => x
    end.

  Lemma n_leq_nn : r₀ <= r.
  Proof.
    rewrite /r/r₀ -addn1.
    apply leq_pmull.
    by rewrite addn1.
  Qed.

  Lemma yyy : forall a b,
      prime a ->
      prime b ->
      0 < a * b.
  Proof.
    move => a b ap bp.
    rewrite muln_gt0.
    apply/andP.
    split.
    - exact: prime_gt0 ap.
    - exact: prime_gt0 bp.
  Qed.

  Lemma fold_R3 : (π1.n + (π1.n + (π1.n + π1.n * π1.n.+3).+3).+3).+3 = (π1.n.+3 * π1.n.+3)%nat.
  Proof.
    rewrite (addnC π1.n (muln _ _)).
    repeat rewrite -addSn.
    rewrite -[X in (_ + (_ + X))%nat = _]addn3.
    rewrite -/Nat.add plusE.
    rewrite -[X in (_ + (_ + X))%nat = _]addnA.
    rewrite addn3.
    by rewrite -mulSnr -mulSn -mulSn.
  Qed.


  Lemma fold_R4 : (π1.n + (π1.n + (π1.n + (π1.n + π1.n * π1.n.+4).+4).+4).+4).+4 = (π1.n.+4 * π1.n.+4)%nat.
  Proof.
    rewrite (addnC π1.n (muln _ _)).
    repeat rewrite -addSn.
    rewrite -[X in (_ + (_ + (_ + X)))%nat = _]addn4.
    rewrite -/Nat.add plusE.
    rewrite -[X in (_ + (_ + (_ + X)))%nat = _]addnA.
    rewrite addn4.
    by rewrite -mulSnr -mulSn -mulSn -mulSn.
  Qed.

  Lemma ltn_R : forall (a b: R₀), a * b < (π1.n + (π1.n + (π1.n + (π1.n + π1.n * π1.n.+4).+4).+4).+4).+4.
  Proof.
    rewrite /R₀/r₀ => a b.
    by rewrite fold_R4 ltn_mul.
  Qed.


  Lemma yyy' {a b:R₀} (ap: prime a) (bp: prime b) :
    0 < ((widen_ord n_leq_nn a) * (widen_ord n_leq_nn b))%R.
  Proof.
    rewrite /widen_ord /=.
    rewrite -/Nat.mul -/Nat.add.
    rewrite plusE multE.
    rewrite modn_small.
    - by apply yyy.
    - by apply ltn_R.
  Qed.

  Lemma yyy'' {a b:R₀} (ap: prime a) (bp: prime b) :
    0 < ((widen_ord n_leq_nn a) * (widen_ord n_leq_nn b))%nat.
  Proof.
    rewrite /widen_ord /=.
    by apply yyy.
  Qed.

  Definition mult_cast (a b : prime_num) : R' :=
    match a,b with
    | exist a' ap , exist b' bp =>
        exist _
          ((widen_ord n_leq_nn a') * (widen_ord n_leq_nn b'))%R (* <-- This [R] is not our [R] but means the Ring. *)
          (yyy' ap bp)
    end.

  Lemma zzz {a b:R₀} : (a * b)%nat < r.
  Proof.
    move: a b; rewrite /R₀/r.
    case => [a a_ltn]; case => [b b_ltn].
    apply ltn_mul; try apply ltn_ord.
  Qed.

  Definition mult_cast_nat (a b : prime_num) : R' :=
    match a,b with
    | exist a' ap , exist b' bp =>
        exist _
          (Ordinal zzz)
          (yyy'' ap bp)
    end.

  Equations KeyGen :
    code Key_locs [interface] (chPubKey × chSecKey) :=
    KeyGen :=
    {code
      p ← sample uniform P ;;
      let p := enum_val p in
      q ← sample uniform (P' p) ;;
      let q := enum_val q in
      assert (p != q) ;;

      e ← sample uniform i_ss ;;
      d ← sample uniform i_ss ;;
      let e := otf e in
      let d := otf d in
      (* assert ed = 1 (mod Phi(n)) *)
      let n := mult_cast_nat p q in
      #put sk_loc := (fto (n,e)) ;;
      #put pk_loc := (fto (n,d)) ;;
      ret ( (fto (n,e)) , fto (n,d) )
    }.

End RSA_KeyGen_code.

Module RSA_SignatureAlgorithms
  (π1  : RSA_params)
  (π2 : KeyGenParams π1)
  (π3 : KeyGen_code π1 π2)
<: SignatureAlgorithms π1 π2 π3.

  Import π1 π2 π3.
  Module KGC := RSA_KeyGen_code π1 π2.
  Import KGC KGC.KGP KGC.KG KGC.


  Lemma dec_smaller_n (d s pq : R) (H: 0 < pq) : (decrypt'' d pq s) < pq.
  Proof.
    by rewrite /decrypt''; apply ltn_pmod.
  Qed.

  Lemma enc_smaller_n (e m pq : R) (H: 0 < pq) : (encrypt'' e pq m) < pq.
  Proof.
    by rewrite /encrypt''; apply ltn_pmod.
  Qed.

  Definition dec_to_In  (d s pq : R) (H: 0 < pq) : 'I_pq :=
    Ordinal (dec_smaller_n d s pq H).
  Definition enc_to_In  (e m pq : R) (H: 0 < pq) : 'I_pq :=
    Ordinal (enc_smaller_n e m pq H).

  Lemma pq_leq_r:
    forall (pq:fintype_ordinal__canonical__fintype_Finite r), pq <= r.
  Proof.
    case => pq pq_ltn_r /=.
    exact: (ltnW pq_ltn_r).
  Qed.

  Equations Sign (sk : chSecKey) (m : chMessage) : chSignature :=
    Sign sk m :=
      match otf sk with
      | (exist pq O_ltn_pq, sk') =>
          (* This may seem unnecessary because we are casting
             from [R] to ['I_pq] and back to [R'].
             It is important for the proof part though.
           *)
          fto (widen_ord
                 (pq_leq_r pq)
                 (enc_to_In (widen_ord n_leq_nn sk') (otf m) pq O_ltn_pq))
      end.

  Equations Ver_sig (pk :  chPubKey) (sig : chSignature) (m : chMessage) : 'bool :=
    Ver_sig pk sig m :=
      match otf pk with
      | (exist pq O_ltn_pq, pk') =>
          (widen_ord
             (pq_leq_r pq)
             (dec_to_In (widen_ord n_leq_nn pk') (otf sig) pq O_ltn_pq))
          == (otf m)
      end.

  (* Playground begin *)

  Definition fun_from_set {S T:ordType} (s:{fset S*T}) : S -> option T :=
    let m := mkfmap s in λ s₁:S, getm m s₁.

  Definition currying_fmap {S T:ordType} {X:eqType} (m:{fmap (S*T) -> X}) : {fmap S -> {fmap T -> X}} :=
    currym m.

  Definition map_from_set {S T:ordType} (s:{fset S*T}) : {fmap S -> T} := mkfmap s.

  (* I believe that this is the lemma that we need:
     [Check mem_domm.]
   *)

  
  (**
     Note this: Our function is total but our fmap is actually not.
     It may return None. This situation is expressed in the function with the comparison
     of the given and decrypted signature/message.

     So there is:
     [if k ∈ m then true else false]
     or for short:
     [k ∈ m]

     As a function, we have [f] where [k ∈ f] is defined as
     [k₀ == f k]

     As a consequence, we cannot relate [f] to [m] but this function [f']
     f' := k₀ == f k

     This means that [k₀] represents all values that are not in the map.
     Consequently, we cannot prove a general lemma because we need this equality check
     and [k₀].
   *)

  (* Playground end *)

  Lemma xxx {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (f: S -> T) (x₁:S) (x₂:T) :
    (x₁, x₂) \in domm s = (x₂ == f x₁).
  Proof.
    apply/dommP.
  Admitted.

  Definition prod_key_map {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) : {fmap S -> T} :=
    mkfmap (domm s).

  Definition has_key {S T:ordType} (s:{fmap S -> T}) (x:S) : bool := x \in domm s.

  Lemma rem_unit {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (x₁:S) (x₂:T) :
      (x₁, x₂) \in domm s -> has_key (prod_key_map s) x₁.
  Proof.
    rewrite /has_key/prod_key_map.
    move/dommP. case => x in_s.
    apply/dommP.

    Restart.

    rewrite /has_key/prod_key_map.
    rewrite mem_domm.
    rewrite mem_domm.
    (*move => in_s. *)
    Check getm.
    rewrite /getm.

  Abort.

  Lemma getm_def_seq_step {S T:ordType} {a₀:S*T} {a₁: seq.seq (S*T)} {a₂:S} :
    getm_def (fset (a₀ :: a₁)) a₂ = getm_def (a₀ :: (fset a₁)) a₂.
  Proof.
  Admitted.

  Lemma rem_unit {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (x₁:S) (x₂:T):
    (x₁, x₂) \in domm s = has_key (prod_key_map s) x₁.
  Proof.
    rewrite /has_key/prod_key_map.
    (*
      Careful here!
      When rewriting with [mem_domm] then
      a check in the domain of a map that evaluates to [bool]
      becomes
      a check for the element itself that evaluates to an [option T].
      This works because Coq coerces [Some _] to [true] and [None] to [false].
      But be careful:
      The comparison [Some x₁ = Some x₂] requires that [x₁ = x₂].
      While this is not necessarily needed! Especially for our lemma!
     *)
    rewrite mem_domm.
    rewrite mem_domm.
    elim/fmap_ind : s => /=.
    - rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v.
      move/dommPn => notin_s.
      rewrite setmE.
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def.
      rewrite -/(getm_def _ x₁) -mkfmapE /=.

    Restart.

    rewrite /has_key/prod_key_map mem_domm mem_domm.
    move: x₁ x₂.
    elim/fmap_ind : s => /=.
    - move => x₁ x₂ /=. rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v notin_s x₁ x₂.
      rewrite setmE.
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def.
      rewrite -/(getm_def _ x₁) -mkfmapE /=.

      case H: ((x₁,x₂) == (x₁',x₂')).
      -- move/eqP:H => H; inversion H => //=. (* turns left side back into bool because the types differ [T != X] *)
         by rewrite ifT.
      -- case H_x₁: (x₁ == x₁').
         2: exact: iH.
         simpl. (* turns the RHS into [true] *)

         (* This case now seems not solvable:
            [x₁ = x₁' /\ x₂ != x₂']
            The problem is that we do not have any evidence that the LHS
            [(x₁,x₂) ∈ s]
            always holds [true].

            And why should this even be the case?!
            - Our argument was that both sides are derived from the same [s].
              Hence, when [x₁] is in the RHS it also needs to be in the LHS.
              The same holds for when it is not in [s].

            Then why do we fail?
            - Oh well, that is because of the induction!
              The case that we stumble over is the one where we discover an [x₂'] in the RHS
              even without consulting [s] at all.
          *)

    Restart.

    rewrite /has_key/prod_key_map mem_domm mem_domm.
    elim/fmap_ind : s => /=.
    - rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v notin_s.
      rewrite setmE. (* LHS *)
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def -/(getm_def _ x₁) -mkfmapE /=. (* RHS *)
      (*
        Indeed, it is the whole approach to solve this via [get_defm]
        just does not work this way.
        In the case, where we add something, we unfold [get_defm] once to
        get the inductive step.
        In this one unfolding, there is always the case where we
        do not consult [s].

        I never use the fact that [(x₁',x₂') ∉ s].
        Let me try.
       *)

    Restart.

    rewrite /has_key/prod_key_map mem_domm mem_domm.
    move: x₁ x₂.
    elim/fmap_ind : s => /=.
    - move => x₁ x₂ /=. rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v notin_s x₁ x₂.
      rewrite setmE.
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def.
      rewrite -/(getm_def _ x₁) -mkfmapE /=.

      case H: ((x₁,x₂) == (x₁',x₂')).
      -- move/eqP:H => H; inversion H => //=. (* turns left side back into bool *)
         by rewrite ifT.
      -- case H_x₁: (x₁ == x₁').
         2: exact: iH.
         move/dommPn:notin_s => notin_s.
         specialize (iH x₁' x₂').
         rewrite notin_s in iH.
         move/eqP: H_x₁ => H_x₁; rewrite -H_x₁ in iH.

         (*
           Nevermind the last transformations.
           Let's check out the following hypothesis
           [s (x₁',x₂') = None] which transforms into [s (x₁,x₂') = None]
           and the goal
           [s (x₁,x₂) = Some x₂'].
           The key point that we were missing is the fact that the hypothesis
           contradicts the goal.
           This is because of the following lemma:
          *)
         have xxx : s (x₁,x₂') = None -> forall x₂'', s (x₁,x₂'') = None.

         (*
           Nope, this does not hold!

           But maybe there is a different contradiction.
          *)

         Restart.

    rewrite /has_key/prod_key_map mem_domm mem_domm.
    elim/fmap_ind : s => /=.
    - rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v notin_s.
      rewrite setmE.
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def.
      rewrite -/(getm_def _ x₁) -mkfmapE /=.

      case H: ((x₁,x₂) == (x₁',x₂')).
      -- move/eqP:H => H; inversion H => //=. (* turns left side back into bool *)
         by rewrite ifT.
      -- case H_x₁: (x₁ == x₁').
         2: exact: iH.
         rewrite xpair_eqE in H.
         rewrite H_x₁ in H.
         simpl in H.

         (*
           The problem is that the induction tries to add something to the map
           that is not yet there.
           Hence, we get into trouble in the first case where it does not consult
           the map itself.
          *)

         Restart.

    rewrite /has_key/prod_key_map mem_domm mem_domm.
    elim/fmap_ind : s => /=.
    - rewrite /domm /=.
      by rewrite -fset0E /mkfmap/foldr.
    - move => s iH [x₁' x₂'] v notin_s.

      (*
        Why do I think that this holds?

        Case analysis on [x₁ == x₁'].
        - Case: [x₁ == x₁']
            -- RHS always finds [x₂']
            -- LHS needs case analysis on [x₂ == x₂']
              --- Case [x₂ == x₂']: LHS finds it in the first step
              --- Case [x₂ != x₂']: consults [s] where it may find it or not

        So this is the problem. The queries against the maps differ!
        The RHS only looks for [x₁] while the LHS looks for [(x₁,x₂)].

        Does that mean I can prove a lemma where [x₂] is more restricted?
       *)


  Abort.

  Lemma rem_unit {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (x₁:S) :
    (exists (x₂:T), (x₁, x₂) \in domm s) = has_key (prod_key_map s) x₁.
  Proof.
    rewrite /has_key/prod_key_map mem_domm.
    elim/fmap_ind : s => /=.
    - rewrite /domm /=.
      rewrite -fset0E /mkfmap/foldr.
      simpl.
 
      (* rewrite in_fset0. *)

  Abort.


  Lemma rem_unit {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (x₁:S) (x₂:T):
    (x₁, x₂) \in domm s -> has_key (prod_key_map s) x₁.
  Proof.
    move: x₁ x₂.
    elim/fmap_ind : s => /=.
    - move => x₁ x₂.
      by rewrite domm0 in_fset0.
    - move => s iH [x₁ x₂] v x_notin_s x₁' x₂'.
      rewrite /has_key/prod_key_map.
      rewrite mem_domm mem_domm.

      rewrite setmE.
      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def.
      rewrite -/(getm_def _ x₁') -mkfmapE /=.

      case H: ((x₁',x₂') == (x₁,x₂)).
      -- move/eqP:H => H; inversion H.
         rewrite ifT //=.
      -- rewrite -mem_domm => x'_in_s.
         case H_x₁: (x₁' == x₁).
         --- by [].
         --- specialize (iH x₁' x₂' x'_in_s).
             rewrite /has_key/prod_key_map mem_domm in iH.
             exact: iH.
  Qed.

  Lemma rem_unit' {S T:ordType} {X:eqType} (s:{fmap (S*T) -> X}) (x₁:S):
    has_key (prod_key_map s) x₁ -> exists (x₂:T), (x₁, x₂) \in domm s.
  Proof.
    move: x₁.
    elim/fmap_ind : s => /=.
    - move => x₁.
      rewrite /has_key/prod_key_map.
      rewrite mem_domm mkfmapE domm0 //=.
    - move => s iH [x₁ x₂] v x_notin_s x₁'.
      rewrite /has_key/prod_key_map.
      rewrite mem_domm.

      rewrite domm_set mkfmapE -fset_cons getm_def_seq_step /getm_def -/(getm_def _ x₁') -mkfmapE /=.

      case H_x₁: (x₁' == x₁).
      -- move => x_in_s.
         exists x₂.
         move/eqP:H_x₁ => H_x₁; rewrite H_x₁ //=.
         auto_in_fset. (* TODO remove when pushing this into extructures. or move the tactic alltogether. *)
      -- rewrite /has_key /prod_key_map in iH.
         rewrite -mem_domm => x₁'_in_s.
         specialize (iH x₁' x₁'_in_s).
         case: iH => x₂' iH.
         exists x₂'.
         rewrite /domm in iH.
         by rewrite fset_cons in_fsetU1; apply/orP; right.
  Qed.

  Theorem Signature_prop:
    ∀ (l: {fmap (chSignature  * chMessage ) -> 'unit})
      (s : chSignature) (pk : chPubKey) (m  : chMessage),
      Ver_sig pk s m = ((s,m) \in domm l).
  Proof.
    move => l s pk m.
    apply esym.
    (*
      This looks promising already.
      I would like to move this inequaility onto the branches
      to then say that this is the [v] that is not in the map.
      But for that I need a transformation first to remove the [unit].
     *)
    rewrite mem_domm.
    rewrite /Ver_sig.
    rewrite /getm/getm_def.
    rewrite /dec_to_In/decrypt''.
    (*
      I take that back:
      I do not see how this can be provable at all!

      A map if a partial function. Whether [Ver_sig] indeed implements
      that particular function or phrase the other way around, whether the map
      contains the pairs for the particular [Ver_sig] implementation
      cannot be derived without further evidence!
      (At least I cannot see where this information is supposed to come from!)

      It all feels to me like this wants to be a functional correctness property.
      Or it needs to be part of a different game.
     *)


    Abort.

  Theorem Signature_prop':
    ∀ (l: {fmap (chSignature  * chMessage ) -> 'unit})
      (pk : chPubKey)
      (sk : chSecKey)
      (m  : chMessage),
      Ver_sig pk (Sign sk m) m = ((Sign sk m, m) \in domm l).
  Proof.
    move => l pk sk m.
    rewrite mem_domm.
    rewrite /Ver_sig/Sign.

    generalize (otf m) => m'.
    case: pk => pk pk_lt /=.

    (* LHS *)
    rewrite /enc_to_In/dec_to_In.
    Fail rewrite rsa_correct''.

    (* I can certainly reduce the LHS to [true].
       But the RHS talks about the [Sign] of real instead of ideal!
       We still miss the fact that this tuple is actually really in [l].
     *)
  Abort.

  Theorem Signature_correct pk sk msg seed :
    Some (pk,sk) = Run sampler KeyGen seed ->
    Ver_sig pk (Sign sk msg) msg == true.
  Proof.
    rewrite /Run/Run_aux /=.

    (* SSReflect style generalization: *)
    move: (pkg_interpreter.sampler_obligation_4 seed {| pos := P; cond_pos := pos_i_P |}) => p.
    move: (pkg_interpreter.sampler_obligation_4 (seed + 1) {| pos := P' (enum_val p); cond_pos := _ |}) => q.

    have xxx: (enum_val p != enum_val q). { admit. }
    rewrite /assert.
    rewrite ifT //=.

    move: (pkg_interpreter.sampler_obligation_4 (seed + 1 + 1) {| pos := i_ss; cond_pos := positive_Sample |}) => sk₁.
    move: (pkg_interpreter.sampler_obligation_4 (seed + 1 + 1 + 1) {| pos := i_ss; cond_pos := positive_Sample |}) => pk₁.

    case => pk_eq sk_eq. (* injectivity *)

    rewrite /Ver_sig/Sign/dec_to_In/enc_to_In /=.
    rewrite sk_eq pk_eq /=.
    rewrite !otf_fto /=.

    case H: (mult_cast_nat (enum_val p) (enum_val q)) => [pq pq_gt_O] /=.
    rewrite /widen_ord /=.
    rewrite !otf_fto /=.

    apply/eqP/eqP.
    (* TODO this step is a bit strange. investigate. *)
    case H₁: (Ordinal (n:=r) (m:=_) _) => [m i].
    case: H₁.

    move: H; rewrite /mult_cast_nat -/Nat.add -/Nat.mul /widen_ord.

    (* case: (enum_val q). case => [q' q'_ltn_r₀ q'_prime]. *)
    (* case Hq₀: q => [q'₀ q'_ltn_r₀]. rewrite -Hq₀. *)
    case Hq: (enum_val q) => [q' q'_prime].

    (* case Hp: (enum_val p); case => [p' p'_ltn_r₀ p'_prime]. *)
    (* case Hp₀: p => [p'₀ p'_ltn_r₀]. rewrite -Hp₀. *)
    case Hp: (enum_val p) => [p' p'_prime].

    case.

    case H₂: (Ordinal (n:=r) (m:=p') _) => [p'' p''_ltn_r].
    case: H₂ => p'_eq_p''.
    case H₂: (Ordinal (n:=r) (m:=q') _) => [q'' q''_ltn_r].
    case: H₂ => q'_eq_q''.

    case XX: (Ordinal (n:=r) (m:=p'*q') _) => [p_mul_q pr].
    case: XX. move/esym => [p_mul_q_eq].
    move/esym => pq_spec.

    rewrite -[X in X = _ -> _](@modn_small _ pq).
    - rewrite -[X in _ = X -> _](@modn_small _ pq).
      + rewrite pq_spec.
        rewrite (rsa_correct'' p_mul_q_eq) /=.
        * move => msg_eq. subst.
          (*
            Once more this raises an interesting point:
            I cannot prove the below, i.e., [otf < p'' * q''].
            The theorem here actually only talks about [msg].
            But the correctness theorem of RSA talks about
            [msg %% p'' * q'']!
            So it seems that we are actually trying to show
            something more general at this point.
            That is, the correctness statement for signatures
            is incompatible with the correctness statement for
            RSA!
           *)
          repeat rewrite modn_small in msg_eq.
          ** subst. (* TODO Why does [subst] succeed and [rewrite] fail? *)
             (* I need to add [nat_of_ord] on both sides before
                [reflexivity] works.
              *)
             by apply ord_inj.
          ** admit. (* FIXME Cannot prove this: [m       < p'' * q''] *)
          ** admit. (* FIXME Cannot prove this: [otf msg < p'' * q''] *)
        * rewrite /wf_type.
          apply/andP; split; try exact: p'_prime.
          apply/andP; split; try exact: q'_prime.
          apply/andP; split; [move: xxx; rewrite Hq Hp |].
          apply/andP; split; [rewrite pq_spec in pq_gt_O; exact: pq_gt_O|].
          apply/andP; split.
          1:{ rewrite p_mul_q_eq; apply dvdn_mulr.
              rewrite /dvdn.
              apply/eqP.
              admit. (* FIXME Missing pre-condition. *)
          }
          apply/andP; split.
          ** admit. (* FIXME Missing pre-condition. *)
          ** admit. (* FIXME Missing pre-condition. *)
      + admit. (* FIXME Cannot prove this: [m < pq] *)
    - by rewrite /decrypt''; apply ltn_pmod.

    Unshelve.
      1: apply (leq_trans p'_ltn_r₀ n_leq_nn).
      apply (leq_trans q'_ltn_r₀ n_leq_nn).
  Admitted.

End RSA_SignatureAlgorithms.
