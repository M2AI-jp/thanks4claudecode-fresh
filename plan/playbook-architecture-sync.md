# playbook-architecture-sync.md

> **ARCHITECTURE.md と repository-map.yaml の実装との整合性を回復する**

---

## meta

```yaml
project: architecture-sync
branch: docs/architecture-sync
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: claudecode  # ドキュメント更新のため claudecode で十分
```

---

## context

```yaml
5w1h:
  what: ARCHITECTURE.md と repository-map.yaml を実装と整合させる
  why: M086 Orchestrator 設計が文書に反映されておらず、ユーザーフロー図が古い
  who: 開発者（ドキュメント参照者）
  when: 今回のセッション
  where: docs/ARCHITECTURE.md, docs/repository-map.yaml, .claude/hooks/generate-repository-map.sh
  how: 差分調査結果に基づき、セクション7・8・10を更新、日本語 truncation を修正

analysis_summary: |
  1. セクション7: prompt-analyzer, term-translator, executor-resolver の3 SubAgent が不足
  2. セクション8: 8件→21件に拡充が必要
  3. セクション10: pm の Orchestrator 設計（M086）が未反映
  4. repository-map.yaml: LC_ALL=C による日本語 truncation 問題

user_approval: ユーザーが「はい、進めて ultrathink」で承認済み
```

---

## goal

```yaml
summary: ARCHITECTURE.md と repository-map.yaml を実装と整合させる
done_when:
  - ARCHITECTURE.md セクション7 に prompt-analyzer, term-translator, executor-resolver SubAgent が追加されている
  - ARCHITECTURE.md セクション8 に全21件の Skills が記載されている
  - ARCHITECTURE.md セクション10 が M086 Orchestrator 設計（pm → prompt-analyzer → term-translator → executor-resolver → reviewer の委譲チェーン）を反映している
  - repository-map.yaml の description が truncation されずに生成される（日本語対応修正済み）
```

---

## phases

### p1: generate-repository-map.sh の日本語対応修正

**goal**: description の truncation 問題を修正する

#### subtasks

- [x] **p1.1**: generate-repository-map.sh の extract_description 関数が日本語を正しく処理する
  - executor: claudecode
  - validations:
    - technical: "bash -n でシンタックスエラーがない"
    - consistency: "他の関数と処理方式が整合している"
    - completeness: "LC_ALL 設定と awk の文字数制限が修正されている"

- [x] **p1.2**: generate-repository-map.sh を実行し、repository-map.yaml が正しく生成される
  - executor: claudecode
  - validations:
    - technical: "bash .claude/hooks/generate-repository-map.sh が exit 0 で終了する"
    - consistency: "出力ファイルが docs/repository-map.yaml に存在する"
    - completeness: "日本語の description が truncated されていない（例: health-checker の description が完全）"

**status**: done
**max_iterations**: 5

---

### p2: ARCHITECTURE.md セクション7 更新（SubAgent 追加）

**goal**: 不足している3つの SubAgent を追加する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: ARCHITECTURE.md セクション7 に prompt-analyzer SubAgent の呼び出し構造が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep 'prompt-analyzer' docs/ARCHITECTURE.md で存在確認"
    - consistency: "他の SubAgent（pm, critic 等）と同じフォーマットで記載"
    - completeness: "参照ファイル、入出力が記載されている"

- [x] **p2.2**: ARCHITECTURE.md セクション7 に term-translator SubAgent の呼び出し構造が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep 'term-translator' docs/ARCHITECTURE.md で存在確認"
    - consistency: "他の SubAgent と同じフォーマットで記載"
    - completeness: "参照ファイル、入出力が記載されている"

- [x] **p2.3**: ARCHITECTURE.md セクション7 に executor-resolver SubAgent の呼び出し構造が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep 'executor-resolver' docs/ARCHITECTURE.md で存在確認"
    - consistency: "他の SubAgent と同じフォーマットで記載"
    - completeness: "参照ファイル、入出力が記載されている"

**status**: done
**max_iterations**: 5

---

### p3: ARCHITECTURE.md セクション8 更新（Skills 全件記載）

**goal**: 全21件の Skills を記載する

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: ARCHITECTURE.md セクション8 に全21件の Skills が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -c '###.*/' docs/ARCHITECTURE.md で 21 以上を確認（各 Skill のサブセクション）"
    - consistency: "既存 8 件と同じフォーマットで新規 13 件が追加されている"
    - completeness: "以下の不足 Skills が全て記載: abort-playbook, context-management, deploy-checker, executor-resolver, frontend-design, lint-checker, plan-management, playbook-init, prompt-analyzer, state, term-translator, test-runner, understanding-check"

**status**: done
**max_iterations**: 5

---

### p4: ARCHITECTURE.md セクション10 更新（M086 Orchestrator 設計）

**goal**: pm の委譲チェーンを反映した情報フロー図に更新する

**depends_on**: [p2]

#### subtasks

- [x] **p4.1**: ARCHITECTURE.md セクション10 の「タスク開始から完了まで」図が M086 Orchestrator 設計を反映している
  - executor: claudecode
  - validations:
    - technical: "grep -A30 'pm SubAgent' docs/ARCHITECTURE.md で委譲チェーンが確認できる"
    - consistency: "prompt-analyzer → term-translator → executor-resolver の順序が正しい"
    - completeness: "pm が orchestrator として各 SubAgent を呼び出す構造が明示されている"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3, p4]

#### subtasks

- [x] **p_final.1**: ARCHITECTURE.md セクション7 に prompt-analyzer, term-translator, executor-resolver が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -E 'prompt-analyzer|term-translator|executor-resolver' docs/ARCHITECTURE.md | wc -l で 3 以上"
    - consistency: "各 SubAgent が正しいセクション（7）に配置されている"
    - completeness: "3つ全ての SubAgent が記載されている"

- [x] **p_final.2**: ARCHITECTURE.md セクション8 に全21件の Skills が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'SKILL.md' docs/ARCHITECTURE.md で Skills 記載数を確認"
    - consistency: "Skills の記載フォーマットが統一されている"
    - completeness: ".claude/skills/*/SKILL.md の件数（21）と一致"

- [x] **p_final.3**: ARCHITECTURE.md セクション10 が M086 Orchestrator 設計を反映している
  - executor: claudecode
  - validations:
    - technical: "grep 'orchestrator' docs/ARCHITECTURE.md で存在確認"
    - consistency: "委譲チェーン図が正しい順序を示している"
    - completeness: "pm → prompt-analyzer → term-translator → executor-resolver → reviewer の流れが明示"

- [x] **p_final.4**: repository-map.yaml の description が truncation されていない
  - executor: claudecode
  - validations:
    - technical: "bash .claude/hooks/generate-repository-map.sh を実行"
    - consistency: "日本語 description が途中で切れていない"
    - completeness: "全ての日本語 description が完全に出力されている"

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
