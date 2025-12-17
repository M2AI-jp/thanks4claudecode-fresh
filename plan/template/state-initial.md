# state-initial.md

> **フォーク直後の state.md 初期状態テンプレート。**
> **セットアップ開始時に state.md をこの内容でリセットする。**

---

## 使い方

1. このファイルの「テンプレート」セクション以下を state.md にコピー
2. または `cp plan/template/state-initial.md state.md` を実行

---

## focus.current の候補値

```yaml
# 特殊（main ブランチで許可）
setup:         新規ユーザーのセットアップ
plan-template: テンプレート編集

# フレームワーク開発（framework/* ブランチ）
framework-*:   AI エージェント基盤の開発
thanks4claudecode-recovery: 回復プロジェクト

# プロダクト開発（feature/* ブランチ）
product-*:     実際のアプリケーション開発
```

詳細は docs/product-vs-framework.md を参照。

---

## テンプレート

```markdown
# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: setup  # setup | plan-template | framework-* | product-*
project: null   # setup 完了後: plan/project.md
```

---

## playbook

```yaml
active: setup/playbook-setup.md
branch: null  # setup は main で実行可
last_archived: null
```

---

## goal

```yaml
milestone: setup
phase: p0
done_criteria:
  - setup/playbook-setup.md Phase 0-8 を完了する
  - plan/project.md が生成される
  - focus.current が product-* または framework-* に切り替わる
```

---

## session

```yaml
last_start: null   # SessionStart で自動更新
last_clear: null
```

---

## config

```yaml
security: trusted  # strict | trusted | developer | admin
toolstack: A       # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode
  worker: claudecode
  reviewer: claudecode
  human: user
```

セキュリティモードの詳細は docs/security-modes.md を参照。

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画（setup 完了後に生成） |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/security-modes.md | セキュリティモード定義 |
| docs/product-vs-framework.md | フレームワーク/プロダクト分離方針 |
```

---

## 検証方法

state.md をこのテンプレートでリセット後、以下を確認:

1. `bash .claude/hooks/session-start.sh` を実行
2. 出力に `setup/playbook-setup.md` への Read 指示があること
3. 出力に「Phase 0 から開始」の説明があること
4. [自認] テンプレートに `playbook: setup/playbook-setup.md` があること
5. PLAYBOOK 未作成警告が出ないこと
