# Test Count Clarification

> playbook-orchestration-completeness-100 の証跡と現在のテスト数の差分を説明

---

## Summary

| 時点 | テスト数 | 備考 |
|------|----------|------|
| playbook-orchestration-completeness-100 作成時 | 8 tests | 正常ケースのみ |
| playbook-fix-empty-input-test 完了後 | 11 tests | エラーケース 3 件追加 |

---

## 経緯

1. **2026-01-02 (playbook-orchestration-completeness-100)**
   - `tests/tmp-run.bats` を新規作成
   - 正常ケース 8 件のテストを実装
   - 証跡: "8 tests, 0 failures"

2. **2026-01-02 (playbook-fix-empty-input-test)**
   - エラーハンドリングのテストを追加
   - 追加されたテスト:
     - `run.sh with empty input fails gracefully`
     - `run.sh with invalid JSON fails gracefully`
     - `run.sh with missing input field fails gracefully`
   - 現在: 11 tests

---

## 結論

playbook-orchestration-completeness-100 の証跡「8 tests」は**作成時点では正確**だった。
その後の playbook で 3 件追加され、現在は 11 tests が正しい。

証跡は過去の記録として保持し、この補足ログで経緯を明確化する。
