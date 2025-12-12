# playbook: Hooks/SubAgents/Skills 強制力レビュー

> 作成日: 2025-12-12
> 優先度: 高
> 見積: 4h

---

## goal

```yaml
summary: "強制力100%担保を実現するため、Hooks/SubAgents/Skills を評価・最適化"
phase: "p0-evaluation"
done_criteria:
  - "シナリオ別フローの評価が完了し、問題点が特定されている"
  - "より効率的なアーキテクチャ案が提示されている"
  - "強制力の観点から全 Hooks が [BLOCK]/[WARN]/[INFO] の妥当性を検証されている"
  - "統合・削除候補が機能損失なしで実行されている"
  - "critic が PASS を返す"
```

---

## derives_from

```yaml
project: plan/active/project.md
milestone: "Hooks/SubAgents/Skills 完全整理"
task: "DW-005（継続）- 強制力100%担保"
```

---

## phases

### Phase 0: フロー評価

id: p0
name: "フロー評価"
goal: "シナリオ別フローチャートを評価し、make sense かどうか判定"
status: "done"

done_criteria:
  - "6つのシナリオフローの評価レポートが作成されている"
  - "フローの問題点（循環、重複、欠落）が特定されている"
  - "より効率的なアプローチが提案されている"

tasks:
  - id: t0
    name: "シナリオフロー評価"
    status: "done"
    subtasks:
      - step: "Scenario 1-6 のフローを評価"
        executor: claudecode
        criteria: "各シナリオに評価コメントが付与"
        status: "[x]"
      - step: "問題点を特定（循環、重複、欠落）"
        executor: claudecode
        criteria: "問題リストが作成"
        status: "[x]"
      - step: "より効率的なアーキテクチャを提案"
        executor: claudecode
        criteria: "提案が文書化"
        status: "[x]"

---

### Phase 1: 強制力分析・実行

id: p1
name: "強制力分析・実行"
goal: "全 Hooks の強制力レベルを検証し、100%担保を実現"
status: "done"
depends_on: [p0]
note: "ユーザー承認により分析と実行を統合"

done_criteria:
  - "[WARN] の Hooks が [BLOCK] に昇格すべきか判定されている"
  - "各 Hook の強制力レベルに理由が付与されている"
  - "強制力マトリクスが作成されている"

tasks:
  - id: t1
    name: "強制力検証"
    status: "done"
    subtasks:
      - step: "全 Hooks の強制力レベルを列挙"
        executor: claudecode
        criteria: "マトリクスが作成"
        status: "[x]"
      - step: "[WARN] の Hooks を [BLOCK] 候補として評価"
        executor: claudecode
        criteria: "昇格理由/維持理由が付与"
        status: "[x]"
      - step: "強制力100%担保の設計を確定"
        executor: claudecode
        criteria: "設計ドキュメントが作成"
        status: "[x]"

---

### Phase 2: 統合・削除計画

id: p2
name: "統合・削除計画"
goal: "機能損失なしの統合・削除計画を策定"
status: "done"
depends_on: [p1]

done_criteria:
  - "統合候補の機能マッピングが完了している"
  - "統合後のコードで全機能がカバーされることが確認されている"
  - "削除候補の影響分析が完了している"

tasks:
  - id: t2
    name: "機能マッピング"
    status: "done"
    subtasks:
      - step: "統合元の全機能を列挙"
        executor: claudecode
        criteria: "機能リストが作成"
        status: "[x]"
      - step: "統合後のコードで全機能がカバーされる設計"
        executor: claudecode
        criteria: "設計ドキュメントが作成"
        status: "[x]"
      - step: "削除候補の依存関係を確認"
        executor: claudecode
        criteria: "依存グラフが作成"
        status: "[x]"

---

### Phase 3: ユーザー確認

id: p3
name: "ユーザー確認"
goal: "評価結果と計画をユーザーに提示し、承認を取得"
status: "done"
depends_on: [p2]
note: "ユーザー承認「全て実行 ultrathink」により完了"

done_criteria:
  - "フロー評価結果がユーザーに提示されている"
  - "強制力マトリクスがユーザーに提示されている"
  - "統合・削除計画がユーザーに提示されている"
  - "ユーザーが対応方針を承認している"

tasks:
  - id: t3
    name: "ユーザー確認"
    status: "done"
    subtasks:
      - step: "評価結果を提示"
        executor: claudecode
        criteria: "結果が表示"
        status: "[x]"
      - step: "ユーザーの承認を取得"
        executor: user
        criteria: "承認が記録"
        status: "[x]"

---

### Phase 4: 実行

id: p4
name: "実行"
goal: "承認された変更を実行"
status: "done"
depends_on: [p3]

done_criteria:
  - "強制力の昇格が実行されている"
  - "統合が実行されている"
  - "削除が実行されている"
  - "ドキュメントが更新されている"

tasks:
  - id: t4
    name: "変更実行"
    status: "done"
    subtasks:
      - step: "強制力の昇格を実行"
        executor: claudecode
        criteria: "Hooks のコードが更新"
        status: "[x]"
      - step: "統合を実行"
        executor: claudecode
        criteria: "統合対象が 1 つにまとめられている"
        status: "[x]"
      - step: "削除を実行"
        executor: claudecode
        criteria: "削除対象が削除されている"
        status: "[x]"
      - step: "ドキュメント更新"
        executor: claudecode
        criteria: "inventory/feature-map.md/settings.json が更新"
        status: "[x]"

---

### Phase 5: 検証

id: p5
name: "検証"
goal: "変更が正しく反映され、機能が損なわれていないことを確認"
status: "done"
depends_on: [p4]

done_criteria:
  - "全シナリオフローが正常に動作する"
  - "settings.json の整合性が確認されている"
  - "回帰テストが PASS している"
  - "critic が PASS を返す"

tasks:
  - id: t5
    name: "検証"
    status: "done"
    subtasks:
      - step: "シナリオフローのシミュレーション"
        executor: claudecode
        criteria: "6シナリオ全て正常動作"
        status: "[x]"
      - step: "settings.json の整合性確認"
        executor: claudecode
        criteria: "登録 Hooks が全て存在"
        status: "[x]"
      - step: "critic 呼び出し"
        executor: claudecode
        criteria: "critic が PASS を返す"
        status: "[x]"

---

## metadata

```yaml
branch: refactor/hooks-review
```
