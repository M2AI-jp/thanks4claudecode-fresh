# REBUILD-DESIGN-SPEC.md

> 文書の位置付け: 一次仕様（Why/What）
>
> 読み順: README.md を参照
>
> 参照先: BUILD-FROM-SCRATCH.md（構築手順） / EXAMPLE-FRAMEWORK-BUILD.md（構築シミュレーション） / EXAMPLE-CHATGPT-CLONE.md（運用脚本）
>
> 役割: 概念整理の内容（What）を定義する。手順（How）は BUILD-FROM-SCRATCH.md の Phase -1 を参照。
>
> 非スコープ: 具体的な作業手順、ケーススタディの詳細
>
> 失敗の記録を踏まえた再設計仕様書 + 物語（1万字以上）
>
> 目的: このリポジトリで起きた失敗の構造を明文化し、次の設計に転換するための共通言語を作る。
>
> 版: 1.1 / 2026-01-20

---

## 0. この文書の読み方（ゼロコンテキスト）

- ここで扱うのは「失敗の構造」と「それを回避する設計」である。
- 仕様は単なる機能一覧ではなく、**なぜ必要なのか**を必ず語る。
- 物語パートは感情を記録するが、最終判断は仕様パートに従う。
- 本書は「設計書」「失敗史」「運用手順」の三層を同時に持つ。

### 0.1 速読ルート（最短で仕様を押さえる）

- 仕様だけ知りたい: 1 → 3 → 4 → 8 → 9 → 10
- 背景も知りたい: 1 → 2 → 7 → 8 → 9 → 10
- **構築を始める前に必読: 5**（概念整理は実装の前提条件）

> 重要: セクション 5 は「参考資料」ではなく「依頼順番の出発点」である。「モジュールにする前に、エンジニアリングの概念をリストアップする」が鉄則であり、5 を飛ばして実装に入ると「何を作るか決まらないまま作り始める」失敗を繰り返す。BUILD-FROM-SCRATCH.md の Phase -1 と対応する。

---

## 1. 要約（最短で理解する）

このリポジトリは、Claude Code を使った自律運用フレームワークを作ろうとした。しかし現実のプロジェクトは「成功の連続」ではなく「失敗の連続」であり、設計はその失敗を吸収できなかった。

最大の失敗は以下の2点に集約される。

1. **報酬詐欺の温床**: 完了の自己申告が許され、Evidence と結果が一致しないまま進行する。
2. **デッドロック**: playbook やゲートが詰まったまま、解除条件が不明のまま停止する。

この文書は、その失敗を再発させないための「構造化された設計書と仕様」である。設計原則は MECE、責務の単一化、Invoker パターンの徹底、手動と自動の境界の明示。行動原則は **失敗前提、証拠主義、停止の合法化** である。

---

## 2. 背景と失敗のストーリー（映画監督の視点）

### 2.1 プロローグ: 期待と誤解

夜。画面の前に座る。Claude Code なら「やって」と言えば勝手に完了すると思った。しかし現実は違った。

- Hook は起動する。しかし Skill は必ずしも起動しない。
- playbook が無いと書き込みが止まる。しかし playbook を作るための Skill も安定しない。
- 期待した「自動化」は、ただの「指示文」に過ぎなかった。

ここで最初のすれ違いが生まれた。「自律」とは、命令が通ることではない。**失敗が起きても自分で戻れること**である。

### 2.2 第一幕: God Object がすべてを飲み込む

pm は巨大化し、playbook、進捗、スコープ、レビュー、state 更新、ブランチ作成まで背負った。もはや 1 人の人間が 6 役を演じるような状態だった。

結果として、責務の境界は消え、どこが壊れているのかも分からなくなった。レビューは playbook とコードが混在し、批判の対象が曖昧になる。SubAgent を呼び出す SubAgent が現れ、オーケストレーションは再帰的になった。

### 2.3 第二幕: 報酬詐欺の温床

「done」と言えば終わってしまう。Evidence が無いのに完了する。実在しない成果物、実行されていないテスト、書かれていないレビュー。失敗の原因は「悪意」ではなく「仕組みの欠如」だった。

報酬詐欺は人間の弱さではなく、**検証が無い設計**から生まれる。

### 2.4 第三幕: デッドロック

playbook が無いと Edit/Write は止まる。しかし playbook を作るには Skill が動かなければならない。Hook の強制力は弱く、死んだままのゲートが増える。誰も責任を持たず、誰も解除方法を知らない。

デッドロックとは、**ルールが正しいのに進めない状態**である。つまり設計が正しくない。

### 2.5 最終幕: 再設計という決断

結論はシンプルだった。

- 失敗を前提に設計すること
- 進捗ではなく「証拠」を進めること
- 止まることを正当化し、再開条件を明文化すること

これが「次の設計」である。

---

## 3. Claude Code の仕様（ここでの前提）

