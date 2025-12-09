# playbook-current-implementation-redesign

> **タスク**: docs/current-implementation.md を「復旧可能な仕様書」として再設計
>
> **derives_from**: project.md vision.goal「入力→処理→出力が明確に連鎖する仕組み」の文書化
> **ブランチ**: feat/current-implementation-redesign（既存）
> **関連**: extension-system.md（公式仕様の真実源）

---

## goal

```yaml
summary: |
  extension-system.md を基準として使用し、公式仕様 → 実装のマッピングを徹底的に厳密化。
  いつでも仕組み自体を復旧できるよう、すべての「入力→処理→出力」プロセスと
  プロセス同士の連携を表現した仕様書を完成させる。

done_criteria:
  - extension-system.md の各仕様項目に対応する実装が全てマッピングされている
  - 各コンポーネント（Hooks/SubAgents/Skills）の「公式仕様 → 実装理由」が記載されている
  - 依存関係図が作成され、視認性が確保されている
  - 復旧手順が文書化されている（「何を失ったら、何を復旧するか」）
  - 不要ファイルの選定が完了している（削除予定リストが明確）
  - Phase 完了時に critic が PASS を返す
```

---

## phases

### Phase 1: extension-system.md 完全読み込みと仕様マッピング

```yaml
current_phase: 1
status: done

summary: |
  extension-system.md の全 11 セクションを読み込み、各セクションの仕様要件に対して
  現在の実装がどう対応しているかをマッピングする。
  不足分とズレを洗い出す。

done_criteria:
  - extension-system.md の構造を把握（4つの拡張メカニズム）
  - 10種類の Hook イベント全てについて、公式発火条件を理解
  - 3種類の Hook タイプ、matcher 仕様、stdin JSON スキーマを確認
  - 環境変数と出力・効果を含めた完全な Hook 仕様を抽出
  - SubAgents/Skills/Commands の公式仕様を確認
  - 現在の settings.json との対応関係を整理

test_method: |
  1. extension-system.md を分割読み込み
  2. 各セクションの表のすべてのフィールドを Excel/CSV で整理
  3. 公式仕様 vs 現在実装の対比表を作成
  4. メモ: 「拡張システムは 4つのメカニズム」「Hook は 10種類」「matcher は 3種類」など

executor: claude_code
evidence: phase-1-mapping.md（新規作成ファイル）

known_issues: []
```

### Phase 2: 現在実装の「完全な」棚卸し

```yaml
current_phase: 2
status: done

summary: |
  Phase 1 の公式仕様に基づいて、現在の実装を 100% 棚卸しする。
  settings.json、.claude フォルダ配下の全ファイルを読み込み、
  マッピングテーブルを生成する。

done_criteria:
  - settings.json の全 Hook 登録がマッピングされている
  - .claude/agents/*.md の全 9 SubAgent を表で整理
  - .claude/skills/*/ の全 9 Skill を表で整理
  - .claude/commands/*.md の全 Command を表で整理
  - .claude/hooks/ の全 18 ファイルが登録/非登録で分類されている
  - 各コンポーネントの frontmatter（name, description, tools, triggers）が完全に抽出されている
  - 実装と公式仕様のズレが列挙されている（例：skill.md vs SKILL.md）

test_method: |
  1. settings.json を JSON パース
  2. .claude/agents/ → ls -la で全ファイル確認
  3. .claude/skills/ → 各ディレクトリの SKILL.md/skill.md 確認
  4. .claude/hooks/ → ファイル一覧と settings.json 登録状況を突合
  5. 対比表を作成（実装状況のテーブル化）

executor: claude_code
evidence: phase-2-inventory.md（新規作成ファイル）

known_issues:
  - frontend-design, lint-checker, test-runner, deploy-checker の Skill に frontmatter が不完全
  - check-coherence.sh, check-state-update.sh は settings.json 未登録だが pre-bash-check.sh 経由で呼び出される
```

### Phase 3: 入力→処理→出力フロー図の再構築

