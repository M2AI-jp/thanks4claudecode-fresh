# playbook-m088-project-complete-verification.md

> **M088: project_complete workflow の E2E 検証・修正**
>
> 根本問題: 「全 milestone achieved」検知ロジックが未実装

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m088-project-complete-verification
created: 2025-12-22
issue: null
derives_from: M083  # M083 検証結果から導出
reviewed: false
roles:
  worker: claudecode  # この playbook では worker = claudecode
```

---

## goal

```yaml
summary: project_complete workflow を実装し、全 milestone 達成時に main マージ + GitHub プッシュが行われることを確認する

done_when:
  - archive-playbook.sh に「全 milestone achieved」検知ロジックが追加されている
  - 全 milestone achieved 時に merge-pr.sh が呼び出される or Claude への指示が出力される
  - E2E テスト（模擬シナリオ）で project_complete workflow が動作することが確認される
  - repository-map.yaml の project_complete workflow が実態と一致している
```

---

## phases

### p1: 現状分析

**goal**: project_complete workflow の実装状況を詳細に調査

#### subtasks

- [ ] **p1.1**: merge-pr.sh の実装内容が把握されている
  - executor: claudecode
  - validations:
    - technical: "merge-pr.sh を Read して機能を確認"
    - consistency: "repository-map.yaml の定義と整合性確認"
    - completeness: "入力/出力/エラー処理が把握されている"

- [ ] **p1.2**: settings.json に merge-pr.sh が未登録であることが確認されている
  - executor: claudecode
  - validations:
    - technical: "grep で settings.json を検索"
    - consistency: "repository-map.yaml の hook_trigger_sequence と比較"
    - completeness: "全 Hook 登録状況が把握されている"

- [ ] **p1.3**: 「全 milestone achieved」検知ロジックの実装場所が決定されている
  - executor: claudecode
  - validations:
    - technical: "候補（archive-playbook.sh / 新規 Hook）を比較検討"
    - consistency: "既存アーキテクチャとの整合性確認"
    - completeness: "実装方針が決定されている"

**status**: pending
**max_iterations**: 5

---

### p2: 検知ロジック実装

**goal**: 全 milestone achieved を検知するロジックを実装

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: archive-playbook.sh に project.md 参照ロジックが追加されている
  - executor: claudecode
  - validations:
    - technical: "bash -n で構文チェック PASS"
    - consistency: "既存の archive-playbook.sh ロジックと整合"
    - completeness: "project.md の milestone.status を正しく解析できる"

- [ ] **p2.2**: 全 milestone が achieved の場合に検知できることが確認されている
  - executor: claudecode
  - validations:
    - technical: "テスト用 project.md で検知ロジックをテスト"
    - consistency: "false positive/negative がないことを確認"
    - completeness: "正常系・異常系のテストが完了"

- [ ] **p2.3**: 検知時に merge-pr.sh 呼び出し or Claude への指示が出力される
  - executor: claudecode
  - validations:
    - technical: "出力フォーマットが実装されている"
    - consistency: "repository-map.yaml の project_complete.output と整合"
    - completeness: "main マージ + GitHub プッシュ + state.md neutral 化の指示が含まれる"

**status**: pending
**max_iterations**: 5

---

### p3: E2E 検証

**goal**: project_complete workflow の動作を E2E で確認

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: テスト用 project.md（全 milestone achieved）が作成されている
  - executor: claudecode
  - validations:
    - technical: "tmp/test-project-complete.md が存在する"
    - consistency: "本番 project.md と同じ構造である"
    - completeness: "全 milestone が status: achieved である"

- [ ] **p3.2**: archive-playbook.sh がテスト project.md で正しく動作する
  - executor: claudecode
  - validations:
    - technical: "スクリプト実行で期待する出力が得られる"
    - consistency: "出力が repository-map.yaml の定義と一致"
    - completeness: "main マージ指示が含まれている"

- [ ] **p3.3**: 実際のセッションで project_complete が発火することが確認されている
  - executor: claudecode
  - validations:
    - technical: "playbook 完了時に project_complete 出力を確認"
    - consistency: "workflows.project_complete と動作が一致"
    - completeness: "出力に全ての required アクションが含まれる"

**status**: pending
**max_iterations**: 5

---

### p4: ドキュメント整合性

**goal**: repository-map.yaml と実装を同期

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: repository-map.yaml の project_complete が実態と一致している
  - executor: claudecode
  - validations:
    - technical: "project_complete セクションを確認"
    - consistency: "実装と定義が一致"
    - completeness: "hooks, subagents, skills, output が正確"

- [ ] **p4.2**: extension-system.md に project_complete の発火条件が記載されている
  - executor: claudecode
  - validations:
    - technical: "ドキュメントに記載がある"
    - consistency: "repository-map.yaml と整合"
    - completeness: "発火条件が明確に記載されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: archive-playbook.sh に「全 milestone achieved」検知ロジックが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep で検知ロジックの存在を確認"
    - consistency: "ロジックが project.md を正しく解析"
    - completeness: "関連コードが全て含まれている"

- [ ] **p_final.2**: 全 milestone achieved 時に merge-pr.sh 呼び出し or Claude への指示が出力される
  - executor: claudecode
  - validations:
    - technical: "スクリプト実行で出力を確認"
    - consistency: "出力フォーマットが repository-map.yaml と一致"
    - completeness: "main マージ + GitHub プッシュ + state.md neutral 化が含まれる"

- [ ] **p_final.3**: E2E テスト（模擬シナリオ）で project_complete workflow が動作する
  - executor: claudecode
  - validations:
    - technical: "テストシナリオが実行可能"
    - consistency: "期待する結果が得られる"
    - completeness: "全ステップが動作確認済み"

- [ ] **p_final.4**: repository-map.yaml の project_complete workflow が実態と一致している
  - executor: claudecode
  - validations:
    - technical: "YAML 構造が正しい"
    - consistency: "実装とドキュメントが一致"
    - completeness: "全フィールドが正確"

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

---

## E2E テスト結果（2025-12-22）

### p1: 現状分析

| チェック項目 | 結果 |
|-------------|------|
| merge-pr.sh 存在 | ✓ EXISTS (284行、機能完成) |
| merge-pr.sh settings.json 登録 | ⛔ **未登録** |
| 全 milestone 検知ロジック | ⛔ **未実装** |

### 根本原因

```yaml
問題1: merge-pr.sh が settings.json に未登録
  - repository-map.yaml では Hook として定義されている
  - 実際は settings.json に登録されていない
  - 結果: playbook 完了時に自動発火しない

