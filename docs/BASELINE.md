# BASELINE.md

> **アーキテクチャリファレンス & 開発ガイド**
>
> このドキュメントは設計思想と各コンポーネントの責務を明記し、
> 今後の開発における判断基準を提供する。

---

## Meta

```yaml
version: 1.0.0
created: 2025-12-25
verified_commit: b3a0b6e
claude_md_version: 2.0.0
```

---

## 1. 設計思想

### 1.1 解決すべき問題

```yaml
LLM の構造的欠陥:
  自己承認バイアス:
    症状: 自分の出力を「完了」と判断しがち
    原因: 検証者と作業者が同一
    結果: 不完全な成果物が「完了」として提出される

  スコープクリープ:
    症状: ユーザー要求に引きずられて作業範囲が肥大
    原因: 「NO」と言う判断基準がない
    結果: 当初の目的から逸脱、収束しない

  状態喪失:
    症状: コンテキストリセット後に何をしていたか忘れる
    原因: 状態がチャット履歴にしか存在しない
    結果: 作業の継続性が失われる
```

### 1.2 解決戦略

```yaml
原則: 「お願い」ではなく「ブロック」で制御する

trinity:
  hooks:
    役割: 構造的強制
    手段: ツール実行前に条件をチェックし、不成立なら BLOCK を返す
    効果: LLM は物理的に進めない

  subagents:
    役割: 独立検証
    手段: 作業者とは別の SubAgent が done_criteria を判定
    効果: 自己承認バイアスを構造的に防止

  state_md:
    役割: 状態永続化
    手段: 現在状態をファイルに保存、セッション開始時に読み込み
    効果: コンテキストリセット後も状態を復元可能
```

### 1.3 なぜこの層構造か

```yaml
L1_hooks → L2_skills → L3_subagents:
  設計理由:
    - Hook は「発火条件」のみを判定（軽量）
    - Skill は「何をすべきか」をパッケージ化（再利用可能）
    - SubAgent は「専門的判断」を行う（独立性）

  チェーン順序の意味:
    - Hook がトリガーとなり Skill を呼び出す
    - Skill が SubAgent に委譲する
    - SubAgent が実際の判断・作業を行う

  スキップ禁止の理由:
    - Hook を飛ばす → 保護機構が無効化
    - Skill を飛ばす → 文脈が失われる
    - SubAgent を飛ばす → 独立検証が行われない
```

---

## 2. コンポーネント詳細

### 2.1 L1: Hooks（導火線層）

```
.claude/hooks/
├── prompt.sh          # UserPromptSubmit
├── pre-tool.sh        # PreToolUse(*)
├── post-tool.sh       # PostToolUse(*)
└── session.sh         # セッション管理
```

#### prompt.sh

```yaml
発火: ユーザーがプロンプトを送信した時
責務: State Injection
内包機能:
  - state.md から playbook.active を読み取る
  - playbook=null なら「playbook-init を呼べ」と指示を注入
  - playbook 存在時は現在の phase を注入
出力: { decision: "continue", messages: [...] }
開発ヒント:
  - 新しい状態を注入したい場合はここに追加
  - 注入メッセージは role: "user" で追加
```

#### pre-tool.sh

```yaml
発火: 任意のツールが実行される前
責務: ゲートキーパー
内包機能:
  - session-manager/init-guard.sh を呼び出し
  - access-control/main-branch.sh を呼び出し
  - Edit/Write 時:
    - access-control/protected-edit.sh
    - playbook-gate/playbook-guard.sh  ← 核心
    - playbook-gate/depends-check.sh
    - reward-guard/critic-guard.sh
  - Bash 時:
    - access-control/bash-check.sh
    - quality-assurance/checkers/lint.sh
出力: exit 0 (許可) または exit 1 + BLOCK メッセージ
開発ヒント:
  - 新しいガードを追加する場合は case 文に追加
  - invoke_skill() で Skill 内の handler を呼び出す
```

#### post-tool.sh

```yaml
発火: ツール実行完了後
責務: 事後チェック・通知
内包機能:
  - 現時点では軽量（将来拡張用）
開発ヒント:
  - 実行結果の検証、ログ記録などに使用
```

---

### 2.2 L2: Skills（ユースケース層）

