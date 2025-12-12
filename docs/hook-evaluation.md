# hook-evaluation.md

> **非Core Hooks の評価レポート**
>
> M010 p2: 各 Hook のコード確認、依存関係、使用頻度、代替手段を分析し、削除候補を提示

---

## 評価日時

2025-12-13

---

## 評価方法

1. 各 Hook のソースコードを Read で確認
2. コード内での他ファイル参照を分析
3. settings.json での登録状況を確認
4. Core 機能との関連性を評価
5. 削除した場合の影響を判定

---

## 評価対象（非Core Hooks: 20個）

### Core Hooks（保護対象・評価対象外）

| Hook | 役割 |
|------|------|
| session-start.sh | セッション初期化、pending/consent ファイル作成 |
| prompt-guard.sh | ユーザー意図ガード |
| init-guard.sh | INIT 必須チェック |
| playbook-guard.sh | playbook 存在チェック |
| consent-guard.sh | 合意ファイルチェック |
| critic-guard.sh | critic PASS チェック |
| check-coherence.sh | 整合性チェック |
| log-subagent.sh | SubAgent ログ記録 |
| scope-guard.sh | スコープガード |
| executor-guard.sh | executor 権限チェック |

---

## 非Core Hooks 評価結果

### 1. check-protected-edit.sh

| 項目 | 内容 |
|------|------|
| 役割 | Edit/Write 時のファイル保護（HARD_BLOCK/BLOCK/WARN レベル） |
| 依存関係 | state.md, .claude/protected-files.txt |
| トリガー | PreToolUse:Edit, PreToolUse:Write |
| 使用頻度 | 高（全ての Edit/Write 操作） |
| 代替手段 | なし（セキュリティ機能） |
| 削除影響 | **重大** - 保護ファイルの誤編集が発生 |
| Core 関連性 | **高** - セキュリティの基盤 |
| **判定** | **保持推奨** |

---

### 2. check-main-branch.sh

| 項目 | 内容 |
|------|------|
| 役割 | main/master ブランチでの Edit/Write ブロック |
| 依存関係 | state.md（focus.current） |
| トリガー | PreToolUse:Edit, PreToolUse:Write |
| 使用頻度 | 高（全ての Edit/Write 操作） |
| 代替手段 | なし（git 運用ルール） |
| 削除影響 | **中** - main ブランチへの直接変更が可能に |
| Core 関連性 | **中** - git 運用の安定性 |
| **判定** | **保持推奨** |

---

### 3. depends-check.sh

| 項目 | 内容 |
|------|------|
| 役割 | Phase の depends_on 検証（警告のみ、ブロックなし） |
| 依存関係 | playbook ファイル |
| トリガー | PreToolUse:Edit |
| 使用頻度 | 低（Phase 変更時のみ） |
| 代替手段 | CLAUDE.md の LOOP 動作で代替可能 |
| 削除影響 | **軽微** - 警告が表示されなくなるだけ |
| Core 関連性 | **低** - 情報提供のみ |
| **判定** | **削除候補** |

理由: 警告のみで強制力がなく、CLAUDE.md の Phase 管理で十分カバーされる

---

### 4. check-file-dependencies.sh

| 項目 | 内容 |
|------|------|
| 役割 | ファイル依存関係の情報表示 |
| 依存関係 | .claude/file-dependencies.yaml |
| トリガー | PreToolUse:Edit, PreToolUse:Write |
| 使用頻度 | 中（Edit/Write 時） |
| 代替手段 | ドキュメント参照で代替可能 |
| 削除影響 | **軽微** - 情報表示がなくなるだけ |
| Core 関連性 | **低** - 情報提供のみ |
| **判定** | **削除候補** |

理由: 情報提供のみで必須機能ではない。file-dependencies.yaml 自体の参照も少ない

---

### 5. pre-compact.sh

| 項目 | 内容 |
|------|------|
| 役割 | /compact 前のセッション状態を snapshot.json に保存 |
| 依存関係 | state.md, user-intent.md, playbook |
| トリガー | PreCompact |
| 使用頻度 | 中（/compact 実行時） |
| 代替手段 | なし（コンテキスト継承の唯一の手段） |
| 削除影響 | **重大** - compact 後のコンテキスト継承が失われる |
| Core 関連性 | **高** - セッション継続性 |
| **判定** | **保持推奨** |

---

### 6. session-end.sh

| 項目 | 内容 |
|------|------|
| 役割 | セッション終了時の状態記録 |
| 依存関係 | state.md |
| トリガー | Stop |
| 使用頻度 | 中（セッション終了時） |
| 代替手段 | なし |
| 削除影響 | **中** - 終了状態の追跡ができなくなる |
| Core 関連性 | **中** - 状態管理 |
| **判定** | **保持推奨** |

---

### 7. stop-summary.sh

| 項目 | 内容 |
|------|------|
| 役割 | Stop イベント時の Phase 状態サマリー出力 |
| 依存関係 | state.md, playbook |
| トリガー | Stop |
| 使用頻度 | 中（セッション終了時） |
| 代替手段 | なし |
| 削除影響 | **中** - 終了時の状態確認ができなくなる |
| Core 関連性 | **中** - ユーザー意図確認 |
| **判定** | **保持推奨** |

