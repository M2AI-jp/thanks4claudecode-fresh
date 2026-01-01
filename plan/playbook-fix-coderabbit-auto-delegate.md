# playbook-fix-coderabbit-auto-delegate.md

## meta

```yaml
project: fix-coderabbit-auto-delegate
branch: fix/coderabbit-auto-delegate
created: 2026-01-01
issue: null
reviewed: true
```

---

## context

```yaml
5w1h:
  who: Claude Code ユーザー（toolstack C で coderabbit executor を使用）
  what: coderabbit 自動委譲機能を codex と同様に hookSpecificOutput JSON 形式に修正
  when: 今回のセッションで完了
  where: executor-guard.sh、quality-assurance SKILL.md、state.md
  why: codex と同様に coderabbit でも自動委譲が機能するようにするため。現在は stderr にテキスト出力しており、Claude が JSON 形式の委譲指示を受け取れない
  how: executor-guard.sh の coderabbit case を codex と同じ JSON 形式に修正、SKILL.md に coderabbit-delegate を追加、state.md の note を更新

analysis_result:
  source: user-provided
  timestamp: 2026-01-01T21:30:00Z
  data:
    risks:
      technical:
        - risk: hookSpecificOutput 形式の誤り
          severity: low
          mitigation: codex の実装を参考に同一形式で実装
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-01T21:30:00Z
  summary: ユーザーが「その理解で正しいです」と承認
  approved_items:
    - question_id: confirmation
      question: この理解で playbook を作成してよいですか？
      answer: はい
```

---

## goal

```yaml
summary: coderabbit 自動委譲を codex と同様に hookSpecificOutput JSON 形式に修正する
done_when:
  - executor-guard.sh の coderabbit case が hookSpecificOutput JSON 形式で出力する
  - quality-assurance SKILL.md に coderabbit-delegate SubAgent が記載されている
  - state.md の note が最新情報に更新されている
```

---

## phases

### p1: executor-guard.sh の修正

**goal**: coderabbit case を codex と同様の hookSpecificOutput JSON 形式に修正する

#### subtasks

- [x] **p1.1**: executor-guard.sh の coderabbit case が hookSpecificOutput JSON を出力する
  - executor: claudecode
  - validations:
    - technical: "bash -n で構文エラーがないことを確認" ✅
    - consistency: "codex case と同じ JSON 構造であることを確認" ✅
    - completeness: "必要なフィールド（action, target_subagent, executor, file_path）が全て含まれていることを確認" ✅

**status**: done
**max_iterations**: 5

---

### p2: SKILL.md の更新

**goal**: quality-assurance SKILL.md に coderabbit-delegate SubAgent を記載する

**depends_on**: []

#### subtasks

- [x] **p2.1**: quality-assurance SKILL.md の SubAgent 一覧に coderabbit-delegate が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep で coderabbit-delegate の記載を確認" ✅
    - consistency: "他の SubAgent（reviewer, health-checker）と同じ形式であることを確認" ✅
    - completeness: "role, location, invocation, output の全フィールドが含まれていることを確認" ✅

**status**: done
**max_iterations**: 5

---

### p3: state.md の更新

**goal**: state.md の note を最新情報に更新する

**depends_on**: [p1, p2]

#### subtasks

- [x] **p3.1**: state.md の note が coderabbit 自動委譲の修正完了を反映している
  - executor: claudecode
  - validations:
    - technical: "grep で note セクションの更新を確認" ✅
    - consistency: "playbook 完了と矛盾しない内容であることを確認" ✅
    - completeness: "修正内容の要約が含まれていることを確認" ✅

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: executor-guard.sh の coderabbit case が hookSpecificOutput JSON 形式で出力する
  - executor: claudecode
  - validations:
    - technical: "grep で 'hookSpecificOutput' と 'coderabbit-delegate' の存在を確認" ✅
    - consistency: "codex case と同じ構造であることを目視確認" ✅
    - completeness: "action, target_subagent, executor, file_path フィールドが全て存在" ✅

- [x] **p_final.2**: quality-assurance SKILL.md に coderabbit-delegate SubAgent が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep で 'coderabbit-delegate' の記載を確認" ✅
    - consistency: "SubAgent 一覧セクションに正しく配置されている" ✅
    - completeness: "role, location, invocation, output が全て記載されている" ✅

- [x] **p_final.3**: state.md の note が最新情報に更新されている
  - executor: claudecode
  - validations:
    - technical: "grep で note の内容を確認" ✅
    - consistency: "タスク完了と整合する内容である" ✅
    - completeness: "修正完了の旨が記載されている" ✅

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
