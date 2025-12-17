# state.md

> **現在地を示す Single Source of Truth**
>
> このリポジトリは Experimental Archive（実験博物館）として凍結されました。

---

## focus

```yaml
current: archived  # 実験完了・博物館化
project: plan/project.md
disposition: Experimental Archive
```

---

## playbook

```yaml
active: null  # 回復プロジェクト完了
branch: recovery-project-m101-m120
last_archived: M120 playbook-m120 (2025-12-18)
```

---

## goal

```yaml
milestone: M120  # 完了
phase: done
done_criteria:
  - "docs/final-decision.md に、選択した方針と理由が記録されている ✓"
  - "README.md の冒頭に、このリポジトリの位置づけが明記されている ✓"
  - "state.md の focus/current が、最終方針に合わせて更新されている ✓"
```

---

## session

```yaml
last_start: 2025-12-18 04:01:31
last_end: 2025-12-18
final_session: true
```

---

## config

```yaml
security: admin
toolstack: A
roles:
  orchestrator: claudecode
  worker: claudecode
  reviewer: claudecode
  human: user
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| docs/final-decision.md | 博物館化の決定 |
| README.md | リポジトリ概要（実験記録） |
| plan/project.md | 回復プロジェクト計画（完了） |
