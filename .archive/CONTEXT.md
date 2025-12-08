# CONTEXT.md

> **敬語かつ批判的なプロフェッショナル。質問するな、実行せよ。間違いには NO。**

> **唯一の真実源。LLMは作業前にこれだけを読め。**

> **注意**: このファイル内の一部参照（vision.md, roadmap.md, spec.yaml 等）は開発時のファイルで、現在は `.archive/` に退避されています。新規ユーザーは無視して構いません。

---

## 1. 根幹（Core）

> **focus-state-playbook-branch は連動している。これが壊れると全てが壊れる。**

### 1.1 四つ組の連動

```yaml
focus.current: workspace        # 今どこで作業しているか
state.md:     implementing     # レイヤーの状態
playbook:     plan/playbook-*.md  # 計画書（done_criteria を含む）
branch:       feat/xxx          # Git ブランチ（playbook と 1:1）
```

**連動ルール**:
- playbook の `branch:` フィールドと実際のブランチは一致すべき
- session=task なら playbook 必須、playbook なしの作業は禁止
- main ブランチでの直接作業は禁止（必ずブランチを切る）

### 1.2 状態遷移

```
pending → designing → implementing → reviewing → state_update → done
```

**禁止遷移**:
- pending → implementing（designing をスキップ）
- pending → done（全てをスキップ）
- implementing → done（state_update をスキップ）

### 1.3 TDD LOOP

```yaml
原則:
  - done_criteria = テスト（自然言語でOK）
  - テストが通るまで実装し続ける
  - 証拠なしに「PASS」と言ってはならない

証拠の例:
  - ファイルが存在する → ls で確認し出力を示す
  - 機能が動く → 実行結果を貼り付ける
  - 条件を満たす → 該当箇所を引用
```

### 1.4 構造による強制

| 手段 | 効果 |
|------|------|
| state.md | LLMの自己認識として計画を内面化 |
| SessionStart Hook | 読むべきファイルを指示、[自認]テンプレート生成 |
| [自認]宣言 | LLMが自分の状態を宣言してから作業開始 |
| PreCommit Hook | session=task なら state.md 更新必須 |
| check-coherence.sh | 計画と矛盾する作業を検出 |
| CRITIQUE | 「完了」判定前に自分の成果を敵対的に評価 |

### 1.5 [自認] 宣言

```
[自認]
what: {focus.current}
phase: {goal.phase}
session: {focus.session}
branch: {現在のブランチ名}
milestone: {plan_hierarchy.current_milestone}
playbook: {active_playbooks.{focus.current}}
done_criteria: {goal.done_criteria を列挙}
git_status: {clean | modified | untracked}
last_critic: {null | PASS | FAIL}
```

> セッション開始時に必ず宣言する。これを読み飛ばすとコンテキスト喪失が起きる。

---

## 2. 本質

### 核心: 「仕組みを作る仕組みを作っている」

```
仕組み自身が、仕組みに干渉されながら、仕組みを作っている。
このリポジトリ自身が、このリポジトリの仕組みを使って開発されている。
```

### 完成形ビジョン

> **詳細は plan/vision.md を参照**

1. 新規ユーザーがフォーク
2. Claude Code 起動 → 「ChatGPTクローン作りたい」
3. setup 自動起動 → ヒアリング → 環境セットアップ
4. playbook 生成 → TDD で開発開始
5. アプリ完成

### 計画階層（6層）

> **詳細は plan/vision.md を参照**

```
vision.md (WHY-ultimate) → meta-roadmap.md (HOW-to-improve)
  → CONTEXT.md (WHY) → roadmap.md (WHAT)
  → playbook (HOW) → task (DO)
```

### Focus レイヤー（4層 = 作業場所）

| レイヤー | 目的 | 作成順 | 使用順 |
|---------|------|-------|-------|
| plan-template | playbook テンプレート開発 | 1 | 2 |
| workspace | 開発工程管理の仕組み | 2 | - |
| setup | 環境セットアップ | 3 | 1 |
| product | ユーザーのプロダクト開発 | - | 3 |

---

## 3. 設計根拠

