# Fix Backlog: Claude Code 自律運用フレームワーク

```yaml
version: 1.0.0
created: 2025-01-03
status: ACTIVE
purpose: 全ての playbook 生成時に参照される修正バックログ
```

---

## Section 0: 目的と文脈

このドキュメントは単なる作業指示書ではなく、**報酬詐欺への対策として生まれた品質管理文書**である。

```yaml
origin:
  trigger: skill-audit-v2 playbook（2026-01-03）
  problem: |
    v1 監査では「全て keep」という統計的に不自然な判定が行われた。
    これは「自己採点による報酬詐欺」の典型例であり、
    bash -n のみで works 判定し、外部検証を行わなかった。
  solution: |
    反証モード（問題を探す姿勢）+ codex 独立評価により
    39 件の問題を発見。この結果を永続的に追跡するため本文書を作成。
  result:
    discovered_issues: 39
    high_severity: 13
    medium_severity: 22
    low_severity: 4
    undetermined: 3

purpose:
  primary: |
    発見された問題の系統的解決を支援する。
    各 playbook 作成時に、pm SubAgent がこの文書を参照し、
    対応する PB-XX の Scope/Done when/Validation を done_criteria に反映する。
  secondary: |
    playbook 作成時の品質ベースラインを提供する。
    「何を修正すべきか」が事前に整理されているため、
    スコープの発散を防ぎ、検証可能な基準を設定できる。
  tertiary: |
    将来の監査との比較基準となる。
    PB-XX が完了するたびに進捗を追跡し、
    システム全体の健全性を測定できる。

principles:
  - name: 外部検証の原則
    description: 自己採点は攻略される。codex/coderabbit による独立評価を必須とする
    reference: self-evaluation-defense.md Section 3.1
  - name: 反証モードの原則
    description: 「問題がない」ではなく「問題を探したが見つからなかった」と表現する
    reference: self-evaluation-defense.md Section 3.3
  - name: トレーサビリティの原則
    description: 行番号・コマンド出力を証拠として記録する
    reference: self-evaluation-defense.md Section 3.2
  - name: 正直さの原則
    description: 判定不能は UNDETERMINED として正直に残す
    reference: self-evaluation-defense.md Section 3.4

related_documents:
  - path: .claude/SKILL_INDEX_v2.md
    role: 監査結果の詳細（問題リスト、推奨アクション）
  - path: .claude/frameworks/self-evaluation-defense.md
    role: 自己評価バイアス防止の設計原則
  - path: plan/archive/playbook-skill-audit-v2.md
    role: 監査プロセスの記録（p1-p5 の実行履歴）
```

---

## 使用方法

### playbook 生成フロー

pm SubAgent が playbook を作成する際、以下の手順でこのドキュメントを参照する：

```yaml
step_1_identify:
  action: タスク内容から対応する PB-XX を特定
  example: |
    タスク「bash-check.sh のパス計算修正」
    → PB-03（playbook-fix-bash-check-repo-root.md）を特定

step_2_extract:
  action: Section 1 から Scope/Done when/Validation を取得
  fields:
    - Scope: 修正対象ファイル一覧
    - Done when: 完了条件（機械的に検証可能な形式）
    - Validation: 検証コマンドまたはスクリプト

step_3_detail:
  action: Section 2 から詳細分析を取得
  fields:
    - 対象ファイル: 絶対パス
    - 問題の詳細: 行番号とコードスニペット
    - 修正内容: before/after の差分
    - done_criteria: 機械的検証条件
    - executor: 実行担当（claudecode/codex）

step_4_playbook:
  action: 取得した情報を playbook に反映
  sections:
    - goal.done_when: Done when + done_criteria から構成
    - phases.subtasks: Scope のファイルごとにタスク化
    - validations: Validation コマンドを 3 点検証に組み込む
```

### anti-fraud プロトコル

このドキュメントを使用する際の報酬詐欺防止ルール：

```yaml
prohibited:
  - 独自解釈でスコープを変更する
    # 理由: PB-XX のスコープは監査結果に基づく。勝手な拡大/縮小は禁止
  - Validation を実行せずに完了とする
    # 理由: 「それっぽい完了」を防ぐため、記載の検証コマンドを必ず実行
  - Section 2 の行番号を確認せずに修正する
    # 理由: 問題の正確な位置を特定し、修正範囲を限定するため

required:
  - PB-XX の Validation を critic による検証項目に含める
    # critic が独立して検証できるよう、playbook に明記
  - 修正前後の diff を記録する
    # 変更内容を追跡可能にし、事後検証を可能に
  - Section 2 のコードスニペットと実際のコードを照合する
    # ドキュメントと実態の乖離を検出
  - 完了時は PB-XX を「修正済み」としてマーキング（将来の進捗追跡用）
    # システム全体の健全性を測定可能に

evidence_format:
  technical: "コマンド出力（exit code, stdout/stderr）"
  consistency: "Section 2 の行番号と実際のファイルの一致確認"
  completeness: "Scope の全ファイルに対する修正確認"
```

