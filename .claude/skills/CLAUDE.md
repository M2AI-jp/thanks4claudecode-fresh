# .claude/skills/

> **Skills - 特定の状況で参照される専門知識**

---

## 役割

Skills は特定の状況で必要になる専門知識やプロセス定義です。
SubAgents から呼び出されるか、直接 Skill ツールで呼び出されます。

---

## 呼び出し方法

```
Skill: "skill-name"
```

例: `Skill: "consent-process"` で合意プロセスの詳細を取得

---

## 利用可能な Skills

### ワークフロー系

| Skill | 役割 | トリガー |
|-------|------|----------|
| consent-process | 合意プロセス（[理解確認]） | playbook=null で新規タスク開始時 |
| post-loop | playbook 完了後の処理 | playbook の全 Phase が done |
| context-externalization | コンテキスト外部化 | Phase 完了時 |
| plan-management | 計画管理 | playbook 作成時 |

### 検証系

| Skill | 役割 | トリガー |
|-------|------|----------|
| lint-checker | 静的解析 | .ts/.tsx/.js/.jsx/.sh 変更時 |
| test-runner | テスト実行 | *.test.* / *.spec.* 変更時 |
| deploy-checker | デプロイ確認 | done_criteria に「デプロイ」含む時 |

### ガイド系

| Skill | 役割 | トリガー |
|-------|------|----------|
| context-management | /compact 最適化ガイド | コンテキスト管理時 |
| execution-management | 並列実行制御ガイド | タスク最適化時 |
| learning | 失敗パターン記録・学習 | エラー発生時 |

---

## Skill の構成

各 Skill は以下の構造を持ちます：
```
{skill-name}/
  skill.md      # Skill の定義（frontmatter + 内容）
```

### frontmatter 例

```yaml
name: consent-process
description: ユーザープロンプトの誤解釈防止
triggers:
  - playbook=null で新規タスク開始時
auto_invoke: false
```

---

## 連携

- **SubAgents** → Skills を内部で呼び出す
- **Hooks** → トリガー条件の検出
- **CLAUDE.md** → @参照で Skill にリンク
