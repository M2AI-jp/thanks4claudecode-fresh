# playbook-m082-repository-optimization.md

> **repository-map.yaml を Single Source of Truth として、リポジトリ構造を最適化する**

---

## meta

```yaml
project: m082-repository-optimization
branch: feat/m082-repository-optimization
created: 2025-12-22
issue: null
derives_from: null  # 新規タスク
reviewed: false
roles:
  orchestrator: claudecode
  worker: claudecode
  reviewer: claudecode
  human: user
```

---

## goal

```yaml
summary: repository-map.yaml を Single Source of Truth として、リポジトリの構造・仕様・ドキュメント配置を最適化する
done_when:
  - repository-map.yaml が MECE 原則に基づいて整理されている（重複・漏れなし）
  - workflows セクションが最新の Hook/SubAgent/Skill 構成を反映している
  - 不要ファイル・孤立ファイルが特定され、削除計画が明確である
  - repository-map.yaml の自動更新スクリプトが正常に動作する
```

---

## phases

### p1: 現状分析 - repository-map.yaml の構造評価

**goal**: 現在の repository-map.yaml の構造を分析し、最適化対象を特定する

#### subtasks

- [ ] **p1.1**: docs/repository-map.yaml を全文読み、セクション構成を把握する
  - executor: claudecode
  - test_command: `test -f docs/repository-map.yaml && wc -l docs/repository-map.yaml | awk '{print $1}'`
  - validations:
    - technical: "ファイルが存在し、行数がカウントできる"
    - consistency: "実ディレクトリ構造と一致するセクションが存在"
    - completeness: "全セクション（hooks, agents, skills, commands, docs, plan, workflows など）を確認"

- [ ] **p1.2**: repository-map.yaml の hooks セクションと実際の .claude/hooks/ ディレクトリを比較
  - executor: claudecode
  - test_command: `ls -1 .claude/hooks/*.sh 2>/dev/null | wc -l`
  - validations:
    - technical: "ls コマンドが正常に実行でき、ファイル数がカウントできる"
    - consistency: "repository-map.yaml に記載された hooks 数と実ディレクトリの数が一致するか確認"
    - completeness: "不足している Hook や余分な Hook を特定"

- [ ] **p1.3**: workflows セクションの完全性を確認
  - executor: claudecode
  - test_command: `grep -c 'name:' docs/repository-map.yaml | awk '{if($1>=6) print "PASS"}'`
  - validations:
    - technical: "grep コマンドで workflow 数をカウント可能"
    - consistency: "各 workflow が実装された Hook/SubAgent と対応しているか確認"
    - completeness: "CLAUDE.md と workflows セクションの内容が一致するか確認"

- [ ] **p1.4**: docs/criterion-validation-rules.md との関連を確認
  - executor: claudecode
  - test_command: `test -f docs/criterion-validation-rules.md && echo PASS`
  - validations:
    - technical: "ファイルが存在することを確認"
    - consistency: "repository-map.yaml で参照されているか確認"
    - completeness: "不足している参照ドキュメントを特定"

**status**: pending
**max_iterations**: 5

---

### p2: MECE 分析 - 重複・漏れ・衝突の検出

**goal**: repository-map.yaml を MECE（Mutually Exclusive, Collectively Exhaustive）原則で整理

#### subtasks

