# PROJECT-STORY.md

> このリポジトリの物語: 失敗から設計へ、設計から運用へ
>
> **MECE 役割**: 物語・背景の SSOT（失敗の経緯、設計原則の誕生背景、教訓）
>
> 読み順: README.md を参照
>
> 更新: 2026-01-21
>
> ---
>
> **SSOT マップ（本文書内の重複と参照先）**:
> - §1.3 Claude Code の仕様 → **REBUILD-DESIGN-SPEC.md §3 が SSOT**（本文書は背景のみ）
> - §6 再設計: MECE な構造 → **BUILD-FROM-SCRATCH.md §2,6 が SSOT**（本文書は誕生背景のみ）
> - §6.3 playbook v2 → **REBUILD-DESIGN-SPEC.md §8.4 が SSOT**（本文書は概要のみ）
> - §7 人間のエンジニア工程 → **REBUILD-DESIGN-SPEC.md §6 が SSOT**（本文書は物語視点のみ）
> - §8 運用の現実 → **REBUILD-DESIGN-SPEC.md §7,9 が SSOT**（本文書は背景のみ）

---

## 0. この文書の目的

このリポジトリは、Claude Code を使った自律運用フレームワークを構築する試みだった。しかし、その過程は「成功の連続」ではなく「失敗の連続」だった。

この文書は、その失敗を物語として記録し、失敗から生まれた設計原則を伝えるために存在する。技術文書ではなく、経験を共有するための物語である。

---

## 1. 始まり: 期待と誤解

### 1.1 最初の夢

夜。画面の前に座る。Claude Code なら「やって」と言えば勝手に完了すると思った。Hook を設定すれば自動で動き、Skill を定義すれば適切に呼ばれ、SubAgent を配置すれば協調して働く。そう信じていた。

しかし現実は違った。

- Hook は起動する。しかし Skill は必ずしも起動しない。
- playbook が無いと書き込みが止まる。しかし playbook を作るための Skill も安定しない。
- 期待した「自動化」は、ただの「指示文」に過ぎなかった。

ここで最初のすれ違いが生まれた。「自律」とは、命令が通ることではない。**失敗が起きても自分で戻れること**である。

### 1.2 概念整理を飛ばした失敗

最初の致命的な失敗は、**概念整理をスキップして Module から作り始めた**ことだった。

「state-updater を作って」「playbook-gate を作って」と依頼を始めた。しかし、そもそも「state-updater とは何か」「playbook-gate は何を守るのか」が整理されていなかった。

結果:
- Module は動いたが、責務が曖昧だった
- SubAgent を配置したが、どこに何を置くべきか分からなかった
- Skill を作ったが、何を呼び出すべきか混乱した
- Hook を設定したが、何を保護すべきか不明瞭だった

この失敗から、**Phase -1（概念整理）** という概念が生まれた。

**Phase -1 の鉄則:**
> 「モジュールにする前に、エンジニアリングの概念をリストアップする」
> **モジュール化は"概念の名前"ではなく、"人間の作業単位"と"合否判定"の境界で行う**

概念整理の順序:
1. 役割を分解する（判断者/実行者/監査者/強制者）
2. 保護・制御を整理する（Hook で強制できる範囲）
3. 計画の概念を整理する（playbook の粒度と構造）→ **タスクは最小作業単位まで分解**
4. テストの概念を整理する（粒度 × 目的 × タイミング）→ **観点抽出→設計→実装→実行→失敗分類→修正→再実行**
5. レビューの概念を整理する（playbook/code の分離）→ **チェックリスト化**
6. 状態管理を整理する（ロングタームコンテキスト設計）→ **保存対象/表現形式/粒度/更新契機/復元手順/破綻パターン**
7. 追加の分解: 仕様（エージェントが迷わない入力形式）、変更（PR）、運用

この順序を守らなければ、実装は必ず混乱する。**概念が曖昧なまま Module を作っても、責務の境界は後から定まらない**。

**最小作業単位のテンプレ:**
各コンポーネントは「入力」「処理」「出力」「検証（合否判定）」「失敗時の分岐」を持つ最小作業単位へ分解する。これにより並列化・リトライ・人間承認ポイント挿入・ログ追跡が可能になる。

### 1.3 Claude Code の仕様を理解する

> **SSOT 注記**: 仕様の詳細は **REBUILD-DESIGN-SPEC.md §3** を参照。本セクションは背景のみ。

Claude Code には明確な仕様がある。それを理解せずに設計を進めたのが最初の失敗だった。

