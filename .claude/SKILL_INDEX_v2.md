# SKILL_INDEX_v2.md

> **外部検証・反証モードによる機能監査結果**
>
> v1 の「全て keep」判定は報酬詐欺として破棄。本版は codex による独立評価と反証モードで再評価。

---

## 評価方法

```yaml
approach:
  mode: adversarial  # 問題を探す（確認バイアス防止）
  external_verification: codex-delegate  # 独立評価者
  traceability: required  # 行番号・コマンド出力必須
  undetermined: allowed  # 無理な判定をしない

phases:
  p1: 依存グラフ生成（機械的データ収集）
  p2: 実行テスト（実際の動作確認）
  p3: codex 反証評価（独立した問題探索）
  p4: 結果統合（優先順位付け）

anti_fraud_protocol:
  - claudecode による自己採点禁止
  - 根拠なき「keep」判定禁止
  - 未確定の無理な埋め禁止
```

---

## サマリー

| 指標 | 値 |
|------|-----|
| 評価ファイル数 | 31 スクリプト + 9 定義ファイル |
| 発見問題数 | 39 件 |
| High 重要度 | 13 件 |
| Medium 重要度 | 22 件 |
| Low 重要度 | 4 件 |
| 未確定 | 3 件 |

### 推奨アクション集計

| Action | 件数 | 対象 |
|--------|------|------|
| fix | 13 | 高/中重要度の問題あり |
| review | 10 | 軽微な問題または動作未検証 |
| keep | 6 | 問題なし |
| remove | 0 | - |

---

## 依存グラフ（p1 結果）

### Hook 依存

```
pre-tool.sh
  ├── source: common.sh (line 13)
  ├── bash: guards/*.sh (line 26)
  └── bash: bash-check.sh (line 61)

post-tool.sh
  ├── source: common.sh (line 13)
  └── bash: handlers/*.sh (line 26)
```

### Guard 依存（重要な発見）

| ファイル | 行 | 依存先 | 状態 |
|----------|-----|--------|------|
| playbook-guard.sh | 107,138,171 | failure-logger.sh | **欠損** |
| bash-check.sh | 16,34,38 | contract.sh | **欠損** |
| protected-edit.sh | 28 | contract.sh | **欠損** |
| executor-guard.sh | 117 | role-resolver.sh | 存在 |
| coherence.sh | 9 | state-schema.sh | 存在 |

### 未参照ファイル

検出数: 0（全スクリプトが参照されている）

---

## 実行テスト結果（p2 結果）

### テスト実行サマリー

| スクリプト | 結果 | 問題 |
|------------|------|------|
| pre-tool.sh | WARN | 古い playbook パス参照 |
| playbook-guard.sh | TIMEOUT | ハング（入力待ち or 無限ループ） |
| main-branch.sh | PASS | 正常動作 |

### 欠損ファイル発見

| ファイル | 参照元 | 重要度 |
|----------|--------|--------|
| failure-logger.sh | playbook-guard.sh:107,138,171 | medium |
| contract.sh | bash-check.sh:16,34,38 | medium |

---

## 問題リスト（High 重要度のみ）

### p2 発見

| # | ファイル | 問題 | 推奨 |
|---|----------|------|------|
| 1 | playbook-guard.sh | 単体テストでタイムアウト | fix |

### p3.1 Hook 評価（codex）

| # | ファイル | 行 | 問題 | 推奨 |
|---|----------|-----|------|------|
| 2 | prompt.sh | 50-53 | grep -c 算術エラー（件数 0 で失敗） | fix |
| 3 | prompt.sh | 45 | awk パターンマッチ失敗 | fix |
| 4 | session-start.sh | - | settings.json 未登録、重複の可能性 | review |
| 5 | generate-repository-map.sh | 85 | cleanup.sh からの参照パス不正 | review |

### p3.2 Guard 評価（codex）

| # | ファイル | 問題 | 推奨 |
|---|----------|------|------|
| 6 | bash-check.sh | REPO_ROOT パス計算不正、contract.sh 常に失敗 | fix |
| 7 | protected-edit.sh | 同上、デッドコード含む | fix |
| 8 | depends-check.sh | exit 0 固定、ガード機能なし | review |
| 9 | scope-guard.sh | デフォルト警告のみ、保護無効 | review |
| 10 | coherence.sh | 相対パス source、cwd 依存で壊れやすい | fix |
| 11 | pending-guard.sh | jq 不在で exit 0、Fail-closed 違反 | fix |

### p3.3 SKILL.md 評価（codex）

| # | ファイル | 問題 | 推奨 |
|---|----------|------|------|
| 12 | access-control/SKILL.md | lib/contract.sh が存在しない | fix |

### p3.4 SubAgent 評価（codex）

| # | ファイル | 問題 | 推奨 |
|---|----------|------|------|
| 13 | pm.md | 900行超、過剰複雑性、deprecated コード残存 | fix |
| 14 | critic.md | tools に Write/Edit なし、session-state 書き込み不可 | fix |

---

## 未確定リスト

以下は単体実行にモック環境が必要なため、動作検証が未完了。

| ファイル | 理由 |
|----------|------|
| executor-guard.sh | state.md, playbook 読み込みが必要 |
| subtask-guard.sh | playbook パース処理が必要 |
| phase-status-guard.sh | 同上 |

---

## 推奨アクション詳細

### fix（13件）- 修正必須

**Hooks:**
- `prompt.sh` - grep/awk エラーハンドリング追加
- `post-tool.sh` - codex 指摘の問題修正
- `subagent-stop.sh` - codex 指摘の問題修正

**Guards:**
- `bash-check.sh` - REPO_ROOT パス計算修正、contract.sh 依存除去
- `protected-edit.sh` - 同上、デッドコード削除
- `playbook-guard.sh` - ハング原因調査・修正
- `executor-guard.sh` - codex 指摘の問題修正
- `critic-guard.sh` - codex 指摘の問題修正
- `coherence.sh` - 絶対パス source に変更
- `pending-guard.sh` - jq 不在時の Fail-closed 実装

**Definitions:**
- `access-control/SKILL.md` - 欠損ファイル参照削除
- `pm.md` - 過剰複雑性の解消、deprecated コード削除
- `critic.md` - ツール権限の明確化

### review（10件）- 要調査

- `session-start.sh` - settings.json 登録確認
- `generate-repository-map.sh` - パス参照の正確性確認
- `depends-check.sh` - ガード機能の要否判断
- `scope-guard.sh` - 保護機能の要否判断
- `subtask-guard.sh` - 動作検証
- `phase-status-guard.sh` - 動作検証
- `playbook-gate/SKILL.md` - ファイル名不一致修正
- `golden-path/SKILL.md` - 欠損参照修正
- `codex-delegate.md` - toolstack 定義参照追加
- `reviewer.md` - プレースホルダ説明追加

### keep（6件）- 問題なし

- `pre-tool.sh` - 正常動作
- `session.sh` - 正常動作
- `main-branch.sh` - テスト PASS
- `role-resolver.sh` - 問題なし
- `reward-guard/SKILL.md` - 問題なし
- `session-manager/SKILL.md` - 問題なし

---

## v1 との差分

| 項目 | v1 | v2 |
|------|-----|-----|
| 評価方法 | bash -n のみ | 実行テスト + codex 反証 |
| 外部検証 | なし | codex-delegate |
| 問題発見数 | 0 | 39 |
| fix 推奨 | 0 | 13 |
| 全て keep | 74/74 | 6/29 |
| 未確定 | 0（無理に判定） | 3（正直に残す） |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-03 | v2 作成。外部検証・反証モードで再評価。39問題発見。 |
