# playbook-m021-changelog-suggest.md

> **CHANGELOG サジェストシステム - 機能提案エンジン**
>
> M020 で実装した CHANGELOG モニタリングを拡張し、
> 新バージョン検出時に関連する新機能を自動提案するシステム。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m021-changelog-suggest
created: 2025-12-13
issue: null
derives_from: M021  # project.milestone の ID
reviewed: false
```

---

## goal

```yaml
summary: |
  CHANGELOG の新機能をこのリポジトリの特性に基づいて分析し、
  自動的に活用可能な機能を優先度付きで提案するシステムを構築する。

done_when:
  - repo-profile.json が作成され、リポジトリ特性が定義されている
  - changelog-checker.sh がキーワード抽出とマッチングを行う
  - 新バージョン通知に関連機能のサジェストが含まれる
  - /changelog --suggest で詳細な適用可能性分析が表示される
  - 優先度（高・中・低）で機能が分類される
```

---

## phases

### p1: リポジトリプロファイル定義

> リポジトリが使用している機能と関心領域を定義するプロファイルを作成

```yaml
- id: p1
  name: "リポジトリプロファイル定義"
  goal: |
    .claude/cache/repo-profile.json を作成し、
    このリポジトリの機能カテゴリ、関心領域、優先度キーワードを定義する。

  subtasks:
    - id: p1.1
      criterion: ".claude/cache/repo-profile.json が作成されている"
      executor: claudecode
      test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json && echo PASS"

    - id: p1.2
      criterion: "repo-profile.json に5つ以上の機能カテゴリが定義されている"
      executor: claudecode
      test_command: "grep -c '\"category\"' /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json | awk '{if($1>=5) print \"PASS\"; else print \"FAIL\"}'"

    - id: p1.3
      criterion: "repo-profile.json に関心領域（interest_areas）が定義されている"
      executor: claudecode
      test_command: "grep -q 'interest_areas' /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json && echo PASS"

    - id: p1.4
      criterion: "repo-profile.json に優先度キーワード（priority_keywords）が定義されている"
      executor: claudecode
      test_command: "grep -q 'priority_keywords' /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json && echo PASS"

    - id: p1.5
      criterion: "repo-profile.json の JSON が有効である"
      executor: claudecode
      test_command: "cat /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json | jq empty && echo PASS"

  status: pending
  max_iterations: 5

---

### p2: changelog-checker.sh の拡張

> CHANGELOG からキーワード抽出を行い、repo-profile.json とマッチングして関連機能を検出

```yaml
- id: p2
  name: "changelog-checker.sh の拡張"
  goal: |
    changelog-checker.sh を拡張して、
    CHANGELOG からキーワード抽出を行い、
    repo-profile.json とマッチングし、
    新バージョン通知に関連機能を追加する。
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "changelog-checker.sh に keyword_extraction 関数が実装されている"
      executor: claudecode
      test_command: "grep -q 'keyword_extraction' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p2.2
      criterion: "changelog-checker.sh が repo-profile.json を読み込んでいる"
      executor: claudecode
      test_command: "grep -q 'repo-profile.json' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p2.3
      criterion: "changelog-checker.sh が3つ以上のキーワードマッチングを実行する"
      executor: claudecode
      test_command: "grep -c 'grep.*-i' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh | awk '{if($1>=3) print \"PASS\"; else print \"FAIL\"}'"

    - id: p2.4
      criterion: "マッチング結果が SUGGESTION_MESSAGE に追加されている"
      executor: claudecode
      test_command: "grep -q 'SUGGESTION_MESSAGE' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p2.5
      criterion: "changelog-checker.sh が正常に実行でき、エラーが発生しない"
      executor: claudecode
      test_command: "bash /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh >/dev/null 2>&1 && echo PASS"

  status: pending
  depends_on: [p1]
  max_iterations: 5

---

### p3: 新バージョン通知の拡張

> 新バージョン検出時に関連機能のサジェストを含める

```yaml
- id: p3
  name: "新バージョン通知の拡張"
  goal: |
    新バージョン検出時に、
    SUGGESTION_MESSAGE が systemMessage に含まれるようにする。
  depends_on: [p2]

  subtasks:
    - id: p3.1
      criterion: "SessionStart Hook が SUGGESTION_MESSAGE を systemMessage に追加している"
      executor: claudecode
      test_command: "grep -q 'SUGGESTION_MESSAGE' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && echo PASS"

    - id: p3.2
      criterion: "新バージョン通知メッセージに関連機能情報が含まれている形式が定義されている"
      executor: claudecode
      test_command: "grep -q 'Suggested features' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p3.3
      criterion: "systemMessage への追加ロジックがテスト可能である"
      executor: claudecode
      test_command: "grep -q 'echo.*SUGGESTION_MESSAGE' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

  status: pending
  depends_on: [p2]
  max_iterations: 5

