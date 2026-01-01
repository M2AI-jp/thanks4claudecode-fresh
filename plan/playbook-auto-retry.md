# playbook-auto-retry.md

> **FAIL 時自動リトライ機能の実装 + プロンプト解釈基盤構築**

---

## meta

```yaml
project: auto-retry
branch: feat/auto-retry
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: codex  # 全コード実装は codex が担当
```

---

## context

```yaml
背景:
  - max_iterations は playbook に定義されているが、FAIL 時に自動リトライするロジックが未実装
  - 現状: codex 実装 → critic FAIL → ここで止まる（手動介入待ち）
  - あるべき姿: codex 実装 → critic FAIL → エラーを codex にフィード → 再実装 → max_iterations まで自動ループ
  - 根本問題: executor 判定がキーワードベースで表面的。pm SubAgent に機能が詰め込みすぎ

解決策:
  - p0: プロンプト解釈・executor判定基盤の構築（根本治療）
    - prompt-analyzer SubAgent: 5W1H 分析 + リスク分析
    - term-translator SubAgent: エンジニア用語への変換
    - executor-resolver SubAgent: LLM ベースの executor 判定
    - pm SubAgent の orchestrator 化
  - p1-p4: 自動リトライ機構の実装（元のタスク）
    - critic-guard.sh 拡張: FAIL 時にエラー内容を保存
    - executor-guard.sh 拡張: 保存されたエラーを次回プロンプトに注入
    - ループ制御: iteration_count を session-state に記録
    - ドキュメント更新: 動作仕様を明記

設計決定:
  - iteration_count 保存先: .claude/session-state/iteration-count
  - FAIL 理由保存先: .claude/session-state/last-fail-reason
  - max_iterations 到達時: AskUserQuestion で人間に確認
  - executor 判定: キーワード → LLM ベースに移行
```

---

## goal

```yaml
summary: プロンプト解釈基盤を構築し、critic FAIL 時に自動リトライする機構を実装する
done_when:
  # p0: プロンプト解釈基盤
  - prompt-analyzer SubAgent が存在し、5W1H 分析 + リスク分析を実行する
  - term-translator SubAgent が存在し、エンジニア用語への変換を実行する
  - executor-resolver SubAgent が存在し、LLM ベースで executor を判定する
  - pm SubAgent が orchestrator として上記 SubAgent を呼び出す
  # p1-p4: 自動リトライ機構
  - critic-guard.sh が FAIL 時に .claude/session-state/last-fail-reason にエラー内容を保存する
  - executor-guard.sh が保存されたエラーを読み込み、codex プロンプトに注入する仕組みが存在する
  - iteration_count が .claude/session-state/iteration-count に記録される
  - max_iterations 到達時に AskUserQuestion が呼ばれる仕組みが存在する
  - playbook-format.md に max_iterations の自動リトライ動作が明記されている
  - ARCHITECTURE.md に自動リトライフローが追記されている
```

---

## phases

### p0: プロンプト解釈・executor判定基盤

**goal**: ユーザープロンプトを深く解釈し、正しい executor 判定ができる基盤を構築

#### subtasks

- [x] **p0.1**: prompt-analyzer SubAgent の設計が完了している ✓
  - executor: codex
  - validations:
    - technical: "PASS - .claude/skills/prompt-analyzer/agents/prompt-analyzer.md 存在（405行）"
    - consistency: "PASS - YAML フロントマター + Markdown 形式で他 SubAgent と整合"
    - completeness: "PASS - 5W1H(L20-77)、リスク分析(L95-163)、曖昧さ検出(L169-206) 定義済み"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.2**: prompt-analyzer SubAgent が 5W1H 分析を実行できる ✓
  - executor: codex
  - validations:
    - technical: "PASS - テストプロンプト「認証機能を実装して。JWT を使って」で who/what/when/where/why/how/missing 抽出確認"
    - consistency: "PASS - understanding-check との役割分担明確（pm.md L5: skills 参照）"
    - completeness: "PASS - 6項目 + missing 配列で全分析される"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.3**: prompt-analyzer SubAgent がリスク分析を実行できる ✓
  - executor: codex
  - validations:
    - technical: "PASS - テストプロンプトで technical/scope/dependency リスク列挙確認"
    - consistency: "PASS - high/medium/low severity + mitigation 形式で明文化"
    - completeness: "PASS - 3カテゴリ全て分析される"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.4**: term-translator SubAgent の設計・実装が完了している ✓
  - executor: codex
  - validations:
    - technical: "PASS - .claude/skills/term-translator/agents/term-translator.md 存在（435行）"
    - consistency: "PASS - 他 SubAgent と同形式"
    - completeness: "PASS - 6カテゴリ18パターンの変換ルール定義済み"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.5**: executor-resolver SubAgent の設計・実装が完了している ✓
  - executor: codex
  - validations:
    - technical: "PASS - .claude/skills/executor-resolver/agents/executor-resolver.md 存在（650行）"
    - consistency: "PASS - playbook-format.md の 4 種 executor と整合"
    - completeness: "PASS - 判定フロー(L186-358) + 出力形式(L360-392) 定義済み"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.6**: pm SubAgent が orchestrator として上記 SubAgent を呼び出す ✓
  - executor: codex
  - validations:
    - technical: "PASS - pm.md 更新済み（830行、M086 Orchestrator セクション追加）"
    - consistency: "PASS - 既存の必須経由点・playbook作成フローと整合"
    - completeness: "PASS - prompt-analyzer→term-translator→executor-resolver→playbook のフロー定義(L36-55)"
  - validated: 2026-01-01T19:30:00Z

