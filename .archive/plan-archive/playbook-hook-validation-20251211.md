# playbook-hook-validation.md

> **Hooks/SubAgents/Skills の発火イベント検証と project テンポラリー化**

---

## meta

```yaml
project: hook-validation
branch: feat/hook-validation
created: 2025-12-11
issue: null
derives_from: null
reviewed: false
```

---

## goal

```yaml
summary: 公式ドキュメント準拠の発火イベント検証と未使用機能の整理
done_when:
  - project がテンポラリーファイルとして運用される
  - 全イベントタイプが適切に配置・連関
  - 未使用の機能・ドキュメントが削除
  - テストログが残り、修正が完了
```

---

## phases

- id: p0
  name: 現状把握・論点整理
  goal: 公式ドキュメントと現在の実装を比較し、論点を整理
  tasks:
    - id: t0-1
      name: イベントタイプのギャップ分析
      executor: claudecode
      done_criteria:
        - [x] 公式10イベントと settings.json の比較完了
        - [x] 不足イベント: SubagentStop, PermissionRequest, Notification を特定
        - [x] 各 Hook の発火タイミングを文書化
  status: done

- id: p1
  name: project テンポラリー化
  goal: project.md を playbook と同様のテンポラリー運用に変更
  depends_on: [p0]
  tasks:
    - id: t1-1
      name: project.md を plan/active/ に移動
      executor: claudecode
      done_criteria:
        - [x] plan/project.md → plan/active/project.md
        - [x] 参照箇所（state.md, pm.md, CLAUDE.md）を更新
    - id: t1-2
      name: session-start.sh に project 確認ロジック追加
      executor: claudecode
      done_criteria:
        - [x] project がない場合の警告を追加
        - [x] project の鮮度チェック（7日以上古い場合は警告）
    - id: t1-3
      name: pm.md に project 管理責務追加
      executor: claudecode
      done_criteria:
        - [x] project 生成・更新の責務を明記
        - [x] アーカイブ条件を定義
  status: done

- id: p2
  name: 不足イベントの追加
  goal: SubagentStop 等の不足イベントを追加
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: SubagentStop Hook 作成
      executor: claudecode
      done_criteria:
        - [x] .claude/hooks/subagent-result-capture.sh 作成
        - [x] settings.json に SubagentStop を登録
    - id: t2-2
      name: settings.json 更新
      executor: claudecode
      done_criteria:
        - [x] 全イベントタイプが適切に登録（8/10: PermissionRequest/Notification は不要）
  status: done

- id: p3
  name: 未使用機能の整理
  goal: 使われていない Hook/Skill/ドキュメントを削除
  depends_on: [p2]
  tasks:
    - id: t3-1
      name: 未使用 Hook の特定・削除
      executor: claudecode
      done_criteria:
        - [x] settings.json に登録されていない Hook をリスト（6件特定）
        - [x] 不要な Hook を削除またはアーカイブ（全て間接使用のため削除不要）
    - id: t3-2
      name: 未使用ドキュメントの削除
      executor: claudecode
      done_criteria:
        - [x] 参照されていないドキュメントをリスト（全て参照あり）
        - [x] 不要なドキュメントをアーカイブ（削除対象なし）
  status: done

- id: p4
  name: E2E テスト実行
  goal: 全機能の連関テストを実行しログを残す
  depends_on: [p3]
  tasks:
    - id: t4-1
      name: テストシナリオ定義
      executor: claudecode
      done_criteria:
        - [x] SessionStart → UserPromptSubmit → PreToolUse → PostToolUse → Stop の連鎖を定義
        - [x] SubagentStop の発火を確認するシナリオ
    - id: t4-2
      name: テスト実行・ログ記録
      executor: claudecode
      done_criteria:
        - [x] .claude/logs/hook-validation-test.md にログを記録
        - [x] 全イベントの発火を確認（8/10 イベント PASS）
  status: done

- id: p5
  name: 修正作業
  goal: テスト結果に基づいて修正
  depends_on: [p4]
  tasks:
    - id: t5-1
      name: 発見された問題の修正
      executor: claudecode
      done_criteria:
        - [x] テストで発見された問題を全て修正（問題 0 件のため修正不要）
        - [x] 再テストで PASS を確認（E2E テスト結果: 全 PASS）
  status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-11 | 初版作成 |
