# Playbook: M109 - 報酬詐欺防止の E2E シナリオテスト設計

## meta

```yaml
id: playbook-m109
derives_from: M109
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

「LLM が done と言っているが実際は done ではない」ケースを定義し、防止策を評価する。

---

## phases

### p0: シナリオ設計

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/e2e-scenarios-reward-fraud.md を作成 ✓
- [x] **p0.2**: 5 つのシナリオを Given/When/Then 形式で定義 ✓
- [x] **p0.3**: 各シナリオの expected_blocker を明記 ✓
- [x] **p0.4**: 現状での防止能力を評価 ✓
- [x] **p0.5**: 構造的に防げないケースを正直に列挙 ✓

---

## done_criteria verification

- [x] 5 つ以上のシナリオが Given/When/Then 形式で定義されている
- [x] 各シナリオに expected_blocker が明記されている
- [x] 『現状では防げない』シナリオが正直に列挙されている
  - RF-003: LLM が critic を呼ばなければ防げない
  - 手動バイパス（sed 等）は防げない
