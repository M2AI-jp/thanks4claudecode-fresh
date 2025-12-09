# playbook-plan-optimization.md

> **plan フォルダの最適化 - 構造の一貫性と説明の充実**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/full-autonomy-implementation
created: 2025-12-10
issue: null
derives_from: milestones  # project.md の未達成マイルストーンから導出
reviewed: false
```

---

## goal

```yaml
summary: plan フォルダの構造を最適化し、説明を充実させる
done_when:
  - README.md が現在の構造（active/ フォルダ使用）を正確に反映
  - template/ に CLAUDE.md が追加され、各テンプレートの役割が明確
  - design/ に README.md が追加され、設計ドキュメントの役割が明確
  - 全ファイルが一貫した構造で整理されている
```

---

## phases

```yaml
- id: p0
  name: README.md 更新
  goal: plan/README.md を現在の構造に合わせて更新
  executor: claudecode
  done_criteria:
    - active/ フォルダの使用が明記されている
    - playbook のライフサイクル（active → archive）が説明されている
    - 構造図が最新の状態を反映している
  test_method: |
    1. README.md を読んで構造図を確認
    2. 実際のフォルダ構造と比較
    3. 不整合がないことを確認
  status: done

- id: p1
  name: template/CLAUDE.md 追加
  goal: template フォルダに CLAUDE.md を追加し、各テンプレートの役割を説明
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - template/CLAUDE.md が存在する
    - 各テンプレートファイルの役割が説明されている
    - 使用タイミングが明記されている
  test_method: |
    1. cat plan/template/CLAUDE.md
    2. 全テンプレートが説明されていることを確認
  status: done

- id: p2
  name: design/README.md 追加
  goal: design フォルダに README.md を追加し、設計ドキュメントの役割を説明
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - design/README.md が存在する
    - 各設計ドキュメントの役割が説明されている
    - 参照タイミングが明記されている
  test_method: |
    1. cat plan/design/README.md
    2. 全設計ドキュメントが説明されていることを確認
  status: done

- id: p3
  name: critic 検証 & コミット
  goal: 全変更を検証してコミット
  executor: claudecode
  depends_on: [p0, p1, p2]
  done_criteria:
    - critic SubAgent で done_criteria を検証
    - 全項目が PASS
    - git commit が成功
  test_method: |
    1. Task(subagent_type="critic") で検証
    2. git add -A && git commit
    3. git log -1 で確認
  status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。plan フォルダの最適化。 |
