# test/

> **根幹機能テスト、シナリオテスト、結果アーカイブの統合管理**

---

## 目的

1. **根幹機能テスト**: 8つの根幹機能が仕様通り動作するかを検証
2. **シナリオテスト**: ユーザー体験全体（E2E）を検証
3. **メタ認知テスト**: LLM が仕組みを正しく使えるかを言語化して検証
4. **結果アーカイブ**: 再現性と改善のためのログ保存

---

## 構造

```
test/
├── template/            # テスト形式定義
│   └── test-format.md   # given-when-then 形式（あらゆるテストに対応）
├── core/                # 根幹機能テスト（10ファイル）
│   ├── session-start.test.md      # SessionStart Hook
│   ├── protected-edit.test.md     # 保護ファイル機構
│   ├── coherence.test.md          # 整合性チェック
│   ├── state-update.test.md       # state.md 更新強制
│   ├── critique.test.md           # CRITIQUE 機能
│   ├── playbook-branch.test.md    # playbook-branch 連動
│   ├── layer-transition.test.md   # 状態遷移
│   ├── self-recognition.test.md   # [自認] 宣言
│   ├── tdd-loop.test.md           # TDD LOOP
│   └── file-structure.test.md     # ファイル構造
├── scenarios/           # E2E シナリオ
│   ├── new-user-chatgpt-clone.md      # v1（非推奨）
│   └── fresh-fork-chatgpt-clone.md    # v3（推奨）
├── results/             # 実行結果アーカイブ
│   └── 2025-12-01-*.md
└── README.md            # このファイル
```

## 既存テスト（t1-t6）との対応表

| 既存 ID | テスト名 | 新形式ファイル | シナリオ ID |
|---------|---------|---------------|------------|
| t1 | focus-guard | coherence.test.md | s2 |
| t2 | session-start | session-start.test.md | s1 |
| t3 | protected-edit | protected-edit.test.md | s1, s3 |
| t4 | coherence | coherence.test.md | s1 |
| t5 | state-update | state-update.test.md | s2 |
| t6 | file-structure | file-structure.test.md | s1-s5 |

**実行方法**:
```bash
# 既存テスト（自動実行）
bash .claude/hooks/test-done-criteria.sh       # 全テスト
bash .claude/hooks/test-done-criteria.sh t1    # 特定テスト

# 新形式テスト（手動/半自動）
# 各 test/core/*.test.md の verify.command を実行
```

---

## シナリオ一覧

| シナリオ | バージョン | 開始地点 | 推奨度 |
|---------|-----------|---------|-------|
| new-user-chatgpt-clone.md | v1 | 既存ワークスペース | 非推奨 |
| fresh-fork-chatgpt-clone.md | v3 | GitHub フォーク直後 | **推奨** |

**注意**: v1 シナリオは setup レイヤーをスキップしていたため、真のユーザー体験を検証できていませんでした。
新規テストは必ず v3（fresh-fork-*）を使用してください。

---

## テスト種類の関係

```
┌─────────────────────────────────────────────────────────┐
│ test/                                                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  core/ (根幹機能テスト)                                   │
│  ├── 自動検証可能 → verify.type: auto                    │
│  │   └── bash .claude/hooks/test-done-criteria.sh       │
│  ├── 手動確認 → verify.type: manual                      │
│  │   └── チェックリストで確認                             │
│  └── LLM 確認 → verify.type: llm                         │
│      └── LLM にプロンプトで確認                           │
│                                                         │
│  scenarios/ (E2E シナリオテスト)                          │
│  └── 全フローを通しで検証                                 │
│      └── 人間 or LLM が実行、results/ に記録              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## シナリオ vs playbook の test_method

| 項目 | playbook の test_method | test/scenarios/ |
|------|------------------------|-----------------|
| 粒度 | Phase 単位（細かい） | E2E（全体フロー） |
| 目的 | done_criteria の検証 | ユーザー体験の検証 |
| 実行者 | codex（自動判定） | 人間 or LLM（メタ認知） |
| 記録 | playbook 内に記載 | results/ にアーカイブ |

---

## テスト種類

### 1. 機能テスト
- 各コンポーネントが仕様通り動作するか
- Hook が正しく発火するか
- コマンドが期待通り動作するか

### 2. シナリオテスト
- 新規ユーザーが setup → plan → 開発 の全フローを完走できるか
- 仕組みの「流れ」が自然か

### 3. メタ認知テスト
- LLM が [自認] を正しく宣言するか
- LLM が done_criteria を正しく評価するか
- LLM が報酬詐欺に陥らないか
- ユーザー体験の心情まで言語化

---

## 結果フォーマット

```yaml
scenario: {シナリオ名}
date: {実行日}
executor: {実行者}
result: PASS | FAIL | PARTIAL

findings:
  - {発見事項}

bugs:
  - {バグや問題点}

user_experience:
  心情:
    - {各ステップでの感情変化}
  摩擦点:
    - {使いにくかった箇所}
  満足点:
    - {良かった箇所}
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-01 | v3 シナリオ追加（fresh-fork-chatgpt-clone.md）。まっさらな状態からの E2E テスト。 |
| 2025-12-01 | 初版作成。シナリオベーステストの構造定義。 |
