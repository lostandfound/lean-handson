# Lean 4 で学ぶ社会保険料計算 — 設計

## 目的

日本の給与計算のうち、社会保険料（健康保険・厚生年金）の本人負担額の計算を Lean 4 で形式化しながら、Lean のプログラミングと定理証明を学ぶ。

## スコープ

対象とするもの:

- 報酬月額から標準報酬月額を決める等級表の参照（健康保険 50 等級、厚生年金 32 等級）
- 標準報酬月額と料率から、労使折半の本人負担額を計算する処理
- 本人負担額の端数処理（50 銭以下は切り捨て、50 銭を超えたら切り上げ）
- 毎月の控除額（健康保険 + 厚生年金）

対象外とするもの（後の拡張候補）:

- 介護保険（40〜64 歳）
- 賞与（標準賞与額）
- 定時決定・随時改定などの標準報酬月額の決定手続き
- 源泉徴収税、年末調整

前提とするデータ:

- 健康保険は協会けんぽの東京都支部、2026 年度（令和 8 年 3 月分から）の料率と保険料額表を使う。
- 厚生年金は日本年金機構が公表する保険料額表を使う。
- 数値はすべて公表資料から取得し、出典 URL と取得日を `docs/sources.md` に記録する。記憶に頼って数値を書かない。

## 学習の進め方

演習形式で進める。型、データ、テストは用意しておき、関数の本体と証明は `sorry` として残す。学習者が `sorry` を埋めるとテストが通る。

解けない演習を出さないため、模範解答を先に書いてビルドが通ることを確かめ、その後で演習側を `sorry` に置き換える。

## 方針: 金額と料率の表現

Mathlib を使わず、Lean 本体だけで完結させる。

- 金額は `Nat`（円）で表す。
- 料率は分子と分母の組で表す（例: 9.91% は `991 / 10000`）。
- 掛け算は整数のまま最後まで行い、端数処理は割り算の商と余りで判定する。

採らなかった案:

- Mathlib の `ℚ`: 数式どおりに書けるが、Mathlib の取得とビルドが重く、入門には過剰。
- `Float`: 誤差が出るため金額計算には使えない。演習の 1 問で反例として扱うにとどめる。

## リポジトリ構成

```
lean-handson/
├── lakefile.toml
├── lean-toolchain        # セットアップ時点の最新安定版に固定
├── AGENTS.md             # 正本
├── CLAUDE.md             # AGENTS.md へのシンボリックリンク
├── Payroll.lean          # ライブラリのルート
├── Payroll/              # 演習（sorry 入り）
│   ├── Money.lean        # 章 1
│   ├── Rate.lean         # 章 2
│   ├── Grade.lean        # 章 3
│   └── Premium.lean      # 章 4
├── PayrollTest/          # テスト（#guard / example）
├── Solutions/            # 模範解答（lake のビルド対象外）
└── docs/
    ├── 00-setup.md       # 章 0: 環境構築
    ├── 01-money.md 〜 04-premium.md
    └── sources.md        # 数値の出典
```

テストは別ライブラリ `PayrollTest` に置く。演習が `sorry` のままでも `Payroll` 本体のビルドは警告だけで通り、`PayrollTest` のビルドだけが失敗する。

## 章立て

### 章 0: 環境構築

- `elan` をインストールする（公式スクリプトまたは `brew install elan-init`）。
- VS Code に拡張機能「Lean 4」を入れる。
- `lake build` が通ることを確認する。

### 章 1: 金額と端数処理（`Payroll/Money.lean`）

```lean
abbrev Yen := Nat

/-- num / den 円を、50 銭以下は切り捨て、50 銭超は切り上げて円にする。den = 0 のときは 0 を返す。 -/
def roundHalfDown (num den : Nat) : Yen

/-- 丸めた結果と真の値の差は 0.5 円以内。絶対値を使わず Nat の不等式 2 本で表す。 -/
theorem roundHalfDown_close (h : 0 < den) :
    let r := roundHalfDown num den
    2 * num ≤ (2 * r + 1) * den ∧ 2 * r * den < 2 * num + den

/-- 分母を固定すると、分子について単調。 -/
theorem roundHalfDown_mono (h : n₁ ≤ n₂) :
    roundHalfDown n₁ den ≤ roundHalfDown n₂ den
```

学ぶこと: `def`、`Nat` の `/` と `%`、`if`、`#eval`、`omega`。

### 章 2: 料率（`Payroll/Rate.lean`）

```lean
structure Rate where
  num : Nat
  den : Nat
  den_pos : 0 < den

/-- 標準報酬月額 × 料率 の全額（端数処理後）。 -/
def totalPremium (std : Yen) (r : Rate) : Yen :=
  roundHalfDown (std * r.num) r.den

/-- 労使折半の本人負担額。std × num / (2 × den) を端数処理する。 -/
def employeeShare (std : Yen) (r : Rate) : Yen

theorem employeeShare_le_total : employeeShare std r ≤ totalPremium std r
```

学ぶこと: `structure`、証明をフィールドに持つ型、章 1 の補題の再利用。

### 章 3: 等級表（`Payroll/Grade.lean`）

```lean
structure GradeRow where
  grade : Nat
  std   : Yen   -- 標準報酬月額
  lower : Yen   -- 報酬月額の下限（この額以上がこの等級）

/-- 表が昇順に並んでいること。Mathlib の List.Sorted は使わず、core の List.Pairwise で定義する。 -/
def SortedTable (t : List GradeRow) : Prop :=
  t.Pairwise (fun a b => a.lower < b.lower ∧ a.std < b.std)

/-- lower ≤ pay を満たす行のうち最後の行の std を返す。該当行がなければ 0。 -/
def lookupStd (t : List GradeRow) (pay : Yen) : Yen

theorem lookupStd_mono (hs : SortedTable t) (h : p₁ ≤ p₂) :
    lookupStd t p₁ ≤ lookupStd t p₂

def kenpoTable : List GradeRow    -- 健康保険 50 等級
def kouseiTable : List GradeRow   -- 厚生年金 32 等級

theorem kenpoTable_sorted : SortedTable kenpoTable    -- decide で示す
theorem kouseiTable_sorted : SortedTable kouseiTable
```

報酬月額には上限がないので、`decide` による全数検査では単調性を示せない。ソート済みの表一般について帰納法で示す。全章で最も難しい演習になる。

学ぶこと: `List`、パターンマッチ、再帰、帰納法、`decide`。

### 章 4: 合成（`Payroll/Premium.lean`）

```lean
def kenpoRate : Rate     -- 協会けんぽ 東京都 2026 年度
def kouseiRate : Rate    -- 厚生年金 18.3%（公表資料で確認する）

def monthlyDeduction (pay : Yen) : Yen :=
  employeeShare (lookupStd kenpoTable pay) kenpoRate
  + employeeShare (lookupStd kouseiTable pay) kouseiRate
```

公表されている保険料額表から数行を選び、本人負担額が一致することを `PayrollTest` で確かめる。

## テスト

- 各章に `PayrollTest/<章>.lean` を置き、`#guard` で具体的な値を確かめる。
- 章 4 のテストの期待値は、公表されている保険料額表の値をそのまま使う。
- 完了の条件は、`Payroll` と `PayrollTest` の両方が `sorry` の警告なしでビルドできること（模範解答で確認する）。

## 注意

端数処理の規則は、事業主と被保険者の間に特約がない場合のもの（給与から控除するときは 50 銭以下を切り捨て、50 銭を超えたら切り上げ）とする。これは学習用のモデルであり、実務で使う計算の正しさは保証しない。
