# 社会保険料計算で学ぶ Lean 4 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) または superpowers:executing-plans でタスクごとに実装する。各ステップは `- [ ]` のチェックボックスで進捗を管理する。

**Goal:** 協会けんぽ（東京都、2026 年度）と厚生年金の本人負担保険料を計算する Lean 4 プロジェクトを、`sorry` を埋めて進める演習教材として作る。

**Architecture:** Lean 本体のみ（Mathlib なし）の Lake プロジェクト。演習 `Payroll/`、テスト `PayrollTest/`、模範解答 `Solutions/` を分ける。模範解答は `scripts/check-solutions.sh` が一時ディレクトリで `Payroll/` に重ねてビルドし、正しさを確かめる。

**Tech Stack:** Lean 4（elan で導入、最新の安定版に固定）、Lake（`lakefile.toml`）、bash、VS Code の Lean 4 拡張機能。

**Spec:** `docs/superpowers/specs/2026-11-19-payroll-lean-design.md`

## Global Constraints

- Mathlib を依存に加えない。Lean 本体と core の補題・タクティク（`omega`、`decide`、`simp`、`split`、`induction`）だけを使う。
- 金額は `Nat`（円）で表す。`Float` と `ℚ` は使わない。
- 名前空間はすべて `Payroll`。
- 端数処理は「50 銭以下は切り捨て、50 銭を超えたら切り上げ」。
- 料率と等級表の数値は公表資料から取得し、出典 URL と取得日を `docs/sources.md` に記録する。計画に書いた数値は下書きであり、公表資料との照合が終わるまでは確定値として扱わない。
- 演習側 `Payroll/*.lean` には `sorry` 入りの版だけを置く。完成した実装は `Solutions/*.lean` に置く。
- 文書（`.md`）は通常の日本語で書く。
- コミットメッセージには変更の理由を書き、末尾に `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` を付ける。
- ブランチは `main`。リモートは `origin`（`https://github.com/lostandfound/lean-handson.git`）。push は利用者の指示があるまでしない。

## ファイル構成

- `lean-toolchain`: Lean のバージョンを固定する。
- `lakefile.toml`: ライブラリ `Payroll`（既定のビルド対象）と `PayrollTest` を定義する。`Solutions` はビルド対象に含めない。
- `.gitignore`: `.lake/` を除外する。
- `AGENTS.md`: エージェント向けの作業規則（正本）。`CLAUDE.md` はそこへのシンボリックリンク。
- `Payroll.lean` / `PayrollTest.lean`: 各ライブラリのルート。章を追加するたびに import を足す。
- `Payroll/Money.lean`: 円の型と端数処理（章 1）。
- `Payroll/Rate.lean`: 料率と本人負担額（章 2）。
- `Payroll/Grade.lean`: 等級表の型、参照、具体的な表（章 3）。
- `Payroll/Premium.lean`: 料率の具体値と月額控除（章 4）。
- `PayrollTest/<章>.lean`: 各章の `#guard` テスト。
- `Solutions/<章>.lean`: 各章の模範解答。`Payroll/<章>.lean` と同じモジュール名、同じ宣言を持つ。
- `scripts/check-solutions.sh`: 模範解答の検証。
- `docs/00-setup.md`〜`docs/04-premium.md`: 各章の解説。`docs/sources.md`: 出典。

## 各章のタスクに共通する流れ

1. テスト `PayrollTest/<章>.lean` を書く。
2. 演習 `Payroll/<章>.lean` を `sorry` 入りで書く。`lake build Payroll` は警告だけで通り、`lake build PayrollTest` は失敗することを確かめる。
3. 模範解答 `Solutions/<章>.lean` を書き、`scripts/check-solutions.sh` が成功することを確かめる。
4. 解説 `docs/0N-<章>.md` を書いてコミットする。

模範解答の証明が書いたとおりに通らない場合は、定理の主張を変えずに証明だけを直す。主張を変える必要が出た場合は、spec と演習とテストを同時に直し、その理由をコミットメッセージに書く。

---

### Task 1: 環境構築とプロジェクトの骨組み

**Files:**
- Create: `lean-toolchain`, `lakefile.toml`, `.gitignore`, `AGENTS.md`, `CLAUDE.md`（シンボリックリンク）, `Payroll.lean`, `PayrollTest.lean`, `scripts/check-solutions.sh`, `docs/00-setup.md`

**Interfaces:**
- Produces: `lake build Payroll` と `lake build PayrollTest` が動くプロジェクト。`scripts/check-solutions.sh`（引数なし。成功で終了コード 0、`sorry` が残るかビルドに失敗すると 1）。

- [ ] **Step 1: elan をインストールする**

利用者のマシンにソフトウェアを入れる操作なので、実行前に利用者の了承を得る。

```bash
brew install elan-init
elan default stable
lean --version
lake --version
```

Expected: `Lean (version 4.x.y, ...)` と Lake のバージョンが表示される。

- [ ] **Step 2: Lean のバージョンを固定する**

