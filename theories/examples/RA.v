

(*
Introduction:
Here we will look at the remote attestation that is using a TPM for secure hardware 
cryptography. It is like the version used on the RATLS paper.
*)

From Relational Require Import OrderEnrichedCategory GenericRulesSimple.

Set Warnings "-notation-overridden,-ambiguous-paths".
From mathcomp Require Import all_ssreflect all_algebra reals distr realsum
  fingroup.fingroup solvable.cyclic prime ssrnat ssreflect ssrfun ssrbool ssrnum
  eqtype choice seq.
Set Warnings "notation-overridden,ambiguous-paths".

From Crypt Require Import Axioms ChoiceAsOrd SubDistr Couplings
  UniformDistrLemmas FreeProbProg Theta_dens RulesStateProb UniformStateProb
  pkg_core_definition choice_type pkg_composition pkg_rhl
  Package Prelude RandomOracle.

From Coq Require Import Utf8.
From extructures Require Import ord fset fmap.

From Equations Require Import Equations.
Require Equations.Prop.DepElim.
Require Import Coq.Init.Logic.
Require Import List.

Set Equations With UIP.

Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

Import Num.Def.
Import Num.Theory.
Import Order.POrderTheory.

Import PackageNotation.

Obligation Tactic := idtac.

(** REMOTE ATTESTATION
    VERIFIER                             PROVER
Generates a chal-
  lenge 'chal'
                   -----chal----->    
                                       Attestation
                                       (using TPM) 
                   <-----res------
Validity check
  of proof
** ATTESTATION
Input: 'chal'
--------------
TPM generates 'quoted' information
sig = Sign(chal,key,quoted)
--------------
Output: '(sig,quoted)'
**)

(*
Introduction:
Here we will look at the remote attestation that is using a TPM for secure hardware 
cryptography. It is like the version used on the RATLS paper.
*)

Module Type SignatureParams.

    Variable (n: nat).
    Definition pos_n: nat := 2^n.

    (*
      FIXME This does not make much sense, does it?
      Keys should be of type [uniform p].

      J: I made this because the signature ideal-game requires us
      to create and add to a set and ask if something is an element of
      that set. This construction is from MACCCA.v
      (See joy of crypto, p. 194)
      Furthermore, this entire file works without a single
      'sampling' call. I guess the "randomness / samlpling" is an
      important part of ssprove. But the core is that it is able to show
      that two packages are the same. They may or may not use a sampling.
      But, it indeed might be necessary/ helpful to add it at some point.
     *)

    Definition SecKey : choice_type := chFin(mkpos pos_n).
    Definition PubKey : choice_type := chFin(mkpos pos_n).
    Definition State : choice_type := chFin(mkpos pos_n).
    Definition Challenge : choice_type := chFin(mkpos pos_n).
    Definition Attestation : choice_type := chFin(mkpos pos_n).
    Definition Message : choice_type := chFin(mkpos pos_n).
    Definition Signature : choice_type := chFin(mkpos pos_n).

    Parameter Challenge_pos : Positive #|Challenge|.

End SignatureParams.

(** |  SIGNATURE  |
    |   SCHEME    | **)

