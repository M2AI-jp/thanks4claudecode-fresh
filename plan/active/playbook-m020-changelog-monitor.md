# playbook-m020-changelog-monitor.md

> **Claude Code CHANGELOG モニタリングシステムの構築**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m020-changelog-monitor
created: 2025-12-13
issue: null
derives_from: M020
reviewed: false
```

---

## goal

```yaml
summary: Claude Code の CHANGELOG を定期的にチェックし、新機能を検出・キャッシュ・通知するシステムを構築する

done_when:
  - .claude/cache/ ディレクトリが作成され、キャッシュメカニズムが機能している
  - changelog-checker.sh が SessionStart で発火し、24時間キャッシュを検証している
  - /changelog コマンドで最新情報を表示でき、強制更新オプションが動作している
  - 新バージョン検出時に通知が表示される
```

---

## phases

### p0: キャッシュディレクトリ & メタデータ構造設計

フェーズの目標: CHANGELOG キャッシュの物理的・論理的構造を設計・実装。

```yaml
subtasks:
  - id: p0.1
    criterion: ".claude/cache/ ディレクトリが作成されている"
    executor: claudecode
    test_command: "test -d /Users/amano/Desktop/thanks4claudecode/.claude/cache && echo PASS || echo FAIL"

  - id: p0.2
    criterion: "changelog-meta.json の初期スキーマが定義されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-meta.json && grep -q '\"cached_at\"' /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-meta.json && echo PASS || echo FAIL"

  - id: p0.3
    criterion: "changelog-latest.md がダウンロードされ保存されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-latest.md && wc -l /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-latest.md | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p0.4
    criterion: ".claude/cache/ が .gitignore に登録されている"
    executor: claudecode
    test_command: "grep -q '^\\.claude/cache/' /Users/amano/Desktop/thanks4claudecode/.gitignore && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

### p1: changelog-checker.sh実装

フェーズの目標: SessionStart Hook で自動発火し、24時間キャッシュロジックを検証。

```yaml
subtasks:
  - id: p1.1
    criterion: "changelog-checker.sh ファイルが存在する"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS || echo FAIL"

  - id: p1.2
    criterion: "changelog-checker.sh に実行権限がある"
    executor: claudecode
    test_command: "test -x /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS || echo FAIL"

  - id: p1.3
    criterion: "SessionStart Hook に changelog-checker.sh が登録されている"
    executor: claudecode
    test_command: "grep -q 'changelog-checker.sh' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && echo PASS || echo FAIL"

  - id: p1.4
    criterion: "24時間キャッシュ判定ロジックが実装されている"
    executor: claudecode
    test_command: "grep -q 'cache_age' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && grep -q '86400' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS || echo FAIL"

  - id: p1.5
    criterion: "24時間以内の再実行でキャッシュが返される"
    executor: user
    test_command: "手動確認: SessionStart 直後に再度 /changelog コマンドを実行し、同じ内容が表示されることを確認"

status: pending
max_iterations: 5
depends_on: [p0]
```

### p2: /changelog コマンド実装

フェーズの目標: ユーザーが手動でキャッシュを更新できるコマンドを実装。

```yaml
subtasks:
  - id: p2.1
    criterion: "/changelog コマンドファイルが .claude/commands/ に作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.md && echo PASS || echo FAIL"

  - id: p2.2
    criterion: "/changelog コマンドが最新の CHANGELOG を表示する"
    executor: user
    test_command: "手動確認: /changelog コマンド実行後、Claude Code の最新バージョン情報が表示されることを確認"

  - id: p2.3
    criterion: "/changelog --force オプションでキャッシュを強制更新できる"
    executor: user
    test_command: "手動確認: /changelog --force 実行後、CHANGELOG が再ダウンロードされることを確認"

  - id: p2.4
    criterion: "/changelog コマンドの説明が .claude/commands/changelog.md に含まれている"
    executor: claudecode
    test_command: "grep -q '強制更新' /Users/amano/Desktop/thanks4claudecode/.claude/commands/changelog.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
depends_on: [p1]
```

### p3: 新バージョン検出 & 通知機構

フェーズの目標: バージョン差分を検出し、通知を実装。

```yaml
subtasks:
  - id: p3.1
    criterion: "current_version と latest_version が changelog-meta.json に記録されている"
    executor: claudecode
    test_command: "grep -q 'current_version' /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-meta.json && grep -q 'latest_version' /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-meta.json && echo PASS || echo FAIL"

  - id: p3.2
    criterion: "バージョン比較ロジックが changelog-checker.sh に実装されている"
    executor: claudecode
    test_command: "grep -q 'version.*comparison\\|compare.*version' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS || echo FAIL"

  - id: p3.3
    criterion: "新バージョン検出時に system_message に通知が追加される"
    executor: user
    test_command: "手動確認: 新バージョン検出時（changelog-meta.json が更新されるよう強制した場合など）に通知が表示されることを確認"

  - id: p3.4
    criterion: "通知メッセージにバージョン情報と新機能概要が含まれている"
    executor: claudecode
    test_command: "grep -q 'version\\|新機能' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/changelog-checker.sh && echo PASS || echo FAIL"

status: pending
max_iterations: 5
depends_on: [p2]
```

### p4: テスト & クリーンアップ

フェーズの目標: システム全体の動作検証とドキュメント整備。

```yaml
subtasks:
  - id: p4.1
    criterion: "SessionStart 発火時に changelog-checker.sh が正常に実行される"
    executor: user
    test_command: "手動確認: セッション開始後、キャッシュが自動チェックされることを確認（ログ確認など）"

  - id: p4.2
    criterion: "キャッシュ及びメタデータファイルが正常に保存されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-latest.md && test -f /Users/amano/Desktop/thanks4claudecode/.claude/cache/changelog-meta.json && echo PASS || echo FAIL"

  - id: p4.3
    criterion: "docs/repository-map.yaml に changelog-checker.sh が登録されている"
    executor: claudecode
    test_command: "grep -q 'changelog-checker' /Users/amano/Desktop/thanks4claudecode/docs/repository-map.yaml && echo PASS || echo FAIL"

  - id: p4.4
    criterion: "CHANGELOG システムの説明が state.md または README に追加されている"
    executor: claudecode
    test_command: "grep -q 'CHANGELOG\\|changelog' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
depends_on: [p3]
```

---

## 参照

- plan/project.md: M020 の定義
- plan/template/playbook-format.md: playbook フォーマット
- docs/criterion-validation-rules.md: done_criteria 検証ルール
- docs/folder-management.md: フォルダ管理ルール
- .claude/hooks/session-start.sh: Hook の発火仕様

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M020 milestone から自動導出。 |