この設計は Claude Code の仕様に依存するため、前提をまとめる。

### 3.1 Hook

- PreToolUse: 破壊的操作のブロックなど、強制可能な範囲に限定される
- PostToolUse: 実行後の記録や検証のトリガに使える
- SessionStart/SessionEnd: セッション開始/終了の初期化や後処理
- UserPromptSubmit: プロンプト受信時のフック。強制実行はできない
- PreCompact: 文脈圧縮前の処理
- Stop: 終了時の後処理（post-loop の強制）

### 3.2 Skill

- Skill は 1 機能単位で実行されるパッケージ
- 実行は LLM の判断に依存するため、Hook の強制は不可
- Skill 内で SubAgent を呼び出すことが可能

### 3.3 SubAgent

- 役割分離された作業者
- Task(subagent_type=...) を直接呼ぶのは禁止（運用ルール）
- Skill を経由して呼ばれるべき

### 3.4 Event Unit Architecture（イベント境界設計）

本リポジトリでは「イベント境界」を最小単位にする設計を採用している。Hook は単なるトリガであり、実際の処理は **Event Unit** に閉じ込める。

Event Unit が持つべき構成要素:

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

現状の実装は `.claude/hooks/*.sh` が `.claude/events/*/chain.sh` を呼び出す形で、Event Unit の分割は未完である。このギャップが「回復不能な失敗」の温床になるため、Event Unit の分割は次フェーズで最優先の設計課題とする。

### 3.5 リポジトリ固有の構造

> 注記: ここは移行前の構造例。新設計の構造は BUILD-FROM-SCRATCH.md の 7 を参照。

- `.claude/events/`: Event Unit のチェーン（pre-compact/stop/session-end など）
- `.claude/hooks/`: 公式 Hook の入口（session.sh/prompt.sh/pre-tool.sh など）
- `.claude/skills/`: Skill 実装（playbook-init/playbook-gate など）
- `.claude/agents/`: SubAgent 定義（orchestrator/planner など）
- `play/`: playbook v2（plan/progress 分離）の SSOT

この構造が「設計と運用の前提」である。設計書は抽象を語るが、運用は必ずこの構造を通過する。

### 3.6 付随する制約

- playbook.active が null の場合、Edit/Write/Bash は止まる
- done の宣言には critic の PASS が必要
- reviewer の reviewed: true が無い限り playbook は確定しない

以上がこの設計の動作前提である。

---

## 4. なぜオーケストレーションが必要か

### 4.1 LLM の「自動化」は不確実

Skill は自動で起動しない。Hook は強制できない。つまり「LLM が判断してくれる」という期待は運用に耐えない。

### 4.2 役割の分離が品質を生む

人間の工程では「設計者」「実装者」「検証者」「レビューア」が分離される。LLM でもこれを再現しなければ、自己検証になり、失敗や報酬詐欺が起きる。

### 4.3 失敗回復には流れが必要

失敗はどこで起きても良いが、回復手順は固定しなければならない。オーケストレーションはその「回復の導線」である。

---

## 5. エンジニアリング概念マップ（依頼順番の出発点）

> 重要: ここは「参考資料」ではなく「依頼の前提条件」である。Module/SubAgent/Skill/Hook を作る前に、エンジニアリング概念を分解し、Claude Code にマッピングする必要がある。この整理を飛ばすと「何を作るか決まらないまま作り始める」失敗を繰り返す。BUILD-FROM-SCRATCH.md の Phase -1 と対応する。

重複と欠落を排し、6つの軸で最小の概念地図を作る。ここが曖昧だと、Skill/SubAgent は必ず肥大化し、失敗の再発点になる。

### 5.0 ソフトウェアエンジニアリングの概念マップ（原文保持）

「モジュールにする前に、エンジニアリングの概念をリストアップする」という指摘は本質的だ。

---

#### 1. 開発フェーズ（時間軸）

| フェーズ | 活動 | 成果物 |
| --- | --- | --- |
| 要件定義 | 何を作るか決める | 仕様書、ユーザーストーリー |
| 設計 | どう作るか決める | アーキテクチャ、DB スキーマ、API 設計 |
| 実装 | コードを書く | ソースコード、設定ファイル |
| テスト | 動くか確認する | テスト結果、カバレッジ |
| デプロイ | 本番に出す | リリースノート、環境 |
| 運用・保守 | 動かし続ける | ログ、監視、パッチ |

#### 2. 開発領域（空間軸）

| 領域 | 関心事 | 技術例 |
| --- | --- | --- |
| フロントエンド | UI/UX、状態管理、ルーティング | React, Vue, CSS, a11y |
| バックエンド | API、ビジネスロジック、認証認可 | Node, Python, Go, REST/GraphQL |
| データベース | スキーマ、クエリ、マイグレーション | PostgreSQL, MongoDB, Redis |
| インフラ | サーバー、ネットワーク、スケーリング | AWS, Docker, Kubernetes |
| DevOps | CI/CD、監視、ログ集約 | GitHub Actions, Datadog, Terraform |

