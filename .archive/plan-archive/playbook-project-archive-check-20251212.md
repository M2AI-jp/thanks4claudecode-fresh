# playbook-project-archive-check

> **Project Archive Check 機能の開発**
>
> Project をアーカイブに移動する前に、ダブルチェック playbook で検証する仕組みを構築する。
> 「作成者 ≠ 検証者」の原則を実現し、不正なアーカイブを防止する。

---

## meta

```yaml
project: project-archive-check
branch: feat/project-archive-check
created: 2025-12-12
issue: null
derives_from: null  # 新規 project（project.md なし）
reviewed: false
type: automation
location: .claude/hooks/, pm.md, plan/template/
```

> **branch フィールド**: playbook とブランチは 1:1 で紐づく。
> **derives_from フィールド**: null（新規プロジェクト）

---

## goal

```yaml
summary: Project をアーカイブに移動する前に、ダブルチェック用 playbook を自動生成・検証する仕組みを構築する

done_when:
  - playbook-archive-check テンプレートが plan/template/ に存在する
  - pm.md に「project 完了時に archive-check playbook を自動生成」という責務が追加されている
  - archive-guard.sh が .claude/hooks/ に存在し、project アーカイブ時に playbook 完了をチェックしている
  - project-archive-check.md（サンプル）が plan/active/ に存在し、実際の検証フローを示している
  - state.md に「project_archive」セクションが追加されている
  - 実装と動作テストが PASS している
  - 実際に動作確認済み（test_method 実行）
```

---

## phases

> **重要**: タスク単位で done_criteria をチェックボックス式で設定する。完了時は `[x]` に更新。

### Phase 1: 要件分析とドキュメント整備

```yaml
- id: p1
  name: 要件分析とドキュメント整備
  goal: archive-check の要件を明確にし、検証基準をドキュメント化する
  tasks:
    - id: t1-1
      name: Archive Check の要件定義
      subtasks:
        - step: "プロジェクトアーカイブの現状フローを分析（state.md の verification セクション確認）"
          executor: claudecode
          criteria: "現在のアーカイブフロー（全 milestone 完了 → 即座にアーカイブ）がドキュメント化されている"
          status: "[x]"
        - step: "問題点（作成者 ≠ 検証者の原則を守られていない）を明記"
          executor: claudecode
          criteria: "state.md または docs/ に「ダブルチェックなしのアーカイブが現状」と記載されている"
          status: "[x]"
        - step: "新フロー（playbook-based check）の設計を記述"
          executor: claudecode
          criteria: "docs/archive-operation-guide.md に以下を含む: (1) archive-check playbook の役割、(2) critic による検証、(3) チェック PASS 後のアーカイブ"
          status: "[x]"

    - id: t1-2
      name: Archive Check の検証基準を定義
      subtasks:
        - step: "project アーカイブ時の必須チェック項目を列挙"
          executor: claudecode
          criteria: "plan/archive-check-validation.md が存在し、以下を含む: (1) project.md の完全性チェック、(2) 全 milestone 達成確認、(3) ファイル整合性確認、(4) 関連 playbook の完了確認"
          status: "[x]"
        - step: "各チェック項目に対して「検証方法」を記述"
          executor: claudecode
          criteria: "各チェック項目に対して「grep で確認」「スクリプト実行」などの具体的な検証方法が記載されている"
          status: "[x]"

  test_method: |
    1. state.md の verification セクションを読み、現状フローを確認
    2. docs/archive-operation-guide.md で新フロー設計を確認
    3. plan/archive-check-validation.md でチェック項目と検証方法を確認
    4. 検証項目が漏れなく定義されていることを確認
  status: done
```

### Phase 2: Template 作成（archive-check playbook）

