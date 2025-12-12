# Codex への評価依頼

> **削除候補コンポーネント・ドキュメントの第三者評価**

---

## 背景

thanks4claudecode プロジェクトは、Claude Code の自律性と品質を向上させるための Hooks/SubAgents/Skills フレームワークです。

現在、リポジトリをスリムアップするために、参照されないドキュメント・非Core Hooks/SubAgents/Skills を特定し、削除候補としてリスト化しました。

この削除候補について、**客観的で批判的な第三者視点**からの評価を求めます。

---

## 評価対象

### 削除予定ドキュメント（27ファイル）

`.archive/` に移動済み。以下の例：
- `.claude/CLAUDE-ref.md` - 旧 CLAUDE.md リファレンス
- `.claude/commands/` - 旧コマンド定義（crit.md, focus.md, lint.md など）
- `.claude/context/` - 旧コンテキストファイル
- `docs/artifact-management-rules.md` - 成果物管理ルール（現在は active-playbooks で代替）
- `docs/file-inventory.md` - ファイル棚卸し（obsolete）
- `plan/design/` - 旧計画設計ドキュメント（現在は playbook で代替）

**判定根拠**: tech-stack.md を除き参照されず、git log でも最近 1 ヶ月間参照なし。

---

### 削除候補 Hooks（評価済み）

p2 の評価により、以下が削除候補として特定されました：

| Hook | 削除理由 | 代替手段 |
|------|--------|----------|
| create-pr-hook.sh | PR 作成の Hook は実装済み | create-pr.sh の本体機能で対応 |
| state-guard.sh | state.md の監視 | session-start.sh + CLAUDE.md INIT で代替 |
| layer-transition-guard.sh | レイヤー遷移監視（旧用語） | playbook-guard.sh で代替 |

評価レポート: docs/hook-evaluation.md

---

### 削除候補 SubAgents（評価済み）

p3 の評価により、以下が削除候補として特定されました：

| SubAgent | 削除理由 | 代替手段 |
|----------|--------|----------|
| plan-guard.md | 計画整合性チェック（重複） | CLAUDE.md INIT + playbook-guard.sh で代替 |
| health-checker.md | システムヘルスチェック（重複） | system-health-check.sh（Hook）で代替 |

評価レポート: docs/subagent-evaluation.md

**Core SubAgents（保護対象）**:
- pm.md: playbook 作成・管理（必須）
- critic.md: Phase 完了判定（必須）

---

### 削除候補 Skills（評価済み）

p4 の評価により、以下が削除候補として特定されました：

| Skill | 削除理由 | 代替手段 |
|-------|--------|----------|
| execution-management | 複数タスク並列実行は未設計 | CLAUDE.md LOOP セクションで代替 |
| learning | エラー記録が本プロジェクトで最小 | ドキュメント記録で代替 |
| beginner-advisor | トリガー条件が実装されていない | ユーザー確認時に手動対応 |
| frontend-design | フロントエンド開発は対象外 | 別プロジェクトで別途実装 |
| state | 旧形式（layer）で新 3層構造と矛盾 | CLAUDE.md の state セクションで代替 |

評価レポート: docs/skill-evaluation.md

**Core Skill（保護対象）**:
- post-loop: playbook 完了後の自動処理（必須）

---

## 評価質問

Codex による第三者視点で、以下を評価してください：

### 1. 削除判定の妥当性

```
質問: 上記の削除候補（Hooks 3個、SubAgents 2個、Skills 5個）は、
     削除しても問題がないか？

評価視点:
  - 代替手段は機能的に十分か
  - 依存関係・副作用はないか
  - 将来のメンテナンス性に影響ないか
```

### 2. 見落とし・追加削除候補

```
質問: 削除すべき他のコンポーネント・ドキュメントはないか？

評価視点:
  - 実装が古い/矛盾している部分
  - 実装がされていない（定義のみ）部分
  - 依存関係が限定的な部分
```

### 3. 保持判定への懸念

```
質問: 保持推奨としたコンポーネント（Hooks, SubAgents, Skills）に対して、
     削除しても良い/改善が必要な部分があるか？

評価視点:
  - 実装が不完全でないか
  - 3層構造との矛盾がないか
  - 保守コストが高すぎないか
```

### 4. 全体的な改善提案

```
質問: コンポーネント・ドキュメント構成全体への改善提案があるか？

評価視点:
  - Core/非Core の境界は適切か
  - 保護対象の選定は正しいか
  - 新しく追加すべき Hooks/SubAgents/Skills があるか
```

---

## 補足資料

- **状況**: .archive/ に削除予定ファイルが移動済み
- **git status**: 27 ファイル削除、3 評価レポート作成（doc-reference-audit.md, hook-evaluation.md, subagent-evaluation.md）
- **プロジェクト状態**: M010 p5 実行中。前の Phase（p0-p4）は PASS で完了

---

## 出力形式

Codex の評価結果は以下の形式で`docs/codex-evaluation-report.md`に記載してください：

```
# Codex 第三者評価レポート

## 1. 削除判定の妥当性
- [評価内容]
- [改善提案]

## 2. 見落とし・追加削除候補
- [該当するコンポーネント]
- [削除理由]

## 3. 保持判定への懸念
- [懸念項目]
- [改善方針]

## 4. 全体的な改善提案
- [提案1]
- [提案2]

## 総合判定
- 削除予定リスト: 適切 / 要修正
- 改善優先度: 高 / 中 / 低
```

---

