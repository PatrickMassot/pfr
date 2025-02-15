import Mathlib.Data.Finsupp.Fintype
import Mathlib.LinearAlgebra.Basis.VectorSpace
import Mathlib.GroupTheory.Sylow

/-!
# Finite field vector spaces

Here we define the notion of a vector space over a finite field, and record basic results about it.

## Main classes

* `ElementaryAddCommGroup`: An elementary p-group.
-/

-- TODO: Find an appropriate home for this section
section to_move

section AddCommMonoid
variable {n : ℕ} {M : Type*} [AddCommMonoid M] [Module (ZMod (n + 1)) M]

/- FIXME: n is not unified/inferred -/
@[coe] def AddSubmonoid.toSubmodule (S : AddSubmonoid M) : Submodule (ZMod (n + 1)) M := by
  have smul_mem : ∀ (c : ZMod (n + 1)) { x : M }, x ∈ S.carrier → c • x ∈ S.carrier := by
    intros c _ hx
    induction' c using Fin.induction with _ hc
    · simp_rw [zero_smul, AddSubmonoid.mem_carrier, AddSubmonoid.zero_mem]
    · rw [← Fin.coeSucc_eq_succ, Module.add_smul, one_smul] ; exact S.add_mem hc hx
  exact { S with smul_mem' := smul_mem }

@[simp, norm_cast] theorem AddSubmonoid.coe_toSubmodule (S : AddSubmonoid M) :
  S.toSubmodule (n := n) = (S : Set M) := rfl

instance : Coe (AddSubmonoid M) (Submodule (ZMod (n + 1)) M) := ⟨AddSubmonoid.toSubmodule⟩

variable {M' : Type*} [AddCommMonoid M'] [Module (ZMod (n + 1)) M']

@[coe] def AddMonoidHom.toLinearMap (f : M →+ M') : M →ₗ[ZMod (n + 1)] M' := by
  have map_smul : ∀ (c : ZMod (n + 1)) (x : M), f (c • x) = c • f x := by
    intros c _
    induction' c using Fin.induction with _ hc
    · simp_rw [zero_smul, map_zero]
    · simp_rw [← Fin.coeSucc_eq_succ, Module.add_smul, one_smul, f.map_add, hc]
  exact { f with map_smul' := map_smul }

@[simp, norm_cast] theorem AddMonoidHom.coe_toLinearMap (f : M →+ M) :
  ⇑(f.toLinearMap (n := n)) = f := rfl

instance : Coe (M →+ M') (M →ₗ[ZMod (n + 1)] M') := ⟨AddMonoidHom.toLinearMap⟩

end AddCommMonoid

section AddCommGroup

variable {n : ℕ} {G : Type*} [AddCommGroup G] [Module (ZMod n) G]

@[coe] def AddSubgroup.toSubmodule (H : AddSubgroup G) : Submodule (ZMod n) G := by
  have smul_mem : ∀ (c : ZMod n) { x : G }, x ∈ H.carrier → c • x ∈ H.carrier := by
    cases' n with n; swap
    · exact fun c _ hx ↦ (AddSubmonoid.toSubmodule H.toAddSubmonoid).smul_mem c hx
    · intros c _ hx
      induction' c using Int.induction_on with _ hc _ hc
      · simp_rw [zero_smul, AddSubgroup.mem_carrier, AddSubgroup.zero_mem]
      · simp_rw [Module.add_smul, one_smul, AddSubgroup.mem_carrier, H.add_mem hc hx]
      · simp_rw [sub_smul, one_smul, AddSubgroup.mem_carrier, H.sub_mem hc hx]
  exact { H with smul_mem' := smul_mem }

@[simp, norm_cast] theorem AddSubgroup.coe_toSubmodule (H : AddSubgroup G) :
  H.toSubmodule (n := n) = (H : Set G) := rfl

instance : Coe (AddSubgroup G) (Submodule (ZMod n) G) := ⟨AddSubgroup.toSubmodule⟩

variable {G' : Type*} [AddCommGroup G'] [Module (ZMod n) G']

@[coe] def AddMonoidHom.toLinearMapGroup (f : G →+ G') : G →ₗ[ZMod n] G' := by
  have map_smul : ∀ (c : ZMod n) (x : G), f (c • x) = c • f x := by
    cases' n with n; swap
    · exact (AddMonoidHom.toLinearMap f).map_smul
    · intros c _
      induction' c using Int.induction_on with _ hc _ hc
      · simp_rw [zero_smul, map_zero]
      · simp_rw [Module.add_smul, one_smul, f.map_add, hc]
      · simp_rw [sub_smul, one_smul, f.map_sub, hc]
  exact { f with map_smul' := map_smul }

@[simp, norm_cast] theorem AddMonoidHom.coe_toLinearMapGroup (f : G →+ G') :
  ⇑(f.toLinearMapGroup (n := n)) = f := rfl

instance : Coe (G →+ G') (G →ₗ[ZMod n] G') := ⟨AddMonoidHom.toLinearMapGroup⟩

end AddCommGroup
end to_move


/-- An elementary `p`-group, i.e., a commutative additive group in which every nonzero element has
order exactly `p`. -/
class ElementaryAddCommGroup (G : Type*) [AddCommGroup G] (p : outParam ℕ) : Prop where
  orderOf_of_ne {x : G} (hx : x ≠ 0) : addOrderOf x = p

namespace ElementaryAddCommGroup

@[simp]
lemma torsion {G: Type*} [AddCommGroup G] (p: ℕ) [elem : ElementaryAddCommGroup G p] (x:G) : p • x = 0 := by
  by_cases h: x = 0
  . simp [h]
  have := elem.orderOf_of_ne h
  rw [← this]
  exact addOrderOf_nsmul_eq_zero x

lemma of_torsion {G: Type*} [AddCommGroup G] {p: ℕ} (hp: p.Prime) (h : ∀ x : G, p • x = 0) : ElementaryAddCommGroup G p := by
  constructor
  intro x hx
  have := addOrderOf_dvd_of_nsmul_eq_zero (h x)
  rw [Nat.dvd_prime hp] at this
  rcases this with this | this
  . simp at this; contradiction
  exact this


/-- A vector space over Z/p is an elementary abelian p-group. -/
-- We can't make this an instance as `p` is not determined.
lemma ofModule [AddCommGroup G] [Module (ZMod p) G] [Fact p.Prime] :
    ElementaryAddCommGroup G p where
  orderOf_of_ne := addOrderOf_eq_prime (Basis.ext_elem (.ofVectorSpace (ZMod p) G) (by simp))

-- We add the special case instance for `p = 2`.
instance [AddCommGroup G] [Module (ZMod 2) G] : ElementaryAddCommGroup G 2 := ofModule

/-- In an elementary abelian $p$-group, every finite subgroup $H$ contains a further subgroup of
cardinality between $k$ and $pk$, if $k \leq |H|$.-/
lemma exists_subgroup_subset_card_le {G : Type*} {p : ℕ} (hp : p.Prime)
    [AddCommGroup G] [h : ElementaryAddCommGroup G p]
    {k : ℕ} (H : AddSubgroup G) (hk : k ≤ Nat.card H) (h'k : k ≠ 0) :
    ∃ (H' : AddSubgroup G), Nat.card H' ≤ k ∧ k < p * Nat.card H' ∧ H' ≤ H := by
  let Gm := Multiplicative G
  have hm : IsPGroup p Gm := by
    intro gm
    rcases eq_or_ne gm 1 with rfl|hg
    · exact ⟨0, by simp⟩
    · refine ⟨1, ?_⟩
      have : Multiplicative.toAdd gm ≠ 0 := hg
      simpa only [pow_one, h.orderOf_of_ne this] using addOrderOf_nsmul_eq_zero (Multiplicative.toAdd gm)
  let Hm : Subgroup Gm := AddSubgroup.toSubgroup H
  obtain ⟨H'm, H'mHm, H'mk, kH'm⟩ := Sylow.exists_subgroup_le_card_le (H := Hm) hp hm hk h'k
  exact ⟨AddSubgroup.toSubgroup.symm H'm, H'mk, kH'm, H'mHm⟩

variable [AddCommGroup G] [elem : ElementaryAddCommGroup G 2]

@[simp]
lemma sub_eq_add ( x y : G ) : x - y = x + y := by
  rw [sub_eq_add_neg, add_right_inj, ← add_eq_zero_iff_neg_eq]
  by_cases h : y = 0
  · simp only [h, add_zero]
  · simpa only [elem.orderOf_of_ne h, two_nsmul] using (addOrderOf_nsmul_eq_zero y)

@[simp]
lemma add_self ( x : G ) : x + x = 0 := by
  rw [← sub_eq_add]
  simp


@[simp]
lemma neg_eq_self ( x : G ) : - x = x := by
  simpa [-sub_eq_add] using sub_eq_add 0 x

lemma sum_add_sum_eq_sum ( x y z : G ) : (x + y) + (y + z) = x + z := by
  rw [← sub_eq_add x y]
  abel

lemma sum_add_sum_add_sum_eq_zero ( x y z : G ) : (x + y) + (y + z) + (z + x) = 0 := by
  rw [sum_add_sum_eq_sum, add_comm x z, add_self]

open Function

@[simp] lemma char_smul_eq_zero {Γ : Type*} [AddCommGroup Γ] [ElementaryAddCommGroup Γ p] (x : Γ) :
    p • x = 0 := by
  by_cases hx : x = 0
  · simp only [hx, smul_zero]
  · have obs := ElementaryAddCommGroup.orderOf_of_ne hx
    rw [addOrderOf] at obs
    simpa only [obs, add_left_iterate, add_zero] using
      iterate_minimalPeriod (f := fun z ↦ x + z) (x := 0)

lemma char_ne_one_of_ne_zero {Γ : Type*} [AddCommGroup Γ] [ElementaryAddCommGroup Γ p] {x : Γ}
    (x_ne_zero : x ≠ 0) : p ≠ 1 := by
  have obs := ElementaryAddCommGroup.orderOf_of_ne x_ne_zero
  rw [addOrderOf] at obs
  by_contra maybe_one
  apply x_ne_zero
  simpa only [obs, maybe_one, iterate_succ, iterate_zero, comp_apply, add_zero, id_eq] using
    iterate_minimalPeriod (f := fun z ↦ x + z) (x := 0)

@[simp] lemma char_smul_eq_zero' {Γ : Type*} [AddCommGroup Γ] [ElementaryAddCommGroup Γ p] (x : Γ)
    (k : ℤ) : (k*p) • x = 0 := by
  rw [mul_smul]
  norm_cast
  simp

lemma two_le_char_of_ne_zero {Γ : Type*} [NeZero p] [AddCommGroup Γ] [ElementaryAddCommGroup Γ p]
    {x : Γ} (x_ne_zero : x ≠ 0) : 2 ≤ p := by
  by_contra maybe_small
  have p_le_one : p ≤ 1 := by linarith
  rcases Nat.le_one_iff_eq_zero_or_eq_one.mp p_le_one with hp|hp
  · simp_all only [neZero_zero_iff_false]
  · exact char_ne_one_of_ne_zero x_ne_zero hp

lemma mem_periodicPts {Γ : Type*} [NeZero p] [AddCommGroup Γ] [ElementaryAddCommGroup Γ p]
    {x : Γ} (y : Γ) : y ∈ periodicPts (fun z ↦ x + z) := by
  simp only [periodicPts, IsPeriodicPt, add_left_iterate, Set.mem_setOf_eq]
  exact ⟨p, Fin.size_pos', by simp [IsFixedPt]⟩

open Nat in
instance (Ω Γ : Type*) (p : ℕ) [NeZero p] [AddCommGroup Γ] [ElementaryAddCommGroup Γ p] :
    ElementaryAddCommGroup (Ω → Γ) p where
  orderOf_of_ne := by
    intro f f_ne_zero
    have iter_p : (fun x ↦ f + x)^[p] 0 = 0 := by
      ext ω
      simp
    have no_less : ∀ n, 0 < n → n < p → (fun x ↦ f + x)^[n] 0 ≠ 0 := by
      intro n n_pos n_lt_p
      apply ne_iff.mpr
      obtain ⟨ω, hfω⟩ := show ∃ ω, f ω ≠ 0 from ne_iff.mp f_ne_zero
      existsi ω
      have obs := ElementaryAddCommGroup.orderOf_of_ne hfω
      rw [addOrderOf] at obs
      by_contra con
      apply not_isPeriodicPt_of_pos_of_lt_minimalPeriod (f := fun x ↦ f ω + x) (x := 0)
              n_pos.ne.symm (by simpa only [obs] using n_lt_p)
      simp_rw [IsPeriodicPt, IsFixedPt]
      convert con
      simp
    rw [addOrderOf, minimalPeriod]
    have mem_pPts : 0 ∈ periodicPts (fun g ↦ f + g) := by
      rw [periodicPts]
      existsi p
      rw [IsPeriodicPt, IsFixedPt]
      refine ⟨Fin.size_pos', ?_⟩
      ext ω
      simp
    simp only [mem_pPts, gt_iff_lt, dite_true]
    classical
    rw [find_eq_iff]
    refine ⟨⟨Fin.size_pos', iter_p⟩, ?_⟩
    intro n n_lt_p
    by_contra con
    exact no_less n con.1 n_lt_p con.2

lemma Int.mod_eq (n m : ℤ) : n % m = n - (n / m) * m := by
  rw [eq_sub_iff_add_eq, add_comm, Int.ediv_add_emod']

open Set

lemma exists_finsupp {G : Type*} [AddCommGroup G] {n : ℕ}
    [ElementaryAddCommGroup G (n + 1)] {A : Set G} {x : G} (hx : x ∈ Submodule.span ℤ A) :
    ∃ μ : A →₀ ZMod (n + 1), (μ.sum fun a r ↦ (r : ℤ) • (a : G)) = x := by
  rcases mem_span_set.1 hx with ⟨w, hw, rfl⟩; clear hx
  use (w.subtypeDomain A).mapRange (↑) rfl
  rw [Finsupp.sum_mapRange_index (by simp)]
  set A' := w.support.preimage ((↑) : A → G) injOn_subtype_val
  erw [Finsupp.sum_subtypeDomain_index hw (h := fun (a : G) (r : ℤ) ↦ ((r : ZMod (n+1)) : ℤ) • a)]
  refine (Finsupp.sum_congr ?_).symm
  intro g _
  generalize w g = r
  have : ∃ k : ℤ, ((r : ZMod (n+1)) : ℤ) = r + k*(n+1) := by
    use -(r / (n+1))
    rw_mod_cast [ZMod.coe_int_cast, Int.mod_eq, sub_eq_add_neg, neg_mul]
  rcases this with ⟨k, hk⟩
  rw [hk, add_smul]
  norm_cast
  simp only [char_smul_eq_zero', add_zero]

lemma finite_closure {G : Type*} [AddCommGroup G] {n : ℕ}
    [ElementaryAddCommGroup G (n + 1)] {A : Set G} (h : A.Finite) :
    (AddSubgroup.closure A : Set G).Finite := by
  classical
  have : Fintype A := Finite.fintype h
  have : Fintype (A →₀ ZMod (n + 1)) := Finsupp.fintype
  rw [← Submodule.span_int_eq_addSubgroup_closure, Submodule.coe_toAddSubgroup]
  let φ : (A →₀ ZMod (n + 1)) → G := fun μ ↦ μ.sum fun a r ↦ (r : ℤ) • (a : G)
  have : SurjOn φ univ (Submodule.span ℤ A : Set G) := by
    intro x hx
    rcases exists_finsupp hx with ⟨μ, hμ⟩
    use μ, trivial, hμ
  exact finite_univ.of_surjOn _ this

lemma subgroup {G : Type*} [AddCommGroup G] {n : ℕ}
    [ElementaryAddCommGroup G n] (H : AddSubgroup G) : ElementaryAddCommGroup H n := by
  constructor
  intro x hx
  rw [← AddSubgroup.addOrderOf_coe x]
  apply orderOf_of_ne
  norm_cast

def smul : ZMod 2 → G → G
  | 0, _ => 0
  | 1, x => x

instance (priority := low) module : Module (ZMod 2) G where
  smul := smul
  one_smul := fun _ => rfl
  mul_smul := by
    intro a b x
    fin_cases a <;> fin_cases b <;> abel
  smul_zero := by intro a ; fin_cases a <;> rfl
  smul_add := by
    intro a x y
    fin_cases a
    · change 0 = 0 + 0 ; simp
    · rfl
  add_smul := by
    intro a b x
    fin_cases a <;> fin_cases b
    · simp only [Fin.zero_eta, CharTwo.add_self_eq_zero, ElementaryAddCommGroup.add_self] ; rfl
    · simp only [Fin.zero_eta, Fin.mk_one, zero_add, self_eq_add_left] ; rfl
    · simp only [Fin.mk_one, Fin.zero_eta, add_zero, self_eq_add_right] ; rfl
    · simp only [Fin.mk_one, CharTwo.add_self_eq_zero, ElementaryAddCommGroup.add_self] ; rfl
  zero_smul := fun _ => rfl


lemma quotient_group {G : Type*} [AddCommGroup G] {p : ℕ} (hp: p.Prime) {H : AddSubgroup G} (hH: ∀ x : G, p • x ∈ H) : ElementaryAddCommGroup (G ⧸ H) p := by
  apply of_torsion hp
  intro x
  rcases QuotientAddGroup.mk'_surjective H x with ⟨y, rfl⟩
  simp only [QuotientAddGroup.mk'_apply, ← QuotientAddGroup.mk_nsmul, QuotientAddGroup.eq_zero_iff, hH y]


end ElementaryAddCommGroup