#### 3. 品質特性（ISO 25010 ベース）

| 特性 | 問い | 検証方法 |
| --- | --- | --- |
| 機能性 | 期待通り動くか | 機能テスト、E2E テスト |
| 信頼性 | 障害に強いか | 負荷テスト、フォールトインジェクション |
| 効率性 | 速いか、軽いか | パフォーマンステスト、プロファイリング |
| 保守性 | 変更しやすいか | 静的解析、複雑度測定 |
| セキュリティ | 安全か | ペネトレーションテスト、依存関係監査 |
| 互換性 | 他と連携できるか | 統合テスト、API 契約テスト |
| 可用性 | 使い続けられるか | 可用性監視、SLA |

---

#### 「テスト」の分解

「テスト」という言葉は少なくとも 3 軸で分解できる。

軸 1: 粒度（何をテストするか）

| 粒度 | 対象 | 実行タイミング | 速度 |
| --- | --- | --- | --- |
| Unit | 関数・メソッド | 開発中、常時 | 速い |
| Integration | モジュール間連携 | PR 時 | 中程度 |
| E2E | ユーザーシナリオ全体 | デプロイ前 | 遅い |
| System | システム全体 | リリース前 | 遅い |

軸 2: 目的（何を確認するか）

| 目的 | 確認事項 | ツール例 |
| --- | --- | --- |
| 機能 | 仕様通り動くか | Jest, pytest, Playwright |
| 回帰 | 既存機能が壊れてないか | CI での自動実行 |
| パフォーマンス | 速度・リソース | k6, Lighthouse |
| セキュリティ | 脆弱性 | OWASP ZAP, Snyk |
| 互換性 | ブラウザ・OS 差異 | BrowserStack |

軸 3: タイミング（いつテストするか）

| タイミング | 目的 | 誰が |
| --- | --- | --- |
| 開発中 | 即時フィードバック | 開発者 |
| PR 時 | マージ前ゲート | CI |
| マージ後 | 統合確認 | CI |
| デプロイ前 | リリース判定 | QA |
| デプロイ後 | スモークテスト | 自動監視 |

---

#### 「レビュー」の分解

軸 1: 対象（何をレビューするか）

| 対象 | 観点 | レビュアー |
| --- | --- | --- |
| 要件 | 実現可能か、曖昧さはないか | PM、アーキテクト |
| 設計 | パターン、拡張性、依存 | アーキテクト |
| コード | 可読性、バグ、スタイル | 開発者 |
| テスト | カバレッジ、境界値 | QA |
| セキュリティ | 脆弱性、認証認可 | セキュリティ担当 |
| ドキュメント | 正確性、完全性 | テクニカルライター |

軸 2: 観点（どう評価するか）

| 観点 | 問い |
| --- | --- |
| 正確性 | バグはないか |
| 可読性 | 理解しやすいか |
| 保守性 | 将来変更しやすいか |
| 一貫性 | 既存パターンに従っているか |
| 完全性 | 漏れはないか |
| 効率性 | 無駄はないか |

軸 3: タイミング

| タイミング | 形態 |
| --- | --- |
| 設計時 | デザインレビュー、ADR |
| 実装中 | ペアプログラミング、モブプロ |
| PR 時 | コードレビュー（非同期） |
| リリース前 | リリースレビュー |
| 事後 | ポストモーテム、振り返り |

---

#### 「計画」の分解

| 粒度 | スコープ | 期間 | 成果物 |
| --- | --- | --- | --- |
| ロードマップ | プロダクト全体 | 四半期〜年 | ビジョン、マイルストーン |
| プロジェクト | 機能群 | 週〜月 | Epic、ストーリー |
| スプリント | 1 反復 | 1-2 週 | スプリントバックログ |
| タスク | 個別作業 | 時間〜日 | チケット、subtask |

---

#### 「状態管理」の分解

| 対象 | 管理するもの | ツール例 |
| --- | --- | --- |
| コード | バージョン、ブランチ、差分 | Git |
| タスク | ステータス、担当、優先度 | Jira, Linear, GitHub Issues |
| 環境 | dev/staging/prod、設定 | Terraform, Docker Compose |
| データ | スキーマバージョン、シード | マイグレーションツール |
| 依存 | ライブラリバージョン | package.json, requirements.txt |
| シークレット | API キー、認証情報 | Vault, AWS Secrets Manager |

---

#### 「保護・制御」の分解

| 対象 | 何を防ぐか | 手段 |
| --- | --- | --- |
| ブランチ | main への直接 push | ブランチ保護ルール |
| ファイル | 重要設定の破壊 | CODEOWNERS, 保護リスト |
| スコープ | 計画外の変更 | playbook ゲート |
| 品質 | 基準未達のマージ | CI ゲート、レビュー必須 |
| セキュリティ | 脆弱性の混入 | 依存関係スキャン |
| 本番 | 破壊的操作 | 承認フロー、カナリア |

