# Playbook: M107 - Single Source of Truth 明確化

## meta

```yaml
id: playbook-m107
derives_from: M107
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

各情報の正本を明確化し、重複定義を禁止するルールを確立する。

---

## phases

### p0: SSoT ドキュメント作成

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/single-source-of-truth.md を作成 ✓
- [x] **p0.2**: 正本一覧を定義 ✓
- [x] **p0.3**: 派生ファイルの役割を明記 ✓
- [x] **p0.4**: 禁止事項を記載 ✓

---

## done_criteria verification

- [x] docs/single-source-of-truth.md に正本が一覧化されている
- [x] current-definitions.md と deprecated-references.md の役割が明文化されている
- [x] repository-map.yaml が正本であると明記されている

Note: 重複定義の実際の削除は M108 で対応