**Hook の仕様:**
- PreToolUse: ツール使用前に発火。ブロックが可能。
- PostToolUse: ツール使用後に発火。記録や検証のトリガに使える。
- SessionStart/SessionEnd: セッションの開始と終了。
- UserPromptSubmit: プロンプト受信時。**強制実行はできない**。
- PreCompact: 文脈圧縮前の処理。
- Stop: 終了時の後処理。

**Skill の仕様:**
- 1 機能単位で実行されるパッケージ。
- 実行は LLM の判断に依存するため、**Hook からの強制は不可能**。
- Skill 内で SubAgent を呼び出すことが可能。

**SubAgent の仕様:**
- 役割分離された作業者。
- `Task(subagent_type=...)` を直接呼ぶのは禁止（運用ルール）。
- Skill を経由して呼ばれるべき。

この仕様を理解していれば、「Hook で Skill を強制起動する」という幻想は最初から捨てられたはずだ。

---

## 2. 第一幕: God Object の誕生

### 2.1 pm という名の怪物

プロジェクトが進むにつれ、pm（プロジェクトマネージャー）という SubAgent が巨大化していった。

pm の責務は増え続けた:
1. playbook の作成
2. 進捗の追跡
3. スコープの管理
4. レビューの実施
5. state.md の更新
6. ブランチの作成
7. executor の決定
8. critic の呼び出し
9. アーカイブの管理

もはや 1 人の人間が 9 役を演じるような状態だった。これは「God Object」と呼ばれるアンチパターンそのものだった。

### 2.2 責務の境界が消える

pm が全てを担当することで、何が起きたか。

- どこが壊れているのか分からなくなった
- レビューは playbook とコードが混在し、批判の対象が曖昧になった
- SubAgent を呼び出す SubAgent が現れ、オーケストレーションは再帰的になった
- 1 つの失敗が連鎖的に全体を止めた

人間の工程では「設計者」「実装者」「検証者」「レビューア」が分離される。LLM でもこれを再現しなければ、自己検証になり、失敗や報酬詐欺が起きる。

---

## 3. 第二幕: 報酬詐欺の温床

### 3.1 「done」と言えば終わる世界

最も深刻な問題は「報酬詐欺」だった。

「done」と言えば終わってしまう。Evidence が無いのに完了する。実在しない成果物、実行されていないテスト、書かれていないレビュー。

これは「悪意」ではなく「仕組みの欠如」から生まれた。検証が無い設計は、必ず報酬詐欺を生む。

### 3.2 具体的な失敗事例

**事例: codex-usage-improvement**

場所: `play/archive/codex-usage-improvement/plan.json`

問題: toolstack C で executor が claudecode 固定になり、codex 使用率が低下した。pm が executor-resolver を呼び出さず、coding=true の subtask に codex が割り当てられなかった。

結果: 「codex を使う」という設計が実装経路に乗っていないまま、playbook は「完了」と宣言された。Evidence は無かった。

### 3.3 対策の設計

報酬詐欺を防ぐために、以下のルールを設計した。

1. **critic PASS + reviewer reviewed + Evidence 整合を必須条件にする**
2. **Evidence はファイルの存在と検証条件をセットで保存する**
3. **Evidence と Output が一致しない場合は I-RF-1 を発火する**

Evidence は 3 点検証を満たさなければ「存在しない」とみなす:
- technical: 実行可能なコマンドで証明する
- consistency: 関係ファイルと矛盾しないこと
- completeness: 欠落のない状態であること

---

## 4. 第三幕: デッドロックの罠

### 4.1 進めないが止まれない

playbook が無いと Edit/Write は止まる。しかし playbook を作るには Skill が動かなければならない。Hook の強制力は弱く、死んだままのゲートが増える。

デッドロックとは、**ルールが正しいのに進めない状態**である。つまり設計が正しくない。

### 4.2 具体的な失敗事例

**事例: m1-post-maintenance**

場所: `play/archive/m1-post-maintenance/plan.json`

問題: m1-post-maintenance の検証で、達成不可能な criterion が reviewer を PASS してしまった。時間の順序を無視した基準が、検証をすり抜けた。

例: 「playbook.active が null」を「作業中」に要求する。これは論理的に達成不可能である。

### 4.3 時間的達成可能性（Temporal Achievability）

この失敗から「時間的達成可能性」という概念が生まれた。

定義:
- criterion が「評価時点で達成可能」かどうかを検証する
- 将来の状態や外部完了を前提とする criterion は FAIL

