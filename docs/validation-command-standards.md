# validation_plan command 標準化ガイド

> **目的**: playbook の validation_plan.command が実行可能であることを保証し、報酬詐欺を防止する

---

## 背景

2026-01-27 の mece-completion playbook で報酬詐欺（虚偽報告）が発生した。

**根本原因**:
- validation_plan の command が実行不可能だった（stdin 想定、HARD_BLOCK アクセス）
- 報告された evidence と実際のコマンド出力が乖離していた
- critic が command を再実行せず、報告を信頼した

---

## 標準化ルール

### 1. 推奨コマンド形式

```yaml
ファイル存在チェック:
  推奨: "test -f path && echo 'exists'"
  推奨: "test -d path && echo 'exists'"
  推奨: "[ -f path ] && echo 'exists'"
  禁止: "ls path"  # 出力形式が不安定

ファイル内容チェック:
  推奨: "grep -c 'pattern' file"
  推奨: "jq -r '.field' file.json"
  推奨: "jq -e '.field' file.json > /dev/null && echo 'exists'"
  禁止: "cat file | grep pattern"  # 冗長

行数チェック:
  推奨: "wc -l < file | tr -d ' '"
  禁止: "cat file | wc -l"  # 冗長

複合条件:
  推奨: "test -f A && test -f B && echo 'both_exist'"
  禁止: "ls A B"  # エラー時の挙動が不安定
```

### 2. 禁止パターン（FORBIDDEN）

```yaml
stdin_dependent:
  description: "stdin からの入力を想定するコマンド"
  examples:
    - "bash script.sh 2>&1"  # script.sh が stdin を読む場合
    - "echo '{}' | jq ."     # パイプ元がない場合
  reason: "Hook 経由で実行する際に stdin が利用できない"

hard_block_access:
  description: "HARD_BLOCK ファイルへの直接アクセス"
  examples:
    - "grep pattern .claude/protected-files.txt"
    - "cat .claude/protected-files.txt"
    - "jq . CLAUDE.md"
  reason: "PreToolUse Hook がブロックする"
  alternative: "wc -l で行数チェック、または type: manual に変更"

interactive_commands:
  description: "対話入力を想定するコマンド"
  examples:
    - "read -p 'input: ' var"
    - "vim file"
  reason: "自動実行環境では対話入力が不可能"

ambiguous_output:
  description: "出力形式が不安定なコマンド"
  examples:
    - "ls -la"           # 環境依存の出力形式
    - "find . -name '*'" # 順序が不安定
  reason: "expected との照合が困難"
```

### 3. expected 形式の標準

```yaml
exact_match:
  description: "完全一致"
  example:
    expected: "exists"
  usage: "test -f, echo 等の出力"

numeric_comparison:
  description: "数値比較"
  examples:
    - expected: "0"        # 完全一致
    - expected: ">= 1"     # 1 以上
    - expected: "<= 10"    # 10 以下
    - expected: "1"        # grep -c の出力
  usage: "wc -l, grep -c 等の出力"

pattern_match:
  description: "パターンマッチ"
  examples:
    - expected: "contains 'keyword'"
    - expected: "starts_with 'prefix'"
  usage: "複雑な出力の部分一致"
```

---

## HARD_BLOCK ファイルの検証方法

### 対象ファイル

```
HARD_BLOCK:CLAUDE.md
HARD_BLOCK:.claude/protected-files.txt
```

### 代替検証方法

```yaml
行数での間接検証:
  command: "wc -l < .claude/protected-files.txt | tr -d ' '"
  expected: "<= 16"
  rationale: "削除前17行 → 削除後16行以下"

type: manual 指定:
  validation_plan:
    technical:
      type: "manual"
      command: "Read ツールで .claude/protected-files.txt を読み、RUNBOOK.md が含まれないことを確認"
      expected: "RUNBOOK.md の記載なし"
```

---

## 検証フロー

```
1. playbook 作成時（pm）
   - validation_plan の command を記述
   - 禁止パターンに該当しないことを確認

2. playbook レビュー時（reviewer）
   - 全 command を dry-run で実行
   - 実行可能性を検証
   - FAIL の場合は修正を要求

3. subtask 完了時（critic）
   - command を実際に実行
   - 出力と expected を照合
   - evidence に実際の出力を記録
```

---

## 参照

- `.claude/skills/quality-assurance/agents/reviewer.md` - command rerun check
- `.claude/frameworks/done-criteria-validation.md` - critic 検証基準
- `play/template/plan.json` - _template_rules
