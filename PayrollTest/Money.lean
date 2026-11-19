import Payroll.Money

open Payroll

-- 端数が 50 銭未満なら切り捨てる
#guard roundHalfDown 9 4 == 2        -- 2.25 円
-- ちょうど 50 銭も切り捨てる
#guard roundHalfDown 5 2 == 2        -- 2.5 円
#guard roundHalfDown 57130 20 == 2856  -- 2856.5 円（標準報酬 58,000 円 × 9.85% ÷ 2）
-- 50 銭を超えたら切り上げる
#guard roundHalfDown 11 4 == 3       -- 2.75 円
#guard roundHalfDown 51 100 == 1     -- 0.51 円
-- 割り切れる場合はそのまま
#guard roundHalfDown 6 3 == 2
#guard roundHalfDown 0 7 == 0
-- 分母が 0 なら 0
#guard roundHalfDown 5 0 == 0

-- 定理が期待どおりの形で使えること
example : 2 * 5 ≤ 2 * (2 * roundHalfDown 5 2) + 2 := (roundHalfDown_close (by decide)).1
example : roundHalfDown 9 4 ≤ roundHalfDown 11 4 := roundHalfDown_mono (by decide)
