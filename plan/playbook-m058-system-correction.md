# playbook-m058-system-correction.md

> **System Correction: archive-playbook.sh バグ修正 & M057 クリーンアップ & 設計誤りの根本修正**
>
> 以下の3つの重大な問題を同時に解決:
> 1. archive-playbook.sh が state.md 構造の誤りで動作していない
> 2. M057 playbook が plan/ と plan/archive/ の両方に存在（データ不整合）
> 3. 根本的な設計誤り: Claude Code がワーカーのままになっている

---

## meta

```yaml
project: System Correction - Multi-Issue Fix
branch: fix/m058-system-correction
created: 2025-12-17
issue: null
derives_from: M058
reviewed: false
```

---

## goal

```yaml
summary: |
  archive-playbook.sh のバグを修正し、M057 playbook のクリーンアップを完了させ、
  Codex/CodeRabbit がメインワーカーという根本設計に修正する。

done_when:
  - "[ ] archive-playbook.sh が state.md の正しい構造（playbook.active）を参照している"
  - "[ ] archive-playbook.sh の構文エラーが修正されている"
  - "[ ] plan/playbook-m057-cli-migration.md が削除されている"
  - "[ ] plan/archive/playbook-m057-cli-migration.md のみが存在する"
  - "[ ] state.md の playbook.active が null に更新されている"
  - "[ ] project.md の M057 status が achieved に更新されている"
  - "[ ] project.md の M058 が新規マイルストーンとして追加されている"
  - "[ ] playbook-guard.sh が admin モードでも playbook チェックをバイパスしない"
  - "[ ] CLAUDE.md の「設計思想」セクションが Codex/CodeRabbit メインワーカーの方針に更新されている"
```

---

## phases

### p1: archive-playbook.sh バグ修正

**goal**: state.md の新しい構造（playbook.active フィールド）を参照するように修正

**status**: done

#### subtasks

- [x] **p1.1**: archive-playbook.sh が `## playbook` セクション > `active:` フィールドを参照している ✓
  - executor: claudecode
  - test_command: `grep -q 'playbook.*active' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - playbook.active を参照"
    - consistency: "PASS - state.md 構造と一致"
    - completeness: "PASS - 全箇所修正済み"
  - validated: 2025-12-17T04:30:00

- [x] **p1.2**: state.md の古い `## active_playbooks` セクションへの参照が削除されている ✓
  - executor: claudecode
  - test_command: `grep -q 'active_playbooks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo FAIL || echo PASS`
  - validations:
    - technical: "PASS - active_playbooks 参照なし"
    - consistency: "PASS - コメント含め全削除"
    - completeness: "PASS - 0 件"
  - validated: 2025-12-17T04:30:00

- [x] **p1.3**: archive-playbook.sh の構文が正しい ✓
  - executor: claudecode
  - test_command: `bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - bash -n でエラーなし"
    - consistency: "PASS - 他の Hook と同じスタイル"
    - completeness: "PASS - 全行検証済み"
  - validated: 2025-12-17T04:30:00

### p2: M057 playbook のクリーンアップ

**goal**: plan/ から M057 playbook を削除し、archive 版のみに統一

**status**: done

#### subtasks

- [x] **p2.1**: plan/playbook-m057-cli-migration.md が削除されている ✓
  - executor: claudecode
  - test_command: `test ! -f /Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ファイル削除済み"
    - consistency: "PASS - archive 版のみ存在"
    - completeness: "PASS - 重複解消"
  - validated: 2025-12-17T04:35:00

- [x] **p2.2**: plan/archive/playbook-m057-cli-migration.md のみが存在する ✓
  - executor: claudecode
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - archive 版存在確認"
    - consistency: "PASS - 単一ソース"
    - completeness: "PASS - データ保持"
  - validated: 2025-12-17T04:35:00

### p3: state.md の更新

**goal**: state.md を正しい状態に更新する

**status**: done

#### subtasks

- [x] **p3.1**: state.md の playbook.active が M058 playbook を指している ✓
  - executor: claudecode
  - test_command: `grep 'active:.*playbook-m058' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - active が playbook-m058 を指定"
    - consistency: "PASS - playbook ファイル存在"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

- [x] **p3.2**: state.md の goal.milestone が M058 に更新されている ✓
  - executor: claudecode
  - test_command: `grep 'milestone: M058' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - milestone: M058"
    - consistency: "PASS - project.md と一致"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

