# playbook-skill-audit-v2.md

> **外部検証・反証モードによる機能監査**

---

## meta

```yaml
project: skill-audit-v2
branch: refactor/skill-audit-v2
created: 2026-01-03
reviewed: true
context_approved: true
```

---

## context

```yaml
previous_failure:
  - "bash -n だけで works 判定"
  - "全て keep（統計的に不自然）"
  - "自己採点・外部検証なし"

design_fix:
  - "実行テストで検証"
  - "codex で独立評価"
  - "反証モード（問題を探す）"
  - "未確定は undetermined"
```

---

## goal

```yaml
done_when:
  - 依存グラフが生成されている
  - 実行テスト結果が記録されている
  - codex による反証評価が完了している
  - 問題と未確定がリストされている
```

---

## phases

### p1: 依存グラフ生成

**goal**: スクリプト間の呼び出し関係を可視化

#### subtasks

- [x] **p1.1**: pre-tool.sh の依存抽出
  - validations:
    - technical: "PASS - grep 実行、3 依存検出"
    - consistency: "PASS - 行番号付きで記録"
    - completeness: "PASS - bash/source パターン網羅"
  - result:
    - line 13: `source "$LIB_DIR/common.sh"`
    - line 26: `bash "$path"` (guard 呼び出し)
    - line 61: `bash-check.sh` 呼び出し
  - validated: 2026-01-03T12:45:00

- [x] **p1.2**: post-tool.sh の依存抽出
  - validations:
    - technical: "PASS - grep 実行、2 依存検出"
    - consistency: "PASS - 行番号付きで記録"
    - completeness: "PASS - bash/source パターン網羅"
  - result:
    - line 13: `source "$LIB_DIR/common.sh"`
    - line 26: `bash "$path"` (handler 呼び出し)
  - validated: 2026-01-03T12:45:00

- [x] **p1.3**: 全 guard の依存抽出
  - validations:
    - technical: "PASS - 14 ファイル検査"
    - consistency: "PASS - 依存先行番号付き"
    - completeness: "PASS - guards/ 全ファイル網羅"
  - result:
    - files_checked: 14
    - key_dependencies:
      - executor-guard.sh:117 → role-resolver.sh
      - playbook-guard.sh:108,139,172 → failure-logger.sh
      - bash-check.sh:35 → contract.sh
      - protected-edit.sh:28 → contract.sh
      - coherence.sh:9 → state-schema.sh
  - validated: 2026-01-03T12:45:00

- [x] **p1.4**: 未参照ファイル検出
  - validations:
    - technical: "PASS - 31 スクリプト検査"
    - consistency: "PASS - 未参照 0 件確認"
    - completeness: "PASS - guards/handlers/workflow/scripts 全検査"
  - result:
    - total_scripts: 31
    - unreferenced: 0
  - validated: 2026-01-03T12:45:00

**status**: done

---

### p2: 実行テスト

**goal**: 実際に実行して動作確認

#### subtasks

- [x] **p2.1**: pre-tool.sh 模擬実行
  - validations:
    - technical: "EXECUTED - 警告のみ出力"
    - consistency: "ISSUE - ALLOW/BLOCK/WARN 未出力"
    - completeness: "PARTIAL - 動作するが期待出力なし"
  - result:
    - output: "⚠️ playbook ファイルが存在しません"
    - issue: "古い playbook パスを参照している可能性（要調査）"
  - validated: 2026-01-03T12:50:00

- [x] **p2.2**: playbook-guard 単体テスト
  - validations:
    - technical: "TIMEOUT - 実行がハング"
    - consistency: "ISSUE - 応答なし"
    - completeness: "FAIL - テスト不完全"
  - result:
    - issue: "スクリプトがハング（入力待ち or 無限ループ）"
    - dependency_issue: "failure-logger.sh が存在しない（line 107,138,171）"
  - validated: 2026-01-03T12:50:00

- [x] **p2.3**: main-branch-guard 単体テスト
  - validations:
    - technical: "PASS - EXIT_CODE: 0"
    - consistency: "PASS - feature ブランチなのでブロックしない（正常）"
    - completeness: "PASS"
  - result:
    - branch: "refactor/skill-audit-v2"
    - exit_code: 0
  - validated: 2026-01-03T12:50:00

- [x] **p2.4**: 依存ファイル存在確認
  - validations:
    - technical: "EXECUTED"
    - consistency: "ISSUE - 欠損ファイル発見"
    - completeness: "PASS - 全依存先を確認"
  - result:
    - missing: ["failure-logger.sh", "contract.sh"]
    - existing: ["state-schema.sh"]
  - validated: 2026-01-03T12:50:00

**issues_found_in_p2**:
  - file: "failure-logger.sh"
    severity: medium
    problem: "存在しない。playbook-guard.sh:107,138,171 が参照"
  - file: "contract.sh"
    severity: medium
    problem: "存在しない。bash-check.sh:16,34,38 が参照"
  - file: "playbook-guard.sh"
    severity: high
    problem: "単体テストでタイムアウト"

**status**: done

---

### p3: codex 反証評価

**goal**: codex に「問題を探す」評価を委譲

#### subtasks

