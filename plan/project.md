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

- id: M007
  name: "システムアーキテクチャ可視化"
  description: |
    リポジトリ内の全 Hooks、SubAgents、Skills を
    発火タイミング別に整理し、入出力と依存関係を明示する。
    docs/feature-map.md として成果物を作成。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M006]
  playbooks: [playbook-system-architecture-map.md]
  done_when:
    - [x] docs/feature-map.md が存在する
    - [x] 全 Hook（29ファイル）が発火タイミング別に整理されている
    - [x] 各 Hook の入力（stdin JSON）・出力（exit code）が明示されている
    - [x] SubAgent 一覧（8種類）が記載されている
    - [x] Skill 一覧（13個）が記載されている
    - [x] ファイル間の依存関係が図解されている

- id: M008
  name: "Clear時コンテキスト継承 & Tech Stack & 5W1H理解確認"
  description: |
    1. /clear 推奨アナウンス時に「元のプロンプト」「成果物」「次のアクション」を
       明示し、clear 前後の混乱を防止する。
    2. project.md の tech_stack を人間にも読みやすい自然言語ドキュメントとして
       独立ファイル（docs/tech-stack.md）に展開する。
    3. [理解確認] 機能を 5W1H 形式で構造化し、理解の精度を向上させる。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M007]
  playbooks: [playbook-clear-context-enhancement.md]
  done_when:
    - [x] Clear時アナウンスに「元のプロンプト要約」が含まれる
    - [x] Clear時アナウンスに「成果物サマリー」が含まれる
    - [x] Clear時アナウンスに「ネクストアクション提案」が含まれる
    - [x] docs/tech-stack.md が存在し、自然言語で充実した説明がある
    - [x] [理解確認] が 5W1H 形式で出力される

- id: M009
  name: "Tech Stack 精査・不要ファイル削除・Core機能保護"
  description: |
    1. tech-stack.md を精査・拡充し、全 Hooks/SubAgents/Skills の
       機能・発火タイミング・依存関係を厳密に明文化する。
    2. リポジトリ内の不要ファイルを特定し、コンテキスト腐食を防止するため削除する。
    3. Core機能を厳選し、protected-files.txt に HARD_BLOCK として保護指定する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M008]
  playbooks: [playbook-tech-stack-refinement.md]
  done_when:
    - [x] tech-stack.md に全 Hooks の依存関係が明文化されている
    - [x] tech-stack.md に全 SubAgents/Skills の依存関係が明文化されている
    - [x] 不要ファイル削除候補リストが作成されている
    - [x] ユーザー承認後、不要ファイルが削除されている
    - [x] Core機能が特定され、protected-files.txt に追加されている

- id: M010
  name: "ドキュメント・コンポーネント監査"
  description: |
    tech-stack.md 以外の不要ドキュメント削除、非Core Hooks/SubAgents/Skills の評価・削除検討。
    リポジトリ全体のコンテキスト品質をさらに向上させ、参照されないファイルを整理する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M009]
  playbooks: [playbook-doc-audit-component-eval.md]
  done_when:
    - [x] ドキュメント参照状況の最終確認リストが作成されている
    - [x] 未参照ドキュメントがアーカイブに移動されている
    - [x] 非Core Hooks の評価が完了している
    - [x] 非Core SubAgents の評価が完了している
    - [x] 非Core Skills の評価が完了している
    - [x] Codex による第三者評価・最終レポートが作成されている
  decomposition:
    playbook_summary: |
      ドキュメント・コンポーネント監査を実施し、参照されないファイルを削除、
      非Core Hooks/SubAgents/Skills の必要性を評価・改善する。
    phase_hints:
      - name: "ドキュメント参照状況の最終確認・リスト作成"
        what: tech-stack.md を除く全ドキュメントの参照状況を確認し、リストを作成
      - name: "未参照ドキュメントをアーカイブに移動"
        what: 未参照ドキュメントを archive/ に移動し、削除せずに保管
      - name: "非Core Hooks の評価"
        what: 各 Hook のコード確認、使用頻度、代替手段の有無を評価
      - name: "非Core SubAgents の評価"
        what: 各 SubAgent の依存関係、使用状況を確認・評価
      - name: "非Core Skills の評価"
        what: 各 Skill の機能、使用可能性を確認・評価
      - name: "Codex による第三者評価・最終レポート"
        what: 削除予定ファイル・コンポーネントを Codex に提示し、第三者視点での評価・改善提案を取得
    success_indicators:
      - 参照されないドキュメントが特定される
      - 非Core コンポーネントの必要性が評価される
      - Codex による客観的な改善提案が得られる
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

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M005（StateInjection）達成。systemMessage で状態を自動注入。 |
| 2025-12-13 | 3層構造の自動運用システム設計。用語統一。milestone に ID 追加。 |
| 2025-12-10 | 初版作成。 |
