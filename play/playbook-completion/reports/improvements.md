# playbook 実行中に発見した改善点

> Generated: 2026-01-07
> Playbook: playbook-completion (p_self_update.1)

---

## 1. 概要

playbook-completion 実行中に発見した改善点を記録する。
技術的改善点と運用改善点を分類。

---

## 2. 技術的改善点

### 2.1 High Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-T1 | jq 依存の明示化 | playbook-guard.sh で jq を使用するが、インストール確認が一部不足 | check_project_reviewed() 内に `command -v jq` チェック追加 |

### 2.2 Medium Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-T2 | settings.json の `-lc` エントリ | 9件の警告が出る | 不要なエントリを削除または正しいパスに修正 |
| IMP-T3 | repository-map.yaml 自動更新 | 手動実行が必要 | post-tool-edit で自動生成するか、integrity check で自動修復 |

### 2.3 Low Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-T4 | evidence/ ディレクトリ | 空のまま | progress.json 内の evidence で代替可能、削除を検討 |

---

## 3. 運用改善点

### 3.1 High Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-O1 | p4.1 の自己参照的 criterion | 「全 Phase 完走」を p4 で検証しようとする矛盾 | criterion を「検証サイクルの記録が存在する」に修正、または既存完走 playbook を証拠とする |

### 3.2 Medium Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-O2 | critic FAIL 時のリカバリ | FAIL 後に修正 → 再実行の流れが明確でない | FAIL 時のガイダンスを critic 出力に含める |
| IMP-O3 | codex/coderabbit delegate の動作確認 | 手動確認が必要 | スモークテストコマンドを用意 |

### 3.3 Low Priority

| ID | 改善点 | 現状 | 提案 |
|----|--------|------|------|
| IMP-O4 | playbook template の self_update phase | 全 playbook に含めるべきか | optional phase として定義し、必要に応じて追加 |

---

## 4. p4.2 問題記録との整合

| p4.2 問題 | 改善点 | 対応 |
|-----------|--------|------|
| ISS-M1 (-lc warnings) | IMP-T2 | settings.json 修正 |
| ISS-M2 (repository-map drift) | IMP-T3 | 自動更新検討 |
| ISS-L1 (evidence/ 空) | IMP-T4 | 削除または運用見直し |
| ISS-L2 (coderabbit Minor) | IMP-T1 | jq チェック追加 |

---

## 5. 優先度サマリ

| 優先度 | 技術的 | 運用 |
|--------|--------|------|
| High | 1件 | 1件 |
| Medium | 2件 | 2件 |
| Low | 1件 | 1件 |

---

## 6. 結論

- playbook-completion は正常に完走
- 発見された改善点は全て **非ブロッカー**
- 次回 playbook で対応可能なレベルの改善点

---

## 7. 検証コマンド

```bash
# 本ファイルの存在確認
ls -la play/playbook-completion/reports/improvements.md

# 改善点数の確認
grep -c "^| IMP-" play/playbook-completion/reports/improvements.md
```