```bash
cd /Users/lostandfound/gitlab/lean-handson
tag=$(curl -s https://api.github.com/repos/leanprover/lean4/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
echo "leanprover/lean4:${tag}" > lean-toolchain
cat lean-toolchain
```

Expected: `leanprover/lean4:v4.x.y` の 1 行（`-rc` が付かない安定版）。

- [ ] **Step 3: `lakefile.toml` と `.gitignore` を書く**

`lakefile.toml`:

```toml
name = "payroll"
defaultTargets = ["Payroll"]

[[lean_lib]]
name = "Payroll"

[[lean_lib]]
name = "PayrollTest"
```

`.gitignore`:

```
.lake/
```

- [ ] **Step 4: ルートモジュールを書く**

`Payroll.lean`（章を追加するたびに import を足す。最初は空）:

```lean
-- 各章のモジュールをここで import する
```

`PayrollTest.lean`:

```lean
-- 各章のテストモジュールをここで import する
```

- [ ] **Step 5: ビルドが通ることを確かめる**

Run: `lake build Payroll PayrollTest`
Expected: エラーなしで完了する。

- [ ] **Step 6: `scripts/check-solutions.sh` を書く**

```bash
#!/usr/bin/env bash
# 模範解答を演習に重ね、sorry なしで全体がビルドできることを確かめる。
# 作業ツリーを汚さないよう、一時ディレクトリにコピーしてから上書きする。
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

rsync -a --exclude .git --exclude .lake "$root/" "$tmp/"
if compgen -G "$root/Solutions/*.lean" > /dev/null; then
  cp "$root"/Solutions/*.lean "$tmp/Payroll/"
fi

cd "$tmp"
if ! lake build Payroll PayrollTest > build.log 2>&1; then
  cat build.log
  echo "check-solutions: build failed" >&2
  exit 1
fi
if grep -q "declaration uses 'sorry'" build.log; then
  grep "declaration uses 'sorry'" build.log
  echo "check-solutions: sorry remains" >&2
  exit 1
fi
echo "check-solutions: OK"
```

```bash
chmod +x scripts/check-solutions.sh
mkdir -p Solutions && touch Solutions/.gitkeep
scripts/check-solutions.sh
```

Expected: `check-solutions: OK`

- [ ] **Step 7: `AGENTS.md` と `CLAUDE.md` を作る**

`AGENTS.md`:

```markdown
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
```

```bash
ln -s AGENTS.md CLAUDE.md
ls -l CLAUDE.md
```

Expected: `CLAUDE.md -> AGENTS.md`

- [ ] **Step 8: `docs/00-setup.md` を書く**

```markdown
# 章 0: 環境構築

## 必要なもの

- elan: Lean のバージョン管理ツール。`brew install elan-init` で入る。
- VS Code と拡張機能「Lean 4」（発行元 leanprover）。

## 手順

1. `brew install elan-init` を実行し、続けて `elan default stable` を実行する。
2. このリポジトリを VS Code で開く。初回は `lean-toolchain` に書かれたバージョンの Lean が自動でダウンロードされる。
3. ターミナルで `lake build Payroll` を実行し、エラーなく終わることを確かめる。
4. `Payroll/Money.lean` を開き、右側の「Lean Infoview」に証明の状態が表示されることを確かめる。

## 進め方

- `Payroll/` の各ファイルにある `sorry` を、章の順に埋めていく。
- `lake build PayrollTest` が通れば、その章は解けている。
- 詰まったときは `docs/0N-*.md` のヒントを読む。模範解答は `Solutions/` にあるが、まず自分で考えてから開く。
```

- [ ] **Step 9: コミットする**

```bash
git add lean-toolchain lakefile.toml .gitignore AGENTS.md CLAUDE.md Payroll.lean PayrollTest.lean scripts Solutions/.gitkeep docs/00-setup.md
git commit -F - <<'EOF'
chore: Lean プロジェクトの骨組みと模範解答の検証スクリプトを追加

演習（sorry 入り）と模範解答を別々に置くため、模範解答を一時ディレクトリで演習に重ねて
ビルドするスクリプトを用意した。これで作業ツリーを汚さずに、解ける演習だけを出せる。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: 章 1 金額と端数処理

**Files:**
- Create: `PayrollTest/Money.lean`, `Payroll/Money.lean`, `Solutions/Money.lean`, `docs/01-money.md`
- Modify: `Payroll.lean`, `PayrollTest.lean`

**Interfaces:**
- Produces:
  - `abbrev Payroll.Yen := Nat`
  - `def Payroll.roundHalfDown (num den : Nat) : Yen`
  - `theorem Payroll.roundHalfDown_close {num den : Nat} (h : 0 < den) : 2 * num ≤ 2 * (den * roundHalfDown num den) + den ∧ 2 * (den * roundHalfDown num den) < 2 * num + den`
  - `theorem Payroll.roundHalfDown_mono {n₁ n₂ den : Nat} (h : n₁ ≤ n₂) : roundHalfDown n₁ den ≤ roundHalfDown n₂ den`

- [ ] **Step 1: テストを書く**

`PayrollTest/Money.lean`:

```lean
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
```

`PayrollTest.lean` に `import PayrollTest.Money` を追加する。

- [ ] **Step 2: 演習を書く**

`Payroll/Money.lean`:

```lean
namespace Payroll

