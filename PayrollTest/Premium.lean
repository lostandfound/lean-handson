import Payroll.Premium

open Payroll

-- 公表資料（docs/sources.md）の保険料額表との照合
-- 健康保険（東京都 9.85%）の折半額
#guard kenpoShare 60000 == 2856       -- 標準報酬 58,000 円: 2,856.5 → 2,856
#guard kenpoShare 300000 == 14775     -- 標準報酬 300,000 円
#guard kenpoShare 650000 == 32012     -- 標準報酬 650,000 円: 32,012.5 → 32,012
#guard kenpoShare 2000000 == 68457    -- 標準報酬 1,390,000 円: 68,457.5 → 68,457
-- 厚生年金（18.3%）の折半額
#guard kouseiShare 50000 == 8052      -- 標準報酬 88,000 円
#guard kouseiShare 300000 == 27450    -- 標準報酬 300,000 円
#guard kouseiShare 2000000 == 59475   -- 標準報酬 650,000 円
-- 月額控除 = 健康保険 + 厚生年金
#guard monthlyDeduction 300000 == 42225
#guard monthlyDeduction 2000000 == 68457 + 59475
