# Linter/Formatter 設定テンプレート

> **言語別デファクトスタンダードの設定ファイルテンプレート**
>
> setup/playbook-setup.md Phase 5-A で使用

---

## 1. 言語別デファクト一覧

| 言語 | Linter | Formatter | 設定ファイル |
|------|--------|-----------|-------------|
| JavaScript/TypeScript | ESLint | Prettier | .eslintrc.js, .prettierrc |
| Python | Ruff | Ruff | pyproject.toml |
| Shell | ShellCheck | shfmt | .shellcheckrc |
| Go | golangci-lint | gofmt | .golangci.yml |
| Rust | clippy | rustfmt | rustfmt.toml |
| Markdown | markdownlint | - | .markdownlint.json |

---

## 2. JavaScript/TypeScript

### 2.1 ESLint (.eslintrc.js)

```javascript
module.exports = {
  root: true,
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'next/core-web-vitals',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
  },
};
```

### 2.2 Prettier (.prettierrc)

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

### 2.3 インストールコマンド

```bash
# Next.js プロジェクトの場合（ESLint は create-next-app で含まれる）
pnpm add -D prettier eslint-config-prettier
```

---

## 3. Python

### 3.1 Ruff (pyproject.toml)

```toml
[tool.ruff]
# Linter
select = ["E", "F", "W", "I", "UP", "B", "SIM", "C90"]
ignore = ["E501"]  # line-too-long は formatter に任せる
line-length = 100
target-version = "py311"

# Formatter
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### 3.2 インストールコマンド

```bash
pip install ruff
# または
brew install ruff
```

---

## 4. Shell

### 4.1 ShellCheck (.shellcheckrc)

```ini
# SC2086: Double quote to prevent globbing and word splitting
# SC2155: Declare and assign separately
disable=SC2086,SC2155
shell=bash
```

### 4.2 shfmt 設定

```bash
# インデント 2 スペース、POSIX 互換
shfmt -i 2 -ci -w .claude/hooks/*.sh
```

### 4.3 インストールコマンド

```bash
brew install shellcheck shfmt
```

---

## 5. Go

### 5.1 golangci-lint (.golangci.yml)

```yaml
run:
  timeout: 5m

linters:
  enable:
    - gofmt
    - govet
    - errcheck
    - staticcheck
    - gosimple
    - ineffassign
    - unused

linters-settings:
  gofmt:
    simplify: true
```

### 5.2 インストールコマンド

```bash
brew install golangci-lint
# gofmt は Go に含まれる
```

---

## 6. Rust

### 6.1 rustfmt (rustfmt.toml)

```toml
edition = "2021"
max_width = 100
tab_spaces = 4
use_small_heuristics = "Default"
```

### 6.2 インストールコマンド

```bash
rustup component add rustfmt clippy
```

---

## 7. Markdown

### 7.1 markdownlint (.markdownlint.json)

```json
{
  "default": true,
  "MD013": false,
  "MD033": false,
  "MD041": false
}
```

### 7.2 インストールコマンド

```bash
npm install -g markdownlint-cli
# または
brew install markdownlint-cli
```

---

## 8. pre-commit 統合

### 8.1 .pre-commit-config.yaml

```yaml
repos:
  # JavaScript/TypeScript
  - repo: local
    hooks:
      - id: eslint
        name: ESLint
        entry: pnpm eslint --fix
        language: system
        files: \.(js|jsx|ts|tsx)$
        pass_filenames: false

      - id: prettier
        name: Prettier
        entry: pnpm prettier --write
        language: system
        files: \.(js|jsx|ts|tsx|json|md|css)$

  # Shell
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
        args: [--severity=warning]

  # Python
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  # Markdown
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.38.0
    hooks:
      - id: markdownlint
        args: [--fix]
```

### 8.2 インストールコマンド

```bash
pip install pre-commit
pre-commit install
```

---

## 9. VSCode 統合

### 9.1 .vscode/settings.json

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  },
  "eslint.validate": ["javascript", "javascriptreact", "typescript", "typescriptreact"]
}
```

### 9.2 推奨拡張機能 (.vscode/extensions.json)

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "charliermarsh.ruff",
    "timonwong.shellcheck",
    "foxundermoon.shell-format",
    "DavidAnson.vscode-markdownlint"
  ]
}
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。6言語のデファクト Linter/Formatter を網羅。 |
