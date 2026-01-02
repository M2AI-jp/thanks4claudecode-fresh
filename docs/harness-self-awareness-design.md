# Harness Self-Awareness Design

> **Claude Code が自分自身を掌握するための設計ドキュメント**
>
> 作成日: 2026-01-02
> 更新日: 2026-01-03
> ステータス: v2 実装完了

---

## 背景

### 問題提起（ユーザープロンプト）

```
Claude CodeのHook・Subagents・SkillsがClaudeの挙動に及ぼす影響を数値化して、
コンテキストウィンドウの圧迫度合いに準ずる処理能力を数値化して、
CCが自律するハーネス破綻の許容値を概算して、収まるよう調整できないかな？
他にもっと良い数学的なアプローチがあったら教えて欲しい
（数学以外の定量を扱う学問領域でも可能）。
言語以外での統制が必要と感じてる
```

### 核心的な問い

- 「Claude Codeに自分のキャパを知ってほしい」
- 「自動でメンテナンスされてほしい」
- 「いちいちユーザープロンプトで言わなくても」

---

## Claude Code の致命的欠陥

### 1. 自己観測能力がない

```yaml
Claude Code が知らないこと:
  - この会話で何トークン消費したか
  - コンテキストの何%を使ったか
  - 破綻まであと何トークンか
  - いま処理能力が劣化しているかどうか
```

### 2. コンテキストの欠落（最も致命的）

```yaml
Claude Code の現状:
  - 10個のSubAgent定義がある → 全て読んでいない
  - 6個のHookスクリプトがある → 全て検証していない
  - 20以上のSkillがある → 連携を把握していない
  - ARCHITECTURE.mdに書いてある → でも実装と一致するか不明

結果:
  - 「何が完成しているか」分からない
  - 「何が壊れているか」分からない
  - 「何を呼んだら何が起きるか」確信がない
  - リポジトリ全体を掌握できていない
```

**これは「トークン消費」よりも深刻な問題。**

Claude は今、「自分の体の一部」を知らない状態で動いている。

### 3. 自己メンテナンス能力がない

- ユーザーが言わないとドキュメントを更新しない
- 整合性チェックを自動実行しない
- health.sh を自動呼び出ししない（ARCHITECTURE.md Section 14 で既知）

### 4. フィードバックループが閉じていない

- 観測 → 判断 → 調整 のループが存在しない
- 「お願い」で制御しようとしている
- 数値ベースの制御がない

---

## 必要な構造の変化

### 現在の構造

```
ユーザープロンプト
    │
    ▼
playbook（単発タスク）
    ├─→ phase 1
    ├─→ phase 2
    └─→ phase N

問題:
  - playbookを跨ぐ視点がない
  - リポジトリ全体の状態を追跡しない
```

### 必要な構造

```
上位計画（project.md）
    │
    ├─→ リポジトリ全体の状態マップ
    │     ├─→ 完成（検証済み）
    │     ├─→ 未完成（WIP）
    │     ├─→ 壊れている（要修正）
    │     └─→ 不明（要調査）
    │
    ├─→ playbook 1（タスク1）
    ├─→ playbook 2（タスク2）
    └─→ playbook N

Claudeは常にこの全体像を掌握
```

---

## 以前の「project」との違い

| 当時 | 今 |
|------|-----|
| playbookの仕様が不安定 | V16で安定 |
| 検証フレームワークなし | critic/reviewer が動作 |
| 状態管理が曖昧 | state.md SSoT が確立 |
| Hook/Skill/SubAgentが未整備 | チェーンが動いている |
| 「外部化」の基盤がない | ファイルベースの永続化が可能 |

**今なら「外部化して実装できるフェーズ」**

---

## 数値化モデル

### Codex提案: 有効コンテキストモデル

```
C_eff = W - O_sys - O_dyn

W: コンテキスト上限（例: 200k tokens）
O_sys: 固定オーバーヘッド（Hook/Skills/ポリシー）
O_dyn: 動的オーバーヘッド（会話履歴、SubAgent合流）

P = I_task / C_eff
P > 1 → タスクがコンテキストに入りきらない → 破綻確定
```

