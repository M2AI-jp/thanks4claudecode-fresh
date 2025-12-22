# playbook-repository-map-sync.md

> **repository-map.yaml を Claude が安定して同期できるワークフローを実装**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/repository-map-sync-workflow
created: 2025-12-22
issue: null
derives_from: null  # 新規タスク（既存 done_when に該当なし）
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: session-start.sh に差分チェックを追加し、repository-map.yaml の乖離を自動検出する
done_when:
  - session-start.sh に差分チェック関数（check_repository_map_drift）が存在する
  - 乖離検出時に [DRIFT] repository-map.yaml に乖離あり メッセージが出力される
  - RUNBOOK.md に [DRIFT] 検出時の対応ルールが記載されている
  - docs/repository-structure.md に同期ワークフローの説明が追加されている
```

---

## phases

### p1: 差分チェック関数の実装

**goal**: session-start.sh に軽量な差分チェック関数を追加する

#### subtasks

- [ ] **p1.1**: session-start.sh に check_repository_map_drift 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'check_repository_map_drift' .claude/hooks/session-start.sh で関数存在を確認"
    - consistency: "session-start.sh の既存機能（pending 設定、state.md 更新）が壊れていないことを確認"
    - completeness: "関数内に hooks/agents/skills/commands の 4 カテゴリのカウント比較ロジックがある"

- [ ] **p1.2**: 差分チェックが 1 秒以内に完了する
  - executor: claudecode
  - validations:
    - technical: "time bash .claude/hooks/session-start.sh で実行時間を測定"
    - consistency: "既存の session-start.sh 出力フォーマットが変更されていない"
    - completeness: "find コマンドで実ファイル数をカウントし、repository-map.yaml の count と比較"

- [ ] **p1.3**: 乖離検出時に [DRIFT] メッセージが出力される
  - executor: claudecode
  - validations:
    - technical: "一時的にファイルを追加/削除し、session-start.sh 実行で [DRIFT] が出力されることを確認"
    - consistency: "メッセージ形式が他の Hook 警告（[WARN], [BLOCK]）と統一されている"
    - completeness: "[DRIFT] メッセージに乖離の詳細（expected vs actual）が含まれる"

**status**: done
**max_iterations**: 5

---

### p2: ドキュメント更新

**goal**: RUNBOOK.md と docs/repository-structure.md を更新する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: RUNBOOK.md に [DRIFT] 検出時の対応ルールが記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -q '\\[DRIFT\\]' RUNBOOK.md で記載を確認"
    - consistency: "RUNBOOK.md の既存フォーマット（yaml/tables/code blocks）に従っている"
    - completeness: "対応手順（generate-repository-map.sh 実行）が明記されている"

- [ ] **p2.2**: docs/repository-structure.md に同期ワークフローの説明が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'DRIFT' docs/repository-structure.md で記載を確認"
    - consistency: "既存のセクション構成と整合性がある"
    - completeness: "差分検出の仕組み、検出時の対応、手動更新方法が含まれる"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされていることを最終検証する

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p_final.1**: session-start.sh に check_repository_map_drift 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -q 'check_repository_map_drift' .claude/hooks/session-start.sh && echo PASS"
    - consistency: "bash -n .claude/hooks/session-start.sh でシンタックスエラーがない"
    - completeness: "関数が呼び出されていることを確認"

- [ ] **p_final.2**: 乖離検出時に [DRIFT] メッセージが出力される
  - executor: claudecode
  - validations:
    - technical: "実際の乖離シナリオでテスト実行"
    - consistency: "出力フォーマットが一貫している"
    - completeness: "Claude が自動で generate-repository-map.sh を実行するルールが明文化されている"

- [ ] **p_final.3**: RUNBOOK.md に対応ルールが記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -q '\\[DRIFT\\]' RUNBOOK.md && echo PASS"
    - consistency: "既存の Troubleshooting セクションと整合"
    - completeness: "具体的なコマンドが記載されている"

- [x] **p_final.4**: docs/repository-structure.md に説明が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'DRIFT' docs/repository-structure.md && echo PASS"
    - consistency: "既存ドキュメント構造と整合"
    - completeness: "同期ワークフロー全体が説明されている"

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

## 技術的詳細

### 差分チェック関数の設計

```bash
check_repository_map_drift() {
    local REPO_MAP="docs/repository-map.yaml"

    # repository-map.yaml が存在しない場合はスキップ
    [ ! -f "$REPO_MAP" ] && return 0

    # 実際のファイル数をカウント
    local ACTUAL_HOOKS=$(find .claude/hooks -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_AGENTS=$(find .claude/agents -maxdepth 1 -name "*.md" -type f ! -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_SKILLS=$(find .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_COMMANDS=$(find .claude/commands -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    # repository-map.yaml の count を取得
    local EXPECTED_HOOKS=$(grep -A2 "^hooks:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_AGENTS=$(grep -A2 "^agents:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_SKILLS=$(grep -A2 "^skills:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_COMMANDS=$(grep -A2 "^commands:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')

    # 乖離チェック
    local DRIFT=false
    local DRIFT_DETAILS=""

    if [ "$ACTUAL_HOOKS" != "$EXPECTED_HOOKS" ]; then
        DRIFT=true
        DRIFT_DETAILS="hooks: $EXPECTED_HOOKS -> $ACTUAL_HOOKS"
    fi
    if [ "$ACTUAL_AGENTS" != "$EXPECTED_AGENTS" ]; then
        DRIFT=true
        DRIFT_DETAILS="$DRIFT_DETAILS agents: $EXPECTED_AGENTS -> $ACTUAL_AGENTS"
    fi
    if [ "$ACTUAL_SKILLS" != "$EXPECTED_SKILLS" ]; then
        DRIFT=true
        DRIFT_DETAILS="$DRIFT_DETAILS skills: $EXPECTED_SKILLS -> $ACTUAL_SKILLS"
    fi
    if [ "$ACTUAL_COMMANDS" != "$EXPECTED_COMMANDS" ]; then
        DRIFT=true
        DRIFT_DETAILS="$DRIFT_DETAILS commands: $EXPECTED_COMMANDS -> $ACTUAL_COMMANDS"
    fi

    if [ "$DRIFT" = true ]; then
        echo ""
        echo "[DRIFT] repository-map.yaml に乖離あり"
        echo "  詳細: $DRIFT_DETAILS"
        echo "  対応: bash .claude/hooks/generate-repository-map.sh を実行してください"
        echo ""
    fi
}
```

### Claude の自動対応ルール（RUNBOOK.md に追加）

```yaml
[DRIFT] 検出時の対応:
  トリガー: session-start.sh が [DRIFT] メッセージを出力
  対応:
    1. bash .claude/hooks/generate-repository-map.sh を実行
    2. 更新された repository-map.yaml を確認
    3. 必要に応じて git add && git commit

  自動化レベル:
    - Claude が [DRIFT] を検出した場合、自動で更新を実行
    - コミットはユーザー確認後に行う
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成 |
