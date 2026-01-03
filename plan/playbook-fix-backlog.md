# playbook-fix-backlog.md

> **調査結果を永続的なバックログドキュメントとして保存する**

---

## meta

```yaml
project: fix-backlog
branch: docs/fix-backlog
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: 2つの調査結果（詳細分析22件 + Codex版25件）を docs/fix-backlog.md に永続化する
done_when:
  - docs/fix-backlog.md が存在する
  - Section 1-5（実行可能バックログ、詳細分析、マッピングテーブル、推奨実行順序、サマリー）が全て含まれている
  - PB-01〜PB-25（25件）が含まれている
  - P0-01〜P0-10、P1-01〜P1-10、P2-01〜P2-02（22件）が含まれている
```

---

## context

```yaml
5w1h:
  who: Claude（claudecode）が作成、開発チームが参照
  what: docs/fix-backlog.md を作成する
  when: このセッションで完了
  where: docs/fix-backlog.md（常に参照される位置）
  why: 2つの調査結果を永続的に参照可能な場所に保存する
  how: ユーザー提供のコンテンツをそのまま使用してファイル作成

analysis_result:
  source: user-provided
  timestamp: 2026-01-03
  data:
    task_type: single_file_creation
    content_status: provided_by_user
    risk_level: low

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03
  summary: ユーザーが done_criteria を明示的に承認済み
```

---

## phases

### p1: ドキュメント作成

**goal**: docs/fix-backlog.md を作成し、5つのセクションと全バックログ項目を含める

#### subtasks

- [x] **p1.1**: docs/fix-backlog.md が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f docs/fix-backlog.md で存在確認済み（875行）"
    - consistency: "PASS - docs/ フォルダ内に他ドキュメントと同様に配置"
    - completeness: "PASS - ファイルが作成されている"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p1.2**: Section 1-5 が全て含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 5 セクション全て検出"
    - consistency: "PASS - ユーザー指定のセクション構成と一致"
    - completeness: "PASS - 5 セクション全て含まれている"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p1.3**: PB-01〜PB-25（25件）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -o 'PB-[0-9]+' | sort -u | wc -l で 25 件検出"
    - consistency: "PASS - Codex版バックログの全項目が含まれている"
    - completeness: "PASS - 25 件全て含まれている"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p1.4**: P0-01〜P0-10、P1-01〜P1-10、P2-01〜P2-02（22件）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -oE 'P[0-2]-[0-9]+' | sort -u | wc -l で 22 件検出"
    - consistency: "PASS - 詳細分析の全項目が含まれている"
    - completeness: "PASS - 22 件全て含まれている"
  - validated: 2026-01-03T13:30:00+09:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: docs/fix-backlog.md が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f docs/fix-backlog.md 確認済み"
    - consistency: "PASS - ファイルパスが正しい"
    - completeness: "PASS - ファイルが存在する（875行）"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p_final.2**: Section 1-5 が全て含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 5 セクション全て検出"
    - consistency: "PASS - セクション順序が正しい"
    - completeness: "PASS - 全セクションが含まれている"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p_final.3**: PB-01〜PB-25（25件）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - 25 件検出（codex 独立検証済み）"
    - consistency: "PASS - ID 形式が統一されている"
    - completeness: "PASS - 25 件全て含まれている"
  - validated: 2026-01-03T13:30:00+09:00

- [x] **p_final.4**: P0-01〜P0-10、P1-01〜P1-10、P2-01〜P2-02（22件）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - 22 件検出（codex 独立検証済み）"
    - consistency: "PASS - ID 形式が統一されている"
    - completeness: "PASS - 22 件全て含まれている"
  - validated: 2026-01-03T13:30:00+09:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
