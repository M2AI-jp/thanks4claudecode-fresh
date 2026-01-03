# playbook-password-generator-cli.md

> **TypeScript でパスワードジェネレーター CLI を作成する**

---

## meta

```yaml
project: password-generator-cli
branch: feat/password-generator-cli
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: TypeScript でパスワードジェネレーター CLI を作成する
done_when:
  - R1: tmp/password-generator/ ディレクトリが存在する
  - R2: npm run gen が 16 文字のパスワードを出力する
  - R3: npm run gen -- --length 8 が 8 文字のパスワードを出力する
  - R4: npm run gen -- --no-symbols が記号なしパスワードを出力する
  - R5: npm run gen -- --no-numbers が数字なしパスワードを出力する
  - R6: エントロピー（ビット数）が正しく計算・表示される
```

---

## context

```yaml
5w1h:
  who: 開発者（コマンドラインから実行）
  what: TypeScript でパスワードジェネレーター CLI を作成する
  when: 今回のセッションで完了
  where: tmp/password-generator/ に新規作成
  why: CLI ツール開発練習
  how: TypeScript + Node.js、crypto.randomBytes で暗号学的に安全な乱数を生成

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03
  summary: |
    - エントロピー表示: シンプルに "Password: Xy7!kL2m (52.4 bits)" 形式（1行）
    - 文字セット: 大小英字 + 数字 + 記号(!@#$%^&*()_+-=[]{}|;:,.<>?)
    - crypto.randomBytes を使用して暗号学的に安全な乱数を生成
```

---

## phases

### p1: 環境構築

**goal**: TypeScript プロジェクトの初期セットアップ

#### subtasks

- [ ] **p1.1**: tmp/password-generator/ ディレクトリが存在する
  - executor: claudecode
  - validations:
    - technical: "test -d tmp/password-generator でディレクトリ存在を確認"
    - consistency: "tmp/ フォルダ内に配置されていることを確認"
    - completeness: "ディレクトリが作成されている"

- [ ] **p1.2**: package.json が存在し、gen スクリプトが定義されている
  - executor: claudecode
  - validations:
    - technical: "test -f package.json && grep 'gen' package.json で確認"
    - consistency: "TypeScript プロジェクトとして適切な構成"
    - completeness: "name, scripts.gen, dependencies が含まれている"

- [ ] **p1.3**: tsconfig.json が存在し、コンパイル可能な状態である
  - executor: claudecode
  - validations:
    - technical: "test -f tsconfig.json で存在確認"
    - consistency: "ES モジュール設定が適切"
    - completeness: "必要なコンパイラオプションが全て含まれている"

**status**: pending
**max_iterations**: 5

---

### p2: TypeScript 実装

**goal**: パスワードジェネレーターのコア実装

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: src/index.ts が存在し、CLI エントリーポイントとして機能する
  - executor: codex
  - validations:
    - technical: "test -f src/index.ts でファイル存在確認"
    - consistency: "package.json の gen スクリプトと整合"
    - completeness: "CLI 引数パースと出力が実装されている"

- [ ] **p2.2**: crypto.randomBytes を使用した暗号学的に安全な乱数生成が実装されている
  - executor: codex
  - validations:
    - technical: "grep 'crypto' src/index.ts で crypto モジュール使用を確認"
    - consistency: "Node.js 標準の crypto モジュールを使用"
    - completeness: "Math.random ではなく crypto.randomBytes を使用"

- [ ] **p2.3**: --length オプションでパスワード長を指定できる
  - executor: codex
  - validations:
    - technical: "grep 'length' src/index.ts でオプション実装を確認"
    - consistency: "デフォルト値 16 が設定されている"
    - completeness: "--length {N} 形式で動作する"

- [ ] **p2.4**: --no-symbols オプションで記号を除外できる
  - executor: codex
  - validations:
    - technical: "grep 'no-symbols' src/index.ts でオプション実装を確認"
    - consistency: "記号文字セット !@#$%^&*()_+-=[]{}|;:,.<>? が定義されている"
    - completeness: "オプション指定時に記号が含まれない"

- [ ] **p2.5**: --no-numbers オプションで数字を除外できる
  - executor: codex
  - validations:
    - technical: "grep 'no-numbers' src/index.ts でオプション実装を確認"
    - consistency: "数字文字セット 0-9 が定義されている"
    - completeness: "オプション指定時に数字が含まれない"

