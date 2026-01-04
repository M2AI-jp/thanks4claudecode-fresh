# dogfooding-findings.md

> **FizzBuzz ドッグフーディングで発見した問題点・改善点**
>
> 実施日: 2026-01-04
> playbook: plan/playbook-fizzbuzz-dogfooding.md

---

## 1. 実行サマリー

| フェーズ | executor | 結果 | 所要時間 |
|----------|----------|------|----------|
| playbook 作成 | pm | 完了 | - |
| Phase 1: FizzBuzz 実装 | codex | 完了 | 短時間 |
| Phase 2: CodeRabbit レビュー | coderabbit | 完了（手動代替） | - |
| Phase 3: テスト実行 | claudecode | 完了 | - |
| Phase 4: PR 作成・マージ | claudecode | 完了 | - |
| Phase 5: 発見事項記録 | claudecode | 完了 | - |

---

## 2. 発見事項

### 2.1 Hook チェーン

| 項目 | 状態 | 詳細 |
|------|------|------|
| prompt-analyzer 強制 | **正常動作** | Skill 呼び出し前に prompt-analyzer が必須としてブロック |
| main ブランチ保護 | **正常動作** | AskUserQuestion がブロックされ、ブランチ作成を促された |
| playbook gate | **未検証** | playbook 作成前の Edit/Write ブロックは今回発生せず |

**発見**: Hook チェーンは期待通りに動作。main ブランチ保護が AskUserQuestion にも適用されることを確認。

---

### 2.2 executor 連携

| executor | 状態 | 詳細 |
|----------|------|------|
| codex-delegate | **正常動作** | FizzBuzz 実装とコミットを完了 |
| coderabbit-delegate | **部分動作** | 差分がないためレビュー対象外、手動レビューで代替 |

**発見**:
1. **coderabbit は差分ベース**: コミット済みファイルはレビュー対象外になる。Phase 順序を考慮する必要あり。
2. **codex の出力フォーマット**: 結果を構造化して返すため、後続処理が容易。

**改善案**:
- coderabbit を実行するタイミングを「コミット前」に変更するか、PR ベースのレビューに切り替える

---

### 2.3 critic 検証

| 項目 | 状態 | 詳細 |
|------|------|------|
| critic 呼び出し | **未実行** | 今回は Phase 完了ごとに自己検証で進行 |
| done_criteria 検証 | **未実行** | p_final で手動検証に留まった |

**発見**:
- critic SubAgent が呼び出されなかった
- Phase 完了の自己宣言が容易すぎる（reward-guard が発火しなかった）

**改善案**:
- Phase 完了時に critic を強制呼び出しする Hook を追加
- または `subtask[x].status = done` の変更時に critic を要求

---

### 2.4 マージワークフロー

| 項目 | 状態 | 詳細 |
|------|------|------|
| ブランチ作成 | **正常** | feat/fizzbuzz-dogfooding |
| PR 作成 | **正常** | gh pr create で作成 |
| マージ | **正常** | gh pr merge --squash --auto で即座にマージ |

**発見**:
- git-workflow の create-pr-hook.sh は今回発火しなかった（手動で gh コマンド実行）
- auto-merge が即座に実行された（CI チェックなし？）

**改善案**:
- PR 作成時に git-workflow Hook を経由させる
- マージ前に CI ステータスを確認する処理を追加

---

### 2.5 required_broken の影響

| ファイル | 影響 |
|----------|------|
| docs/4qv-architecture.md | WARN 発生なし |
| docs/file-creation-process-design.md | WARN 発生なし |
| docs/coding-standards.md | WARN 発生なし |

**発見**:
- required_broken ファイルへの参照は今回の作業で発火しなかった
- 影響を受ける作業パターンが限定的である可能性

---

## 3. 分類サマリー

### 正常動作した機能（required として維持）

- prompt-analyzer 強制
- main ブランチ保護
- codex-delegate
- playbook 作成フロー（pm + reviewer）

### 問題または改善が必要な機能

| 機能 | 問題 | 優先度 |
|------|------|--------|
| coderabbit タイミング | 差分ベースのため Phase 順序に依存 | Medium |
| critic 強制呼び出し | Phase 完了時に呼び出されない | High |
| git-workflow Hook | PR 作成時に発火しない | Low |

### 未検証の機能

- playbook gate（Edit/Write ブロック）
- reward-guard（報酬詐欺防止）
- coherence-checker（整合性チェック）

---

## 4. 次のアクション

1. **critic 強制呼び出し**: Phase 完了時に critic を呼ぶ Hook を設計
2. **coderabbit PR レビュー**: PR ベースのレビューに切り替える検討
3. **required_broken 修復**: 参照切れファイルを修復または参照削除

---

## 5. 結論

フレームワークの基本機能（Hook チェーン、executor 連携、ブランチ保護）は正常に動作している。
主な改善点は「critic 強制呼び出し」と「coderabbit タイミング」の2点。
required_broken の影響は今回の作業では確認されなかった。
