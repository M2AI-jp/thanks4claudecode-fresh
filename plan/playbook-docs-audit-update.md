# playbook-docs-audit-update.md

> **一次情報リソース（ARCHITECTURE.md, repository-map.yaml, Skill/SubAgent symlinks）の監査・改善**

---

## meta

```yaml
project: docs-audit-update
branch: feat/docs-audit-update
created: 2026-01-02
issue: null
reviewed: true
```

---

## goal

```yaml
summary: 一次情報リソースのメンテナンス状況を監査し、欠落・不整合を解消する
done_when:
  - ARCHITECTURE.md の全参照が有効である（存在しないファイルへの参照がない）
  - repository-map.yaml が現状と整合している
  - 不要ファイルが削除されている
```

---

## context

```yaml
5w1h:
  who: Claude Code（自律実行）、codex（監査・分析）、coderabbit（レビュー）
  what: 一次情報リソースの監査・改善
  when: 現在のセッション内
  where: docs/, .claude/, plan/ 配下
  why: 参照されているが存在しないファイル、記載漏れ、古い情報がドキュメントの信頼性を損なっている
  how: 不要ファイル監査 → 欠落ファイル対応 → ARCHITECTURE.md 修正 → repository-map 再生成 → 最終検証

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-02T19:00:00Z
  data:
    identified_issues:
      - "docs/current-definitions.md が ARCHITECTURE.md 1033行目で参照されているが存在しない"
      - "ARCHITECTURE.md の SessionStart Hook セクション（120-123行）が実態と異なる可能性"
      - "repository-map.yaml の整合性確認が必要"
    risks:
      scope:
        - risk: "参照修正時の連鎖影響"
          severity: medium
          mitigation: "grep で全参照箇所を事前確認"
      technical:
        - risk: "不要ファイル削除での影響"
          severity: medium
          mitigation: "削除前に依存関係を確認、git で復元可能"

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T19:30:00Z
  summary: |
    current-definitions.md の経緯調査を p1 スコープに含め、
    必要なら作成、不要なら参照削除という判断を Codex に委ねる。
    不要ファイルは監査だけでなく削除も実行する。
  approved_items:
    - question_id: q1
      question: "docs/current-definitions.md について"
      answer: "監査の一環として調査し、必要なら作成、不要なら参照削除"
    - question_id: q2
      question: "不要ファイルの扱い"
      answer: "削除も実行"
```

---

## phases

### p1: 不要ファイル監査・current-definitions.md 経緯調査

**goal**: 使用されていないファイル、古いファイル、current-definitions.md の経緯を調査し、削除/対応方針を決定する

#### subtasks

- [x] **p1.1**: 全ドキュメントの依存関係分析が完了している
  - executor: codex
  - validations:
    - technical: "PASS - grep/rg で docs/, .claude/, plan/ の相互参照を調査、依存グラフ出力完了"
    - consistency: "PASS - ARCHITECTURE.md, CLAUDE.md, RUNBOOK.md からの参照を確認"
    - completeness: "PASS - docs/ 6ファイル、plan/template/ 5ファイル、.claude/skills/ 16 Skills 全て確認"
  - validated: 2026-01-02T19:45:00Z

- [x] **p1.2**: current-definitions.md の経緯が調査され、対応方針が決定している
  - executor: codex
  - validations:
    - technical: "PASS - git log で確認: 2025-12-25 commit e0659107 で削除（孤立ドキュメント整理）"
    - consistency: "PASS - 用語定義は CLAUDE.md, ARCHITECTURE.md, term-translator Skill で代替済み"
    - completeness: "PASS - 決定: B（参照を削除）- ファイル再作成は不要"
  - validated: 2026-01-02T19:45:00Z

- [x] **p1.3**: 不要ファイルリストが作成されている
  - executor: codex
  - validations:
    - technical: "PASS - 依存分析から未参照ファイル抽出: .claude/context/claude-md-history.md"
    - consistency: "PASS - 削除候補は governance/PROMPT_CHANGELOG.md と重複確認済み"
    - completeness: "PASS - 削除対象3件: ファイル1件 + 参照削除2件（ARCHITECTURE.md:1033, RUNBOOK.md:166-167）"
  - validated: 2026-01-02T19:45:00Z

**status**: done
**max_iterations**: 5