### クイックリファレンス

| 目的 | 参照先 |
|------|--------|
| PB-XX の Scope/Done when 確認 | Section 1 |
| 行番号・コードスニペット確認 | Section 2 |
| PB-XX と P0/P1/P2 の対応表 | Section 3 |
| 作業順序の判断 | Section 4 |
| 全体進捗の把握 | Section 5 |

---

## Section 1: 実行可能バックログ（Codex版）

### P0 Guard Stability

#### PB-01: playbook-fix-playbook-guard-timeout.md ✅ FIXED
- **概要**: playbook-guard.sh の非対話ハングを排除し必ず終了するよう修正
- **Scope**: playbook-guard.sh, test-workflow-simple.sh
- **Done when**: playbook 未設定時にタイムアウトせず BLOCK/WARN を返す
- **Validation**: test-workflow-simple.sh
- **Status**: 修正済み (2026-01-03)
- **修正内容**:
  - 問題: `INPUT=$(cat)` に timeout がなく無限ハングの可能性
  - 修正: `if ! INPUT=$(timeout 5 cat 2>/dev/null); then` パターンに変更
  - 対象行: 35-38

#### PB-02: playbook-fix-failure-logger.md
- **概要**: 欠損している failure logger を最小修正で解消（既存ログ機構へ集約 or 最小実装を追加）
- **Scope**: failure-logger.sh, playbook-guard.sh
- **Done when**: 欠損参照が消え、ログ出力が失敗しない
- **Validation**: `rg "failure-logger" .claude` の参照先確認

#### PB-03: playbook-fix-bash-check-repo-root.md
- **概要**: bash-check.sh の REPO_ROOT 算出を修正し contract.sh に到達
- **Scope**: bash-check.sh, contract.sh
- **Done when**: contract 参照が失敗しない
- **Validation**: verify-hook-delegation.sh

#### PB-04: playbook-fix-protected-edit-repo-root.md
- **概要**: protected-edit.sh の REPO_ROOT 算出を修正し contract.sh に到達
- **Scope**: protected-edit.sh, contract.sh
- **Done when**: contract 参照が失敗しない
- **Validation**: verify-hook-delegation.sh

#### PB-05: playbook-fix-coherence-absolute-path.md
- **概要**: coherence.sh の state-schema.sh 参照を絶対パス化して cwd 依存を排除
- **Scope**: coherence.sh, state-schema.sh
- **Done when**: 任意 cwd でも PASS/WARN が安定
- **Validation**: coherence.sh

---

### P0 Hook Robustness

#### PB-06: playbook-fix-pending-guard-fail-closed.md
- **概要**: jq 不在時の fail-closed 実装と明示エラー
- **Scope**: pending-guard.sh
- **Done when**: jq 不在でも PASS にならない
- **Validation**: jq を外した環境で guard 単体実行

#### PB-07: playbook-fix-prompt-grep-awk.md ✅ FIXED
- **概要**: grep -c/awk の 0 件時エラーを回避
- **Scope**: prompt.sh
- **Done when**: 空結果でも exit 0 を維持し誤 BLOCK しない
- **Validation**: 0件ケースでの hook 単体実行
- **Status**: 修正済み (2026-01-03)
- **修正内容**:
  - 問題: pipefail 環境で `grep -c ... || echo "0"` が `0\n0` を出力し算術演算エラー
  - 原因: grep -c が 0 件時に exit 1 → pipefail で || が実行 → 出力が連結
  - 修正: `|| true` + `${var:-0}` に変更（.claude/hooks/prompt.sh 行 52, 55-56）
- **テスト**: 9テストケース全PASS (行18,20,47,52,55 + 全体実行)

