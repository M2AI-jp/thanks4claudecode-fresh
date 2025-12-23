# Artifact Management Rules

> **目的**: 「仕組みとして参照されないファイル」が生成されないようにルール化
>
> **作成日**: 2025-12-09
> **playbook**: playbook-artifact-health.md p10

---

## 1. ファイル生成時の判定基準

### 1.1 「このファイルは future に参照されるか？」

```yaml
ファイル作成前に自問:
  1. このファイルは state.md/CLAUDE.md から参照されるか？
  2. このファイルは他のファイルに統合されるか？
  3. このファイルは playbook 完了後も保持する価値があるか？

判定結果:
  - 参照される → 最終成果物として作成
  - 統合される → 中間成果物として作成（クリーンアップ必須）
  - どちらでもない → 作成しない
```

### 1.2 ファイル種別と処理

| 種別 | 説明 | 処理 |
|------|------|------|
| 最終成果物 | タスク完了後も保持 | 保持 |
| 中間成果物 | 統合後に不要 | 統合後削除 |
| テンプレート | 再利用される | 保持 |
| 一時ファイル | 作業中のみ使用 | 即時削除 |

---

## 2. 削除 vs アーカイブの判定フロー

```
ファイル処理の判定:
                    ┌─────────────────┐
                    │ ファイル不要    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ 将来の参照可能性 │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │ あり          │ なし         │
              ▼              ▼              │
    ┌─────────────────┐  ┌─────────────────┐
    │ アーカイブ       │  │ 削除           │
    │ → .archive/     │  │ → rm           │
    └─────────────────┘  └─────────────────┘
```

### 具体例

```yaml
アーカイブ対象:
  - 完了した playbook（過去の計画として参照可能）
  - 古いバージョンのドキュメント（履歴として保持）
  - 実験的な実装（将来の参考になる可能性）

削除対象:
  - 統合済みの中間成果物（phase-*.md、draft-*.md）
  - 重複ファイル
  - 一時ファイル（*.tmp、*.bak）
```

---

## 3. Phase ファイル生成の禁止ルール

### 3.1 禁止パターン

```yaml
禁止:
  - Phase ごとに phase-{n}-{name}.md を作成して最後に統合
  - 中間ファイルを作成してクリーンアップしない

理由:
  - playbook-current-implementation-redesign で 7 件の phase-*.md が残存
  - 統合後のクリーンアップが忘れられやすい
```

### 3.2 推奨パターン

```yaml
推奨:
  - 既存ファイルに直接追記（docs/*.md に追記）
  - 中間成果物が必要な場合:
    - ファイル名に「draft-」または「temp-」プレフィックス
    - 最終 Phase の done_criteria に「中間成果物が削除されている」を含める

playbook 作成時のチェック:
  - pm.md ステップ 5.5 で中間成果物を確認
  - playbook-format.md「中間成果物の処理」セクションを参照
```

---

## 4. state.md active_playbooks の更新ルール

### 4.1 タイミング

| イベント | 更新内容 |
|---------|---------|
| playbook 作成時 | active_playbooks.{layer} に path を設定 |
| playbook 完了時 | active_playbooks.{layer} を null に設定 |
| playbook アーカイブ時 | 変更なし（完了時に null 済み） |

### 4.2 整合性チェック

```yaml
常に真であるべき条件:
  - playbook.active に設定されている playbook は plan/ に存在する
  - plan/ の playbook は全 Phase done でない（進行中）
  - plan/archive/ の playbook は全 Phase done（完了済み）

不整合発生時:
  - health-checker SubAgent で検出
  - 手動修正または自動修正を実行
```

---

## 5. 参照ドキュメント

| ドキュメント | 内容 |
|------------|------|
| docs/archive-operation-rules.md | アーカイブ運用ルール |
| docs/file-creation-process-design.md | ファイル作成プロセス設計 |
| plan/template/playbook-format.md | playbook テンプレート（中間成果物の処理を含む） |
| .claude/agents/pm.md | pm SubAgent（ステップ 5.5 中間成果物確認） |
| CLAUDE.md POST_LOOP | アーカイブ実行（行動 0.5） |

---

## 6. チェックリスト

### playbook 作成時

- [ ] Phase で作成するファイルをリストアップしたか？
- [ ] 中間成果物があれば最終 Phase にクリーンアップを含めたか？
- [ ] done_criteria に「中間成果物が削除されている」を含めたか？

### playbook 完了時

- [ ] 全 Phase が done か？
- [ ] archive-playbook.sh の提案が出力されたか？
- [ ] POST_LOOP でアーカイブを実行したか？
- [ ] state.md active_playbooks を null に更新したか？

### 定期的なヘルスチェック

- [ ] plan/ に完了済み playbook がないか？
- [ ] plan/ に stray files（phase-*.md 等）がないか？
- [ ] state.md と plan/ の整合性は取れているか？

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。playbook-artifact-health.md p10 で再発防止ルールを文書化。 |