/-- 金額（円）。保険料も報酬も負にならないので Nat で表す。 -/
abbrev Yen := Nat

/-- `num / den` 円を、50 銭以下は切り捨て、50 銭を超えたら切り上げて円にする。
    `den = 0` のときは 0 を返す。
    ヒント: 商 `num / den` と余り `num % den` を使う。端数 `余り / den` が 1/2 以下かどうかを、
    割り算をせずに判定する方法を考える。 -/
def roundHalfDown (num den : Nat) : Yen :=
  sorry

/-- 丸めた結果と真の値 `num / den` の差は 0.5 円以内。
    ヒント: `Nat.div_add_mod num den` と `Nat.mod_lt num h` を `have` で手元に置き、
    `unfold roundHalfDown` してから `split` で場合分けし、`omega` で閉じる。 -/
theorem roundHalfDown_close {num den : Nat} (h : 0 < den) :
    2 * num ≤ 2 * (den * roundHalfDown num den) + den ∧
    2 * (den * roundHalfDown num den) < 2 * num + den := by
  sorry

/-- 分母を固定すると、分子について単調。
    ヒント: `den = 0` の場合と `0 < den` の場合に分ける。後者では `roundHalfDown_close` を
    2 回使い、`Nat.lt_of_mul_lt_mul_left` で `den` を約分する。 -/
theorem roundHalfDown_mono {n₁ n₂ den : Nat} (h : n₁ ≤ n₂) :
    roundHalfDown n₁ den ≤ roundHalfDown n₂ den := by
  sorry

end Payroll
```

`Payroll.lean` に `import Payroll.Money` を追加する。

- [ ] **Step 3: 演習の状態を確かめる**

Run: `lake build Payroll`
Expected: 成功し、`declaration uses 'sorry'` の警告が 3 件出る。

Run: `lake build PayrollTest`
Expected: `#guard` の行でエラーになって失敗する（`sorry` に依存する式は評価できないため）。失敗しない場合は、`#guard` が `sorry` を検出しないということなので、作業を止めて報告する。

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: build failed`（模範解答がまだないため）。

- [ ] **Step 4: 模範解答を書く**

`Solutions/Money.lean`:

```lean
namespace Payroll

abbrev Yen := Nat

def roundHalfDown (num den : Nat) : Yen :=
  if den = 0 then 0
  -- 端数 r/den ≤ 1/2 を、割り算を使わず 2r ≤ den で判定する
  else if 2 * (num % den) ≤ den then num / den
  else num / den + 1

theorem roundHalfDown_close {num den : Nat} (h : 0 < den) :
    2 * num ≤ 2 * (den * roundHalfDown num den) + den ∧
    2 * (den * roundHalfDown num den) < 2 * num + den := by
  have key := Nat.div_add_mod num den
  have hlt := Nat.mod_lt num h
  unfold roundHalfDown
  split
  · omega
  · split
    · omega
    · rw [Nat.mul_add, Nat.mul_one]
      omega

theorem roundHalfDown_mono {n₁ n₂ den : Nat} (h : n₁ ≤ n₂) :
    roundHalfDown n₁ den ≤ roundHalfDown n₂ den := by
  by_cases hd : den = 0
  · simp [roundHalfDown, hd]
  · have hpos : 0 < den := Nat.pos_of_ne_zero hd
    have h1 := (roundHalfDown_close (num := n₁) hpos).2
    have h2 := (roundHalfDown_close (num := n₂) hpos).1
    have hlt : den * roundHalfDown n₁ den < den * (roundHalfDown n₂ den + 1) := by
      rw [Nat.mul_add, Nat.mul_one]
      omega
    have := Nat.lt_of_mul_lt_mul_left hlt
    omega

end Payroll
```

- [ ] **Step 5: 模範解答を検証する**

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: OK`

- [ ] **Step 6: 解説を書く**

`docs/01-money.md`:

```markdown
# 章 1: 金額と端数処理

## 題材

健康保険料と厚生年金保険料の本人負担額を給与から控除するとき、1 円未満の端数は
「50 銭以下は切り捨て、50 銭を超えたら切り上げ」で処理する（事業主と被保険者の間に特約がない場合）。
四捨五入とは、ちょうど 50 銭のときの扱いが違う。

## 学ぶこと

- `def` による関数定義と `if ... then ... else`
- `Nat` の割り算 `/`（切り捨て）と余り `%`
- `#eval` と `#guard` による動作確認
- `theorem` と `by` で始まる証明、`have`、`unfold`、`split`、`omega`

## なぜ Float を使わないか

