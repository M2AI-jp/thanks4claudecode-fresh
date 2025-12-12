# .claude/context/

> **Context - 履歴と参照用コンテキストの保存場所**

---

## 役割

このフォルダは、セッション間で保持すべき履歴や参照用コンテキストを保存します。
「現在地」ではなく「過去の記録」を担当します。

---

## 設計原則

```yaml
現在地: state.md が担当（Single Source of Truth）
履歴: .claude/context/ が担当（参照用）
```

---

## 保存ファイル

| ファイル | 役割 |
|----------|------|
| history.md | state.md の変更履歴（過去の作業記録） |
| claude-md-history.md | CLAUDE.md の変更履歴（バージョン履歴） |

---

## 参照タイミング

- **history.md**: 過去の作業を振り返る時
- **claude-md-history.md**: CLAUDE.md の変更理由を確認する時

これらは毎回読まれるわけではなく、必要な時にのみ参照されます。

---

## 連携

- **state.md** → 現在の履歴は state.md に 1 行のみ記録
- **CLAUDE.md** → 現在のバージョン情報は CLAUDE.md に 1 行のみ記録
