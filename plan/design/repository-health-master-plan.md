# repository-health-master-plan.md

> **リポジトリ健全性メンテナンスの上位設計書**
>
> 目的: 「必要/壊れている/不要」の判定基準を先に確定し、依存抽出→分類→主要ドキュメント更新→メンテナンスまでの全体手順を定義する。

---

## 1. 目的

- 既存ドキュメントの古さ・参照切れ・壊れた必須を放置しない
- 「必要性」判断を証拠ベースに統一し、LLM 自己申告を排除する
- repository-map と ARCHITECTURE を実態に合わせて更新する

---

## 2. スコープ

### 対象（In）

- `.claude/hooks/*`
- `.claude/skills/*`
- `.claude/skills/*/agents/*`
- `.claude/frameworks/*`
- `docs/ARCHITECTURE.md`
- `docs/repository-map.yaml`
- `state.md`（SSOT の整合性確認のみ）

### 対象外（Out）

- `.archive/*`（履歴として保持、評価対象外）
- `node_modules/*`
- `tmp/*`
- 生成物（ログ、キャッシュ）

---

## 3. 定義

### 必須（required）

このファイルが存在しないと **コア契約のいずれかが破綻する**もの。
例: PreToolUse を担う hook が欠落している、playbook gate が動作しない 等。

### 壊れている必須（required_broken）

必須だが **実行するとエラーになる / 期待動作しない**もの。
修復対象として必ず列挙する。

### 不要（optional）

削除しても **コア契約が全て維持される**もの。
削除候補またはアーカイブ候補として扱う。

---

## 4. fix-backlog 連携

- docs/fix-backlog.md は本計画に包含する（上位レイヤー）
- 未完了 PB は「修復対象一覧」に参照として紐付ける
- 新規発見は PB-29 以降として追記する

---

## 5. 依存グラフ（参照チェーン）

```
.claude/settings.json
  └─ .claude/hooks/*.sh
       ├─ .claude/skills/*/guards/*.sh
       │    └─ scripts/contract.sh など
       └─ .claude/skills/*/handlers/*.sh
            └─ .claude/schema/* など
```

---

## 6. 証拠ルール

- **証拠はコマンド出力 + 参照箇所**で示す
- LLM の文章は証拠にしない
- 判定は PASS / FAIL / UNDETERMINED を明示

証拠例:
- `rg` で参照箇所を提示
- `bash -n` で構文検証
- 実行ログ（exit code + stderr）

---

## 7. ワークフロー

### Step A: 判定基準の確定

- 「必須/壊れている/不要」の判定基準を文書化
- 証拠フォーマットを固定

### Step B: 依存抽出（実参照ベース）

1. hooks → skills → agents の参照チェーンを抽出
2. 参照先ファイルの実在確認
3. 参照切れは「壊れている必須」に分類
4. 増分で進める（hooks → skills → docs の順）

### Step C: 分類と健全性判定

- required / required_broken / optional を分類
- 影響範囲（どの契約に影響するか）を付与

### Step D: ドキュメント更新

- `docs/repository-map.yaml` を最新化
- `docs/ARCHITECTURE.md` を分類結果に合わせて更新

### Step E: メンテナンス方針の確定

- 修復 / 削除 / 保留 を決定
- 進行中タスクは playbook に落とす

---

## 8. 成果物

| 成果物 | 目的 |
|--------|------|
| docs/repository-health.md | 判定基準・分類結果・メンテ方針 |
| docs/repository-map.yaml | 全ファイルの最新マップ |
| docs/ARCHITECTURE.md | 実態に即した構成説明 |

---

## 9. 進行ルール

- 先に基準、後で抽出（順序厳守）
- 全ての判定に証拠を付ける
- 迷ったら UNDETERMINED に倒す
