# 現在実装の棚卸し・完全版

> **このファイルが Single Source of Truth。spec.yaml や architecture-features.md を参照不要。**
>
> 最終確認: 2025-12-08
> 検証方法: settings.json, .claude/agents/*.md, .claude/skills/*/, .claude/commands/*.md を直接読み込み
>
> 関連ドキュメント:
> - [extension-system.md](./extension-system.md): Claude Code 公式リファレンスに基づく拡張システム体系
> - [plan/project.md](../plan/project.md): Macro 計画（DW-000 に最適化計画を含む）

---

## 1. Hooks 実装状況

### 1.1 settings.json 登録済み（実際の設定）

> ソース: `.claude/settings.json`

#### PreToolUse（*）- 全ツール対象
| Hook | timeout | 用途 |
|------|---------|------|
| init-guard.sh | 3000ms | 必須ファイル Read 前のツールブロック |
| check-main-branch.sh | 3000ms | main ブランチ警告 |

#### PreToolUse（Edit）- 編集ツール対象
| Hook | timeout | 用途 |
|------|---------|------|
| check-protected-edit.sh | 5000ms | 保護ファイル編集ブロック |
| playbook-guard.sh | 3000ms | playbook=null でブロック |
| check-file-dependencies.sh | 3000ms | 依存ファイル情報表示 |
| critic-guard.sh | 3000ms | done 更新前に critic 要求 |
| scope-guard.sh | 3000ms | スコープ外編集警告 |
| executor-guard.sh | 3000ms | executor 不一致警告 |

#### PreToolUse（Write）- 同上（Edit と同一）
| Hook | timeout | 用途 |
|------|---------|------|
| check-protected-edit.sh | 5000ms | 保護ファイル編集ブロック |
| playbook-guard.sh | 3000ms | playbook=null でブロック |
| check-file-dependencies.sh | 3000ms | 依存ファイル情報表示 |
| critic-guard.sh | 3000ms | done 更新前に critic 要求 |
| scope-guard.sh | 3000ms | スコープ外編集警告 |
| executor-guard.sh | 3000ms | executor 不一致警告 |

#### PreToolUse（Bash）
| Hook | timeout | 用途 |
|------|---------|------|
| pre-bash-check.sh | 10000ms | git commit 前チェック呼び出し |

#### SessionStart（*）
| Hook | timeout | 用途 |
|------|---------|------|
| session-start.sh | 5000ms | 状態表示、ガイダンス、pending 作成 |

#### PostToolUse（Task）
| Hook | timeout | 用途 |
|------|---------|------|
| log-subagent.sh | 3000ms | SubAgent 実行ログ記録 |

#### SessionEnd（*）
| Hook | timeout | 用途 |
|------|---------|------|
| session-end.sh | 5000ms | 状態保存、未 push 警告 |

### 1.2 ファイル存在するが未登録

> ⚠️ これらは settings.json に登録されておらず、実際には発火しない

| Hook | ファイルパス | 想定用途 | 状態 |
|------|------------|---------|------|
| check-coherence.sh | .claude/hooks/ | 整合性チェック | **未登録** |
| check-state-update.sh | .claude/hooks/ | state.md 更新強制 | **未登録** |
| check-manifest-sync.sh | .claude/hooks/ | マニフェスト同期 | **未登録**（手動用） |
| check-playbook-quality.sh | .claude/hooks/ | playbook 品質 | **未登録** |

### 1.3 Hook ファイル一覧（16個）

```
.claude/hooks/
├── init-guard.sh            ✓ 登録済み
├── check-main-branch.sh     ✓ 登録済み
├── check-protected-edit.sh  ✓ 登録済み
├── playbook-guard.sh        ✓ 登録済み
├── check-file-dependencies.sh ✓ 登録済み
├── critic-guard.sh          ✓ 登録済み
├── scope-guard.sh           ✓ 登録済み
├── executor-guard.sh        ✓ 登録済み
├── pre-bash-check.sh        ✓ 登録済み
├── session-start.sh         ✓ 登録済み
├── log-subagent.sh          ✓ 登録済み
├── session-end.sh           ✓ 登録済み
├── check-coherence.sh       ✗ 未登録
├── check-state-update.sh    ✗ 未登録
├── check-manifest-sync.sh   ✗ 未登録
└── check-playbook-quality.sh ✗ 未登録
```

### 1.4 優先度ツリー

```
P0 ─── 絶対守護（HARD_BLOCK）
│      ├── CLAUDE.md
│      └── .claude/protected-files.txt
│
P1 ─── セーフティ機構（BLOCK/WARN）
│      └── check-protected-edit.sh
│
P2 ─── 初期化強制
│      ├── session-start.sh (SessionStart)
│      └── init-guard.sh (PreToolUse *)
│
P3 ─── 状態連動（四つ組の整合性）
│      ├── check-main-branch.sh
│      ├── playbook-guard.sh
│      ├── scope-guard.sh
│      └── executor-guard.sh
│
P4 ─── 検証強制
│      ├── critic-guard.sh
│      ├── pre-bash-check.sh
│      ├── check-coherence.sh      ← 未登録
│      └── check-state-update.sh   ← 未登録
│
P5 ─── 監視・記録
       ├── check-file-dependencies.sh
       ├── log-subagent.sh
       └── session-end.sh
```

### 1.5 未活用の Hook イベント

| イベント | 公式仕様 | 現状 | 改善機会 |
|---------|---------|------|---------|
| **UserPromptSubmit** | プロンプト送信時 | 未使用 | INIT を早期強制 |
| **Stop** | エージェント停止時 | 未使用 | POST_LOOP 自動化 |
| **SubagentStop** | SubAgent 完了時 | 未使用 | critic 結果自動評価 |
| **PreCompact** | コンパクト前 | 未使用 | 重要情報保持指示 |
| **PermissionRequest** | 権限確認時 | 未使用 | カスタム権限判定 |
| **Notification** | 通知時 | 未使用 | 通知カスタマイズ |

---

## 2. SubAgents 実装状況

### 2.1 現在の SubAgents（9個）

> ソース: `.claude/agents/*.md` の frontmatter を直接読み込み

| Agent | model | tools | description キーワード |
|-------|-------|-------|---------------------|
| **critic** | haiku | Read, Grep, Bash | MUST BE USED before marking any task as done |
| **pm** | haiku | Read, Write, Edit, Grep, Glob | PROACTIVELY manages playbooks and project progress |
| **coherence** | haiku | Read, Bash, Grep | PROACTIVELY checks state.md and playbook consistency |
| **state-mgr** | haiku | Read, Edit, Write, Grep, Bash | AUTOMATICALLY manages state.md, playbook operations |
| **reviewer** | haiku | Read, Grep, Glob, Bash | Use this agent for code and design reviews |
| **health-checker** | haiku | Read, Grep, Glob, Bash | システム状態の定期監視 |
| **plan-guard** | haiku | Read, Grep, Glob | PROACTIVELY checks 3-layer plan coherence |
| **setup-guide** | sonnet | Read, Write, Edit, Bash, Grep, Glob | AUTOMATICALLY guides setup process |
| **beginner-advisor** | haiku | Read | AUTOMATICALLY explains technical terms with metaphors |

### 2.2 SubAgents 詳細

#### critic
```yaml
file: .claude/agents/critic.md
description: MUST BE USED before marking any task as done. Evaluates done_criteria with evidence-based judgment. Prevents self-reward fraud through critical thinking.
model: haiku
tools: Read, Grep, Bash
trigger: done 判定前（必須）
enforcement: 複合的防御（構造的ブロック困難）
  - CLAUDE.md LOOP（行動ルール MUST）
  - critic-guard.sh（視覚的警告）
```

#### pm
```yaml
file: .claude/agents/pm.md
description: PROACTIVELY manages playbooks and project progress. Creates playbook when missing, tracks phase completion, manages scope. Says NO to scope creep.
model: haiku
tools: Read, Write, Edit, Grep, Glob
trigger: playbook=null, Phase 完了, スコープ外要求
機能:
  - 計画の導出（Plan Derivation）
  - playbook 作成
  - 進捗管理
  - スコープ管理（NO と言う）
```

#### coherence
```yaml
file: .claude/agents/coherence.md
description: PROACTIVELY checks state.md and playbook consistency before git commit. Detects focus mismatch and forbidden state transitions.
model: haiku
tools: Read, Bash, Grep
trigger: commit 前、整合性確認
```

#### state-mgr
```yaml
file: .claude/agents/state-mgr.md
description: AUTOMATICALLY manages state.md, playbook operations, and layer structure. Use for focus switching, state transitions, and playbook phase updates.
model: haiku
tools: Read, Edit, Write, Grep, Bash
trigger: focus 切替、状態遷移
```

#### reviewer
```yaml
file: .claude/agents/reviewer.md
description: Use this agent for code and design reviews. Evaluates code quality, design patterns, and best practices. Provides constructive feedback for improvements.
model: haiku
tools: Read, Grep, Glob, Bash
trigger: 手動呼び出し
⚠️ PROACTIVELY/AUTOMATICALLY なし → 自動委譲されにくい
```

#### health-checker
```yaml
file: .claude/agents/health-checker.md
description: システム状態の定期監視。state.md/playbook の整合性、git 状態、ファイル存在確認などを行う。
model: haiku
tools: Read, Grep, Glob, Bash
trigger: 手動呼び出し
⚠️ 日本語 description → 自動委譲されにくい可能性
```

#### plan-guard
```yaml
file: .claude/agents/plan-guard.md
description: PROACTIVELY checks 3-layer plan coherence at session start. Rejects or reconfirms when no plan exists or user prompt is unrelated to existing plan. LLM-led session flow.
model: haiku
tools: Read, Grep, Glob
trigger: セッション開始、プロンプト受信
```

#### setup-guide
```yaml
file: .claude/agents/setup-guide.md
description: AUTOMATICALLY guides setup process when focus.current=setup. Conducts hearing, environment setup, and Skills generation. Does not ask unnecessary questions.
model: sonnet  # 唯一の sonnet
tools: Read, Write, Edit, Bash, Grep, Glob
trigger: focus.current=setup
```

#### beginner-advisor
```yaml
file: .claude/agents/beginner-advisor.md
description: AUTOMATICALLY explains technical terms with metaphors when beginner-level questions are detected. Proactively simplifies complex concepts.
model: haiku
tools: Read
trigger: 初心者質問検出、重要タイミング
```

---

## 3. Skills 実装状況

### 3.1 現在の Skills（9個）

> ソース: `.claude/skills/*/SKILL.md` または `skill.md` を直接読み込み

| Skill | ファイル名 | frontmatter | 状態 |
|-------|----------|-------------|------|
| **state** | SKILL.md | ✓ あり | 正常 |
| **plan-management** | SKILL.md | ✓ あり | 正常 |
| **context-management** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **execution-management** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **learning** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **frontend-design** | SKILL.md | ✗ なし | ⚠️ 要修正 |
| **lint-checker** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |
| **test-runner** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |
| **deploy-checker** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |

### 3.2 Skills 詳細

#### 正常な Skills

```yaml
state:
  name: state
  description: このワークスペースの state.md 管理、playbook 運用、レイヤー構造の専門知識。

