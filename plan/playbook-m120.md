# Playbook: M120 - このリポジトリの最終的な扱いを決める

## meta

```yaml
id: playbook-m120
derives_from: M120
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

E2E 検証とシンプル化の結果を踏まえて、thanks4claudecode を
1) テンプレート化
2) 博物館化
3) 凍結（廃棄）
のいずれかに決定する。

---

## phases

### p0: 最終決定

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: E2E テスト結果を分析 ✓
- [x] **p0.2**: 3 つの選択肢を評価 ✓
- [x] **p0.3**: docs/final-decision.md を作成 ✓

---

### p1: ドキュメント更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: README.md を「実験博物館」として更新 ✓
- [x] **p1.2**: state.md の focus.current を archived に変更 ✓
- [x] **p1.3**: playbook.active を null に設定 ✓

---

## done_criteria verification

- [x] docs/final-decision.md に、選択した方針と理由が記録されている
  - 方針: 博物館化（Experimental Archive）
  - 理由: テンプレートとしては複雑すぎ、廃棄するには学びが多い
- [x] README.md の冒頭に、このリポジトリの位置づけが明記されている
  - 「📦 Experimental Archive（実験博物館）」
- [x] state.md の focus/current が、最終方針に合わせて更新されている
  - current: archived