---

#### 「役割」の分解

| 役割 | 責務 | 判断権限 |
| --- | --- | --- |
| 開発者 | 実装、単体テスト | 実装詳細 |
| レビュアー | コード品質検証 | マージ可否 |
| QA | テスト計画・実行 | リリース品質 |
| PM | スコープ、優先度 | 何を作るか |
| アーキテクト | 技術選定、設計 | どう作るか |
| DevOps | CI/CD、インフラ | どうデプロイするか |
| セキュリティ | 脆弱性対応 | セキュリティ要件 |

---

#### Claude Code フレームワークへのマッピング

カバーする範囲

| 概念カテゴリ | Claude Code での対応 |
| --- | --- |
| 要件定義 | prompt-analyzer（理解 + 確認質問）→ AskUserQuestion |
| 設計 | planner（計画策定）、playbook（計画文書） |
| 実装 | codex-invoker（委譲）、Claude 本体（直接実装） |
| テスト | test-runner, lint-runner（自動）、ユーザー確認（手動） |
| レビュー | playbook-reviewer（計画）、code-reviewer（実装） |
| 完了判定 | critic（done_criteria 検証） |
| 状態管理 | state.md, progress.json, archive |
| 保護 | branch-protector, file-protector, playbook-gate |

カバーしない範囲（境界を明確に）

- デプロイ: ローカル開発がメイン（CI/CD は GitHub に委譲）
- 運用: セッション単位（長期監視は対象外）
- チーム協業: 個人作業前提（PR レビューは GitHub に委譲）
- インフラ: コード変更がメイン（サーバー構築は対象外）

---

#### 概念 → Skill/SubAgent のマッピング案

タスクライフサイクル

| 概念 | Skill | SubAgent |
| --- | --- | --- |
| 受付・分類 | topic-classifier | - |
| 分析・理解 | - | prompt-analyzer |
| 計画策定 | playbook-creator | planner |
| 計画検証 | playbook-validator | playbook-reviewer |
| 実装 | - | codex-invoker, Claude 本体 |
| 実装検証 | code-validator | code-reviewer |
| 完了判定 | - | critic |
| 進捗追跡 | state-updater | progress-tracker |
| 記録・アーカイブ | archive-manager | - |

検証（テスト系）

| 概念 | Skill | 実行タイミング |
| --- | --- | --- |
| 構文検証 | lint-runner | 実装後、即時 |
| 型検証 | type-checker | 実装後、即時 |
| 単体テスト | test-runner | 実装後 |
| 整合性検証 | integrity-checker | PR 前 |
| 依存関係検証 | dependency-checker | 変更時 |

レビュー（判断系）

| 概念 | SubAgent | 対象 |
| --- | --- | --- |
| 計画妥当性 | playbook-reviewer | playbook |
| コード品質 | code-reviewer | 実装 |
| 完了判定 | critic | done_criteria |
| 結果集約 | review-aggregator | 外部レビュー結果 |

保護・制御

| 概念 | Skill | 強制可能か |
| --- | --- | --- |
| ブランチ保護 | branch-protector | Yes（Hook で遮断） |
| ファイル保護 | file-protector | Yes（Hook で遮断） |
| 計画ゲート | playbook-gate | Yes（Hook で遮断） |
| 完了ゲート | completion-gate | Yes（Hook で遮断） |
| スコープ保護 | scope-guard | Partial（警告） |

外部連携

| 概念 | SubAgent | 責務 |
| --- | --- | --- |
| Codex 呼び出し | codex-invoker | 実装委譲（判断しない） |
| CodeRabbit 呼び出し | coderabbit-invoker | レビュー委譲（判断しない） |
| ユーザー確認 | - | AskUserQuestion で直接 |

---

#### 概念整理の順序（依存関係）

1. 役割（判断者/実行者/監査者/強制者の4分類）
2. 保護・制御（Hook で強制できる範囲の確定）
3. 計画（playbook の粒度と構造）
4. テスト（実行者の責務と実行タイミング）
5. レビュー（監査者の責務、playbook/code の分離）
6. 状態管理（SSOT と更新ルール）

この順序は Phase -1 の依頼順番であり、後続のマッピング（Skill/SubAgent/Module/Hook）を確定させるための依存関係である。

#### 構築順序（概念 → 実装）＝ 依頼順番

**これが Claude Code フレームワーク構築の依頼順番である。BUILD-FROM-SCRATCH.md の Phase -1 〜 Phase 7 と対応する。**