`#eval (0.1 + 0.2 : Float)` を実行すると `0.300000` と表示されるが、
`#eval (0.1 + 0.2 : Float) == 0.3` は `false` になる。2 進数の浮動小数点では 0.1 を正確に表せないためである。
金額で同じことが起きると、50 銭ちょうどの判定を誤る。この教材では、料率を分子と分母の整数で持ち、
割り算を最後の 1 回だけにする。

## 演習

`Payroll/Money.lean` の `sorry` を上から順に埋める。

1. `roundHalfDown`: 端数 `num % den` を `den` と比べる。`r / den ≤ 1/2` は、両辺に `2 * den` を掛けると `2 * r ≤ den` になる。
2. `roundHalfDown_close`: 「誤差が 0.5 円以内」を、分数を使わずに不等式 2 本で表したもの。
   `omega` は掛け算 `den * (num / den)` を 1 つの変数のように扱うので、同じ形の項が仮定と結論に現れるようにそろえる。
3. `roundHalfDown_mono`: 分子が大きいほど丸めた結果も大きい（減らない）。章 2 で使う。

`lake build PayrollTest` が通れば完了。
```

- [ ] **Step 7: コミットする**

```bash
git add Payroll.lean PayrollTest.lean Payroll/Money.lean PayrollTest/Money.lean Solutions/Money.lean docs/01-money.md
git commit -F - <<'EOF'
feat: 章 1 金額と端数処理の演習を追加

社会保険料の本人負担額は 50 銭以下切り捨て・50 銭超切り上げで丸めるため、
これを Nat の商と余りだけで表す。誤差の上界と単調性は後の章の証明で使う。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: 章 2 料率と本人負担額

**Files:**
- Create: `PayrollTest/Rate.lean`, `Payroll/Rate.lean`, `Solutions/Rate.lean`, `docs/02-rate.md`
- Modify: `Payroll.lean`, `PayrollTest.lean`

**Interfaces:**
- Consumes: `Payroll.Yen`, `Payroll.roundHalfDown`, `Payroll.roundHalfDown_close`（Task 2）
- Produces:
  - `structure Payroll.Rate where num : Nat; den : Nat; den_pos : 0 < den`
  - `def Payroll.totalPremium (std : Yen) (r : Rate) : Yen`
  - `def Payroll.employeeShare (std : Yen) (r : Rate) : Yen`
  - `theorem Payroll.employeeShare_le_total (std : Yen) (r : Rate) : employeeShare std r ≤ totalPremium std r`

- [ ] **Step 1: テストを書く**

`PayrollTest/Rate.lean`:

```lean
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
```

`PayrollTest.lean` に `import PayrollTest.Rate` を追加する。

- [ ] **Step 2: 演習を書く**

`Payroll/Rate.lean`:

```lean
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
```

`Payroll.lean` に `import Payroll.Rate` を追加する。

- [ ] **Step 3: 演習の状態を確かめる**

Run: `lake build Payroll`
Expected: 成功する（`sorry` の警告あり）。

Run: `lake build PayrollTest`
Expected: 失敗する。

Run: `scripts/check-solutions.sh`
Expected: 失敗する（`Solutions/Rate.lean` がなく、演習の `sorry` が残るため）。

- [ ] **Step 4: 模範解答を書く**

`Solutions/Rate.lean`:

```lean
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
```

`Solutions/Rate.lean` の `import Payroll.Money` は、検証時には `Solutions/Money.lean` を重ねた版を読む。

- [ ] **Step 5: 模範解答を検証する**

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: OK`

- [ ] **Step 6: 解説を書く**

`docs/02-rate.md`:

```markdown
# 章 2: 料率と本人負担額

## 題材

健康保険料と厚生年金保険料は「標準報酬月額 × 料率」で決まり、事業主と被保険者が半分ずつ負担する（労使折半）。
給与から控除するのは本人負担分で、章 1 の端数処理をかける。

## 学ぶこと

- `structure` による型の定義と、無名コンストラクタ `⟨985, 10000, by decide⟩`
- 証明をフィールドに持つ型（`den_pos`）。不正な値を作れなくする
- 前の章の定理を `have` で取り出して使う
- `generalize` で長い式に名前を付ける、`rw` で式の形をそろえる

## 演習

`Payroll/Rate.lean` の `sorry` を埋める。

1. `employeeShare`: 全額 `std * num / den` の半分は `std * num / (2 * den)`。
   全額を丸めてから 2 で割るのではなく、半分にしてから 1 回だけ丸める。
2. `employeeShare_le_total`: 本人負担額が全額を超えないこと。当たり前に見えるが、
   2 回の丸めの誤差が重なるので、章 1 の誤差の上界を両方に使って示す。

`lake build PayrollTest` が通れば完了。
```

- [ ] **Step 7: コミットする**

```bash
git add Payroll.lean PayrollTest.lean Payroll/Rate.lean PayrollTest/Rate.lean Solutions/Rate.lean docs/02-rate.md
git commit -F - <<'EOF'
feat: 章 2 料率と本人負担額の演習を追加

