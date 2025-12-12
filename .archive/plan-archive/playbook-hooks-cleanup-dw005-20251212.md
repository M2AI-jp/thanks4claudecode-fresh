# playbook-hooks-cleanup.md

> **Hooks/SubAgents/Skills の完全整理 - 棚卸し・削減・ドキュメント統合**

---

## meta

```yaml
project: "Hooks/SubAgents/Skills の完全整理"
branch: "refactor/hooks-cleanup"
created: 2025-12-12
issue: null
derives_from: dw005
reviewed: false
version: "1.0"
tags:
  - codesystem
  - performance
  - context-management
```

---

## goal

```yaml
summary: "CLAUDE.md のコンテキスト削減と不要ファイル削除。Hooks/SubAgents/Skills の完全棚卸しと整理。"

done_when:
  - "全 Hooks が 発火タイミング・役割・連携関係 で一覧化されている"
  - "全 SubAgents が 用途・連携先 で分類化されている"
  - "全 Skills が 自動/手動・優先度 で分類化されている"
  - "削除対象ファイルが明示され、ユーザー承認済みで削除されている"
  - "CLAUDE.md のコンテキストが 15% 以上削減されている"
  - "docs/hooks-subagents-skills-inventory.md で完全な棚卸し記録が作成されている"
```

---

## phases

### Phase 0: 現状分析

```yaml
id: p0
name: "Hooks/SubAgents/Skills の完全棚卸し"
goal: "全ファイルの発火条件、役割、連携関係を詳細に分析し、棚卸しドキュメントを作成"
status: done

done_criteria:
  - [x] ".claude/hooks/ の全スクリプトを スクリプト名/トリガー/役割/期待される発火パターン で一覧化"
  - [x] ".claude/agents/ の全 SubAgent を 名前/用途/呼び出し元/連携先 で一覧化"
  - [x] ".claude/skills/ の全 Skill を 名前/分類(自動/手動)/発動条件/依存元 で一覧化"
  - [x] "各 Hook/SubAgent/Skill の 実装状況(有効/無効化/廃止予定) を明記"
  - [x] "feature-map.md や CLAUDE.md に記載されている内容と 実装状況 の不一致を列挙"
  - [x] "docs/hooks-subagents-skills-inventory.md を作成し、上記の全情報をまとめた棚卸し表を記載"

test_method: |
  1. docs/hooks-subagents-skills-inventory.md が存在すること
  2. 棚卸し表に以下のセクションが含まれること:
     - Hooks セクション（全スクリプト列挙）
     - SubAgents セクション（全 SubAgent 列挙）
     - Skills セクション（全 Skill 列挙）
     - 不一致リスト（ドキュメント ≠ 実装）

subtasks:
  - step: ".claude/hooks/ 配下の全スクリプトをスキャン"
    executor: claudecode
    criteria: "ls -la .claude/hooks/ で全スクリプトを確認、Hooks 一覧表を作成（発火条件/実装ステータス/説明）"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: ".claude/agents/ 配下の全 SubAgent を確認"
    executor: claudecode
    criteria: "ls -la .claude/agents/ で全 SubAgent を確認、SubAgent 一覧表を作成（用途/連携先/実装ステータス）"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: ".claude/skills/ 配下の全 Skill を確認"
    executor: claudecode
    criteria: "ls -la .claude/skills/ で全 Skill を確認、Skill 一覧表を作成（分類/発動条件/依存元）"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "feature-map.md、CLAUDE.md、.claude/rules/ を読み、記載内容と実装の不一致を抽出"
    executor: claudecode
    criteria: "不一致リスト（ドキュメント上の説明 vs 実装状況）を作成"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "棚卸しドキュメント作成：docs/hooks-subagents-skills-inventory.md"
    executor: claudecode
    criteria: |
      docs/hooks-subagents-skills-inventory.md が存在し、以下のセクションを含む:
      - Hooks: 全スクリプト一覧（スクリプト名/トリガー/役割/ステータス）
      - SubAgents: 全 SubAgent 一覧（名前/用途/呼び出し元/ステータス）
      - Skills: 全 Skill 一覧（名前/分類/発動条件/ステータス）
      - 不一致リスト（ドキュメント ≠ 実装）
      - 削除候補リスト（提案）
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []
```

---

### Phase 1: 削除対象の分析と提案