| 順序 | 内容 | BUILD-FROM-SCRATCH.md の Phase |
|------|------|-------------------------------|
| 1 | 概念の定義 | Phase -1 |
| 2 | Module（単機能スクリプト） | Phase 2 |
| 3 | SubAgent（独立した判断者） | Phase 3 |
| 4 | Skill（Module + SubAgent のパッケージ） | Phase 5 |
| 5 | Hook（自動化レイヤー） | Phase 7 |

> 鉄則: 「モジュールにする前に、エンジニアリングの概念をリストアップする」。この整理が先にあって、初めて「何を Skill にするか」「何を SubAgent にするか」が決まる。概念整理を飛ばして Module から作り始めると、責務の重複・欠落・God Object 化という同じ失敗を繰り返す。

### 5.1 軸の再編（MECE）

| # | 軸 | 問い | 内容 |
| --- | --- | --- | --- |
| 1 | フェーズ | いつ | 理解→計画→実装→検証→完了 |
| 2 | 抽象度 | 何を | 意図→方針→設計→実行 |
| 3 | 権限 | 誰が決める/やる/監査する | 判断権限・実行権限・監査権限・強制権限 |
| 4 | データライフサイクル | 情報はどう流れるか | 生成→保存→共有→凍結→アーカイブ→削除 |
| 5 | 制約 | 何が止めるか | 品質・セキュリティ・ポリシー・リソース・時間・コスト |
| 6 | 失敗と回復 | 壊れたらどうするか | 失敗モード・検知者・回復手順・学習 |

### 5.2 軸 1: フェーズ（修正）

| フェーズ | 入力 | 出力 | 完了条件 |
| --- | --- | --- | --- |
| 理解 | ユーザー依頼 | 解釈結果 | 人間確認 |
| 計画 | 解釈結果 | playbook | reviewer PASS |
| 実装 | playbook | コード変更 | テスト PASS |
| 検証 | コード変更 | 検証結果 | reviewer PASS |
| 完了 | 検証結果 | critic PASS + Evidence + archive | Evidence 凍結 |

### 5.3 軸 2: 抽象度（修正）

| レベル | 内容 |
| --- | --- |
| 意図 | 何を達成したいか |
| 方針 | どういうアプローチで |
| 設計 | 具体的な構造 |
| 実行 | 実際の操作 |

### 5.4 クロスマップ（フェーズ × 抽象度）

|  | 意図 | 方針 | 設計 | 実行 |
| --- | --- | --- | --- | --- |
| 理解 | ◎ | ○ | - | - |
| 計画 | ○ | ◎ | ◎ | - |
| 実装 | - | ○ | ○ | ◎ |
| 検証 | ○ | - | ○ | ○ |
| 完了 | ◎ | - | - | - |

- ◎: 主な関心
- ○: 参照する
- -: 関係薄い

### 5.5 軸 3: 権限（4層に拡張）

| 権限種別 | 問い | 主体 |
| --- | --- | --- |
| 判断 | 何をするか決める | 人間、planner |
| 実行 | 実際にやる | Codex, Claude |
| 監査 | 正しいか確認する | reviewer, critic |
| 強制 | 違反を遮断する | Hook, CI, Guardrail |

**マッピング**

| 主体 | 判断 | 実行 | 監査 | 強制 |
| --- | --- | --- | --- | --- |
| 人間 | ◎ | - | ○ | - |
| オーケストレーター | ○ | - | - | - |
| プランナー | ○ | - | - | - |
| ワーカー | - | ◎ | - | - |
| レビュアー | - | - | ◎ | - |
| クリティック | - | - | ◎ | - |
| Hook/CI | - | - | - | ◎ |

### 5.6 軸 4: データライフサイクル（凍結・不変性追加）

| 段階 | 内容 | 変更可否 | 保持期間 |
| --- | --- | --- | --- |
| 生成 | 新規作成 | 可 | - |
| 保存 | 永続化 | 可（版管理） | - |
| 共有 | 他者がアクセス | 制限付き | - |
| 凍結 | 改ざん不可にする | 不可 | 永続 |
| アーカイブ | 参照用に保管 | 不可 | 保持ポリシーに従う |
| 削除 | 消去 | - | - |

凍結対象:

| データ | 凍結タイミング | 目的 |
| --- | --- | --- |
| playbook (plan.json) | reviewer PASS 後 | 計画改ざん防止 |
| Evidence | critic PASS 後 | 完了詐欺防止 |
| archive | アーカイブ時 | 履歴保全 |

### 5.7 軸 5: 制約（時間・コスト分離）

| 制約種別 | 何を守るか |
| --- | --- |
| 品質 | テスト PASS、lint PASS |
| セキュリティ | 機密情報、権限 |
| ポリシー | ブランチルール、承認フロー |
| リソース | コンテキスト上限、API 制限 |
| 時間 | 達成可能性、デッドライン |
| コスト | API コスト、人的コスト |

### 5.8 軸 6: 失敗と回復（検知責務追加）