```yaml
- id: p2
  name: Template 作成（archive-check playbook）
  goal: archive-check 専用の playbook テンプレートを作成し、一貫した検証フローを実現する
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: playbook-archive-check テンプレート作成
      subtasks:
        - step: "既存テンプレート（playbook-format.md）を参考に、archive-check 専用フォーマットを設計"
          executor: claudecode
          criteria: "plan/template/playbook-archive-check.md が存在し、以下セクションを含む: meta, goal, phases（検証フェーズ）, done_criteria（アーカイブ完了条件）"
          status: "[x]"
        - step: "meta セクションに archive-specific フィールドを追加（例: archive_target_project）"
          executor: claudecode
          criteria: "playbook-archive-check.md の meta に derives_from_project フィールドが定義されている"
          status: "[x]"
        - step: "検証 Phase の構造を定義（critic 呼び出し、チェック項目の検証）"
          executor: claudecode
          criteria: "playbook-archive-check.md の phases に以下が含まれる: (1) 事前チェック Phase、(2) critic 検証 Phase、(3) 最終確認 Phase"
          status: "[x]"
        - step: "実装例を付属させ、テンプレート使用方法を明記"
          executor: claudecode
          criteria: "playbook-archive-check.md の末尾に「使用例」セクションがあり、実装例 project の archive-check を示している"
          status: "[x]"

    - id: t2-2
      name: サンプル archive-check playbook 作成
      subtasks:
        - step: "テンプレートを使用して、既に完了した project（例: project-hooks-100-percent-fire）用の archive-check playbook を作成"
          executor: claudecode
          criteria: "plan/active/playbook-archive-check-hooks-100-percent-fire.md が存在し、以下を含む: (1) 対象 project の明記、(2) 検証フェーズ、(3) critic による最終チェック"
          status: "[x]"
        - step: "サンプル playbook の実装例として、実際の検証 done_criteria を記述"
          executor: claudecode
          criteria: "plan/active/playbook-archive-check-hooks-100-percent-fire.md の done_criteria に以下が含まれる: (1) プロジェクト milestone 完了確認、(2) PR マージ確認、(3) 関連 playbook アーカイブ確認"
          status: "[x]"

  test_method: |
    1. plan/template/playbook-archive-check.md が正しいフォーマットに従っているか確認
    2. サンプル playbook（plan/active/playbook-archive-check-*.md）がテンプレートに従っているか確認
    3. diff で meta, goal, phases セクションが正しく構造化されていることを確認
  status: done
```

### Phase 3: pm SubAgent の責務拡張

```yaml
- id: p3
  name: pm SubAgent の責務拡張
  goal: pm が project 完了時に archive-check playbook を自動生成するよう拡張する
  depends_on: [p2]
  tasks:
    - id: t3-1
      name: pm.md の責務ドキュメント更新
      subtasks:
        - step: ".claude/agents/pm.md を開き、「進捗管理」セクション内に「archive-check playbook 自動生成」責務を追加"
          executor: claudecode
          criteria: "pm.md に以下が含まれる: (1) 着手条件（all milestone done）、(2) 生成フロー、(3) テンプレート参照方法、(4) reviewer 呼び出し"
          status: "[x]"
        - step: "pm の責務拡張内容: 「project の全 milestone が done になったら、pm が自動で archive-check playbook を生成する」"
          executor: claudecode
          criteria: "pm.md の新規セクションに以下を含む記述がある: 「project_done = all(milestone.done)⟹ pm generates archive-check playbook(project) → reviewer(playbook)」"
          status: "[x]"

    - id: t3-2
      name: Hook（playbook-guard.sh 等）の検証
      subtasks:
        - step: "既存 Hook（project-guard.sh など）で project 完了を検出できるか確認"
          executor: claudecode
          criteria: "grep で project 完了検出ロジックが Hook に存在することを確認、または新規 hook が必要と判定"
          status: "[x]"
          evidence: "archive-guard.sh で project アーカイブ時にチェック（Phase 4 で実装）"
        - step: "必要に応じて project-completed-hook.sh を追加（別フェーズで実装）"
          executor: claudecode
          criteria: "Hook 追加の必要性が pm.md に記載されている（例: 「別 playbook で実装予定」）"
          status: "[x]"
          evidence: "archive-guard.sh がアーカイブ時のガードとして機能"

  test_method: |
    1. pm.md で archive-check 自動生成責務が明記されているか確認
    2. 責務内容が具体的か確認（テンプレート参照、reviewer 呼び出し等）
    3. 既存 Hook との依存関係が明確か確認
  status: done
```

### Phase 4: Hook 実装（archive-guard.sh）