```
.claude/skills/
├── access-control/        # アクセス制御
│   └── guards/
│       ├── main-branch.sh    # main ブランチ作業禁止
│       ├── protected-edit.sh # 保護ファイル編集禁止
│       └── bash-check.sh     # Bash コマンド検証
│
├── playbook-gate/         # Playbook ゲート
│   └── guards/
│       ├── playbook-guard.sh # playbook=null ブロック ★核心
│       ├── depends-check.sh  # Phase 依存チェック
│       └── executor-guard.sh # executor 権限チェック
│
├── playbook-init/         # タスク開始エントリー
│   └── SKILL.md              # pm への委譲を強制
│
├── golden-path/           # Golden Path 管理
│   └── agents/
│       ├── pm.md             # プロジェクトマネージャー ★
│       └── ...
│
├── understanding-check/   # 理解確認
│   └── SKILL.md              # 5W1H 分析フレームワーク
│
├── quality-assurance/     # 品質保証
│   ├── agents/
│   │   └── reviewer.md       # Playbook レビュー ★
│   └── checkers/
│       └── lint.sh
│
├── reward-guard/          # 報酬詐欺防止
│   ├── agents/
│   │   └── critic.md         # 完了判定 ★
│   └── guards/
│       ├── critic-guard.sh   # critic なしの完了をブロック
│       ├── subtask-guard.sh  # subtask 未完了をブロック
│       └── scope-guard.sh    # スコープ逸脱をブロック
│
├── session-manager/       # セッション管理
│   └── handlers/
│       └── init-guard.sh     # 初期化チェック
│
├── state/                 # 状態管理
│   └── SKILL.md              # state.md 操作
│
└── ...                    # 他 Skill
```

#### Skill 構造パターン

```yaml
典型的な Skill 構造:
  SKILL.md:           # Skill 定義（いつ使うか、何をするか）
  guards/:            # ガードスクリプト（ブロック判定）
  handlers/:          # ハンドラスクリプト（処理実行）
  checkers/:          # チェッカースクリプト（検証実行）
  agents/:            # SubAgent 定義（*.md）

開発ヒント:
  - 新しい保護ルールを追加 → guards/ に .sh を追加
  - 新しい処理を追加 → handlers/ に .sh を追加
  - 専門的判断が必要 → agents/ に .md を追加
  - pre-tool.sh から invoke_skill() で呼び出し
```

---

### 2.3 L3: SubAgents（専門検証者層）

```yaml
pm (golden-path/agents/pm.md):
  役割: プロジェクトマネージャー
  責務:
    - タスク開始の必須エントリーポイント
    - playbook 作成（ドラフト）
    - understanding-check の実行
    - reviewer への委譲
    - state.md の更新
  呼び出し元: playbook-init Skill
  呼び出し先: understanding-check, reviewer
  開発ヒント:
    - playbook 作成ロジックを変更したい場合はここ
    - 新しい Phase パターンを追加する場合はここ

reviewer (quality-assurance/agents/reviewer.md):
  役割: 計画検証者
  責務:
    - playbook のシミュレーション実行
    - Phase 依存関係の検証
    - done_criteria の検証可能性チェック
    - PASS/FAIL 判定
  呼び出し元: pm
  判定基準: .claude/frameworks/playbook-review-criteria.md
  開発ヒント:
    - レビュー基準を変更したい場合は frameworks/ を編集

critic (reward-guard/agents/critic.md):
  役割: 完了判定者
  責務:
    - done_criteria の独立検証
    - 証拠ベースの PASS/FAIL 判定
    - 報酬詐欺の防止
  呼び出し元: Claude（Phase 完了時）
  核心ルール: 作業者 ≠ 検証者
  開発ヒント:
    - 検証ロジックを厳格化したい場合はここ
    - 証拠の形式を追加したい場合はここ
```

---

### 2.4 SSOT: state.md

```yaml
役割: Single Source of Truth（唯一の真実源）
位置: リポジトリルート

セクション:
  focus:
    current: 現在のワークスペース識別子
    用途: 複数プロジェクト対応時の切り替え

  playbook:
    active: 現在アクティブな playbook パス（null = 待機状態）
    branch: 作業ブランチ名
    review_pending: レビュー待ちフラグ
    核心: active=null で変更系ツールがブロックされる

  goal:
    phase: 現在の Phase
    done_criteria: 現在の完了条件
    用途: コンテキストリセット後の状態復元

  config:
    security: admin/user モード
    toolstack: A/B/C（使用ツール構成）
    roles: 役割→executor マッピング

信頼階層:
  1. state.md（最優先）
  2. playbook
  3. チャット履歴（リセットで消失）

開発ヒント:
  - 新しい状態を追加する場合は state.md にセクション追加
  - Skill(state) 経由で操作することを推奨
```

---

## 3. データフロー

### 3.1 タスク開始フロー

```
ユーザー: 「ボタン作って」
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ prompt.sh (State Injection)                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ state.md を読み込み                                      │ │
│ │ playbook.active = null を検出                           │ │
│ │ 「Skill(playbook-init) を呼べ」を注入                    │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude: Skill(skill='playbook-init') を呼び出し             │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ playbook-init Skill                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ SKILL.md: 「pm SubAgent に委譲せよ」                     │ │
│ │ → Task(subagent_type='pm', prompt='...')                │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ pm SubAgent                                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 1. understanding-check 実行（5W1H 分析）                 │ │
│ │ 2. ユーザー承認を取得                                    │ │
│ │ 3. playbook 作成（ドラフト）                             │ │
│ │ 4. reviewer 呼び出し                                     │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ reviewer SubAgent                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ playbook をシミュレーション                              │ │
│ │ PASS → pm に戻る                                        │ │
│ │ FAIL → 修正案を提示 → pm が修正 → 再レビュー            │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ pm SubAgent (続き)                                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ state.md 更新: playbook.active = 新しい playbook        │ │
│ │ ブランチ作成: feat/xxx                                   │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
     作業開始可能
```