保険料は標準報酬月額と料率の積を労使で折半するため、料率を分子と分母で持つ型を用意した。
分母が 0 の料率を型で排除し、本人負担が全額を超えないことを丸め誤差込みで示す。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: 等級表と料率の公表資料を取得する

**Files:**
- Create: `docs/sources.md`

**Interfaces:**
- Produces: Task 5 と Task 6 が使う確定値（健康保険 50 等級と厚生年金 32 等級の「等級・標準報酬月額・報酬月額の下限」、健康保険料率、厚生年金保険料率、照合用の保険料額表の行）。

- [ ] **Step 1: 公表資料を取得する**

次の公式サイトから、2026 年度（令和 8 年 3 月分から）の資料を取得する。ダウンロードしたファイルは scratchpad の専用ディレクトリに置き、リポジトリには入れない。

- 全国健康保険協会（協会けんぽ）「令和 8 年度保険料額表（東京支部）」: https://www.kyoukaikenpo.or.jp/
- 日本年金機構「厚生年金保険料額表」: https://www.nenkin.go.jp/

- [ ] **Step 2: 下書きの値と照合する**

次の下書きを公表資料と 1 行ずつ照合する。違いがあれば公表資料の値を採用し、違いがあったことを `docs/sources.md` に書く。

健康保険料率（東京都）: 9.85%（民間サイトの記載。公式資料で確認する）。厚生年金保険料率: 18.3%。

健康保険の等級表（等級, 標準報酬月額, 報酬月額の下限）:

```
1 58000 0
2 68000 63000
3 78000 73000
4 88000 83000
5 98000 93000
6 104000 101000
7 110000 107000
8 118000 114000
9 126000 122000
10 134000 130000
11 142000 138000
12 150000 146000
13 160000 155000
14 170000 165000
15 180000 175000
16 190000 185000
17 200000 195000
18 220000 210000
19 240000 230000
20 260000 250000
21 280000 270000
22 300000 290000
23 320000 310000
24 340000 330000
25 360000 350000
26 380000 370000
27 410000 395000
28 440000 425000
29 470000 455000
30 500000 485000
31 530000 515000
32 560000 545000
33 590000 575000
34 620000 605000
35 650000 635000
36 680000 665000
37 710000 695000
38 750000 730000
39 790000 770000
40 830000 810000
41 880000 855000
42 930000 905000
43 980000 955000
44 1030000 1005000
45 1090000 1055000
46 1150000 1115000
47 1210000 1175000
48 1270000 1235000
49 1330000 1295000
50 1390000 1355000
```

厚生年金の等級表: 厚生年金の第 n 級は、健康保険の第 n+3 級と同じ標準報酬月額（n = 1〜32）。下限は、第 1 級だけ 0、それ以外は健康保険の第 n+3 級と同じ。第 1 級は 88,000 円、第 32 級は 650,000 円。

照合用の行（Task 6 のテストに使う）: 標準報酬月額 58,000 円、300,000 円、650,000 円、1,390,000 円の健康保険料（全額・折半額）と、88,000 円、300,000 円、650,000 円の厚生年金保険料（全額・折半額）を公表資料から書き写す。

- [ ] **Step 3: `docs/sources.md` を書く**

```markdown
# 数値の出典

この教材で使う料率と等級表の出典。数値を変えるときは、ここに出典と取得日を追記する。

## 健康保険（協会けんぽ 東京支部、令和 8 年 3 月分から）

- 資料: 令和 8 年度保険料額表（東京支部）
- URL: （取得した資料の URL）
- 取得日: （取得した日付）
- 健康保険料率: （資料の値）

## 厚生年金保険

- 資料: 厚生年金保険料額表
- URL: （取得した資料の URL）
- 取得日: （取得した日付）
- 厚生年金保険料率: （資料の値）

## 照合用の行

（Step 2 で書き写した行を、標準報酬月額・全額・折半額の 3 列で書く）

## 下書きとの違い

（違いがなければ「なし」と書く）
```

括弧の部分は、このステップで実際の値に置き換えてからコミットする。括弧が残ったままコミットしない。

- [ ] **Step 4: コミットする**