### 破綻許容値モデル

```
Pr(success) = sigmoid(α + βP + γX)

P* = Pr(success) = 0.5 の点を破綻許容値として定義（CI付き）

目的変数:
  - 成功率
  - 到達率
  - 平均ターン
  - リトライ率
  - コスト
  - ループ発生率

説明変数:
  - P（処理負荷比）
  - フック数
  - スキル数
  - サブエージェント数
  - ツール呼び出し率
  - メモリ投入量
```

### 学問領域候補

| 領域 | 適用可能性 | 具体的アプローチ |
|------|------------|-----------------|
| **情報理論** | high | エントロピー・相互情報量でコンテキストの「有効情報密度」を測定 |
| **制御理論** | high | フィードバックループ（critic → 修正 → 再検証）の安定性解析 |
| **信頼性工学** | high | MTBF（平均故障間隔）、FMEA（故障モード影響解析）でハーネス破綻を分析 |
| **待ち行列理論** | medium | タスク到着率 vs 処理率で「詰まり」を予測（ρ=λ/μ） |
| **経済学（限界効用）** | medium | 追加 Hook/Skill の限界効用逓減をモデル化 |
| **実験計画法（DOE）** | medium | Hook/Skills/Agentsの因子設計で影響を分離 |

---

## 具体的な設計案

### project.md の構造

```yaml
ファイル: plan/project.md

内容:
  1. repository_health:
       verified: []        # 検証済みコンポーネント
       wip: []             # 作業中
       broken: []          # 壊れている（要修正）
       unknown: []         # 未調査

  2. dependency_graph:
       hooks:
         pre-tool.sh:
           calls: [playbook-guard.sh, subtask-guard.sh, ...]
           depends_on: [state.md, playbook-*.md]
       skills: ...
       subagents: ...

  3. context_budget:
       total_limit: 200000
       baseline_overhead: 15000  # Hook/Skill/基本ファイル
       current_session: null     # セッション中に計測
       threshold_warn: 0.8
       threshold_block: 0.95

  4. active_playbooks:
       current: {path}
       queue: []           # 待機中のタスク
       completed: []       # 完了（アーカイブ）

更新トリガー:
  - SessionStart: 読み込み + ヘルスチェック
  - playbook完了: 状態更新
  - 定期（手動または自動）: 全体検証
```

---

## 現状調査結果（2026-01-02）

### Hooks (7個)

| ファイル | 状態 | 登録 |
|----------|------|------|
| pre-tool.sh | OK | PreToolUse |
| post-tool.sh | OK | PostToolUse |
| session.sh | OK | SessionStart |
| session-start.sh | OK | SessionStart（v2新規） |
| prompt.sh | OK | UserPromptSubmit |
| subagent-stop.sh | OK | SubagentStop |
| generate-repository-map.sh | OK | 手動 |

### Skill Scripts (33個)

| カテゴリ | 数 | 状態 |
|----------|-----|------|
| access-control/guards | 3 | OK |
| coherence-checker/scripts | 1 | OK（v2新規） |
| git-workflow/handlers | 3 | OK |
| playbook-gate/guards + workflow | 6 | OK |
| post-loop | 2 | OK |
| quality-assurance/checkers | 3 | OK |
| reward-guard/guards | 5 | OK |
| session-manager/handlers | 4 | OK |
| test-runner/scripts | 6 | OK |

### SubAgents (10個)

| 名前 | 役割 | Write権限 |
|------|------|-----------|
| pm | orchestrator | あり |
| critic | 検証 | なし |
| reviewer | レビュー | なし |
| health-checker | 監視 | なし |
| prompt-analyzer | 分析 | なし |
| term-translator | 変換 | なし |
| executor-resolver | 判定 | なし |
| codex-delegate | Codex MCP | なし |
| coderabbit-delegate | CodeRabbit CLI | なし |
| setup-guide | 初期設定 | あり |

