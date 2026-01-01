# .claude/rules/

> **仕様・テスト・運用規約の一元管理ディレクトリ**

---

## 目的

```yaml
purpose: |
  CLAUDE.md から分離した詳細ルールを管理。
  セッション開始時に /init で読み込まれる。

structure:
  coding.md: コーディング規約
  testing.md: テスト規約
  operations.md: 運用規約
```

---

## 読み込み順序

```yaml
order:
  1: CLAUDE.md（憲法）
  2: state.md（現在状態）
  3: .claude/rules/*.md（詳細ルール）
  4: playbook（タスク定義）
```

---

## ファイル一覧

| ファイル | 内容 |
|----------|------|
| coding.md | コーディングスタイル、命名規則、型安全性 |
| testing.md | テスト方針、カバレッジ基準、TDD フロー |
| operations.md | 運用手順、デプロイ、監視 |
