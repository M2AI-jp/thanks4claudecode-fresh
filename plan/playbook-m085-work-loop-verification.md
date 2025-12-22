# playbook-m085-work-loop-verification.md

> **work_loop workflow の E2E 検証・修正**
>
> M083 検証結果: work_loop は部分対応（乖離の深刻度: 中）
> PreToolUse:Edit で Guard チェーンは動作するが、「phase 完了」検知は公式 Hook では不可
> Guard 連鎖: playbook-guard -> scope-guard -> executor-guard -> critic-guard

---

## meta

```yaml
project: m085-work-loop-verification
branch: feat/m085-work-loop-verification
created: 2025-12-22
issue: null
derives_from: M083  # Workflow 動作検証の続き（work_loop 特化）
reviewed: true  # pm セルフレビュー完了（2025-12-22）
roles:
  orchestrator: claudecode
  worker: claudecode
  reviewer: claudecode
  human: user
```

---

## goal

```yaml
summary: work_loop workflow が E2E で動作することを検証し、問題があれば修正する
done_when:
  - PreToolUse:Edit が playbook-guard, scope-guard, executor-guard, critic-guard を順次呼び出す
  - 各 Guard が期待通りにブロック/許可する（playbook=null でブロック、playbook 存在で許可）
  - critic SubAgent との連携が動作する（critic-guard が state: done 変更をブロック）
  - 「phase 完了」の代替検知方法が明確になっている（公式 Hook では不可のため）
```

---

## 検証対象（repository-map.yaml より抽出）

```yaml
workflow:
  id: work_loop
  name: "LOOP"
  when: "INIT 完了後、playbook が存在する場合"
  process:
    hooks:
      - "playbook-guard.sh: playbook 存在確認"
      - "scope-guard.sh: スコープ制限"
      - "executor-guard.sh: executor 整合性"
      - "critic-guard.sh: critic 未実行チェック"
    subagents:
      - "critic: PASS/FAIL 判定"
  output:
    - "ファイル変更（Edit/Write）"
    - "validations 結果（3点検証）"
    - "critic 判定（PASS/FAIL）"
    - "phase.status = done（PASS の場合）"
```

---

## phases

### p1: Guard 登録・構文検証

**goal**: 全 Guard が settings.json に正しく登録され、構文エラーがないことを確認

#### subtasks

- [ ] **p1.1**: settings.json の PreToolUse:Edit セクションに全 Guard が登録されている
  - executor: claudecode
  - validations:
    - technical: "grep で playbook-guard, scope-guard, executor-guard, critic-guard の登録を確認"
    - consistency: "登録順序が playbook-guard -> scope-guard -> executor-guard -> critic-guard"
    - completeness: "各 Guard に timeout 設定（3000ms）が存在"

- [ ] **p1.2**: playbook-guard.sh が bash -n で構文エラーなく通過する
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/playbook-guard.sh が exit 0"
    - consistency: "set -euo pipefail が設定されている"
    - completeness: "jq 依存部分にフォールバック（jq がない場合スキップ）"

- [ ] **p1.3**: scope-guard.sh が bash -n で構文エラーなく通過する
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/scope-guard.sh が exit 0"
    - consistency: "set -euo pipefail が設定されている"
    - completeness: "STRICT_MODE 環境変数の説明がコメントにある"

- [ ] **p1.4**: executor-guard.sh が bash -n で構文エラーなく通過する
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/executor-guard.sh が exit 0"
    - consistency: "set -euo pipefail が設定されている"
    - completeness: "role-resolver.sh 連携コードが存在する"

- [ ] **p1.5**: critic-guard.sh が bash -n で構文エラーなく通過する
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/critic-guard.sh が exit 0"
    - consistency: "state: done 検出ロジックが存在"
    - completeness: "self_complete: true チェックが存在"

**status**: pending
**max_iterations**: 3

---

### p2: playbook-guard.sh の動作検証

**goal**: playbook=null で Edit/Write がブロックされ、playbook 存在時は許可されることを確認

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: playbook=null 時に Edit がブロックされる
  - executor: claudecode
  - validations:
    - technical: "playbook: null 状態で echo '{\"tool_input\":{\"file_path\":\"test.ts\"}}' | bash playbook-guard.sh が exit 2"
    - consistency: "エラーメッセージに「playbook 必須」が含まれる"
    - completeness: "pm エージェント呼び出しの案内がある"

- [ ] **p2.2**: playbook 存在時に Edit が許可される
  - executor: claudecode
  - validations:
    - technical: "playbook: {path} 状態で echo '{\"tool_input\":{\"file_path\":\"test.ts\"}}' | bash playbook-guard.sh が exit 0"
    - consistency: "ブロックメッセージが出力されない"
    - completeness: "reviewed: false の場合は警告のみ（ブロックなし）"

