# golden-path Skill

> **Core Contract #1: Golden Path**
>
> タスク依頼 → pm → playbook 作成のワークフローを強制する

---

## 責務

```yaml
core_contract: "#1 Golden Path"
rule: タスク依頼を受けたら、返答を始める前に pm を呼ぶ
trigger: "作って/実装して/修正して/追加して" 等のタスク要求パターン
```

このSkillは以下を担当:
1. タスク開始フローの標準化
2. pm SubAgent のオーケストレーション
3. playbook 作成の強制

---

## ディレクトリ構造

```
golden-path/
├── SKILL.md          ← このファイル
├── workflow/
│   ├── task-start.sh     ← タスク開始フロー
│   └── playbook-init.sh  ← playbook 初期化
└── agents/
    └── pm.md             ← pm SubAgent
```

---

## 発火条件

- ユーザーがタスクを依頼した時
- playbook が null の状態で作業開始しようとした時
- prompt.sh（導火線）から呼び出される

---

## 使用方法

### CLI から直接呼び出し
```
/task-start
```

### SubAgent 経由
```
Task(subagent_type='pm', prompt='playbook を作成')
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義 |
| docs/4qv-architecture.md | アーキテクチャ設計書 |
| .claude/hooks/prompt.sh | State Injection（導火線） |
