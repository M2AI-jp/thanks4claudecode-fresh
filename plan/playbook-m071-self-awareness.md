# playbook-m071-self-awareness.md

> **M071: 完全自己認識システム - Claude がユーザープロンプトなしで全機能を把握**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m071-self-awareness
created: 2025-12-17
issue: null
derives_from: M071
reviewed: false
```

---

## goal

```yaml
summary: Claude がユーザープロンプトに依存せず全機能を把握し、変更も自動認識する完全自己認識システムを構築
done_when:
  - docs/feature-catalog.yaml が存在し、全 Hook/SubAgent/Skill の詳細情報を含む
  - session-start.sh が feature-catalog.yaml を読み込み、機能サマリーを出力する
  - 機能の追加・削除を自動検出する仕組みが実装されている
  - 機能カタログが自動更新され、常に最新が保証されている
```

---

## phases

### p1: Feature Catalog 設計・作成

**goal**: docs/feature-catalog.yaml を設計し、全機能の詳細情報を Single Source of Truth として定義する

#### subtasks

- [ ] **p1.1**: docs/feature-catalog.yaml の構造設計が完了している
  - executor: claudecode
  - test_command: `echo "PASS - 設計は次の subtask で検証"`
  - validations:
    - technical: "YAML 構造として妥当である"
    - consistency: "repository-map.yaml と重複せず補完関係にある"
    - completeness: "Hook/SubAgent/Skill/Command の全カテゴリを網羅"

- [ ] **p1.2**: docs/feature-catalog.yaml が存在し、YAML として有効である
  - executor: claudecode
  - test_command: `test -f docs/feature-catalog.yaml && python3 -c "import yaml; yaml.safe_load(open('docs/feature-catalog.yaml'))" && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML パースが成功する"
    - consistency: "repository-map.yaml のカウントと一致"
    - completeness: "全コンポーネントの詳細情報を含む"

- [ ] **p1.3**: feature-catalog.yaml に全 Hook（31個）の詳細情報が含まれている
  - executor: claudecode
  - test_command: `grep -c "^    - name:" docs/feature-catalog.yaml | awk '{if($1>=31) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "31 件以上の Hook エントリが存在"
    - consistency: ".claude/hooks/*.sh と一致"
    - completeness: "各 Hook に purpose/trigger/dependencies が定義"

- [ ] **p1.4**: feature-catalog.yaml に全 SubAgent（6個以上）の詳細情報が含まれている
  - executor: claudecode
  - test_command: `grep -c "subagent_type:" docs/feature-catalog.yaml | awk '{if($1>=6) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "6 件以上の SubAgent エントリが存在"
    - consistency: ".claude/agents/*.md と一致"
    - completeness: "各 SubAgent に purpose/invocation が定義"

- [ ] **p1.5**: feature-catalog.yaml に全 Skill（9個以上）の詳細情報が含まれている
  - executor: claudecode
  - test_command: `grep -c "skill_dir:" docs/feature-catalog.yaml | awk '{if($1>=9) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "9 件以上の Skill エントリが存在"
    - consistency: ".claude/skills/*/ と一致"
    - completeness: "各 Skill に purpose/triggers が定義"

**status**: pending
**max_iterations**: 5

---

### p2: 自動検出・更新システム実装

**goal**: 機能の追加・削除を自動検出し、feature-catalog.yaml を自動更新する仕組みを構築

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: .claude/hooks/feature-catalog-sync.sh が存在し実行可能である
  - executor: claudecode
  - test_command: `test -x .claude/hooks/feature-catalog-sync.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが実行可能"
    - consistency: "generate-repository-map.sh と連携"
    - completeness: "全コンポーネントタイプをスキャン"

- [ ] **p2.2**: feature-catalog-sync.sh が新規 Hook を検出できる
  - executor: claudecode
  - test_command: `bash .claude/hooks/feature-catalog-sync.sh --dry-run 2>&1 | grep -q "Scanning" && echo PASS || echo FAIL`
  - validations:
    - technical: "スキャン処理が動作"
    - consistency: "実際のファイル構成と一致"
    - completeness: "追加・削除・変更を検出"

- [ ] **p2.3**: feature-catalog-sync.sh が削除された機能を検出できる
  - executor: claudecode
  - test_command: `bash .claude/hooks/feature-catalog-sync.sh --check 2>&1 | grep -qE "(OK|OUTDATED)" && echo PASS || echo FAIL`
  - validations:
    - technical: "存在チェックが動作"
    - consistency: "カタログと実ファイルの差分を検出"
    - completeness: "全カテゴリで削除検出"

- [ ] **p2.4**: settings.json に feature-catalog-sync.sh が SessionStart Hook として登録されている
  - executor: claudecode
  - test_command: `grep -q "feature-catalog-sync.sh" .claude/settings.json && echo PASS || echo FAIL`
  - validations:
    - technical: "settings.json に登録済み"
    - consistency: "他の SessionStart Hook と競合しない"
    - completeness: "適切なタイミングで発火"

