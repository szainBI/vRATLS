

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
Require Import Lia.

From Equations Require Import Equations.
Require Equations.Prop.DepElim.

Set Equations With UIP.

Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

Import Num.Def.
Import Num.Theory.
Import Order.POrderTheory.

Import PackageNotation.

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


(** |  SIGNATURE  |
    |   SCHEME    | **)

  
Module Type SignatureParams.

    Parameter SecKey PubKey State Challenge Attest : finType.
    (* seed = input key gen
       State = state of device to be attested, called quoted in specification
       Challenge = send by verifier to attester
       Attest = signature (maybe signature || message?)
    *)  
    Parameter SecKey_pos : Positive #|SecKey|.
    Parameter PubKey_pos : Positive #|PubKey|.
    Parameter State_pos : Positive #|State|.
    Parameter Challenge_pos : Positive #|Challenge|.
    Parameter Attest_pos : Positive #|Attest|.
    Parameter Bool_pos : Positive #|bool_choiceType|.
  
End SignatureParams.
  
Module Type SignatureAlgorithms (π : SignatureParams).
  
  Import π.
  
  #[local] Open Scope package_scope.  
   
  #[local] Existing Instance State_pos. 
  #[local] Existing Instance Challenge_pos. 
  #[local] Existing Instance Attest_pos. 
  #[local] Existing Instance Bool_pos.
  #[local] Existing Instance SecKey_pos.
  #[local] Existing Instance PubKey_pos.
  
  (* defining the instances again*)
  Definition ch_state := 'fin #|State|.  (* using "choice" because of choice_type *)
  Definition ch_challenge := 'fin #|Challenge|.      (* "'fin" is their own finite set definition with n>0, not n >= 0 *)
  Definition ch_attest := 'fin #|Attest|.  
  Definition ch_Bool := 'fin #|bool_choiceType|.
  Definition ch_sec_key := 'fin #|SecKey|.
  Definition ch_pub_key := 'fin #|PubKey|.
  Definition choice_Transcript :=
    chProd (chProd ch_challenge ch_state) ch_attest.
    
  Parameter Sign_locs : {fset Location}.     (* | Defining a finite set (fset) of elements of type Location*)
  Parameter Sign_Simul_locs : {fset Location}.
  
  Parameter Sig_Sign :
    ∀ (sk : ch_sec_key) (c : ch_challenge) (s : ch_state),
    code Sign_locs [interface] ch_attest.
  
  Parameter Sig_Verify :
  ∀ (pk : ch_pub_key) (c : ch_challenge) (s : ch_state) (a : ch_attest),
     ch_Bool.

  Parameter Sig_Simulate :
    ∀ (c : ch_challenge) (s : ch_state) (pk : ch_pub_key),
    code Sign_Simul_locs [interface] choice_Transcript.

  Parameter KeyGen : forall (sk : ch_sec_key), ch_pub_key.
  
  End SignatureAlgorithms.
  
  
  Module Type Signature (π : SignatureParams)
  (Alg : SignatureAlgorithms π).
  
      Import π.
      Import Alg.
  
      Definition TRANSCRIPT : nat := 0.
      Definition choice_Input :=  
        chProd ( chProd (chProd ch_pub_key ch_challenge ) ch_state ) ch_sec_key.
      Notation " 'chInput' " := 
        choice_Input (in custom pack_type at level 2).
      Notation " 'chTranscript' " :=
        choice_Transcript (in custom pack_type at level 2).     
  
      Definition Sign_real:
        package Sign_locs
          [interface] (** No procedures from other packages are imported. *)
          [interface #val #[ TRANSCRIPT ] : chInput → chTranscript]
        :=
        [package
          #def #[ TRANSCRIPT ] (input : chInput) : chTranscript 
          {
            let '(pk,c,q,sk) := input in
            m ← Sig_Sign sk c q ;;
            @ret choice_Transcript (c,q,m) 
          }
        ].
      
      Definition Sign_ideal:
      package Sign_Simul_locs
          [interface] (** No procedures from other packages are imported. *)
          [interface #val #[ TRANSCRIPT ] : chInput → chTranscript]
        :=
        [package
          #def #[ TRANSCRIPT ] (input : chInput) : chTranscript 
          {
            let '(pk,c,q,sk) := input in
            t ← Sig_Simulate c q pk;;
            ret t
          }
          ].

      Definition ɛ_sign A := AdvantageE Sign_real Sign_ideal A.  

(** |    REMOTE   |
    | ATTESTATION | **)

    Section RemoteAttestation.

    Definition ATTEST : nat := 5.
    Definition GET_sk : nat := 6.
    Definition GET_pk : nat := 7.
    Definition INIT : nat := 8.
    Definition VER : nat := 9.
    Definition ATTESTATION : nat :=   0.

    Definition challenge_loc : Location := ('option ch_challenge; 7%N).
    Definition attest_loc : Location := ('option ch_attest; 8%N).

    Definition Com_locs : {fset Location} := 
      fset [:: challenge_loc ; attest_loc ].

    Definition setup_loc : Location := ('bool; 10%N).
    Definition sk_loc : Location := (ch_sec_key; 11%N).
    Definition pk_loc : Location := (ch_pub_key; 12%N).
    (* Definition attest_loc : Location := (ch_pub_key; 13%N). *)
    Definition KEY_locs : {fset Location} := 
      fset [:: setup_loc; sk_loc ; pk_loc].

     Lemma in_fset_left l (L1 L2 : {fset Location}) :
      is_true (l \in L1) →
      is_true (l \in (L1 :|: L2)).
    Proof.
      intros H.
      apply /fsetUP.
      left. assumption.
    Qed.

    Definition i_sk := #|SecKey|.
    Definition i_sk_pos : Positive i_sk.
    Proof.
      unfold i_sk.
      apply SecKey_pos.
    Qed.
  
    #[local] Existing Instance i_sk_pos.

    Hint Extern 20 (is_true (_ \in (_ :|: _))) =>
      apply in_fset_left; solve [auto_in_fset]
      : typeclass_instances ssprove_valid_db.

    Notation " 'chSecKey' " :=
        ch_sec_key (in custom pack_type at level 2).        
    Notation " 'chPubKey' " :=
        ch_pub_key (in custom pack_type at level 2).
    Notation " 'chAttest' " :=
        ch_attest (in custom pack_type at level 2).
    Notation " 'chChallenge' " :=
        ch_challenge (in custom pack_type at level 2).

    Definition KEY:
      package KEY_locs
        [interface]
        [interface
           #val #[ INIT ] : 'unit → 'unit ;
           #val #[ GET_sk ] : 'unit → chSecKey ;
           #val #[ GET_pk ] : 'unit → chPubKey
        ]
      :=
      [package
         #def #[ INIT ] (_ : 'unit) : 'unit
         {
           b ← get setup_loc ;;
           #assert (negb b) ;;
           sk ← sample uniform i_sk ;;
           let pk := KeyGen sk in
           #put setup_loc := true ;;
           #put sk_loc := sk ;;
           #put pk_loc := pk ;;
           @ret 'unit Datatypes.tt
         }
         ;
         #def #[ GET_sk ] (_ : 'unit) : chSecKey
         {
           b ← get setup_loc ;;
           if b then
             sk ← get sk_loc ;;
             pk ← get pk_loc ;;
             ret sk
           else
             fail
         }
         ;
         #def #[ GET_pk ] (_ : 'unit) : chPubKey
         {
           b ← get setup_loc ;;
           if b then
             sk ← get sk_loc ;;
             pk ← get pk_loc ;;
             ret pk
           else
             fail
         }
      ].

    Definition RA_to_Sig_locs := (Com_locs :|: Sign_Simul_locs).
    
    #[tactic=notac] Equations? RA_to_Sig:
      package RA_to_Sig_locs
        [interface
          #val #[ INIT ] : 'unit → 'unit ;
          #val #[ GET_sk ] : 'unit → chSecKey ;
          #val #[ GET_pk ] : 'unit → chPubKey
        ]
      [interface
        #val #[ ATTEST ] : chInput → chAttest ;
        #val #[ VER ] : chTranscript → 'bool
      ]
    := RA_to_Sig :=
    [package
      #def #[ ATTEST ] (i : chInput) : chAttest
      {
        #import {sig #[ INIT ] : 'unit → 'unit } as key_gen_init ;;
        #import {sig #[ GET_sk ] : 'unit → chSecKey } as key_gen_get_sk ;;
        #import {sig #[ GET_pk ] : 'unit → chPubKey } as key_gen_get_pk ;;
        let '(pk,c,s,a) := i in
        _ ← key_gen_init Datatypes.tt ;;
        sk ← key_gen_get_sk Datatypes.tt ;;
        pk ← key_gen_get_pk Datatypes.tt ;;
        '(c,s,a) ← Sig_Simulate c s pk ;;
        #put challenge_loc := Some c ;;
        #put attest_loc := Some a ;;
        ret a
      }
      ;
      #def #[ VER ] (t : chTranscript) : 'bool
      {
        let '(c,s,a) := t in
        #import {sig #[ GET_pk ] : 'unit → chPubKey } as key_gen_get_pk ;;
        pk ← key_gen_get_pk Datatypes.tt ;;
        ret (otf (Sig_Verify pk c s a))
      }
    ].
  Proof.
    unfold RA_to_Sig_locs.    
    ssprove_valid.
    eapply valid_injectLocations.
    1: apply fsubsetUr.
    eapply valid_injectMap.
    2: apply (Sig_Simulate s2 s1 x1 ).
    rewrite -fset0E.
    apply fsub0set.
  Qed.

  Definition choice_Attest_Input :=  
    chProd  ch_challenge  ch_state.
  
  Notation " 'chAttIn' " := 
      choice_Attest_Input (in custom pack_type at level 2).

  Definition i_pubkey := #|PubKey|.
  Definition i_challenge := #|Challenge|.
  Definition i_state := #|State|.
  Definition i_seckey := #|SecKey|.

  Definition i_pubkey_pos : Positive i_pubkey.
    Proof.
      unfold i_pubkey.
      apply PubKey_pos.
    Qed.
  
  Definition i_challenge_pos : Positive i_challenge.
    Proof.
      unfold i_challenge.
      apply Challenge_pos.
    Qed.

  Definition i_state_pos : Positive i_state.
    Proof.
      unfold i_state.
      apply State_pos.
    Qed.

  Definition i_seckey_pos : Positive i_seckey.
    Proof.
      unfold i_seckey.
      apply SecKey_pos.
    Qed.

  Definition RA_real:
      package fset0
        [interface
          #val #[ INIT ] : 'unit → 'unit ;
          #val #[ GET_sk ] : 'unit → chSecKey ;
          #val #[ GET_pk ] : 'unit → chPubKey ;
          #val #[ ATTEST ] : chInput → chAttest
        ]
        [interface #val #[ ATTESTATION ] : chAttIn → chAttest]
      :=
      [package
        #def #[ ATTESTATION ] (cs : chAttIn) : chAttest
        {
          #import {sig #[ ATTEST ] : chInput → chAttest } as attest ;;
          #import {sig #[ INIT ] : 'unit → 'unit } as key_gen_init ;;
          #import {sig #[ GET_sk ] : 'unit → chSecKey } as key_gen_get_sk ;;
          #import {sig #[ GET_pk ] : 'unit → chPubKey } as key_gen_get_pk ;;
          let '(c,s) := cs in
          _ ← key_gen_init Datatypes.tt ;;
          sk ← key_gen_get_sk Datatypes.tt ;;
          pk ← key_gen_get_pk Datatypes.tt ;;
          a ← attest pk c s sk ;;
          ret a          
        }
      ].

  Definition RA_ideal:
      package fset0
        [interface
          #val #[ INIT ] : 'unit → 'unit ;
          #val #[ GET_sk ] : 'unit → chSecKey ;
          #val #[ GET_pk ] : 'unit → chPubKey ;
          #val #[ ATTEST ] : chInput → chAttest
        ]
        [interface #val #[ ATTESTATION ] : chAttIn → chAttest]
      :=
      [package
        #def #[ ATTESTATION ] (_ : chAttIn) : chAttest
        {
          #import {sig #[ ATTEST ] : chInput → chAttest } as attest ;;
          pk ← sample uniform i_pubkey ;;
          c ← sample uniform i_challenge ;;
          s ← sample uniform i_state ;;
          sk ← sample uniform i_seckey ;;
          a ← attest pk c s sk ;;
          ret a          
        }
      ].

  End Signature.



