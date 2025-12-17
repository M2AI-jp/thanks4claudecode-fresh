# Playbook: M102 - 安全な編集モード（developer / admin モード）の仕様定義

## meta

```yaml
id: playbook-m102
derives_from: M102
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

admin/developer モードの本来の意味を明確化し、回復作業中のガードバイパス仕様を定義する。

---

## phases

### p0: 現行 Hook の調査

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: 全 Hook ファイル一覧を取得 ✓
- [x] **p0.2**: 各 Hook のカテゴリ（Guard/Check/Observer/Utility）を分類 ✓

---

### p1: security-modes.md の作成

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: docs/security-modes.md を作成 ✓
- [x] **p1.2**: 4つのモード（strict/trusted/developer/admin）を定義 ✓
- [x] **p1.3**: 各 Hook × 各モード の挙動マトリックスを作成 ✓
- [x] **p1.4**: admin モードに入る/出る手順を記載 ✓

---

## done_criteria verification

- [x] docs/security-modes.md が作成されている
- [x] strict/trusted/developer/admin の意味と挙動が定義されている
- [x] 各 Hook がどの mode で有効/緩和/無効になるかの一覧表がある
- [x] state.md の config.security の値と定義が一致している
