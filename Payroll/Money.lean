namespace Payroll

/-- 金額（円）。保険料も報酬も負にならないので Nat で表す。
    abbrev ではなく notation にしている。abbrev だと omega が Yen を Nat と認識せず、証明が通らない。 -/
notation "Yen" => Nat

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
