# playbook-verify-subagent-data-flow.md

> **ARCHITECTURE.md 最新化 + coderabbit 統合テスト**

---

## meta

```yaml
project: verify-subagent-data-flow
branch: feat/update-architecture-and-e2e-test
created: 2026-01-01
issue: null
reviewed: true
```

---

## goal

```yaml
summary: ARCHITECTURE.md に coderabbit-delegate を追加し、複合 E2E テスト（A/B/C/D）で動作を検証する
done_when:
  - ARCHITECTURE.md に coderabbit-delegate SubAgent が記載されている
  - E2E テスト A（coderabbit 単体）が成功する
  - E2E テスト B（codex->coderabbit 連携）が成功する
  - E2E テスト C（toolstack 切替）が成功する
  - E2E テスト D（エラーケース）が成功する
```

---

## context

```yaml
5w1h:
  who: "開発者"
  what: "ARCHITECTURE.md 最新化 + coderabbit 統合テスト"
  when: "今回のセッション"
  where: "docs/ARCHITECTURE.md, tmp/"
  why: "coderabbit-delegate SubAgent を追加済みだが、ARCHITECTURE.md に未記載。統合テストで動作確認が必要"
  how: "ARCHITECTURE.md を編集、E2E テストスクリプト作成・実行"

analysis_result:
  source: prompt-analyzer
  timestamp: "2026-01-01T23:00:00Z"
  data:
    5w1h:
      what: "ARCHITECTURE.md と repository-map.yaml を最新化 + 複合 E2E テスト"
      why: "coderabbit-delegate SubAgent が ARCHITECTURE.md に未記載"
      who: "開発者"
      when: "今回のセッション"
      where: "docs/ARCHITECTURE.md, tmp/"
      how: "ドキュメント編集 + テストスクリプト作成・実行"
    risks:
      technical:
        - risk: "CodeRabbit CLI が未インストールの場合のテスト失敗"
          severity: medium
          mitigation: "テスト D でエラーケースを検証"
      scope: []
      dependency:
        - risk: "executor-guard.sh が正しく hookSpecificOutput を出力しない可能性"
          severity: low
          mitigation: "既に実装済みのため低リスク"
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: "2026-01-01T23:00:00Z"
  data:
    original_terms: []
    technical_requirements: []
    codebase_context:
      relevant_files:
        - "docs/ARCHITECTURE.md"
        - ".claude/skills/quality-assurance/agents/coderabbit-delegate.md"
        - ".claude/skills/playbook-gate/guards/executor-guard.sh"
      existing_patterns:
        - "codex-delegate と同等の hookSpecificOutput JSON 形式"
      conventions: []

user_approved_understanding:
  source: understanding-check
  approved_at: "2026-01-01T23:00:00Z"
  summary: "ユーザーが ultrathink を指定し、承認済みとして進行を許可"
  approved_items:
    - question_id: "approval"
      question: "この理解で進めてよいですか？"
      answer: "ultrathink を指定しているので承認済みとして進めてOK"
  technical_requirements_confirmed: []
```

---

## phases

### p1: ARCHITECTURE.md 最新化

**goal**: ARCHITECTURE.md に coderabbit-delegate SubAgent を追加

#### subtasks

- [x] **p1.1**: ARCHITECTURE.md の SubAgent 一覧に coderabbit-delegate が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'coderabbit-delegate' docs/ARCHITECTURE.md で 1 以上を確認" ✅
    - consistency: "他の SubAgent（codex-delegate, reviewer）と同等の記述形式" ✅
    - completeness: "役割、参照ファイル、呼び出し方法が記載されている" ✅

- [x] **p1.2**: repository-map.yaml が最新の状態である（確認のみ）
  - executor: claudecode
  - validations:
    - technical: "grep 'coderabbit-delegate' docs/repository-map.yaml で存在確認" ✅
    - consistency: "他の SubAgent と同等の記述形式" ✅
    - completeness: "skill と description が記載されている" ✅

**status**: done
**max_iterations**: 3

---

### p2: E2E テスト作成・実行

**goal**: tmp/ に E2E テストスクリプトを作成し、A/B/C/D の全テストを実行

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: tmp/e2e-subagent-test.sh が存在し、テスト A/B/C/D を含む
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/e2e-subagent-test.sh でファイル存在確認" ✅
    - consistency: "scripts/ 配下の既存テストスクリプトと同等の形式" ✅
    - completeness: "テスト A/B/C/D の全ケースが含まれている" ✅

- [x] **p2.2**: テスト A（coderabbit 単体）が成功する
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトの A セクションが PASS を返す" ✅ (4 PASS)
    - consistency: "executor-guard.sh の hookSpecificOutput が正しく出力される" ✅
    - completeness: "coderabbit-delegate への自動委譲が確認できる" ✅

- [x] **p2.3**: テスト B（codex->coderabbit 連携）が成功する
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトの B セクションが PASS を返す" ✅ (3 PASS)
    - consistency: "codex 実装後に coderabbit レビューの流れが確認できる" ✅
    - completeness: "全フローが正常に動作する" ✅

- [x] **p2.4**: テスト C（toolstack 切替）が成功する
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトの C セクションが PASS を返す" ✅ (3 PASS)
    - consistency: "toolstack A/B/C で executor 解決が正しく動作する" ✅
    - completeness: "全 toolstack パターンがテストされている" ✅

- [x] **p2.5**: テスト D（エラーケース）が成功する
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトの D セクションが PASS を返す" ✅ (3 PASS)
    - consistency: "coderabbit CLI インストール確認、jq 確認、構文チェック" ✅
    - completeness: "エラーケースが適切に処理される" ✅

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを検証

**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: ARCHITECTURE.md に coderabbit-delegate SubAgent が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'coderabbit-delegate SubAgent' docs/ARCHITECTURE.md で 2 件確認" ✅
    - consistency: "codex-delegate と同等の記述形式" ✅
    - completeness: "役割、参照ファイル、呼び出し例が含まれている" ✅

- [x] **p_final.2**: E2E テスト A/B/C/D が全て成功している
  - executor: claudecode
  - validations:
    - technical: "bash tmp/e2e-subagent-test.sh が 13 PASS / 0 FAIL" ✅
    - consistency: "各テストの出力が期待通り" ✅
    - completeness: "4 つのテストケース全てが実行されている" ✅

- [x] **p_final.3**: tmp/ 内のテストファイルが後工程に影響しないことを確認
  - executor: claudecode
  - validations:
    - technical: "テストファイルが tmp/ 内に閉じている" ✅
    - consistency: "playbook 完了時に tmp/ は自動クリーンアップされる" ✅
    - completeness: "他ディレクトリに影響がない" ✅

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-01 | 初版作成 |