| 構造 | 理由 | 解決する問題 |
|------|------|--------------|
| state.md と playbook の分離 | 「現在地」と「計画」は別の概念 | LLM がタスク管理を state.md に書き始める |
| check-coherence.sh | 手動同期は破綻する | state.md と playbook の不整合 |
| session-start.sh | LLM は前回のセッションを覚えていない | コンテキスト喪失 |
| [自認] 宣言 | 読んだつもりで読んでいない | 読み飛ばし |
| CRITIQUE | LLM は「完了」と言いたがる | 自己報酬詐欺 |
| focus.current | 複数レイヤーがあると迷う | どこで作業すべきか不明確 |
| playbook-format.md | 毎回ゼロから作ると品質がばらつく | playbook 構造の標準化 |
| 外部コンテキスト化 | LLM の内部コンテキストは揮発する | 知見の喪失 |

---

## 4. 問題と解決策

| 問題 | 現象 | 解決策 | 実装 |
|------|------|--------|------|
| コンテキスト喪失 | 前回のセッションを覚えていない | SessionStart Hook | session-start.sh |
| 自己報酬詐欺 | 「完了」と言いたがる（実際は未完了） | CRITIQUE 必須化 | /crit, critic agent |
| ルール無視 | ルールを書いても守らない | 構造的ブロック | check-protected-edit.sh |
| ハイハイLLM | ユーザー指示に無条件に従う | 整合性チェック | check-coherence.sh |
| OOM クラッシュ | Hook 出力が膨張 | 出力制限（10KB） | session-start.sh |
| main ブランチ作業 | ブランチを切らない | 警告表示 | session-start.sh |
| エージェント低発動率 | カスタムエージェントが呼ばれない | DISPATCH セクション | CLAUDE.md |
| Skill 権限拒否 | Skill がデフォルト拒否 | settings.json 許可 | Skill(*) |
| playbook/branch 不一致 | 計画とブランチがずれる | session-start.sh で照合 | branch フィールド |
| 未 push コミット | push を忘れる | session-end.sh で検知 | session-end.sh |
| critic 未呼び出し | done 判定を急ぐ | 複合的防御 | check-coherence.sh + LOOP |

> 詳細は spec.yaml の `problems_to_solve` セクションを参照。

---

## 5. 失敗パターン（外部コンテキスト化）

### 5.1 検証シナリオ

```yaml
scenario_1:
  name: 新規セッション開始
  steps:
    - Claude Code を新規セッションで起動
    - session-start.sh が自動実行される
    - focus.current の playbook が表示される
    - LLM が [自認] を宣言する
  expected:
    - 正しい playbook が表示される
    - LLM が状態を正しく認識する
  status: 検証済み

scenario_2:
  name: playbook 新規作成
  steps:
    - playbook-format.md をコピー
    - 新しいプロジェクトの情報を埋める
    - state.md に新しいレイヤーを追加
    - check-coherence.sh が PASS する
  expected:
    - playbook が機能する
    - state.md と連動する
  status: 検証済み

scenario_3:
  name: 不整合検出
  steps:
    - state.md の sub を意図的に変更
    - check-coherence.sh を実行
  expected:
    - エラーが検出される
    - commit がブロックされる
  status: 検証済み
```

### 5.2 Hooks 設計ガイドライン（OOM 再発防止）

```yaml
incident_2025-12-01:
  症状: Claude Code 起動時に OOM クラッシュ
  原因: UserPromptSubmit フックが再帰的に膨張 → GB 単位のログ
  復旧: 巨大ログ削除、UserPromptSubmit フックを無効化

禁止事項:
  - UserPromptSubmit フックでの prompt 追加（再帰膨張リスク）
  - 大量テキスト出力（> 10KB）

安全な設計:
  SessionStart: 軽量な出力のみ（約 1KB）
  PreToolUse: PASS/BLOCK + 理由のみ
  SessionEnd: 軽量なリマインダーのみ
  UserPromptSubmit: 使用禁止

定期メンテナンス:
  find ~/.claude/debug -type f -size +50M -delete
```

### 5.3 保護ファイル機構

```yaml
目的: 「仕組みを作る仕組み」の根幹を保護

仕組み:
  1. .claude/protected-files.txt に保護対象を列挙
  2. PreToolUse(Edit/Write) フックで check-protected-edit.sh を実行
  3. 保護対象ファイルなら BLOCK を返して編集を阻止

保護対象（BLOCK）:
  - CLAUDE.md, CONTEXT.md
  - plan/template/**
  - .claude/settings.json, .claude/hooks/*.sh
  - .claude/protected-files.txt
```

