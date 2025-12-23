# session-manager Skill

> **セッション管理**
>
> セッション開始〜終了のライフサイクル管理

---

## 責務

このSkillは以下を担当:
1. 必須ファイル（state.md, playbook）の Read 強制
2. セッション開始/終了の状態追跡
3. compact 前のスナップショット保存・復元
4. セッション情報の更新

---

## ディレクトリ構造

```
session-manager/
├── SKILL.md              ← このファイル
└── handlers/
    ├── init-guard.sh         ← 必須ファイル Read 強制
    ├── start.sh              ← セッション開始処理
    ├── end.sh                ← セッション終了処理
    └── compact.sh            ← compact 前スナップショット保存
```

---

## 発火条件

- SessionStart イベント（startup/resume/clear）
- SessionEnd イベント
- PreCompact イベント
- 全ツール使用時（init-guard）
- session.sh（導火線）から呼び出される

---

## ハンドラー一覧

| ハンドラー | トリガー | 役割 |
|------------|----------|------|
| init-guard.sh | 全ツール使用時 | state.md, playbook の Read 済みチェック |
| start.sh | SessionStart | session.last_start 更新、初期化処理 |
| end.sh | SessionEnd | session.last_end 更新、クリーンアップ |
| compact.sh | PreCompact | 状態スナップショット保存 |

---

## init-guard の動作

```yaml
required_reads:
  - state.md
  - playbook（state.md の playbook.active で指定）

on_missing:
  action: WARN
  message: "必須ファイルを Read してください"

admin_override:
  enabled: true
  description: "admin モードでは WARN に緩和"
```

---

## セッション状態の追跡

```yaml
# state.md の session セクション
session:
  last_start: "2025-12-24 12:00:00"
  last_end: "2025-12-24 11:30:00"
  last_clear: "2025-12-24 10:00:00"
```

---

## compact 前の保存

```yaml
snapshot_location: tmp/pre-compact-snapshot/
contents:
  - state.md のコピー
  - 現在の playbook のコピー
  - 重要な一時ファイル
```

---

## 使用方法

### 導火線から自動呼び出し
session.sh が SessionStart/End/PreCompact 時に呼び出す

### 手動でセッション開始
```bash
bash .claude/skills/session-manager/handlers/start.sh
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| state.md | session セクションの更新先 |
| .claude/hooks/session.sh | 導火線 |