Module Type SignatureAlgorithms (π : SignatureParams).

  Import π.

  #[local] Open Scope package_scope.

  (*
    FIXME
    This also looks strange to me:
    It seems like the whole scheme builds upon an
    asymmetric encryption scheme.
    If so, then we should definitely show that this
    is indeed the case!

    J: I don't understand the question. I've never defined an
    encryption nor an decryption functionality. Where do you
    get the impression that we use an asymmetric enc. scheme?

    S: From the presence of a public-secret key pair.
   *)

  Parameter KeyGen : (SecKey × PubKey).

  (* currently not used *)
  Parameter KeyGen_alt : 
  ∀ {L : {fset Location}},
    code L [interface] (SecKey × PubKey).

  Parameter Sign : ∀ (sk : SecKey) (m : Message), Signature.

  (* currently not used *)  
  Parameter Sign_alt :
  ∀ {L : {fset Location}} (sk : SecKey) (m : Message),
    code L [interface] Signature.

  Parameter Ver_sig : ∀ (pk : PubKey) (sig : Signature) (m : Message), 'bool.
   
  (* currently not used *)
  Parameter Ver_sig_alt :
  ∀ {L : {fset Location}} (pk : PubKey) (sig : Signature) (m : Message),
    code L [interface] 'bool.

  Parameter Attest :
    ∀ {L : {fset Location}} (sk : SecKey) ( c : Challenge ) (s : State),
       code L [interface] Signature.

  Parameter Ver_att :
    ∀ {L : {fset Location}} (pk : PubKey) (att : Attestation)
                   ( c : Challenge) ( s : State),
       code L [interface] 'bool.

  (*
TODO remove below
   *)

  Parameter Hash :
    	State -> Challenge ->
      Message.

  Parameter Hash_refl :
    forall s1 c1 , Hash s1 c1 = Hash s1 c1.

  Parameter Hash_bij :
    forall s1 c1 s2 c2, s1 != s2 \/ c1 != c2  -> Hash s1 c1 != Hash s2 c2.

End SignatureAlgorithms.