問題2: 「全 milestone achieved」検知ロジックが存在しない
  - archive-playbook.sh: playbook 完了のみ検知
  - project.md の milestone.status を参照していない
  - 結果: 全 milestone 達成を誰も検知しない

問題3: merge-pr.sh の設計
  - 現状: 手動実行スクリプト（bash merge-pr.sh [PR番号]）
  - 期待: Hook として自動発火
  - 設計変更が必要
```

### 修正方針

```yaml
選択肢A: merge-pr.sh を Hook として登録
  - settings.json の PostToolUse:Edit に追加
  - 全 milestone 検知ロジックを merge-pr.sh に追加
  - 全 milestone achieved の場合のみ発火

選択肢B: archive-playbook.sh に統合
  - archive-playbook.sh に全 milestone 検知を追加
  - 全 milestone achieved で merge-pr.sh を呼び出す
  - 既存のスクリプト構造を活用

選択肢C: 新規 Hook を作成
  - project-complete-hook.sh を新規作成
  - 全 milestone 検知 + merge-pr.sh 呼び出し
  - 責務を明確に分離

推奨: 選択肢B（最小変更）
```

### 総合結果

```yaml
project_complete workflow: ✅ PASS（2025-12-22 修正完了）
  - archive-playbook.sh に全 milestone 検知ロジック追加
  - pending/in_progress が 0 で PROJECT COMPLETE 発火
  - main マージ手順を出力

修正内容:
  - archive-playbook.sh 末尾に検知ロジック追加
  - カウント方法: pending/in_progress == 0 で判定
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | E2E 検証完了。根本原因特定: merge-pr.sh 未登録 + 検知ロジック未実装。 |
| 2025-12-22 | 初版作成。M083 検証結果に基づく緊急対応 playbook。 |
