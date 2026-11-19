# AGENTS.md

Lean 4 の学習用リポジトリ。日本の社会保険料（協会けんぽ東京都の健康保険と厚生年金）の本人負担額の計算を題材に、`sorry` を埋める演習形式で進める。設計は `docs/superpowers/specs/2026-11-19-payroll-lean-design.md` を参照。

## コマンド

- `lake build Payroll`: 演習をビルドする。`sorry` の警告は出てよい。
- `lake build PayrollTest`: テストを実行する。演習が解けるまでは失敗する。
- `scripts/check-solutions.sh`: 模範解答を演習に重ねてビルドし、正しさを確かめる。

## 規則

- Mathlib を依存に加えない。
- `Payroll/` には `sorry` 入りの演習だけを置く。学習者に頼まれないかぎり、エージェントが演習の `sorry` を埋めない。
- 完成した実装は `Solutions/` に置き、変更したら `scripts/check-solutions.sh` を実行する。
- 料率と等級表の数値は公表資料から取り、出典を `docs/sources.md` に記録する。記憶で数値を書かない。
- ヒントを求められたら、答えのコードではなく、使う補題やタクティクの名前と考え方を示す。