- [ ] **p2.6**: エントロピー計算が実装されている
  - executor: codex
  - validations:
    - technical: "grep 'entropy\\|log2\\|Math.log' src/index.ts でエントロピー計算を確認"
    - consistency: "エントロピー = length * log2(charset_size) の計算式"
    - completeness: "小数点1桁で表示される"

**status**: pending
**max_iterations**: 5

---

### p3: 動作確認

**goal**: CLI の動作確認とビルド

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: npm run gen が 16 文字のパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen を実行し、16 文字のパスワードが出力されることを確認"
    - consistency: "デフォルト動作として 16 文字が出力される"
    - completeness: "エントロピーも同時に表示される"

- [ ] **p3.2**: npm run gen -- --length 8 が 8 文字のパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --length 8 を実行し、8 文字のパスワードが出力されることを確認"
    - consistency: "--length オプションが正しく動作する"
    - completeness: "エントロピーも正しく計算される"

- [ ] **p3.3**: npm run gen -- --no-symbols が記号なしパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --no-symbols を実行し、記号が含まれないことを確認"
    - consistency: "記号文字が一切含まれていない"
    - completeness: "英字と数字のみで構成される"

- [ ] **p3.4**: npm run gen -- --no-numbers が数字なしパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --no-numbers を実行し、数字が含まれないことを確認"
    - consistency: "数字が一切含まれていない"
    - completeness: "英字と記号のみで構成される"

**status**: pending
**max_iterations**: 5

---

### p_review: コードレビュー

**goal**: CodeRabbit によるコードレビュー

**depends_on**: [p3]

#### subtasks

- [ ] **p_review.1**: CodeRabbit レビューが完了している
  - executor: coderabbit
  - validations:
    - technical: "coderabbit-delegate でレビュー実行"
    - consistency: "レビュー対象が実装内容と一致"
    - completeness: "全変更ファイルがレビュー対象"

**status**: pending
**max_iterations**: 3

---

### p_fix: レビュー指摘対応

**goal**: レビュー指摘の修正またはダブルチェック

**depends_on**: [p_review]

#### subtasks

- [ ] **p_fix.1**: レビュー指摘が全て対応済み、または指摘なしの場合はダブルチェック完了
  - executor: codex
  - validations:
    - technical: |
        Critical/Major 指摘: 全て修正済み
        Minor 指摘: 修正または理由付きスキップ
        指摘なし: 実装の再確認（ダブルチェック）
    - consistency: "修正内容が元の要件と整合"
    - completeness: "全指摘に対応済み"

- [ ] **p_fix.2**: 修正後の再レビューが PASS（Critical/Major があった場合）
  - executor: coderabbit
  - validations:
    - technical: "再レビューで Critical/Major が 0"
    - consistency: "修正が適切に反映"
    - completeness: "新たな問題が発生していない"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p_fix]

#### subtasks

- [ ] **p_final.1**: tmp/password-generator/ ディレクトリが存在する
  - executor: claudecode
  - validations:
    - technical: "test -d tmp/password-generator で存在確認"
    - consistency: "tmp/ フォルダ内に配置されている"
    - completeness: "必要なファイルが全て含まれている"

- [ ] **p_final.2**: npm run gen が 16 文字のパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen を実行し、16 文字のパスワードが出力されることを確認"
    - consistency: "Password: {16文字} ({bits} bits) 形式で出力される"
    - completeness: "エントロピーが正しく計算されている"

- [ ] **p_final.3**: npm run gen -- --length 8 が 8 文字のパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --length 8 を実行し、8 文字のパスワードが出力されることを確認"
    - consistency: "指定した長さのパスワードが出力される"
    - completeness: "エントロピーが正しく計算されている"

- [ ] **p_final.4**: npm run gen -- --no-symbols が記号なしパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --no-symbols を実行し、記号が含まれないことを確認"
    - consistency: "英字と数字のみで構成される"
    - completeness: "エントロピーが文字セットに基づき計算されている"

- [ ] **p_final.5**: npm run gen -- --no-numbers が数字なしパスワードを出力する
  - executor: claudecode
  - validations:
    - technical: "npm run gen -- --no-numbers を実行し、数字が含まれないことを確認"
    - consistency: "英字と記号のみで構成される"
    - completeness: "エントロピーが文字セットに基づき計算されている"

- [ ] **p_final.6**: エントロピー（ビット数）が正しく計算・表示される
  - executor: claudecode
  - validations:
    - technical: "エントロピー = length * log2(charset_size) の計算結果を確認"
    - consistency: "小数点1桁で表示される"
    - completeness: "全オプション組み合わせで正しく計算される"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' ! -path 'tmp/password-generator/*' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
