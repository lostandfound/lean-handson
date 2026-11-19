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
