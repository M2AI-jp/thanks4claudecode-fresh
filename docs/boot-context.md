# Boot Context（ブートコンテキスト）

> セッション開始時に必ず読むべき最小限の情報

---

## 概要

このファイルは Claude がセッション開始時に最初に読むべきエントリポイントである。
複雑な CLAUDE.md を全て読む代わりに、このファイルから必要な情報に辿り着ける。

---

## 必須読み込み（3ファイル）

1. **state.md** - 現在地（Single Source of Truth）
   - focus.current: 今何をしているか
   - playbook.active: 現在の計画
   - goal.milestone: 現在の目標

2. **plan/project.md** - プロジェクト全体像
   - vision: 最終目標
   - milestones: 中間目標リスト

3. **現在の playbook**（state.md の playbook.active）
   - phases: 作業フェーズ
   - done_criteria: 完了条件

---

## 作業フロー

```
1. state.md を読む
2. focus.current を確認
3. playbook.active を確認
   - null → pm SubAgent で playbook 作成
   - あり → playbook を読んで作業開始
4. LOOP: phase ごとに実行 → 完了 → 次へ
```

---

## 重要なルール（要約）

- **main ブランチで作業禁止**: まずブランチを切る
- **playbook なしで Edit/Write 禁止**: 計画駆動
- **保護ファイル編集禁止**: CLAUDE.md, state.md の一部

---

## 詳細ドキュメントへの参照

| 詳細が必要な時 | 参照先 |
|---------------|--------|
| セキュリティモード | docs/security-modes.md |
| コンポーネント分類 | docs/component-taxonomy.md |
| フレームワーク/プロダクト分離 | docs/product-vs-framework.md |
| Hook 責任分担 | docs/hook-responsibilities.md |
| Single Source of Truth | docs/single-source-of-truth.md |
| 行動ルール全文 | CLAUDE.md |

---

## [自認] テンプレート

```
[自認]
what: {focus.current}
milestone: {goal.milestone}
phase: {goal.phase}
branch: {git branch 名}
playbook: {playbook.active}
```

---

## クイックリファレンス

```bash
# 状態確認
cat state.md

# プロジェクト確認
cat plan/project.md

# 現在の playbook 確認
cat $(grep "active:" state.md | awk '{print $2}')

# ブランチ確認
git branch --show-current

# 健全性チェック
bash .claude/hooks/system-health-check.sh
```

---

## このファイルの位置づけ

- **最初に読む**: session-start.sh で案内される
- **毎セッション必須**: init-guard.sh で強制（予定）
- **軽量**: 100行以内を維持