#### PB-08: playbook-fix-post-tool.md ✅ CLOSED
- **概要**: codex 指摘の不具合を再現→修正→回帰テスト追加
- **Scope**: post-tool.sh, test-workflow-simple.sh
- **Done when**: 再現ケースが PASS
- **Validation**: test-workflow-simple.sh
- **Status**: CLOSED - 問題なし判定 (2026-01-03)
- **調査結果**:
  - bash -n 構文チェック: OK
  - jq 不在時チェック: 不要（PostToolUse は後処理、ブロック不要）
  - invoke_skill で `|| true` 使用、失敗しても続行する設計
  - 明確な不具合は発見されず
- **判定**: 問題なしとして CLOSED

#### PB-09: playbook-fix-subagent-stop.md ✅ FIXED
- **概要**: codex 指摘の不具合を再現→修正→回帰テスト追加
- **Scope**: subagent-stop.sh, test-workflow-simple.sh
- **Done when**: 再現ケースが PASS
- **Validation**: test-workflow-simple.sh
- **Status**: 修正済み (2026-01-03)
- **修正内容**:
  - 問題: jq 不在時に exit 0（Fail-open）
  - 修正: exit 2 + エラーメッセージ（Fail-closed）に変更
  - 対象行: 21-24

#### PB-10: playbook-fix-executor-guard.md ✅ INVESTIGATED
- **概要**: codex 指摘の guard 失敗パターンを特定し修正
- **Scope**: executor-guard.sh
- **Done when**: 想定外 executor を確実に BLOCK
- **Validation**: guard 単体実行で PASS/FAIL を確認
- **Status**: 調査済み・問題なし (2026-01-03)
- **調査結果**:
  - bash -n 構文チェック: OK
  - jq 不在時 Fail-closed: 既に実装済み（行 47-57）
  - 未知の executor は警告のみで exit 0（設計意図通り）
  - 明確な不具合は発見されず

#### PB-26: playbook-fix-main-branch-skill-task-deadlock.md ✅ FIXED
- **概要**: main-branch.sh で Skill/Task ツールを許可し、playbook-init 呼び出し時のデッドロックを解消
- **Scope**: main-branch.sh
- **Done when**: main ブランチで Skill/Task ツールがブロックされない
- **Validation**: main ブランチで Skill(playbook-init) が実行可能
- **Status**: 修正済み (2026-01-03)
- **修正内容**:
  - 問題: main-branch.sh の許可リストに Skill/Task がなく、playbook-init がブロックされる
  - 原因: 設計意図「playbook 作成で自動ブランチ作成」が動作しないデッドロック
  - 修正: 行 54-57 に Skill/Task ツール許可を追加
  - ヘッダーコメント（行 17）にも Skill/Task を例外として追記

---

### P0/P1 Skill & Agent Integrity

#### PB-11: playbook-fix-critic-guard.md
- **概要**: codex 指摘の問題を修正し critic 強制が確実に動作
- **Scope**: critic-guard.sh
- **Done when**: critic 未実行の done 変更を BLOCK
- **Validation**: guard 単体実行 + 失敗ケース再現

#### PB-12: playbook-fix-access-control-skill-contract-path.md
- **概要**: SKILL 文書の contract 参照を実体に一致させる
- **Scope**: SKILL.md, contract.sh
- **Done when**: ドキュメント参照と実ファイルが一致
- **Validation**: SKILL.md

#### PB-13: playbook-fix-playbook-gate-skill-filename.md
- **概要**: playbook-gate のファイル名不一致を修正
- **Scope**: SKILL.md
- **Done when**: 記載されているパスが実在
- **Validation**: SKILL.md

#### PB-14: playbook-fix-golden-path-skill-references.md
- **概要**: golden-path の欠損参照を修正
- **Scope**: SKILL.md
- **Done when**: 参照先が全て実在
- **Validation**: 参照先の存在チェック

#### PB-15: playbook-fix-codex-delegate-toolstack.md
- **概要**: codex-delegate の toolstack 参照を明確化
- **Scope**: codex-delegate.md
- **Done when**: toolstack の定義が曖昧でなく再現可能
- **Validation**: 文書内の参照整合確認

---

### P1 Workflow Verification

#### PB-16: playbook-fix-session-start-idempotency.md
- **概要**: settings.json 登録の冪等化と重複検知
- **Scope**: session-start.sh, settings.json
- **Done when**: 連続実行でも重複が発生しない
- **Validation**: hook 単体実行の繰り返し確認

#### PB-17: playbook-fix-generate-repository-map-paths.md
- **概要**: 生成パス不整合を修正し repository-map.yaml を更新
- **Scope**: generate-repository-map.sh, repository-map.yaml
- **Done when**: 生成がエラーなく完了し参照整合
- **Validation**: hook 単体実行で exit 0

