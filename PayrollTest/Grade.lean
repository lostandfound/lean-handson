import Payroll.Grade

open Payroll

-- 表の大きさ
#guard kenpoTable.length == 50
#guard kouseiTable.length == 32
-- 表が昇順であること
#guard sortedB kenpoTable
#guard sortedB kouseiTable
#guard !sortedB (mkTable [(1, 200, 0), (2, 100, 10)])   -- std が減る表は不正
-- 健康保険: 等級の境目
#guard lookupStd kenpoTable 0 == 58000
#guard lookupStd kenpoTable 62999 == 58000
#guard lookupStd kenpoTable 63000 == 68000
#guard lookupStd kenpoTable 300000 == 300000
#guard lookupStd kenpoTable 1355000 == 1390000
#guard lookupStd kenpoTable 5000000 == 1390000   -- 上限
-- 厚生年金: 下限と上限
#guard lookupStd kouseiTable 50000 == 88000
#guard lookupStd kouseiTable 300000 == 300000
#guard lookupStd kouseiTable 634999 == 620000
#guard lookupStd kouseiTable 635000 == 650000
#guard lookupStd kouseiTable 5000000 == 650000   -- 上限
-- 空の表
#guard lookupStd [] 100 == 0

example : lookupStd kenpoTable 100000 ≤ lookupStd kenpoTable 200000 :=
  lookupStd_mono kenpoTable (by decide)
