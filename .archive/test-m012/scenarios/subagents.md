# SubAgent Test Scenarios

> **10種類の SubAgent テストシナリオ（責務別 MECE 分類）**

---

## 計画系

### SubAgent: pm

**Trigger:** playbook=null でセッション開始、新規タスク開始時
**Expected:**
- project.md を参照して milestone を特定
- playbook を作成（derives_from を設定）
- state.md を更新
- ブランチを作成

**Verify:**
```bash
# playbook が作成されたことを確認
test -f plan/active/playbook-*.md && echo PASS || echo FAIL

# derives_from が設定されていることを確認
grep -q 'derives_from:' plan/active/playbook-*.md && echo PASS || echo FAIL
```

### SubAgent: plan-guard

**Trigger:** セッション開始時、計画変更時
**Expected:**
- 3層計画（project → playbook → phase）の整合性チェック
- 不整合がある場合は警告

**Verify:**
```bash
# state.md と playbook の整合性を確認
grep 'phase:' state.md && grep 'status:' plan/active/playbook-*.md
```

---

## 検証系

### SubAgent: critic

**Trigger:** Phase 完了判定前（必須）
**Expected:**
- done_criteria を証拠ベースで検証
- PASS/FAIL を判定
- self_complete: true/false を設定

**Verify:**
```bash
# critic 出力に [CRITIQUE] が含まれることを確認
# PASS または FAIL が明示されていることを確認
```

### SubAgent: reviewer

**Trigger:** コード/設計レビュー時
**Expected:**
- コード品質レビュー
- 設計レビュー
- 改善提案の生成

**Verify:**
```bash
# reviewer 出力に [REVIEW] が含まれることを確認
# Approved/Needs Changes/Rejected が明示されていることを確認
```

---

## 支援系

### SubAgent: Explore

**Trigger:** コードベース探索、ファイル検索時
**Expected:**
- 高速なファイル検索
- パターンマッチング
- コードベース構造の把握

**Verify:**
```bash
# 検索結果が返されることを確認
# ファイルパスが正しいことを確認
```

### SubAgent: setup-guide

**Trigger:** focus=setup 時
**Expected:**
- セットアップ手順のガイド
- 環境構築の支援
- Skills 生成

**Verify:**
```bash
# setup フローが正常に動作することを確認
```

### SubAgent: health-checker

**Trigger:** 定期チェック時
**Expected:**
- システム状態の監視
- state.md/playbook の整合性確認
- git 状態確認

**Verify:**
```bash
# 健全性チェック結果が出力されることを確認
```

### SubAgent: claude-code-guide

**Trigger:** Claude Code の使い方を質問した時
**Expected:**
- Claude Code/Agent SDK のドキュメント参照
- 使い方の説明

**Verify:**
```bash
# ドキュメントに基づいた回答が返されることを確認
```

---

## 外部連携系（新規）

### SubAgent: codex

**Trigger:** 複雑なコード実装が必要なとき、テストシナリオの自動実行時
**Expected:**
- `codex exec` で非インタラクティブ実行
- プロンプトを送信して結果を取得
- JSON 形式で出力

**Verify:**
```bash
# Codex CLI が動作することを確認
codex --version 2>&1 | grep -q '0.71' && echo PASS || echo FAIL

# exec が動作することを確認
codex exec 'echo PASS' --json 2>&1 | grep -q 'PASS' && echo PASS || echo FAIL
```

### SubAgent: coderabbit

**Trigger:** コードレビューが必要なとき、PR 作成前
**Expected:**
- `coderabbit review` でコードレビュー実行
- 品質チェック結果を取得
- 改善提案の生成

**Verify:**
```bash
# CodeRabbit CLI が動作することを確認
coderabbit --help 2>&1 | grep -q 'review' && echo PASS || echo FAIL
```

---

## SubAgent 呼び出しフロー検証

### シナリオ: 新規タスク開始から Phase 完了まで

```
1. ユーザーがタスクを指示
   → pm が呼び出される
   → playbook が作成される

2. Phase 実行
   → claudecode が subtask を実行

3. Phase 完了判定
   → critic が呼び出される
   → PASS/FAIL を判定

4. 全 Phase 完了
   → POST_LOOP 実行
   → playbook アーカイブ
```

**Verify:**
```bash
# 各 SubAgent のログを確認
cat .claude/logs/subagent.log | grep -E 'pm|critic'
```