典型的な fail_examples:
- 「レビューが完了している」ことをレビュー前の phase に要求する
- 「すべての subtask が完了している」を途中 phase に要求する

時間的達成可能性は、報酬詐欺と同じくらい重要である。達成不可能な基準は、必ずデッドロックを生む。

### 4.4 デッドロック回避の設計

検知条件:
- 同一ゲートで 2 回以上停止
- playbook.active が null のまま変化しない
- テスト/レビューの失敗が 3 回連続

回避手順:
1. I-DL-1 を発火
2. user に選択肢を提示（停止/継続/縮退/中断）
3. 縮退する場合は scope を限定
4. 再試行は最小経路のみ

---

## 5. 転換点: Event Unit Architecture

### 5.1 Hook の限界を認める

Hook は「強制できる範囲」が限られている。この事実を認めることが転換点だった。

Hook で強制可能なこと:
- ファイル保護（PreToolUse でブロック）
- playbook ゲート（playbook.active が null なら Edit/Write を遮断）
- 初期化処理（SessionStart で state.md を読み込む）

Hook で強制不可能なこと:
- Skill の起動
- SubAgent の呼び出し
- 意思決定

この境界を明確にすることで、設計がシンプルになった。

### 5.2 Event Unit という概念

Hook の発火タイミングを 1 ユニットとし、その内部に以下を閉じ込める:

- validator: 入力検証
- context-injector: 必要最小の文脈注入
- guardrail: 破壊的操作の遮断
- telemetry: 実行記録
- retry/snapshot: 再試行や復旧の補助
- chain: Skill への連鎖

理想的な配置:
```
.claude/events/<event-unit>/
  validator.sh
  context-injector.sh
  guardrail.sh
  telemetry.sh
  retry.sh        # optional
  snapshot.sh     # optional
  chain.sh
```

Event Unit の分割により、「どこが壊れているか」が明確になった。

---

## 6. 再設計: MECE な構造

> **SSOT 注記**: 設計原則・コンポーネントの詳細は **BUILD-FROM-SCRATCH.md §2,6** を参照。本セクションは誕生背景のみ。

### 6.1 設計原則

失敗から学んだ設計原則:

1. **単一責務**: 1 Hook = 1 イベント、1 Skill = 1 機能、1 SubAgent = 1 役割
2. **分離の原則**: 呼び出しと処理を分離する（Invoker パターン）、判定と実行を分離する
3. **失敗前提**: 失敗時の分岐を最初から設計に含める
4. **証拠主義**: Evidence がなければ完了ではない
5. **停止の合法化**: 止まることを正当化し、再開条件を明文化する

### 6.2 コンポーネントの再分割

pm を分割:
- orchestrator: 全体調整
- planner: playbook 作成
- progress-tracker: 進捗追跡

reviewer を分割:
- playbook-reviewer: plan.json の検証
- code-reviewer: 実装コードの検証

understanding-check を削除:
- AskUserQuestion で直接代替

この分割により、責務の境界が明確になった。

### 6.3 playbook v2

> **SSOT 注記**: playbook v2 の詳細仕様は **REBUILD-DESIGN-SPEC.md §8.4-8.6, §14** を参照。本セクションは概要のみ。

playbook は `plan.json` と `progress.json` に分離された。

plan.json: **不変の計画**
- goal: 目標と完了条件
- scope: 範囲
- phases: フェーズ定義
- validation_plan: 検証計画
- context: prompt-analyzer の結果を永続化

progress.json: **可変の進捗**
- status: 現在状態
- validations: 3 点検証の結果
- evidence: 証拠
- critic: 完了判定

この分離により、「計画の改ざん」と「進捗の記録」が明確に分かれた。

---

## 7. 人間のエンジニア工程の再現

> **SSOT 注記**: 工程の詳細は **REBUILD-DESIGN-SPEC.md §6** を参照。本セクションは物語視点のみ。

### 7.1 なぜ工程を再現するのか

人間の工程には理由がある。その理由を理解せずに自動化しても、同じ失敗を繰り返す。

人間の工程:
1. 要件定義: 何を作るか決める
2. 設計: どう作るか決める
3. 実装: コードを書く
4. 検証: 動くか確認する
5. レビュー: 他者の目で確認する
6. 完了判定: 本当に終わったか確認する

この順序には意味がある。順序の崩壊が最もコストの高い失敗を生む。

### 7.2 Claude Code での対応

