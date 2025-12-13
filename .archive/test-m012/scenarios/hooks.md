# Hook Test Scenarios

> **29個の Hook テストシナリオ（発火タイミング別 MECE 分類）**

---

## SessionStart（セッション開始時）

### Hook: session-start

**Trigger:** セッション開始（startup/resume/clear/compact）
**Expected:** state.md の last_start 更新、CORE/必須Read 指示出力
**Verify:** `grep 'last_start' state.md` で日時が更新されていること

### Hook: core-component-check

**Trigger:** SessionStart 時に session-start.sh の後に実行
**Expected:** .claude/core-components.yaml の Core 14個の存在確認
**Verify:** 欠損コンポーネントがある場合は警告が出力されること

---

## UserPromptSubmit（ユーザープロンプト送信時）

### Hook: prompt-guard

**Trigger:** ユーザーがプロンプトを送信
**Expected:** State Injection（systemMessage に状態注入）、user-intent.md に保存
**Verify:** systemMessage に focus/milestone/phase が含まれること

---

## PreToolUse（ツール実行前）

### 全ツール共通（matcher: "*"）

### Hook: init-guard

**Trigger:** 任意のツール実行前
**Expected:** 必須ファイル（state.md, playbook）が Read されるまでブロック
**Verify:** Read 未完了で他ツール実行時に exit 2 でブロック

### Hook: check-main-branch

**Trigger:** 任意のツール実行前
**Expected:** main ブランチでの作業をブロック
**Verify:** `git branch` が main の場合に exit 2

---

### Edit 専用（matcher: "Edit"）

### Hook: consent-guard

**Trigger:** Edit ツール実行前
**Expected:** [理解確認] 完了まで Edit をブロック
**Verify:** .claude/consent/pending.md が存在する場合に exit 2

### Hook: check-protected-edit

**Trigger:** Edit ツール実行前
**Expected:** 保護ファイル（HARD_BLOCK/BLOCK/WARN）の編集を制御
**Verify:** HARD_BLOCK ファイル編集時に exit 2

### Hook: playbook-guard

**Trigger:** Edit ツール実行前
**Expected:** playbook=null で Edit をブロック
**Verify:** state.md の playbook.active が null の場合に exit 2

### Hook: critic-guard

**Trigger:** Edit ツール実行前（state: done への変更時）
**Expected:** critic PASS なしで done 変更をブロック
**Verify:** self_complete: false で status: done 変更時に警告

### Hook: scope-guard

**Trigger:** Edit ツール実行前
**Expected:** done_when/done_criteria の無断変更を検出・警告
**Verify:** playbook の done_when 変更時に警告出力

### Hook: executor-guard

**Trigger:** Edit ツール実行前
**Expected:** executor: codex/coderabbit/user の Phase で Claude の直接編集をブロック
**Verify:** executor が claudecode 以外の場合に exit 2

---

### Write 専用（matcher: "Write"）

### Hook: consent-guard (Write)

**Trigger:** Write ツール実行前
**Expected:** [理解確認] 完了まで Write をブロック
**Verify:** .claude/consent/pending.md が存在する場合に exit 2

### Hook: check-protected-edit (Write)

**Trigger:** Write ツール実行前
**Expected:** 保護ファイルへの書き込みを制御
**Verify:** HARD_BLOCK ファイル書き込み時に exit 2

### Hook: playbook-guard (Write)

**Trigger:** Write ツール実行前
**Expected:** playbook=null で Write をブロック
**Verify:** state.md の playbook.active が null の場合に exit 2

### Hook: critic-guard (Write)

**Trigger:** Write ツール実行前（state: done への変更時）
**Expected:** critic PASS なしで done 変更をブロック
**Verify:** self_complete: false で status: done 変更時に警告

### Hook: scope-guard (Write)

**Trigger:** Write ツール実行前
**Expected:** done_when/done_criteria の無断変更を検出・警告
**Verify:** playbook の done_when 変更時に警告出力