#### PB-18: playbook-implement-depends-check.md
- **概要**: exit 0 固定を廃止し依存チェックを実装
- **Scope**: depends-check.sh
- **Done when**: 依存欠如で FAIL する
- **Validation**: 依存欠如ケースの再現

#### PB-19: playbook-define-scope-guard-behavior.md
- **概要**: scope-guard の警告止まり/FAIL 方針を決定して実装
- **Scope**: scope-guard.sh
- **Done when**: 方針が文書化され挙動が一貫
- **Validation**: guard 単体実行

#### PB-20: playbook-verify-subtask-guard.md
- **概要**: 実 playbook を使った subtask-guard の動作検証と回帰テスト化
- **Scope**: subtask-guard.sh, test-workflow-state-transition.sh
- **Done when**: validations 不足の [x] を必ず BLOCK
- **Validation**: test-workflow-state-transition.sh

---

### P1/P2 Documentation & Template Hygiene

#### PB-21: playbook-verify-phase-status-guard.md
- **概要**: phase-status-guard の実 playbook 検証をテスト化
- **Scope**: phase-status-guard.sh, test-workflow-state-transition.sh
- **Done when**: 不正な status 変更を BLOCK
- **Validation**: test-workflow-state-transition.sh

#### PB-22: playbook-fix-reviewer-agent-doc.md
- **概要**: reviewer のプレースホルダを具体手順に置換
- **Scope**: reviewer.md
- **Done when**: 手順と判定基準が明文化
- **Validation**: 文書レビュー

#### PB-23: playbook-fix-critic-agent-tools.md
- **概要**: critic の tools 権限と role 説明の整合修正
- **Scope**: critic.md
- **Done when**: 実運用で必要な操作が定義通り可能
- **Validation**: 文書と運用の一致確認

#### PB-24: playbook-reduce-pm-doc-complexity.md
- **概要**: pm.md の deprecated/重複を整理し構造を簡潔化（内容保持）
- **Scope**: pm.md
- **Done when**: 冗長性が減り読みやすい
- **Validation**: 文書レビュー

#### PB-25: playbook-harden-playbook-template-traceability.md
- **概要**: R# と証拠（行番号/コマンド出力）を最小追加しテンプレ整合を強化
- **Scope**: playbook-format.md, playbook-examples.md
- **Done when**: トレーサビリティの記入欄が明示
- **Validation**: テンプレの整合確認

---

## Section 2: 詳細分析（行番号・コードスニペット付き）

調査基準: 全ファイル読み込みに基づく
調査ファイル数: 約70ファイル（hooks, guards, handlers, skills, agents, frameworks, docs）
原則: 1 アクションアイテム = 1 playbook 粒度 / 発散禁止 / 極端な省略・削除禁止

---

### P0: 緊急修復（実行時エラー・セキュリティ問題）

---

#### P0-01: bash-check.sh の REPO_ROOT パス計算修正

**対象ファイル**: .claude/skills/access-control/guards/bash-check.sh

**問題の詳細 (行 14-16)**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."
CONTRACT_SCRIPT="${REPO_ROOT}/scripts/contract.sh"
```
- 実際のパス: .claude/skills/access-control/guards/bash-check.sh
- 2階層上: .claude/skills/ → 不正
- 正しくは4階層上: リポジトリルート

**修正内容**:
```bash
# 変更前
REPO_ROOT="${SCRIPT_DIR}/../.."

# 変更後
REPO_ROOT="${SCRIPT_DIR}/../../../.."
```

**検証方法**:
```bash
cd .claude/skills/access-control/guards/
SCRIPT_DIR=$(pwd)
echo "${SCRIPT_DIR}/../../../.." | xargs realpath
# → リポジトリルートであることを確認
```

**done_criteria**:
- contract.sh が正しく source される
- bash -n bash-check.sh が成功

**executor**: claudecode

**対応 PB**: PB-03

---

#### P0-02: protected-edit.sh の REPO_ROOT パス計算修正

**対象ファイル**: .claude/skills/access-control/guards/protected-edit.sh

**問題の詳細 (行 21-23)**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."
CONTRACT_SCRIPT="${REPO_ROOT}/scripts/contract.sh"
```
- P0-01 と同じ問題

**修正内容**:
```bash
REPO_ROOT="${SCRIPT_DIR}/../../../.."
```

**done_criteria**:
- contract.sh が正しく source される
- bash -n protected-edit.sh が成功

**executor**: claudecode

**対応 PB**: PB-04

