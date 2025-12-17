# Security Modes 仕様

> セキュリティモードの定義と、各 Hook の挙動マッピング

---

## 概要

`state.md` の `config.security` で設定されるセキュリティモードは、Hook の挙動を制御する。
このドキュメントは、各モードの意味と、どの Hook がどのモードでどう動作するかを定義する。

---

## モード定義

```yaml
modes:
  strict:
    description: "全てのガードが有効。本番運用向け。"
    use_case: "通常の開発作業、安全性が最優先の場合"
    
  trusted:
    description: "一部のガードを緩和。信頼されたユーザー向け。"
    use_case: "熟練した開発者による効率的な作業"
    
  developer:
    description: "開発者モード。ほとんどのガードを緩和するが、重要なガードは維持。"
    use_case: "フレームワーク自体の開発、デバッグ"
    
  admin:
    description: "管理者モード。ほぼ全てのガードをバイパス。回復作業用。"
    use_case: "緊急の回復作業、Hook が暴れて編集不能な場合の脱出"
    warning: "危険な操作が可能になる。短時間のみ使用すること。"
```

---

## Hook 一覧と各モードでの挙動

| Hook | カテゴリ | strict | trusted | developer | admin |
|------|----------|--------|---------|-----------|-------|
| **init-guard.sh** | Guard | ✓ Block | ✓ Block | ✓ Block | ○ Pass |
| **playbook-guard.sh** | Guard | ✓ Block | ✓ Block | ○ Pass | ○ Pass |
| **check-main-branch.sh** | Guard | ✓ Block | ✓ Block | ○ Pass | ○ Pass |
| **check-protected-edit.sh** | Guard | ✓ Block | ✓ Block | ✓ Block | ✓ Block |
| **consent-guard.sh** | Guard | ✓ Block | ○ Pass | ○ Pass | ○ Pass |
| **critic-guard.sh** | Guard | ✓ Block | ✓ Block | ○ Pass | ○ Pass |
| **scope-guard.sh** | Guard | ✓ Block | ✓ Block | ○ Pass | ○ Pass |
| **executor-guard.sh** | Guard | ✓ Block | ○ Pass | ○ Pass | ○ Pass |
| **subtask-guard.sh** | Guard | ✓ Block | ✓ Block | ○ Pass | ○ Pass |
| **depends-check.sh** | Guard | ✓ Block | ○ Pass | ○ Pass | ○ Pass |
| **prompt-guard.sh** | Check | ✓ Warn | ✓ Warn | ○ Pass | ○ Pass |
| **check-coherence.sh** | Check | ✓ Warn | ○ Pass | ○ Pass | ○ Pass |
| **lint-check.sh** | Check | ✓ Check | ○ Pass | ○ Pass | ○ Pass |
| **pre-bash-check.sh** | Check | ✓ Check | ○ Pass | ○ Pass | ○ Pass |
| **session-start.sh** | Observer | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **session-end.sh** | Observer | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **log-subagent.sh** | Observer | ✓ Run | ✓ Run | ○ Pass | ○ Pass |
| **failure-logger.sh** | Observer | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **stop-summary.sh** | Observer | ✓ Run | ✓ Run | ○ Pass | ○ Pass |
| **pre-compact.sh** | Observer | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **archive-playbook.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **cleanup-hook.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **create-pr-hook.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **create-pr.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **merge-pr.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **generate-repository-map.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **role-resolver.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **system-health-check.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |
| **test-hooks.sh** | Utility | ✓ Run | ✓ Run | ✓ Run | ✓ Run |

### 凡例

- **✓ Block**: 条件を満たさなければ exit 2 でブロック
- **✓ Warn**: 警告を出すが処理は継続
- **✓ Check**: チェックを実行するが結果によらず継続
- **✓ Run**: 通常通り実行
- **○ Pass**: 何もせず exit 0 で通過

---

## カテゴリ定義

```yaml
Guard:
  description: "操作をブロックする門番"
  behavior: "条件を満たさなければ exit 2"
  examples:
    - init-guard.sh (必須ファイル Read 強制)
    - playbook-guard.sh (playbook 必須)
    - check-main-branch.sh (main ブランチ作業禁止)
    - check-protected-edit.sh (保護ファイル編集禁止)

Check:
  description: "検証を行うが、結果によらず処理継続"
  behavior: "警告を出すことはあるが exit 0"
  examples:
    - lint-check.sh (構文チェック)
    - check-coherence.sh (整合性チェック)

Observer:
  description: "ログ記録・状態観測"
  behavior: "常に exit 0、副作用としてログ記録"
  examples:
    - session-start.sh (セッション開始処理)
    - log-subagent.sh (SubAgent ログ)

Utility:
  description: "便利機能の提供"
  behavior: "常に exit 0、オプショナルな処理"
  examples:
    - archive-playbook.sh (アーカイブ提案)
    - cleanup-hook.sh (一時ファイル削除)
```

---

## admin モードに入る手順

```bash
# 1. state.md の config.security を admin に変更
# （Edit ツールがブロックされる場合は sed を使用）

sed -i '' 's/security: .*/security: admin/' state.md

# 2. 作業を実行

# 3. 作業完了後、security を元に戻す
sed -i '' 's/security: admin/security: trusted/' state.md
```

---

## admin モードから出る手順

```bash
# 作業完了後、必ず security を戻す
sed -i '' 's/security: admin/security: trusted/' state.md

# または strict に戻す
sed -i '' 's/security: admin/security: strict/' state.md
```

---

## 注意事項

1. **admin モードは短時間のみ使用**: 回復作業が終わったら即座に trusted/strict に戻す
2. **check-protected-edit.sh は常に有効**: admin でも CLAUDE.md 等の重要ファイルは保護される
3. **Observer は常に動作**: ログ記録は全モードで有効（デバッグのため）
4. **モード変更はコミット前に戻す**: admin モードのままコミットしない

---

## 実装状態

| 項目 | 状態 |
|------|------|
| 仕様定義（このドキュメント） | ✓ 完了 |
| 各 Hook への実装 | 未実装（M113 で実装予定） |
| state.md との連携 | 一部実装済み |
