# project.md

> **プロジェクトの根幹計画。setup 完了相当の状態から生成。**
> **playbook はこのファイルを参照して作成する。**

---

## meta

```yaml
project: workspace-optimization
created: 2025-12-12
type: automation
location: /Users/amano/Desktop/thanks4claudecode/
```

---

## vision

### ユーザーの意図

> Claude Code ワークスペースの最適化と改善。
>
> 新規ユーザーが迷わずセットアップでき、
> 既存機能が効率的に動作するワークスペースを実現する。

### 成功の定義

- setup フォルダのトークン数が 50% 以下に削減
- CATALOG.md が適切に分割または削減
- 新規セッションでセットアップフローが正常開始
- 全 setup Phase が正常動作
- ドキュメント構造が明確で迷わない

---

## tech_decisions

> **このワークスペースの技術選択**

### 言語

```yaml
language: Bash/Shell + Markdown + YAML
reason: |
  Claude Code の Hook システムは shell スクリプトで実装。
  計画・状態管理は Markdown + YAML で実装。
```

### フレームワーク

```yaml
frontend: none
backend: none
automation: Claude Code Hooks + SubAgents
reason: |
  プロダクトは Claude Code ワークスペース自体。
  Hooks + SubAgents + CLAUDE.md の三位一体アーキテクチャで構成。
```

### ライブラリ

```yaml
ui: none
state_management: state.md（YAML ベースの状態管理）
data_fetching: none
form: none
validation: critic SubAgent（done_criteria 検証）
auth: none
database: none
ai: Claude Code（Claude Opus 4.5）
```

### デプロイ

```yaml
platform: local
reason: |
  このワークスペースはローカルで動作。
  git によるバージョン管理、ブランチによる playbook 分離。
```

---

## non_functional_requirements

> **このワークスペースの非機能要件**

### 規模

```yaml
users: 1  # 開発者本人
data_volume: small  # ログ、設定ファイル
```

### パフォーマンス

```yaml
response_time: fast < 1s  # Hook 応答速度
concurrent_users: 1
```

### セキュリティ

```yaml
requires_auth: false
handles_pii: false
handles_payment: false
```

### 可用性

```yaml
downtime_tolerance: medium  # 開発環境のため
requires_backup: true  # git が backup
```

### 予算

```yaml
monthly_budget: free
initial_investment: none
```

### 期間

```yaml
target_release: flexible
mvp_deadline: flexible
```

---

## stack

```yaml
framework: Claude Code Hooks
language: Bash/Shell, Markdown, YAML
deploy: local
database: git
external_apis:
  - Claude API (via Claude Code)
```

---

## constraints

- セッション開始時の必須 Read 件数を最小化
- setup フォルダのサイズを削減
- 既存機能は全て保証
- 新規ユーザーを想定した UI/UX 改善

---

## decomposition

> **各 done_when を playbook に展開するための分解ガイド。pm SubAgent が参照して playbook を自動生成。**