---

### 8. lint-check.sh

| 項目 | 内容 |
|------|------|
| 役割 | git commit 前の静的解析（ESLint/ShellCheck/Ruff） |
| 依存関係 | なし（外部ツール呼び出し） |
| トリガー | PreToolUse:Bash (git commit) |
| 使用頻度 | 低（git commit 時のみ） |
| 代替手段 | CI/CD で代替可能、pre-commit hook でも可能 |
| 削除影響 | **軽微** - 警告が表示されなくなるだけ（ブロックしない） |
| Core 関連性 | **低** - 品質チェック補助 |
| **判定** | **削除候補** |

理由: 警告のみでブロックせず、CI で代替可能

---

### 9. pre-bash-check.sh

| 項目 | 内容 |
|------|------|
| 役割 | Bash 経由での保護ファイルへの書き込みブロック |
| 依存関係 | state.md, protected-files.txt, check-coherence.sh, check-state-update.sh |
| トリガー | PreToolUse:Bash |
| 使用頻度 | 高（全ての Bash 操作） |
| 代替手段 | なし（check-protected-edit.sh を補完） |
| 削除影響 | **中** - Bash 経由での保護ファイル編集が可能に |
| Core 関連性 | **中** - セキュリティ補助 |
| **判定** | **保持推奨** |

---

### 10. update-tracker.sh

| 項目 | 内容 |
|------|------|
| 役割 | ファイル変更追跡と current-implementation.md 更新提案 |
| 依存関係 | docs/current-implementation.md, .claude/logs/changes.log |
| トリガー | PostToolUse:Edit, PostToolUse:Write |
| 使用頻度 | 中（Edit/Write 時） |
| 代替手段 | 手動でのドキュメント更新 |
| 削除影響 | **軽微** - 更新提案が表示されなくなるだけ |
| Core 関連性 | **低** - 情報提供のみ |
| **判定** | **削除候補** |

理由: 情報提供のみで必須機能ではない

---

### 11. doc-freshness-check.sh

| 項目 | 内容 |
|------|------|
| 役割 | ドキュメント鮮度チェック（3日以上古い場合に警告） |
| 依存関係 | docs/current-implementation.md, docs/extension-system.md |
| トリガー | PostToolUse:Read |
| 使用頻度 | 中（Read 時） |
| 代替手段 | 手動での更新日確認 |
| 削除影響 | **軽微** - 鮮度警告が表示されなくなるだけ |
| Core 関連性 | **低** - 情報提供のみ |
| **判定** | **削除候補** |

理由: 情報提供のみで必須機能ではない

---

### 12. failure-logger.sh

| 項目 | 内容 |
|------|------|
| 役割 | Hook ブロック時の失敗パターン記録 |
| 依存関係 | .claude/logs/failures.log, learning Skill |
| トリガー | 他 Hook から呼び出し |
| 使用頻度 | 低（Hook ブロック時のみ） |
| 代替手段 | なし（ただし learning Skill が未実装状態） |
| 削除影響 | **軽微** - 失敗ログが記録されなくなる |
| Core 関連性 | **低** - ユーティリティ |
| **判定** | **削除候補** |

理由: learning Skill との連携が前提だが、現状では活用されていない

---

### 13. system-health-check.sh

| 項目 | 内容 |
|------|------|
| 役割 | Hook/SubAgent/Skill の健全性チェック |
| 依存関係 | .claude/settings.json, state.md |
| トリガー | SessionStart（session-start.sh から呼び出し） |
| 使用頻度 | 高（毎セッション開始時） |
| 代替手段 | なし |
| 削除影響 | **中** - 設定不整合の検出ができなくなる |
| Core 関連性 | **中** - システム健全性 |
| **判定** | **保持推奨** |

---

### 14. generate-implementation-doc.sh

| 項目 | 内容 |
|------|------|
| 役割 | current-implementation.md の自動生成 |
| 依存関係 | .claude/ 配下全体 |
| トリガー | 手動実行 |
| 使用頻度 | 低（必要時のみ） |
| 代替手段 | 手動でのドキュメント作成 |
| 削除影響 | **軽微** - 自動生成ができなくなる |
| Core 関連性 | **低** - ユーティリティ |
| **判定** | **削除候補** |

理由: update-tracker.sh から呼び出されるユーティリティだが、両方とも必須ではない

---

### 15. archive-playbook.sh

| 項目 | 内容 |
|------|------|
| 役割 | playbook 完了時のアーカイブ提案 |
| 依存関係 | docs/archive-operation-rules.md, state.md, playbook |
| トリガー | PostToolUse:Edit（playbook 編集時） |
| 使用頻度 | 中（playbook 完了時） |
| 代替手段 | なし（POST_LOOP フローの一部） |
| 削除影響 | **中** - アーカイブ提案が表示されなくなる |
| Core 関連性 | **高** - CLAUDE.md の POST_LOOP から参照 |
| **判定** | **保持推奨** |

---

### 16. create-pr.sh

