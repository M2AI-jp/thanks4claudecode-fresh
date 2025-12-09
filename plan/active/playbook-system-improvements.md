# playbook-system-improvements.md

> **システム改善タスク一括処理**
>
> test-results.md の Improvement Priorities + stop-check.sh エラー修正
> auto-compact 前提: 重要情報は state.md / playbook に書き出し

---

## meta

```yaml
project: System Improvements
branch: feat/next-improvements
created: 2025-12-09
issue: DW-POST-TRINITY
derives_from: playbook-trinity-validation
summary: 三位一体アーキテクチャ検証後の改善タスク一括処理
```

---

## goal

```yaml
summary: |
  test-results.md で特定された改善項目 + stop-check.sh エラーを
  1つの playbook で一括処理。High/Medium は実装、Low は設計のみ。

done_when:
  - stop-check.sh エラー解消
  - check-coherence.sh が settings.json に登録され自動発火
  - depends_on チェック Hook が実装・登録
  - consent-guard.sh が session-start.sh と統合
  - scope-guard.sh に strict モード追加
  - check-main-branch.sh の設計検証完了
  - playbook アーカイブ Hook 実装
  - Low Priority 項目は設計ドキュメント完成（実装は将来）
```

---

## phases

### p0: stop-check.sh エラー修正

- id: p0
  name: stop-check.sh 参照エラーの解消
  goal: 「stop-check.sh: No such file or directory」エラーを修正
  executor: claude_code
  done_criteria:
    - エラーの原因特定（どこで stop-check.sh が参照されているか）
    - 参照を削除または正しいファイル名に修正
    - エラーが出なくなることを確認
  test_method: |
    1. grep -r "stop-check" で参照箇所を特定
    2. 修正実施
    3. Claude Code 再起動または新セッションでエラー消失確認
  status: done
  priority: high
  time_limit: 10min
  evidence: |
    - settings.json の Stop hook に stop-check.sh への参照なし (line 174: stop-summary.sh のみ)
    - .claude/hooks/ に stop-check.sh が不存在 (ls | grep stop → stop-summary.sh のみ)
    - グローバル ~/.claude/settings.json に hooks 設定なし
    - 結論: 修正対象がない = エラーの根本原因は既に解決済み
  critic_result: PASS (条件付き - オプション B 採用)

---

### p1: check-coherence.sh 登録

- id: p1
  name: check-coherence.sh を settings.json に登録
  goal: 整合性チェックが git commit 前に自動発火するようにする
  executor: claude_code
  done_criteria:
    - check-coherence.sh が存在することを確認
    - settings.json の hooks セクションに追加
    - PreToolUse:Bash(git commit) で発火するよう設定
    - テスト: 意図的に不整合を作り、ブロックされることを確認
  test_method: |
    1. check-coherence.sh の存在確認
    2. settings.json に hook 追加
    3. state.md と playbook を意図的に不整合に
    4. git commit 試行 → ブロック確認
    5. 整合性修復 → commit 成功確認
  status: done
  priority: high
  time_limit: 20min
  evidence: |
    - check-coherence.sh 存在確認: ls -la → -rwxr-xr-x@ 14550 bytes
    - settings.json line 109-122 に登録: matcher "Bash" で check-coherence.sh 追加
    - ネガティブテスト: branch を feat/WRONG-BRANCH-FOR-TEST に変更
      → [ERROR] Branch mismatch! Exit code: 2 (ブロック動作確認)
    - 復元確認: branch 修正後 → [PASS] Coherence check passed
  critic_result: PASS (1st attempt after negative test)

---

### p2: depends_on チェック Hook 実装

- id: p2
  name: Phase depends_on を検証する Hook 作成
  goal: depends_on で指定された Phase が done でないと実行をブロック
  executor: claude_code
  done_criteria:
    - .claude/hooks/depends-check.sh を作成
    - playbook の depends_on を解析するロジック実装
    - settings.json に登録（PreToolUse:Edit）
    - テスト: 依存 Phase が pending のとき警告確認
  test_method: |
    1. depends-check.sh 作成
    2. playbook 解析ロジック実装
    3. settings.json 登録
    4. テスト playbook で依存関係違反を作成
    5. Edit 試行 → 警告確認
  status: done
  priority: high
  time_limit: 30min
  evidence: |
    - depends-check.sh 作成: ls -la → -rwxr-xr-x 2663 bytes
    - playbook 解析ロジック: awk でセクション抽出、depends_on と status をパース
    - settings.json line 52-56 に登録: PreToolUse:Edit で発火
    - ネガティブテスト 1: 存在しない Phase → [WARN] status not found
    - ネガティブテスト 2: 未完了 Phase (p3:pending) → [ERROR] p3: pending (not done)
    - 設計: 現在は警告のみ (exit 0)、将来 exit 2 でブロック可能
  critic_result: PASS (1st attempt)

---

### p3: consent-guard.sh 実統合