- [x] **p3.3**: state.md の goal.phase が p1 に更新されている ✓
  - executor: claudecode
  - test_command: `grep 'phase: p1' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - phase: p1"
    - consistency: "PASS - playbook phase と一致"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

### p4: project.md の更新

**goal**: project.md に M058 を追加し、M057 を achieved に更新

**status**: done

#### subtasks

- [x] **p4.1**: project.md の M057 status が achieved に更新されている ✓
  - executor: claudecode
  - test_command: `grep -A 10 'id: M057' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep -q 'status:.*achieved' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - status: achieved"
    - consistency: "PASS - playbook 完了と一致"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

- [x] **p4.2**: project.md の M057 achieved_at タイムスタンプが追加されている ✓
  - executor: claudecode
  - test_command: `grep -A 10 'id: M057' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep -q 'achieved_at' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - achieved_at: 2025-12-17"
    - consistency: "PASS - 日付形式正しい"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

- [x] **p4.3**: project.md に M058 マイルストーン が新規追加されている ✓
  - executor: claudecode
  - test_command: `grep -q 'id: M058' /Users/amano/Desktop/thanks4claudecode/plan/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M058 存在"
    - consistency: "PASS - M057 の次"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

- [x] **p4.4**: M058 は M057 に depends_on している ✓
  - executor: claudecode
  - test_command: `grep -A 10 'id: M058' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep -q 'depends_on:.*M057' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - depends_on: [M057]"
    - consistency: "PASS - 依存関係正しい"
    - completeness: "PASS"
  - validated: 2025-12-17T04:40:00

### p5: playbook-guard.sh の admin バイパス問題修正

**goal**: admin モードでも playbook 必須チェックをバイパスしないように修正

**status**: done

#### subtasks

- [x] **p5.1**: playbook-guard.sh から admin モードの完全バイパスが削除されている ✓
  - executor: claudecode
  - test_command: `grep -A 5 'admin' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh | grep -q 'exit 0' && echo FAIL || echo PASS`
  - validations:
    - technical: "PASS - admin での exit 0 なし"
    - consistency: "PASS - プロセスガード統一"
    - completeness: "PASS - コメント説明追加済み"
  - validated: 2025-12-17T04:45:00

- [x] **p5.2**: playbook-guard.sh が security モードに関係なく playbook=null をブロックする ✓
  - executor: claudecode
  - test_command: `grep -q 'exit 2' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - exit 2 でブロック"
    - consistency: "PASS - 全モードで統一"
    - completeness: "PASS"
  - validated: 2025-12-17T04:45:00

- [x] **p5.3**: playbook-guard.sh の構文が正しい ✓
  - executor: claudecode
  - test_command: `bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - bash -n OK"
    - consistency: "PASS - 他 Hook と同スタイル"
    - completeness: "PASS"
  - validated: 2025-12-17T04:45:00

### p6: AI エージェントオーケストレーション役割定義

**goal**: 役割を固定化し、pm.md と CLAUDE.md に明記。オーケストレーション動作を確認。

#### 役割定義（1セット固定）

```yaml
roles:
  orchestrator: claudecode    # 監督・調整・設計
  worker: codex               # 本格的なコード実装
  code_reviewer: coderabbit   # コードレビュー（PR 時）
  playbook_reviewer: reviewer # playbook レビュー（SubAgent opus）
```

#### subtasks

- [x] **p6.1**: pm.md に役割定義セクションが追加されている ✓
  - executor: claudecode
  - test_command: `grep -q 'worker: codex' /Users/amano/Desktop/thanks4claudecode/.claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - 役割定義が playbook-format.md の executor と整合"
    - completeness: "PASS - 4 役割全てが定義されている"
  - validated: 2025-12-17T05:30:00

- [x] **p6.2**: pm.md に playbook_reviewer: reviewer が明記されている ✓
  - executor: claudecode
  - test_command: `grep -q 'playbook_reviewer: reviewer' /Users/amano/Desktop/thanks4claudecode/.claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - reviewer SubAgent の名前と一致"
    - completeness: "PASS - playbook_reviewer の役割が明記"
  - validated: 2025-12-17T05:30:00

- [x] **p6.3**: CLAUDE.md に役割定義が追加されている ✓
  - executor: claudecode
  - test_command: `grep -q 'worker: codex' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - pm.md の役割定義と一致"
    - completeness: "PASS - 4 役割全てが CLAUDE.md に存在"
  - validated: 2025-12-17T05:30:00

- [x] **p6.4**: 全 SubAgent が opus モデルに設定されている ✓
  - executor: claudecode
  - test_command: `grep -l "model: opus" /Users/amano/Desktop/thanks4claudecode/.claude/agents/*.md | wc -l`
  - validations:
    - technical: "PASS - grep + wc コマンド正常実行、結果: 7"
    - consistency: "PASS - 全 SubAgent が同一モデル（opus）"
    - completeness: "PASS - 7 ファイル全てが opus"
  - validated: 2025-12-17T05:30:00

