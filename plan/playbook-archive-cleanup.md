# playbook-archive-cleanup.md

> **一時的なブートストラップ playbook（アーカイブ処理完了用）**

---

## meta

```yaml
branch: main
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: Change Control playbook のアーカイブ処理を完了する
done_when:
  - state.md が正しく更新されている
  - playbook ファイルが削除されている
```

---

## phases

### p1: クリーンアップ

**goal**: アーカイブ処理を完了

**status**: in_progress