---

#### P0-03: coherence.sh の相対パス source を絶対パスに修正

**対象ファイル**: .claude/skills/reward-guard/guards/coherence.sh

**問題の詳細 (行 9)**:
```bash
source .claude/schema/state-schema.sh
```
- cwd がリポジトリルートでないと失敗
- git commit 時に bash-check.sh から呼ばれる（行 141）ため、リポジトリルートから実行される前提だが明示すべき

**修正内容**:
```bash
# 変更前
source .claude/schema/state-schema.sh

# 変更後
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../../.."
source "${REPO_ROOT}/.claude/schema/state-schema.sh"
```

**done_criteria**:
- bash -n coherence.sh が成功
- 任意ディレクトリからの実行でパスエラーなし

**executor**: claudecode

**対応 PB**: PB-05

---

#### P0-04: pending-guard.sh の jq 不在時 Fail-closed 化

**対象ファイル**: .claude/skills/post-loop/guards/pending-guard.sh

**問題の詳細 (行 31-34)**:
```bash
# jq がない場合はスキップ（フェイルセーフ）
if ! command -v jq &> /dev/null; then
    exit 0  # ← Fail-open: セキュリティ違反
fi
```

**修正内容**:
```bash
# 変更前
if ! command -v jq &> /dev/null; then
    exit 0
fi

# 変更後
if ! command -v jq &> /dev/null; then
    echo "[FAIL-CLOSED] jq not found - blocking for security" >&2
    exit 2
fi
```

**done_criteria**:
- jq 不在時に exit 2 でブロック
- エラーメッセージが stderr に出力

**executor**: claudecode

**対応 PB**: PB-06

---

#### P0-05: subagent-stop.sh の jq 不在時 Fail-closed 化

**対象ファイル**: .claude/hooks/subagent-stop.sh

**問題の詳細 (行 22-24)**:
```bash
if ! command -v jq &> /dev/null; then
    exit 0  # ← Fail-open
fi
```

**修正内容**:
```bash
if ! command -v jq &> /dev/null; then
    echo "[FAIL-CLOSED] jq not found" >&2
    exit 2
fi
```

**done_criteria**:
- jq 不在時に exit 2 でブロック

**executor**: claudecode

**対応 PB**: PB-09

---

#### P0-06: access-control/SKILL.md の存在しないファイル参照を修正

**対象ファイル**: .claude/skills/access-control/SKILL.md

**問題の詳細 (行 28-29)**:
```
└── lib/
    └── contract.sh           ← 契約判定ロジック
```
- .claude/skills/access-control/lib/contract.sh は存在しない
- 実際の contract.sh は scripts/contract.sh（リポジトリルート直下）

**修正内容**:
```markdown
# 変更前（ディレクトリ構造セクション）
└── lib/
    └── contract.sh           ← 契約判定ロジック

# 変更後
# lib/ セクション全体を削除

# 関連セクション追記
## 外部依存

| ファイル | 役割 |
|----------|------|
| scripts/contract.sh | 契約判定ロジック（共通） |
```

**done_criteria**:
- 存在しないファイルへの参照がない
- 実際の contract.sh への参照が追加されている

**executor**: claudecode

**対応 PB**: PB-12

---

#### P0-07: playbook-gate/SKILL.md のファイル名不一致修正

**対象ファイル**: .claude/skills/playbook-gate/SKILL.md

**問題の詳細 (行 37)**:
```
├── archive.sh            ← playbook 完了時アーカイブ
```
- 実際のファイル名: archive-playbook.sh

**修正内容**:
```markdown
# 変更前
├── archive.sh            ← playbook 完了時アーカイブ

# 変更後
├── archive-playbook.sh   ← playbook 完了時アーカイブ
```

**done_criteria**:
- ファイル名が実態と一致

**executor**: claudecode

**対応 PB**: PB-13

---

#### P0-08: golden-path/SKILL.md の存在しないファイル参照を削除

**対象ファイル**: .claude/skills/golden-path/SKILL.md

**問題の詳細 (行 84)**:
```
| docs/4qv-architecture.md | アーキテクチャ設計書 |
```
- docs/4qv-architecture.md は存在しない
- docs/ARCHITECTURE.md は存在する

**修正内容**:
```markdown
# 変更前
| docs/4qv-architecture.md | アーキテクチャ設計書 |

# 変更後
| docs/ARCHITECTURE.md | アーキテクチャ設計書 |
```

**done_criteria**:
- 参照先が存在するファイルになっている