```bash
git add docs/sources.md
git commit -F - <<'EOF'
docs: 料率と等級表の出典を記録

等級表と料率は毎年改定されうるため、教材で使う数値がどの公表資料のどの版に基づくかを残す。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: 章 3 等級表

**Files:**
- Create: `PayrollTest/Grade.lean`, `Payroll/Grade.lean`, `Solutions/Grade.lean`, `docs/03-grade.md`
- Modify: `Payroll.lean`, `PayrollTest.lean`

**Interfaces:**
- Consumes: `Payroll.Yen`（Task 2）、Task 4 で確定した等級表
- Produces:
  - `structure Payroll.GradeRow where grade : Nat; std : Yen; lower : Yen`
  - `def Payroll.mkTable (rows : List (Nat × Yen × Yen)) : List GradeRow`
  - `def Payroll.lookupStd : List GradeRow → Yen → Yen`
  - `theorem Payroll.lookupStd_mono (t : List GradeRow) {p₁ p₂ : Yen} (h : p₁ ≤ p₂) : lookupStd t p₁ ≤ lookupStd t p₂`
  - `def Payroll.sortedB : List GradeRow → Bool`
  - `def Payroll.kenpoTable : List GradeRow`、`def Payroll.kouseiTable : List GradeRow`
  - `theorem Payroll.kenpoTable_sorted : sortedB kenpoTable = true`、`theorem Payroll.kouseiTable_sorted : sortedB kouseiTable = true`

- [ ] **Step 1: テストを書く**

`PayrollTest/Grade.lean`:

```lean
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
```

`PayrollTest.lean` に `import PayrollTest.Grade` を追加する。

- [ ] **Step 2: 演習を書く**

`Payroll/Grade.lean`。`kenpoRows` と `kouseiRows` には Task 4 で確定した値を書く（以下は下書きの値）。表のデータは演習の対象にしない。

```lean
import Payroll.Money

namespace Payroll

/-- 等級表の 1 行。報酬月額が `lower` 以上なら、少なくともこの等級になる。 -/
structure GradeRow where
  grade : Nat
  std   : Yen   -- 標準報酬月額
  lower : Yen   -- 報酬月額の下限
  deriving Repr

/-- (等級, 標準報酬月額, 報酬月額の下限) の組から表を作る。 -/
def mkTable (rows : List (Nat × Yen × Yen)) : List GradeRow :=
  rows.map fun (g, s, l) => { grade := g, std := s, lower := l }

/-- `lower ≤ pay` を満たす行の `std` の最大値。該当する行がなければ 0。
    表が昇順なら「該当する最後の行の std」と一致する。
    ヒント: リストの先頭と残りでパターンマッチし、再帰で書く。`max` が使える。 -/
def lookupStd : List GradeRow → Yen → Yen
  | _, _ => sorry

/-- 報酬月額が増えても標準報酬月額は減らない。昇順でない表でも成り立つ。
    ヒント: `induction t` で表について帰納法を使う。`cons` の場合は
    `simp only [lookupStd, Nat.max_def]` で展開し、`repeat' split` で場合を分け、`omega` で閉じる。 -/
theorem lookupStd_mono (t : List GradeRow) {p₁ p₂ : Yen} (h : p₁ ≤ p₂) :
    lookupStd t p₁ ≤ lookupStd t p₂ := by
  sorry

/-- 隣り合う行で `lower` と `std` がどちらも真に増えていれば `true`。
    ヒント: 先頭 2 行 `a :: b :: rest` を取り出すパターンを使う。 -/
def sortedB : List GradeRow → Bool
  | _ => sorry

def kenpoRows : List (Nat × Yen × Yen) := [
  (1, 58000, 0), (2, 68000, 63000), (3, 78000, 73000), (4, 88000, 83000),
  (5, 98000, 93000), (6, 104000, 101000), (7, 110000, 107000), (8, 118000, 114000),
  (9, 126000, 122000), (10, 134000, 130000), (11, 142000, 138000), (12, 150000, 146000),
  (13, 160000, 155000), (14, 170000, 165000), (15, 180000, 175000), (16, 190000, 185000),
  (17, 200000, 195000), (18, 220000, 210000), (19, 240000, 230000), (20, 260000, 250000),
  (21, 280000, 270000), (22, 300000, 290000), (23, 320000, 310000), (24, 340000, 330000),
  (25, 360000, 350000), (26, 380000, 370000), (27, 410000, 395000), (28, 440000, 425000),
  (29, 470000, 455000), (30, 500000, 485000), (31, 530000, 515000), (32, 560000, 545000),
  (33, 590000, 575000), (34, 620000, 605000), (35, 650000, 635000), (36, 680000, 665000),
  (37, 710000, 695000), (38, 750000, 730000), (39, 790000, 770000), (40, 830000, 810000),
  (41, 880000, 855000), (42, 930000, 905000), (43, 980000, 955000), (44, 1030000, 1005000),
  (45, 1090000, 1055000), (46, 1150000, 1115000), (47, 1210000, 1175000),
  (48, 1270000, 1235000), (49, 1330000, 1295000), (50, 1390000, 1355000)
]

def kouseiRows : List (Nat × Yen × Yen) := [
  (1, 88000, 0), (2, 98000, 93000), (3, 104000, 101000), (4, 110000, 107000),
  (5, 118000, 114000), (6, 126000, 122000), (7, 134000, 130000), (8, 142000, 138000),
  (9, 150000, 146000), (10, 160000, 155000), (11, 170000, 165000), (12, 180000, 175000),
  (13, 190000, 185000), (14, 200000, 195000), (15, 220000, 210000), (16, 240000, 230000),
  (17, 260000, 250000), (18, 280000, 270000), (19, 300000, 290000), (20, 320000, 310000),
  (21, 340000, 330000), (22, 360000, 350000), (23, 380000, 370000), (24, 410000, 395000),
  (25, 440000, 425000), (26, 470000, 455000), (27, 500000, 485000), (28, 530000, 515000),
  (29, 560000, 545000), (30, 590000, 575000), (31, 620000, 605000), (32, 650000, 635000)
]

