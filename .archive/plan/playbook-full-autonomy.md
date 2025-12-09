# playbook-full-autonomy.md

> **mission.md の success_criteria を全て達成する包括的 playbook**
>
> Claude Code の全機能を100%活用し、自律性を実証する。

---

## meta

```yaml
project: full-autonomy
branch: feat/full-autonomy-implementation
created: 2025-12-10
issue: null
derives_from: d_autonomy, d_purpose_consistency
reviewed: false
```

---

## goal

```yaml
summary: mission.md の success_criteria を全て達成し、自律性を実証する
done_when:
  - mission.md の success_criteria が全てチェック済み
  - ユーザープロンプトなしで全 Phase を完遂
  - critic PASS で完了
```

---

## phases

```yaml
# ============================================================
# Phase 0: 基盤整備（現状の問題修正）
# ============================================================
- id: p0
  name: 基盤整備
  goal: health-checker/coherence で検出された問題を修正
  executor: claudecode
  done_criteria:
    - state.md に active_playbooks セクションが存在する
    - check-coherence.sh が focus="product" に対応
    - git status で未コミット変更が整理されている
  test_method: |
    1. grep "active_playbooks" state.md
    2. bash .claude/hooks/check-coherence.sh（エラーなし）
    3. git status --porcelain | wc -l（減少確認）
  status: done

# ============================================================
# Phase 1: 信頼性（SubAgent/Skill 呼び出し検証）
# ============================================================
- id: p1
  name: SubAgent/Skill 呼び出し検証
  goal: 全 SubAgent と Skill が呼び出し可能であることを検証
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - critic SubAgent が呼び出し可能
    - reviewer SubAgent が呼び出し可能
    - state Skill が呼び出し可能
    - plan-management Skill が呼び出し可能
    - learning Skill が呼び出し可能
    - 実際に呼び出して応答を確認済み
  test_method: |
    1. Task(subagent_type="critic") で応答確認
    2. Task(subagent_type="reviewer") で応答確認
    3. Skill: "state" で応答確認
    4. Skill: "plan-management" で応答確認
    5. Skill: "learning" で応答確認
  status: done

# ============================================================
# Phase 2: 信頼性（MCP サーバー検証）
# ============================================================
- id: p2
  name: MCP サーバー検証
  goal: context7, codex, ide MCP が動作することを検証
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - context7 の resolve-library-id が応答する
    - codex の ping が応答する
    - ide の getDiagnostics が応答する
    - 実際に呼び出して応答を確認済み
  test_method: |
    1. mcp__context7__resolve-library-id("typescript")
    2. mcp__codex__ping()
    3. mcp__ide__getDiagnostics()
  status: done

# ============================================================
# Phase 3: 自己認識（current-implementation.md 自動更新検証）
# ============================================================
- id: p3
  name: ドキュメント自動更新検証
  goal: generate-implementation-doc.sh が正常動作することを検証
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - generate-implementation-doc.sh が exit 0 で完了
    - current-implementation.md が更新される
    - 更新内容が実態と一致
  test_method: |
    1. bash .claude/hooks/generate-implementation-doc.sh
    2. diff current-implementation.md（変更確認）
    3. Hook 数、SubAgent 数が正確か目視確認
  status: done

# ============================================================
# Phase 4: 自己修復（失敗学習ループ検証）
# ============================================================
- id: p4
  name: 失敗学習ループ検証
  goal: failure-logger.sh と session-start.sh の学習ループが動作することを検証
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - failure-logger.sh が失敗を JSONL 形式で記録する
    - session-start.sh が繰り返し失敗を検出して警告する
    - 実際にテスト失敗を記録して検証済み
  test_method: |
    1. echo '{"hook":"test","context":"test","action":"test"}' | bash .claude/hooks/failure-logger.sh
    2. cat .claude/logs/failures.log（記録確認）
    3. bash .claude/hooks/session-start.sh（警告表示確認）
  status: done

# ============================================================
# Phase 5: 目的一貫性（mission 整合性チェック検証）
# ============================================================
- id: p5
  name: mission 整合性チェック検証
  goal: prompt-guard.sh の報酬詐欺検出が動作することを検証
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - prompt-guard.sh が「完了しました」パターンを検出
    - prompt-guard.sh が「忘れて」パターンを検出
    - systemMessage で警告が出力される
  test_method: |
    1. echo '{"prompt":"完了しました"}' | bash .claude/hooks/prompt-guard.sh
    2. echo '{"prompt":"忘れて"}' | bash .claude/hooks/prompt-guard.sh
    3. 警告メッセージの内容確認
  status: done

# ============================================================
# Phase 6: 自律性（compact 後のコンテキスト継続検証）
# ============================================================
- id: p6
  name: compact コンテキスト継続検証
  goal: pre-compact.sh と session-start.sh compact 分岐が動作することを検証
  executor: claudecode
  depends_on: [p5]
  done_criteria:
    - pre-compact.sh が snapshot.json を生成する
    - session-start.sh が compact トリガーで snapshot を読む
    - additionalContext が出力される
  test_method: |
    1. bash .claude/hooks/pre-compact.sh
    2. cat .claude/.session-init/snapshot.json（存在確認）
    3. echo '{"trigger":"compact"}' | bash .claude/hooks/session-start.sh（復元確認）
  status: done

# ============================================================
# Phase 7: 統合検証（critic による全体評価）
# ============================================================
- id: p7
  name: critic 統合評価
  goal: mission.md の success_criteria を critic SubAgent で評価
  executor: claudecode
  depends_on: [p1, p2, p3, p4, p5, p6]
  done_criteria:
    - critic が全 success_criteria を評価
    - 全項目が PASS
    - 証拠が明示されている
  test_method: |
    1. Task(subagent_type="critic") で mission.md success_criteria を評価
    2. 全項目 PASS を確認
    3. 不足があれば修正して再評価
  status: pending

# ============================================================
# Phase 8: 最終コミット & mission.md 更新
# ============================================================
- id: p8
  name: 最終コミット
  goal: 全変更をコミットし、mission.md の success_criteria をチェック
  executor: claudecode
  depends_on: [p7]
  done_criteria:
    - git commit が成功
    - mission.md の success_criteria が全てチェック済み
    - state.md の playbook が archived に移動
  test_method: |
    1. git add -A && git commit
    2. mission.md を更新（チェックマーク付与）
    3. playbook を .archive/ に移動
  status: done
```

---

## 使用する Claude Code 機能

```yaml
# このplaybook で活用する全機能

Tools:
  - TodoWrite: 進捗管理
  - Task: SubAgent 呼び出し
  - Skill: Skills 呼び出し
  - Bash: コマンド実行
  - Read/Write/Edit: ファイル操作

SubAgents:
  - pm: playbook 作成（完了）
  - health-checker: システム診断（完了）
  - coherence: 整合性チェック（完了）
  - critic: done_criteria 評価（Phase 7）
  - reviewer: playbook レビュー（必要に応じて）
  - state-mgr: state.md 管理（必要に応じて）

Skills:
  - state: state.md 操作
  - plan-management: playbook 操作
  - learning: 失敗パターン学習

MCP:
  - context7: 外部ドキュメント参照
  - codex: コード生成支援
  - ide: IDE 連携

Hooks（自動発火）:
  - session-start.sh: セッション開始
  - prompt-guard.sh: プロンプト検証
  - init-guard.sh: 初期化ガード
  - playbook-guard.sh: playbook ガード
  - pre-compact.sh: compact 前処理
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。mission success_criteria 達成のための包括的 playbook。 |
