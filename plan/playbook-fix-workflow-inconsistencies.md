# playbook-fix-workflow-inconsistencies.md

> **workflow 点検で発見された不整合を修正する**

---

## meta

```yaml
project: thanks4claudecode
branch: chore/fix-workflow-inconsistencies
created: 2025-12-22
issue: null
derives_from: null  # 点検で発見された不整合の修正（新規マイルストーンなし）
reviewed: true
roles:
  worker: claudecode  # 軽量な修正作業のため claudecode で実行
```

---

## goal

```yaml
summary: workflow 点検で発見された 3 つの不整合を修正する
done_when:
  - session-end.sh が state.md の現在の構造（playbook.active）を正しく参照している
  - consent-guard.sh への参照がドキュメントから削除されている
  - repository-map.yaml の mandatory_outputs から [理解確認] が削除されている
```

---

## phases

### p1: session-end.sh の state.md 参照修正

**goal**: session-end.sh が古い `## layer:` 参照ではなく、現在の state.md 構造を使用する

#### subtasks

- [x] **p1.1**: session-end.sh の 99 行目が `## playbook` セクションの `active:` を参照している
  - executor: claudecode
  - validations:
    - technical: "grep で修正後のパターンを確認（playbook セクションから active: を取得）" ✅
    - consistency: "state.md の実際の構造と一致していることを確認" ✅
    - completeness: "PLAYBOOK 変数が正しく設定されることを確認" ✅
  - validated: 2025-12-22

- [x] **p1.2**: session-end.sh の 125 行目の LAYER_STATE 参照が削除または適切な代替処理になっている
  - executor: claudecode
  - validations:
    - technical: "grep で LAYER_STATE の参照が削除/修正されていることを確認" ✅
    - consistency: "LAYER_STATE を使用していた後続のロジックが適切に処理されていることを確認" ✅
    - completeness: "layer.state に依存するチェックが削除/置換されていることを確認" ✅
  - validated: 2025-12-22

- [x] **p1.3**: session-end.sh が bash -n でシンタックスエラーなく実行可能である
  - executor: claudecode
  - validations:
    - technical: "bash -n session-end.sh が exit 0 を返す" ✅
    - consistency: "スクリプト全体の論理フローが維持されている" ✅
    - completeness: "変更箇所が動作確認可能" ✅
  - validated: 2025-12-22

**status**: done
**max_iterations**: 5

---

### p2: consent-guard.sh 参照の削除（設計縮小）

**goal**: 存在しない consent-guard.sh への参照をドキュメントから削除する

#### subtasks

- [x] **p2.1**: docs/extension-system.md の 185-186 行目から consent-guard.sh の記載が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep で consent-guard.sh が extension-system.md に存在しないことを確認" ✅
    - consistency: "Edit/Write フローの図が整合性を保っていることを確認" ✅
    - completeness: "該当行と関連する説明が適切に削除されていることを確認" ✅
  - validated: 2025-12-22

- [x] **p2.2**: docs/ARCHITECTURE.md から consent-guard.sh の記載が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep で consent-guard.sh が ARCHITECTURE.md に存在しないことを確認" ✅
    - consistency: "アーキテクチャ図/リストが整合性を保っていることを確認" ✅
    - completeness: "関連する全ての記載が削除されていることを確認" ✅
  - validated: 2025-12-22

- [x] **p2.3**: docs/hook-responsibilities.md から consent-guard.sh の記載が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep で consent-guard.sh が hook-responsibilities.md に存在しないことを確認" ✅
    - consistency: "Hook 一覧が整合性を保っていることを確認" ✅
    - completeness: "セクション構造が維持されていることを確認" ✅
  - validated: 2025-12-22

- [x] **p2.4**: docs/current-definitions.md から consent-guard.sh の記載が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep で consent-guard.sh が current-definitions.md に存在しないことを確認" ✅
    - consistency: "定義表が整合性を保っていることを確認" ✅
    - completeness: "行が適切に削除されていることを確認" ✅
  - validated: 2025-12-22

**status**: done
**depends_on**: [p1]
**max_iterations**: 5

---

### p3: mandatory_outputs から [理解確認] を削除

**goal**: repository-map.yaml と関連ドキュメントから [理解確認] の必須出力を削除する

#### subtasks

- [x] **p3.1**: docs/repository-map.yaml の mandatory_outputs から [理解確認] が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep で mandatory_outputs に [理解確認] が存在しないことを確認" ✅
    - consistency: "YAML 構造が維持されていることを確認" ✅
    - completeness: "[自認] のみが mandatory_outputs に残っていることを確認" ✅
  - validated: 2025-12-22

- [x] **p3.2**: generate-repository-map.sh が [理解確認] を出力しないことを確認
  - executor: claudecode
  - validations:
    - technical: "grep で generate-repository-map.sh に [理解確認] の抽出ロジックがないことを確認" ✅
    - consistency: "スクリプトの動作が維持されていることを確認" ✅
    - completeness: "必要な場合のみ修正が行われていることを確認" ✅
  - validated: 2025-12-22

**status**: done
**depends_on**: [p2]
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: 全ての不整合が修正され、システムが正常に動作することを確認

#### subtasks

- [x] **p_final.1**: session-end.sh が state.md の playbook.active を正しく参照している
  - executor: claudecode
  - validations:
    - technical: "grep でパターン確認、bash -n でシンタックス確認" ✅
    - consistency: "state.md の構造と一致" ✅
    - completeness: "古い layer 参照が存在しない" ✅
  - validated: 2025-12-22

- [x] **p_final.2**: docs/ 内に consent-guard.sh への参照が存在しない
  - executor: claudecode
  - validations:
    - technical: "grep -r で docs/ 内に consent-guard.sh が存在しないことを確認" ✅
    - consistency: "ドキュメントの整合性が維持されている" ✅
    - completeness: "全てのドキュメントから削除されている" ✅
  - validated: 2025-12-22

- [x] **p_final.3**: repository-map.yaml が正常に生成される
  - executor: claudecode
  - validations:
    - technical: "generate-repository-map.sh を実行し正常終了を確認" ✅ (ファイル生成成功)
    - consistency: "生成された YAML が valid であることを確認" ✅
    - completeness: "mandatory_outputs から [理解確認] が削除されていることを確認" ✅
  - validated: 2025-12-22

**status**: done
**depends_on**: [p3]
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成。workflow 点検で発見された 3 つの不整合を修正。 |
