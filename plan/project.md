# project.md

> **プロジェクトの根幹計画。Claude が3層構造（project → playbook → phase）を自動運用する。**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-10
status: active
```

---

## vision

```yaml
goal: "Claude Code の自律性と品質を継続的に向上させる"

principles:
  - 報酬詐欺防止（critic 必須）
  - 計画駆動開発（playbook 必須）
  - 構造的強制（Hooks）
  - 3層自動運用（project → playbook → phase）

success_criteria:
  - ユーザープロンプトなしで 1 playbook を完遂できる
  - compact 後も mission を見失わない
  - 次タスクを自動導出して開始できる
  - 全 Hook/SubAgent/Skill が動作確認済み
  - playbook 完了時に /clear タイミングを案内する
  - project.milestone が自動更新される
```

---

## milestones

```yaml
- id: M001
  name: "三位一体アーキテクチャ確立"
  status: achieved
  achieved_at: 2025-12-09
  playbooks:
    - playbook-reward-fraud-prevention.md

- id: M002
  name: "Self-Healing System 基盤実装"
  status: achieved
  achieved_at: 2025-12-10
  playbooks:
    - playbook-full-autonomy.md

- id: M003
  name: "PR 作成・マージの自動化"
  status: achieved
  achieved_at: 2025-12-10
  playbooks:
    - playbook-pr-automation.md

- id: M004
  name: "3層構造の自動運用システム"
  description: |
    project → playbook → phase の3層構造を確立し、
    Claude が主導で自動運用できるようにする。
    人間は意思決定とプロンプト提供のみ。
  status: achieved
  achieved_at: 2025-12-13 00:06:00
  depends_on: [M001, M002, M003]
  playbooks:
    - playbook-three-layer-system.md
  done_when:
    - [x] 用語が統一されている（Macro→project, layer廃止）
    - [x] playbook 完了時に project.milestone が自動更新される
    - [x] playbook 完了時に /clear 推奨がアナウンスされる
    - [x] 次 milestone から playbook が自動作成される

- id: M005
  name: "確実な初期化システム（StateInjection）"
  description: |
    UserPromptSubmit Hook を拡張し、state/project/playbook の状態を
    systemMessage として強制注入する。LLM が Read しなくても情報が届く。
  status: achieved
  achieved_at: 2025-12-13 01:20:00
  depends_on: [M004]
  playbooks:
    - playbook-state-injection.md
  done_when:
    - [x] systemMessage に focus/milestone/phase/playbook が含まれる
    - [x] systemMessage に project_summary/last_critic が含まれる
    - [x] /clear 後も最初のプロンプトで情報が注入される
    - [x] playbook=null の場合も正しく動作する

- id: M006
  name: "厳密な done_criteria 定義システム"
  description: |
    done_criteria の事前定義精度を向上させる。
    自然言語の曖昧な定義ではなく、検証可能な形式で定義し、
    「テストをクリアするためのテスト」という構造的問題を解消する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M005]
  playbooks: [playbook-strict-criteria.md]
  done_when:
    - [x] done_criteria が Given/When/Then 形式で定義される
    - [x] 各 criteria に test_command が紐付けられている
    - [x] 曖昧な表現（「動作する」「正しく」等）が検出・拒否される
  decomposition:
    playbook_summary: |
      done_criteria の定義精度を向上させるシステムを構築。
      「テストをクリアするためのテスト」から「テストで検証できる仕様」へ転換。
    phase_hints:
      - name: "done_criteria 検証ルール定義"
        what: |
          曖昧な表現を自動検出するルールセット（禁止パターン）を定義。
          Given/When/Then 形式での定義テンプレートを作成。
      - name: "test_command マッピング実装"
        what: |
          各 done_criteria に対応する test_command を自動マッピング。
          実行可能な検証コマンドを明示。
      - name: "critic による criteria レビュー機構"
        what: |
          playbook 作成時に critic が criteria 定義の品質をチェック。
          PASS/FAIL で曖昧さを検出・拒否。
    success_indicators:
      - done_criteria の曖昧表現が自動検出される
      - criteria: test_command が1:1で紐付けられている
      - critic が criteria 品質をチェックできる