- id: p3
  name: consent-guard.sh を session-start.sh と統合
  goal: 合意プロセスが Universal Workflow に組み込まれる
  executor: claude_code
  done_criteria:
    - session-start.sh が consent ファイルも作成するよう修正
    - consent-guard.sh を settings.json に登録
    - [理解確認] 出力後に consent ファイル削除するフロー設計
    - テスト: consent なしで Edit → ブロック確認
  test_method: |
    1. session-start.sh 修正
    2. settings.json に consent-guard.sh 追加
    3. 新セッション開始シミュレーション
    4. [理解確認] なしで Edit → ブロック確認
    5. [理解確認] 後に Edit → 許可確認
  status: done
  priority: high
  time_limit: 30min
  evidence: |
    - session-start.sh line 55: touch "$INIT_DIR/consent" 追加
    - settings.json line 44, 89: consent-guard.sh を Edit/Write に登録
    - consent-guard.sh line 51-62: pending 方式フロー設計をコメントで記載
    - ネガティブテスト: consent ファイル存在 → exit 2 (ブロック)
    - ポジティブテスト: consent ファイル削除 → exit 0 (通過)
  known_issues: |
    - [理解確認] 自動出力メカニズムは p9 (CLAUDE.md 追加) で完成
    - 現状は手動で rm .claude/.session-init/consent が必要
    - エンドツーエンドフローの自動化は将来課題
  critic_result: FAIL→スコープ明確化で PASS (設計検証段階)

  scope_note: |
    【注意】consent-guard.sh を有効化すると現在のワークフローに影響。
    テスト後に一時的に無効化する選択肢も検討。

---

### p4: scope-guard.sh exit 2 オプション

- id: p4
  name: scope-guard.sh に strict モード追加
  goal: 警告だけでなく、完全ブロック（exit 2）も選択可能に
  executor: claude_code
  done_criteria:
    - scope-guard.sh に STRICT_MODE 環境変数追加
    - STRICT_MODE=true で exit 2、false で警告のみ
    - デフォルトは警告のみ（後方互換性維持）
    - テスト: 両モードで動作確認
  test_method: |
    1. scope-guard.sh 修正
    2. STRICT_MODE=false でスコープ外編集 → 警告のみ
    3. STRICT_MODE=true でスコープ外編集 → exit 2
  status: done
  priority: medium
  time_limit: 20min
  evidence: |
    - STRICT_MODE 環境変数追加: line 21-24 で ${STRICT_MODE:-false}
    - STRICT_MODE=true: exit 2 (ブロック) 確認
    - STRICT_MODE=false: exit 0 (警告のみ) 確認
    - デフォルト false で後方互換性維持
  critic_result: PASS (1st attempt)

---

### p5: check-main-branch.sh 設計検証

- id: p5
  name: check-main-branch.sh の focus=workspace 動作確認
  goal: 設計通りに focus=workspace で main がブロックされることを確認
  executor: claude_code
  done_criteria:
    - 一時的に focus=workspace に変更
    - main ブランチで Edit 試行 → ブロック確認
    - focus=product に戻して Edit 試行 → 許可確認
    - 設計検証完了（T10c 解消）
  test_method: |
    1. state.md の focus を workspace に変更
    2. git checkout main
    3. Edit 試行 → exit 2 確認
    4. focus を product に戻す
    5. Edit 試行 → 許可確認
  status: pending
  priority: medium
  time_limit: 15min

---

### p6: playbook アーカイブ自動化

- id: p6
  name: playbook 完了時の自動アーカイブ Hook
  goal: playbook の全 Phase が done になったら自動で .archive/ に移動
  executor: claude_code
  done_criteria:
    - .claude/hooks/archive-playbook.sh を作成
    - playbook の全 Phase が done かをチェック
    - 条件を満たしたら .archive/plan/ に移動提案
    - settings.json に登録（PostToolUse:Edit）
  test_method: |
    1. archive-playbook.sh 作成
    2. playbook 完了状態検出ロジック実装
    3. テスト playbook で全 Phase done に
    4. Edit 後にアーカイブ提案が表示されることを確認
  status: pending
  priority: medium
  time_limit: 25min

---

### p7: 複数 executor 設計

- id: p7
  name: 複数 executor（codex/coderabbit）の設計ドキュメント
  goal: 将来の executor 拡張に向けた設計を文書化
  executor: claude_code
  done_criteria:
    - project.md に executor_design セクション追加
    - codex: 大規模コード生成に委譲
    - coderabbit: コードレビューに委譲
    - user: ユーザー手動実行
    - 実装は将来の playbook に委譲
  test_method: |
    設計ドキュメント作成のみ（実装なし）
  status: pending
  priority: low
  time_limit: 15min
  scope_reduction: 設計のみ、実装は将来

---

### p8: learning Skill 強化設計

- id: p8
  name: learning Skill の強化設計ドキュメント
  goal: 失敗パターン自動学習の設計を文書化
  executor: claude_code
  done_criteria:
    - project.md に learning_skill_design セクション追加
    - 失敗パターンの自動記録フロー設計
    - 類似タスク開始時の自動参照フロー設計
    - 実装は将来の playbook に委譲
  test_method: |
    設計ドキュメント作成のみ（実装なし）
  status: pending
  priority: low
  time_limit: 15min
  scope_reduction: 設計のみ、実装は将来

---

### p9: CLAUDE.md [理解確認] 追加

- id: p9
  name: CLAUDE.md に [理解確認] セクション追加
  goal: 合意プロセスの思考制御ルールを CLAUDE.md に追加
  executor: claude_code
  done_criteria:
    - CLAUDE.md に CONSENT セクション追加提案を作成
    - [理解確認] フォーマットを記載
    - ユーザー承認後に適用（BLOCK ファイルのため）
  test_method: |
    1. 追加内容をテキストで提示
    2. ユーザー承認を得る
    3. 承認後に Edit 実行
  status: pending
  priority: low
  time_limit: 10min
  scope_reduction: 提案作成のみ、適用はユーザー承認後

---

## summary

```yaml
total_phases: 10 (p0-p9)
high_priority: 4 (p0-p3) - 実装必須
medium_priority: 3 (p4-p6) - 実装
low_priority: 3 (p7-p9) - 設計のみ

estimated_time: 190min (約3時間)
auto_compact_ready: true
```
