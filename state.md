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
active: plan/active/playbook-clear-context-enhancement.md
branch: feat/clear-context-enhancement
```

---

## goal

```yaml
milestone: M008  # Clear時コンテキスト継承 & Tech Stack & 5W1H理解確認
phase: done  # 全 Phase 完了
done_criteria:
  - [x] Clear時アナウンスに「元のプロンプト要約」が含まれる
  - [x] Clear時アナウンスに「成果物サマリー」が含まれる
  - [x] Clear時アナウンスに「ネクストアクション」が含まれる
  - [x] docs/tech-stack.md が自然言語で充実した説明を持つ
  - [x] [理解確認] が 5W1H 形式で構造化される
```

---

## session

```yaml
last_start: 2025-12-13 02:25:05
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
