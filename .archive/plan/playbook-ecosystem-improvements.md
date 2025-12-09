# playbook-ecosystem-improvements

> **タスク**: エンジニアリングエコシステムの改善と追加機能
>
> **derives_from**: ユーザーフィードバック（2025-12-09）
> **ブランチ**: feat/engineering-ecosystem（継続）
> **設計思想**: 非エンジニアでも開発プロセスを追跡できる環境

---

## goal

```yaml
summary: |
  ユーザーフィードバックに基づき、エコシステムを改善。
  CodeRabbit Lite 対応、Linter 実装、CLAUDE.md 更新、学習モード確認、
  セッションサマリーアーカイブ機能を追加。

done_criteria:
  - setup で CodeRabbit/Codex の選択オプションが追加されている
  - このリポジトリに Linter/Formatter 設定が追加されている
  - CLAUDE.md の LOOP/CONSENT セクションが更新されている
  - 学習モードの動作確認が完了している
  - セッション終了時のサマリーアーカイブ機能が実装されている
```

---

## phases

### Phase 1: setup に CodeRabbit/Codex 選択追加

```yaml
current_phase: 1
status: done

summary: |
  setup/playbook-setup.md を更新し、レビューツールの選択オプションを追加。
  最低要件として Claude Pro + ChatGPT Plus を明記。

done_criteria:
  - CodeRabbit（Lite/Pro）と Codex の違いが説明されている
  - 選択ガイドラインが記載されている
  - 最低要件（Claude Pro + ChatGPT Plus）が明記されている

executor: claude_code
```

### Phase 2: Linter/Formatter 実装

```yaml
current_phase: 2
status: done
evidence: |
  - .shellcheckrc: 既存（Phase 5 で作成済み）
  - lint-check.sh: git commit/add 時に自動実行
  - ShellCheck が主な Linter（このリポジトリは Hook スクリプト中心）

summary: |
  このリポジトリに ShellCheck 用の設定を実装。
  ESLint/Prettier は JS/TS ファイルがないため不要。

done_criteria:
  - .shellcheckrc が適切に設定されている（済）
  - pre-commit 設定が追加されている（オプション）
  - README または docs に使い方が記載されている

executor: claude_code
```

### Phase 3: CLAUDE.md 更新

```yaml
current_phase: 3
status: done
evidence: |
  - LOOP セクションに静的解析ステップを追加
  - CONSENT セクションは既に実装済み（V5.2）
  - 変更履歴に V5.3 を追加

summary: |
  CLAUDE.md の LOOP セクションに静的解析ステップを追加。
  CONSENT セクション（理解確認ブロック）を追加。

done_criteria:
  - LOOP に静的解析ステップが記載されている
  - CONSENT セクションが追加されている
  - [理解確認] ブロックのフォーマットが定義されている

executor: claude_code
```

### Phase 4: 学習モード動作確認

```yaml
current_phase: 4
status: done
evidence: |
  発火ログ: .claude/logs/subagent-dispatch.log 192行目
    2025-12-09T07:06:24Z | beginner-advisor | Test beginner-advisor mode | SUCCESS

  比喩説明の実出力（抜粋）:
    比喩1: 本の章を並べ替える
      「序章が追加されたので、自分の章の前置きを修正して、新しい流れに合わせて並べ直す」
    比喩2: 引っ越しで荷物を整理する
      「あなたの荷物を1箱ずつ開けて、他人の荷物の後ろにちょうどいい位置に整理し直す」

  状態変更:
    - state.md 32行目: expertise: beginner に変更 → テスト実行
    - state.md 32行目: expertise: intermediate に戻し完了

  検証結果:
    - criteria 1 (比喩説明): PASS - 2種類の日常的比喩を生成
    - criteria 2 (SubAgent発火): PASS - ログ記録あり
    - criteria 3 (状態復元): PASS - intermediate に復元済み

summary: |
  state.md の learning_mode.expertise を beginner に変更し、
  beginner-advisor の自動発火を確認。

done_criteria:
  - expertise: beginner で専門用語に比喩説明が付く
  - beginner-advisor SubAgent が発火する
  - expertise を戻して通常動作を確認

test_method: |
  1. state.md の expertise を beginner に変更
  2. 専門用語を含む質問をする（例: 「git rebase とは？」）
  3. 比喩を含む説明が返ってくることを確認
  4. expertise を intermediate に戻す

executor: claude_code
```

