# Playbook: M110 - 計画駆動開発（playbook 必須）の E2E シナリオ設計

## meta

```yaml
id: playbook-m110
derives_from: M110
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

playbook=null での Edit/Write を防止するシナリオを定義し、現状の防止能力を評価する。

---

## phases

### p0: シナリオ設計

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/e2e-scenarios-plan-driven.md を作成 ✓
- [x] **p0.2**: 5 つのシナリオを定義 ✓
- [x] **p0.3**: pm SubAgent の役割を明記 ✓
- [x] **p0.4**: 構造的に防げないケースを列挙 ✓

---

## done_criteria verification

- [x] Playbook を無視する典型的なパターンが定義されている
- [x] playbook-guard / scope-guard / pm SubAgent の役割分担が明確
- [x] 『人間の手動編集でしか止められない』ケースが記録されている
  - sed バイパス（PD-003）は防げない
