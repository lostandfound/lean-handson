import Payroll.Rate

open Payroll

-- テスト用の料率。章 4 の本番の料率とは独立に置く
def rate985 : Rate := ⟨985, 10000, by decide⟩   -- 9.85%
def rate183 : Rate := ⟨183, 1000, by decide⟩    -- 18.3%

-- 標準報酬月額 300,000 円、9.85%: 全額 29,550 円、本人 14,775 円
#guard totalPremium 300000 rate985 == 29550
#guard employeeShare 300000 rate985 == 14775
-- 58,000 円、9.85%: 全額 5,713 円、本人 2,856.5 円 → 50 銭は切り捨てて 2,856 円
#guard totalPremium 58000 rate985 == 5713
#guard employeeShare 58000 rate985 == 2856
-- 88,000 円、18.3%: 全額 16,104 円、本人 8,052 円
#guard employeeShare 88000 rate183 == 8052

example : employeeShare 58000 rate985 ≤ totalPremium 58000 rate985 :=
  employeeShare_le_total 58000 rate985