plan-management:
  name: plan-management
  description: Multi-layer planning and playbook management. Use when creating playbooks, transitioning phases, or managing plan hierarchy. Triggers on "plan", "playbook", "phase", "roadmap", "milestone" keywords.

context-management:
  name: context-management
  description: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。
  triggers:
    - /compact を実行する前
    - コンテキストが 80% を超えたとき
    - セッション終了時

execution-management:
  name: execution-management
  description: 並列実行制御とリソース配分のガイドライン。タスク実行の最適化を支援。
  triggers:
    - 複数タスクを同時に実行するとき
    - コンテキストが逼迫しているとき

learning:
  name: learning
  description: 失敗パターンの記録・学習。過去の失敗から学び、同じ問題を繰り返さない。
  triggers:
    - エラーが発生したとき
    - critic が FAIL を返したとき
```

#### 問題のある Skills

```yaml
frontend-design:
  file: .claude/skills/frontend-design/SKILL.md
  問題: frontmatter なし
  対策: YAML frontmatter を追加する

lint-checker:
  file: .claude/skills/lint-checker/skill.md
  問題:
    1. ファイル名が小文字（公式仕様は SKILL.md）
    2. frontmatter なし
  対策: SKILL.md にリネーム + frontmatter 追加

test-runner:
  file: .claude/skills/test-runner/skill.md
  問題: 同上
  対策: 同上

