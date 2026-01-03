# playbook-fix-backlog-batch-19.md

> **fix-backlog.md の未完了 19 件を一括で処理する長大な playbook**
>
> derives_from: fix-backlog.md (PB-02 ~ PB-06, PB-11 ~ PB-25)

---

## meta

```yaml
project: fix-backlog-batch-19
branch: fix/backlog-batch-19-pbs
created: 2026-01-04
issue: null
reviewed: true
derives_from: fix-backlog.md
roles:
  worker: claudecode  # ドキュメント修正中心のため claudecode を使用
```

---

## goal

```yaml
summary: fix-backlog.md の未完了 19 件（PB-02〜06, PB-11〜25）を修正し、全て FIXED または CLOSED にする
done_when:
  - fix-backlog.md の PB-02〜06, PB-11〜25 が全て FIXED または CLOSED ステータスである
  - 各修正に対して bash -n または grep による検証が PASS している
  - 関連ドキュメントの参照が実際に存在するファイルを指している
```

---

## context

```yaml
5w1h:
  who: "pm SubAgent（Claude Code）が実行"
  what: "未完了の19件のPB（PB-02〜06, PB-11〜25）を修正し fix-backlog.md を更新"
  when: "現在のセッションで実施"
  where: "各 PB で指定されたファイル"
  why: "playbook とレビューの仕組みが刷新されたため、統合 playbook として再作成"
  how: "fix-backlog.md の推奨実行順序に従い5つの Phase に分割して実行"

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-04T02:30:00Z
  data:
    risks:
      technical:
        - "19件の修正が互いに干渉する可能性（medium）"
      scope:
        - "19件は範囲が大きく、途中で中断する可能性（medium）"
      dependency:
        - "P0 修正が完了しないと P1/P2 に影響（high）"
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-04T02:30:00Z
  summary: "ユーザーが「まとめて1つの長大な playbook にしてOK」と明示的に承認"
```

---

## phases

### p1: P0 Guard Stability（PB-02〜05）

**goal**: パス計算・相対パス問題を修正し、Guard が安定動作するようにする

#### subtasks

- [ ] **p1.1**: PB-02 failure-logger.sh の参照が解消されている（削除または実装）
  - executor: claudecode
  - validations:
    - technical: "rg 'failure-logger' .claude で参照が存在しないか、存在するなら実体もある"
    - consistency: "playbook-guard.sh の動作に影響がないことを確認"
    - completeness: "参照と実体が一致している"

- [ ] **p1.2**: PB-03 bash-check.sh の REPO_ROOT が正しく 4 階層上を指している
  - executor: claudecode
  - validations:
    - technical: "grep 'REPO_ROOT.*/../../../..' bash-check.sh で確認"
    - consistency: "contract.sh が正しく source される"
    - completeness: "bash -n bash-check.sh が成功"

- [ ] **p1.3**: PB-04 protected-edit.sh の REPO_ROOT が正しく 4 階層上を指している
  - executor: claudecode
  - validations:
    - technical: "grep 'REPO_ROOT.*/../../../..' protected-edit.sh で確認"
    - consistency: "contract.sh が正しく source される"
    - completeness: "bash -n protected-edit.sh が成功"

- [ ] **p1.4**: PB-05 coherence.sh の state-schema.sh 参照が絶対パスである
  - executor: claudecode
  - validations:
    - technical: "grep 'REPO_ROOT.*state-schema.sh' coherence.sh で確認"
    - consistency: "任意ディレクトリからの実行でパスエラーなし"
    - completeness: "bash -n coherence.sh が成功"

**status**: pending
**max_iterations**: 5

---

### p2: P0 Hook Robustness（PB-06, PB-11）

**goal**: Fail-closed 化と Guard 強制を確実に動作させる
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: PB-06 pending-guard.sh が jq 不在時に exit 2 を返す
  - executor: claudecode
  - validations:
    - technical: "grep -A2 'command -v jq' pending-guard.sh で exit 2 を確認"
    - consistency: "他の guard と同じ Fail-closed パターン"
    - completeness: "エラーメッセージが stderr に出力される"

- [ ] **p2.2**: PB-11 critic-guard.sh が critic 未実行の done 変更を BLOCK する
  - executor: claudecode
  - validations:
    - technical: "bash -n critic-guard.sh が成功"
    - consistency: "self_complete: true がなければ BLOCK される"
    - completeness: "FAIL 情報が session-state に保存される"

**status**: pending
**max_iterations**: 5

---

### p3: P0/P1 Skill & Agent Integrity（PB-12〜15）

**goal**: SKILL.md と Agent ドキュメントの参照不整合を修正する
**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: PB-12 access-control/SKILL.md の lib/contract.sh 参照が修正されている
  - executor: claudecode
  - validations:
    - technical: "grep -v 'lib/contract.sh' access-control/SKILL.md で lib/ 参照がない"
    - consistency: "scripts/contract.sh への参照または外部依存セクションがある"
    - completeness: "ディレクトリ構造が実態と一致"

- [ ] **p3.2**: PB-13 playbook-gate/SKILL.md の archive.sh が archive-playbook.sh に修正されている
  - executor: claudecode
  - validations:
    - technical: "grep 'archive-playbook.sh' playbook-gate/SKILL.md で確認"
    - consistency: "実際のファイル名と一致"
    - completeness: "ディレクトリ構造が正確"

- [ ] **p3.3**: PB-14 golden-path/SKILL.md の 4qv-architecture.md 参照が ARCHITECTURE.md に修正されている
  - executor: claudecode
  - validations:
    - technical: "grep 'ARCHITECTURE.md' golden-path/SKILL.md で確認"
    - consistency: "参照先ファイルが存在する"
    - completeness: "全ての参照が有効なファイルを指す"

