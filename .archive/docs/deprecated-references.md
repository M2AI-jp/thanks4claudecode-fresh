# 廃止された表記の参照一覧 (2025-12-18)

> このファイルは「古い表記」を含むファイルを記録する。
> 修正対象と、履歴として放置するものを区別する。

---

## 修正対象（現在使用中のファイル）

### 1. 廃止用語「Macro」を含むファイル

| ファイル | 行 | 内容 | 修正方法 |
|----------|-----|------|----------|
| plan/design/mission.md | - | Macro 計画 | project に置換 |
| plan/design/plan-chain-system.md | - | Macro チェック | project に置換 |
| plan/template/state-initial.md | - | Macro 計画 | project に置換 |
| setup/playbook-setup.md | - | Macro（project.md） | project に置換 |
| .claude/frameworks/playbook-review-criteria.md | - | Macro 計画 | project に置換 |

### 2. 廃止ファイル「architecture-*.md」への参照

| ファイル | 内容 | 修正方法 |
|----------|------|----------|
| plan/template/state-initial.md | architecture-*.md への参照 | 行を削除 |
| .claude/agents/reviewer.md | architecture-*.md への参照 | 行を削除 |
| AGENTS.md | architecture-*.md への参照 | 行を削除 |

### 3. 廃止用語「layer」を含むファイル

| ファイル | 内容 | 修正方法 |
|----------|------|----------|
| plan/template/state-initial.md | 4つのレイヤーを管理 | 全面書き換え必要 |
| plan/template/state-initial.md | ## layer: workspace | セクション削除 |

### 4. 古い focus 構造を含むファイル

| ファイル | 問題 | 修正方法 |
|----------|------|----------|
| plan/template/state-initial.md | 古い4層構造（plan-template/workspace/setup/product） | 現在の構造に更新 |

---

## 放置対象（履歴・ログ）

以下は過去の記録として保持。修正不要。

| ディレクトリ | 理由 |
|--------------|------|
| .claude/state-history/ | state.md の変更履歴 |
| .claude/logs/ | セッションログ |
| .claude/context/history.md | 変更履歴（参照用） |
| plan/archive/ | アーカイブ済み playbook |

---

## 優先度

### 高（誤作動の原因になりうる）

1. **plan/template/state-initial.md** - 新規ワークスペース作成時に使用される。古い構造がコピーされると問題。
2. **AGENTS.md** - LLM が参照する可能性がある。

### 中（参照される可能性がある）

3. **.claude/frameworks/playbook-review-criteria.md** - reviewer SubAgent が参照
4. **.claude/agents/reviewer.md** - reviewer SubAgent の定義
5. **setup/playbook-setup.md** - セットアップフロー

### 低（ほぼ参照されない）

6. **plan/design/mission.md** - 設計ドキュメント
7. **plan/design/plan-chain-system.md** - 設計ドキュメント

---

## 修正計画

### Phase p2 で実行する修正

1. plan/template/state-initial.md を現在の state.md 形式に更新
2. AGENTS.md から architecture-*.md への参照を削除
3. .claude/agents/reviewer.md から architecture-*.md への参照を削除
4. .claude/frameworks/playbook-review-criteria.md の Macro を project に置換
5. setup/playbook-setup.md の Macro を project に置換
6. plan/design/ の Macro を project に置換（低優先度）
