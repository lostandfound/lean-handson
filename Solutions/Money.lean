namespace Payroll

-- abbrev だと omega が Yen を Nat と認識しないため notation にする
notation "Yen" => Nat

def roundHalfDown (num den : Nat) : Yen :=
  if den = 0 then 0
  -- 端数 r/den ≤ 1/2 を、割り算を使わず 2r ≤ den で判定する
  else if 2 * (num % den) ≤ den then num / den
  else num / den + 1

theorem roundHalfDown_close {num den : Nat} (h : 0 < den) :
    2 * num ≤ 2 * (den * roundHalfDown num den) + den ∧
    2 * (den * roundHalfDown num den) < 2 * num + den := by
  have key := Nat.div_add_mod num den
  have hlt := Nat.mod_lt num h
  unfold roundHalfDown
  split
  · omega
  · split
    · omega
    · rw [Nat.mul_add, Nat.mul_one]
      omega

theorem roundHalfDown_mono {n₁ n₂ den : Nat} (h : n₁ ≤ n₂) :
    roundHalfDown n₁ den ≤ roundHalfDown n₂ den := by
  by_cases hd : den = 0
  · simp [roundHalfDown, hd]
  · have hpos : 0 < den := Nat.pos_of_ne_zero hd
    have h1 := (roundHalfDown_close (num := n₁) hpos).2
    have h2 := (roundHalfDown_close (num := n₂) hpos).1
    have hlt : den * roundHalfDown n₁ den < den * (roundHalfDown n₂ den + 1) := by
      rw [Nat.mul_add, Nat.mul_one]
      omega
    have := Nat.lt_of_mul_lt_mul_left hlt
    omega

end Payroll