### 既知の問題

| 問題 | 状態 | 影響 |
|------|------|------|
| failure-logger.sh 不存在 | ガード済み | 低 |
| health.sh 自動呼び出し未実装 | 未対応 | 中 |
| doc-freshness-check.sh 未実装 | 未対応 | 中 |
| self-healing-system 未実装 | 未対応 | 中 |

---

## 実装ロードマップ（v2）

> v1 は「計測（体重計）」に偏り「調整（ダイエット）」が欠けていたため、全面的に再設計。

### Phase 1: 不要ファイル削除 ✓

- context-estimator（v1成果物）を削除
- 旧 session-start.sh を削除
- executor: claudecode

### Phase 2: prompt-analyzer 拡張 ✓

- 複数論点・指示の分解機能を追加
- multi_topic_detection セクションを実装
- executor: codex

### Phase 3: SessionStart 強化 ✓

- 全 Hook/Skill/SubAgent の状態を読み込む session-start.sh を新規作成
- セッション開始時にコンポーネント一覧を表示
- executor: codex

### Phase 4: 整合性自動チェック ✓

- coherence-checker Skill を実装
- ARCHITECTURE.md と実装の整合性を自動検出
- verified/inconsistent/missing の分類
- executor: codex

### Phase 5: 自動修正/提案 ✓

- severity 判定ロジック（low/medium/high）
- low: auto_fix（ドキュメント追記内容を生成）
- medium/high: suggestion（対応提案を出力）
- executor: codex

---

## 実装ロードマップ（v3）

> v2 で実現した「整合性チェック + 提案」を、SessionStart で自動実行し、auto_fix を実際に適用できるようにする。

### Phase 1: SessionStart 連携 ✓

- session-start.sh に coherence-checker 呼び出しを追加
- 問題があれば詳細警告（ファイル一覧含む）を表示
- executor: claudecode

### Phase 2: auto_fix 適用スクリプト ✓

- apply-fixes.sh を実装
- severity: low の問題に対して ARCHITECTURE.md への追記を生成
- ユーザー承認を必須とする（インタラクティブモード）
- バックアップ作成後に適用
- executor: claudecode

### v3 で実現したフィードバックループ

```
SessionStart
    │
    ├─→ session-start.sh
    │     ├─→ Component Status（Hooks/Skills/SubAgents 数）
    │     └─→ Coherence Check（整合性チェック）
    │           ├─→ verified: 整合OK
    │           ├─→ inconsistent: 要対応（実装なし）
    │           └─→ missing: 要対応（ドキュメントなし）
    │
    └─→ ユーザーに警告表示
          │
          └─→ apply-fixes.sh（任意）
                ├─→ 提案表示
                ├─→ ユーザー承認
                ├─→ バックアップ作成
                └─→ ARCHITECTURE.md 更新
```

### 使用方法

```bash
# SessionStart 時に自動実行（session-start.sh）
# 問題があれば警告が表示される

# 詳細レポートを確認
bash .claude/skills/coherence-checker/scripts/check.sh

# missing（ドキュメント未記載）を修正
bash .claude/skills/coherence-checker/scripts/apply-fixes.sh
```

---

## 関連ドキュメント

| ファイル | 役割 |
|----------|------|
| docs/ARCHITECTURE.md | 現在の構造定義 |
| state.md | 現在状態（SSOT） |
| plan/playbook-harness-self-awareness.md | 実装playbook |
| plan/archive/playbook-repository-audit.md | 直前の監査結果 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-03 | v3 実装完了: SessionStart 連携、apply-fixes.sh 実装 |
| 2026-01-03 | v2 実装完了: 全5フェーズ完了、coherence-checker 追加 |
| 2026-01-02 | v2 方向転換: context-estimator 削除、整合性チェック + 自動修正に変更 |
| 2026-01-02 | 初版作成（会話から抽出、playbook p1で実装） |
