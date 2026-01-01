# Multi-Language Pipeline Demo

Python → TypeScript パイプライン処理のデモ。オーケストレーション練習用。

## Prerequisites

- **Node.js**: >= 18.0.0 (LTS 推奨)
- **Python**: >= 3.8
- **bats-core**: 統合テスト用 (`brew install bats-core`)
- **shellcheck**: シェルスクリプト解析 (`brew install shellcheck`)
- **ruff**: Python linter (`pip install ruff`)
- **jq**: JSON processor (`brew install jq`) - テストで使用
- **eslint**: TypeScript linter (`npm install -g eslint`)
- **ts-node**: TypeScript 実行環境 (`npm install -g ts-node`)

### セットアップ

```bash
# プロジェクトルートで依存関係をインストール
npm install

# TypeScript 実行環境の確認
npx ts-node --version
```

## Files

| File | Language | Description |
|------|----------|-------------|
| `run.sh` | Bash | オーケストレーター。Python → TypeScript の順で処理を実行 |
| `process.py` | Python | Step 1: JSON 入力を加工（uppercase_input 追加） |
| `transform.ts` | TypeScript | Step 2: Python 出力を変換（reversed_input 追加） |

## Usage

```bash
# 基本実行
bash tmp/run.sh '{"input":"hello"}'

# デフォルト入力で実行
bash tmp/run.sh
```

## Output Example

```json
{
  "python_output": {
    "original": { "input": "hello" },
    "processed_by": "python",
    "timestamp": "2026-01-02T00:40:44.803820",
    "added_fields": { "uppercase_input": "HELLO", "step": 1 }
  },
  "processed_by": "typescript",
  "timestamp": "2026-01-01T15:40:46.101Z",
  "added_fields": {
    "step": 2,
    "reversed_input": "olleh",
    "input_length": 5
  }
}
```

## Testing

```bash
# 統合テスト
bats tests/tmp-run.bats
```

## Quality Checks

```bash
# 静的解析
shellcheck tmp/run.sh
ruff check tmp/process.py
npx eslint tmp/transform.ts
```

## Evidence

- Codex agentId: `a06e567` (transform.ts 作成)
- CodeRabbit review: `~/.coderabbit/logs/2026-01-01T14-47-52-887Z-...`
- Critic PASS: `.claude/logs/critic-results.log`