### Hook: executor-guard (Write)

**Trigger:** Write ツール実行前
**Expected:** executor: codex/coderabbit/user の Phase で Claude の直接編集をブロック
**Verify:** executor が claudecode 以外の場合に exit 2

---

### Bash 専用（matcher: "Bash"）

### Hook: pre-bash-check

**Trigger:** Bash ツール実行前
**Expected:** HARD_BLOCK ファイルへの書き込み検出、git commit 前の回帰テスト実行
**Verify:** `echo > CLAUDE.md` 実行時にブロック

### Hook: check-coherence

**Trigger:** Bash ツール実行前（git commit 時）
**Expected:** state-playbook-branch の整合性チェック
**Verify:** state.md と playbook の不整合時に警告

### Hook: lint-check

**Trigger:** Bash ツール実行前（git commit 時）
**Expected:** ESLint/ShellCheck/Ruff を実行
**Verify:** lint エラーがある場合に警告出力

---

## PostToolUse（ツール実行後）

### Hook: log-subagent

**Trigger:** Task ツール実行後
**Expected:** SubAgent 発動をログに記録、critic PASS/FAIL を検出・処理
**Verify:** .claude/logs/subagent.log に記録されること

### Hook: archive-playbook

**Trigger:** Edit ツール実行後
**Expected:** playbook の全 Phase が done ならアーカイブを提案
**Verify:** 全 Phase done で「アーカイブ提案」が出力

### Hook: create-pr-hook

**Trigger:** Edit ツール実行後
**Expected:** PR 作成条件を検出
**Verify:** PR 作成可能な状態で案内出力

### Hook: update-tracker

**Trigger:** Edit/Write ツール実行後
**Expected:** 変更を追跡し、current-implementation.md の自動更新を促す
**Verify:** ファイル変更後に systemMessage に更新案内

---

## SessionEnd（セッション終了時）

### Hook: session-end

**Trigger:** セッション終了
**Expected:** state.md の last_end 更新、四つ組整合性チェック、セッションサマリー生成
**Verify:** `grep 'last_end' state.md` で日時が更新されていること

---

## Stop（エージェント停止時）

### Hook: stop-summary

**Trigger:** エージェント停止
**Expected:** Phase 状態サマリー出力、ユーザー意図との整合性チェック
**Verify:** 停止時にサマリーが出力されること

---

## PreCompact（コンパクト前）

### Hook: pre-compact

**Trigger:** auto-compact / /compact 実行前
**Expected:** snapshot.json に状態保存、additionalContext で重要情報を伝達
**Verify:** .claude/snapshot.json が更新されること

---

## ユーティリティ（直接発火しない）

### Hook: failure-logger

**Trigger:** 他 Hook からの呼び出し
**Expected:** 失敗パターンを JSONL 形式で記録
**Verify:** .claude/logs/failures.log に記録されること

### Hook: generate-implementation-doc

**Trigger:** 他 Hook からの呼び出し
**Expected:** current-implementation.md を自動生成
**Verify:** docs/current-implementation.md が更新されること

### Hook: system-health-check

**Trigger:** session-start.sh からの呼び出し
**Expected:** システム健全性チェック
**Verify:** 健全性チェック結果が出力されること

### Hook: create-pr

**Trigger:** 手動実行
**Expected:** PR 作成スクリプト実行
**Verify:** `gh pr create` が成功すること

### Hook: merge-pr

**Trigger:** 手動実行
**Expected:** PR マージスクリプト実行
**Verify:** `gh pr merge` が成功すること

### Hook: test-hooks

**Trigger:** 開発用手動実行
**Expected:** Hook のテスト実行
**Verify:** テスト結果が出力されること

### Hook: lib/common

**Trigger:** 他 Hook からの source
**Expected:** 共通関数・変数の提供
**Verify:** `source .claude/hooks/lib/common.sh` が成功すること
