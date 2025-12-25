# playbook-drift-sync.md

> **repository-map.yaml の DRIFT 検出機能を強化し、ARCHITECTURE.md との同期を促す仕組みを構築する**

---

## meta

```yaml
project: drift-sync
branch: feat/architecture-drift-sync
created: 2025-12-25
issue: null
reviewed: true
roles:
  worker: claudecode  # シェルスクリプト追記のため claudecode
```

---

## goal

```yaml
summary: repository-map.yaml と ARCHITECTURE.md の乖離を検出し、LLM に影響セクションを通知する
done_when:
  - generate-repository-map.sh に detect_drift_and_sync() 関数が存在する
  - start.sh に check_architecture_sync() 関数が存在する
  - DRIFT 検出時に ARCHITECTURE_SYNC_REQUIRED メッセージが出力される
  - 影響セクション（0-8）が特定され LLM に通知される
  - bash .claude/skills/session-manager/handlers/start.sh で動作確認済み
```

---

## phases

### p1: detect_drift_and_sync 関数の実装

**goal**: generate-repository-map.sh に DRIFT 検出と同期関数を追加する

#### subtasks

- [ ] **p1.1**: detect_drift_and_sync() 関数が generate-repository-map.sh に存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'detect_drift_and_sync()' .claude/hooks/generate-repository-map.sh でマッチ"
    - consistency: "既存の check_repository_map_drift() と補完的な役割"
    - completeness: "ARCHITECTURE.md との比較ロジックが含まれている"

- [ ] **p1.2**: detect_drift_and_sync() が ARCHITECTURE.md のセクション番号（0-8）を抽出できる
  - executor: claudecode
  - validations:
    - technical: "関数内で ARCHITECTURE.md のセクション見出しを解析"
    - consistency: "ARCHITECTURE.md の現在のセクション構造と一致"
    - completeness: "全セクション（0-8）が対象"

**status**: pending
**max_iterations**: 5

---

### p2: check_architecture_sync 関数の実装

**goal**: start.sh に ARCHITECTURE.md との同期チェック関数を追加する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: check_architecture_sync() 関数が start.sh に存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'check_architecture_sync()' .claude/skills/session-manager/handlers/start.sh でマッチ"
    - consistency: "既存の check_repository_map_drift() と同じ形式"
    - completeness: "セッション開始時に自動実行される位置に配置"

- [ ] **p2.2**: DRIFT 検出時に ARCHITECTURE_SYNC_REQUIRED メッセージが出力される
  - executor: claudecode
  - validations:
    - technical: "関数内に ARCHITECTURE_SYNC_REQUIRED の出力ロジックが存在"
    - consistency: "既存の DRIFT 警告メッセージと統一されたフォーマット"
    - completeness: "影響セクション番号が含まれる"

- [ ] **p2.3**: check_architecture_sync() が start.sh 内で呼び出されている
  - executor: claudecode
  - validations:
    - technical: "start.sh 内で check_architecture_sync の呼び出しが存在"
    - consistency: "check_repository_map_drift() と同じタイミングで実行"
    - completeness: "セッション開始時に自動実行される"

**status**: pending
**max_iterations**: 5

---

### p3: 動作テスト

**goal**: 実装した機能の動作を確認する

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p3.1**: bash -n で両スクリプトのシンタックスエラーがない
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/generate-repository-map.sh && bash -n .claude/skills/session-manager/handlers/start.sh が exit 0"
    - consistency: "既存の動作が壊れていない"
    - completeness: "両ファイルのシンタックスチェック完了"

- [ ] **p3.2**: start.sh を直接実行して DRIFT チェックが動作する
  - executor: claudecode
  - validations:
    - technical: "bash .claude/skills/session-manager/handlers/start.sh を実行してエラーなし"
    - consistency: "既存の出力フォーマットと整合"
    - completeness: "check_architecture_sync() が実行される"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: generate-repository-map.sh に detect_drift_and_sync() 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'detect_drift_and_sync()' .claude/hooks/generate-repository-map.sh"
    - consistency: "関数が正しい形式で定義されている"
    - completeness: "必要なロジックが全て含まれている"

- [ ] **p_final.2**: start.sh に check_architecture_sync() 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'check_architecture_sync()' .claude/skills/session-manager/handlers/start.sh"
    - consistency: "関数が正しい形式で定義されている"
    - completeness: "必要なロジックが全て含まれている"

- [ ] **p_final.3**: DRIFT 検出時に ARCHITECTURE_SYNC_REQUIRED メッセージが出力される
  - executor: claudecode
  - validations:
    - technical: "grep -q 'ARCHITECTURE_SYNC_REQUIRED' .claude/skills/session-manager/handlers/start.sh"
    - consistency: "メッセージフォーマットが統一されている"
    - completeness: "影響セクションが含まれている"

- [ ] **p_final.4**: 影響セクション（0-8）が特定され LLM に通知される
  - executor: claudecode
  - validations:
    - technical: "セクション番号を含む出力ロジックが存在"
    - consistency: "ARCHITECTURE.md のセクション構造と一致"
    - completeness: "全セクションが検出対象"

- [ ] **p_final.5**: bash .claude/skills/session-manager/handlers/start.sh で動作確認済み
  - executor: claudecode
  - validations:
    - technical: "コマンド実行が exit 0"
    - consistency: "既存の出力と整合"
    - completeness: "新機能が動作している"

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
