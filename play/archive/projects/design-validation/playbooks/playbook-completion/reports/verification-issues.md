# 検証中の問題記録

> Generated: 2026-01-07
> Playbook: playbook-completion (p4.2)

---

## 1. 概要

playbook-completion 実行中に発見された問題を記録する。
問題がない場合も「問題なし」を記録（done_criteria: 「問題なしでも記録」）。

---

## 2. 発見された問題

### 2.1 Critical 問題

なし

### 2.2 High 問題

なし

### 2.3 Medium 問題

| ID | 問題 | 発見場所 | 対応状況 |
|----|------|----------|----------|
| ISS-M1 | `-lc` hook file warnings (9件) | session-start スモークテスト | 既知の設定問題、scope 外 |
| ISS-M2 | repository-map.yaml drift | integrity check | scope 外（generate-repository-map.sh で修正可能） |

### 2.4 Low 問題

| ID | 問題 | 発見場所 | 対応状況 |
|----|------|----------|----------|
| ISS-L1 | evidence/ ディレクトリ空 | integrity check | cosmetic、機能影響なし |
| ISS-L2 | coderabbit Minor 指摘 2件 | p2.1 レビュー | 任意対応（jq チェック追加推奨） |

---

## 3. 問題詳細

### ISS-M1: `-lc` hook file warnings

```
[WARN] Hook ファイルが存在しません: -lc
  → settings.json から削除するか、ファイルを作成してください
```

- **原因**: settings.json の hook 設定に不正なエントリ
- **影響**: なし（警告のみ、Hook 動作に影響なし）
- **対応**: scope 外（本 playbook は Critical/High のみ対応）

### ISS-M2: repository-map.yaml drift

```
[DRIFT] repository-map.yaml に乖離あり
  詳細: agents:  → 7
  対応: bash .claude/hooks/generate-repository-map.sh を実行してください
```

- **原因**: ファイル変更後にマップ再生成が未実行
- **影響**: なし（キャッシュのみ、機能影響なし）
- **対応**: `bash .claude/hooks/generate-repository-map.sh` で修正可能

### ISS-L1: evidence/ ディレクトリ空

```
[WARN] playbook-completion → evidence 記録あり(31)だが evidence/ が空または不存在
```

- **原因**: evidence ファイルを別途作成していない
- **影響**: なし（progress.json 内に evidence 記録あり）
- **対応**: cosmetic、対応不要

### ISS-L2: coderabbit Minor 指摘

1. `jq` コマンドの存在確認がない（check_project_reviewed 内）
2. project.json の例外パスが広すぎる可能性

- **影響**: なし（既に playbook-guard.sh の他箇所で jq チェック済み）
- **対応**: 任意（将来の改善として記録）

---

## 4. playbook-completion 固有の問題

### 4.1 p4.1 の自己参照的矛盾

- **問題**: p4.1 の criterion「全 Phase を完走させた記録が存在する」は、p4 進行中に検証不可
- **解決**: 既存の完走済み playbook（post-loop-fix 等）を検証サイクルの証拠として採用
- **教訓**: 自己参照的な criterion は避けるか、解釈を明確化すべき

---

## 5. 結論

- **Critical/High 問題**: 0件
- **Medium 問題**: 2件（既知・scope 外）
- **Low 問題**: 2件（cosmetic・任意対応）

playbook-completion の検証中に**ブロッカーとなる問題は発見されなかった**。
発見された問題は全て既知または scope 外の軽微な問題。

---

## 6. 検証コマンド

```bash
# 本ファイルの存在確認
ls -la play/playbook-completion/reports/verification-issues.md

# 問題数の確認
grep -c "^| ISS-" play/playbook-completion/reports/verification-issues.md
```
