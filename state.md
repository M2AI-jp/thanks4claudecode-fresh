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
active: plan/playbook-m071-self-awareness.md
branch: feat/m071-self-awareness
last_archived: M069 playbook-m069-documentation.md (2025-12-17)
```

---

## goal

```yaml
milestone: M071
phase: p1
done_criteria:
  - docs/feature-catalog.yaml が存在し、全 Hook/SubAgent/Skill の詳細情報を含む
  - session-start.sh が feature-catalog.yaml を読み込み、機能サマリーを出力する
  - 機能の追加・削除を自動検出する仕組みが実装されている
  - 機能カタログが自動更新され、常に最新が保証されている
```

---

## session

```yaml
last_start: 2025-12-17 18:33:27
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