**executor**: claudecode

**対応 PB**: PB-14

---

#### P0-09: common.sh の CONTEXT_MD 参照確認と修正

**対象ファイル**: .claude/lib/common.sh

**問題の詳細 (行 30)**:
```bash
CONTEXT_MD="$WORKSPACE_ROOT/CONTEXT.md"
```
- CONTEXT.md は存在しない（Glob で確認済み）

**修正内容**:
- 使用箇所を確認
- 未使用なら変数定義を削除
- 使用されているなら代替ファイルに変更（または機能削除）

**done_criteria**:
- 存在しないファイルへの参照がない
- または未使用変数が削除されている

**executor**: claudecode

**対応 PB**: なし（追加調査後に PB 番号割り当て）

---

#### P0-10: repository-map.yaml の古いパス参照を修正

**対象ファイル**: docs/repository-map.yaml

**問題の詳細 (行 284-287, 316-321)**:
```yaml
references:
  - ".claude/hooks/init-guard.sh"
  - ".claude/hooks/check-main-branch.sh"
  - ".claude/hooks/playbook-guard.sh"
```
- 実際のパス:
  - .claude/skills/session-manager/handlers/init-guard.sh
  - .claude/skills/access-control/guards/main-branch.sh
  - .claude/skills/playbook-gate/guards/playbook-guard.sh

**修正内容**:
- workflows セクション内の全ての references を実際のパスに修正

**done_criteria**:
- 全ての参照パスが実際に存在するファイルを指している

**executor**: claudecode

**対応 PB**: PB-17

---

### P1: 機能修正（動作するが問題あり）

---

#### P1-01: pm.md の過剰複雑性解消と DEPRECATED 削除

**対象ファイル**: .claude/skills/golden-path/agents/pm.md

**問題の詳細**:
- 932行の巨大ファイル
- [DEPRECATED] セクションが残存（executor-resolver に移行済み）

**修正内容**:
- DEPRECATED セクション（存在確認後に特定）を削除
- 削除理由をコメントとして 1 行残す
- 重複する説明の統合

**done_criteria**:
- ファイル行数が 800 行以下
- DEPRECATED セクションが削除されている
- executor-resolver への参照が維持されている

**executor**: claudecode

**対応 PB**: PB-24

---

#### P1-02: critic.md の session-state 書き込み方法の明文化

**対象ファイル**: .claude/skills/reward-guard/agents/critic.md

**問題の詳細**:
```yaml
tools: Read, Grep, Bash
# Write/Edit は禁止（自己完了防止）
# しかし session-state への書き込みを Bash 経由で指示している
```

**修正内容**:
```yaml
# 行 4 付近に追加
tools: Read, Grep, Bash
# Note: Write/Edit は禁止（自己完了防止）
# session-state への書き込みは Bash (mkdir -p, cat >) で実行
```

**done_criteria**:
- tools の説明が明確
- session-state 書き込みの方法が文書化

**executor**: claudecode

**対応 PB**: PB-23

---

#### P1-03: depends-check.sh のガード機能実装判断

**対象ファイル**: .claude/skills/playbook-gate/guards/depends-check.sh

**問題の詳細 (行 74-78)**:
```bash
if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $ERRORS 件の依存 Phase が未完了です"
    exit 0  # 警告のみ、ブロックしない
fi
```

**判断・修正内容**:
- depends_on 違反時にブロック（exit 2）すべきか設計判断
- ブロックする場合: 行 78 を exit 2 に変更
- 現状維持の場合: 設計意図をコメントで追記

**done_criteria**:
- 設計意図が明確にコメントされている
- ブロック/警告のどちらかが意図的に選択されている

**executor**: claudecode

**対応 PB**: PB-18

---

#### P1-04: scope-guard.sh の STRICT_MODE デフォルト値判断

**対象ファイル**: .claude/skills/reward-guard/guards/scope-guard.sh

**問題の詳細 (行 23)**:
```bash
STRICT_MODE="${STRICT_MODE:-false}"
```
- デフォルトで警告のみ（ブロックしない）

**判断・修正内容**:
- Fail-closed にすべき場合: デフォルトを true に変更
- 現状維持の場合: 設計意図をコメントで追記

**done_criteria**:
- 設計意図が明確
- STRICT_MODE のデフォルト値が意図的に選択されている

**executor**: claudecode

**対応 PB**: PB-19

---

#### P1-05: session-start.sh の init-guard.sh 相対パス確認

**対象ファイル**: .claude/hooks/session-start.sh