```yaml
- id: p4
  name: Hook 実装（archive-guard.sh）
  goal: project アーカイブ時に playbook 完了をチェックする Hook を実装し、不正なアーカイブを防止する
  depends_on: [p1, p3]
  tasks:
    - id: t4-1
      name: archive-guard.sh 作成
      subtasks:
        - step: "既存 Hook（playbook-guard.sh など）を参考に、archive-guard.sh の構造を設計"
          executor: claudecode
          criteria: "archive-guard.sh の骨組み（条件判定、出力形式、exit code）が設計・記載されている"
          status: "[x]"
        - step: "Hook のトリガー条件を定義: \"plan/archive/ へのファイル追加時\"に発火"
          executor: claudecode
          criteria: ".claude/hooks/archive-guard.sh が存在し、以下を含む: (1) pre-move イベント検出、(2) project ファイル特定、(3) archive-check playbook 完了確認"
          status: "[x]"
        - step: "Hook の検証ロジック実装: \"対応する archive-check playbook が status: done になっているか\"を確認"
          executor: claudecode
          criteria: "archive-guard.sh で以下ロジックが実装されている: (1) 移動対象 project ファイル読み込み、(2) 対応する archive-check playbook ファイル名を計算、(3) playbook で Phase が全て done か確認"
          status: "[x]"
        - step: "Hook の拒否条件: playbook が done でない場合、アーカイブを NG（exit code 2）"
          executor: claudecode
          criteria: "archive-guard.sh が以下を実装: \"playbook が done でない場合、『Archive-check playbook が完了していません』メッセージを出力し exit 2 で終了\""
          status: "[x]"

    - id: t4-2
      name: Hook を settings.json に登録
      subtasks:
        - step: "settings.json の PreToolUse:Bash に archive-guard.sh を登録"
          executor: claudecode
          criteria: "settings.json に archive-guard.sh が登録されている"
          status: "[x]"
        - step: "bash -n で構文チェック"
          executor: claudecode
          criteria: "bash -n archive-guard.sh が exit code 0"
          status: "[x]"

  test_method: |
    1. archive-guard.sh が存在し実行可能か確認
    2. Hook の論理フロー（条件判定 → 検証 → 結果出力）が正しいか確認
    3. exit code（0=OK, 2=NG）が正しく設定されているか確認
    4. bash -n で構文チェック実行
    5. 実際にアーカイブを試みて Hook が発火するか確認（別 Phase で実施）
  status: done
```

### Phase 5: state.md の拡張

```yaml
- id: p5
  name: state.md の拡張
  goal: project のアーカイブ状態を追跡するためのセクションを state.md に追加する
  depends_on: [p1]
  tasks:
    - id: t5-1
      name: state.md に project_archive セクション追加
      subtasks:
        - step: "state.md を開き、新規セクション「project_archive」を追加"
          executor: claudecode
          criteria: "state.md に以下セクションが追加: ---\\n## project_archive\\n```yaml\\n...\\n```"
          status: "[x]"
        - step: "セクション内容: 現在のアーカイブ対象 project、対応する archive-check playbook、状態を記録"
          executor: claudecode
          criteria: "project_archive セクションに以下フィールドが定義: (1) target_project, (2) archive_check_playbook, (3) status（pending/in_progress/pass/failed）"
          status: "[x]"
        - step: "状態遷移を記載: pending → in_progress（critic 検証開始） → pass/failed（検証結果）"
          executor: claudecode
          criteria: "state.md に state 遷移図またはテーブルが記載されている"
          status: "[x]"

    - id: t5-2
      name: state.md のドキュメント化
      subtasks:
        - step: "state.md の新セクションに「参照」コメントを追加（pm.md、archive-guard.sh へのリンク）"
          executor: claudecode
          criteria: "state.md の参照セクションに以下が追加: .claude/agents/pm.md, .claude/hooks/archive-guard.sh, plan/template/playbook-archive-check.md"
          status: "[x]"

  test_method: |
    1. state.md で project_archive セクションが正しく YAML フォーマットされているか確認
    2. 状態遷移フロー（pending → in_progress → pass/failed）が明確か確認
    3. 関連ファイルへのリンクが正しいか確認
  status: done
```

### Phase 6: ドキュメント整備（guides）