- id: M014
  name: "フォルダ管理ルール確立 & クリーンアップ機構実装"
  description: |
    1. 全フォルダの役割を明確化（テンポラリ/永続）
    2. tmp/ フォルダを新設し、テンポラリファイルを統一配置
    3. playbook 完了時の自動クリーンアップ機構を実装
    4. フォルダ管理ルールをドキュメント化
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M006]
  playbooks: [playbook-m014-folder-management.md]
  done_when:
    - [x] 不要ファイルが .archive/ に移動されている
    - [x] tmp/ フォルダが新設され、.gitignore に登録されている
    - [x] .claude/hooks/cleanup-hook.sh が実装されている
    - [x] 全 playbook テンプレートに cleanup phase が追加されている
    - [x] docs/folder-management.md が作成されている
    - [x] project.md に参照が追加されている

# ============================================================
# M015-M023: 再定義・再検証対象（2025-12-14 リセット）
# ============================================================

- id: M015
  name: "フォルダ管理ルール検証テスト"
  description: |
    M014 で実装したフォルダ管理ルールとクリーンアップ機構の動作検証。
    tmp/ と永続フォルダ（docs/）の分離が正しく機能することを確認する。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M014]
  playbooks:
    - playbook-m015-folder-validation.md
  done_when:
    - [x] tmp/ ディレクトリが存在し .gitignore に登録されている
    - [x] cleanup-hook.sh が実行可能で構文エラーがない
    - [x] docs/folder-management.md が存在する

- id: M016
  name: "リリース準備：自己認識システム完成"
  description: |
    リポジトリの完成度を高め、リリース可能な状態にする。
    repository-map.yaml の完全性、コンテキスト保護、整合性確認。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M015]
  playbooks:
    - playbook-m016-release-preparation.md
  done_when:
    - [x] repository-map.yaml の全 Hook に trigger が明示されている（unknown が 0 個）
    - [x] CLAUDE.md に [理解確認] セクションが存在する
    - [x] state.md / project.md / playbook の整合性が確認されている

- id: M017
  name: "仕様遵守の構造的強制"
  description: |
    「拡散」を抑止し「収束」を強制する仕組みを実装。
    state.md スキーマの単一定義源を作成し、Hook がそこを参照する形に統一。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M016]
  playbooks:
    - playbook-m017-state-schema.md
  done_when:
    - [x] .claude/schema/state-schema.sh が存在し source 可能
    - [x] state-schema.sh に SECTION_* 定数と getter 関数が定義されている
    - [x] Hook がハードコードではなくスキーマを参照している

- id: M018
  name: "3検証システム（technical/consistency/completeness）"
  description: |
    subtask 単位で 3 視点の検証を構造的に強制するシステム。
    - technical: 技術的に正しく動作するか
    - consistency: 他のコンポーネントと整合性があるか
    - completeness: 必要な変更が全て完了しているか
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M017]
  playbooks:
    - playbook-m018-3validations.md
  done_when:
    - [x] subtask-guard.sh が存在し実行可能
    - [x] subtask-guard.sh に 3 検証（technical/consistency/completeness）のロジックがある
    - [x] playbook-format.md に validations セクションが存在する

- id: M019
  name: "playbook 自己完結システム"
  description: |
    playbook を自己完結させる仕組みを構築。
    final_tasks によるアーカイブ前チェック、repository-map 更新。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M018]
  playbooks:
    - playbook-m019-self-contained.md
  done_when:
    - [x] archive-playbook.sh に final_tasks チェックが実装されている
    - [x] playbook テンプレートに final_tasks 例が含まれている

- id: M020
  name: "archive-playbook.sh バグ修正"
  description: |
    archive-playbook.sh の ARCHIVE_DIR を plan/archive/ に修正し、
    完了済み playbook が正しくアーカイブされることを確認。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M019]
  playbooks:
    - playbook-m020-archive-bugfix.md
  done_when:
    - [x] archive-playbook.sh の ARCHIVE_DIR が plan/archive/ を指している
    - [x] archive-playbook.sh の構文が正しい（bash -n）