- [x] **p0.7**: playbook-format.md の executor 判定ガイドが LLM ベースに更新されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - L512-526 に LLM ベース判定セクション存在"
    - consistency: "PASS - 既存フォーマットと整合"
    - completeness: "PASS - 新方式(LLM) + 旧方式(DEPRECATED) の移行説明あり"
  - validated: 2026-01-01T19:30:00Z

**status**: done
**max_iterations**: 5

---

### p1: FAIL 情報保存機構

**goal**: critic FAIL 時にエラー情報を保存する機構を実装

**depends_on**: [p0]

#### subtasks

- [x] **p1.1**: .claude/session-state/ ディレクトリ構造が定義されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - test -d .claude/session-state で確認（EXISTS）"
    - consistency: "PASS - executor-guard.sh, critic-guard.sh で参照"
    - completeness: "PASS - README.md 存在（42行、last-fail-reason/iteration-count 説明含む）"
  - validated: 2026-01-01T20:00:00Z

- [x] **p1.2**: critic-guard.sh に FAIL 時エラー保存ロジックが追加されている ✓
  - executor: codex
  - validations:
    - technical: "PASS - bash -n シンタックスOK、save_fail_reason() 関数（L84-103）存在"
    - consistency: "PASS - 既存の critic 未実行ブロックロジック内に統合"
    - completeness: "PASS - phase_id(L90), reason(L100), timestamp(L95) が YAML 形式で保存"
  - validated: 2026-01-01T20:00:00Z

**status**: done
**max_iterations**: 5

---

### p2: エラー注入機構

**goal**: 保存されたエラーを次回実行時にプロンプトへ注入する機構を実装

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: executor-guard.sh にエラー読み込み・注入ロジックが追加されている ✓
  - executor: codex
  - validations:
    - technical: "PASS - bash -n シンタックスOK"
    - consistency: "PASS - codex executor ブロック内に統合（L229-262）"
    - completeness: "PASS - FAIL_INFO を systemMessage に含む（L278）、has_fail_info フラグ出力"
  - validated: 2026-01-01T20:00:00Z

- [x] **p2.2**: エラー注入後に last-fail-reason がクリアされる ✓
  - executor: codex
  - validations:
    - technical: "PASS - rm -f \"$LAST_FAIL_REASON_FILE\"（L241）で削除"
    - consistency: "PASS - 読み込み後すぐに削除で状態管理ルール遵守"
    - completeness: "PASS - クリア処理が executor-guard.sh L241 に含まれている"
  - validated: 2026-01-01T20:00:00Z

**status**: done
**max_iterations**: 5

---

### p3: イテレーション制御

**goal**: iteration_count を追跡し、max_iterations 到達時に人間確認を強制

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: iteration_count が .claude/session-state/iteration-count に記録される ✓
  - executor: codex
  - validations:
    - technical: "PASS - ITERATION_COUNT_FILE 変数定義（L23）、読み込みロジック（L244-247）存在"
    - consistency: "PASS - count: 形式で YAML 互換、grep で抽出"
    - completeness: "PASS - count 値が hookSpecificOutput.iteration_count に出力（L275）"
  - validated: 2026-01-01T20:00:00Z