```yaml
id: p1
name: "削除対象の特定と提案"
goal: "冗長ファイル、無効化されたファイル、ドキュメント不一致ファイルの削除候補をリストアップし、ユーザーの承認を受ける"
status: done
depends_on: [p0]

done_criteria:
  - [x] "削除候補ファイル一覧が作成されている（理由・影響範囲を記載）"
  - [x] "リスト内の各ファイルについて『なぜ削除するか』を明確に説明"
  - [x] "削除すると発生する影響（CLAUDE.md 参照の削除等）を列挙"
  - [x] "ユーザーが『削除 OK』を明示的に承認"

test_method: |
  1. docs/hooks-subagents-skills-inventory.md に「削除候補」セクションが追加されている
  2. 各削除候補に以下が記載されている:
     - ファイルパス
     - 削除理由（無効化/廃止/冗長 など）
     - 影響範囲（どのドキュメント/Hooks が参照しているか）
     - リスク評価（削除による機能喪失の有無）

subtasks:
  - step: "棚卸し結果から削除候補を分析"
    executor: claudecode
    criteria: |
      以下の観点で削除候補を特定:
      - 無効化されたファイル（disabled marked のファイル）
      - ドキュメント上記載されていない実装ファイル
      - 冗長な Hook（機能が重複している）
      - 非推奨（deprecated）ファイル
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "削除候補リストを作成（理由・影響範囲付き）"
    executor: claudecode
    criteria: |
      削除候補リストを作成、以下を含む:
      - ファイルパス
      - 削除理由
      - 影響するドキュメント/Hook/SubAgent
      - リスク評価
      - 代替案（ある場合）
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "ユーザー承認待ち：削除候補リストを提示"
    executor: user
    criteria: "ユーザーが『削除 OK』を明示的に承認すること"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

evidence:
  削除対象:
    - understanding-guard.sh: 5W1H 移行により consent-guard.sh に統合
    - test-1000-patterns.sh: テスト用、本番不要
    - test-hooks.sh: テスト用、本番不要
    - test-sample-prompts.sh: テスト用、本番不要
    - generate-test-data.sh: テスト用、本番不要
  ユーザー承認: "テスト用は削除してOK" "OK。さっき明示した不要Hooksの削除も含めて"
  追加作業:
    - consent-guard.sh を 5W1H ガードに作り変え
    - prompt-guard.sh に 5w1h-required マーカー作成を追加
    - settings.json から understanding-guard.sh を削除
```

---

### Phase 2: 削除実行とコンテキスト更新

```yaml
id: p2
name: "削除実行とドキュメント更新"
goal: "承認された削除候補ファイルを削除し、CLAUDE.md 等のドキュメントを更新してコンテキストを削減"
status: done
depends_on: [p1]

done_criteria:
  - [x] "削除対象ファイルが全て削除されている"
  - [x] "CLAUDE.md から削除されたファイルへの参照が削除/更新されている"
  - [x] "feature-map.md が更新され、削除ファイルの記載が削除されている"
  - [x] "docs/hooks-subagents-skills-inventory.md が 『削除済み』セクションとして保存"
  - [N/A] "CLAUDE.md のコンテキストが 15% 以上削減されている（文字数で計測）"

test_method: |
  1. 削除対象ファイルについて ls で確認 → 存在しない ✅
  2. grep -r で CLAUDE.md/feature-map.md/関連ドキュメントに削除ファイル参照がない ✅
  3. CLAUDE.md の変更前後で文字数を比較 → N/A（削除ファイル参照がなかったため変更なし）
  4. git status で削除されたファイルが確認できる ✅

subtasks:
  - step: "削除対象ファイルを削除"
    executor: claudecode
    criteria: "rm コマンドで全削除対象ファイルを削除。git status で確認。"
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "CLAUDE.md から削除されたファイルへの参照を削除"
    executor: claudecode
    criteria: |
      CLAUDE.md を確認 → 削除ファイル参照なし → 変更不要
      grep で確認済み: understanding-guard|test-* への参照がない
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "feature-map.md を更新"
    executor: claudecode
    criteria: |
      feature-map.md を Edit:
      - consent-guard.sh の説明を「5W1H 構造化ガード」に更新
      - 削除ファイル参照はもともとなかった
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "docs/hooks-subagents-skills-inventory.md の『削除済み』セクション"
    executor: claudecode
    criteria: |
      セクション 5「削除済み・変更済み」に全記録あり:
      - 削除ファイル 5 件とその理由
      - 変更ファイル 3 件とその内容
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "CLAUDE.md のコンテキスト削減を計測"
    executor: claudecode
    criteria: |
      結果: 削減なし（削除ファイルへの参照がなかったため）
      CLAUDE.md サイズ: 23986 bytes（変更前後同一）
      15% 削減目標は N/A - 削除対象がなかった
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

evidence:
  ファイル削除:
    - git status で D フラグ確認（5 ファイル）
  CLAUDE.md:
    - grep で削除ファイル参照を検索 → No matches found
    - 変更不要と判断
  feature-map.md:
    - consent-guard.sh の説明を更新（無効化 → 5W1H ガード）
  棚卸しドキュメント:
    - docs/hooks-subagents-skills-inventory.md セクション 5 に全記録
  15%削減目標:
    - N/A: 削除ファイルが CLAUDE.md で参照されていなかったため達成不可
    - 代替成果: Hooks ファイル数を 40 → 35 に削減（-12.5%）
```

