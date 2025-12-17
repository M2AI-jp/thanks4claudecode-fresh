# Project: thanks4claudecode-recovery

> 回復プロジェクト: 複雑化した AI エージェント基盤を「小さく・テスト可能で・使い回せる」状態に再構成する

---

## meta

```yaml
project: thanks4claudecode-recovery
created: 2025-12-18
status: active
legacy_archived: plan/archive/project-v1-legacy.md
```

---

## vision

```yaml
goal: "thanks4claudecode を『小さく・テスト可能で・使い回せる AI エージェント基盤』として再構成する"
principles:
  - システム自身の自己申告を信じない（E2E でのみ信用する）
  - 1 機能 = 1 コンポーネント = 1 責任（MECE）
  - context の入口を 1 箇所に絞る
  - 「フレームワーク開発」と「実際のプロジェクト開発」を分離する
success_criteria:
  - Hooks/SubAgents/Skills が役割ベースに再分類されている
  - 5 つの主要機能に対する E2E シナリオテストが存在し、PASS している
  - CLAUDE.md の「毎セッション必読部分」が 200 行以下に削減されている
  - このリポジトリの扱い（テンプレ化 / 博物館化 / 廃棄）が決定されている
```

---

## milestones

```yaml
- id: M101
  name: "レガシー project.md の凍結と回復プロジェクトの開始"
  description: |
    既存の project.md を「実験の履歴」として保存し、
    回復専用の project.md を作り直す。以降の作業は全て新 project.md を基準に行う。
  status: not_started
  depends_on: []
  playbooks: []
  done_when:
    - "既存の plan/project.md が plan/archive/project-v1-legacy.md 等の名前で保存されている"
    - "新しい plan/project.md が project-format テンプレートに沿った構造で作成されている"
    - "新しい project.md の vision が『回復プロジェクト』専用の内容になっている"
    - "state.md の参照先 (project: ...) が新しい project.md を指している"

- id: M102
  name: "安全な編集モード（developer / admin モード）の仕様定義"
  description: |
    admin/developer モードの本来の意味を明確化し、
    「回復作業中はどの Hook がどこまでバイパスされるか」の仕様を決める。
    まずは仕様だけを決め、実装は後続の milestone で行う。
  status: not_started
  depends_on: [M101]
  playbooks: []
  done_when:
    - "docs/security-modes.md が作成され、strict/trusted/developer/admin の意味と挙動が定義されている"
    - "各 Hook がどの mode で有効/緩和/無効になるかの一覧表が docs/security-modes.md に記載されている"
    - "state.md の config.security の値と docs/security-modes.md の定義が一致している"

- id: M103
  name: "フレームワーク vs ワークスペースの分離方針を決める"
  description: |
    このリポジトリで「何を開発するのか」を整理し、
    1) AI フレームワーク（Hooks/SubAgents/Skills）の開発
    2) 実際のプロダクト開発（SaaS 等）
    を論理的に分離する方針を決める。必要であればレポジトリを分割する。
  status: not_started
  depends_on: [M101]
  playbooks: []
  done_when:
    - "docs/product-vs-framework.md が存在し、フレームワーク層とプロダクト層の責務が文章で定義されている"
    - "state.md の focus.current の候補値が、framework 用と workspace 用で整理されている"
    - "plan/template/state-initial.md が新しい focus 構造に合わせて更新されている"

- id: M104
  name: "コンポーネント分類の再設計（Hooks/SubAgents/Skills の MECE 化）"
  description: |
    Hooks / SubAgents / Skills を、「何を守っているか」の観点で再分類する。
    例: Guard (強制), Observer (ロギング), Planner (計画生成), Adapter (外部ツール連携) など。
    1 コンポーネント = 1 カテゴリになるように MECE を目指す。
  status: not_started
  depends_on: [M101, M103]
  playbooks: []
  done_when:
    - "docs/component-taxonomy.md が作成され、カテゴリ一覧と定義が書かれている"
    - "docs/repository-map.yaml に各コンポーネントの category フィールドが追加されている"
    - "1つのコンポーネントが複数カテゴリにまたがっていないことが目視で確認されている"
    - "『何のカテゴリにも属さない』コンポーネントが 0 である"

- id: M105
  name: "Hook チェーンの最小化（編集ループの核心だけ残す）"
  description: |
    PreToolUse/Edit の Hook 連鎖から、「どうしても必要なガード」だけを抽出し、
    それ以外は Observer/Optional に降格させる。編集ループをミニマルにする。
  status: not_started
  depends_on: [M104]
  playbooks: []
  done_when:
    - "docs/hook-responsibilities.md が更新され、各 Hook の category と優先度が追記されている"
    - ".claude/settings.json の PreToolUse:Edit に登録されている Hook が 3〜5 個程度に削減されている（init-guard / playbook-guard / check-protected-edit / check-main-branch 程度）"
    - "削除された Hook は manual 実行か PostToolUse/SessionStart に移動されている"
    - "repository-map.yaml の Hooks 数の整合が取れている"

- id: M106
  name: "context エントリポイントの一本化（軽量ブートストラップ）"
  description: |
    「セッション開始時に必ず読むべき情報」を 1 ファイルに集約し、その他は必要に応じて参照する形にする。
    CLAUDE.md の毎回読むべき部分を 200 行以内にまとめ、詳細ルールは別ファイルに分離する。
  status: not_started
  depends_on: [M104, M105]
  playbooks: []
  done_when:
    - "docs/boot-context.md が作成され、state.md / project.md / 現在の playbook へのリンクと最小限のルールが書かれている"
    - "CLAUDE.md の冒頭に『まず docs/boot-context.md を読め』と明示されている"
    - "CLAUDE.md の『毎セッション必読』部分が 200 行以内に収まっている"
    - "init-guard.sh が state.md + docs/boot-context.md の Read を強制する仕様に簡略化されている"

- id: M107
  name: "state.md / project.md / repository-map の Single Source of Truth 明確化"
  description: |
    どの情報の正本（Single Source of Truth）がどこかを定義し、
    他のファイルからの重複定義を禁止する。
    例: Hooks 一覧は repository-map.yaml が正本、他は派生。
  status: not_started
  depends_on: [M104, M106]
  playbooks: []
  done_when:
    - "docs/single-source-of-truth.md に、各情報（Hooks/Agents/Skills/plan/state）の正本が一覧化されている"
    - "current-definitions.md と deprecated-references.md の役割が明文化され、重複する定義が削除されている"
    - "repository-map.yaml が『正本である』と明記されている"

- id: M108
  name: "古い用語・古い構造の一掃（health-checker / テンプレート含む）"
  description: |
    Macro/layer などの廃止用語や、古い state 構造を前提とした SubAgent/テンプレートを洗い出し、
    現在の定義に合わせて書き直すか、レガシーとしてアーカイブする。
  status: not_started
  depends_on: [M107]
  playbooks: []
  done_when:
    - "docs/deprecated-references.md に列挙されている『修正対象』ファイルが全て更新済み or アーカイブ済みである"
    - ".claude/agents/health-checker.md のチェック項目が現行 state.md 構造に一致している"
    - "plan/template/state-initial.md が最新の state.md フォーマットに揃えられている"
    - "grep で Macro / layer / architecture-*.md などの廃止用語が現在使用中ファイルから消えている"

- id: M109
  name: "報酬詐欺防止の E2E シナリオテスト設計"
  description: |
    「LLM が done と言っているが実際は done ではない」ケースを 3〜5 パターン定義し、
    Hooks/SubAgents がそれをどこまで防げるかを確認する E2E シナリオを設計する（まだ実装はしない）。
  status: not_started
  depends_on: [M106]
  playbooks: []
  done_when:
    - "docs/e2e-scenarios-reward-fraud.md に、少なくとも 3 つのシナリオが Given/When/Then 形式で定義されている"
    - "各シナリオに対して、『どの Hook/SubAgent に期待するか』が明記されている"
    - "『現状では防げない』シナリオがあれば、それも正直に列挙されている"

- id: M110
  name: "計画駆動開発（playbook 必須）の E2E シナリオ設計"
  description: |
    playbook=null での Edit/Write を試みるシナリオや、
    playbook を無視して直接ファイル変更するシナリオを定義し、
    どの Hook がそれを止めるべきかを明文化する。
  status: not_started
  depends_on: [M106]
  playbooks: []
  done_when:
    - "docs/e2e-scenarios-plan-driven.md に、Playbook を無視する典型的なパターンが定義されている"
    - "playbook-guard / scope-guard / pm SubAgent の役割分担がシナリオ上で明確になっている"
    - "『人間の手動編集でしか止められない』ケースがあれば、それも記録されている"

- id: M111
  name: "3層自動運用（project → playbook → phase）の実装範囲の再定義"
  description: |
    3層自動運用が「設計だけ」なのか「どこまで実装済みなのか」を冷静に棚卸しする。
    自動でやる範囲と、人間が介在する範囲を線引きし直す。
  status: not_started
  depends_on: [M107, M109, M110]
  playbooks: []
  done_when:
    - "docs/three-layer-system.md が作成され、現在の実装状況（implemented / planned / not-planned）が一覧化されている"
    - "project.md の vision および success_criteria から『完全自動』のような過剰な期待表現が削られている"
    - "pm SubAgent の仕様（AGENTS.md と pm.md）が、現実的な責務に合わせて更新されている"

- id: M112
  name: "E2E テストの実装（報酬詐欺 / 計画駆動 / 3層運用 / context 外部化）"
  description: |
    M109〜M111 で定義したシナリオに対して、実際に Bash + Claude Code で再現する
    テストスクリプト（または手順）を実装する。
  status: not_started
  depends_on: [M109, M110, M111]
  playbooks: []
  done_when:
    - ".claude/skills/test-runner/ 以下、または docs/e2e-tests に E2E 手順が実装されている"
    - "少なくとも 1 つのシナリオについて、『実際に防げている』ことが確認されている"
    - "少なくとも 1 つのシナリオについて、『今の設計では防げない』ことが確認されている"
    - "README または docs に、『何が出来ていて何が出来ていないか』が率直に書かれている"

- id: M113
  name: "admin モードの実装と検証（安全な「鎮静モード」）"
  description: |
    M102 で定義した admin/developer モードのうち、
    回復作業のための「一時的にガードを緩めるモード」を実装し、
    『Hook が暴れて編集できない』状態からの脱出手段を提供する。
  status: not_started
  depends_on: [M102, M105, M108]
  playbooks: []
  done_when:
    - "check-protected-edit.sh 以外の主要 Hook が、state.config.security = admin のときに exit 0 になるよう仕様が整理されている"
    - "docs/security-modes.md に、admin モードに入る/出る手順が書かれている"
    - "admin モードで plan/project.md や Hooks 自体の編集が可能であることが手動検証されている"

- id: M120
  name: "このリポジトリの最終的な扱いを決める（テンプレ化 / 博物館化 / 廃棄）"
  description: |
    ここまでの E2E 検証とシンプル化の結果を踏まえて、
    thanks4claudecode を
    1) 新規プロジェクト用テンプレートとして残すのか
    2) 実験博物館として read-only にするのか
    3) 概念だけ別レポジトリに移し、このレポジトリは凍結するのか
    を決定する。
  status: not_started
  depends_on: [M112, M113]
  playbooks: []
  done_when:
    - "docs/final-decision.md に、選択した方針と理由が記録されている"
    - "README.md の冒頭に、このリポジトリの位置づけ（テンプレ/博物館/凍結）が明記されている"
    - "state.md の focus/current が、最終方針に合わせて更新されている"
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| README.md | プロジェクト概要（最終方針決定後に更新） |
| state.md | 現在の状態（Single Source of Truth） |
| docs/boot-context.md | セッション開始時の軽量エントリポイント（M106で作成） |
| docs/repository-map.yaml | コンポーネント一覧（自動生成） |
