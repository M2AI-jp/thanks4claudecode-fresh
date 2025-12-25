# playbook-login-darkmode.md

> **tmp/ フォルダにログイン画面 + ダークモード切り替えボタンを作成**

---

## meta

```yaml
project: login-darkmode
branch: feat/login-darkmode
created: 2025-12-25
issue: null
reviewed: true
roles:
  worker: claudecode  # シンプルな HTML/CSS/JS なので claudecode で実装
```

---

## goal

```yaml
summary: tmp/ に HTML + CSS + JS でログイン画面とダークモード切り替え機能を実装する
done_when:
  - tmp/login-demo/index.html が存在する
  - ログインフォーム（ID/パスワード入力欄、ログインボタン）が表示される
  - ダークモード切り替えボタンが動作する（クリックでテーマが切り替わる）
```

---

## phases

### p1: ファイル構造作成

**goal**: tmp/login-demo/ ディレクトリと基本ファイルを作成

#### subtasks

- [ ] **p1.1**: tmp/login-demo/ ディレクトリが存在する
  - executor: claudecode
  - validations:
    - technical: "test -d tmp/login-demo でディレクトリ存在を確認"
    - consistency: "tmp/ フォルダ内に配置されている"
    - completeness: "ディレクトリが作成されている"

- [ ] **p1.2**: tmp/login-demo/index.html が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/login-demo/index.html でファイル存在を確認"
    - consistency: "HTML5 DOCTYPE が含まれている"
    - completeness: "基本的な HTML 構造が含まれている"

- [ ] **p1.3**: tmp/login-demo/style.css が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/login-demo/style.css でファイル存在を確認"
    - consistency: "index.html から参照されている"
    - completeness: "CSS ファイルが作成されている"

- [ ] **p1.4**: tmp/login-demo/script.js が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/login-demo/script.js でファイル存在を確認"
    - consistency: "index.html から参照されている"
    - completeness: "JS ファイルが作成されている"

**status**: pending
**max_iterations**: 5

---

### p2: ログインフォーム実装

**goal**: ログインフォームの UI を実装する
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: index.html にログインフォームが含まれている
  - executor: claudecode
  - validations:
    - technical: "grep で form, input type='text', input type='password', button を確認"
    - consistency: "フォーム要素が適切にマークアップされている"
    - completeness: "ID入力、パスワード入力、ログインボタンが含まれている"

- [ ] **p2.2**: style.css にログインフォームのスタイルが定義されている
  - executor: claudecode
  - validations:
    - technical: "grep で .login-form, .login-button 等のセレクタを確認"
    - consistency: "ライトモード用のスタイルが定義されている"
    - completeness: "フォーム要素全てにスタイルが適用されている"

**status**: pending
**max_iterations**: 5

---

### p3: ダークモード実装

**goal**: ダークモード切り替え機能を実装する
**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: index.html にダークモード切り替えボタンが含まれている
  - executor: claudecode
  - validations:
    - technical: "grep で dark-mode-toggle または同等の要素を確認"
    - consistency: "ボタンがアクセシブルである（aria-label 等）"
    - completeness: "切り替えボタンが配置されている"

- [ ] **p3.2**: style.css にダークモード用の CSS 変数またはクラスが定義されている
  - executor: claudecode
  - validations:
    - technical: "grep で .dark-mode または :root のカラー変数を確認"
    - consistency: "ライトモードとダークモードの両方のスタイルが定義されている"
    - completeness: "背景色、テキスト色、ボタン色等が切り替わる"

- [ ] **p3.3**: script.js にテーマ切り替えロジックが実装されている
  - executor: claudecode
  - validations:
    - technical: "grep で classList.toggle または同等のロジックを確認"
    - consistency: "ボタンクリックでテーマが切り替わる"
    - completeness: "ダークモード状態が正しく反映される"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: tmp/login-demo/index.html が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/login-demo/index.html を実行して確認"
    - consistency: "ファイルパスが正しい"
    - completeness: "ファイルが存在する"

- [ ] **p_final.2**: ログインフォーム（ID/パスワード入力欄、ログインボタン）が表示される
  - executor: claudecode
  - validations:
    - technical: "grep で input type='text', input type='password', button を確認"
    - consistency: "HTML 構造が正しい"
    - completeness: "全てのフォーム要素が含まれている"

- [ ] **p_final.3**: ダークモード切り替えボタンが動作する（クリックでテーマが切り替わる）
  - executor: claudecode
  - validations:
    - technical: "script.js に切り替えロジックが存在することを確認"
    - consistency: "CSS にダークモードスタイルが定義されている"
    - completeness: "ボタン、CSS、JS が連携している"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-25 | 初版作成 |
