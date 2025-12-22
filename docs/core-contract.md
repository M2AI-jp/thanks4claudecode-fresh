# Core Contract

> **この契約は admin モードでも回避不可。Hooks により構造的に強制される。**

---

## 1. Playbook Gate

### ルール

`state.md` の `playbook.active` が `null` の場合、**意味的変更を禁止**する。

### 意味的変更の定義

| 対象 | 例 |
|------|-----|
| コード | `*.ts`, `*.js`, `*.py`, `*.go` 等 |
| Hook | `.claude/hooks/*.sh` |
| 設定 | `.claude/settings.json`, `*.config.*` |
| 仕様 | `docs/*.md`（core-contract.md, admin-contract.md を含む） |

### 例外（常に許可）

| 対象 | 理由 |
|------|------|
| `state.md` | 状態管理の SSOT。セッション終了等で更新が必要 |
| `plan/playbook-*.md` | Bootstrap 例外。playbook 自体の作成が必要 |
| `plan/archive/**` | アーカイブ先。Admin Maintenance で許可 |

### 判定

```
IF playbook.active == null:
    IF target IN 例外リスト:
        ALLOW
    ELSE IF security == admin AND target IN maintenance_whitelist:
        ALLOW (Maintenance 権限)
    ELSE:
        BLOCK
```

---

## 2. HARD_BLOCK

### ルール

以下のファイルは **security モードに関係なく常に保護**される。

### 対象ファイル

```
CLAUDE.md
.claude/protected-files.txt
.claude/.session-init/pending
.claude/hooks/init-guard.sh
.claude/hooks/critic-guard.sh
.claude/hooks/scope-guard.sh
.claude/hooks/executor-guard.sh
.claude/hooks/playbook-guard.sh
```

### 判定

```
IF target IN HARD_BLOCK_LIST:
    BLOCK (admin でも回避不可)
```

---

## 3. Fail-Closed

### ルール

判定に必要な情報が取得できない場合、**通過させずにブロック**する。

### 例

| 状況 | 挙動 |
|------|------|
| `state.md` が存在しない | BLOCK |
| `jq` コマンドが無い | BLOCK |
| `git diff` が失敗 | BLOCK |
| `playbook.active` が読み取れない | BLOCK |

### 判定

```
IF 判定に必要な情報が取得不可:
    BLOCK (fail-closed)
```

---

## E2E テスト要件

以下のシナリオで Core Contract の動作を検証する。

### シナリオ A: playbook=null & non-admin

```yaml
given:
  - state.md: playbook.active = null
  - state.md: security = strict
expect:
  - Edit .claude/hooks/*.sh → BLOCK
  - Bash "echo 'x' > src/index.ts" → BLOCK
  - git add → BLOCK
```

### シナリオ D: HARD_BLOCK 検証

```yaml
given:
  - state.md: security = admin
expect:
  - Edit CLAUDE.md → BLOCK (admin でも)
  - Edit .claude/protected-files.txt → BLOCK
```