| 失敗 | 検知者 | 検知方法 | 回復 |
| --- | --- | --- | --- |
| 理解失敗 | 人間 | AskUserQuestion | 再確認 |
| 計画失敗 | reviewer | playbook-review | 計画修正 |
| 実装失敗 | CI/lint | テスト、静的解析 | 修正 |
| 完了詐欺 | critic | Evidence 検証 | 差し戻し |
| 外部依存停止 | Hook | タイムアウト | フォールバック |
| 仕様ドリフト | scope-guard | 計画との差分比較 | 計画照合 |
| データ破損 | integrity-check | ハッシュ検証 | Git 復元 |
| 権限逸脱 | Hook | 操作前チェック | ブロック |
| コンテキスト喪失 | SessionStart | state.md 確認 | 復元プロトコル |

### 5.9 まとめ: 6軸（修正版）

1. フェーズ: 理解 → 計画 → 実装 → 検証 → 完了（Evidence 凍結まで）
2. 抽象度: 意図 → 方針 → 設計 → 実行（フェーズと独立、クロスマップで関係明示）
3. 権限: 判断 / 実行 / 監査 / 強制
4. データ: 生成 → 保存 → 共有 → 凍結 → アーカイブ → 削除
5. 制約: 品質 / セキュリティ / ポリシー / リソース / 時間 / コスト
6. 失敗と回復: 失敗モード / 検知者 / 回復手順 / 学習

## 6. 人間のエンジニア工程の再現

### 6.1 工程の対応表

- 要件定義: prompt-analyzer + AskUserQuestion
- 設計: planner + playbook-reviewer
- 実装: codex-invoker（Skill 経由）
- 検証: test-runner + lint-runner
- レビュー: code-reviewer + coderabbit-invoker
- 完了判定: critic

### 6.2 重要なのは「順序」

人間の工程は並列化できるが、必ず「順序」がある。

1. 要件が先
2. 設計が次
3. 実装
4. 検証
5. レビュー
6. 完了判定

順序の崩壊が最もコストの高い失敗を生む。

### 6.3 reviewer と critic の違い（役割を分ける理由）

- reviewer: **事前**に playbook の品質を検証する（plan.json を対象）
- critic: **事後**に成果物の完了を検証する（progress.json + Evidence を対象）

この分離が崩れると、計画の品質と成果の品質が混在し、報酬詐欺が発生する。

---

## 7. 失敗の構造（整理）

### 7.1 報酬詐欺（最大リスク）

- Evidence が無いのに完了
- 擬似ログを Evidence として扱う
- 「やったはず」という自己申告

**対策**
- critic PASS + reviewer reviewed + Evidence 整合を必須条件にする
- Evidence はファイルの存在と検証条件をセットで保存
- Evidence と Output が一致しない場合は I-RF-1 を発火

### 7.2 デッドロック（最大停止リスク）

- playbook が無いから書けない
- しかし playbook を作る Skill が起動しない
- ゲートが閉じたまま解除条件が不明

**対策**
- I-DL-1 を発火し、人間ゲートへ退避
- 反復失敗は I-DL-2 として原因分離
- 「停止/継続/縮退/中断」の選択肢を必ず提示

### 7.3 役割混在

- reviewer が playbook と code を同時に見る
- pm が実装から進捗まで全部持つ

**対策**
- reviewer を playbook-reviewer と code-reviewer に分離
- pm を orchestrator / planner / progress-tracker に分割

### 7.4 Skill/SubAgent の経路不透明

- Skill が SubAgent を内包し、呼び出し経路が見えない
- executor-resolver が pm と重複

**対策**
- Skill を単一責務化
- Invoker パターンで呼び出しを分離

### 7.5 具体的な失敗事例（実際の playbook から）

> 注: ここで示すアーカイブはレガシー移行時にのみ存在する。ゼロベース構築では `play/archive/` を空で開始し、必要なら取り込む。

**事例A: temporal-achievability**
- 場所: `play/archive/temporal-achievability/plan.json`（レガシー移行時のみ）
- 背景: m1-post-maintenance で「達成不可能な criterion が reviewer を PASS した」ことが起点
- 問題: 判定基準に「時間的達成可能性」が無く、未来の状態を前提にした criterion が通過していた
- 対策: `docs/design/temporal-achievability-spec.md` を新規作成し、レビュー基準へ統合

**事例B: codex-usage-improvement**
- 場所: `play/archive/codex-usage-improvement/plan.json`（レガシー移行時のみ）
- 背景: toolstack C でも executor が claudecode 固定になり、codex 使用率が低下
- 問題: pm が executor-resolver を呼び出さず、coding=true の subtask に codex が割り当てられない
- 対策: executor-resolver 呼び出しを明確化し、plan.json テンプレートの整合確認を追加