```yaml
current_phase: 3
status: done

summary: |
  extension-system.md Section 1.7「Hook による処理フロー」を基準に、
  現在実装の Hook 連鎖を厳密に再構築する。
  各 Hook の発火タイミング、入力パラメータ、判定ロジック、次の Hook への連携を明記。

done_criteria:
  - SessionStart → UserPromptSubmit → PreToolUse(*) → Pre/PostToolUse(具体) → Stop → SessionEnd の連鎖を確定
  - 各段階での入力・出力（stdin/stdout/exit code）をドキュメント化
  - 分岐（Edit vs Write vs Bash など）が明確に表現されている
  - 各 Hook での判定ロジック（例：check-coherence.sh の 5つのチェック項目）を記載
  - 連鎖が断絶している箇所（example: UserPromptSubmit から PreToolUse(*) への自動連携）を明記
  - 連鎖が「同一セッション内」なのか「複数セッション」なのか を明確化

test_method: |
  1. session-start.sh → init-guard.sh → playbook-guard.sh → ... の実装コード確認
  2. 各 Hook が「exit 0 で続行」「exit 2 でブロック」のいずれを返すか確認
  3. pending ファイル作成・削除のタイミングを確認
  4. フロー図を Mermaid または ASCIIart で再描画

executor: claude_code
evidence: phase-3-flow.md（新規作成ファイル）

known_issues:
  - Stop Hook が実装されているが、実際に「エージェント停止時」に発火するか未検証
  - SubagentStop Hook は使用されていない（PostToolUse(Task) で代替）
```

### Phase 4: 仕様 → 実装の根拠ドキュメント化

```yaml
current_phase: 4
status: done

summary: |
  extension-system.md の各仕様項目に対して、なぜその仕様を実装したのか、
  実装がその仕様の「どの部分」に対応しているのか を記載する。
  例：「Hook ivent = PreToolUse」「matcher = "*"」「timeout = 3000ms」
  など、すべてが根拠付きで説明される。

done_criteria:
  - 各 Hook（18ファイル）について以下を記載：
    - 公式仕様のどのセクションか
    - 発火条件（イベント、matcher）
    - 入力パラメータ（stdin JSON スキーマ準拠確認）
    - 出力・効果（exit code, stdout）
    - 次の Hook/SubAgent との連携
  - 各 SubAgent（9個）について：
    - 公式仕様の「SubAgents とは何か」との対応
    - tools リスト
    - description の「PROACTIVELY」「AUTOMATICALLY」キーワード
    - trigger 条件
  - 各 Skill（9個）について：
    - description の内容
    - triggers リスト
    - 参照タイミング

test_method: |
  1. extension-system.md → 各セクション番号をメモ（例：Section 2.1 = SubAgents）
  2. 現在実装の各ファイル → 対応する extension-system.md セクション番号を併記
  3. 仕様との「ズレ」があれば「已知の仕様外」と明記

executor: claude_code
evidence: phase-4-justification.md（新規作成ファイル）

known_issues: []
```

### Phase 5: 依存関係図の作成

```yaml
current_phase: 5
status: done

summary: |
  Hooks/SubAgents/Skills/Commands 間の依存関係を図で表現する。
  「A が発火したら B が自動で呼び出される」「B の出力が C の入力になる」
  などの関係を明確にし、視認性を確保する。

done_criteria:
  - Hook 間の依存関係図が作成されている（例：session-start.sh → init-guard.sh）
  - SubAgent 呼び出し元（Hooks/CLAUDE.md）が記載されている
  - Skill 参照タイミング（どの Hook/SubAgent/Command から参照されるか）が記載されている
  - Command 実行フロー（ユーザーが呼び出す場合）が表現されている
  - 循環依存がないことが確認されている
  - 削除した場合の影響範囲が明確になっている

test_method: |
  1. session-start.sh を削除したら何が壊れるか → session_tracking, pending ファイル生成ロジック消失
  2. init-guard.sh を削除したら → 必須 Read が強制されない
  3. 各ファイルについて「削除されたら影響を受ける他ファイル」を列挙

executor: claude_code
evidence: phase-5-dependencies.md（新規作成ファイル）

known_issues: []
```

### Phase 6: 復旧手順の文書化

