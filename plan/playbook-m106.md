# Playbook: M106 - context エントリポイントの一本化

## meta

```yaml
id: playbook-m106
derives_from: M106
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

セッション開始時に必ず読むべき情報を 1 ファイルに集約し、CLAUDE.md を軽量化する。

---

## phases

### p0: boot-context.md の作成

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/boot-context.md を作成 ✓
- [x] **p0.2**: 必須読み込み 3 ファイルを明記 ✓
- [x] **p0.3**: 作業フローを簡潔に記載 ✓
- [x] **p0.4**: 詳細ドキュメントへの参照を追加 ✓

---

### p1: CLAUDE.md の更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: CLAUDE.md の冒頭に boot-context.md への参照を追加 ✓
- [x] **p1.2**: CLAUDE.md が 200 行以内であることを確認 ✓ (198行)

---

## done_criteria verification

- [x] docs/boot-context.md が作成されている (103行)
- [x] CLAUDE.md の冒頭に boot-context.md への参照がある
- [x] CLAUDE.md が 200 行以内 (198行)

Note: init-guard.sh の更新は M113 (admin モード実装) と併せて行う
