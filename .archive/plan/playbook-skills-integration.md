# playbook-skills-integration.md

> **Skills と template/ が仕組みとして機能するよう、SubAgents 経由の呼び出しルートを確立する**
>
> **注記**: このタスク（p4）の設計に問題があったため、
> playbook-artifact-health に置き換え。p1-p3 は完了済み。

---

## meta

```yaml
project: skills-integration
branch: feat/skills-integration
created: 2025-12-09
issue: null
derives_from: null  # 独立タスク（コンテキスト参照の構造的欠陥修正）
status: archived  # p4 を artifact-health に代替
```

---

## goal

```yaml
summary: SubAgents → Skills の呼び出しルートを確立し、全ファイルが仕組みとしてアクセス可能な状態にする

done_when:
  - critic SubAgent が lint-checker/test-runner を呼び出すルートが確立
  - pm SubAgent が plan/template/playbook-format.md を必須 Read
  - CLAUDE.md に「SubAgent → Skills」の連鎖が明記
  - コンテキスト0から検証し、全ファイルへのアクセス経路が存在
```

---

## phases

```yaml
- id: p1
  name: critic.md に Skills 呼び出しを追加
  goal: critic が done 判定時に lint-checker/test-runner を呼び出すルートを確立
  executor: claudecode
  done_criteria:
    - critic.md に「コード変更があれば lint-checker を呼び出す」手順が追加されている
    - critic.md に「テストファイル変更があれば test-runner を呼び出す」手順が追加されている
    - 呼び出しタイミングが明確に定義されている
  test_method: |
    1. critic.md を Read
    2. Skills 呼び出し手順が記載されていることを確認
  evidence:
    - critic.md:127-173 に Skills 連携セクション追加
    - lint-checker, test-runner, deploy-checker の呼び出しルール定義
  status: done

- id: p2
  name: pm.md に template 参照を必須化
  goal: pm が playbook 作成時に plan/template/playbook-format.md を必ず Read するルートを確立
  executor: claudecode
  depends_on: []
  done_criteria:
    - pm.md の playbook 作成手順に「Read: plan/template/playbook-format.md」が必須として追加されている
    - planning-rules.md への参照も追加されている
    - 手順が番号付きで明確に記載されている
  test_method: |
    1. pm.md を Read
    2. template 参照が必須として記載されていることを確認
  evidence:
    - pm.md:119-122 にステップ0「必須テンプレート参照」追加
    - pm.md:154-166 にテンプレート必須参照の理由セクション追加
  status: done

- id: p3
  name: CLAUDE.md に連鎖ルートを明記
  goal: 「Hooks → SubAgents → Skills」の連鎖を CLAUDE.md に明記
  executor: claudecode
  depends_on: [p1, p2]
  done_criteria:
    - CLAUDE.md に SKILLS_CHAIN セクションが追加されている
    - 連鎖ルート（どの SubAgent がどの Skill を呼ぶか）が明記されている
    - template/ への参照ルートが明記されている
  test_method: |
    1. CLAUDE.md を Read
    2. SKILLS_CHAIN セクションが存在することを確認
  evidence:
    - CLAUDE.md:409-506 に SKILLS_CHAIN セクション追加
    - 連鎖構造図、SubAgent → Skills 呼び出しルール、全ファイルアクセス経路を定義
  status: done

- id: p4
  name: コンテキスト0から検証
  goal: /clear 後、全ファイルへのアクセス経路が存在することを確認
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - /clear 実行後、INIT で必要なファイルが全て参照される
    - Skills への呼び出しルートが SubAgents 経由で確立されている
    - template/ への参照ルートが pm 経由で確立されている
    - 「仕組みとして参照されないファイル」が存在しない（アーカイブ系を除く）
  test_method: |
    1. /clear を実行
    2. INIT を実行
    3. 各ファイルカテゴリへのアクセス経路を確認
    4. 経路がないファイルをリストアップ
  status: cancelled  # playbook-artifact-health に統合・置換
  notes: |
    問題点:
      1. done_criteria 4「仕組みとして参照されないファイルが存在しない」が曖昧
      2. 対処療法でアーカイブに移動させようとしていた（根本改善なし）
      3. 根本原因「なぜアーカイブされないのか」が不明

    解決策:
      playbook-artifact-health.md が完全な分析と改善を実施:
        - p1: 完了済み playbook の未アーカイブ原因分析
        - p2: phase-*.md 作成目的の明確化
        - p3-p4: アーカイブ/ファイル作成プロセス改善
        - p5-p8: 健全化実行
        - p9-p10: 検証と再発防止ルール化
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | playbook-artifact-health に置換。p4 の根本設計を再考。p1-p3 は成果物（CLAUDE.md SKILLS_CHAIN セクション）として保持。 |
| 2025-12-09 | 初版作成。Skills 統合タスク。 |
