# playbook-gate Skill

> **Core Contract #2: Playbook Gate**
>
> playbook なしでの変更をブロックする

---

## 責務

```yaml
core_contract: "#2 Playbook Gate"
rule: playbook 必須
block: state.md の playbook.active が null の場合、Edit/Write をブロック
bash: 変更系 Bash コマンド（cat >, tee, sed -i, git add/commit 等）も同様にブロック
```

このSkillは以下を担当:
1. playbook なしでの Edit/Write ブロック
2. executor に応じた作業制御
3. Phase 依存関係チェック
4. 完了した playbook のアーカイブ

---

## ディレクトリ構造

```
playbook-gate/
├── SKILL.md              ← このファイル
├── guards/
│   ├── playbook-guard.sh     ← playbook 必須チェック
│   ├── executor-guard.sh     ← executor 強制（claudecode/codex/user）
│   ├── depends-check.sh      ← Phase 依存関係チェック
│   └── role-resolver.sh      ← executor 名解決
└── workflow/
    ├── archive.sh            ← playbook 完了時アーカイブ
    └── cleanup.sh            ← テンポラリクリーンアップ
```

---

## 発火条件

- Edit/Write ツール使用時（PreToolUse）
- 変更系 Bash コマンド使用時（PreToolUse）
- playbook 完了時（PostToolUse）
- pre-tool.sh（導火線）から呼び出される

---

## ガード一覧

| ガード | 役割 | ブロック時の動作 |
|--------|------|------------------|
| playbook-guard.sh | playbook.active が null かチェック | Edit/Write を BLOCK |
| executor-guard.sh | 現在の executor が許可されているかチェック | 不一致時 WARN |
| depends-check.sh | Phase の依存関係が満たされているかチェック | 未完了依存があれば BLOCK |
| role-resolver.sh | executor 名を解決（claudecode/codex/user） | - |

---

## 使用方法

### 導火線から自動呼び出し
pre-tool.sh が Edit/Write 検出時に自動的に呼び出す

### 手動検証
```bash
bash .claude/skills/playbook-gate/guards/playbook-guard.sh
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義 |
| state.md | playbook.active の確認元 |
| .claude/hooks/pre-tool.sh | 導火線 |
