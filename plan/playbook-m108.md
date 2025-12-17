# Playbook: M108 - 古い用語・古い構造の一掃

## meta

```yaml
id: playbook-m108
derives_from: M108
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

Macro/layer などの廃止用語や、古い state 構造を前提とした SubAgent/テンプレートを現在の定義に合わせて更新する。

---

## phases

### p0: 廃止用語の検索

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: Macro/layer/architecture-*.md の使用箇所を検索 ✓
- [x] **p0.2**: ほとんどがドキュメント内での廃止説明であることを確認 ✓

---

### p1: health-checker.md の更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: layer.*.state の参照を削除 ✓
- [x] **p1.2**: focus.current の候補値を更新 ✓
- [x] **p1.3**: config.security の候補値を追加 ✓
- [x] **p1.4**: 参照ドキュメントを追加 ✓
- [x] **p1.5**: model を opus から haiku に変更（高速実行のため） ✓

---

### p2: state-initial.md の確認

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p2.1**: state-initial.md が M103 で既に更新済みであることを確認 ✓

---

## done_criteria verification

- [x] deprecated-references.md の修正対象ファイルが更新済み
- [x] health-checker.md のチェック項目が現行 state.md 構造に一致
- [x] plan/template/state-initial.md が最新フォーマット（M103 で対応済み）
- [x] 廃止用語（Macro/layer/architecture-*.md）がアクティブなファイルから削除されている
  - Note: ドキュメント内で廃止を説明する参照は許可