- [x] **p3.1**: Hook 反証評価
  - validations:
    - technical: "PASS - codex-delegate 完了"
    - consistency: "PASS - 行番号付き問題リスト"
    - completeness: "PASS - 7 Hook 全評価"
  - result:
    - high_severity: 4
      - "prompt.sh:50-53 - grep -c 算術エラー"
      - "prompt.sh:45 - awk パターンマッチ失敗"
      - "session-start.sh - settings.json 未登録、重複の可能性"
      - "generate-repository-map.sh:85 - cleanup.sh からの参照パス不正"
    - medium_severity: 5
    - recommendations:
      - fix: ["prompt.sh", "post-tool.sh", "subagent-stop.sh"]
      - review: ["session-start.sh", "generate-repository-map.sh"]
      - keep: ["pre-tool.sh", "session.sh"]
  - validated: 2026-01-03T12:55:00

- [x] **p3.2**: Guard 反証評価（14ファイル）
  - validations:
    - technical: "PASS - codex-delegate 完了"
    - consistency: "PASS - 行番号付き問題リスト"
    - completeness: "PASS - 14 Guard 全評価"
  - result:
    - high_severity: 6
      - "bash-check.sh - REPO_ROOT パス計算不正、contract.sh 常に失敗"
      - "protected-edit.sh - 同上、デッドコード"
      - "depends-check.sh - exit 0 固定、ガード機能なし"
      - "scope-guard.sh - デフォルト警告のみ、保護無効"
      - "coherence.sh - 相対パス source、cwd 依存で壊れやすい"
      - "pending-guard.sh - jq 不在で exit 0、Fail-closed 違反"
    - medium_severity: 10
    - recommendations:
      - fix: ["bash-check.sh", "protected-edit.sh", "playbook-guard.sh",
              "executor-guard.sh", "critic-guard.sh", "coherence.sh", "pending-guard.sh"]
      - review: ["depends-check.sh", "scope-guard.sh", "subtask-guard.sh", "phase-status-guard.sh"]
      - keep: ["main-branch.sh", "role-resolver.sh"]
  - validated: 2026-01-03T13:00:00

- [x] **p3.3**: SKILL.md 反証評価
  - validations:
    - technical: "PASS - codex-delegate 完了"
    - consistency: "PASS - ファイル存在確認付き"
    - completeness: "PASS - 5 SKILL.md 全評価"
  - result:
    - high_severity: 1
      - "access-control/SKILL.md - lib/contract.sh が存在しない"
    - medium_severity: 2
      - "playbook-gate/SKILL.md - archive.sh 名前不一致"
      - "golden-path/SKILL.md - 4qv-architecture.md 欠損"
    - recommendations:
      - fix: ["access-control/SKILL.md"]
      - review: ["playbook-gate/SKILL.md", "golden-path/SKILL.md"]
      - keep: ["reward-guard/SKILL.md", "session-manager/SKILL.md"]
  - validated: 2026-01-03T13:10:00

- [x] **p3.4**: SubAgent 反証評価
  - validations:
    - technical: "PASS - codex-delegate 完了"
    - consistency: "PASS - 参照先存在確認付き"
    - completeness: "PASS - 4 SubAgent 全評価"
  - result:
    - high_severity: 2
      - "pm.md - 900行超過剰複雑性、deprecated残存"
      - "critic.md - Write/Edit権限なしで書き込み不可"
    - medium_severity: 5
    - low_severity: 4
    - recommendations:
      - fix: ["pm.md", "critic.md"]
      - review: ["codex-delegate.md", "reviewer.md"]
  - validated: 2026-01-03T13:10:00

**status**: done

---

### p4: 結果統合

**goal**: 発見された問題を統合

#### subtasks

- [x] **p4.1**: 問題リスト作成
  - validations:
    - technical: "PASS - p2/p3 全結果統合"
    - consistency: "PASS - 行番号・ソース付き"
    - completeness: "PASS - 全カテゴリ網羅"
  - result:
    - total_issues: 39
    - high_severity: 13
    - medium_severity: 22
    - low_severity: 4
  - validated: 2026-01-03T13:15:00

- [x] **p4.2**: 未確定リスト作成
  - validations:
    - technical: "PASS - undetermined 抽出完了"
    - consistency: "PASS - 理由付き"
    - completeness: "PASS"
  - result:
    - total_undetermined: 3
    - items: ["executor-guard.sh", "subtask-guard.sh", "phase-status-guard.sh"]
    - reason: "単体実行にはモック環境が必要"
  - validated: 2026-01-03T13:15:00

- [x] **p4.3**: 推奨集計
  - validations:
    - technical: "PASS - 全推奨集計"
    - consistency: "PASS - 重複除去済"
    - completeness: "PASS"
  - result:
    - keep: 6
    - fix: 13
    - review: 10
    - remove: 0
  - validated: 2026-01-03T13:15:00

**status**: done

---

### p5: SKILL_INDEX_v2.md 作成

**goal**: 根拠付きインデックス作成

#### subtasks

- [x] **p5.1**: ファイル作成
  - validations:
    - technical: "PASS - ファイル作成完了"
    - consistency: "PASS - 全セクション含む"
    - completeness: "PASS - p1-p4 全結果反映"
  - result:
    - file: ".claude/SKILL_INDEX_v2.md"
    - sections: 7
    - lines: 250+
  - validated: 2026-01-03T13:20:00

**status**: done

---

## anti_fraud_protocol

```yaml
禁止:
  - claudecode による自己採点
  - 根拠なき「keep」判定
  - 未確定の無理な埋め

必須:
  - 各判定に行番号・コマンド出力
  - codex による独立評価
  - 反証モード（問題を探す）
  - undetermined は正直に残す
```