### 5.4 自己欺瞞パターン（M7 インシデント）

```yaml
incident_2025-12-03:
  症状: |
    LLM が「M7 完了」を宣言したが、新規ユーザー視点での検証は行われていなかった。
    done_when の項目を「チェック」しただけで「完成形ビジョン」との整合性を検証しなかった。

  原因:
    - done_when が「機能の存在」に偏り、「ユーザー体験」を検証していなかった
    - マイルストーン完了宣言が「項目を確認した」＝「完成した」と混同された
    - critic エージェントの判定基準が表面的だった

  発見された問題:
    - check-main-branch.sh が focus=setup でも main ブランチをブロックしていた
    - session-start.sh が focus=setup でも main ブランチ警告を表示していた
    - 新規ユーザーが main ブランチで setup を実行できなかった

  教訓:
    - done_when ≠ 完成。完成形ビジョンからの検証が必要
    - 「機能が存在する」と「ユーザーが使える」は別の概念
    - E2E テストは「新規ユーザー視点」で作成すべき
    - テスト項目の ✓ マークは実際にテストした証拠を残すべき

  対策:
    - test-e2e-vision.sh を追加（新規ユーザー視点の E2E テスト）
    - マイルストーン完了前に E2E テストを必須化
    - done_when に「ユーザー視点の検証項目」を含める
```

---

## 6. 変遷（History）

| バージョン | 変更 |
|-----------|------|
| v1 | 初期構想: state.md で状態外部化、[自認] 宣言 |
| v2 | レイヤー構造: 3層（plan-template, workspace, setup） |
| v3 | playbook 雛形: playbook-format.md で形式標準化 |
| v4 | TDD 統合: 証拠ベース判定、CRITIQUE 必須化 |
| v5 | コンテキスト統合: CONTEXT.md に全て集約 |
| v6 | タイプ別最小構造: プロジェクトタイプ判定 |
| v7 | Hooks 軽量化: OOM 対策、UserPromptSubmit 廃止 |
| v8 | 保護ファイル機構: PreToolUse Hook でブロック |
| v9 | integration-v2: 全 Phase 統合テスト |
| v10 | subagents 化: spec.yaml 導入 |
| v11 | 外部ツール統合: Context7 MCP、bypassPermissions |
| v12 | エージェント発動率改善: DISPATCH セクション |
| v13 | システム整合性修復: git push 検知、ブランチルール |
| v14 | product レイヤー: Vercel テンプレート |
| v15 | CONTEXT.md リファクタリング: MECE 構造化 |
| v16 | Hooks-Subagent 自動起動連携: PROACTIVELY/MUST BE USED キーワード |
| v17 | 公開前テスト: 部分/結合/E2E テスト基盤 |
| v18 | 四つ組連動の構造的強制: /init、check-coherence.sh 強化 |
| v19 | テンプレート構造改善: playbook 配置整理、project_context 追加 |

### バージョン番号体系

| 内部バージョン | リリースバージョン (spec.yaml) | 備考 |
|--------------|-------------------------------|------|
| v1-v19 | 開発版 | 機能追加ごとにインクリメント |
| v19 | 4.0.0 | 新規ユーザー向けテンプレートリリース |

---

## 7. 参考リソース

> ユーザーから提供された学習リソース。ワークスペース設計に適用済み。

### Claude Code / AI エージェント