- [ ] **p2.3**: state.md への編集は常に許可される（デッドロック回避）
  - executor: claudecode
  - validations:
    - technical: "echo '{\"tool_input\":{\"file_path\":\"state.md\"}}' | bash playbook-guard.sh が exit 0"
    - consistency: "playbook=null でも exit 0"
    - completeness: "state.md パターンマッチが正しい"

- [ ] **p2.4**: playbook ファイル自体の作成は常に許可される（ブートストラップ例外）
  - executor: claudecode
  - validations:
    - technical: "echo '{\"tool_input\":{\"file_path\":\"plan/playbook-test.md\"}}' | bash playbook-guard.sh が exit 0"
    - consistency: "playbook=null でも exit 0"
    - completeness: "plan/playbook-*.md パターンマッチが正しい"

**status**: pending
**max_iterations**: 5

---

### p3: scope-guard.sh の動作検証

**goal**: done_when/done_criteria の無断変更が検出され、警告が表示されることを確認

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: done_when を含む編集で警告が表示される
  - executor: claudecode
  - validations:
    - technical: "echo '{\"tool_input\":{\"file_path\":\"plan/playbook-test.md\",\"old_string\":\"done_when:\",\"new_string\":\"done_when: modified\"}}' | bash scope-guard.sh の出力に「スコープ変更を検出」が含まれる"
    - consistency: "STRICT_MODE=false では exit 0（警告のみ）"
    - completeness: "pm エージェント経由の案内がある"

- [ ] **p3.2**: done_criteria を含む編集で警告が表示される
  - executor: claudecode
  - validations:
    - technical: "done_criteria を含む old_string/new_string で警告が出力される"
    - consistency: "playbook ファイルの場合のみ検出"
    - completeness: "project.md への変更も検出される"

- [ ] **p3.3**: STRICT_MODE=true の場合は exit 2 でブロックされる
  - executor: claudecode
  - validations:
    - technical: "STRICT_MODE=true 環境変数設定時に exit 2"
    - consistency: "エラーメッセージに「ブロックされます」が含まれる"
    - completeness: "通常は STRICT_MODE=false（警告のみ）"

- [ ] **p3.4**: 通常のファイル編集では警告が表示されない
  - executor: claudecode
  - validations:
    - technical: "done_when/done_criteria を含まない編集で警告なし"
    - consistency: "exit 0 で正常終了"
    - completeness: "stdout/stderr が空"

**status**: pending
**max_iterations**: 3

---

### p4: executor-guard.sh の動作検証

**goal**: Phase の executor が claudecode 以外の場合、コードファイル編集がブロックされることを確認

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: executor: codex の Phase でコードファイル編集がブロックされる
  - executor: claudecode
  - validations:
    - technical: "executor: codex の Phase で *.ts ファイル編集時に exit 2"
    - consistency: "エラーメッセージに「Codex CLI を使用してください」が含まれる"
    - completeness: "ドキュメントファイル（*.md）は許可される"

- [ ] **p4.2**: executor: user の Phase でコードファイル編集がブロックされる
  - executor: claudecode
  - validations:
    - technical: "executor: user の Phase で *.ts ファイル編集時に exit 2"
    - consistency: "エラーメッセージに「ユーザー作業の Phase です」が含まれる"
    - completeness: "手動作業の例が表示される"

- [ ] **p4.3**: executor: claudecode の Phase ではコードファイル編集が許可される
  - executor: claudecode
  - validations:
    - technical: "executor: claudecode の Phase で *.ts ファイル編集時に exit 0"
    - consistency: "ブロックメッセージが出力されない"
    - completeness: "全ファイルタイプで許可"

- [ ] **p4.4**: role-resolver.sh との連携が動作する
  - executor: claudecode
  - validations:
    - technical: "executor: worker の場合、toolstack A では claudecode に解決される"
    - consistency: "toolstack B では codex に解決される"
    - completeness: "role-resolver.sh が呼び出される"

- [ ] **p4.5**: Toolstack A では codex/coderabbit が使用不可
  - executor: claudecode
  - validations:
    - technical: "toolstack: A で executor: codex の Phase は exit 2"
    - consistency: "エラーメッセージに「Toolstack A では使用できません」が含まれる"
    - completeness: "toolstack 変更の案内がある"

**status**: pending
**max_iterations**: 5

---

### p5: critic-guard.sh の動作検証

**goal**: state: done への変更が critic PASS なしでブロックされることを確認

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: state: done への変更が critic 未実行時にブロックされる
  - executor: claudecode
  - validations:
    - technical: "state.md に state: done を書き込もうとして exit 2"
    - consistency: "エラーメッセージに「critic 未実行」が含まれる"
    - completeness: "critic エージェント呼び出しの案内がある"

- [ ] **p5.2**: self_complete: true が存在する場合は state: done への変更が許可される
  - executor: claudecode
  - validations:
    - technical: "state.md に self_complete: true がある場合、state: done 書き込みで exit 0"
    - consistency: "ブロックメッセージが出力されない"
    - completeness: "critic PASS 後のフローが機能する"

