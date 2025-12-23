# access-control Skill

> **アクセス制御**
>
> 保護ファイル・ブランチ・Bash 契約のチェック

---

## 責務

このSkillは以下を担当:
1. HARD_BLOCK ファイルの保護（CLAUDE.md, protected-files.txt 等）
2. main ブランチでの直接作業禁止
3. 危険な Bash コマンドのブロック
4. Bash 契約の判定

---

## ディレクトリ構造

```
access-control/
├── SKILL.md              ← このファイル
├── guards/
│   ├── protected-edit.sh     ← 保護ファイル編集ブロック
│   ├── main-branch.sh        ← main ブランチ作業禁止
│   └── bash-check.sh         ← Bash 契約チェック
└── lib/
    └── contract.sh           ← 契約判定ロジック
```

---

## 発火条件

- 全ての Edit/Write ツール使用時（PreToolUse）
- 全ての Bash ツール使用時（PreToolUse）
- pre-tool.sh（導火線）から呼び出される

---

## ガード一覧

| ガード | 役割 | ブロック時の動作 |
|--------|------|------------------|
| protected-edit.sh | HARD_BLOCK ファイルへの編集をチェック | 保護対象なら BLOCK |
| main-branch.sh | main ブランチでの作業をチェック | main なら BLOCK（一部例外あり） |
| bash-check.sh | 危険な Bash コマンドをチェック | 危険なら BLOCK |

---

## 保護レベル

```yaml
HARD_BLOCK:
  - CLAUDE.md
  - .claude/protected-files.txt
  action: 常にブロック、admin でも回避不可

BLOCK:
  - state.md（特定条件下）
  - settings.json
  action: ブロック、admin で WARN に緩和可能

WARN:
  - その他の重要ファイル
  action: 警告のみ、処理は継続
```

---

## Bash 契約

```yaml
allowed_always:
  - git status, git log, git diff
  - ls, cat, head, tail
  - npm test, npm run

blocked_without_playbook:
  - git add, git commit, git push
  - rm -rf, mv, cp（変更系）
  - cat >, tee, sed -i

blocked_always:
  - rm -rf /
  - :(){:|:&};:
```

---

## 使用方法

### 導火線から自動呼び出し
pre-tool.sh が全ツール使用時に自動的に呼び出す

### 手動検証
```bash
bash .claude/skills/access-control/guards/protected-edit.sh
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| .claude/protected-files.txt | 保護ファイル一覧 |
| CLAUDE.md | admin モード制約 |
