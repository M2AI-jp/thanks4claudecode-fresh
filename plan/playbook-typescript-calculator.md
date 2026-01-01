# playbook-typescript-calculator.md

> **.tmp/calculator/ に TypeScript 電卓プログラムを作成する**

---

## meta

```yaml
project: typescript-calculator
branch: feat/typescript-calculator
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: codex      # 実装は codex が担当
  reviewer: coderabbit  # レビューは coderabbit が担当
```

---

## context

```yaml
5w1h:
  who: "開発者（Claude Code + Codex + CodeRabbit 連携）"
  what: ".tmp/calculator/ に TypeScript 電卓プログラム（add, subtract, multiply, divide）を作成"
  when: "現在のセッションで完了"
  where: ".tmp/calculator/ ディレクトリ"
  why: "executor の役割ベース指定（worker, reviewer）の動作検証"
  how: "TypeScript + Jest でテスト駆動開発、worker(codex) で実装、reviewer(coderabbit) でレビュー"

analysis_result:
  source: prompt-analyzer
  timestamp: "2026-01-01T21:15:00Z"
  data:
    5w1h:
      who: "開発者（Claude Code を使用）"
      what: "TypeScript の電卓プログラム（四則演算）の作成"
      when: "現在のセッションで完了"
      where: ".tmp/calculator/ ディレクトリ"
      why: "executor の役割ベース指定（worker/reviewer）の動作検証"
      how: "TypeScript + Jest でテスト駆動開発"
      missing: []
    risks:
      technical:
        - risk: "ゼロ除算のエラーハンドリング実装漏れ"
          severity: medium
          mitigation: "divide 関数で明示的にチェック"
        - risk: "Jest 設定の不備"
          severity: low
          mitigation: "ts-jest を使用"
      scope:
        - risk: "四則演算以外の機能追加要求"
          severity: low
          mitigation: "playbook でスコープを明確化"
      dependency:
        - risk: "Node.js / npm 環境の問題"
          severity: low
          mitigation: "事前確認で対応"
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: "2026-01-01T21:15:00Z"
  data:
    original_terms: []  # 曖昧な表現なし
    technical_requirements:
      - requirement: "add(a, b) -> a + b を返す関数"
        derived_from: "四則演算"
        implementation_hint: "純粋関数として実装"
      - requirement: "subtract(a, b) -> a - b を返す関数"
        derived_from: "四則演算"
        implementation_hint: "純粋関数として実装"
      - requirement: "multiply(a, b) -> a * b を返す関数"
        derived_from: "四則演算"
        implementation_hint: "純粋関数として実装"
      - requirement: "divide(a, b) -> a / b を返す、b=0 時はエラー"
        derived_from: "四則演算 + ゼロ除算エラーハンドリング"
        implementation_hint: "b === 0 の場合に Error を throw"
    codebase_context:
      relevant_files: []
      existing_patterns: []
      conventions: []

user_approved_understanding:
  source: understanding-check
  approved_at: "2026-01-01T21:15:00Z"
  summary: ".tmp/calculator/ に TypeScript 電卓を作成、worker(codex) で実装、reviewer(coderabbit) でレビュー"
  approved_items:
    - question_id: "q1"
      question: "この理解で playbook を作成してよいですか？"
      answer: "はい（ユーザーの明確な指示に基づく）"
  technical_requirements_confirmed: []
```

---

## goal

```yaml
summary: ..tmp/calculator/ に TypeScript 電卓プログラム（四則演算）を作成する
done_when:
  - ..tmp/calculator/package.json が存在する
  - ..tmp/calculator/src/calculator.ts に add, subtract, multiply, divide 関数が存在する
  - npm test が exit 0 で終了する（13 tests passed 確認済み）
  - divide(1, 0) がエラーを throw するテストが PASS する
```

---

## phases

### p1: プロジェクト初期化

**goal**: TypeScript + Jest の開発環境を構築する

#### subtasks

- [x] **p1.1**: .tmp/calculator/package.json が存在する
  - executor: claudecode
  - validations:
    - technical: PASS - package.json 作成完了
    - consistency: PASS - name, version, scripts 含む
    - completeness: PASS - test script が jest を呼び出す
  - validated: 2026-01-01T21:20:00Z

