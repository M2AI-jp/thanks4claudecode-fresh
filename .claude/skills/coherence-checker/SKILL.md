# coherence-checker Skill

> **ARCHITECTURE.md と実装の整合性チェック**
>
> ドキュメントと実装の乖離を検出する

---

## Purpose

ARCHITECTURE.md に記載されているファイル・ディレクトリと、実際のファイルシステムの整合性を自動チェックする。

---

## When to Use

- SessionStart 後（手動または自動）
- ARCHITECTURE.md 更新後
- Hook/Skill/SubAgent の追加・削除後
- 定期的な整合性監査時

---

## ディレクトリ構造

```
coherence-checker/
├── SKILL.md              ← このファイル
└── scripts/
    └── check.sh          ← 整合性チェックスクリプト
```

---

## チェック項目

| カテゴリ | チェック内容 |
|----------|-------------|
| Hooks | ARCHITECTURE.md 記載の Hook ファイルが存在するか |
| Hooks（逆方向） | .claude/hooks/*.sh が ARCHITECTURE.md に記載されているか |
| Skills | ARCHITECTURE.md 記載の Skill ディレクトリが存在するか |
| Skills（逆方向） | .claude/skills/*/ が ARCHITECTURE.md に記載されているか |
| Skills | 各 Skill に SKILL.md が存在するか |
| SubAgents | ARCHITECTURE.md 記載の SubAgent ファイルが存在するか |
| SubAgents（逆方向） | .claude/skills/*/agents/*.md が ARCHITECTURE.md に記載されているか |

---

## Output Format

```yaml
coherence_check:
  timestamp: "2026-01-02T12:00:00+09:00"
  summary:
    verified: N      # 整合が取れている項目数
    inconsistent: N  # 実装にないがドキュメントに記載
    missing: N       # ドキュメントにないが実装に存在
  hooks:
    - file: ".claude/hooks/session.sh"
      status: verified|inconsistent|missing
      note: "..."
  skills:
    - dir: ".claude/skills/session-manager/"
      status: verified|inconsistent|missing
      has_skill_md: true|false
      note: "..."
  subagents:
    - file: ".claude/skills/golden-path/agents/pm.md"
      status: verified|inconsistent|missing
      note: "..."
```

---

## 使用方法

```bash
# 手動実行
bash .claude/skills/coherence-checker/scripts/check.sh
```

---

## ステータス定義

| ステータス | 意味 |
|-----------|------|
| verified | ARCHITECTURE.md に記載があり、実装も存在 |
| inconsistent | ARCHITECTURE.md に記載があるが、実装が存在しない |
| missing | 実装は存在するが、ARCHITECTURE.md に記載がない |

---

## 関連

| ファイル | 役割 |
|----------|------|
| docs/ARCHITECTURE.md | チェック対象のドキュメント |
| state.md | 整合性チェック結果の記録先（オプション） |