- [ ] **p3.4**: PB-15 codex-delegate.md に toolstack 定義参照が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'state.md|config.toolstack' codex-delegate.md で確認"
    - consistency: "toolstack A/B/C の説明と整合"
    - completeness: "定義元への参照が明確"

**status**: pending
**max_iterations**: 5

---

### p4: P1 Workflow Verification（PB-16〜21）

**goal**: ワークフローの冪等性・設計判断・テスト化を完了する
**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: PB-16 session-start.sh の state-schema.sh 参照が cwd 非依存である
  - executor: claudecode
  - validations:
    - technical: "参照パスを確認し、絶対パスまたは REPO_ROOT ベース"
    - consistency: "他のスクリプトと同じパターン"
    - completeness: "連続実行で重複が発生しない"

- [ ] **p4.2**: PB-17 repository-map.yaml と cleanup.sh のパス参照が正しい
  - executor: claudecode
  - validations:
    - technical: "cleanup.sh の MAP_SCRIPT が正しいパスを指す"
    - consistency: "repository-map.yaml の references が実在ファイルを指す"
    - completeness: "generate-repository-map.sh の実行がエラーなし"

- [ ] **p4.3**: PB-18 depends-check.sh の設計判断が文書化されている
  - executor: claudecode
  - validations:
    - technical: "コメントで設計意図が記載されている"
    - consistency: "BLOCK または WARN の選択が意図的"
    - completeness: "ドキュメントに反映されている"

- [ ] **p4.4**: PB-19 scope-guard.sh の STRICT_MODE 設計判断が文書化されている
  - executor: claudecode
  - validations:
    - technical: "コメントで設計意図が記載されている"
    - consistency: "デフォルト値の選択が意図的"
    - completeness: "ドキュメントに反映されている"

- [ ] **p4.5**: PB-20 subtask-guard.sh の動作がテストケースで検証されている
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトが存在する"
    - consistency: "validations 不足の [x] を BLOCK することを確認"
    - completeness: "回帰テストに組み込まれている"

- [ ] **p4.6**: PB-21 phase-status-guard.sh の動作がテストケースで検証されている
  - executor: claudecode
  - validations:
    - technical: "テストスクリプトが存在する"
    - consistency: "不正な status 変更を BLOCK することを確認"
    - completeness: "回帰テストに組み込まれている"

**status**: pending
**max_iterations**: 10

---

### p5: P1/P2 Documentation & Agent Hygiene（PB-22〜24）

**goal**: Agent ドキュメントの品質を向上させる
**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: PB-22 reviewer.md のプレースホルダが具体手順に置換されている
  - executor: claudecode
  - validations:
    - technical: "プレースホルダ（TODO, TBD, ...）がない"
    - consistency: "手順と判定基準が明文化されている"
    - completeness: "4QV+ フレームワークが完全に記載されている"

- [ ] **p5.2**: PB-23 critic.md の tools 権限と session-state 書き込み方法が明確である
  - executor: claudecode
  - validations:
    - technical: "tools の説明コメントがある"
    - consistency: "Write/Edit 禁止の理由が明記"
    - completeness: "Bash 経由の書き込み方法が文書化"

- [ ] **p5.3**: PB-24 pm.md の DEPRECATED セクションが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -c DEPRECATED pm.md が 0 または最小限"
    - consistency: "executor-resolver への参照が維持"
    - completeness: "ファイル行数が 850 行以下"

**status**: pending
**max_iterations**: 5

---

### p6: fix-backlog.md 更新

**goal**: 全ての修正を fix-backlog.md に反映する
**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: PB-02〜06 のステータスが FIXED または CLOSED に更新されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'PB-0[2-6].*FIXED|CLOSED' fix-backlog.md で 5 件確認"
    - consistency: "修正内容と Status が整合"
    - completeness: "修正日と PR 情報が記載"

- [ ] **p6.2**: PB-11〜25 のステータスが FIXED または CLOSED に更新されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'PB-(1[1-9]|2[0-5]).*FIXED|CLOSED' fix-backlog.md で 15 件確認"
    - consistency: "修正内容と Status が整合"
    - completeness: "修正日と PR 情報が記載"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 全ての done_when が満たされていることを最終確認する
**depends_on**: [p6]

#### subtasks

- [ ] **p_final.1**: fix-backlog.md の PB-02〜06, PB-11〜25 が全て FIXED または CLOSED である
  - executor: claudecode
  - validations:
    - technical: "grep -E '(PB-0[2-6]|PB-1[1-9]|PB-2[0-5]).*FIXED|CLOSED' fix-backlog.md | wc -l が 19 以上"
    - consistency: "各 PB のステータスが実際の修正状況と一致"
    - completeness: "全 19 件が処理済み"

- [ ] **p_final.2**: 各修正に対して bash -n または grep による検証が PASS している
  - executor: claudecode
  - validations:
    - technical: "bash -n で全修正スクリプトの構文チェック PASS"
    - consistency: "検証コマンドの結果が期待値と一致"
    - completeness: "全ファイルが検証済み"

- [ ] **p_final.3**: 関連ドキュメントの参照が実際に存在するファイルを指している
  - executor: claudecode
  - validations:
    - technical: "SKILL.md 内の全参照パスが test -f で PASS"
    - consistency: "参照先ファイルの内容が期待通り"
    - completeness: "全ドキュメントの参照が有効"

**status**: pending
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
| 2026-01-04 | 初版作成。fix-backlog.md の未完了 19 件を統合 playbook として作成。 |