/-- 健康保険（協会けんぽ）の等級表。出典は docs/sources.md。 -/
def kenpoTable : List GradeRow := mkTable kenpoRows

/-- 厚生年金の等級表。出典は docs/sources.md。 -/
def kouseiTable : List GradeRow := mkTable kouseiRows

/-- ヒント: 具体的な有限の表なので、Lean に全部計算させればよい。 -/
theorem kenpoTable_sorted : sortedB kenpoTable = true := by
  sorry

theorem kouseiTable_sorted : sortedB kouseiTable = true := by
  sorry

end Payroll
```

`Payroll.lean` に `import Payroll.Grade` を追加する。

- [ ] **Step 3: 演習の状態を確かめる**

Run: `lake build Payroll`
Expected: 成功する（`sorry` の警告あり）。

Run: `lake build PayrollTest`
Expected: 失敗する。

- [ ] **Step 4: 模範解答を書く**

`Solutions/Grade.lean` は、`Payroll/Grade.lean` の `sorry` の部分を次のように置き換えたもの（`GradeRow`、`mkTable`、`kenpoRows`、`kouseiRows`、`kenpoTable`、`kouseiTable` は同じ内容をそのまま写す）。

```lean
def lookupStd : List GradeRow → Yen → Yen
  | [], _ => 0
  | row :: rest, pay =>
    if row.lower ≤ pay then max row.std (lookupStd rest pay)
    else lookupStd rest pay

theorem lookupStd_mono (t : List GradeRow) {p₁ p₂ : Yen} (h : p₁ ≤ p₂) :
    lookupStd t p₁ ≤ lookupStd t p₂ := by
  induction t with
  | nil => simp [lookupStd]
  | cons row rest ih =>
    simp only [lookupStd, Nat.max_def]
    repeat' split
    all_goals omega

def sortedB : List GradeRow → Bool
  | a :: b :: rest => a.lower < b.lower && a.std < b.std && sortedB (b :: rest)
  | _ => true

theorem kenpoTable_sorted : sortedB kenpoTable = true := by
  decide

theorem kouseiTable_sorted : sortedB kouseiTable = true := by
  decide
```

`decide` が再帰の深さの上限で失敗する場合は、`set_option maxRecDepth 4000 in` を定理の前に付ける。

- [ ] **Step 5: 模範解答を検証する**

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: OK`

- [ ] **Step 6: 解説を書く**

`docs/03-grade.md`:

```markdown
# 章 3: 等級表

## 題材

保険料は実際の給与ではなく、等級表で区切った「標準報酬月額」に料率を掛けて決まる。
健康保険は 50 等級（58,000 円〜1,390,000 円）、厚生年金は 32 等級（88,000 円〜650,000 円）。
報酬月額が表の上限を超えても、標準報酬月額は最上位の等級のままである。数値の出典は `docs/sources.md`。

## 学ぶこと

- `List` とパターンマッチ（`[]` と `row :: rest`）
- 構造的再帰による関数定義
- `induction` による帰納法の証明
- `decide`: 有限で具体的な命題を Lean に計算させて証明する

## 演習

`Payroll/Grade.lean` の `sorry` を埋める。

1. `lookupStd`: 条件を満たす行の `std` の最大値を、再帰で求める。
   「最後に該当した行」ではなく「最大値」で定義すると、次の証明が簡単になる。
   表が昇順なら 2 つの定義は一致する。
2. `lookupStd_mono`: 報酬月額は上限なく大きくなりうるので、`decide` で全部の値を調べることはできない。
   表の長さについての帰納法で示す。
3. `sortedB` と `kenpoTable_sorted` / `kouseiTable_sorted`: 具体的な表が昇順であることは、
   データの入力ミスの検査になる。表は有限なので `decide` で示せる。

`lake build PayrollTest` が通れば完了。
```

- [ ] **Step 7: コミットする**

```bash
git add Payroll.lean PayrollTest.lean Payroll/Grade.lean PayrollTest/Grade.lean Solutions/Grade.lean docs/03-grade.md
git commit -F - <<'EOF'
feat: 章 3 等級表の演習を追加

保険料は実際の給与ではなく標準報酬月額から決まるため、等級表の参照を用意した。
参照を最大値で定義して、単調性を表の並びに依存せず示せるようにし、
並びの正しさは具体的な表のデータ検査として decide で確かめる。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: 章 4 月額控除の合成

**Files:**
- Create: `PayrollTest/Premium.lean`, `Payroll/Premium.lean`, `Solutions/Premium.lean`, `docs/04-premium.md`
- Modify: `Payroll.lean`, `PayrollTest.lean`

**Interfaces:**
- Consumes: `Payroll.Rate`、`Payroll.employeeShare`（Task 3）、`Payroll.lookupStd`、`Payroll.kenpoTable`、`Payroll.kouseiTable`（Task 5）、Task 4 で確定した料率と照合用の行
- Produces:
  - `def Payroll.kenpoRate : Rate`、`def Payroll.kouseiRate : Rate`
  - `def Payroll.kenpoShare (pay : Yen) : Yen`、`def Payroll.kouseiShare (pay : Yen) : Yen`
  - `def Payroll.monthlyDeduction (pay : Yen) : Yen`

- [ ] **Step 1: テストを書く**

`PayrollTest/Premium.lean`。期待値は Task 4 で書き写した公表資料の値にする（以下は下書きの値から計算したもの）。

```lean
import Payroll.Premium

