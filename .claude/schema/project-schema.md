# project.md スキーマ定義

> **project.md のフォーマット定義。肥大化防止と長期 goal 保護のためのルールを含む。**

---

## 概要

project.md はプロジェクトの長期計画を管理するファイル。以下の問題を解決するためにスキーマを定義:

1. **肥大化問題**: 達成済み milestone が蓄積し、ファイルが巨大化する
2. **goal 保護問題**: compact 時に長期 goal が失われるリスクがある
3. **構造の曖昧さ**: フィールドの意味や制約が不明確

---

## スキーマ定義

### 必須セクション

```yaml
# project.md

## meta
project: <string>         # プロジェクト識別子（必須）
created: <date>           # 作成日（YYYY-MM-DD）
status: <enum>            # active | paused | completed

## vision
goal: <string>            # 1行の長期目標（必須、prompt-guard.sh で注入される）
principles:               # 設計原則（3-5項目推奨）
  - <string>
success_criteria:         # 最終成功基準（3-7項目推奨）
  - <string>

## active_milestones
# 現在進行中の milestone（最大5件）
- id: <string>            # M001, M002, ... 形式
  name: <string>          # 1行の名前
  status: <enum>          # not_started | in_progress | achieved
  depends_on: [<id>]      # 依存 milestone のリスト（オプション）
  done_when:              # 完了条件（3-7項目推奨）
    - <string>

## achieved_milestones
# 達成済み milestone（1行サマリー形式）
- <id>: <summary>         # 例: "M001: 三位一体アーキテクチャ確立 (2025-12-09)"

## constraints
- <string>                # 制約条件（5-10項目推奨）

## focus_areas
- <string>                # 現在の注力領域（1-3項目）
```

---

## フィールド詳細

### vision.goal

```yaml
定義: プロジェクトの最上位目標（1行）
制約:
  - 1行（100文字以内推奨）
  - 具体的で検証可能な形式
  - prompt-guard.sh が systemMessage に注入
  - pre-compact.sh が additionalContext で保護
例:
  - "Claude Code の自律性と品質を継続的に向上させる"
  - "企業の経費精算業務を自動化する SaaS を構築する"
禁止:
  - 曖昧な表現（"良いアプリを作る"）
  - 複数目標の混在（"Aをして、Bもして、Cもする"）
```

### active_milestones

```yaml
定義: 現在進行中の milestone（最大5件）
制約:
  - 最大5件（6件以上は分割または優先度見直し）
  - status が achieved になったら achieved_milestones に移動
  - done_when は検証可能な形式（状態形式、チェックボックス）
フィールド:
  id: M001, M002, ... 形式（ユニーク）
  name: 1行の簡潔な名前
  status: not_started | in_progress | achieved
  depends_on: 依存 milestone の id リスト（オプション）
  done_when: 完了条件（3-7項目推奨）
```

### achieved_milestones

```yaml
定義: 達成済み milestone（1行サマリー形式）
制約:
  - 1 milestone = 1行（肥大化防止）
  - 詳細は plan/archive/ の playbook を参照
形式:
  - "<id>: <name> (<achieved_at>)"
  - 例: "M001: 三位一体アーキテクチャ確立 (2025-12-09)"
圧縮ルール:
  1. status: achieved になった milestone を 1行に圧縮
  2. done_when は削除（playbook に記録済み）
  3. playbooks は削除（plan/archive/ に存在）
  4. description は削除（name に要約）
```

### constraints

```yaml
定義: プロジェクト全体の制約条件
制約:
  - 5-10項目推奨
  - 技術的制約、運用制約、ビジネス制約を含む
例:
  - Hook は exit code で制御（0=通過、2=ブロック）
  - state.md が Single Source of Truth
  - playbook なしで Edit/Write は禁止
```

### focus_areas

```yaml
定義: 現在の注力領域
制約:
  - 1-3項目
  - 短期的な方向性を示す
  - milestone と連動
例:
  - "理解確認システムの再実装"
  - "project.md の肥大化防止"
```

---

## 状態遷移ルール

### milestone 状態遷移

```
not_started → in_progress → achieved
                  ↓
              (失敗時)
                  ↓
              not_started に戻る
```

### achieved 時の処理

```yaml
1. playbook が全 phase done で完了
2. archive-playbook.sh が playbook をアーカイブ
3. project.md の milestone を更新:
   - active_milestones から削除
   - achieved_milestones に 1行サマリーを追加
4. 次の milestone を特定:
   - depends_on が解決された milestone を選択
   - pm が新 playbook を作成
```

---

## 1行圧縮サンプル

### 圧縮前（active_milestones）

```yaml
- id: M001
  name: "三位一体アーキテクチャ確立"
  status: achieved
  achieved_at: 2025-12-09
  playbooks:
    - playbook-reward-fraud-prevention.md
  done_when:
    - "[x] .claude/hooks/ ディレクトリに Hook スクリプトが存在する"
    - "[x] .claude/agents/ ディレクトリに SubAgent 定義が存在する"
    - "[x] CLAUDE.md に三位一体の説明が記載されている"
    - "[x] .claude/settings.json に Hook が登録されている"
```

### 圧縮後（achieved_milestones）

```yaml
- M001: 三位一体アーキテクチャ確立 (2025-12-09)
```

---

## 長期 goal 保護

### prompt-guard.sh による注入

```yaml
目的: セッション開始時に vision.goal を systemMessage に注入
実装:
  - project.md の vision.goal を抽出
  - State Injection メッセージに含める
  - Claude が常に長期 goal を認識できる
```

### pre-compact.sh による保護

```yaml
目的: compact 時に vision.goal を additionalContext で保護
実装:
  - snapshot.json に vision.goal を含める
  - compact 後の再開時に復元
  - 長期 goal の喪失を防止
```

---

## 移行ガイド

既存の project.md を新スキーマに移行する手順:

```yaml
1. achieved milestone を 1行サマリーに圧縮
   - done_when を削除
   - playbooks を削除
   - description を削除

2. in_progress/not_started を active_milestones に移動
   - 最大5件に絞る
   - 6件以上は depends_on で順序付け

3. focus_areas を追加
   - 現在の注力領域を 1-3項目で記述

4. constraints を整理
   - 5-10項目に絞る

5. vision.goal を 1行に要約
   - 100文字以内推奨
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| state.md | 現在の状態（focus, playbook, goal） |
| plan/template/playbook-format.md | playbook テンプレート |
| .claude/hooks/prompt-guard.sh | vision.goal 注入 |
| .claude/hooks/pre-compact.sh | vision.goal 保護 |