deploy-checker:
  file: .claude/skills/deploy-checker/skill.md
  問題: 同上
  対策: 同上
```

---

## 4. Commands 実装状況

### 4.1 現在の Commands（7個）

> ソース: `.claude/commands/*.md`

| Command | ファイル | 用途 | 関連 Agent |
|---------|---------|------|-----------|
| /crit | crit.md | done_criteria 達成状況チェック | critic |
| /playbook-init | playbook-init.md | 新しいタスク開始フロー | pm |
| /lint | lint.md | 整合性チェック実行 | coherence |
| /focus | focus.md | レイヤーフォーカス切替 | state-mgr |
| /test | test.md | done_criteria テスト実行 | - |
| /rollback | rollback.md | Git ロールバック | - |
| /state-rollback | state-rollback.md | state.md バックアップ・復元 | - |

### 4.2 不足している Commands

```yaml
提案:
  - /health: health-checker 呼び出し
  - /review: reviewer 呼び出し
  - /plan: plan-guard 呼び出し
```

---

## 5. Git 操作自律化

> **四つ組（state-playbook-git-branch）の整合性を自動で維持する仕組み**

### 5.1 ブランチ保護フロー

```
                    ┌─────────────────────────────────────┐
                    │          PreToolUse(*)              │
                    │        check-main-branch.sh         │
                    └─────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
              focus=setup     focus=product   focus=workspace
                    │               │               │
                 許可            許可          main ブランチ?
                                                    │
                                            ┌───────┴───────┐
                                           YES              NO
                                            │               │
                                      ブロック(exit 2)    許可
                                            │
                                   「git checkout -b」を促す
```

#### check-main-branch.sh の詳細

```yaml
発火: PreToolUse(*)
対象: Edit, Write, Bash（git checkout/switch/branch は除外）
許可ツール: Read, Grep, Glob（読み取りは常に許可）

条件判定:
  focus=setup|product|plan-template: main でも許可（新規ユーザー用）
  focus=workspace:
    main/master ブランチ → exit 2（ブロック）
    それ以外 → 許可

例外:
  - state.md への Edit は許可（デッドロック回避）
  - git checkout/switch/branch は許可（ブランチ切り替え用）
```

### 5.2 コミット前自動チェック

```
                    ┌─────────────────────────────────────┐
                    │          PreToolUse(Bash)           │
                    │          pre-bash-check.sh          │
                    └─────────────────────────────────────┘
                                    │
                          "git commit" を検出?
                                    │
                            ┌───────┴───────┐
                           YES              NO
                            │               │
                    ┌───────┴───────┐     通過
                    │               │
            回帰テスト実行     整合性チェック
   .claude/tests/regression-test.sh    │
                    │               │
                 FAIL?          check-coherence.sh
                    │           check-state-update.sh
                 exit 1              │
                (ブロック)        警告表示
```

#### pre-bash-check.sh の詳細

```yaml
発火: PreToolUse(Bash)
トリガー: "git commit" パターン検出

実行内容:
  1. 保護ファイル書き込み検出:
     - HARD_BLOCK: CLAUDE.md, .claude/protected-files.txt
     - BLOCK (strict mode): settings.json, hooks/, plan/template/

  2. 回帰テスト（存在する場合）:
     - .claude/tests/regression-test.sh を実行
     - 失敗 → exit 1（コミットブロック）

  3. 整合性チェック:
     - check-coherence.sh を呼び出し
     - check-state-update.sh を呼び出し
```

#### check-coherence.sh の詳細

```yaml
呼び出し元: pre-bash-check.sh（git commit 時）
登録状況: ⚠️ settings.json 未登録（手動/間接呼び出しのみ）

チェック項目:
  1. 全レイヤーの state と playbook.phases の整合性
     - state=pending なのに done phases がある → ERROR
     - state=done なのに pending phases がある → ERROR

  2. ブランチ整合性
     - playbook.branch と現在のブランチが一致するか
     - 不一致 → ERROR + exit 2

  3. focus 矛盾検出
     - staged ファイルが focus.current の editable 範囲外 → WARN

  4. critic 強制
     - state: done への変更 + self_complete: false → exit 2（ブロック）

  5. コンテキスト管理リマインダー
     - Phase 完了時に /context 確認を促す
```

#### check-state-update.sh の詳細

```yaml
呼び出し元: pre-bash-check.sh（git commit 時）
登録状況: ⚠️ settings.json 未登録

動作:
  - state.md が staged されていない場合 → 警告（ブロックなし）
  - 「state.md を更新してください」と表示
```

### 5.3 セッションライフサイクル

```
SessionStart                                              SessionEnd
    │                                                         │
    ▼                                                         ▼
session-start.sh                                      session-end.sh
    │                                                         │
    ├── 未コミット変更警告                                     ├── 未コミット変更チェック
    ├── playbook 有無チェック                                 ├── 四つ組整合性チェック
    ├── INIT ガイダンス表示                                   ├── critic リマインド
    └── session_tracking.last_start 更新                      ├── 未 push コミット検出
                                                              └── session_tracking.last_end 更新
```

#### session-end.sh の詳細

```yaml
発火: SessionEnd(*)

自動更新（LLM 依存なし）:
  - session_tracking.last_end: タイムスタンプ
  - session_tracking.uncommitted_warning: true/false

チェック項目:
  1. 未コミット変更数
  2. playbook-branch 整合性
  3. layer.state と playbook.phases の整合性
  4. 未 push コミット数（git fetch → 比較）

出力:
  - [OK] / [WARNING] のサマリー
  - 次セッション開始前の対処を促す
```

### 5.4 CLAUDE.md のルール連携

```yaml
INIT フェーズ 2:
  - git rev-parse --abbrev-ref HEAD（ブランチ確認）
  - git status -sb（変更確認）
  - main ブランチ → 新ブランチ作成を促す

CORE:
  - git_branch_sync: 1 playbook = 1 branch

POST_LOOP:
  - 残タスクあり → git checkout -b feat/{next-task}
  - 新 playbook 作成 → state.md 更新 → LOOP 継続

[自認] 出力:
  - branch: 現在のブランチ名
  - git_status: clean | modified | untracked
```

### 5.5 四つ組の連動図

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     四つ組（Four-Tuple Coherence）                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   state.md          playbook            git branch         CLAUDE.md    │
│   (focus.current)   (active_playbooks)  (HEAD)             ([自認])     │
│        │                 │                  │                   │        │
│        └────────────────┬┴──────────────────┴───────────────────┘        │
│                         │                                                │
│              ┌──────────┴──────────┐                                     │
│              │    整合性チェック    │                                     │
│              │ check-coherence.sh  │                                     │
│              └──────────┬──────────┘                                     │
│                         │                                                │
│      ┌──────────────────┼──────────────────┐                             │
│      │                  │                  │                             │
│  branch 不一致      state 矛盾       focus 外編集                         │
│      │                  │                  │                             │
│   ERROR              ERROR              WARN                             │
│  (exit 2)           (exit 2)         (警告のみ)                          │
│                                                                          │
│   → コミットブロック      → コミットブロック     → 注意喚起                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.6 Git 自律化のまとめ

| フェーズ | Hook/ルール | チェック内容 | 強制度 |
|---------|------------|-------------|--------|
| セッション開始 | session-start.sh | 未コミット警告、playbook 有無 | visual |
| ブランチ操作 | check-main-branch.sh | main ブランチ保護 | structural (exit 2) |
| コード変更 | playbook-guard.sh | playbook なしブロック | structural (exit 2) |
| コミット前 | pre-bash-check.sh | 回帰テスト、整合性 | structural (exit 1/2) |
| コミット前 | check-coherence.sh | 四つ組整合性、critic 強制 | structural (exit 2) |
| セッション終了 | session-end.sh | 未 push、整合性サマリー | visual |

---

## 6. 失敗シナリオと防御機構

> **LLM が暴走するシナリオとその防御機構**

### 6.1 自己報酬詐欺（critic バイパス）

```yaml
攻撃: critic を呼ばずに done 判定
症状: 証拠なしで Phase を done に変更

防御機構:
  - critic-guard.sh: done 更新前に警告（settings.json 登録済み）
  - CLAUDE.md LOOP: 行動ルールで MUST
  - playbook-format.md: double_check フラグ

限界: 構造的ブロックではなく警告のみ
```

### 6.2 計画乖離（DRIFT 無視）

```yaml
攻撃: project.md と無関係な作業を実行
症状: スコープ際限なく拡大

防御機構:
  - plan-guard SubAgent: 計画との整合性チェック
  - scope-guard.sh: done_when/done_criteria 変更警告
```

### 6.3 保護ファイル突破

```yaml
攻撃: admin モードで CLAUDE.md を書き換え
症状: ガバナンスルール消失

防御機構:
  - check-protected-edit.sh: HARD_BLOCK（admin でも警告）
  - protected-files.txt: BLOCK リスト定義
```

### 6.4 状態遷移スキップ

```yaml
攻撃: pending → done を直接実行
症状: 設計なし実装、バグ蓄積

防御機構:
  - check-coherence.sh（⚠️ 未登録）
  - CLAUDE-ref.md STATE MACHINE

限界: check-coherence.sh が settings.json に未登録
```

### 6.5 executor 無視

```yaml
攻撃: executor: codex の Phase を Claude が実行
症状: 専門性未活用、品質低下

防御機構:
  - executor-guard.sh: executor 不一致警告（settings.json 登録済み）
```

---

## 7. 設計原則

### 7.1 Hooks vs SubAgents vs Skills

```
判断フロー:

Q1: 構造的ブロック（exit 2）が必要?
  YES → Hooks (PreToolUse)
  NO  → Q2

Q2: LLM の判断・推論が必要?
  YES → SubAgents
  NO  → Q3

Q3: 常に参照可能な知識ベース?
  YES → Skills
  NO  → Hooks (SessionStart/End)
```

### 7.2 enforcement レベル

```yaml
structural:  # LLM が破れない
  - check-protected-edit.sh (exit 2)
  - init-guard.sh (exit 2)
  - playbook-guard.sh (exit 2)
  - check-main-branch.sh (exit 2 可能)

guideline:   # LLM 遵守に依存
  - CLAUDE.md のルール
  - critic 必須化

visual:      # 視覚的インパクト
  - session-start.sh の警告ボックス
  - critic-guard.sh の警告

passive:     # ブロックしない
  - log-subagent.sh
  - session-end.sh
  - check-file-dependencies.sh
```

### 7.3 ルール vs 構造

```
ルール（弱い）:
  「〇〇してはいけない」と書いてある
  → Claude が無視すれば終わり

構造（強い）:
  Hook が exit 2 でブロック
  → Claude が無視しようとしても物理的に不可能

設計原則:
  - 重要なルールは Hook で強制
  - Claude の善意に依存しない
  - 「うっかり」を許さない
```

---

## 8. 問題点サマリー

### 8.1 未登録 Hooks

| Hook | 状態 | 影響 |
|------|------|------|
| check-coherence.sh | 未登録 | 整合性チェックが自動実行されない |
| check-state-update.sh | 未登録 | state.md 更新強制が機能しない |

### 8.2 Skills のファイル名・frontmatter 問題

| Skill | 問題 | 対策 |
|-------|------|------|
| frontend-design | frontmatter なし | frontmatter 追加 |
| lint-checker | skill.md + frontmatter なし | SKILL.md にリネーム + frontmatter |
| test-runner | 同上 | 同上 |
| deploy-checker | 同上 | 同上 |

### 8.3 SubAgent の自動委譲問題

| Agent | 問題 | 対策 |
|-------|------|------|
| reviewer | PROACTIVELY/AUTOMATICALLY なし | description 改善 |
| health-checker | 日本語 description | 英語化検討 |

---

## 9. 最適化計画

### Phase 1: 高優先度（即効性あり）

1. **check-coherence.sh を settings.json に登録**
2. **check-state-update.sh を settings.json に登録**
3. **UserPromptSubmit Hook 追加**
4. **Stop Hook 追加**

### Phase 2: 中優先度（品質向上）

5. **Skills ファイル名修正**
   - lint-checker/skill.md → SKILL.md
   - test-runner/skill.md → SKILL.md
   - deploy-checker/skill.md → SKILL.md

6. **Skills frontmatter 追加**
   - frontend-design
   - lint-checker
   - test-runner
   - deploy-checker

7. **SubAgent description 最適化**
   - reviewer に PROACTIVELY 追加
   - health-checker 英語化

### Phase 3: 低優先度（拡張）

8. **SubagentStop Hook 追加**
9. **PreCompact Hook 追加**
10. **Command 追加**: /health, /review, /plan

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | Git 操作自律化セクション追加（Section 5）。spec.yaml/architecture-*.md 削除完了。 |
| 2025-12-08 | 実コードベース検証。spec.yaml/architecture-features.md 参照不要版に改訂。 |
| 2025-12-08 | spec.yaml 統合。優先度ツリー、非機能要件、詳細仕様を追加。 |
| 2025-12-08 | 初版作成。現状棚卸しとギャップ分析。 |