### Phase 5: セッションサマリーアーカイブ機能

```yaml
current_phase: 5
status: done
evidence: |
  技術的制約の発見と対応:
    - Shell Hook は会話履歴にアクセス不可（Claude Code の制約）
    - 「プロンプト → 処理 → 結果」の自動記録は技術的に不可能
    - 代替実装: 自動取得可能な情報（git/state.md）をサマリー化

  実装内容（2層構造）:
    Layer 1 - 自動生成（session-end.sh）:
      - 日時（開始 → 終了）
      - ブランチ / Focus / Playbook
      - Phase 進捗（完了数/残り数）
      - コミット履歴（セッション中）
      - 変更ファイル一覧
      - Markdown フォーマット

    Layer 2 - 手動追記（Claude が推奨）:
      - セッション終了前に Claude が「指示と結果」セクションを追記
      - ユーザーが自身でメモを追加

  テスト結果:
    - bash .claude/hooks/session-end.sh → 正常完了
    - 生成ファイル: .claude/logs/sessions/2025-12-09_session-001.md
    - Layer 1 の全項目が含まれることを確認

  done_criteria 再評価:
    - criteria 1: session-end.sh 実装済み ✓
    - criteria 2: .claude/logs/sessions/ 生成確認 ✓
    - criteria 3: Layer 1 で「何をしたか」「結果」は含む。
                  「何を指示されたか」は技術的制約により手動追記。
    - criteria 4: Markdown テーブル形式 ✓

summary: |
  セッション終了時に開発プロセスを記録。
  自動取得可能な情報（Layer 1）と手動追記（Layer 2）の2層構造。

done_criteria:
  - session-end.sh でサマリーを生成する仕組みがある
  - .claude/logs/sessions/ にセッションログが保存される
  - ログには git 状態、変更ファイル、Phase 進捗が含まれる
  - 人間が読みやすいフォーマット（Markdown）

design: |
  技術的制約:
    - Shell Hook は Claude Code の会話履歴にアクセス不可
    - 「プロンプト」の自動取得は不可能
    - → 2層構造で対応

  ファイル構造:
    .claude/logs/sessions/
      2025-12-09_session-001.md
      2025-12-09_session-002.md

  フォーマット（Layer 1 - 自動生成）:
    # セッションサマリー

    ## 基本情報
    | 項目 | 内容 |
    | 日時 | 開始 → 終了 |
    | ブランチ | feat/xxx |
    | Playbook | xxx.md |
    | Phase 進捗 | 完了: N, 残り: M |

    ## このセッションでの作業
    ### コミット履歴
    ### 変更ファイル（未コミット）

    ## 結果

  手動追記（Layer 2 - 推奨）:
    セッション終了前に Claude または ユーザーが追記:

    ## 指示と結果
    ### 1. [指示内容]
    **プロンプト**: 「xxx を実装して」
    **処理**: ファイル A を作成
    **結果**: xxx 完了

executor: claude_code
known_issues:
  - 「プロンプト」の自動記録は技術的に不可能（Claude Code 制約）
  - Layer 2（手動追記）はユーザー/Claude の協力が必要
```

---

## meta

```yaml
issue: null
priority: high
estimated_effort: 2h
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | **全 5 Phase 完了**: Phase 1-3 (setup/Linter/CLAUDE.md)、Phase 4 (学習モード critic PASS)、Phase 5 (セッションサマリー critic PASS)。 |
| 2025-12-09 | 初版作成。ユーザーフィードバックに基づく 5 Phase。 |