**問題の詳細 (行 24)**:
```bash
source .claude/schema/state-schema.sh
```
- cwd 依存の相対パス

**確認・修正内容**:
- session-start.sh が常にリポジトリルートから実行されることを確認
- 確信が持てない場合は絶対パスに変更

**done_criteria**:
- パス参照が確実に動作することが確認されている

**executor**: claudecode

**対応 PB**: PB-16

---

#### P1-06: cleanup.sh の generate-repository-map.sh パス参照確認

**対象ファイル**: .claude/skills/playbook-gate/workflow/cleanup.sh

**問題の詳細 (行 84-85)**:
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAP_SCRIPT="$SCRIPT_DIR/generate-repository-map.sh"
```
- $SCRIPT_DIR は .claude/skills/playbook-gate/workflow/
- generate-repository-map.sh は .claude/hooks/ にある

**修正内容**:
```bash
# 変更前
MAP_SCRIPT="$SCRIPT_DIR/generate-repository-map.sh"

# 変更後
REPO_ROOT="${SCRIPT_DIR}/../../../.."
MAP_SCRIPT="${REPO_ROOT}/.claude/hooks/generate-repository-map.sh"
```

**done_criteria**:
- MAP_SCRIPT が正しいパスを指している

**executor**: claudecode

**対応 PB**: PB-17

---

#### P1-07: reviewer.md のフレームワーク参照確認

**対象ファイル**: .claude/skills/quality-assurance/agents/reviewer.md

**問題の詳細**:
- フレームワーク参照が存在するか確認
  - .claude/frameworks/playbook-review-criteria.md ✓ 存在
  - .claude/frameworks/playbook-reviewer-spec.md ✓ 存在

**確認結果**: 問題なし（参照先は存在する）

**done_criteria**: N/A（確認のみ）

**対応 PB**: PB-22（プレースホルダ置換のみ）

---

#### P1-08: codex-delegate.md の toolstack 定義参照追加

**対象ファイル**: .claude/skills/golden-path/agents/codex-delegate.md

**問題の詳細**:
- toolstack A/B/C の説明があるが、定義元への参照がない

**修正内容**:
```markdown
# 追加
## 参照
- state.md の `config.toolstack` で現在の toolstack を確認
```

**done_criteria**:
- toolstack の定義元への参照が追加されている

**executor**: claudecode

**対応 PB**: PB-15

---

#### P1-09: prompt.sh の grep -c 0 件時挙動確認 ✅ FIXED

**対象ファイル**: .claude/hooks/prompt.sh

**問題の詳細 (行 50-52)**:
```bash
# 修正前（問題あり）
completed=$(echo "$phase_section" | grep -c '\- \[x\]' 2>/dev/null || echo "0")
incomplete=$(echo "$phase_section" | grep -c '\- \[ \]' 2>/dev/null || echo "0")

# 修正後
completed=$(echo "$phase_section" | grep -c '\- \[x\]' 2>/dev/null || true)
completed=${completed:-0}
incomplete=$(echo "$phase_section" | grep -c '\- \[ \]' 2>/dev/null || true)
incomplete=${incomplete:-0}
```

**確認結果**: ~~|| echo "0" があるため問題なし~~ → **問題あり・修正済み**
- pipefail 環境で grep -c が 0 件時に exit 1 を返すと、|| echo "0" も実行され出力が "0\n0" に
- 算術演算 `$((completed + incomplete))` で syntax error 発生

**修正内容**: `|| true` + `${var:-0}` に変更

**done_criteria**: 修正済み (2026-01-03)

**対応 PB**: PB-07（修正完了）

---

#### P1-10: playbook-guard.sh の failure-logger.sh 参照確認

**対象ファイル**: .claude/skills/playbook-gate/guards/playbook-guard.sh

**問題の詳細 (行 107-109, 138-140, 171-173)**:
```bash
if [[ -f ".claude/hooks/failure-logger.sh" ]]; then
    echo '...' | bash .claude/hooks/failure-logger.sh 2>/dev/null || true
