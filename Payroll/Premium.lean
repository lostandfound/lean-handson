import Payroll.Rate
import Payroll.Grade

namespace Payroll

/-- 協会けんぽ 東京都、令和 8 年 3 月分からの健康保険料率。出典は docs/sources.md。 -/
def kenpoRate : Rate := ⟨985, 10000, by decide⟩

/-- 厚生年金保険料率。出典は docs/sources.md。 -/
def kouseiRate : Rate := ⟨183, 1000, by decide⟩

/-- 報酬月額から健康保険料の本人負担額を求める。
    ヒント: 等級表で標準報酬月額を引いてから、料率を掛けて折半する。 -/
def kenpoShare (pay : Yen) : Yen :=
  sorry

/-- 報酬月額から厚生年金保険料の本人負担額を求める。 -/
def kouseiShare (pay : Yen) : Yen :=
  sorry

/-- 毎月の給与から控除する社会保険料（介護保険と子ども・子育て支援金は含まない）。 -/
def monthlyDeduction (pay : Yen) : Yen :=
  sorry

end Payroll
