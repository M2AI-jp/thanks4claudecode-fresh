# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: product
```

---

## playbook

```yaml
active: plan/playbook-repo-map-enhancement.md
branch: feat/repo-map-enhancement
last_archived: plan/archive/playbook-cleanup-project-refs.md
review_pending: true
```

---

## goal

```yaml
phase: p_final2
done_criteria:
  - generate-repository-map.sh が description を正しく抽出し、途中で切れない
  - repository-map.yaml に Skill パッケージ構造（hooks/, agents/, frameworks/）が記録されている
  - repository-map.yaml に 4QV+ 構成と導火線モデルが記録されている
  - deprecated-references.md の対応状況が確認され、必要に応じてアーカイブされている
  - ARCHITECTURE.md のアーカイブ候補が整理されている
  - prompt-guard.sh の表示が project.md 削除後の仕様に適合している
  - state.md の構造が project.md 不要の設計と整合している
  - 孤立ファイル（参照・被参照なし）が整理されている
note: repository-map.yaml 強化 + post-project.md 整合性確保
```

---

## session

```yaml
last_start: 2025-12-24 00:43:16
last_end: 2025-12-24 00:43:15
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
