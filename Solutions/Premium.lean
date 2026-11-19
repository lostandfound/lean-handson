import Payroll.Rate
import Payroll.Grade

namespace Payroll

/-- 協会けんぽ 東京都、令和 8 年 3 月分からの健康保険料率。出典は docs/sources.md。 -/
def kenpoRate : Rate := ⟨985, 10000, by decide⟩

/-- 厚生年金保険料率。出典は docs/sources.md。 -/
def kouseiRate : Rate := ⟨183, 1000, by decide⟩

def kenpoShare (pay : Yen) : Yen :=
  employeeShare (lookupStd kenpoTable pay) kenpoRate

def kouseiShare (pay : Yen) : Yen :=
  employeeShare (lookupStd kouseiTable pay) kouseiRate

def monthlyDeduction (pay : Yen) : Yen :=
  kenpoShare pay + kouseiShare pay

end Payroll