- [x] **p1.2**: .tmp/calculator/tsconfig.json が存在し TypeScript コンパイルが可能である
  - executor: claudecode
  - validations:
    - technical: PASS - tsconfig.json 作成完了
    - consistency: PASS - strict: true, esModuleInterop: true 設定済み
    - completeness: PASS - outDir, rootDir, include 設定済み
  - validated: 2026-01-01T21:20:00Z

- [x] **p1.3**: .tmp/calculator/jest.config.js が存在し Jest が TypeScript をサポートする
  - executor: claudecode
  - validations:
    - technical: PASS - jest.config.js 作成完了
    - consistency: PASS - preset: 'ts-jest' 設定済み
    - completeness: PASS - testEnvironment: 'node' 設定済み
  - validated: 2026-01-01T21:20:00Z

- [x] **p1.4**: npm install が成功し node_modules が存在する
  - executor: claudecode
  - validations:
    - technical: PASS - npm install 完了、280 packages
    - consistency: PASS - package-lock.json 生成済み
    - completeness: PASS - 全依存関係インストール済み
  - validated: 2026-01-01T21:20:00Z

**status**: done
**max_iterations**: 5

---

### p2: 電卓関数の実装

**goal**: add, subtract, multiply, divide 関数を実装する
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .tmp/calculator/src/calculator.ts が存在する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - ファイル作成完了
    - consistency: PASS - src/ 構造が標準的
    - completeness: PASS - 44行の実装
  - validated: 2026-01-01T21:22:00Z

- [x] **p2.2**: add(a, b) 関数が実装されている
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - export function add 確認
    - consistency: PASS - (a: number, b: number): number
    - completeness: PASS - return a + b
  - validated: 2026-01-01T21:22:00Z

- [x] **p2.3**: subtract(a, b), multiply(a, b) 関数が実装されている
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - 両関数が存在
    - consistency: PASS - 同一シグネチャパターン
    - completeness: PASS - それぞれ a - b, a * b を返す
  - validated: 2026-01-01T21:22:00Z

- [x] **p2.4**: divide(a, b) 関数がゼロ除算エラーを throw する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - throw new Error 確認
    - consistency: PASS - if (b === 0) でチェック
    - completeness: PASS - 'Division by zero' メッセージ
  - validated: 2026-01-01T21:22:00Z

**status**: done
**max_iterations**: 5

---

### p3: テストの実装

**goal**: 全関数のテストを Jest で実装する
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: .tmp/calculator/src/calculator.test.ts が存在する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - ファイル作成完了
    - consistency: PASS - src/ 内に配置
    - completeness: PASS - describe/it 構文使用
  - validated: 2026-01-01T21:25:00Z

- [x] **p3.2**: add 関数のテストが存在する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - add テスト存在
    - consistency: PASS - toBe アサーション使用
    - completeness: PASS - 3 テストケース
  - validated: 2026-01-01T21:25:00Z

- [x] **p3.3**: subtract, multiply 関数のテストが存在する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - 両関数のテスト存在
    - consistency: PASS - 同一パターン
    - completeness: PASS - 各 3 テストケース
  - validated: 2026-01-01T21:25:00Z

- [x] **p3.4**: divide 関数のゼロ除算テストが存在する
  - executor: worker (codex-delegate)
  - validations:
    - technical: PASS - toThrow 使用
    - consistency: PASS - expect(() => divide(1, 0)).toThrow('Division by zero')
    - completeness: PASS - 正常系 3 + エラー系 1
  - validated: 2026-01-01T21:25:00Z

- [x] **p3.5**: npm test が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: PASS - exit 0、13 tests passed
    - consistency: PASS - 全テスト PASS
    - completeness: PASS - 4 関数全てテスト済み
  - validated: 2026-01-01T21:25:00Z

**status**: done
**max_iterations**: 5

---

### p4: コードレビュー

**goal**: 実装コードの品質を検証する
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: コードレビューが完了している
  - executor: reviewer (coderabbit CLI 手動実行)
  - validations:
    - technical: PASS - coderabbit review --type uncommitted --plain 実行完了
    - consistency: PASS - 2件の改善提案（命名規約、状態同期）
    - completeness: PASS - セキュリティ問題なし
  - validated: 2026-01-01T21:28:00Z
  - review_output: |
      1. done_when → done_criteria に命名変更推奨
      2. state.md の phase フィールドを p4 に更新推奨
  - discovery: |
      **重要な発見**: coderabbit-delegate SubAgent が存在しない
      - codex には codex-delegate SubAgent がある
      - coderabbit には相当するものがない
      - 現在は CLI 手動実行または GitHub App（PR時）のみ

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全項目を検証する
**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: ..tmp/calculator/package.json が存在する
  - executor: claudecode
  - validations:
    - technical: PASS - ファイル存在確認
    - consistency: PASS - 有効な JSON
    - completeness: PASS - name, version, scripts, devDependencies 含む
  - validated: 2026-01-01T21:30:00Z
  - note: tmp/ → .tmp/ に変更（前回 playbook の ft3 でクリーンアップされたため）

