# Test Scenarios

> **Hooks / SubAgents / Skills の統合テストシナリオ**

## 使い方（Usage）

### 1. シナリオの構造

各シナリオは以下の形式で定義されています：

```markdown
## Hook: {hook-name}

**Trigger:** {発火条件}
**Expected:** {期待動作}
**Verify:** {検証方法}
```

### 2. 手動テスト

1. 対象シナリオを選択
2. Trigger 条件を再現
3. Expected 動作を確認
4. Verify 方法で検証

### 3. 自動テスト（Codex）

```bash
# Codex で自動実行
./test/scripts/codex-runner.sh test/scenarios/hooks.md
```

---

## ファイル一覧

| ファイル | 内容 | 数 |
|----------|------|-----|
| hooks.md | Hook テストシナリオ | 29個 |
| subagents.md | SubAgent テストシナリオ | 10種類 |
| skills.md | Skill テストシナリオ | 10個 |

---

## MECE 分類基準

### Hooks（発火タイミング別）

1. **SessionStart** - セッション開始時
2. **UserPromptSubmit** - ユーザープロンプト送信時
3. **PreToolUse** - ツール実行前
4. **PostToolUse** - ツール実行後
5. **SessionEnd** - セッション終了時
6. **Stop** - エージェント停止時
7. **PreCompact** - コンパクト前

### SubAgents（責務別）

1. **計画系** - pm, plan-guard
2. **検証系** - critic, reviewer
3. **支援系** - Explore, setup-guide, health-checker, claude-code-guide
4. **外部連携系** - codex, coderabbit

### Skills（機能別）

1. **状態管理** - state, plan-management
2. **品質管理** - lint-checker, test-runner, deploy-checker
3. **学習系** - learning
4. **プロセス系** - consent-process, context-externalization, post-loop, context-management

---

## 検証結果の記録先

- `test/results/hooks-results.md`
- `test/results/subagents-results.md`
- `test/results/skills-results.md`
- `test/results/summary.md`
