import Payroll.Money

namespace Payroll

/-- 料率を分子と分母で表す。9.85% は `⟨985, 10000, by decide⟩`。
    `den_pos` があるので、分母が 0 の料率は作れない。 -/
structure Rate where
  num : Nat
  den : Nat
  den_pos : 0 < den

/-- 標準報酬月額 × 料率 の全額（端数処理後）。 -/
def totalPremium (std : Yen) (r : Rate) : Yen :=
  roundHalfDown (std * r.num) r.den

/-- 労使折半の本人負担額。`std * num / (2 * den)` を端数処理する。
    ヒント: `roundHalfDown` に渡す分母を考える。 -/
def employeeShare (std : Yen) (r : Rate) : Yen :=
  sorry

/-- 本人負担額は全額を超えない。
    ヒント: `roundHalfDown_close` を本人負担額（分母 `2 * r.den`）と全額（分母 `r.den`）に
    1 回ずつ使い、`r.den` を約分して `omega` で閉じる。 -/
theorem employeeShare_le_total (std : Yen) (r : Rate) :
    employeeShare std r ≤ totalPremium std r := by
  sorry

end Payroll
