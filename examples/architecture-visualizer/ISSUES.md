# Architecture Visualizer - テスト結果と発見した問題点

> **テスト日**: 2025-12-25
> **目的**: アーキテクチャのユーザーフロー完走テスト

---

## 発見した問題点

### 1. 404 エラー（ファイル消失）

**現象**: PR マージ後に `tmp/sample-website/` が存在しない

**原因**: `.gitignore` で `tmp/` が除外されている

```gitignore
.tmp/
tmp/
tmp/*
!tmp/README.md
```

**対策**:
- `examples/` ディレクトリに移動（永続化）
- または `.gitignore` に例外を追加

**教訓**: tmp/ は一時ファイル用。成果物は examples/ や docs/ に配置すべき

---

### 2. オーケストレーション不在

**現象**: `state.md` で `toolstack: B`（Codex 使用）と設定されているが、実際には claudecode のみで実装された

**期待動作**:
```yaml
toolstack: B
roles:
  orchestrator: claudecode  # 監督・調整・設計
  worker: codex             # 実装担当
  reviewer: claudecode      # レビュー担当
```

**実際の動作**:
- claudecode が全て実行
- codex-delegate SubAgent は呼び出されなかった
- CodeRabbit も未使用（toolstack B では reviewer: claudecode なので正常）

**原因分析**:
1. playbook の `executor` フィールドが全て `claudecode` になっていた
2. codex-delegate への委譲ロジックが発火しなかった
3. toolstack 設定と実際の executor の連動が不足

**改善案**:
- playbook 作成時に toolstack を参照して executor を自動設定
- executor: codex の場合、codex-delegate SubAgent を強制呼び出し

---

### 3. バックグラウンドタスク残存

**現象**: `python -m http.server` がバックグラウンドで起動したまま残存

**原因**:
- `run_in_background: true` で起動後、明示的な終了処理がなかった
- セッション終了時の自動クリーンアップがなかった

**対策**:
- SubagentStop Hook でバックグラウンドタスクを検出・警告
- セッション終了時に `/tasks` で残存確認を促す
- 長時間タスクには必ず timeout を設定

---

### 4. 検証の形骸化（最重要）

**現象**: critic が「PASS」と判定したが、実際には何も検証していない

**具体例**:
```
critic の判定:
  - ファイル存在確認: test -f で確認 → PASS
  - HTTP応答: curl でステータスコード200確認 → PASS
  - タイムライン視覚化: grep で要素数確認 → PASS
```

**問題点**:
1. **ファイル存在確認のみ**: ファイルが存在しても、内容が正しいかは未検証
2. **HTTP応答のみ**: 200が返っても、表示内容が正しいかは未検証
3. **grep カウントのみ**: 要素数だけで、実際の動作は未検証
4. **ブラウザ確認なし**: 人間による視覚的確認がスキップされた

**根本原因**:
- `executor: user` のタスクが形骸化している
- critic は「証拠」としてコマンド出力を示すが、それは「検証」ではない
- 自動化できない検証（視覚確認、操作確認）がスキップされている

**改善案**:

#### A. subtask 単位でのレビュー強制

```yaml
subtask:
  - [ ] p1.1: index.html 作成
    - executor: claudecode
    - validations:
      - technical: "test -f でファイル存在確認"
      - consistency: "HTML5 構造確認"
      - completeness: "必要要素の確認"
    - review: required  # ← 追加
    - reviewer: user    # 人間によるレビュー必須
```

#### B. 検証タイプの明確化

```yaml
validation_types:
  automated:
    # 自動実行可能
    - file_exists: "test -f"
    - http_status: "curl -s -o /dev/null -w '%{http_code}'"
    - grep_count: "grep -c"

  manual:
    # 人間の確認が必要
    - visual_check: "ブラウザで表示確認"
    - interaction_check: "クリック・アニメーション動作確認"
    - ux_check: "ユーザー体験の評価"

  hybrid:
    # スクリーンショット + 人間確認
    - screenshot_diff: "前回との視覚的差分"
```

#### C. critic の検証基準強化

```yaml
critic_rules:
  - automated_only: "自動検証のみでは PASS 不可（manual 項目がある場合）"
  - evidence_required: "全項目について実行ログを提示"
  - user_confirmation: "manual 項目は user の承認が必要"
```

---

## 総合評価

| 項目 | 評価 | 備考 |
|------|------|------|
| Golden Path チェーン | △ | Hook→Skill→SubAgent は動作したが、オーケストレーション不在 |
| 成果物の永続化 | × | tmp/ が gitignore で消失 |
| バックグラウンド管理 | × | 残存タスクの自動クリーンアップなし |
| 検証の実効性 | × | 形骸化、実際の動作確認なし |

---

## 次のアクション

1. [ ] executor と toolstack の連動ロジック実装
2. [ ] subtask 単位での review 機能追加
3. [ ] validation_types の分類と強制
4. [ ] バックグラウンドタスクの自動クリーンアップ
5. [ ] 成果物の配置先ルール明確化（tmp/ 禁止）