- [ ] **p2.1**: hooks セクションの重複を検出
  - executor: claudecode
  - test_command: `grep 'name:' docs/repository-map.yaml | sort | uniq -d | wc -l | awk '{if($1==0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "重複検出ロジックが正常に動作"
    - consistency: "重複がない場合 PASS、ある場合は一覧を出力"
    - completeness: "全セクション（agents, skills, commands, docs）も同様にチェック"

- [ ] **p2.2**: 漏れを検出 - 実ディレクトリにあるが repository-map.yaml に記載されていないファイル
  - executor: claudecode
  - test_command: `diff -q <(ls -1 .claude/hooks/*.sh 2>/dev/null | xargs -I{} basename {}) <(grep 'file:.*\.sh' docs/repository-map.yaml | awk -F'/' '{print $NF}' | sort | uniq) | wc -l | awk '{if($1==0) print "PASS"}'`
  - validations:
    - technical: "diff コマンドで比較可能"
    - consistency: "漏れがある場合、ファイル名と repository-map.yaml のキー名が一致するか確認"
    - completeness: "漏れたファイルをリスト化"

- [ ] **p2.3**: 孤立ファイル - repository-map.yaml に記載されているが実際には存在しないファイル
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh 2>&1 | grep -c 'WARN.*not found' || echo 0`
  - validations:
    - technical: "generate-repository-map.sh が正常に実行できる"
    - consistency: "孤立ファイルの検出ロジックが明確"
    - completeness: "孤立ファイルリストを作成"

- [ ] **p2.4**: workflows における誤参照を検出
  - executor: claudecode
  - test_command: `grep -c 'trigger:' docs/repository-map.yaml | awk '{if($1>=20) print "PASS"}'`
  - validations:
    - technical: "trigger フィールドがカウント可能"
    - consistency: "各 workflow の trigger が実装済み Hook に対応しているか確認"
    - completeness: "trigger が定義されていない workflow を特定"

**status**: pending
**max_iterations**: 5
**depends_on**: [p1]

---

### p3: workflows セクションの再構築

**goal**: repository-map.yaml の workflows を、最新のシステム仕様に基づいて再構築

#### subtasks

- [ ] **p3.1**: 現在の workflows セクション（init_flow, work_loop, post_loop, consent_process, critique_process, project_complete）を .yaml 形式で抽出
  - executor: claudecode
  - test_command: `grep -A 100 'workflows:' docs/repository-map.yaml | head -150 | wc -l | awk '{if($1>=50) print "PASS"}'`
  - validations:
    - technical: "workflows セクションを正常に抽出"
    - consistency: "セクション構造が YAML 形式として有効"
    - completeness: "全 workflow が含まれている"

- [ ] **p3.2**: CLAUDE.md の「Core Contract（11.）」セクションと workflows を対応付け
  - executor: claudecode
  - test_command: `grep -q 'golden_path\|playbook_gate\|reviewer_gate' CLAUDE.md && echo PASS`
  - validations:
    - technical: "CLAUDE.md から Contract ルールを抽出可能"
    - consistency: "golden_path の実装（pm → playbook）が workflows に反映されているか確認"
    - completeness: "all Gate（Golden Path, Playbook Gate, Reviewer Gate）が workflows に含まれている"

- [ ] **p3.3**: workflows に「state_injection」「pre-bash-check」「subtask-guard」を追加（M079, M021, M018）
  - executor: claudecode
  - test_command: `grep -E 'state_injection|pre-bash-check|subtask-guard' docs/repository-map.yaml | wc -l | awk '{if($1>=3) print "PASS"}'`
  - validations:
    - technical: "新規 workflow エントリが YAML として有効"
    - consistency: ".claude/settings.json の Hook 登録と一致"
    - completeness: "各 workflow の trigger / dependencies / actors が定義されている"

- [ ] **p3.4**: workflows の依存関係グラフ（DAG）を可視化
  - executor: claudecode
  - test_command: `test -f tmp/workflow-dag.txt && wc -l tmp/workflow-dag.txt | awk '{if($1>=10) print "PASS"}'`
  - validations:
    - technical: "DAG ファイルが生成可能"
    - consistency: "hooks_trigger_sequence と workflows の依存関係が一致"
    - completeness: "循環依存や孤立した workflow がない"

**status**: pending
**max_iterations**: 5
**depends_on**: [p2]

---

### p4: 不要ファイル特定・クリーンナップ計画

**goal**: repository-map.yaml の分析結果に基づいて、削除対象ファイルを特定し、クリーンナップ計画を策定

#### subtasks

- [ ] **p4.1**: p2 の分析結果（孤立ファイル、重複ファイル）を集約
  - executor: claudecode
  - test_command: `test -f tmp/cleanup-plan.md && grep -c '- \[ \]' tmp/cleanup-plan.md | awk '{if($1>=5) print "PASS"}'`
  - validations:
    - technical: "クリーンナップ計画ファイルが生成可能"
    - consistency: "計画内容が p2 の分析結果と一致"
    - completeness: "削除対象、理由、バックアップ方法が明記されている"

- [ ] **p4.2**: state.md / project.md / playbook で参照されているファイルを一覧化
  - executor: claudecode
  - test_command: `grep -r 'docs/\|plan/\|.claude/' state.md project.md 2>/dev/null | wc -l | awk '{if($1>=10) print "PASS"}'`
  - validations:
    - technical: "参照一覧を抽出可能"
    - consistency: "参照元ファイルが実際に存在"
    - completeness: "所有者別（project, playbook, state）の参照が把握できている"

- [ ] **p4.3**: docs/ ディレクトリ内でカテゴリ別に整理（理由を明記）
  - executor: claudecode
  - test_command: `ls -1 docs/*.md | wc -l | awk '{if($1>=10) print "PASS"}'`
  - validations:
    - technical: "docs/ 内の全ファイルをリスト可能"
    - consistency: "各ファイルが repository-map.yaml の docs セクションに記載されている"
    - completeness: "未分類ファイルの取扱い方が明確"

- [ ] **p4.4**: .archive/ ディレクトリの状態を確認
  - executor: claudecode
  - test_command: `test -d .archive && ls -1 .archive/ | wc -l | awk '{if($1>=1) print "PASS"}'`
  - validations:
    - technical: ".archive/ ディレクトリが存在し、アクセス可能"
    - consistency: "archived playbook との参照関係がある"
    - completeness: "不要な archived item はないか確認"

**status**: pending
**max_iterations**: 5
**depends_on**: [p3]

---

### p5: docs/repository-map.yaml の修正・最適化

**goal**: 分析結果に基づいて repository-map.yaml を修正、最適化版を作成

#### subtasks

- [ ] **p5.1**: 孤立ファイルを削除（またはバックアップ）
  - executor: claudecode
  - test_command: `test ! -f {孤立ファイルパス} && echo PASS || echo FAIL`
  - validations:
    - technical: "削除コマンドが正常に実行"
    - consistency: "git status で削除が追跡可能"
    - completeness: "関連参照も削除されている"

- [ ] **p5.2**: hooks / agents / skills / commands / docs セクションを再整理（MECE に基づく）
  - executor: claudecode
  - test_command: `grep -A 200 'hooks:' docs/repository-map.yaml | grep 'name:' | wc -l | awk '{print $1 ": hooks"}'`
  - validations:
    - technical: "セクション再整理が YAML 形式として有効"
    - consistency: "実ディレクトリと一致"
    - completeness: "カテゴリ分類に重複・漏れがない"

- [ ] **p5.3**: workflows セクションを最新仕様で再構築（p3 の成果物を統合）
  - executor: claudecode
  - test_command: `grep -c 'trigger:' docs/repository-map.yaml | awk '{if($1>=20) print "PASS"}'`
  - validations:
    - technical: "workflow エントリが正常に追加"
    - consistency: "Hook 登録順序と trigger sequence が一致"
    - completeness: "全 workflow が coverage されている"

- [ ] **p5.4**: 新規セクション「integration_points」を追加（Hook・SubAgent・Skill 間の依存関係）
  - executor: claudecode
  - test_command: `grep -q 'integration_points:' docs/repository-map.yaml && echo PASS`
  - validations:
    - technical: "新セクションが YAML として有効"
    - consistency: "依存関係グラフと一致"
    - completeness: "全ての接続点が明示されている"

- [ ] **p5.5**: repository-map.yaml を validate（YAML 構文チェック、参照チェック）
  - executor: claudecode
  - test_command: `python3 -c "import yaml; yaml.safe_load(open('docs/repository-map.yaml'))" && echo PASS`
  - validations:
    - technical: "YAML パーサーが正常に動作"
    - consistency: "参照先ファイルが全て存在"
    - completeness: "スキーマ不正がない"

**status**: pending
**max_iterations**: 5
**depends_on**: [p4]

---

### p6: 自動更新スクリプトの検証・改善

**goal**: repository-map.yaml 自動更新スクリプト（generate-repository-map.sh）が正常に動作することを確認

#### subtasks

- [ ] **p6.1**: generate-repository-map.sh を実行し、更新が正常に動作するか確認
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && grep -q 'hooks:' docs/repository-map.yaml && echo PASS`
  - validations:
    - technical: "スクリプトが exit code 0 で終了"
    - consistency: "更新後の repository-map.yaml が有効 YAML"
    - completeness: "全セクションが正常に更新されている"

- [ ] **p6.2**: 冪等性の検証 - 2 回連続で実行して差分がないか確認
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && cp docs/repository-map.yaml /tmp/map1.yaml && bash .claude/hooks/generate-repository-map.sh && diff /tmp/map1.yaml docs/repository-map.yaml | wc -l | awk '{if($1==0) print "PASS"}'`
  - validations:
    - technical: "2 回実行で同一の出力が得られる"
    - consistency: "冪等性が保証されている"
    - completeness: "ランダム要素や時刻依存がない"

- [ ] **p6.3**: hooks / agents / skills / commands / docs 各セクションの自動検出が正常か確認
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh 2>&1 | grep -c 'Updated.*section' | awk '{if($1>=5) print "PASS"}'`
  - validations:
    - technical: "各セクションの更新ログが出力される"
    - consistency: "更新内容が正確"
    - completeness: "新規ファイルの自動検出が機能している"

- [ ] **p6.4**: workflows セクションの自動生成（または更新ガイドライン）
  - executor: claudecode
  - test_command: `grep -A 50 'workflows:' docs/repository-map.yaml | grep -c 'name:' | awk '{if($1>=6) print "PASS"}'`
  - validations:
    - technical: "workflows が正常に生成・更新されている"
    - consistency: ".claude/settings.json と一致"
    - completeness: "全 workflow が coverage されている"

**status**: pending
**max_iterations**: 5
**depends_on**: [p5]

---

### p7: ドキュメント更新・統合

**goal**: 最適化内容を docs/ に反映し、参照関係を整理

#### subtasks

- [ ] **p7.1**: docs/repository-structure.md を作成（新規）- repository-map.yaml の説明
  - executor: claudecode
  - test_command: `test -f docs/repository-structure.md && wc -l docs/repository-structure.md | awk '{if($1>=50) print "PASS"}'`
  - validations:
    - technical: "ドキュメントファイルが生成可能"
    - consistency: "repository-map.yaml の内容と一致"
    - completeness: "セクション別の詳細説明が含まれている"

- [ ] **p7.2**: repository-map.yaml への参照を project.md に追加
  - executor: claudecode
  - test_command: `grep -q 'repository-map.yaml' project.md && echo PASS`
  - validations:
    - technical: "参照を追加可能"
    - consistency: "project.md の参照セクションに合わせた記述"
    - completeness: "他の参照ファイル（state.md など）との一貫性"

- [ ] **p7.3**: RUNBOOK.md に「repository-map.yaml 管理」セクションを追加
  - executor: claudecode
  - test_command: `grep -q 'repository-map' RUNBOOK.md && echo PASS`
  - validations:
    - technical: "セクション追加が可能"
    - consistency: "他の RUNBOOK セクションとトーン・フォーマットが一致"
    - completeness: "手動更新時のガイドラインが明確"

- [ ] **p7.4**: 中間成果物（分析結果、DAG ファイル等）を tmp/ から削除
  - executor: claudecode
  - test_command: `find tmp/ -name 'cleanup-plan.md' -o -name 'workflow-dag.txt' | wc -l | awk '{if($1==0) print "PASS"}'`
  - validations:
    - technical: "一時ファイル削除が完了"
    - consistency: "git status で追跡可能"
    - completeness: "最終成果物のみが残存"

**status**: pending
**max_iterations**: 5
**depends_on**: [p6]

---

### p_final: 完了検証

**goal**: repository-map.yaml の最適化が完全に達成されたことを確認

#### subtasks

- [ ] **p_final.1**: repository-map.yaml が MECE 原則に基づいて整理されている（重複・漏れなし）
  - executor: claudecode
  - test_command: `python3 -c "import yaml; m=yaml.safe_load(open('docs/repository-map.yaml')); print(len(m.get('hooks', {}).get('entries', [])))" | awk '{if($1>=31) print "PASS"}'`
  - validations:
    - technical: "YAML が解析可能で hooks が少なくとも 31 個存在"
    - consistency: "実ディレクトリ数と一致"
    - completeness: "重複・漏れの自動チェックが PASS"

- [ ] **p_final.2**: workflows セクションが最新の Hook/SubAgent/Skill 構成を反映している
  - executor: claudecode
  - test_command: `grep -A 100 'workflows:' docs/repository-map.yaml | grep -c 'trigger:' | awk '{if($1>=20) print "PASS"}'`
  - validations:
    - technical: "workflow エントリが少なくとも 20 個以上"
    - consistency: ".claude/settings.json と Hook 登録が一致"
    - completeness: "全 workflow type（init_flow, work_loop, post_loop, etc）が coverage"

- [ ] **p_final.3**: 不要ファイル・孤立ファイルが特定され、削除計画が明確である
  - executor: claudecode
  - test_command: `test ! -f docs/cleanup-plan.md || test -f docs/repository-optimization-report.md && echo PASS`
  - validations:
    - technical: "クリーンナップ計画が実行済みまたはレポート化"
    - consistency: "git log で削除が追跡可能"
    - completeness: "残存ファイルが全て必要なものであることが確認"

- [ ] **p_final.4**: repository-map.yaml の自動更新スクリプトが正常に動作する
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && bash -n .claude/hooks/generate-repository-map.sh && echo PASS`
  - validations:
    - technical: "スクリプトが実行でき、構文エラーなし"
    - consistency: "冪等性が保証されている"
    - completeness: "全セクションが自動更新される"

**status**: pending

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

## 備考

- このタスクは **計画駆動型** であり、repository-map.yaml の最適化は段階的に進行
- p1～p4 は分析・計画フェーズ、p5～p7 は実装・検証フェーズ
- 大きな変更は git でコミットして追跡可能にする
- 中間成果物（DAG、分析結果）は tmp/ に配置し、最終フェーズで削除