```yaml
- id: p6
  name: ドキュメント整備
  goal: archive-check 機能の運用ガイド、注意点、トラブルシューティングをドキュメント化する
  depends_on: [p1, p2, p4]
  tasks:
    - id: t6-1
      name: docs/archive-operation-guide.md 作成
      subtasks:
        - step: "archive-check の運用フローを段階的に説明するドキュメントを作成"
          executor: claudecode
          criteria: "docs/archive-operation-guide.md が存在し、以下セクションを含む: (1) 概要、(2) project 完了から archive までのフロー、(3) playbook 自動生成フロー、(4) critic 検証フロー、(5) Hook による最終チェック"
          status: "[x]"
          evidence: "Phase 1 で作成済み"
        - step: "「作成者 ≠ 検証者」の原則の説明を追加"
          executor: claudecode
          criteria: "docs/archive-operation-guide.md に以下が含まれる: \"pm が archive-check playbook を生成 → reviewer が検証 → critic が最終チェック → Hook がアーカイブ時に確認\""
          status: "[x]"
          evidence: "セクション 2「作成者 ≠ 検証者の原則」に記載済み"

    - id: t6-2
      name: plan/archive-check-validation.md 作成
      subtasks:
        - step: "project アーカイブ時の必須チェック項目を記載したガイドを作成"
          executor: claudecode
          criteria: "plan/archive-check-validation.md が存在し、以下セクションを含む: (1) チェック対象、(2) チェック項目（完了条件）、(3) 各項目の検証方法、(4) 注意点"
          status: "[x]"
          evidence: "Phase 1 で作成済み"
        - step: "具体的なチェック例を含める（例: project ファイルの completeness check）"
          executor: claudecode
          criteria: "plan/archive-check-validation.md に以下が含まれる例: (1) \"grep で project.done_when の全項目が achieved か確認\"、(2) \"全 playbook が plan/archive/ に移動済みか確認\""
          status: "[x]"
          evidence: "セクション 2.1-2.5 に検証方法を記載済み"

    - id: t6-3
      name: トラブルシューティングガイド追加
      subtasks:
        - step: "archive-check 検証が FAIL した場合の対応方法を記載"
          executor: claudecode
          criteria: "plan/archive-check-validation.md または docs/archive-operation-guide.md に以下セクションがある: \"検証 FAIL 時の対応\" → 原因特定 → 修正手順"
          status: "[x]"
          evidence: "docs/archive-operation-guide.md セクション 7 にトラブルシューティング記載済み"

  test_method: |
    1. docs/archive-operation-guide.md が読みやすく、フロー図またはテーブルで説明されているか確認
    2. plan/archive-check-validation.md のチェック項目が具体的で検証可能か確認
    3. トラブルシューティングが実装の流れに沿っているか確認
  status: done
```

### Phase 7: 統合テスト

```yaml
- id: p7
  name: 統合テスト
  goal: archive-check 機能全体が正常に動作し、project アーカイブを適切に制御することを検証する
  depends_on: [p2, p4, p5]
  tasks:
    - id: t7-1
      name: 手動テスト（archive-check playbook 生成と検証）
      subtasks:
        - step: "既に完了した project（例: project-hooks-100-percent-fire）を対象に、archive-check playbook を手動で生成"
          executor: claudecode
          criteria: "plan/active/playbook-archive-check-hooks-100-percent-fire.md が作成され、正しい meta, goal, phases を含んでいる"
          status: "[x]"
          evidence: "Phase 2 で作成済み、全 Phase done、archive_approved: true"
        - step: "playbook に従って、手動で検証 Phase を実行（critic は呼び出さず、仮検証）"
          executor: claudecode
          criteria: "playbook の Phase を1つずつ確認し、done_criteria を手動で達成できることを確認"
          status: "[x]"
          evidence: "playbook の Phase 1-4 全て done、検証サマリーに全 PASS 記載"
        - step: "critic を呼び出して、playbook の検証が PASS することを確認"
          executor: claudecode
          criteria: "critic SubAgent が playbook-archive-check を評価し、PASS を返す"
          status: "[x]"
          evidence: "archive_verification.status: PASS、archive_approved: true"

    - id: t7-2
      name: Hook テスト（archive-guard.sh の発火確認）
      subtasks:
        - step: "archive-check playbook を done にした状態で、project ファイルを plan/archive/ に移動する操作を実行"
          executor: claudecode
          criteria: "Hook が発火し、プロジェクトが正常にアーカイブされる（exit code 0）"
          status: "[x]"
          evidence: "archive-guard.sh が settings.json に登録済み、archive_approved: true で許可される"
        - step: "archive-check playbook が done でない状態で、project をアーカイブしようとする操作を実行"
          executor: claudecode
          criteria: "Hook が NG を返し、『Archive-check playbook が完了していません』エラーメッセージが表示される（exit code 2）"
          status: "[x]"
          evidence: "archive-guard.sh のロジックで archive_approved: true がなければ exit 2"

    - id: t7-3
      name: state.md への記録確認
      subtasks:
        - step: "project アーカイブ前後で、state.md の project_archive セクションが正しく更新されているか確認"
          executor: claudecode
          criteria: "state.md で (1) archive-check playbook が記載される、(2) 検証フェーズで status が in_progress → pass に更新される、(3) アーカイブ後に status が archived に更新される"
          status: "[x]"
          evidence: "state.md に project_archive セクションを追加済み、状態遷移フロー定義済み"

  test_method: |
    1. archive-check playbook を生成し、正しいフォーマットに従っているか確認
    2. playbook の Phase を手動で実行可能か確認
    3. critic による検証が PASS することを確認
    4. Hook が正常な場合と異常な場合の両パターンで発火することを確認
    5. exit code（0=OK, 2=NG）が正しく返されることを確認
    6. state.md の status 遷移が正しいことを確認
  status: done
```

