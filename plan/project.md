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

- id: M020
  name: "Claude Code CHANGELOG モニタリングシステム"
  description: |
    Claude Code は頻繁にアップデートされている（現在 v2.0.69）。
    新機能・Hook トリガー・設定オプション等を定期的に検出し、
    このリポジトリに取り込む仕組みを構築する。
    24時間キャッシュで公式リポジトリを監視し、新バージョン検出時に通知する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M019]
  priority: high
  playbooks: [playbook-m020-changelog-monitor.md]
  done_when:
    - [x] .claude/cache/ ディレクトリが作成されている
    - [x] changelog-checker.sh が SessionStart で発火する
    - [x] 24時間経過時のみ CHANGELOG を取得する
    - [x] /changelog コマンドで最新情報を表示できる
    - [x] 新バージョン検出時に通知が表示される

- id: M021
  name: "CHANGELOG サジェストシステム - 機能提案エンジン"
  description: |
    M020 で実装した CHANGELOG モニタリングを拡張。
    新バージョン検出時に、このリポジトリに関連する新機能を自動提案する。
    リポジトリプロファイル（使用技術、関心領域）を定義し、
    新機能とのマッチング、優先度付け、具体的な活用方法を提示する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M020]
  priority: high
  playbooks: [playbook-m021-changelog-suggest.md]
  done_when:
    - [x] repo-profile.json が作成され、リポジトリ特性が定義されている
    - [x] changelog-checker.sh がキーワード抽出とマッチングを行う
    - [x] 新バージョン通知に関連機能のサジェストが含まれる
    - [x] /changelog --suggest で詳細な適用可能性分析が表示される
    - [x] 優先度（高・中・低）で機能が分類される
  decomposition:
    playbook_summary: |
      CHANGELOG の新機能をこのリポジトリの特性に基づいて分析し、
      自動的に活用可能な機能を優先度付きで提案するシステム。
    phase_hints:
      - name: "リポジトリプロファイル定義"
        what: |
          .claude/cache/repo-profile.json を作成。
          このリポジトリが使用している機能（Hooks, SubAgents, Skills等）、
          関心領域（automation, validation, planning等）、
          優先度キーワードを定義。
      - name: "changelog-checker.sh の拡張"
        what: |
          CHANGELOG からキーワード抽出（静的解析）を実装。
          repo-profile.json とマッチングし、関連機能を検出。
          新バージョン通知メッセージに関連機能を追加。
      - name: "/changelog --suggest オプション実装"
        what: |
          /changelog コマンドに --suggest オプションを追加。
          LLM による詳細な適用可能性分析を実行。
          優先度付け（高・中・低）と具体的な活用方法を提示。
    success_indicators:
      - repo-profile.json に5つ以上の機能カテゴリが定義されている
      - changelog-checker.sh が3つ以上のキーワードマッチングを行う
      - サジェストメッセージに優先度と活用方法が含まれる
      - /changelog --suggest が実行可能である
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
│   ├── M005: achieved
│   ├── M006: achieved
│   ├── M020: achieved
│   └── M021: pending ← 次タスク
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
| 2025-12-13 | M021 追加: CHANGELOG サジェストシステム - 機能提案エンジン |
| 2025-12-13 | M020 追加: Claude Code CHANGELOG モニタリングシステム |
| 2025-12-13 | M005（StateInjection）達成。systemMessage で状態を自動注入。 |
| 2025-12-13 | 3層構造の自動運用システム設計。用語統一。milestone に ID 追加。 |
| 2025-12-10 | 初版作成。 |
