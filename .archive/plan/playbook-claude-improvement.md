# playbook-claude-improvement.md

> **CLAUDE.md 改善 - 機能している仕組みとの整合性**

---

## meta

```yaml
project: CLAUDE.md 改善
branch: feat/dw004-release-prep
created: 2025-12-09
issue: null
derives_from: null  # ユーザー要求による
```

---

## goal

```yaml
summary: current-implementation.md を鑑みて、機能している仕組みと CLAUDE.md の整合性を取り、改善案を実装する
done_when:
  - current-implementation.md から機能している仕組みを特定
  - CLAUDE.md の関連部分を確認
  - 改善案を考案し、実装する
```

---

## phases

```yaml
- id: p0
  name: 機能している仕組みの特定
  goal: current-implementation.md を読み、実際に機能している Hook/SubAgent/Skill を特定する
  executor: claudecode
  done_criteria:
    - current-implementation.md の Hooks セクションで「登録済み」のものをリスト化
    - SubAgents の動作実績を確認
    - 機能している/していないの判断根拠を明示
  test_method: |
    1. current-implementation.md を読む
    2. settings.json と照合して登録済み Hook を確認
    3. 機能リストを作成
  status: done
  evidence:
    - structural Hooks（init-guard, playbook-guard, check-protected-edit, check-main-branch）は機能
    - guideline ルール（critic 必須、[自認]）は機能していない
    - 問題の本質: ルールは LLM が無視すれば終わり
  max_iterations: 3

- id: p1
  name: CLAUDE.md との関連性確認
  goal: 機能している仕組みが CLAUDE.md のどの部分と関連しているか確認
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - 各機能仕組みと CLAUDE.md のセクションの対応表を作成
    - 機能しているのに CLAUDE.md に記載がない部分を特定
    - CLAUDE.md に記載があるが機能していない部分を特定
  test_method: |
    1. p0 で特定した機能リストを CLAUDE.md と照合
    2. 対応表を作成
  status: pending
  max_iterations: 3

- id: p2
  name: 改善案の考案
  goal: CLAUDE.md の冒頭を改善する案を考える
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - 優先参照ファイルと行動のセットを設計
    - 1行ルールの案を複数作成
    - ユーザーに提示して選択を求める
  test_method: |
    1. p1 の結果から改善点を抽出
    2. 改善案を複数作成
    3. ユーザーに提示
  status: pending
  max_iterations: 3

- id: p3
  name: 改善の実装
  goal: ユーザー選択に基づき CLAUDE.md を改善
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - CLAUDE.md の冒頭が改善されている
    - 機能している仕組みとの整合性が取れている
    - ユーザー承認
  test_method: |
    1. 改善を実装
    2. 整合性確認
    3. ユーザー確認
  status: pending
  max_iterations: 3
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成 |