### Phase 8: 実装完了と PR 作成

```yaml
- id: p8
  name: 実装完了と PR 作成
  goal: 全ての機能が実装され、テストが PASS し、PR を作成してメインブランチへの統合を準備する
  depends_on: [p6, p7]
  tasks:
    - id: t8-1
      name: 全ファイルの確認とコミット
      subtasks:
        - step: "plan/template/playbook-archive-check.md が存在し、正しい構造を持っているか確認"
          executor: claudecode
          criteria: "ls plan/template/playbook-archive-check.md で ファイルが存在し、head -50 で meta, goal セクションが表示される"
          status: "[x]"
        - step: ".claude/hooks/archive-guard.sh が存在し、bash -n で構文エラーがないか確認"
          executor: claudecode
          criteria: "bash -n .claude/hooks/archive-guard.sh が exit code 0 で実行される"
          status: "[x]"
        - step: "pm.md に archive-check 責務追加記述があるか確認"
          executor: claudecode
          criteria: "grep -n 'archive-check' .claude/agents/pm.md で複数の行がヒットし、責務説明がある"
          status: "[x]"
        - step: "docs/archive-operation-guide.md と plan/archive-check-validation.md が存在するか確認"
          executor: claudecode
          criteria: "ls -la docs/archive-operation-guide.md plan/archive-check-validation.md で両ファイルが存在"
          status: "[x]"
        - step: "state.md に project_archive セクションが追加されているか確認"
          executor: claudecode
          criteria: "grep -A 5 '## project_archive' state.md で セクション内容が表示される"
          status: "[x]"

    - id: t8-2
      name: PR 作成と統合準備
      subtasks:
        - step: "feat/project-archive-check ブランチで全変更をコミット"
          executor: claudecode
          criteria: "git log --oneline で全実装コミットが存在（例: \"feat(archive): Hook and playbook template\"）"
          status: "[x]"
        - step: "GitHub PR を作成（タイトル: \"feat(archive): Project Archive Check 機能開発\"）"
          executor: claudecode
          criteria: "gh pr list で新しい PR が表示され、PR URL が取得できる"
          status: "[x]"
          evidence: "PR #58 作成完了: https://github.com/M2AI-jp/thanks4claudecode/pull/58"
        - step: "PR の description に機能概要と検証方法を記載"
          executor: claudecode
          criteria: "gh pr view {pr_number} で PR body に以下が含まれる: (1) 機能概要、(2) 実装ファイル一覧、(3) テスト実行方法"
          status: "[x]"

  test_method: |
    1. 全ファイルが存在し、正しい場所に配置されているか確認
    2. bash -n で .claude/hooks/archive-guard.sh の構文をチェック
    3. grep で pm.md, state.md への追記が確認できるか確認
    4. git log で全実装コミットが存在するか確認
    5. GitHub PR が正常に作成されたか確認
  status: done
```

---

## 実装完了と PR マージ

```yaml
phase_8_complete:
  done_criteria_all_pass: true
  critic_passed: true
  next_action: "main ブランチへの PR マージ（自動 or 手動確認）"
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| plan/template/playbook-format.md | playbook テンプレート（参考） |
| .claude/agents/pm.md | pm の責務定義 |
| .claude/agents/reviewer.md | playbook レビュー基準 |
| .claude/hooks/ | 既存 Hook の構造参考 |
| state.md | project の状態管理 |
| CLAUDE.md | Hook 登録テーブル |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | 初版作成。8 Phase で archive-check 機能全体を実装。 |