```yaml
DW-001:
  summary: "setup フォルダのトークン数を 50% 以下に削減"
  playbook_summary: "playbook-setup.md のテコ入れと段階的スキップ機構の実装"

  phase_hints:
    - name: "現状分析"
      what: "setup フォルダの全ファイル構造を把握し、トークン数を測定"
    - name: "playbook-setup.md の最適化"
      what: "冗長な説明を削減し、リンク参照に変換"
    - name: "段階的スキップ機構"
      what: "既にセットアップ済みなら Phase をスキップする条件を追加"
    - name: "検証"
      what: "新規セッションで setup フロー動作確認"

  success_indicators:
    - "setup フォルダのトークン数が当初の 50% 以下"
    - "playbook-setup.md が 300KB 以下"
    - "新規セッション開始時に SETUP Phase をスキップ可能"
    - "全 Phase が正常動作"

DW-002:
  summary: "CATALOG.md を適切に分割または削減"
  playbook_summary: "CATALOG.md の内容を .claude/catalogs/ に分割し、参照構造を最適化"

  phase_hints:
    - name: "CATALOG 分析"
      what: "CATALOG.md の項目を分類（言語別、フレームワーク別、ライブラリ別）"
    - name: "分割戦略決定"
      what: "各カテゴリを個別ファイル化するか、セクション化するか判定"
    - name: "CATALOG 分割実装"
      what: "catalog-typescript.md, catalog-framework.md 等に分割"
    - name: "参照インデックス作成"
      what: "setup/CATALOG.md はインデックスのみとして簡略化"
    - name: "検証"
      what: "各 Phase で正しい Catalog を参照できるか確認"

  success_indicators:
    - "CATALOG.md が 100KB 以下の軽量インデックス化"
    - "言語別・フレームワーク別の詳細カタログが .claude/catalogs/ に存在"
    - "setup Phase で必要なカタログだけをロード"
    - "トークン使用量が削減される"

DW-003:
  summary: "新規セッションでセットアップフローが正常開始"
  playbook_summary: "INIT フローを最適化し、新規ユーザーが迷わずセットアップできる状態にする"

  phase_hints:
    - name: "INIT フロー分析"
      what: "session-start.sh から CLAUDE.md INIT セクションまでの流れを検証"
    - name: "冗長な Read 削減"
      what: "必須 Read のみを厳選（state.md, playbook, CLAUDE.md）"
    - name: "ガイダンス改善"
      what: "新規ユーザーへの指示を明確化し、迷わないようにする"
    - name: "consent-process 検証"
      what: "合意プロセスが正常に動作するか確認"
    - name: "エラーメッセージ改善"
      what: "Hook のエラーメッセージを新規ユーザーでもわかるように改善"

  success_indicators:
    - "session-start.sh が 3秒以内に完了"
    - "新規ユーザーが INIT フローで迷わない"
    - "consent-guard.sh が正常に動作"
    - "[自認] 出力が正確（空白がない、形式が正しい）"
    - "全 Hook が正常に発火"

DW-004:
  summary: "docs/ フォルダの構造を簡素化"
  playbook_summary: "現在実装・運用ルール・テンプレートへのアクセス経路を最適化"

  phase_hints:
    - name: "docs 構造分析"
      what: "docs/ フォルダの全ファイルを棚卸し、参照頻度を分析"
    - name: "アーカイブ候補特定"
      what: "古い分析・設計ドキュメントをアーカイブ対象として選定"
    - name: "参照経路最適化"
      what: "CLAUDE.md から @参照で呼び出せるようにする"
    - name: "ドキュメント整理"
      what: "アーカイブ、不要ファイル削除、README 更新"

  success_indicators:
    - "docs/ フォルダのファイル数が 30% 削減"
    - "docs/CLAUDE.md に参照ルールが明記"
    - "古いドキュメントが .archive/ 以下に移動"
    - "重要なドキュメント（current-implementation.md 等）は残存"
```

---

## milestones

- [x] project-thanks4claudecode を完了
- [ ] M1: setup フォルダのテコ入れ
  - [ ] playbook-setup.md の最適化
  - [ ] CATALOG.md の分割
  - [ ] トークン数を 50% 削減
  - [ ] 新規セッション INIT フロー改善
- [ ] M2: docs 構造の簡素化
- [ ] M3: ワークスペース最適化完了

---

## notes

### 参考・背景

- 前プロジェクト: project-thanks4claudecode-20251212（完了）
  - すべての Hook・SubAgent・Skill が 100% 発火確認済み
  - 1000パターンテストで全 PASS

### 最適化の方針

1. **トークン削減**: setup フォルダのサイズを半減
   - playbook-setup.md の説明を簡潔化
   - リンク参照に変換

2. **段階的スキップ**: 既セットアップユーザーはスキップ可能に
   - Phase ごとの条件分岐
   - setup 状態をチェックして必要な Phase のみ実行

3. **新規ユーザーガイド**: INIT フローの改善
   - 迷わない手順書
   - エラーメッセージを明確に

4. **ドキュメント整理**: 参照経路の最適化
   - 古い分析記録をアーカイブ
   - 必須ドキュメント（current-implementation.md）は保持

---

## 参照

| ファイル | 役割 |
|----------|------|
| plan/template/playbook-format.md | playbook テンプレート |
| CLAUDE.md | LLM 振る舞いルール |
| state.md | 現在地を示す Single Source of Truth |
| docs/current-implementation.md | 現在実装の棚卸し |
| setup/playbook-setup.md | セットアップ playbook（最適化対象） |
| setup/CATALOG.md | ライブラリカタログ（分割対象） |