Module RemoteAttestation (π : SignatureParams)
  (Alg : SignatureAlgorithms π).

  Import π.
  Import Alg.

  #[local] Open Scope package_scope.

  Notation " 'pubkey "    := PubKey      (in custom pack_type at level 2).
  Notation " 'pubkey "    := PubKey      (at level 2): package_scope.
  Notation " 'signature " := Signature   (in custom pack_type at level 2).
  Notation " 'signature " := Signature   (at level 2): package_scope.
  Notation " 'state "     := State       (in custom pack_type at level 2).
  Notation " 'state "     := State       (at level 2): package_scope.
  Notation " 'challenge " := Challenge   (in custom pack_type at level 2).
  Notation " 'challenge " := Challenge   (at level 2): package_scope.
  Notation " 'message "   := Message     (in custom pack_type at level 2).
  Notation " 'message "   := Message     (at level 2): package_scope.
  Notation " 'att "       := Attestation (in custom pack_type at level 2).
  Notation " 'att "       := Attestation (at level 2): package_scope.

  (**
  We can't use sets directly in [choice_type] so instead we use a map to units.
  We can then use [domm] to get the domain, which is a set.
  *)
  Definition chSet t := chMap t 'unit.
  Notation " 'set t " := (chSet t) (in custom pack_type at level 2).
  Notation " 'set t " := (chSet t) (at level 2): package_scope.

  Definition tt := Datatypes.tt.

  Definition pk_loc      : Location := (PubKey    ; 0%N).
  Definition sk_loc      : Location := (SecKey    ; 1%N).
  Definition message_loc : Location := (Message   ; 2%N).
  Definition sign_loc    : Location := ('set ('signature × 'message); 3%N).
  Definition state_loc   : Location := (State    ; 4%N).
  Definition chal_loc    : Location := (Challenge ; 5%N).
  Definition attest_loc  : Location := ('set ('challenge × 'state × 'att ) ; 6%N).

  Definition get_pk    : nat := 42. (* routine to get the public key *)
  Definition get_state : nat := 43. (* routine to get the state to be attested *)
  Definition sign      : nat := 44. (* routine to sign a message *)
  Definition verify_sig: nat := 45. (* routine to verify the signature *)
  Definition verify_att: nat := 46.

  Notation " 'attest "    := Attestation    (in custom pack_type at level 2).
  Definition attest    : nat := 47. (* routine to attest *)

  Definition Signature_locs := fset [:: pk_loc ; sk_loc ; sign_loc ].

  Definition Attestation_locs := fset [:: pk_loc ; sk_loc; attest_loc; sign_loc ].
  (*
TODO:
    Definition Attestation_locs := fset [:: pk_loc ; sk_loc; sign_loc ].

TODO:
    Definition hash ((chal,st):'set ('challenge × 'state )) : 'set ('message) :=
      (chal,st).
   *)

  Definition Aux_locs' := fset [:: sign_loc ; pk_loc ; attest_loc ].

  Definition Sign_interface := [interface
    #val #[get_pk] : 'unit → 'pubkey ;
    #val #[sign] : 'message → 'signature ;
    #val #[verify_sig] : ('signature × 'message) → 'bool
  ].

  Definition Att_interface := [interface
  #val #[get_pk] : 'unit → 'pubkey ;
  #val #[attest] : ('challenge × 'state) → 'signature ;
  #val #[verify_att] : ( ('challenge × 'state) × 'signature) → 'bool
  ].

  Definition Sig_real :
  package Signature_locs
    [interface]
    Sign_interface
  :=
  [package
    #def  #[get_pk] (_ : 'unit) : 'pubkey
    {
      pk ← get pk_loc  ;;
      ret pk
    } ;

    #def #[sign] ( 'msg : 'message ) : 'signature
    {
      (*'(sk, pk) ← KeyGen2 sd ;;*)
      let (sk,pk) := KeyGen in
      #put pk_loc := pk ;;
      #put sk_loc := sk ;;
      let sig := Sign sk msg in
      (*sig ← Sign sk msg ;;*)
      (*#put sign_loc := ( sig , msg ) ;; *)
      ret sig
    };
    #def #[verify_sig] ( '(sig,msg) : 'signature × 'message) : 'bool
    {
      pk ← get pk_loc  ;;
      let bool := Ver_sig pk sig msg in
      (*bool ← Ver_sig pk sig msg ;;*)
      ret bool
    }
  ].

  Definition Sig_ideal :
  package Signature_locs
    [interface]
    Sign_interface
  :=
  [package
    #def  #[get_pk] (_ : 'unit) : 'pubkey
    {
      pk ← get pk_loc ;;
      ret pk
    } ;
    #def #[sign] ( 'msg : 'message ) : 'signature
    {
      (*'(sk, pk) ← KeyGen2 sd ;;*)
      let (sk,pk) := KeyGen in
      #put pk_loc := pk ;;
      #put sk_loc := sk ;;
      let sig := Sign sk msg in
      (*sig ← Sign sk msg ;;*)
      S ← get sign_loc ;;
      #put sign_loc := setm S (sig, msg) tt ;;
      ret sig
    };
    #def #[verify_sig] ( '(sig,msg) : 'signature × 'message) : 'bool
    {
      S ← get sign_loc ;;
      ret ( (sig,msg) \in domm S)
    }
  ].

  Definition Att_real_new :
  package Attestation_locs
    [interface]
    Att_interface
  :=
  [package
    #def  #[get_pk] (_ : 'unit) : 'pubkey
    {
      pk ← get pk_loc  ;;
      ret pk
    } ;
    #def #[attest] ( '(chal,state) : 'challenge × 'state ) : 'signature
    {
      (*'(sk, pk) ← KeyGen2 sd ;;*)
      let (sk,pk) := KeyGen in
      #put pk_loc := pk ;;
      #put sk_loc := sk ;;
      let msg := Hash state chal in
      let att := Sign sk msg in
      (*att ← Sign sk msg ;;*)
      ret att
    } ;
    #def #[verify_att] ('(chal, state, att) : ('challenge × 'state) × 'signature) : 'bool
    {
      pk ← get pk_loc  ;;
      let msg := Hash state chal in
      let bool := Ver_sig pk att msg in
      (*bool ← Ver_sig pk att msg ;;*)
      ret bool
    }
  ].

  Definition Att_ideal_new :
  package Attestation_locs
    [interface]
    Att_interface
  :=
  [package
    #def  #[get_pk] (_ : 'unit) : 'pubkey
    {
      pk ← get pk_loc ;;
      ret pk
    } ;
    #def #[attest] ( '(chal,state) : 'challenge × 'state) : 'attest
    {
      A ← get attest_loc ;;
      (*'(sk, pk) ← KeyGen2 sd ;;*)
      let (sk,pk) := KeyGen in
      #put pk_loc := pk ;;
      #put sk_loc := sk ;;
      let msg := Hash state chal in
      let att := Sign sk msg in
      (*att ← Sign sk msg ;;*)
      #put attest_loc := setm A ( chal, state, att ) tt ;;
      ret att
    };
    #def #[verify_att] ('(chal, state, att) : ('challenge × 'state) × 'attest) : 'bool
    {
      A ← get attest_loc ;;
      ret ( (chal, state, att) \in domm A )
    }
  ].

  Definition Aux_locs := fset [:: sign_loc ; pk_loc ; attest_loc ].

  Definition Aux :
  package Aux_locs
  Sign_interface
  Att_interface :=
  [package
    #def #[get_pk] (_ : 'unit) : 'pubkey
    {
      pk ← get pk_loc ;;
      ret pk
    } ;
    #def #[attest] ( '(chal,state) : ('challenge × 'state )) : 'signature
    {
      #import {sig #[sign] : 'message  → 'signature } as sign ;;
      let msg := Hash state chal in
      att ← sign msg ;;
      (*#put attest_loc := att ;;*)
      ret att
    } ;
    #def #[verify_att] ('(chal, state, att) : ('challenge × 'state) × 'signature) : 'bool
    {
      #import {sig #[verify_sig] : ('signature × 'message) → 'bool } as verify ;;
      let msg := Hash state chal in
      (* pk ← get pk_loc ;; *)
      b  ← verify (att,msg) ;;
      ret b
      (* When I just write:
         [verify (att,msg)]
         Then SSProve errors out and cannot validate the package. Why?
       *)
    }
  ].

  Definition mkpair {Lt Lf E}
    (t: package Lt [interface] E) (f: package Lf [interface] E): loc_GamePair E :=
    fun b => if b then {locpackage t} else {locpackage f}.

  Definition Sig_unforg := @mkpair Signature_locs Signature_locs Sign_interface Sig_real Sig_ideal.
  Definition Att_unforg := @mkpair Attestation_locs Attestation_locs Att_interface Att_real_new Att_ideal_new.

(* Attestation_locs =o Aux_locs o Sig_locs
Definition Attestation_locs := fset [:: pk_loc ; sk_loc; attest_loc ].

Definition Signature_locs := fset [:: pk_loc ; sk_loc ; sign_loc ].
Definition Aux_locs' := fset [:: sign_loc ; pk_loc ; attest_loc ]. *)

  Lemma sig_real_vs_att_real_true:
    Att_unforg true ≈₀  Aux ∘ Sig_unforg true.
  Proof.
    eapply eq_rel_perf_ind_eq.
    simplify_eq_rel x.
    all: ssprove_code_simpl.
    - eapply rpost_weaken_rule.
      1: eapply rreflexivity_rule.
      move => [a1 h1] [a2 h2] [Heqa Heqh].
      intuition auto.
    - destruct x.
      ssprove_sync_eq.
      ssprove_sync_eq.
      by [apply r_ret].
    - case x => s s0.
      case s => s1 s2.
      ssprove_sync_eq.
      move => a.
      by [apply r_ret].
  Qed.

  Lemma sig_ideal_vs_att_ideal_false :
  Att_unforg false ≈₀ Aux ∘ Sig_unforg false.
  Proof.
    eapply eq_rel_perf_ind_eq.
    simplify_eq_rel x.
    all: ssprove_code_simpl.
    - ssprove_sync_eq => pk_loc.
      by [apply r_ret].
    - case x => challenge state.
      ssprove_swap_lhs 0.
      ssprove_sync_eq.
      ssprove_swap_lhs 0.
      ssprove_sync_eq.
      rewrite /attest_loc /sign_loc.
    Admitted.
  (*Qed.*)

  (* This is what the theorem is supposed to look like, but it doesn't compile! -> to be changed*)
  Theorem RA_unforg LA A :
  ∀ LA A,
    ValidPackage LA [interface
    #val #[get_pk] : 'unit → 'pubkey ;
    #val #[sign] : ('challenge × 'state) → 'attest ;
    #val #[verify_sig] : ( ('challenge × 'state) × 'attest) → 'bool
    ] A_export A →
    fdisjoint LA (sig_real_vs_att_real_true).(locs) →
    fdisjoint LA (sig_ideal_vs_att_ideal_true).(locs) →
    Advantage Att_unforg <= Advantage Sig_unforg.
Proof.
  