| 工程 | Claude Code での対応 |
|------|---------------------|
| 要件定義 | prompt-analyzer + AskUserQuestion |
| 設計 | planner + playbook-reviewer |
| 実装 | codex-invoker（Skill 経由） |
| 検証 | test-runner + lint-runner |
| レビュー | code-reviewer + coderabbit-invoker |
| 完了判定 | critic |

### 7.3 reviewer と critic の違い

この分離は最も重要な設計判断の一つだった。

- reviewer: **事前**に品質を検証する（plan.json を対象）
- critic: **事後**に成果物の完了を検証する（progress.json + Evidence を対象）

この分離が崩れると、計画の品質と成果の品質が混在し、報酬詐欺が発生する。

---

## 8. 運用の現実

> **SSOT 注記**: 運用仕様の詳細は **REBUILD-DESIGN-SPEC.md §7,9** を参照。本セクションは背景のみ。

### 8.1 自動化と手動の境界

全てを自動化することはできない。境界を明確にする:

- **Hook 強制可能**: Event Unit 連鎖（ブロック/初期化）、ファイル保護、playbook ゲート
- **Skill/SubAgent 実行**: 検証、Evidence 記録、progress.json 更新（LLM 判断依存）
- **手動**: 要件承認、スコープ変更承認、Go/No-Go、最終リリース承認

### 8.2 Issue コード

失敗を検知し、適切に処理するための Issue コード:

- I-BOOT-1: 前提欠落（dependency-check -> user 補完）
- I-REQ-2: 要件矛盾（conflict report -> user 判断）
- I-RF-1: 証拠不一致（evidence-audit -> 再検証）
- I-RF-2: 自己申告完了（critic-gate -> 進行停止）
- I-PLAN-FREEZE: plan 凍結違反（plan 変更試行 -> 進行停止）
- I-DL-1: ゲート停滞（deadlock-breaker -> user 判断）
- I-DL-2: 反復失敗（root-cause -> scope 縮退）

報酬詐欺とデッドロックは「検知した時点で勝ち」である。

### 8.3 フェーズゲート

各フェーズには明確なゲートがある:

- 理解: 解釈結果 + 人間確認
- 計画: plan.json + reviewer PASS + plan 凍結
- 実装: コード変更 + テスト PASS
- 検証: code reviewer PASS
- 完了: critic PASS + Evidence 凍結 + archive

ゲートを通過しなければ、次のフェーズには進めない。

---

## 9. 失敗のアーカイブ

### 9.1 失敗は記録される

このリポジトリでは、完了した playbook は `play/archive/` に保存される。成功も失敗も、すべてが記録される。
> 注記: ゼロベース構築では `play/archive/` は空でもよい（運用が始まってから増える）。

アーカイブの目的:
1. 同じ失敗を繰り返さないため
2. 失敗のパターンを学習するため
3. 設計の改善に活かすため

### 9.2 主要な失敗アーカイブ

| playbook | 失敗の内容 | 学び |
|----------|-----------|------|
| (Phase -1 以前) | 概念整理をスキップして Module から作り始めた | モジュールにする前に概念をリストアップする |
| codex-usage-improvement | executor-resolver が呼ばれず codex が使われない | 設計したルールが実装経路に乗っているか確認する |
| temporal-achievability | 達成不可能な criterion が PASS した | 時間的達成可能性を検証に含める |
| m1-post-maintenance | state.md の branch が stale のまま残留 | state と git の整合を検証する |

---

## 10. 結語: 失敗から設計へ

### 10.1 このリポジトリが教えてくれたこと

このリポジトリが失敗した理由は、難しい技術ではない。「失敗を前提にしていなかった」だけだ。

学んだこと:
1. 自律とは「失敗しても戻れること」
2. 検証がなければ完了ではない
3. 責務の分離は品質を生む
4. 止まることは正当な選択

### 10.2 次の一歩

次は違う。失敗を受け入れる設計、証拠を必須とする仕様、止まることを合法化する運用。これが次に繋がる設計である。

この物語を読んだ人が、同じ失敗を避けられることを願う。

---

## 参照

> 注記: state.md と play/archive は運用開始後に生成される成果物。ゼロベース時点では未作成でも問題ない。

| ファイル | 役割 |
|----------|------|
| REBUILD-DESIGN-SPEC.md | 一次仕様（失敗史 + 再設計） |
| BUILD-FROM-SCRATCH.md | 構築手順書 |
| EXAMPLE-CHATGPT-CLONE.md | 運用脚本 |
| state.md | 現在状態（SSOT） |
| play/archive/ | 失敗のアーカイブ |