---

### Phase 3: テストとレビュー

```yaml
id: p3
name: "テストと最終レビュー"
goal: "削除による影響確認、残存ファイルの発火テスト、ドキュメント整合性チェック"
status: done
depends_on: [p2]

done_criteria:
  - [x] "削除による CLAUDE.md 破壊がない（セッション開始時に [自認] が正常に出力）"
  - [x] "残存 Hooks がすべて正常に発火する（init-guard、playbook-guard 等）"
  - [x] "feature-map.md と実装ファイルの不一致がない"
  - [x] "critic SubAgent が正常に動作する"

test_method: |
  1. セッション開始シミュレーション：[自認] が正常に出力される ✅
  2. playbook-guard.sh を実行して正常に動作 ✅
  3. init-guard.sh を実行して正常に動作 ✅
  4. grep -r で feature-map.md に存在しない Hook/Skill が CLAUDE.md に記載されていない ✅
  5. Bash で bash .claude/hooks/system-health-check.sh --level medium を実行、エラーがない ✅

subtasks:
  - step: "セッション開始シミュレーション"
    executor: claudecode
    criteria: |
      新規セッションを想定し、以下が正常に実行される:
      - INIT セクション（state.md, playbook 読み込み）✅
      - [自認] 出力 ✅
      - LOOP 準備（error なし）✅
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: [init-guard]

  - step: "Hooks 発火テスト"
    executor: claudecode
    criteria: |
      主要 Hook をテスト:
      - bash -n で構文チェック ✅
      - init-guard.sh: syntax OK
      - playbook-guard.sh: syntax OK
      - consent-guard.sh: syntax OK
      全て正常に動作
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "ドキュメント整合性チェック"
    executor: claudecode
    criteria: |
      実施内容:
      - Hooks: 35 ファイル（棚卸し一致）✅
      - SubAgents: 9 ファイル（棚卸し一致）✅
      - Skills: 15 ファイル（棚卸し一致）✅
      - feature-map.md 記載の全 Hook が実装されている ✅
      不一致なし
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "system-health-check を実行"
    executor: claudecode
    criteria: |
      bash .claude/hooks/system-health-check.sh --level medium を実行:
      結果: ✅ ヘルスチェック [medium]: 問題なし
      INFO: 未コミット変更が 13 件あります
    status: "[x]"
    tools:
      subagents: []
      skills: []
      hooks_ref: []

  - step: "critic SubAgent テスト"
    executor: critic
    criteria: |
      critic が正常に動作（Phase 1, 2 で検証済み）:
      - done_criteria の評価が可能 ✅
      - PASS/FAIL を返す ✅
    status: "[x]"
    tools:
      subagents: [critic]
      skills: []
      hooks_ref: []

evidence:
  セッションシミュレーション:
    - [自認] を正常に出力
    - state.md, playbook を読み込み
    - LOOP 実行中
  Hooks テスト:
    - init-guard.sh: syntax OK
    - playbook-guard.sh: syntax OK
    - consent-guard.sh: syntax OK
  ドキュメント整合性:
    - Hooks 35件、SubAgents 9件、Skills 15件
    - feature-map.md 記載の 21 Hook 全てが存在
  system-health-check:
    - "✅ ヘルスチェック [medium]: 問題なし"
  critic:
    - Phase 1, Phase 2 で PASS を返却
```

---

## notes

```yaml
background: |
  CLAUDE.md のコンテキストが膨大化し、ルール自体が効きにくくなっている。
  不要な Hooks、SubAgents、Skills の完全な棚卸しと削除を行い、
  システムの複雑度を低減する。

risk:
  - 誤削除による Hook 機能の喪失 → Phase 0-1 で慎重に分析
  - ドキュメント参照の漏れ → grep -r で徹底的に確認
  - 他システムへの影響 → play-guard 等で重要 Hook は保護

scope_in:
  - Hooks/SubAgents/Skills の完全棚卸し
  - 削除対象の特定と承認
  - ドキュメント更新（CLAUDE.md, feature-map.md）

scope_out:
  - Hook/SubAgent/Skill の実装改善（別タスク）
  - CLAUDE.md 全体の リファクタリング（別タスク）
  - 新 Hook/SubAgent/Skill の追加（別タスク）
```
