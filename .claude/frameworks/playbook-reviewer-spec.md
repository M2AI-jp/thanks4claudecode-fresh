# playbook_reviewer 仕様

> **報酬詐欺防止のための独立検証エージェント**
> criteria がクリアされるまで LOOP する仕組みの核心部分

---

## 役割

- playbook の done_when が「本当に」達成されているか独立検証
- 作成者の PASS 判定を鵜呑みにしない
- 自分でコードを実行して証拠を収集
- **FAIL の場合、該当 subtask を特定して返す（親 Claude が再実行）**

---

## LOOP の仕組み

```
┌─────────────────────────────────────────────────────────┐
│  実装フェーズ (p1 → p2 → p3 → p4)                       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  p_final: playbook_reviewer による独立検証              │
└─────────────────────────────────────────────────────────┘
                         ↓
                   ┌─────────┐
                   │  PASS?  │
                   └────┬────┘
                   YES  │  NO
            ┌──────────┴──────────┐
            ↓                     ↓
    ┌──────────────┐    ┌──────────────────────────┐
    │ reviewed:true │    │ FAIL した subtask を特定  │
    │ → アーカイブ  │    │ 親 Claude が再実行        │
    └──────────────┘    │ → 再度 playbook_reviewer  │
                        └──────────────────────────┘
                                  ↑          │
                                  └──────────┘
                                    LOOP
```

**親 Claude (orchestrator) が LOOP を制御する。**

---

## 検証タイプ

### コードタスク（subtask.coding: true）

```yaml
必須検証:
  - ファイルが存在する（test -f）
  - 構文エラーがない（lint/compile）
  - 実際に実行して期待する出力を得る
  - edge case を最低 1 つ追加テスト

検証コマンド例:
  Python:
    - python3 -m py_compile {file}
    - echo '{}' | python3 {file}（空入力）
    - echo '{"invalid"}' | python3 {file}（不正入力）

  Shell:
    - bash -n {file}（構文チェック）
    - bash {file}（実行テスト）
```

### 非コードタスク（subtask.coding: false）

```yaml
必須検証:
  - 該当ファイル/セクションが存在する
  - 指定されたパターンが含まれている
  - 関連ドキュメントと整合性がある

検証コマンド例:
  - grep -q "{pattern}" {file} && echo PASS
  - test -f {file} && echo PASS
```

---

## 独立性の担保

```yaml
禁止事項:
  - 作成者が書いた「PASS」を確認材料にする
  - playbook の [x] チェックボックスを見る
  - validations の結果文字列を信じる

必須事項:
  - 自分で検証コマンドを実行する
  - 自分で edge case を考える
  - 疑わしきは FAIL
```

---

## 出力形式

### PASS の場合

```yaml
result: PASS
verification:
  - item: "done_when 項目1"
    status: PASS
    evidence: "実行したコマンドと出力"
  - item: "done_when 項目2"
    status: PASS
    evidence: "実行したコマンドと出力"

action: reviewed: true に設定し、アーカイブ可能
```

### FAIL の場合

```yaml
result: FAIL
failed_items:
  - item: "done_when 項目2"
    status: FAIL
    reason: "edge case で失敗: 空入力で例外発生"
    related_subtask: p2.3
    fix_hint: "空入力時のエラーハンドリングを追加"

action: 親 Claude は p2.3 を再実行し、再度 playbook_reviewer を呼ぶ
```

**重要**: FAIL 時は「レポート」ではなく、「再実行すべき subtask」を特定して返す。

---

## 検証チェックリスト

### 前提確認

- [ ] playbook.goal.done_when を全て把握した
- [ ] 各 subtask の coding フラグを確認した
- [ ] p_final 以外の全フェーズが done になっている

### コードタスク検証（coding: true）

- [ ] ファイルが存在する
- [ ] 構文エラーがない（lint/compile 実行）
- [ ] 基本動作を確認（実行テスト）
- [ ] edge case を 1 つ以上自分で追加テスト

### 非コードタスク検証（coding: false）

- [ ] 該当ファイル/セクションが存在する
- [ ] 内容が done_when の要件を満たしている

### 統合検証

- [ ] done_when の全項目が達成されている
- [ ] goal.summary（本来の目的）が達成されている

### 最終判定

- 全チェック PASS → `result: PASS`、`reviewed: true` を設定
- 1 つでも FAIL → `result: FAIL`、`failed_items` と `related_subtask` を返す

---

## 制約

```yaml
配置: p_final の最後の subtask として必須
条件: reviewed: true でなければアーカイブ不可
時間: 検証は 10 分以内を目安
原則: 疑わしきは FAIL
```

---

## 使用方法

```yaml
# playbook の p_final 最後に追加

- [ ] **p_final.N**: playbook_reviewer による独立検証が PASS
  - executor: playbook_reviewer
  - coding: false
  - validations:
    - technical: "done_when の全項目を独立検証"
    - consistency: "subtask.coding に応じた検証レベル"
    - completeness: "edge case を含む追加テスト"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成。LOOP メカニズム、独立検証、FAIL 時の再実行フローを定義。 |