```yaml
current_phase: 6
status: done

summary: |
  「何を失ったら、どのファイルを復旧すればよいか」を明記する。
  例：「settings.json が破損した場合」「.claude/hooks/ が削除された場合」
  など、シナリオ別の復旧リストアップ。

done_criteria:
  - 18 個の Hook ファイル（settings.json 登録/非登録）について「なくなった場合の復旧手順」
  - 9 個の SubAgent について「なくなった場合」の復旧手順
  - 9 個の Skill について「なくなった場合」の復旧手順
  - settings.json が破損した場合の復旧スクリプト仕様
  - .claude/protected-files.txt が削除された場合の復旧方法
  - セッション再開時に必要な state.md リセット手順
  - 「最小限のセットアップで最大限の機能を復旧する」優先順位が明記されている

test_method: |
  1. session-start.sh を削除した後、新規セッション開始時に何が起きるか
  2. settings.json から「prompt-guard.sh」の登録削除 → プロンプト入力時に Hook が発火しない
  3. 復旧リスト：「まず settings.json を復旧」「次に Hook ファイル」など優先度順

executor: claude_code
evidence: phase-6-recovery.md（新規作成ファイル）

known_issues: []
```

### Phase 7: 不要ファイル選定と削除計画

```yaml
current_phase: 7
status: done

summary: |
  以下を確認し、「削除しても仕組みが動く」ファイルを特定する。
  古いテンプレートや冗長なドキュメント、テスト結果ファイルなど。

done_criteria:
  - .archive/ の内容確認（何が退避済みか）
  - spec.yaml（現在 .archive/ にあるはず）の削除の是非確認
  - docs/ の不要ドキュメント確認（例：古い architecture-*.md）
  - .claude/tests/ の古いテスト結果削除
  - playbook-system-improvements.md の .archive/plan/ 移動確認
  - 削除予定リスト最終確定（ファイル一覧）
  - 各ファイルについて「なぜ削除できるか」根拠を記載

test_method: |
  1. .archive/plan/ → ls で削除済み playbook 確認
  2. .archive/spec.yaml の削除理由確認
  3. spec.yaml vs docs/current-implementation.md の重複確認
  4. docs/architecture-*.md の廃止確認（extension-system.md に統合済み）
  5. 削除後 git status, git log で影響範囲確認

executor: claude_code
evidence: phase-7-cleanup-list.md（新規作成ファイル）

known_issues:
  - .archive/ の復元方法が文書化されているか確認必要
  - state.md の upper_plans セクションが古い参照を持っていないか確認
```

### Phase 8: 最終版 current-implementation.md 作成

```yaml
current_phase: 8
status: done

summary: |
  Phases 1-7 の成果物を統合し、最終版 current-implementation.md を作成する。
  以下を含む「Single Source of Truth」となる仕様書。

done_criteria:
  - 「Section 0: 概要」として Macro 目標と done_criteria を記載
  - 「Section 1: Hooks 完全仕様」（Phase 2, 4 の成果物）
  - 「Section 2: SubAgents 完全仕様」（Phase 2, 4 の成果物）
  - 「Section 3: Skills 完全仕様」（Phase 2, 4 の成果物）
  - 「Section 4: Commands 完全仕様」
  - 「Section 5: 入力→処理→出力フロー」（Phase 3）
  - 「Section 6: 依存関係図」（Phase 5）
  - 「Section 7: 復旧手順」（Phase 6）
  - 「Section 8: 削除可能ファイルリスト」（Phase 7）
  - 「Section 9: 変更履歴」（本 playbook の完了を記載）
  - 目次と相互参照が完全
  - markdownlint でエラーなし

test_method: |
  1. 新 current-implementation.md を作成
  2. extension-system.md との相互参照をすべてチェック
  3. plan/project.md との一貫性確認
  4. CLAUDE.md の INIT → [自認] での参照確認
  5. 全セクション読み込み → 100% 充足確認

executor: claude_code
evidence: 新規作成ファイル /Users/amano/Desktop/thanks4claudecode/docs/current-implementation.md

known_issues: []
```

---

## meta

```yaml
issue: null  # 確認後追加
priority: high  # vision の達成に直結
estimated_effort: 6h  # Phases 1-8, 各 30-45min
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。Macro 導出により project.md vision 達成に向けた playbook 生成。8 Phase 定義。 |
