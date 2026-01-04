# Archive Operation Rules

> **目的**: playbook 完了時のアーカイブ運用ルールを明文化
>
> **作成日**: 2025-12-09
> **playbook**: playbook-artifact-health.md p7

---

## 1. アーカイブ判定基準

### 1.1 アーカイブ条件（全て満たす必要あり）

| 条件 | 確認方法 |
|------|---------|
| 全 Phase の status が done | playbook 内の `status:` を確認 |
| state.md playbook.active に含まれていない | state.md を確認 |
| 現在進行中でない | Claude の作業状態を確認 |

### 1.2 アーカイブ禁止条件

以下の場合はアーカイブしない:

- Phase の一部が pending または in_progress
- state.md の playbook.active に登録されている
- setup/playbook-setup.md（テンプレートとして常に保持）

---

## 2. 自動検出フロー

```
1. playbook を Edit → archive-playbook.sh 発火
2. 全 Phase done を検出
3. state.md playbook.active をチェック
   └─ 含まれている → スキップ
   └─ 含まれていない → 「アーカイブ推奨」を出力
4. Claude が POST_LOOP に入る
5. POST_LOOP 行動 0.5 でアーカイブ実行
```

---

## 3. アーカイブ実行手順

### 3.1 自動実行（POST_LOOP 行動 0.5）

Claude が POST_LOOP で以下を実行:

```bash
# 1. アーカイブディレクトリ作成（なければ）
mkdir -p plan/archive

# 2. playbook を移動
mv plan/playbook-{name}.md plan/archive/

# 3. state.md 更新
# playbook.active を null に
```

### 3.2 手動実行

archive-playbook.sh の提案を見逃した場合:

```bash
# 1. 完了した playbook を確認
ls plan/playbook-*.md

# 2. 全 Phase が done か確認
grep "status:" plan/playbook-{name}.md

# 3. 手動でアーカイブ
mkdir -p plan/archive
mv plan/playbook-{name}.md plan/archive/

# 4. state.md を更新
# playbook.active: null

# 5. git 記録
git add -A && git commit -m "chore: archive playbook-{name}"
```

---

## 4. ロールバック手順

### 4.1 アーカイブの取り消し

```bash
# 1. アーカイブから復元
mv plan/archive/playbook-{name}.md plan/

# 2. state.md を更新
# playbook.active: plan/playbook-{name}.md

# 3. git 記録
git add -A && git commit -m "chore: restore playbook-{name} from archive"
```

### 4.2 誤削除からの復元

```bash
# git 履歴から復元
git checkout HEAD~1 -- plan/playbook-{name}.md
```

---

## 5. state.md 更新ルール

### 5.1 アーカイブ時

```yaml
# 変更前
playbook:
  active: plan/playbook-{name}.md

# 変更後
playbook:
  active: null
```

### 5.2 変更履歴への記録

```markdown
| 日時 | 内容 |
|------|------|
| 2025-XX-XX | **playbook-{name} 完了・アーカイブ**: 全N Phase完了。plan/archive/ に退避。 |
```

---

## 6. 関連ファイル

| ファイル | 役割 |
|---------|------|
| .claude/skills/playbook-gate/workflow/archive-playbook.sh | 自動検出 Hook |
| CLAUDE.md POST_LOOP | アーカイブ実行ルール |
| state.md playbook.active | 進行中 playbook 管理 |
| plan/archive/ | アーカイブ先フォルダ |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。playbook-artifact-health.md p7 で作成。 |