- id: M021
  name: "init-guard.sh デッドロック修正"
  description: |
    init-guard.sh で基本 Bash コマンドがブロックされる問題を修正。
    playbook=null 時でも sed/grep/cat/echo/ls/wc が許可される。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M020]
  playbooks:
    - playbook-m021-init-guard-fix.md
  done_when:
    - [x] init-guard.sh に基本コマンド許可リスト（sed/grep/cat/echo/ls/wc）がある
    - [x] git show コマンドが許可されている
    - [x] session-start.sh に CORE セクションが存在する

- id: M022
  name: "SOLID原則に基づくシステム再構築"
  description: |
    SOLID原則（特に単一責任原則）に基づいてシステムを再構築。
    init-guard.sh を単一責任に分離し、各 Hook の責任をドキュメント化。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M021]
  playbooks: [playbook-m022-solid-refactoring.md]
  done_when:
    - [x] init-guard.sh が単一責任（必須ファイル Read 強制のみ）
    - [x] playbook-guard.sh が playbook 存在チェック責任を持つ
    - [x] docs/hook-responsibilities.md に全 Hook の責任が明示されている

- id: M023
  name: "Plan mode 活用ガイド"
  description: |
    Plan mode（think/ultrathink）と Named Sessions の活用ガイドを作成。
    複雑なタスクでの思考深化と、セッション管理を改善。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M022]
  playbooks:
    - playbook-m023-plan-mode-guide.md
  done_when:
    - [x] CLAUDE.md に think/ultrathink の使い分けが明記されている
    - [x] docs/session-management.md が存在し /rename, /resume が記載されている

- id: M025
  name: "システム仕様の Single Source of Truth 構築"
  description: |
    Claude の仕様が分散している問題を解決。
    repository-map.yaml を拡張し、Claude の行動ルール・Hook 連鎖を統合。
    二重管理を排除し、1ファイル・1スクリプトで完結する Single Source of Truth を構築。
  status: achieved
  achieved_at: 2025-12-15
  depends_on: [M023]
  playbooks:
    - playbook-m025-system-specification.md
  done_when:
    - [x] generate-repository-map.sh に system_specification セクション生成機能が追加されている
    - [x] repository-map.yaml に Claude 行動ルール・Hook トリガー連鎖が含まれている
    - [x] 自動更新が 100% 安定（冪等性保証、原子的更新）
    - [x] INIT フロー全体で冗長がなく、効率的に自己認識できることが確認される

- id: M053
  name: "Multi-Toolstack Setup System + Admin Mode Fix"
  description: |
    1. security: admin で全ガードをバイパス（繰り返し発生していた問題を根本修正）
    2. 3 パターン（A/B/C）の Toolstack を実装し、executor を構造的に制御
    3. Codex を SubAgent 化し、コンテキスト膨張を防止
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M025]
  playbooks:
    - playbook-m053-multi-toolstack.md
  done_when:
    - [x] admin モードで全ガードがバイパスされる
    - [x] setup フローに toolstack 選択 Phase がある
    - [x] executor-guard.sh が toolstack に応じて制御する
    - [x] Codex が SubAgent 化されコンテキスト分離されている

- id: M056
  name: "playbook 完了検証システム + V12 チェックボックス形式"
  description: |
    報酬詐欺（done_when 未達成で achieved）を構造的に防止する。
    1. playbook 完了時に done_when を自動検証
    2. subtask 単位で `- [ ]` / `- [x]` で進捗を明示
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M053]
  playbooks:
    - playbook-m056-completion-verification.md
  done_when:
    - [x] playbook-format.md に完了検証フェーズ（p_final）が必須として追加されている
    - [x] archive-playbook.sh が done_when の test_command を再実行して検証する
    - [x] subtask-guard が final_tasks の status: done をブロックしない
    - [x] 既存の achieved milestone の done_when が実際に満たされているか再検証完了
    - [x] V12 チェックボックス形式が全コンポーネントに適用されている