---

### p4: /changelog --suggest オプション実装

> /changelog コマンドに --suggest オプションを追加し、詳細な適用可能性分析を実行

```yaml
- id: p4
  name: "/changelog --suggest オプション実装"
  goal: |
    /changelog コマンドに --suggest オプションを追加して、
    新機能の詳細な適用可能性分析、優先度付け、
    具体的な活用方法を提示する。
  depends_on: [p3]

  subtasks:
    - id: p4.1
      criterion: "/changelog コマンドが --suggest オプションをサポートしている"
      executor: claudecode
      test_command: "grep -q '\\-\\-suggest' /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh && echo PASS"

    - id: p4.2
      criterion: "/changelog --suggest が適用可能性分析を実行するロジックが定義されている"
      executor: claudecode
      test_command: "grep -q 'applicability\\|suggest' /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh && echo PASS"

    - id: p4.3
      criterion: "優先度（高・中・低）の分類ロジックが実装されている"
      executor: claudecode
      test_command: "grep -q 'high\\|medium\\|low' /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh && echo PASS"

    - id: p4.4
      criterion: "/changelog --suggest がヘルプ情報を表示できる"
      executor: claudecode
      test_command: "grep -q 'help\\|usage' /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh && echo PASS"

  status: pending
  depends_on: [p3]
  max_iterations: 5

---

### p5: 優先度付けと活用方法の提示

> サジェストメッセージに優先度と具体的な活用方法を含める

```yaml
- id: p5
  name: "優先度付けと活用方法の提示"
  goal: |
    各サジェストに優先度（高・中・低）と、
    このリポジトリにおける具体的な活用方法を提示する。
  depends_on: [p4]

  subtasks:
    - id: p5.1
      criterion: "関連機能にスコアが計算されている"
      executor: claudecode
      test_command: "grep -q 'score\\|weight' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p5.2
      criterion: "サジェストメッセージに優先度ラベルが含まれている形式が実装されている"
      executor: claudecode
      test_command: "grep -q '\\[HIGH\\]\\|\\[MEDIUM\\]\\|\\[LOW\\]' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

    - id: p5.3
      criterion: "各関連機能に活用方法のコメントが含まれている"
      executor: claudecode
      test_command: "grep -q 'how_to_use\\|application\\|usage' /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json && echo PASS"

    - id: p5.4
      criterion: "整形されたサジェストメッセージが出力される"
      executor: claudecode
      test_command: "grep -q 'format\\|output' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS"

  status: pending
  depends_on: [p4]
  max_iterations: 5

---

### p6: 統合テストと動作確認

> すべての機能が統合され、正常に動作することを確認

```yaml
- id: p6
  name: "統合テストと動作確認"
  goal: |
    新バージョン検出時のサジェスト機能と
    /changelog --suggest オプションが
    期待通りに動作することを確認する。
  depends_on: [p5]

  subtasks:
    - id: p6.1
      criterion: "repo-profile.json が有効な JSON として解析できる"
      executor: claudecode
      test_command: "jq empty /Users/amano/Desktop/thanks4claudecode/.claude/cache/repo-profile.json >/dev/null 2>&1 && echo PASS"

    - id: p6.2
      criterion: "changelog-checker.sh が正常に実行される"
      executor: claudecode
      test_command: "bash /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh >/dev/null 2>&1 && echo PASS"

    - id: p6.3
      criterion: "/changelog コマンドが正常に実行される"
      executor: claudecode
      test_command: "bash /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh >/dev/null 2>&1 && echo PASS"

    - id: p6.4
      criterion: "/changelog --suggest が適切な出力を返す"
      executor: claudecode
      test_command: "bash /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.sh --suggest 2>&1 | grep -q 'Suggested\\|suggest\\|priority' && echo PASS"

  status: pending
  depends_on: [p5]
  max_iterations: 5

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M021 playbook として 6 フェーズを定義。 |
