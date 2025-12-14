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

- id: M015
  name: "フォルダ管理ルール検証テスト"
  description: |
    M014 で実装したフォルダ管理ルールとクリーンアップ機構の動作検証。
    1. tmp/ にテストファイルを生成
    2. 永続フォルダ（docs/）にも別途ファイルを生成
    3. playbook 完了時の cleanup-hook.sh 発火を確認
    4. tmp/ のファイルが削除され、永続ファイルは保持されることを検証
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M014]
  playbooks: [playbook-m015-folder-test.md]
  done_when:
    - [x] tmp/ にテストファイルが生成されている
    - [x] 永続フォルダにテストファイルが生成されている
    - [x] playbook 完了時に cleanup-hook.sh が発火している
    - [x] tmp/ のテストファイルが削除されている
    - [x] 永続ファイルは保持されている

- id: M016
  name: "リリース準備：自己認識システム完成"
  description: |
    リポジトリの完成度を高め、リリース可能な状態にする。
    1. repository-map.yaml の完全性（trigger・連鎖関係の明示）
    2. SubAgents/Skills の description 完全化
    3. コンテキスト保護の検証
    4. [理解確認] に失敗リスク分析を恒常的に組み込み
    5. 全体の整合性確認
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M015]
  playbooks: [playbook-m016-release-preparation.md]
  done_when:
    - [x] repository-map.yaml の全 Hook に trigger が明示されている
    - [x] Hook 間の連鎖関係が docs/ にドキュメント化されている
    - [x] SubAgents/Skills の description が完全化されている
    - [x] [理解確認] に失敗リスク分析が組み込まれている
    - [x] session-start.sh がコンテキスト汚染を自動防止している
    - [x] state.md / project.md / playbook の整合性が確認されている

# ============================================================
# M017-M023: 再定義（2025-12-14）
# ============================================================

- id: M017
  name: "仕様遵守の構造的強制"
  description: |
    「拡散」を抑止し「収束」を強制する仕組みを実装。
    state.md スキーマの単一定義源を作成し、Hook がそこを参照する形に統一。
  status: not_started
  depends_on: [M016]
  playbooks: []
  done_when:
    - [ ] .claude/schema/state-schema.sh が存在し source 可能
    - [ ] state-schema.sh に SECTION_* 定数と getter 関数が定義されている
    - [ ] Hook がハードコードではなくスキーマを参照している

- id: M018
  name: "3検証システム（technical/consistency/completeness）"
  description: |
    subtask 単位で 3 視点の検証を構造的に強制するシステム。
    - technical: 技術的に正しく動作するか
    - consistency: 他のコンポーネントと整合性があるか
    - completeness: 必要な変更が全て完了しているか
  status: not_started
  depends_on: [M017]
  playbooks: []
  done_when:
    - [ ] subtask-guard.sh が存在し実行可能
    - [ ] subtask-guard.sh に 3 検証（technical/consistency/completeness）のロジックがある
    - [ ] playbook-format.md に validations セクションが存在する

- id: M019
  name: "playbook 自己完結システム"
  description: |
    playbook を自己完結させる仕組みを構築。
    final_tasks によるアーカイブ前チェック、repository-map 更新。
  status: not_started
  depends_on: [M018]
  playbooks: []
  done_when:
    - [ ] archive-playbook.sh に final_tasks チェックが実装されている
    - [ ] playbook テンプレートに final_tasks 例が含まれている

- id: M020
  name: "archive-playbook.sh バグ修正"
  description: |
    archive-playbook.sh の ARCHIVE_DIR を plan/archive/ に修正し、
    完了済み playbook が正しくアーカイブされることを確認。
  status: not_started
  depends_on: [M019]
  playbooks: []
  done_when:
    - [ ] archive-playbook.sh の ARCHIVE_DIR が plan/archive/ を指している
    - [ ] archive-playbook.sh の構文が正しい（bash -n）

- id: M021
  name: "init-guard.sh デッドロック修正"
  description: |
    init-guard.sh で基本 Bash コマンドがブロックされる問題を修正。
    playbook=null 時でも sed/grep/cat/echo/ls/wc が許可される。
  status: not_started
  depends_on: [M020]
  playbooks: []
  done_when:
    - [ ] init-guard.sh に基本コマンド許可リスト（sed/grep/cat/echo/ls/wc）がある
    - [ ] git show コマンドが許可されている
    - [ ] session-start.sh に CORE セクションが存在する

- id: M022
  name: "SOLID原則に基づくシステム再構築"
  description: |
    SOLID原則（特に単一責任原則）に基づいてシステムを再構築。
    init-guard.sh を単一責任に分離し、各 Hook の責任をドキュメント化。
  status: not_started
  depends_on: [M021]
  playbooks: []
  done_when:
    - [ ] init-guard.sh が単一責任（必須ファイル Read 強制のみ）
    - [ ] playbook-guard.sh が playbook 存在チェック責任を持つ
    - [ ] docs/hook-responsibilities.md に全 Hook の責任が明示されている

- id: M023
  name: "Plan mode 活用ガイド"
  description: |
    Plan mode（think/ultrathink）と Named Sessions の活用ガイドを作成。
    複雑なタスクでの思考深化と、セッション管理を改善。
  status: not_started
  depends_on: [M022]
  playbooks: []
  done_when:
    - [ ] CLAUDE.md に think/ultrathink の使い分けが明記されている
    - [ ] docs/session-management.md が存在し /rename, /resume が記載されている
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