- id: M057
  name: "Codex/CodeRabbit CLI 化 - MCP 誤設計の根本修正"
  description: |
    Codex と CodeRabbit が MCP サーバーとして誤設計されていた問題を根本修正。
    実際には両方とも CLI ツールとして存在しており、その仕様に合わせて
    全ドキュメント・SubAgent・Hook を一括更新する。
  status: not_started
  depends_on: [M056]
  playbooks: []
  done_when:
    - "[ ] .mcp.json から codex エントリが削除されている"
    - "[ ] docs/toolstack-patterns.md が MCP → CLI に全面書き換えされている"
    - "[ ] .claude/agents/codex-delegate.md が CLI ベースに修正されている"
    - "[ ] .claude/hooks/executor-guard.sh の MCP 参照が CLI に修正されている"
    - "[ ] plan/template/playbook-format.md の executor 説明が更新されている"
    - "[ ] .claude/CLAUDE-ref.md の MCP 参照が削除されている"
    - "[ ] setup/playbook-setup.md の MCP 設定が CLI に修正されている"
    - "[ ] repository-map.yaml が更新されている"
  decomposition:
    playbook_summary: |
      Codex/CodeRabbit を MCP から CLI 実装に転換し、全システムを一貫性のあるCLI構成に統一する。
    phase_hints:
      - name: "MCP 設定削除 & CLI 実装確認"
        what: |
          .mcp.json を確認し codex エントリを削除。
          CLI パスの確認（/Users/amano/.asdf/installs/nodejs/24.4.1/bin/codex 等）
      - name: "toolstack-patterns.md 書き換え"
        what: |
          MCP ベースの説明を CLI ベースに全面書き換え。
          Codex/CodeRabbit の CLI 使用法を明記。
      - name: "codex-delegate.md 修正"
        what: |
          SubAgent を MCP ではなく Bash CLI ベースに修正。
          Task call から Bash call への転換。
      - name: "Hook & template 一括更新"
        what: |
          executor-guard.sh、playbook-format.md、.claude/CLAUDE-ref.md を修正。
          全参照を MCP → CLI に統一。
      - name: "setup ドキュメント & repository-map 更新"
        what: |
          setup/playbook-setup.md の設定を修正。
          repository-map.yaml を自動更新。
    success_indicators:
      - .mcp.json に codex MCP エントリがない
      - docs/toolstack-patterns.md で CLI 使用法が明確
      - executor-guard.sh が CLI ベースで動作
      - 全コンポーネントが CLI 仕様に統一

```

---

## tech_stack

```yaml
framework: Claude Code Hooks System
language: Bash/Shell
deploy: local (git-based)
database: none (file-based: state.md, playbook, project.md)
```

---

## constraints

- Hook は exit code で制御（0=通過、2=ブロック）
- state.md が Single Source of Truth
- playbook なしで Edit/Write は禁止
- critic なしで phase 完了は禁止
- main ブランチでの直接作業は禁止
- 1 playbook = 1 branch
- テンポラリファイルは tmp/ に配置（playbook 完了時に自動削除）
- 完了した playbook は plan/archive/ にアーカイブ

---

## 3層構造

```
project (永続)
├── vision: 最上位目標
├── milestones[]: 中間目標
│   ├── M001: achieved
│   ├── M002: achieved
│   ├── M003: achieved
│   ├── M004: achieved
│   └── M005: achieved ← 最新完了
└── constraints: 制約条件

playbook (一時的)
├── meta.derives_from: M004  # milestone との紐付け
├── goal.done_when: milestone 達成条件
└── phases[]: 作業単位
    ├── p0: pending
    ├── p1: pending
    └── p2: pending

phase (作業単位)
├── done_criteria[]: 完了条件
├── test_method: 検証手順
└── status: pending | in_progress | done
```

---

## 自動運用フロー

```yaml
phase_complete:
  trigger: critic PASS
  action:
    - phase.status = done
    - 次の phase へ（または playbook 完了へ）

playbook_complete:
  trigger: 全 phase が done
  action:
    - playbook をアーカイブ
    - project.milestone を自動更新
      - status = achieved
      - achieved_at = now()
      - playbooks[] に追記
    - /clear 推奨をアナウンス
    - 次の milestone を特定（depends_on 分析）
    - pm で新 playbook を自動作成

project_complete:
  trigger: 全 milestone が achieved
  action:
    - project.status = completed
    - 「次の方向性を教えてください」と人間に確認
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M005（StateInjection）達成。systemMessage で状態を自動注入。 |
| 2025-12-13 | 3層構造の自動運用システム設計。用語統一。milestone に ID 追加。 |
| 2025-12-10 | 初版作成。 |
