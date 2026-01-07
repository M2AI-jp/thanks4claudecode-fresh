# Critical/High Gap 優先リスト

> Generated: 2026-01-07
> Playbook: playbook-completion (p1.2)
> Source: play/playbook-completion/reports/gap-list.md

---

## 1. 概要

本 playbook の scope に従い、Critical/High severity の Gap のみを対応対象とする。

- **対象**: Critical/High severity の Gap
- **対象外**: Medium/Low severity の Gap（scope.excludes に明記）

---

## 2. Critical Gap（1件）

### GAP-C1: Project reviewer 検証なし

| 項目 | 内容 |
|------|------|
| **ID** | GAP-C1 |
| **severity** | Critical |
| **説明** | project 生成時に reviewer チェックがない |
| **影響** | 報酬詐欺防止の根幹が欠落 |
| **現状** | pm SubAgent → project.json 作成 → state.md 更新（検証なし） |
| **あるべき姿** | pm → project.json ドラフト → reviewer 検証 → PASS で確定 |

#### 対応方針

1. **修正箇所**: `.claude/skills/golden-path/agents/pm.md`
2. **修正内容**:
   - project 作成フローに reviewer 呼び出しステップを追加
   - PASS 後に meta.reviewed = true, meta.reviewed_by = "reviewer" を設定
3. **検証基準**: playbook と同じ 4QV+ フレームワーク

#### 関連修正

| 優先度 | 修正内容 | ファイル |
|--------|----------|----------|
| 1 | project.json テンプレートに meta.reviewed 追加 | `play/projects/template/project.json` |
| 2 | pm.md に project 用 reviewer チェック追加 | `.claude/skills/golden-path/agents/pm.md` |
| 3 | design-validation project.json に meta.reviewed 追加 | `play/projects/design-validation/project.json` |

---

## 3. High Gap（0件）

なし

---

## 4. 対応スケジュール

| Phase | 対応 Gap | 作業内容 |
|-------|----------|----------|
| p2.1 | GAP-C1 | pm.md に project 用 reviewer 検証ロジック追加 |
| p2.2 | GAP-C1 関連 | project.json テンプレートに meta.reviewed フィールド追加 |

---

## 5. 対象外（Medium/Low）

以下は本 playbook の scope 外:

### Medium（5件）

| ID | 説明 | 理由 |
|----|------|------|
| GAP-M1 | telemetry.sh 未実装 | 機能は動作中、運用監視は将来対応 |
| GAP-M2 | meta.reviewed 未実装 (project) | GAP-C1 の関連修正として対応 |
| GAP-M3 | meta.reviewed_by 未実装 (project) | 同上 |
| GAP-M4 | prompt-analyzer 未実装 (project) | project-init Skill は将来対応 |
| GAP-M5 | understanding-check 未実装 (project) | 同上 |

### Low（10件）

- validator.sh, context-injector.sh, guardrail.sh, snapshot.sh, retry.sh の未分離
- milestone depends-check, project scope-guard 未実装
- failure-logger.sh, generate-repository-map.sh 不存在
- Stop Hook ドキュメント古い

---

## 6. 結論

- **対応必須**: GAP-C1（Project reviewer 検証なし）→ p2 で対応
- **対応任意**: Medium/Low は scope 外
- **報酬詐欺防止**: p2 完了後、project 生成時も reviewer 検証が必須になる

---

## 7. 検証コマンド

```bash
# 本ファイルの存在確認
ls -la play/playbook-completion/reports/priority-list.md

# Critical/High の件数確認
grep -c "^### GAP-C" play/playbook-completion/reports/priority-list.md
grep -c "^### GAP-H" play/playbook-completion/reports/priority-list.md || echo "0"

# 対応方針の存在確認
grep -A5 "対応方針" play/playbook-completion/reports/priority-list.md
```