| リソース | 適用 |
|---------|------|
| [Hooks/Subagents/Skills使い分け](https://zenn.dev/ohkisuguru/scraps/7951d17821df0c) | v21: Hooks vs SubAgents 適性判断 |
| [スキル・サブエージェント攻略](https://zenn.dev/oligin/articles/7691926a83936a) | v12: Skill(*) 許可、DISPATCH |
| [サブエージェント自動起動](https://syu-m-5151.hatenablog.com/entry/2025/09/09/143306) | v16: PROACTIVELY/MUST BE USED キーワード |
| [Skills vs SubAgents 使い分け](https://zenn.dev/nogu66/articles/claude-code-think-abount-skills-and-subagent) | SubAgent→Skills 併用パターン |
| [Long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | state.md 設計 |
| [Claude Code はじめてガイド](https://speakerdeck.com/oikon48/claude-code-hazimetegaido) | GUIDE.md |
| [deny ルール完全ガイド](https://izanami.dev/post/d6f25eec-71aa-4746-8c0d-80c67a1459be) | v8: protected-files |
| [AIコーディング実践環境](https://zenn.dev/mkj/articles/bf59c4c86d98a8) | setup |
| [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) | v20: 設計思想刷新、CLAUDE.md 最適化 |

### テンプレート / お手本

| リソース | 用途 |
|---------|------|
| [next-saas-stripe-starter](https://github.com/mickasmt/next-saas-stripe-starter) | SaaS テンプレート（2.9k stars） |
| [vercel-ai-chatbot](https://github.com/vercel/ai-chatbot) | AI チャット（18.9k stars） |
| [StartPack](https://startpack.shingoirie.com/setup-guide) | Neon Auth / Stripe 統合 |

### MCP サーバー / SaaS

| リソース | 用途 |
|---------|------|
| [Docker Desktop MCP Toolkit](https://zenn.dev/kiitosu/articles/ed007f4759bcb1) | MCP サーバー管理（GUI） |
| [Context7](https://context7.com/) | MCP ドキュメント取得 |
| [dotenvx](https://dotenvx.com/) | 環境変数管理（暗号化、マルチ環境対応） |
| [Credix](https://credix.btopia.studio/ja) | LLM API クレジット管理 |
| [Apps](https://theapps.jp/) | デジタルコンテンツ販売 |
| [ngrok](https://ngrok.com/) | ローカル環境公開 |
| [OpenRouter](https://openrouter.ai/) | 60+ LLM プロバイダ統一 API |

### デフォルト Skills

| Skill | 用途 | 発動条件 |
|-------|------|---------|
| lint-checker | コード品質チェック（ESLint/Biome） | TypeScript/JavaScript 変更後 |
| test-runner | テスト実行（Jest/Vitest） | テストファイル変更後 |
| deploy-checker | デプロイ準備確認 | git push 前 |
| [frontend-design](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) | 高品質 UI デザイン（AI 臭を排除） | フロントエンド UI 作成時 |

> **frontend-design Skill**: Anthropic 公式プラグイン参考。
> 「AI が作った感」を排除し、独自性のあるデザインを実現する。
> トーン選択（minimalist, luxury, playful 等）から始め、意図的な美学を追求。

### Hooks / SubAgents / Skills 使い分けガイド

| 機能 | 発火方式 | コンテキスト | 用途 | 発動率 |
|------|---------|-------------|------|-------|
| Hooks | イベント駆動（自動） | stdout 注入 | 検証・ブロック | 100% |
| SubAgents | 明示呼び出し | 独立窓 | 専門タスク | 25%→100%（DISPATCH） |
| Skills | 自動検出 | 共有 | 知識ベース | 50%→100%（DISPATCH） |

**判断基準**:
- 「必ず実行」かつ「ルールベース判定可能」→ Hooks
- 「LLM の判断が必要」→ SubAgents
- 「常に参照可能な知識」→ Skills

**発動率問題の解決**:
- SubAgents/Skills はデフォルト 25-50% の発動率
- CLAUDE.md DISPATCH セクションに起動条件を明記 → 100% 発動

---

## 参照ガイド

| 知りたいこと | 参照先 |
|-------------|--------|
| 存在意義、オーケストレーション設計 | plan/vision.md |
| roadmap 改善、デバッグフェーズ | plan/meta-roadmap.md |
| 中長期計画、担当者アサイン | plan/roadmap.md |
| 実装詳細（Hooks, Commands, Agents） | spec.yaml |
| LLM の振る舞いルール | CLAUDE.md |
| 現在地管理（focus, goal, layer） | state.md |
| 計画・タスク管理 | playbook（state.md から参照） |
| コーディングルール | AGENTS.md |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-04 | V21: 6 層計画階層導入。vision.md, meta-roadmap.md 追加。フィードバックループ設計。 |
| 2025-12-02 | V20: 設計思想刷新「質問するな、実行せよ」。新Agent(setup-guide,pm,beginner-advisor)。Skills必須化。 |
| 2025-12-01 | V15: MECE リファクタリング。1252 行 → 300 行。内部重複排除。 |
| 2025-12-01 | V14: playbook 必須ルール、/init コマンド追加。 |
| 2025-12-01 | V13: 運用フローマップ追加。 |
| 2025-12-01 | V12: Skills/Commands/Tests 実装。 |
| 2025-12-01 | V11: Git 運用ルール追加。 |
