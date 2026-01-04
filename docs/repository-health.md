# repository-health.md

> **リポジトリ健全性の判定基準と抽出結果**
>
> 判定は証拠ベース（参照箇所 + 実行結果）で行う。

---

## 1. 判定基準

### 必須（required）

このファイルが存在しないと **コア契約のいずれかが破綻する**もの。

### 壊れている必須（required_broken）

必須だが **実行エラー/期待動作しない**もの。

### 不要（optional）

削除しても **コア契約が維持される**もの。

---

## 2. 証拠フォーマット

- **reference**: 参照箇所（ファイル/行）
- **evidence**: 実行結果（exit code + stdout/stderr）
- **decision**: required / required_broken / optional / undetermined

例:

```
component: .claude/hooks/pre-tool.sh
reference: .claude/settings.json:PreToolUse
evidence: bash -n .claude/hooks/pre-tool.sh (exit 0)
decision: required
```

---

## 3. 依存抽出手法

> hooks → skills → agents の実参照チェーンを起点に抽出する。

```
rg --no-filename "invoke_skill|source.*skill" .claude/hooks/
rg "subagent_type=" .claude/
rg -l "guards/|handlers/|agents/" .claude/skills/*/SKILL.md
```

- 参照切れは required_broken に分類
- 参照先は `test -f` などで実在確認する

---

## 4. fix-backlog 連携

- docs/fix-backlog.md を上位レイヤーとして包含する
- 未完了 PB は「修復対象一覧」に参照として紐付ける
- 新規発見は PB-29 以降として追記する

---

## 5. 抽出結果（Inventory）

> **注意**: ここから下は依存抽出後に更新する。

### Hooks

### Skills

### SubAgents

### Frameworks

### Docs

---

## 6. メンテナンス方針

> 分類確定後に「修復/削除/保留」を明記する。