open Payroll

-- 公表資料（docs/sources.md）の保険料額表との照合
-- 健康保険（東京都 9.85%）の折半額
#guard kenpoShare 60000 == 2856       -- 標準報酬 58,000 円: 2,856.5 → 2,856
#guard kenpoShare 300000 == 14775     -- 標準報酬 300,000 円
#guard kenpoShare 2000000 == 68457    -- 標準報酬 1,390,000 円: 68,457.5 → 68,457
-- 厚生年金（18.3%）の折半額
#guard kouseiShare 50000 == 8052      -- 標準報酬 88,000 円
#guard kouseiShare 300000 == 27450    -- 標準報酬 300,000 円
#guard kouseiShare 2000000 == 59475   -- 標準報酬 650,000 円
-- 月額控除 = 健康保険 + 厚生年金
#guard monthlyDeduction 300000 == 42225
#guard monthlyDeduction 2000000 == 68457 + 59475
```

`PayrollTest.lean` に `import PayrollTest.Premium` を追加する。

- [ ] **Step 2: 演習を書く**

`Payroll/Premium.lean`:

```lean
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
```

`Payroll.lean` に `import Payroll.Premium` を追加する。

- [ ] **Step 3: 演習の状態を確かめる**

Run: `lake build Payroll`
Expected: 成功する（`sorry` の警告あり）。

Run: `lake build PayrollTest`
Expected: 失敗する。

- [ ] **Step 4: 模範解答を書く**

`Solutions/Premium.lean` は、`Payroll/Premium.lean` の 3 つの `sorry` を次のように置き換えたもの（料率の定義は同じ内容をそのまま写す）。

```lean
def kenpoShare (pay : Yen) : Yen :=
  employeeShare (lookupStd kenpoTable pay) kenpoRate

def kouseiShare (pay : Yen) : Yen :=
  employeeShare (lookupStd kouseiTable pay) kouseiRate

def monthlyDeduction (pay : Yen) : Yen :=
  kenpoShare pay + kouseiShare pay
```

- [ ] **Step 5: 模範解答を検証する**

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: OK`

失敗した場合、照合用の行と計算が合わない原因は、等級表のデータ、料率、端数処理のどれかにある。公表資料と見比べて特定し、ほかのテストの期待値を書き換えて辻褄を合わせることはしない。

- [ ] **Step 6: 解説を書く**

`docs/04-premium.md`:

```markdown
# 章 4: 月額控除の合成

## 題材

毎月の給与から控除する社会保険料は、健康保険料と厚生年金保険料の本人負担額の合計である。
どちらも「報酬月額 → 等級表で標準報酬月額 → 料率を掛けて折半 → 端数処理」の順に計算する。

この教材のモデルには、次のものを含めていない。

- 介護保険料（40〜64 歳）
- 子ども・子育て支援金（令和 8 年 4 月分から。健康保険料と合わせて徴収される）
- 賞与にかかる保険料

## 学ぶこと

- 章 1〜3 で作った関数を組み合わせる
- 公表資料の値をテストの期待値にして、モデルと現実を突き合わせる

## 演習

`Payroll/Premium.lean` の `sorry` を埋める。`lake build PayrollTest` が通れば、
この教材の演習はすべて完了。

## 発展

- 介護保険料を加える（年齢の判定が必要になる）
- 子ども・子育て支援金を加える
- 「報酬月額が増えても月額控除は減らない」を証明する（章 1 の `roundHalfDown_mono` と章 3 の `lookupStd_mono` を組み合わせる）
```

- [ ] **Step 7: 全体を確かめる**

Run: `lake build Payroll`
Expected: 成功する（`sorry` の警告あり）。

Run: `scripts/check-solutions.sh`
Expected: `check-solutions: OK`

Run: `git status --short`
Expected: 未追跡の生成物（`.lake/` など）が出ていない。

- [ ] **Step 8: コミットする**

```bash
git add Payroll.lean PayrollTest.lean Payroll/Premium.lean PayrollTest/Premium.lean Solutions/Premium.lean docs/04-premium.md
git commit -F - <<'EOF'
feat: 章 4 月額控除の演習を追加

章 1〜3 の部品を組み合わせて毎月の控除額を求め、公表されている保険料額表の値と照合する。
モデルが現実の表と一致することを、テストで確かめられるようにするため。

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```
