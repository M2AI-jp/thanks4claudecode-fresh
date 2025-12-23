# playbook-setup-redesign.md

> **setup/playbook-setup.md を playbook ベースに再設計**

---

## meta

```yaml
branch: chore/setup-redesign
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: setup/playbook-setup.md から project.md/milestone 参照を削除し、playbook ベースのシステムに対応
done_when:
  - grep "project.md" setup/playbook-setup.md が 0 件
  - grep "milestone" が "計画の連鎖" 設計説明以外で 0 件
  - Phase 8 が playbook ベースのフローに更新されている
  - 設計思想セクションが state.md + playbook の二層構造を反映している

rollback:
  - git checkout -- setup/playbook-setup.md で復元可能
```

---

## phases

### p0: 前提確認

**goal**: 変更対象を確認し、バックアップを作成

#### subtasks

- [x] **p0.1**: setup/playbook-setup.md の現状を確認
  - executor: claudecode
  - result: 17件の project.md 参照を確認

- [x] **p0.2**: ブランチを作成
  - executor: claudecode
  - result: chore/setup-redesign ブランチ作成完了

**status**: done

---

### p1: 設計思想セクションの更新

**goal**: 設計思想と原則から project.md 参照を削除

#### subtasks

- [x] **p1.1**: "学習の流れ" セクションを更新
  - result: "plan/project.md を生成" → "作りたい機能を伝え、playbook を作成"

- [x] **p1.2**: "計画の連鎖" セクションを playbook only に変更
  - result: "playbook → phase（二層構造）" に更新

- [x] **p1.3**: "コンテキスト外部化" セクションを更新
  - result: "state.md / playbook を唯一の真実源に"

- [x] **p1.4**: "原則" セクションの永続化先を更新
  - result: "決定は playbook 内または state.md に記録"

**status**: done

---

### p2: goal と done_when の更新

**goal**: ファイル冒頭の goal から project.md 要件を削除

#### subtasks

- [x] **p2.1**: goal.done_when を更新
  - result: "plan/project.md が生成されている" を削除

- [x] **p2.2**: "補足" セクションを更新
  - result: "plan/ に playbook を作成" に変更

**status**: done

---

### p3: Phase 8 の再設計

**goal**: Phase 8 を project.md 生成なしの開発移行フローに変更

#### subtasks

- [x] **p3.1**: Phase 8 の done_criteria を更新
  - result: project.md 関連を削除、Skills と focus.current のみに

- [x] **p3.2**: Phase 8 の LLM 行動を更新
  - result: project.md 生成処理を削除、Skills 確認と state.md 更新のみに

- [x] **p3.3**: Phase 8 の完了メッセージを更新
  - result: "playbook を作成して開発を進めます" に変更

- [x] **p3.4**: Phase 1-A の補足を更新
  - result: "playbook 作成時に参照" に変更

- [x] **p3.5**: "tech_decisions 永続化の意図" セクションを削除
  - result: セクション全体を削除

**status**: done

---

### p4: 検証

**goal**: 変更が正しく行われたことを確認

#### subtasks

- [x] **p4.1**: project.md 参照がないことを確認
  - result: grep -c "project.md" → 0

- [x] **p4.2**: milestone 参照を確認
  - result: grep -n "milestone" → 0

- [x] **p4.3**: 依存ファイルへの影響確認
  - result: docs/deprecated-references.md のみ（ドキュメント、更新不要）

- [x] **p4.4**: 変更をコミット
  - result: ce51a28

**status**: done

---

## changelog

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 全 Phase 完了。project.md 参照 17件 → 0件。 |
| 2025-12-23 | reviewer FAIL 対応: p0 追加、line 番号削除、検証基準を明確化 |
| 2025-12-23 | 初版作成 |