| 項目 | 内容 |
|------|------|
| 役割 | playbook 完了時の PR 自動作成 |
| 依存関係 | state.md, playbook, gh CLI |
| トリガー | POST_LOOP から手動呼び出し |
| 使用頻度 | 中（playbook 完了時） |
| 代替手段 | 手動での PR 作成 |
| 削除影響 | **中** - 自動 PR 作成ができなくなる |
| Core 関連性 | **中** - 運用フロー |
| **判定** | **保持推奨** |

---

### 17. merge-pr.sh

| 項目 | 内容 |
|------|------|
| 役割 | PR の自動マージ |
| 依存関係 | state.md, playbook, gh CLI |
| トリガー | 手動呼び出し |
| 使用頻度 | 低（PR マージ時） |
| 代替手段 | 手動での PR マージ |
| 削除影響 | **軽微** - 自動マージができなくなる |
| Core 関連性 | **低** - 運用フロー |
| **判定** | **保持推奨**（create-pr.sh との一貫性） |

---

### 18. test-hooks.sh

| 項目 | 内容 |
|------|------|
| 役割 | Hook 機能の検証テスト |
| 依存関係 | 各 Hook ファイル |
| トリガー | 手動実行 |
| 使用頻度 | 低（開発・デバッグ時のみ） |
| 代替手段 | 手動テスト |
| 削除影響 | **軽微** - 自動テストができなくなる |
| Core 関連性 | **低** - 開発用ユーティリティ |
| **判定** | **削除候補** |

理由: 開発・デバッグ用ユーティリティで、通常運用では不要

---

### 19. create-pr-hook.sh

| 項目 | 内容 |
|------|------|
| 役割 | create-pr.sh のラッパー |
| 依存関係 | create-pr.sh, state.md, playbook |
| トリガー | playbook 完了時 |
| 使用頻度 | 低 |
| 代替手段 | create-pr.sh を直接呼び出し |
| 削除影響 | **なし** - create-pr.sh で代替可能 |
| Core 関連性 | **低** - 重複機能 |
| **判定** | **削除候補** |

理由: create-pr.sh と機能重複しており、ラッパーとしての追加価値が低い

---

### 20. lib/common.sh

| 項目 | 内容 |
|------|------|
| 役割 | Hook 共通ライブラリ（色定義、パス、ヘルパー関数） |
| 依存関係 | なし |
| トリガー | 他 Hook から source |
| 使用頻度 | 中（他 Hook が使用） |
| 代替手段 | 各 Hook に直接記述 |
| 削除影響 | **中** - 他 Hook が動作しなくなる可能性 |
| Core 関連性 | **中** - 依存先 |
| **判定** | **保持推奨** |

---

## サマリー

### 保持推奨（11個）

| Hook | 理由 |
|------|------|
| check-protected-edit.sh | セキュリティ基盤 |
| check-main-branch.sh | Git 運用安定性 |
| pre-compact.sh | コンテキスト継承 |
| session-end.sh | 状態管理 |
| stop-summary.sh | ユーザー意図確認 |
| pre-bash-check.sh | セキュリティ補助 |
| system-health-check.sh | システム健全性 |
| archive-playbook.sh | POST_LOOP フロー |
| create-pr.sh | 運用フロー |
| merge-pr.sh | 運用フロー |
| lib/common.sh | 共通ライブラリ |

### 削除候補（9個）

| Hook | 理由 |
|------|------|
| depends-check.sh | 警告のみ、強制力なし |
| check-file-dependencies.sh | 情報提供のみ |
| lint-check.sh | 警告のみ、CI で代替可能 |
| update-tracker.sh | 情報提供のみ |
| doc-freshness-check.sh | 情報提供のみ |
| failure-logger.sh | 未活用ユーティリティ |
| generate-implementation-doc.sh | ユーティリティ |
| test-hooks.sh | 開発用ユーティリティ |
| create-pr-hook.sh | create-pr.sh と重複 |

---

## 削除候補の詳細理由

### 削除基準

1. **警告のみでブロックしない** - 実質的な強制力がない
2. **情報提供のみ** - なくても運用に支障がない
3. **CI/CD で代替可能** - 他の仕組みでカバーされる
4. **機能重複** - 他の Hook で同等の機能が提供されている
5. **開発用** - 通常運用では使用されない

### 削除による影響

- **depends-check.sh**: Phase 依存関係の警告がなくなる → CLAUDE.md の LOOP で管理
- **check-file-dependencies.sh**: ファイル依存情報がなくなる → ドキュメント参照で代替
- **lint-check.sh**: 静的解析警告がなくなる → CI/CD で実行
- **update-tracker.sh**: ドキュメント更新提案がなくなる → 手動管理
- **doc-freshness-check.sh**: 鮮度警告がなくなる → 手動確認
- **failure-logger.sh**: 失敗ログがなくなる → 必要時に復活
- **generate-implementation-doc.sh**: 自動生成がなくなる → 手動作成
- **test-hooks.sh**: 自動テストがなくなる → 手動テスト
- **create-pr-hook.sh**: ラッパーがなくなる → create-pr.sh を直接使用

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 p2 対応。20個の非Core Hooks を評価。 |