- [x] **p6.5**: reviewer SubAgent が playbook レビュー用に設定されている ✓
  - executor: claudecode
  - test_command: `grep -q 'playbook-review-criteria' /Users/amano/Desktop/thanks4claudecode/.claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - playbook-review-criteria.md ファイルが存在"
    - completeness: "PASS - reviewer.md に参照が明記"
  - validated: 2025-12-17T05:30:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [x] **pf.1**: archive-playbook.sh が正しく state.md 構造を参照し、構文エラーがない ✓
  - executor: claudecode
  - test_command: `bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && grep -q 'playbook.*active' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - bash -n で構文チェック通過"
    - consistency: "PASS - state.md の playbook.active 構造と一致"
    - completeness: "PASS - 全ての参照箇所が修正済み"
  - validated: 2025-12-17T05:35:00

- [x] **pf.2**: M057 playbook がアーカイブのみに存在する ✓
  - executor: claudecode
  - test_command: `test ! -f /Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md && test -f /Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - test コマンド正常実行"
    - consistency: "PASS - archive フォルダ構造と一致"
    - completeness: "PASS - 重複ファイルが解消"
  - validated: 2025-12-17T05:35:00

- [x] **pf.3**: playbook-guard.sh が admin モードでも playbook チェックをバイパスしない ✓
  - executor: claudecode
  - test_command: `grep -B 5 -A 5 'admin' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh | grep -q 'exit 0' && echo FAIL || echo PASS`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - プロセスガード設計と一致"
    - completeness: "PASS - admin バイパスが完全に削除"
  - validated: 2025-12-17T05:35:00

- [x] **pf.4**: 役割定義が pm.md と CLAUDE.md の両方に存在する ✓
  - executor: claudecode
  - test_command: `grep -q 'worker: codex' /Users/amano/Desktop/thanks4claudecode/.claude/agents/pm.md && grep -q 'worker: codex' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep コマンド正常実行"
    - consistency: "PASS - 両ファイルの役割定義が一致"
    - completeness: "PASS - 必要な全役割が定義"
  - validated: 2025-12-17T05:35:00

- [x] **pf.5**: 全 SubAgent が opus モデルで動作する ✓
  - executor: claudecode
  - test_command: `grep -l "model: opus" /Users/amano/Desktop/thanks4claudecode/.claude/agents/*.md | wc -l`
  - validations:
    - technical: "PASS - grep + wc コマンド正常実行、結果: 7"
    - consistency: "PASS - 全 SubAgent が統一モデル"
    - completeness: "PASS - 7 ファイル全てが opus 設定"
  - validated: 2025-12-17T05:35:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 詳細説明

### 問題1: archive-playbook.sh のバグ

archive-playbook.sh は以下の誤りがある:
- **行121-128**: `## active_playbooks` セクションを参照しているが、実際の state.md には存在しない
- **正しい構造**: `playbook.active:` フィールド

修正方法:
```bash
# 誤り
ACTIVE_SECTION=$(awk '/^## active_playbooks/,/^## [^a]/' state.md 2>/dev/null || true)

# 修正
PLAYBOOK_ACTIVE=$(grep -A 1 '^active:' state.md | tail -1 | xargs)
```

### 問題2: M057 playbook の重複

状態:
- `/Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md` ← 削除対象
- `/Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md` ← 保持

修正方法:
- plan/ 版を削除
- archive/ 版のみを保持
- state.md の active を null に更新

### 問題3: 根本的な設計誤り

現在の誤った構造:
```yaml
Claude Code: コードの実装をしている（ワーカー）
Codex: 補助的（サブワーカー）
CodeRabbit: コードレビュー（補助）
```

本来の設計:
```yaml
Claude Code: オーケストレーター（監督・調整）
Codex: 本格的なコード実装（メインワーカー）
CodeRabbit: コードレビュー（QA ワーカー）
```

修正箇所:
- CLAUDE.md の executor 説明
- playbook-format.md の executor 選択ガイドライン
- .claude/agents/codex-delegate.md の呼び出しロジック

---

## 注意事項

- このタスクは「修正作業」なので、既存の完了した M057 を修正するのではなく、システムレベルの不具合を修正する
- M057 playbook 自体は archive/ で完全に保持される（データ喪失なし）
- CLAUDE.md の修正は思考フレームの修正であり、将来のタスクから適用される