---

### p2: 欠落ファイル対応

**goal**: p1 の調査結果に基づき、current-definitions.md への対応と不要ファイル削除を実行する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: current-definitions.md の対応が完了している（作成 or 参照削除）
  - executor: claudecode
  - validations:
    - technical: "PASS - ARCHITECTURE.md:1033 から current-definitions.md 参照行を削除"
    - consistency: "PASS - grep で確認: ARCHITECTURE.md 内に current-definitions.md 参照なし"
    - completeness: "PASS - 全参照箇所（1箇所）が対応済み"
  - validated: 2026-01-02T19:50:00Z

- [x] **p2.2**: p1.3 の不要ファイルリストに基づき削除が完了している
  - executor: claudecode
  - validations:
    - technical: "PASS - git rm .claude/context/claude-md-history.md 実行完了"
    - consistency: "PASS - RUNBOOK.md:166-167 の参照を ARCHITECTURE.md へ修正"
    - completeness: "PASS - ファイル1件削除、参照2件修正、計3件全て完了"
  - validated: 2026-01-02T19:50:00Z

**status**: done
**max_iterations**: 5

---

### p3: ARCHITECTURE.md SessionStart Hook セクション修正

**goal**: ARCHITECTURE.md の SessionStart Hook セクションを実態と整合させる

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: .claude/settings.json の SessionStart 設定が確認されている
  - executor: claudecode
  - validations:
    - technical: "PASS - settings.json 確認: SessionStart → .claude/hooks/session.sh"
    - consistency: "PASS - 旧記載: compact.sh（誤り）→ 新記載: session.sh（正しい）"
    - completeness: "PASS - 差分を特定し修正対象として記録"
  - validated: 2026-01-02T19:55:00Z

- [x] **p3.2**: ARCHITECTURE.md の SessionStart Hook セクションが正確である
  - executor: claudecode
  - validations:
    - technical: "PASS - Section 1 の Hook チェーンを session.sh に修正"
    - consistency: "PASS - settings.json と一致"
    - completeness: "PASS - 関連セクション（1箇所）が更新済み"
  - validated: 2026-01-02T19:55:00Z

**status**: done
**max_iterations**: 5

---

### p4: repository-map.yaml 再生成

**goal**: repository-map.yaml を現状のファイル構造で再生成する

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: generate-repository-map.sh が正常に実行される
  - executor: claudecode
  - validations:
    - technical: "PASS - bash .claude/hooks/generate-repository-map.sh が exit 0 で終了"
    - consistency: "PASS - スクリプト実行成功、ログ出力確認"
    - completeness: "PASS - docs/repository-map.yaml が更新済み"
  - validated: 2026-01-02T19:58:00Z

- [x] **p4.2**: repository-map.yaml が現状と整合している
  - executor: claudecode
  - validations:
    - technical: "PASS - Total files: 281, Hooks: 6, Agents: 10, Skills: 21"
    - consistency: "PASS - SubAgent symlinks 10件全て反映"
    - completeness: "PASS - docs/, .claude/, plan/ の全ファイルが含まれている"
  - validated: 2026-01-02T19:58:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: ARCHITECTURE.md の全参照が有効である
  - executor: claudecode
  - validations:
    - technical: "PASS - scripts/common.sh 削除、mcp.json → .mcp.json 修正、全参照存在確認"
    - consistency: "PASS - 参照パスとファイル構造が整合"
    - completeness: "PASS - 全参照が検証済み（critic PASS）"
  - validated: 2026-01-02T20:05:00Z

- [x] **p_final.2**: repository-map.yaml が現状と整合している
  - executor: claudecode
  - validations:
    - technical: "PASS - Total files: 281, Hooks: 6, Agents: 10, Skills: 21"
    - consistency: "PASS - 追加/削除されたファイルが反映されている"
    - completeness: "PASS - 全ファイルが含まれている（critic PASS）"
  - validated: 2026-01-02T20:05:00Z

- [x] **p_final.3**: 不要ファイルが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - .claude/context/claude-md-history.md が git rm で削除済み"
    - consistency: "PASS - git status で削除がステージング済み"
    - completeness: "PASS - 全削除対象が処理済み（critic PASS）"
  - validated: 2026-01-02T20:05:00Z

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
