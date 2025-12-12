# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode  # 現在作業中のプロジェクト名
project: plan/project.md
```

---

## playbook

```yaml
active: null  # M010 完了、アーカイブ済み
branch: feat/doc-audit-component-eval
```

---

## goal

```yaml
milestone: M010  # ドキュメント・コンポーネント監査（achieved）
phase: null
self_complete: true
done_criteria:
  - [x] ドキュメント参照状況の最終確認リストが作成されている
  - [x] 未参照ドキュメントがアーカイブに移動されている
  - [x] 非Core Hooks の評価が完了している
  - [x] 非Core SubAgents の評価が完了している
  - [x] 非Core Skills の評価が完了している
  - [x] Codex による第三者評価・最終レポートが作成されている
```

---

## session

```yaml
last_start: 2025-12-13 04:29:28
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
learning:
  operator: hybrid
  expertise: intermediate
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/feature-map.md | 機能マップ |