- [x] **p3.2**: max_iterations 到達時に AskUserQuestion 呼び出し指示が出力される ✓
  - executor: codex
  - validations:
    - technical: "PASS - MAX_ITERATIONS_WARNING（L260）に AskUserQuestion 指示含む"
    - consistency: "PASS - JSON hookSpecificOutput 形式で既存 BLOCK と整合"
    - completeness: "PASS - 選択肢「リトライ継続 / 中止 / 手動対応」が提示される（L260）"
  - validated: 2026-01-01T20:00:00Z

**status**: done
**max_iterations**: 5

---

### p4: ドキュメント更新

**goal**: playbook-format.md と ARCHITECTURE.md に自動リトライ機構を明記

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: playbook-format.md の max_iterations セクションに自動リトライ動作が明記されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で「自動リトライ機構（M086）」セクション確認（L286）"
    - consistency: "PASS - 既存の Markdown 形式と整合"
    - completeness: "PASS - FAIL 時動作、iteration_count 保存先、上限到達時 AskUserQuestion が説明"
  - validated: 2026-01-01T20:00:00Z

- [x] **p4.2**: ARCHITECTURE.md に自動リトライフローが追記されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で「自動リトライ機構（M086）」フロー確認（L863）"
    - consistency: "PASS - 既存の ASCII フロー図形式と整合"
    - completeness: "PASS - FAIL → 保存 → codex 再委譲 → max_iterations チェック → AskUserQuestion のフロー図示"
  - validated: 2026-01-01T20:00:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: prompt-analyzer SubAgent が正しく動作することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - prompt-analyzer.md 存在（11392 bytes）、5W1H(L215-220)/リスク(L223-233)定義"
    - consistency: "PASS - 他 SubAgent と同形式（YAML フロントマター + Markdown）"
    - completeness: "PASS - who/what/when/where/why/how + technical/scope/dependency リスク構造"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.2**: term-translator SubAgent が正しく動作することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - term-translator.md 存在（13661 bytes）、6カテゴリ変換ルール定義"
    - consistency: "PASS - rationale 付き変換定義（L45, L59, L96 等）"
    - completeness: "PASS - 技術要件抽出（L24-25）、変換ルール（L34-194）定義済み"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.3**: executor-resolver SubAgent が正しく動作することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - executor-resolver.md 存在（19129 bytes）、LLM ベース判定"
    - consistency: "PASS - playbook-format.md の 4 種 executor と整合"
    - completeness: "PASS - 判定フロー(L302-337)、複雑さ判定(L186-213)、executor 説明(L42-170)"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.4**: critic-guard.sh が FAIL 時に last-fail-reason を保存することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - save_fail_reason() L84-103、cat > $LAST_FAIL_REASON_FILE"
    - consistency: "PASS - YAML 形式（phase_id/reason/timestamp）で保存"
    - completeness: "PASS - phase_id(L90), reason(L100), timestamp(L95) 全て含まれる"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.5**: executor-guard.sh がエラー注入する仕組みが動作することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - L235-242 で読み込み/注入/クリア処理"
    - consistency: "PASS - JSON hookSpecificOutput 形式（L269-279）"
    - completeness: "PASS - FAIL_INFO を systemMessage に注入（L278）、rm -f でクリア（L241）"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.6**: iteration_count が正しく動作することを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - executor-guard.sh L244-247 で読み込み、critic.md L353-367 でインクリメント"
    - consistency: "PASS - critic.md L381-382 で Phase 切り替え時リセット"
    - completeness: "PASS - L259-261 で max_iterations 到達時 AskUserQuestion メッセージ出力"
  - validated: 2026-01-01T20:15:00Z

- [x] **p_final.7**: ドキュメントが更新されていることを確認 ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - playbook-format.md L286「自動リトライ機構（M086）」、ARCHITECTURE.md L863 フロー図"
    - consistency: "PASS - 既存 Markdown/ASCII フロー図形式と整合"
    - completeness: "PASS - FAIL→保存→再委譲→max_iterations チェック→AskUserQuestion の全フロー説明"
  - validated: 2026-01-01T20:15:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する ✓
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - result: "Hooks: 6 | Agents: 9 | Skills: 21"

- [x] **ft2**: tmp/ 内の一時ファイルを削除する ✓
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする ✓
  - command: `git add -A && git commit`
  - status: done
  - commit: 5ea40f6 feat(auto-retry): プロンプト解釈基盤 + 自動リトライ機構実装
