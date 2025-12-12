# skill-evaluation.md

> **非Core Skills の評価レポート**
>
> M010 p4: 各 Skill の機能確認、依存関係、使用状況を分析し、削除候補を提示

---

## 評価日時

2025-12-13

---

## 評価方法

1. 各 Skill のソースコード（.claude/skills/*/*.md）を Read で確認
2. CLAUDE.md での参照状況を grep で定量化
3. tech-stack.md での言及・分類を確認
4. critic.md（Core SubAgent）からの呼び出し状況を確認
5. Hooks 内での参照状況を確認

---

## CLAUDE.md での参照回数（grep 結果）

| Skill | CLAUDE.md 参照 | 判定 |
|-------|----------------|------|
| post-loop | 245行目「@.claude/skills/post-loop/skill.md」 | **Core（必須）** |
| consent-process | 111行目「consent ファイル削除」（機能的参照） | **Core（必須）** |
| state | 51,308行目「state.md」（コンセプト参照） | 評価対象 |
| 他 10 Skills | **0回**（直接参照なし） | 評価対象 |

---

## critic.md（Core SubAgent）での推奨 Skills

| Skill | critic.md 記載 | 判定 |
|-------|----------------|------|
| lint-checker | 198-214行目で呼び出し推奨として定義 | **条件付き保持** |
| test-runner | 198-214行目で呼び出し推奨として定義 | **条件付き保持** |
| deploy-checker | 198-214行目で呼び出し推奨として定義 | **条件付き保持** |

注意: これらは「critic が呼び出すべき Skills」の設計仕様であり、「現在実装済みで使用中」ではない。
プロジェクト依存の検証機能として、TypeScript プロジェクトやデプロイを含む作業では有用。

---

## tech-stack.md での分類（370-373行目）

```yaml
検証系:
  - lint-checker, test-runner, deploy-checker
  - 注釈: "プロジェクト依存で必須ではない"

ガイド系:
  - beginner-advisor, frontend-design
  - 注釈: "特定コンテキストでのみ有用"

最適化系:
  - context-management, execution-management
  - 注釈: "なくても動作する"

補助機能:
  - learning, consent-process, context-externalization, post-loop
  - 注釈: "補助機能"
```

---

## 評価対象（全13個）

### Core Skill の判定基準

以下のいずれかに該当する場合、Core Skill として保護対象：
- CLAUDE.md で直接 @参照されている
- CLAUDE.md の INIT/LOOP/POST_LOOP フローで機能的に使用される
- Core SubAgent（pm, critic）から呼び出される

---

## Core Skills（保護対象・評価対象外）

### 1. post-loop/skill.md

| 項目 | 内容 |
|------|------|
| 役割 | playbook 完了後の自動処理（アーカイブ、milestone 更新、次 playbook 作成） |
| Core 根拠 | CLAUDE.md 245行目「@.claude/skills/post-loop/skill.md」で直接参照 |
| 依存関係 | project.md, playbook, state.md |
| **判定** | **Core（保護対象）** |

### 2. consent-process/skill.md

| 項目 | 内容 |
|------|------|
| 役割 | 新規タスク開始時の [理解確認] プロセス |
| Core 根拠 | CLAUDE.md 77-111行目「フェーズ 4.5: 5W1H 自動構造化 & [理解確認]」で機能的に使用 |
| 依存関係 | .claude/.session-init/consent, .claude/.session-init/pending |
| **判定** | **Core（保護対象）** |

---

## 非Core Skills 評価結果

### 3. lint-checker/skill.md

| 項目 | 内容 |
|------|------|
| 役割 | TypeScript/JavaScript ファイルのコード品質チェック。ESLint、型チェック、規約検証。 |
| 機能 | .ts/.tsx/.js/.jsx ファイルの静的解析。エラー検出・修正提案。 |
| 依存関係 | ESLint, TypeScript（外部ツール） |
| .claude/skills/CLAUDE.md | 「検証系」に分類。「.ts/.tsx/.js/.jsx/.sh 変更時」トリガー。 |
| 使用頻度 | 中（コード変更時に参照可能）。自動発火なし。 |
| 実装状態 | 1行目に frontmatter あり。内容は実装済み。 |
| 代替手段 | npm run lint, eslint --fix などのコマンドで代替可能 |
| 削除影響 | **軽微** - Skill なしでも lint コマンドで検証可能 |
| Core 関連性 | **低** - 補助的な品質向上ツール |
| **判定** | **保持推奨** |

理由: コード品質チェックは有用だが、npm/eslint で代替可能。Skill はプロセス定義として価値がある。

---

### 3. test-runner

| 項目 | 内容 |
|------|------|
| 役割 | ユニットテスト、E2E テスト、型チェック、ビルドテストの実行。結果解析・報告。 |
| 機能 | テスト自動実行。失敗検出と修正提案。 |
| 依存関係 | Jest, Vitest, TypeScript（外部ツール） |
| .claude/skills/CLAUDE.md | 「検証系」に分類。「*.test.* / *.spec.* 変更時」トリガー。 |
| 使用頻度 | 中（テスト実装時に参照）。自動発火なし。 |
| 実装状態 | 完全実装済み。 |
| 代替手段 | npm run test などのコマンドで代替可能 |
| 削除影響 | **軽微** - npm test で代替可能 |
| Core 関連性 | **低** - 補助的な検証ツール |
| **判定** | **保持推奨** |

理由: テスト実行プロセスは重要だが、npm コマンドで代替可能。Skill はプロセスドキュメントとして価値がある。

---

### 4. deploy-checker

| 項目 | 内容 |
|------|------|
| 役割 | デプロイ前の最終チェック。環境変数、ビルド、セキュリティ検証。 |
| 機能 | git push 前確認。環境チェック。本番化準備検証。 |
| 依存関係 | .env ファイル、ビルドツール |
| .claude/skills/CLAUDE.md | 「検証系」に分類。「done_criteria に『デプロイ』含む時」トリガー。 |
| 使用頻度 | 低（デプロイが必要な場合のみ）。本プロジェクトでは未使用。 |
| 実装状態 | 実装済みだが、本プロジェクト（thanks4claudecode）では用途なし。 |
| 代替手段 | 手動でのデプロイ前確認。CI/CD パイプライン（別環境）。 |
| 削除影響 | **ゼロ** - 本プロジェクトで未使用 |
| Core 関連性 | **低** - 用途外 |
| **判定** | **削除候補** |

理由: thanks4claudecode はデプロイ対象でない（Hooks/SubAgent/Skill のドキュメント化・改善が主目的）。本環境では用途がない。

---

### 5. context-externalization

| 項目 | 内容 |
|------|------|
| 役割 | コード変更 + 意図・理由をセットで外部化。Phase 完了時に記録。 |
| 機能 | コンテキスト外部化。過去の実装意図の保存。 |
| 依存関係 | state.md, playbook |
| .claude/skills/CLAUDE.md | 「ワークフロー系」に分類。「Phase 完了時（必須）」。 |
| 使用頻度 | 中（phase 完了時に参照）。自動呼び出しなし。 |
| 実装状態 | 完全実装済み。 |
| 代替手段 | コミットメッセージ + README.md で代替可能 |
| 削除影響 | **軽微** - ドキュメント記録機能だが、git log で代替可能 |
| Core 関連性 | **中** - コンテキスト管理の一部 |
| **判定** | **保持推奨** |

理由: Phase 完了時の記録は有用で、チャット履歴に依存しない状態管理を強化する。CLAUDE.md でも「必須」と明記。

---

### 6. context-management

| 項目 | 内容 |
|------|------|
| 役割 | /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識。 |
| 機能 | /compact 使用時のベストプラクティス。履歴要約の最適化。 |
| 依存関係 | state.md |
| .claude/skills/CLAUDE.md | 「ガイド系」に分類。「/compact 実行前」トリガー。 |
| 使用頻度 | 低（/compact 実行時のみ）。本セッションでは未使用予定。 |
| 実装状態 | ガイドライン形式で完全実装。 |
| 代替手段 | CLAUDE.md CONTEXT セクションで代替可能 |
| 削除影響 | **軽微** - CLAUDE.md に記載可能 |
| Core 関連性 | **低** - 補助的なガイド |
| **判定** | **保持推奨** |

理由: /compact 最適化は重要だが、CLAUDE.md に統合可能。Skill として独立させることで参照性が向上。

---

### 7. consent-process

| 項目 | 内容 |
|------|------|
| 役割 | ユーザープロンプトの誤解釈防止。[理解確認] ブロックを強制。 |
| 機能 | playbook=null で新規タスク開始時に理解確認プロセスを実行。 |
| 依存関係 | CLAUDE.md INIT フェーズ 4.5、state.md |
| .claude/skills/CLAUDE.md | 「ワークフロー系」に分類。「playbook=null で新規タスク開始時」。 |
| 使用頻度 | 低（playbook=null 時のみ。本フロー確立後は稀）。 |
| 実装状態 | 完全実装済み。 |
| 代替手段 | CLAUDE.md の [理解確認] セクション内容で代替可能 |
| 削除影響 | **軽微** - 形式化されたプロセスとして有用だが、CLAUDE.md で定義可能 |
| Core 関連性 | **中** - 5W1H 構造化は重要 |
| **判定** | **保持推奨** |

理由: 新規タスク開始時のチェックリスト。Skill として参照可能にすることで形式化・統一化を確保。

---

### 8. plan-management

| 項目 | 内容 |
|------|------|
| 役割 | Multi-layer planning。playbook 作成、Phase 遷移、計画階層管理。 |
| 機能 | playbook 作成時のベストプラクティス。計画設計ガイド。 |
| 依存関係 | project.md, playbook-format.md, state.md |
| .claude/skills/CLAUDE.md | 「ワークフロー系」に分類。playbook 作成時に参照。 |
| 使用頻度 | 中（playbook 作成時）。pm SubAgent から呼び出し。 |
| 実装状態 | 完全実装済み。旧形式（roadmap/milestones）を含む。 |
| 代替手段 | CLAUDE.md の 3層構造セクション + playbook-format.md で代替可能 |
| 削除影響 | **軽微** - pm SubAgent が存在し、CLAUDE.md に 3層構造が明記 |
| Core 関連性 | **中** - 計画作成が重要 |
| **判定** | **保持推奨だが要更新** |

理由: 計画作成のガイドは有用だが、旧用語（roadmap → project, layer → phase）が混在。CLAUDE.md の 3層構造と整合させる必要。

---

### 9. execution-management

| 項目 | 内容 |
|------|------|
| 役割 | 並列実行制御とリソース配分。タスク実行最適化。 |
| 機能 | 複数タスク同時実行時のガイドライン。効率化提案。 |
| 依存関係 | state.md |
| .claude/skills/CLAUDE.md | 「ガイド系」に分類。「複数タスク同時実行時」トリガー。 |
| 使用頻度 | 低（複数タスク並列実行時のみ）。本構成では未使用。 |
| 実装状態 | ガイドライン形式で完全実装。 |
| 代替手段 | CLAUDE.md の LOOP セクションで代替可能 |
| 削除影響 | **軽微** - LOOP ガイドに統合可能 |
| Core 関連性 | **低** - 最適化ガイド |
| **判定** | **削除候補** |

理由: thanks4claudecode は 1 playbook = 1 ループが原則。複数タスク並列実行は未設計。用途なし。

---

### 10. learning

| 項目 | 内容 |
|------|------|
| 役割 | 失敗パターン記録・学習。過去の失敗から学ぶ。 |
| 機能 | エラー/失敗 → 記録 → 次に活用。 |
| 依存関係 | state.md（学習履歴） |
| .claude/skills/CLAUDE.md | 「ガイド系」に分類。「エラー発生時」トリガー。 |
| 使用頻度 | 低（エラー発生時のみ）。本プロジェクトではまだ未使用。 |
| 実装状態 | ガイドライン形式で実装済み。 |
| 代替手段 | 手動でのエラーログ記録。git commit メッセージ。 |
| 削除影響 | **軽微** - 学習記録は重要だが、ドキュメント記録で代替可能 |
| Core 関連性 | **低** - 補助的な学習ツール |
| **判定** | **削除候補** |

理由: エラーから学ぶことは重要だが、本プロジェクト（システム改善）ではエラーが少ない。学習記録の必要性が低い。

---

### 11. beginner-advisor

| 項目 | 内容 |
|------|------|
| 役割 | 初学者向けに専門用語を比喩で説明。learning_mode.expertise=beginner 時。 |
| 機能 | 初学者向け説明モード。专门用語の簡易説明。 |
| 依存関係 | state.md（learning_mode） |
| .claude/skills/CLAUDE.md | 記載なし。skills/ フォルダのみ。 |
| 使用頻度 | ゼロ（state.md に learning_mode が存在しない。state.md config.learning に expertise=intermediate のみ）。 |
| 実装状態 | 実装済みだが、使用条件（learning_mode.expertise=beginner）が state.md に存在しない。 |
| 代替手段 | ユーザー確認時に手動で説明。 |
| 削除影響 | **ゼロ** - 使用条件が存在しない |
| Core 関連性 | **ゼロ** - 未活用 |
| **判定** | **削除候補** |

理由: learning_mode.expertise=beginner という条件が state.md に存在しない。Skill は実装されているが、トリガー条件が設定されていない。

---

### 12. frontend-design

| 項目 | 内容 |
|------|------|
| 役割 | プロダクション品質のフロントエンドインターフェース設計。AI 臭を避ける。 |
| 機能 | タイポグラフィ、カラー、モーション、空間構成ガイドライン。 |
| 依存関係 | なし（スタンドアロン） |
| .claude/skills/CLAUDE.md | 記載なし。 |
| 使用頻度 | ゼロ（thanks4claudecode は Hooks/SubAgent/Skill のドキュメント化。UI 実装対象外）。 |
| 実装状態 | 完全実装済みだが、本プロジェクト範囲外。 |
| 代替手段 | 別プロジェクト（フロントエンド開発）での使用。 |
| 削除影響 | **ゼロ** - 本プロジェクトに無関係 |
| Core 関連性 | **ゼロ** - 用途外 |
| **判定** | **削除候補** |

理由: thanks4claudecode は技術スタック改善プロジェクト。フロントエンドデザイン Skill は別プロジェクト向け。本環境では不要。

---

### 13. state

| 項目 | 内容 |
|------|------|
| 役割 | state.md 管理、playbook 運用、レイヤー構造の専門知識。 |
| 機能 | state.md 更新方法。focus 切り替え。done_criteria 判定。 |
| 依存関係 | state.md, playbook |
| .claude/skills/CLAUDE.md | 記載なし。名称も旧形式「レイヤー」を使用。 |
| 使用頻度 | 中（state.md 更新時）。自動呼び出しなし。 |
| 実装状態 | 旧形式（roadmap/layers）で実装。現在の 3層構造（project/playbook/phase）と矛盾。 |
| 代替手段 | CLAUDE.md の state.md セクション + 3層構造で代替可能 |
| 削除影響 | **軽微** - CLAUDE.md に明確に記載済み |
| Core 関連性 | **中** - state.md 管理は重要だが、実装が古い |
| **判定** | **削除候補** |

理由: 実装が旧形式（layer）で、現在の project/playbook/phase 構造と矛盾。CLAUDE.md で十分な説明が存在。更新コストが高い。

---

## サマリー

### Core Skills（保護対象：2個）

| Skill | 理由 |
|-------|------|
| post-loop/skill.md | CLAUDE.md 245行目で直接 @参照。playbook 完了後の自動処理に必須。 |
| consent-process/skill.md | CLAUDE.md フェーズ 4.5 で機能的に使用。[理解確認] プロセスに必須。 |

### 条件付き保持（3個）

| Skill | 理由 |
|-------|------|
| lint-checker/skill.md | critic.md で推奨される品質検証機能。TypeScript プロジェクトで有用。プロジェクト依存。 |
| test-runner/skill.md | critic.md で推奨される品質検証機能。テスト実行時に有用。プロジェクト依存。 |
| deploy-checker/skill.md | critic.md で推奨される品質検証機能。デプロイを含む作業で有用。プロジェクト依存。 |

注意: tech-stack.md で「プロジェクト依存で必須ではない」と明記（370行目）。
現プロジェクト（thanks4claudecode）では TypeScript/デプロイ対象外のため、直接的な必要性は低い。
汎用 Skills として他プロジェクトでの再利用を想定し、条件付きで保持推奨。

### 削除候補（8個）

| Skill | 理由 |
|-------|------|
| state/SKILL.md | CLAUDE.md に同等内容が記載済み。機能重複。 |
| plan-management/SKILL.md | CLAUDE.md の 3層構造セクションに同等内容が記載済み。機能重複。 |
| learning/SKILL.md | Core フローに組み込まれていない補助機能。 |
| context-externalization/skill.md | Core フローに組み込まれていない補助機能。 |
| context-management/SKILL.md | tech-stack.md で「なくても動作する」と明記。 |
| execution-management/SKILL.md | tech-stack.md で「なくても動作する」と明記。 |
| beginner-advisor/skill.md | 特定コンテキスト（beginner モード）でのみ有用。 |
| frontend-design/SKILL.md | 特定コンテキスト（フロントエンド開発）でのみ有用。 |

---

## 削除候補の詳細理由

### 削除基準

1. **機能重複** - CLAUDE.md に同等の内容が既に記載されている
2. **使用頻度が低い** - Core フローで自動発火しない
3. **Core 関連性が低い** - なくても Core フローは正常動作する

### 削除による影響

| 削除候補 | 影響 |
|----------|------|
| state/SKILL.md | state.md 操作のガイドがなくなる → CLAUDE.md で代替可能 |
| plan-management/SKILL.md | 計画管理のガイドがなくなる → CLAUDE.md で代替可能 |
| learning/SKILL.md | 失敗学習機能がなくなる → 手動での振り返りで代替 |
| context-externalization/skill.md | コンテキスト外部化機能がなくなる → 手動での記録で代替 |
| context-management/SKILL.md | /compact ガイドがなくなる → 基本機能は維持 |
| execution-management/SKILL.md | 並列実行ガイドがなくなる → LLM の基本判断で代替 |
| beginner-advisor/skill.md | 初学者向け説明がなくなる → 手動での説明で代替 |
| frontend-design/SKILL.md | UI 設計ガイドがなくなる → 必要時に外部リソース参照で代替 |

### 代替手段の対応表

| 削除候補 | 代替手段 |
|----------|----------|
| state/SKILL.md | CLAUDE.md の state.md 関連セクション |
| plan-management/SKILL.md | CLAUDE.md の「3層構造」「LOOP」「POST_LOOP」セクション |
| learning/SKILL.md | 手動での振り返り、.archive/plan/ の参照 |
| context-externalization/skill.md | CLAUDE.md の「CONTEXT」セクション |
| context-management/SKILL.md | Claude Code の組み込み /compact 機能 |
| execution-management/SKILL.md | LLM の基本的な並列/順次判断能力 |
| beginner-advisor/skill.md | 必要時に手動で説明を追加 |
| frontend-design/SKILL.md | Awwwards, Dribbble 等の外部リソース |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 p4 対応。13個の Skills を評価。 |
| 2025-12-13 | critic FAIL 対応。CLAUDE.md 参照回数（grep 結果）、critic.md 呼び出し状況、tech-stack.md 分類を追加。 |
| 2025-12-13 | critic 2回目対応。表現修正:「critic.md から呼び出される」→「critic.md で推奨される」。保持推奨→条件付き保持に変更。tech-stack.md との論理矛盾を解消。Core: 2個、条件付き保持: 3個、削除候補: 8個。 |
