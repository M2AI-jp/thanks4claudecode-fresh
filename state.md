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
active: plan/active/playbook-tech-stack-refinement.md
branch: feat/tech-stack-refinement
```

---

## goal

```yaml
milestone: M009  # Tech Stack 精査・不要ファイル削除・Core機能保護
phase: p1
done_criteria:
  - [ ] リポジトリ内全ファイル一覧が作成されている
  - [ ] 各ファイルの寄与度評価が完了している
  - [ ] 削除候補リストがユーザーに提示されている
```

---

## session

```yaml
last_start: 2025-12-13 03:15:20
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
