# golden-path Skill

> **Core Contract #1: Golden Path**
>
> Hook → Skill → SubAgent チェーン経由で playbook を作成する

---

## 責務

```yaml
core_contract: "#1 Golden Path"
rule: タスク依頼を受けたら、Skill(playbook-init) 経由で playbook を作成
trigger: "作って/実装して/修正して/追加して" 等のタスク要求パターン
chain: Hook(prompt.sh) → Skill(playbook-init) → pm SubAgent
```

このSkillは以下を担当:
1. タスク開始フローの標準化
2. pm SubAgent のオーケストレーション（Skill 経由）
3. playbook 作成の強制

### 禁止事項

```yaml
prohibited:
  - Task(subagent_type='pm') を直接呼ぶ
  - Hook/Skill チェーンをスキップする
```

---

## ディレクトリ構造

```
golden-path/
├── SKILL.md          ← このファイル
└── agents/
    ├── pm.md             ← pm SubAgent（playbook 管理）
    └── codex-delegate.md ← Codex 委譲 SubAgent

playbook-init/        ← 別の Skill（エントリーポイント）
└── SKILL.md          ← pm SubAgent への委譲を強制
```

---

## 発火条件

- ユーザーがタスクを依頼した時
- playbook が null の状態で作業開始しようとした時
- prompt.sh（導火線）から呼び出される

---

## 使用方法

### Skill 経由（推奨）
```
Skill(skill='playbook-init')
```

### CLI から直接呼び出し
```
/playbook-init
```

### ⚠️ 禁止パターン
```yaml
# これは NG - Skill 経由でなければならない
Task(subagent_type='pm', prompt='playbook を作成')
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義 |
| .claude/skills/playbook-init/SKILL.md | エントリーポイント Skill |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent |
| .claude/hooks/prompt.sh | State Injection（導火線） |
| docs/ARCHITECTURE.md | アーキテクチャ設計書 |