- [x] **p_final.2**: ..tmp/calculator/src/calculator.ts に add, subtract, multiply, divide 関数が存在する
  - executor: claudecode
  - validations:
    - technical: PASS - 4 関数全て存在
    - consistency: PASS - 全て export されている
    - completeness: PASS - ゼロ除算チェック含む
  - validated: 2026-01-01T21:30:00Z

- [x] **p_final.3**: npm test が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: PASS - exit 0、13 tests passed
    - consistency: PASS - 全テスト PASS
    - completeness: PASS - 4 関数全てテスト済み
  - validated: 2026-01-01T21:30:00Z

- [x] **p_final.4**: divide(1, 0) がエラーを throw するテストが PASS する
  - executor: claudecode
  - validations:
    - technical: PASS - "should throw error on division by zero" テスト PASS
    - consistency: PASS - Error('Division by zero') メッセージ
    - completeness: PASS - 正常系 + エラー系テスト完備
  - validated: 2026-01-01T21:30:00Z

**status**: done

### 検証で発見された重要な問題点

```yaml
issue_1:
  title: coderabbit-delegate SubAgent が存在しない
  severity: high
  description: |
    codex には codex-delegate SubAgent があり、playbook の executor: worker 時に
    自動的に委譲される仕組みがある。

    しかし coderabbit には相当する SubAgent がない。
    現在の選択肢:
      1. coderabbit review CLI を手動実行
      2. PR 作成後の GitHub App 自動レビュー

    executor: reviewer (coderabbit) が playbook で指定されても、
    自動化されたフローがない。

issue_2:
  title: tmp/ ディレクトリが playbook 間で競合
  severity: medium
  description: |
    前回の playbook の ft3 で tmp/ がクリーンアップされ、
    今回の playbook で作成したファイルが消失した。

    対策: .tmp/ を使用（.gitignore で保護）
```
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: .tmp/ 内のため repository-map.yaml 更新は不要
  - command: `echo ".tmp/ は .gitignore のため更新不要"`
  - status: done
  - validated: 2026-01-01T21:31:00Z

- [x] **ft2**: ..tmp/calculator/ のファイルは保持（電卓プログラムとして使用可能）
  - command: `ls ..tmp/calculator/`
  - status: done
  - validated: 2026-01-01T21:31:00Z

- [x] **ft3**: playbook 完了を確認
  - command: `echo "playbook 完了"`
  - status: done
  - validated: 2026-01-01T21:31:00Z

---

## 検証結果サマリー

### オーケストレーション動作確認

| Phase | executor | 解決先 | 動作 | 結果 |
|-------|----------|--------|------|------|
| p1 | claudecode | - | 直接実行 | ✓ |
| p2 | worker | codex | codex-delegate 自動委譲 | ✓ |
| p3 | worker | codex | codex-delegate 自動委譲 | ✓ |
| p4 | reviewer | coderabbit | **手動 CLI 実行** | ⚠️ |
| p_final | claudecode | - | 直接実行 | ✓ |

### 発見された問題

1. **coderabbit-delegate SubAgent が存在しない** (severity: high)
   - codex は自動化されているが、coderabbit は手動実行が必要
   - executor: reviewer が playbook で指定されても自動フローがない

2. **tmp/ ディレクトリ競合** (severity: medium)
   - playbook 間で tmp/ がクリーンアップされファイル消失
   - 対策: .tmp/ 使用

### 推奨アクション

```yaml
recommendation_1:
  title: coderabbit-delegate SubAgent の作成
  priority: high
  description: |
    codex-delegate と同様に、coderabbit CLI をラップする
    SubAgent を作成し、executor: reviewer/coderabbit 時に
    自動的にレビューを実行できるようにする。

recommendation_2:
  title: tmp/ クリーンアップの改善
  priority: medium
  description: |
    ft3 の tmp/ クリーンアップを .tmp/ に変更するか、
    playbook 固有のサブディレクトリを使用する。
```
