---
name: post-loop
description: playbook 完了後の自動コミット、マージ、次タスク導出を実行。
---

# post-loop

> **POST_LOOP - playbook 完了後の自動処理**

---

## トリガー

playbook の全 Phase が done

---

## 行動

```yaml
# ============================================================
# M091: 処理順序修正
# milestone 更新を playbook アーカイブの前に移動
# 理由: playbook-guard は playbook.active=null で Edit をブロックするため、
#       project.md の milestone 更新は playbook.active が有効な間に実行する必要がある
# ============================================================

0. 自動コミット（最終 Phase 分）:
   - `git status --porcelain` で未コミット変更を確認
   - 変更あり → `git add -A && git commit -m "feat: {playbook 名} 完了"`
   - 変更なし → スキップ

1. project.milestone の自動更新（★M091: アーカイブ前に移動）:
   # 重要: playbook.active が有効な間に実行すること
   - playbook の meta.derives_from から milestone ID を読み込み
   - project.md の該当 milestone を検索
   - status: in_progress → status: achieved に更新
   - achieved_at: {現在日時} を追加
   - playbooks[] に playbook 名を追記
   - 実装方法：
     ```bash
     # 1. playbook から derives_from を抽出
     DERIVES_FROM=$(grep "^derives_from:" {playbook} | sed 's/derives_from: *//')

     # 2. project.md の該当 milestone を更新
     # YAML セクション更新（要 yq または sed）
     # - status: in_progress → status: achieved
     # - achieved_at: 日時を追加
     # - playbooks[] に playbook 名を追記
     ```

2. 完了 playbook のアーカイブ:
   # 注意: milestone 更新完了後に実行すること
   - archive-playbook.sh の提案が出力されている場合
   - 以下を実行:
     ```bash
     mkdir -p .archive/plan
     mv plan/playbook-{name}.md plan/archive/
     ```
   - state.md の playbook.active を null に更新
   - 注意: アーカイブ前に git add/commit を完了すること
   - 参照: docs/archive-operation-rules.md

3. GitHub PR 作成（★自動化済み）:
   - Hook: create-pr-hook.sh（PostToolUse:Edit で自動発火、settings.json 登録済み）
   - 本体: create-pr.sh（実際の PR 作成処理）
   - PR タイトル: feat({playbook}/{phase}): {goal summary}
   - PR 本文: done_when + done_criteria + completed phases
   - 条件分岐:
     - 成功: → PR マージへ進む
     - PR 既存: スキップ
     - 失敗: エラーログ出力、手動対応を促す

4. GitHub PR マージ（★自動化済み）:
   - スクリプト: .claude/hooks/merge-pr.sh
   - コマンド: gh pr merge --merge --auto --delete-branch
   - 条件分岐:
     - 成功: ブランチ削除 → main 同期 → 次タスク導出へ
     - Draft: エラー（gh pr ready で解除を促す）
     - コンフリクト: エラー（手動解決を促す）
     - 必須チェック未完了: --auto で待機
     - 失敗: エラーログ出力、手動対応を促す

5. /clear アナウンス:
   - playbook 完了時にユーザーに以下を案内:
     ```
     [playbook 完了]
     playbook-{name} が全 Phase 完了しました。

     コンテキスト使用率を確認し、必要に応じて /clear を実行してください。
     /context で確認 → /clear で リセット可能です。
     ```

6. 次タスクの導出（計画の連鎖）★pm 経由必須:
   - pm SubAgent を呼び出す
   - pm が project.md の not_achieved を確認
   - pm が depends_on を分析し、着手可能な done_when を特定
   - pm が decomposition を参照して新 playbook を作成

7. 残タスクあり:
   - ブランチ作成: `git checkout -b feat/{next-task}`
   - pm が playbook 作成: plan/playbook-{next-task}.md
   - pm が state.md 更新: playbook.active を更新
   - 即座に LOOP に入る

8. 残タスクなし:
   - 「全タスク完了。次の指示を待ちます。」
```

---

## git 自動操作

```yaml
Phase 完了: 自動コミット（critic PASS 後、LOOP 内で実行）
playbook 完了:
  - milestone 更新（POST_LOOP 行動 1: playbook.active 有効時に実行）
  - アーカイブ（POST_LOOP 行動 2: playbook.active = null 化）
  - PR 自動作成（POST_LOOP 行動 3: create-pr-hook.sh → create-pr.sh）
  - PR 自動マージ（POST_LOOP 行動 4: merge-pr.sh）
新タスク: 自動ブランチ（POST_LOOP 行動 6 で実行）
```

---

## 整合性チェック

```yaml
check-coherence.sh:
  - state.md と playbook の連動確認
  - branch と playbook の一致確認
  - focus.current との整合性確認
  - YAML コードブロックを正しくパース
```

---

## 禁止

```yaml
- 「報告して待つ」パターン（残タスクがあるのに止まる）
- ユーザーに「次は何をしますか？」と聞く
```