**status**: pending
**max_iterations**: 5

---

### p3: セッション開始時の機能認識統合

**goal**: session-start.sh が feature-catalog.yaml を読み込み、Claude に機能サマリーを提供する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: session-start.sh が feature-catalog.yaml を読み込む処理を含む
  - executor: claudecode
  - test_command: `grep -q "feature-catalog.yaml" .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイル読み込み処理が存在"
    - consistency: "既存の session-start.sh と整合"
    - completeness: "全カテゴリを読み込み"

- [ ] **p3.2**: session-start.sh の出力に機能カウントサマリーが含まれる
  - executor: claudecode
  - test_command: `bash .claude/hooks/session-start.sh 2>&1 | grep -qE "Hooks|SubAgents|Skills" && echo PASS || echo FAIL`
  - validations:
    - technical: "サマリー出力が動作"
    - consistency: "feature-catalog.yaml のカウントと一致"
    - completeness: "全カテゴリのカウントを表示"

- [ ] **p3.3**: 機能変更があった場合に警告が出力される
  - executor: claudecode
  - test_command: `test -f .claude/hooks/session-start.sh && grep -q "OUTDATED\|変更\|WARNING" .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "警告出力ロジックが存在"
    - consistency: "feature-catalog-sync.sh の結果と連動"
    - completeness: "追加・削除・変更を全て警告"

**status**: pending
**max_iterations**: 5

---

### p4: テスト仕様作成・E2E 検証

**goal**: 機能カタログシステムのテスト仕様を作成し、E2E で動作検証する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: docs/test-spec-feature-catalog.md が存在する
  - executor: claudecode
  - test_command: `test -f docs/test-spec-feature-catalog.md && echo PASS || echo FAIL`
  - validations:
    - technical: "テスト仕様ファイルが存在"
    - consistency: "M064 の test-spec 形式と統一"
    - completeness: "全シナリオを網羅"

- [ ] **p4.2**: テスト仕様に新規機能追加シナリオが含まれる
  - executor: claudecode
  - test_command: `grep -q "新規.*追加\|追加.*検出" docs/test-spec-feature-catalog.md && echo PASS || echo FAIL`
  - validations:
    - technical: "追加シナリオが記載"
    - consistency: "実際の動作と一致"
    - completeness: "Hook/SubAgent/Skill 全てで追加検出"

- [ ] **p4.3**: テスト仕様に機能削除シナリオが含まれる
  - executor: claudecode
  - test_command: `grep -q "削除.*検出\|存在しない" docs/test-spec-feature-catalog.md && echo PASS || echo FAIL`
  - validations:
    - technical: "削除シナリオが記載"
    - consistency: "実際の動作と一致"
    - completeness: "全カテゴリで削除検出"

- [ ] **p4.4**: E2E テストが成功する（全テスト PASS）
  - executor: claudecode
  - test_command: `bash .claude/hooks/test-hooks.sh feature-catalog 2>&1 | grep -q "PASS" && echo PASS || echo FAIL`
  - validations:
    - technical: "テスト実行が成功"
    - consistency: "テスト仕様と実装が一致"
    - completeness: "全シナリオが PASS"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: M071 の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: docs/feature-catalog.yaml が存在し、全 Hook/SubAgent/Skill の詳細情報を含む
  - executor: claudecode
  - test_command: `test -f docs/feature-catalog.yaml && grep -c "purpose:" docs/feature-catalog.yaml | awk '{if($1>=40) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "ファイルが存在し詳細情報を含む"
    - consistency: "repository-map.yaml と整合"
    - completeness: "40 個以上の purpose 定義"

- [ ] **p_final.2**: session-start.sh が feature-catalog.yaml を読み込み、機能サマリーを出力する
  - executor: claudecode
  - test_command: `bash .claude/hooks/session-start.sh 2>&1 | grep -qE "[0-9]+ Hooks" && echo PASS || echo FAIL`
  - validations:
    - technical: "サマリー出力が動作"
    - consistency: "feature-catalog.yaml のカウントと一致"
    - completeness: "Hook/SubAgent/Skill 全カテゴリ"

- [ ] **p_final.3**: 機能の追加・削除を自動検出する仕組みが実装されている
  - executor: claudecode
  - test_command: `test -x .claude/hooks/feature-catalog-sync.sh && bash .claude/hooks/feature-catalog-sync.sh --check 2>&1 | grep -qE "(OK|changes)" && echo PASS || echo FAIL`
  - validations:
    - technical: "自動検出が動作"
    - consistency: "実ファイルと同期"
    - completeness: "全カテゴリで検出"

- [ ] **p_final.4**: 機能カタログが自動更新され、常に最新が保証されている
  - executor: claudecode
  - test_command: `grep -q "feature-catalog-sync.sh" .claude/settings.json && echo PASS || echo FAIL`
  - validations:
    - technical: "自動更新が設定済み"
    - consistency: "SessionStart で発火"
    - completeness: "playbook 完了時も更新"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。M071 完全自己認識システムの playbook。 |