- [ ] **p5.3**: state.md 以外のファイルでは state: done の検出が行われない
  - executor: claudecode
  - validations:
    - technical: "playbook ファイルへの state: done 書き込みで exit 0"
    - consistency: "state.md のみが対象"
    - completeness: "他ファイルは常に許可"

**status**: pending
**max_iterations**: 3

---

### p6: critic SubAgent 連携の動作検証

**goal**: critic SubAgent が validations を評価し、PASS/FAIL を正しく判定することを確認

**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: critic.md に validations 評価ロジックが存在する
  - executor: claudecode
  - validations:
    - technical: "grep 'validations' .claude/agents/critic.md で検出される"
    - consistency: "technical/consistency/completeness の 3 点が記載されている"
    - completeness: "出力フォーマット（PASS/FAIL）が定義されている"

- [ ] **p6.2**: log-subagent.sh が critic 結果を処理する
  - executor: claudecode
  - validations:
    - technical: "log-subagent.sh に critic 結果処理コードが存在"
    - consistency: "PostToolUse:Task で発火する"
    - completeness: "state.md への結果反映ロジックがある"

- [ ] **p6.3**: critic-guard -> critic SubAgent の連携フローが明確である
  - executor: claudecode
  - validations:
    - technical: "critic-guard はブロックのみ、critic 呼び出しは Claude の責任"
    - consistency: "repository-map.yaml の integration_points に記載がある"
    - completeness: "Hook は SubAgent を直接呼び出せない制約が明記されている"

**status**: pending
**max_iterations**: 3

---

### p7: 「phase 完了」検知の代替方法確認

**goal**: 公式 Hook では「phase 完了」を検知できないことを確認し、代替方法を明確にする

**depends_on**: [p6]

#### subtasks

- [ ] **p7.1**: 公式 Hook には「phase 完了」イベントがない
  - executor: claudecode
  - validations:
    - technical: "docs/extension-system.md に「phase 完了」Hook がないことを確認"
    - consistency: "settings.json に該当イベントがない"
    - completeness: "公式ドキュメント準拠"

- [ ] **p7.2**: 代替方法: Claude の行動ルール（CLAUDE.md LOOP セクション）で実現
  - executor: claudecode
  - validations:
    - technical: "CLAUDE.md に LOOP セクションが存在"
    - consistency: "critic PASS 後の state.md 更新が明記されている"
    - completeness: "自動コミットのタイミングが明記されている"

- [ ] **p7.3**: 代替方法: PostToolUse:Edit でアーカイブ提案（archive-playbook.sh）
  - executor: claudecode
  - validations:
    - technical: "archive-playbook.sh が全 Phase done を検出"
    - consistency: "p_final の subtask 全完了を条件とする"
    - completeness: "アーカイブ提案メッセージが出力される"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: work_loop の E2E 検証が完了し、done_when が全て満たされている

**depends_on**: [p7]

#### subtasks

- [ ] **p_final.1**: PreToolUse:Edit が全 Guard を順次呼び出す
  - executor: claudecode
  - validations:
    - technical: "p1.1 の検証結果を確認（settings.json 登録）"
    - consistency: "Guard の登録順序が正しい"
    - completeness: "全 Guard が timeout 設定を持つ"

- [ ] **p_final.2**: 各 Guard が期待通りにブロック/許可する
  - executor: claudecode
  - validations:
    - technical: "p2, p3, p4, p5 の検証結果を確認"
    - consistency: "ブロック条件と許可条件が明確"
    - completeness: "エラーメッセージが適切"

- [ ] **p_final.3**: critic SubAgent との連携が動作する
  - executor: claudecode
  - validations:
    - technical: "p5, p6 の検証結果を確認"
    - consistency: "critic-guard -> critic SubAgent のフローが明確"
    - completeness: "state.md への結果反映が機能する"

- [ ] **p_final.4**: 「phase 完了」の代替検知方法が明確になっている
  - executor: claudecode
  - validations:
    - technical: "p7 の検証結果を確認"
    - consistency: "CLAUDE.md 行動ルール + archive-playbook.sh で実現"
    - completeness: "公式 Hook の制約が明記されている"

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

## 検証観点まとめ

| 検証観点 | Phase | 検証内容 |
|----------|-------|----------|
| PreToolUse:Edit が全 Guard を順次呼ぶか | p1 | settings.json 登録 + 構文検証 |
| 各 Guard が期待通りにブロック/許可するか | p2-p5 | 各 Guard の条件分岐テスト |
| critic SubAgent との連携が動作するか | p6 | critic.md 定義 + log-subagent.sh 処理 |
| 「phase 完了」の検知方法 | p7 | CLAUDE.md 行動ルール + archive-playbook.sh |