### 3.2 作業実行フロー（playbook 存在時）

```
Claude: Edit ツールを呼び出し
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ pre-tool.sh                                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ access-control/main-branch.sh → OK                      │ │
│ │ access-control/protected-edit.sh → OK                   │ │
│ │ playbook-gate/playbook-guard.sh → playbook 存在 → OK   │ │
│ │ playbook-gate/depends-check.sh → 依存 Phase 完了 → OK  │ │
│ │ reward-guard/critic-guard.sh → OK                       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼ (全 OK)
     Edit 実行許可
```

### 3.3 完了判定フロー

```
Claude: 「Phase 完了したと思う」
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude: Task(subagent_type='critic', prompt='...')          │
│ ★ 自分で「完了」と言ってはいけない                          │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ critic SubAgent                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ done_criteria を1つずつ検証                              │ │
│ │ 証拠を収集（grep, test, 実行結果）                       │ │
│ │ PASS: 全条件クリア + 証拠あり                           │ │
│ │ FAIL: 条件未達 or 証拠不足                              │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
    PASS → 次 Phase / 完了
    FAIL → 修正して再検証
```

---

## 4. 開発ガイド

### 4.1 新しいガードを追加する

```bash
# 1. Skill 内に guards/ ディレクトリを作成（なければ）
mkdir -p .claude/skills/{skill-name}/guards/

# 2. ガードスクリプトを作成
cat > .claude/skills/{skill-name}/guards/my-guard.sh << 'EOF'
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
# 条件をチェック
if [[ 条件不成立 ]]; then
    echo "[BLOCK] 理由"
    exit 1
fi
exit 0
EOF

# 3. 実行権限を付与
chmod +x .claude/skills/{skill-name}/guards/my-guard.sh

# 4. pre-tool.sh から呼び出しを追加
# invoke_skill "{skill-name}" "guards/my-guard.sh" || exit $?
```

### 4.2 新しい SubAgent を追加する

```bash
# 1. Skill 内に agents/ ディレクトリを作成（なければ）
mkdir -p .claude/skills/{skill-name}/agents/

# 2. SubAgent 定義を作成
cat > .claude/skills/{skill-name}/agents/my-agent.md << 'EOF'
---
name: my-agent
description: 何をするエージェントか
tools: Read, Write, Bash, ...
model: opus
---

# My Agent

## 責務
- ...

## トリガー条件
- ...

## 行動原則
- ...
EOF

# 3. settings.json に登録
# subagent_type として使えるようになる
```

### 4.3 Core Contract を変更する場合

```yaml
警告: Core Contract は admin モードでも回避不可

変更手順:
  1. governance/PROMPT_CHANGELOG.md に理由を記録
  2. CLAUDE.md を編集（バージョン番号更新）
  3. 関連する Hook/Skill/SubAgent を更新
  4. E2E テストで動作確認
  5. BASELINE.md を更新
```

---

## 5. 検証済み状態（2025-12-25）

```yaml
commit: b3a0b6e
テスト内容: 「ボタン作って」タスクの E2E 実行

e2e_verification:
  date: 2025-12-25
  commit: dc92a38
  test: フレームワーク E2E 検証（playbook-init → pm → reviewer → 実装 → critic → post-loop）
  result: PASS
  note: plan/active/ 汚染修正、create-pr-hook.sh パスバグ修正後の検証

検証項目:
  hook_enforcement:
    playbook_gate: PASS
    main_branch_guard: PASS

  chain_compliance:
    golden_path: PASS
    pm_delegation: PASS
    understanding_check: PASS
    reviewer_gate: PASS

  reward_fraud_prevention:
    critic_verification: PASS
    evidence_based: PASS

チェックサム（変更検知用）:
  CLAUDE.md: 8819111232b8...
  pre-tool.sh: c3c2379ba786...
  prompt.sh: a95083dd8024...
  pm.md: 4d396708738b...
  critic.md: 557e84de2351...
  reviewer.md: 678c2bf893b2...
```

---

## 6. 未実装・拡張候補

```yaml
prompt.sh 自動発火:
  現状: 手動で Skill(playbook-init) を呼んだ
  理想: prompt.sh が自動的に golden_path を発動
  課題: Hook の戻り値だけでは Skill 呼び出しを強制できない

Phase 間自動コミット:
  現状: 手動
  理想: critic PASS 後に自動コミット
  実装場所: post-tool.sh または Skill

p_self_update 自動追加:
  現状: pm が手動判定
  理想: playbook-format.md のルールに基づき自動追加
  実装場所: pm.md 内のロジック
```

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2025-12-25 | アーキテクチャリファレンスとして再設計 |