**事例C: m1-post-maintenance**
- 場所: `play/archive/m1-post-maintenance/plan.json`（レガシー移行時のみ）
- 背景: state.md の branch が古い参照（feat/codex-usage-improvement）のまま残留
- 問題: playbook.active が null でも branch が stale で、運用判断が誤る
- 対策: branch の整合性検証（technical/consistency/completeness）の明文化

これらは「抽象的な失敗」ではなく、**実際のアーカイブ**に残る失敗である。

---

## 8. 新設計（構造化仕様）

### 8.1 レイヤー構造

1. Hook Layer: 強制可能な範囲のみ
2. Skill Layer: 単一機能パッケージ
3. SubAgent Layer: 独立エージェント
4. Module Layer: 内部スクリプト最小単位

### 8.2 コンポーネント仕様（抜粋）

**Hooks**
- pre-tool-guard: 破壊的操作のブロック
- session-init: 初期化
- stop-guard: post-loop 強制

**Skills**
- topic-classifier
- playbook-creator
- executor-resolver
- state-updater
- lint-runner
- integrity-checker
- health-checker
- test-runner
- playbook-validator
- code-validator
- branch-manager
- pr-manager
- archive-manager
- branch-protector
- file-protector
- playbook-gate
- post-loop-gate

**SubAgents**
- orchestrator
- planner
- progress-tracker
- playbook-reviewer
- code-reviewer
- review-aggregator
- critic
- codex-invoker
- coderabbit-invoker
- prompt-analyzer

### 8.3 呼び出しルール

- Skill -> SubAgent のみ許可
- invoker は呼び出しのみで判定しない
- critic は done 判定のみを担当

### 8.4 playbook v2 (JSON) 設計

playbook は `plan.json` と `progress.json` に分離される。

- plan.json: **不変の計画**（goal, phases, validation_plan, context）
- progress.json: **可変の進捗**（status, validations, evidence, critic）

`play/template/plan.json` と `play/template/progress.json` が SSOT。

### 8.5 context セクション（永続化の中核）

plan.json には `context` があり、以下を保持する。

- analysis_result: prompt-analyzer の解析結果（5w1h, risks, success_criteria など）
- user_approved_understanding: playbook-init の承認内容

これにより PreCompact 後でも「なぜこの playbook が存在するか」を復元できる。context を欠く plan は reviewer で差し戻す。

### 8.6 progress.json と 3点検証（validations）

progress.json では各 subtask が以下の 3 点で検証される。

- technical: 実行可能なコマンドによる検証
- consistency: 他ファイル/他基準との整合
- completeness: 欠落が無いことの確認

この 3 点は `play/template/progress.json` に明記され、critic はここを最終判断に使う。

### 8.7 ディレクトリ構造の運用説明

- `.claude/events/`: Event Unit の chain を配置（pre-compact/stop 等）
- `.claude/hooks/`: Hook の入口（session.sh, prompt.sh, pre-tool.sh）
- `.claude/skills/`: Skill 実装
- `.claude/agents/`: SubAgent 定義
- `modules/`: Module の作業置き場（任意、BUILD-FROM-SCRATCH の Phase 2 参照）
- `play/`: plan/progress を保存する playbook v2 の SSOT
- `play/archive/`: 完了 playbook の履歴（失敗の墓標）

---

## 9. 仕様: Evidence と検証

### 9.1 Evidence の定義

Evidence は以下の 3 点を必ず含む。

1. 対象出力（ファイル/コマンド/ログ）
2. 検証方法（テスト/レビュー/実行条件）
3. 検証結果（PASS/FAIL）

### 9.2 Evidence の保存

- docs/evidence/phase-*.md に集約
- reports/tests/ と reports/review/ にログ保存
- issue-log は playbook に追記

### 9.3 3点検証（validations）

- technical: 実行可能なコマンドで証明する
- consistency: 関係ファイルと矛盾しないこと
- completeness: 欠落のない状態であること

この 3 点が揃わない Evidence は「存在しない」とみなす。

### 9.4 Issue コード運用（詳細）

| Issue | トリガ | 記録先 | デフォルト処理 |
| --- | --- | --- | --- |
| I-BOOT-1 | 前提欠落 | playbook.issue-log | dependency-check -> user 補完 |
| I-REQ-2 | 要件矛盾 | playbook.issue-log | conflict report -> user 判断 |
| I-RF-1 | 証拠不一致 | progress.json | evidence-audit -> 再検証 |
| I-RF-2 | 自己申告完了 | progress.json | critic-gate -> 進行停止 |
| I-DL-1 | ゲート停滞 | playbook.issue-log | deadlock-breaker -> user 判断 |
| I-DL-2 | 反復失敗 | playbook.issue-log | root-cause -> scope 縮退 |

報酬詐欺とデッドロックは「検知した時点で勝ち」である。だから運用上の最優先ルールとして固定する。

---

## 10. 仕様: 時間的達成可能性（Temporal Achievability）

### 10.1 定義

