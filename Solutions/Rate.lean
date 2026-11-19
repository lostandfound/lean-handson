import Payroll.Money

namespace Payroll

structure Rate where
  num : Nat
  den : Nat
  den_pos : 0 < den

def totalPremium (std : Yen) (r : Rate) : Yen :=
  roundHalfDown (std * r.num) r.den

def employeeShare (std : Yen) (r : Rate) : Yen :=
  roundHalfDown (std * r.num) (2 * r.den)

theorem employeeShare_le_total (std : Yen) (r : Rate) :
    employeeShare std r ≤ totalPremium std r := by
  have hd := r.den_pos
  have h1 := (roundHalfDown_close (num := std * r.num) (by omega : 0 < 2 * r.den)).2
  have h2 := (roundHalfDown_close (num := std * r.num) hd).1
  unfold employeeShare totalPremium
  generalize roundHalfDown (std * r.num) (2 * r.den) = a at *
  generalize roundHalfDown (std * r.num) r.den = b at *
  -- h1 : 2 * (2 * r.den * a) < 2 * (std * r.num) + 2 * r.den
  -- h2 : 2 * (std * r.num) ≤ 2 * (r.den * b) + r.den
  rw [Nat.mul_assoc] at h1
  have key : r.den * (4 * a) < r.den * (2 * b + 3) := by
    rw [Nat.mul_add, Nat.mul_left_comm r.den 4 a, Nat.mul_left_comm r.den 2 b]
    omega
  have := Nat.lt_of_mul_lt_mul_left key
  omega

end Payroll
