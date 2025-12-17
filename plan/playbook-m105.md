# Playbook: M105 - Hook チェーンの最小化

## meta

```yaml
id: playbook-m105
derives_from: M105
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

PreToolUse:Edit の Hook 連鎖を最小化し、編集ループをミニマルにする。

---

## phases

### p0: 現状分析

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: 現在の settings.json を確認 ✓
- [x] **p0.2**: PreToolUse:Edit に 8 個の Hook があることを確認 ✓

---

### p1: Hook 削減

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: settings.json の PreToolUse:Edit を 2 個に削減 ✓
  - check-protected-edit.sh（セキュリティ）
  - playbook-guard.sh（計画駆動）
- [x] **p1.2**: PreToolUse:Write も同様に削減 ✓
- [x] **p1.3**: PreToolUse:Bash を 1 個に削減 ✓
- [x] **p1.4**: PostToolUse:Edit から create-pr-hook.sh を削除 ✓

---

### p2: ドキュメント更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p2.1**: docs/hook-responsibilities.md を作成 ✓
- [x] **p2.2**: Tier 1/2/3 の分類を記載 ✓
- [x] **p2.3**: 削減の根拠を記載 ✓

---

## done_criteria verification

- [x] docs/hook-responsibilities.md が更新されている
- [x] PreToolUse:Edit に登録されている Hook が 2 個に削減（check-protected-edit / playbook-guard）
- [x] 削除された Hook は手動実行として文書化されている
