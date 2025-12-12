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
active: plan/active/playbook-doc-audit-component-eval.md  # M010
branch: feat/doc-audit-component-eval
```

---

## goal

```yaml
milestone: M010  # ドキュメント・コンポーネント監査
phase: p2
self_complete: false
done_criteria:
  - ドキュメント参照状況の最終確認リストが作成されている
  - 未参照ドキュメントがアーカイブに移動されている
  - 非Core Hooks の評価が完了している
  - 非Core SubAgents の評価が完了している
  - 非Core Skills の評価が完了している
  - Codex による第三者評価・最終レポートが作成されている
```

---

## session

```yaml
last_start: 2025-12-13 03:48:54
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