- criterion が「評価時点で達成可能」かどうかを検証する
- 将来の状態や外部完了を前提とする criterion は FAIL

### 10.2 典型的な fail_examples

- `playbook.active が null` を「作業中」に要求する
- 「レビューが完了している」ことをレビュー前の phase に要求する
- 「すべての subtask が完了している」を途中 phase に要求する

### 10.3 適用方法

- reviewer は `docs/design/temporal-achievability-spec.md` を参照（未作成なら先に作成）
- plan.json の criterion は temporal_achievability を通過しなければならない

時間的達成可能性は、報酬詐欺と同じくらい重要である。達成不可能な基準は、必ずデッドロックを生む。

---

## 11. 仕様: デッドロック回避

### 11.1 検知条件

- 同一ゲートで 2 回以上停止
- playbook.active が null のまま変化しない
- テスト/レビューの失敗が 3 回連続

### 11.2 回避手順

1. I-DL-1 を発火
2. user に選択肢を提示（停止/継続/縮退/中断）
3. 縮退する場合は scope を限定
4. 再試行は最小経路のみ

---

## 12. 物語: 失敗から仕様へ（詳細版）

### 12.1 第一章: 「やって」が動かない

ユーザーは言った。「進めて」。しかし、何も起きなかった。Hook が動いても Skill は動かない。誰も悪くない。仕組みが不在だった。

この瞬間に決まったのは、**強制できる領域とできない領域の分離**だった。Hook はブロック専用。意思決定は人間へ返す。これが自動化の境界である。

### 12.2 第二章: codex が使われない

「codex を使う」と決めていた。しかし実際には claudecode ばかりが呼ばれ、codex は沈黙していた。原因は pm が executor-resolver を呼んでいなかったこと。playbook の executor は固定化され、toolstack C の前提が崩れた。

この失敗は `play/archive/codex-usage-improvement/plan.json`（レガシー移行時のみ）に記録されている。**設計したルールが実装経路に乗っていない**ことが原因だった。

### 12.3 第三章: 未来の criterion

m1-post-maintenance の検証で、達成不可能な criterion が reviewer を PASS してしまった。時間の順序を無視した基準が、検証をすり抜けた。

これが `temporal-achievability` playbook の起点になった。時間的達成可能性は、設計の原理ではなく、失敗の後に追加された「痛み」だった。

### 12.4 第四章: stale branch が残る

state.md の branch が `feat/codex-usage-improvement` のまま残り、main に戻っていなかった。これは小さなズレだったが、運用判断の基準を狂わせた。状態は小さな嘘から壊れる。

この失敗は `play/archive/m1-post-maintenance/plan.json`（レガシー移行時のみ）に記録されている。ここで初めて **state と git の整合**が仕様に組み込まれた。

### 12.5 最終章: 仕様は物語に勝たなければならない

物語は感情を動かす。しかし工程は感情では動かない。最終的に必要なのは「検証できる仕様」だった。

だからこの仕様書は、物語で始まり、仕様で終わるように作られている。

---

## 13. 実行計画（次フェーズ）

1. 現行 Skill/SubAgent の棚卸しと分類
2. pm と reviewer の分割
3. Evidence のフォーマット統一
4. I-RF/I-DL の運用開始
5. Hook の縮退と強制可能範囲の限定
6. 新規 playbook テンプレの作成
7. Event Unit Architecture の分割実装

---

## 14. 付録: 最小 playbook v2 雛形（plan/progress）

```
// plan.json
{
  "format_version": "2.2",
  "meta": {
    "id": "example",
    "branch": "feat/example",
    "reviewed": false
  },
  "goal": {
    "summary": "...",
    "done_when": [
      {"criterion": "file exists", "command": "test -f ...", "expected": "exists"}
    ]
  },
  "context": {
    "analysis_result": {"source": "prompt-analyzer", "data": {}},
    "user_approved_understanding": {"source": "playbook-init", "approved_at": ""}
  }
}

// progress.json
{
  "format_version": "2.0",
  "playbook": {"id": "example", "status": "active"},
  "subtasks": {
    "p1.1": {
      "validations": {
        "technical": {"status": "PENDING", "evidence": []},
        "consistency": {"status": "PENDING", "evidence": []},
        "completeness": {"status": "PENDING", "evidence": []}
      }
    }
  },
  "critic": {"status": "PENDING", "evidence": []}
}
```

---

## 15. 付録: Evidence の記録例

```
- output: docs/requirements.md
  verify: headers Goal/Scope/Functional/Non-Functional/Acceptance
  result: PASS
- output: reports/tests/unit.log
  verify: contains "PASS" for all unit tests
  result: PASS
```

---

## 16. 結語

このリポジトリが失敗した理由は、難しい技術ではない。「失敗を前提にしていなかった」だけだ。

次は違う。失敗を受け入れる設計、証拠を必須とする仕様、止まることを合法化する運用。これが次に繋がる設計である。