fi
```

**確認結果**:
- failure-logger.sh は存在しない
- しかし [[ -f ... ]] で存在チェックしているため、存在しなくても問題なし
- ARCHITECTURE.md (行 1271-1273) でも「低影響」と記載済み

**判断**: 現状維持可（存在チェックでガードされている）

**任意修正**:
- 参照を削除してコードを簡素化
- または failure-logger.sh を実装

**done_criteria**: 現状維持または参照削除

**executor**: claudecode

**対応 PB**: PB-02

---

### P2: ドキュメント整備（実態との乖離修正）

---

#### P2-01: ARCHITECTURE.md の既知の課題セクション更新

**対象ファイル**: docs/ARCHITECTURE.md

**問題の詳細**:
- Section 14「既知の課題と未実装」に bash-check.sh, protected-edit.sh のパス計算問題が記載されていない

**修正内容**:
- P0 修正後に、修正済み項目として更新

**done_criteria**:
- 既知の課題が最新状態に更新されている

**executor**: claudecode

**対応 PB**: なし（P0 修正後に実施）

---

#### P2-02: SKILL.md ディレクトリ構造セクションの全面検証

**対象**: 全ての .claude/skills/*/SKILL.md

**確認内容**:
- 各 SKILL.md の「ディレクトリ構造」セクションが実態と一致するか

**修正内容**:
- 不一致があれば修正

**done_criteria**:
- 全ての SKILL.md のディレクトリ構造が実態と一致

**executor**: claudecode

**対応 PB**: PB-12, PB-13, PB-14（個別対応）

---

## Section 3: マッピングテーブル

| PB番号 | P0/P1/P2 番号 | 対象ファイル | 問題種別 |
|--------|---------------|--------------|----------|
| PB-01 | - | playbook-guard.sh | タイムアウト |
| PB-02 | P1-10 | failure-logger.sh | 欠損参照 |
| PB-03 | P0-01 | bash-check.sh | パス計算 |
| PB-04 | P0-02 | protected-edit.sh | パス計算 |
| PB-05 | P0-03 | coherence.sh | 相対パス |
| PB-06 | P0-04 | pending-guard.sh | Fail-open |
| PB-07 | P1-09 | prompt.sh | grep 0件 |
| PB-08 | - | post-tool.sh | 不具合 |
| PB-09 | P0-05 | subagent-stop.sh | Fail-open |
| PB-10 | - | executor-guard.sh | guard失敗 |
| PB-11 | - | critic-guard.sh | 強制失敗 |
| PB-12 | P0-06 | access-control/SKILL.md | 参照不一致 |
| PB-13 | P0-07 | playbook-gate/SKILL.md | ファイル名 |
| PB-14 | P0-08 | golden-path/SKILL.md | 参照不一致 |
| PB-15 | P1-08 | codex-delegate.md | 参照不足 |
| PB-16 | P1-05 | session-start.sh | 冪等性 |
| PB-17 | P0-10, P1-06 | repository-map.yaml | パス不整合 |
| PB-18 | P1-03 | depends-check.sh | 設計判断 |
| PB-19 | P1-04 | scope-guard.sh | 設計判断 |
| PB-20 | - | subtask-guard.sh | テスト化 |
| PB-21 | - | phase-status-guard.sh | テスト化 |
| PB-22 | P1-07 | reviewer.md | プレースホルダ |
| PB-23 | P1-02 | critic.md | tools説明 |
| PB-24 | P1-01 | pm.md | 複雑性 |
| PB-25 | - | playbook-format.md | トレーサビリティ |
| PB-26 | - | main-branch.sh | デッドロック |

---

## Section 4: 推奨実行順序

```
Phase 1: P0 Guard Stability (PB-01 〜 PB-05)
  ↓ 実行時エラー解消
Phase 2: P0 Hook Robustness (PB-06 〜 PB-10, PB-26)
  ↓ セキュリティ・堅牢性確保・デッドロック解消
Phase 3: P0/P1 Skill & Agent Integrity (PB-11 〜 PB-15)
  ↓ ドキュメント整合
Phase 4: P1 Workflow Verification (PB-16 〜 PB-20)
  ↓ ワークフロー検証
Phase 5: P1/P2 Documentation & Template Hygiene (PB-21 〜 PB-25)
  ↓ 最終品質向上
```

---

## Section 5: サマリー

| 優先度 | 件数 | 内容 |
|--------|------|------|
| P0 Guard Stability | 5件 | パス計算修正、タイムアウト排除 |
| P0 Hook Robustness | 6件 | Fail-closed化、エラー処理、デッドロック解消 |
| P0/P1 Skill & Agent | 5件 | ドキュメント参照整合 |
| P1 Workflow | 5件 | 冪等性、設計判断 |
| P1/P2 Documentation | 5件 | テンプレ・ドキュメント整備 |
| **合計** | **26件** | |

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2025-01-03 | 初版作成：Codex版25件 + 詳細分析 + マッピングテーブル |
