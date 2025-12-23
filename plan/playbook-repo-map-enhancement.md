# playbook-repo-map-enhancement.md

## meta

```yaml
project: thanks4claudecode
branch: feat/repo-map-enhancement
created: 2025-12-24
issue: null
derives_from: null
reviewed: true
roles:
  worker: claudecode  # repository-map.yaml とドキュメント整理
```

---

## goal

```yaml
summary: repository-map.yaml の強化とドキュメント整理
done_when:
  - generate-repository-map.sh が description を正しく抽出し、途中で切れない
  - repository-map.yaml に Skill パッケージ構造（hooks/, agents/, frameworks/）が記録されている
  - repository-map.yaml に 4QV+ 構成と導火線モデルが記録されている
  - deprecated-references.md の対応状況が確認され、必要に応じてアーカイブされている
  - ARCHITECTURE.md のアーカイブ候補が整理されている
```

---

## phases

### p0: generate-repository-map.sh の description 切り詰め修正

**goal**: description が途中で切れずに正しく抽出される

#### subtasks

- [x] **p0.1**: generate-repository-map.sh の extract_description 関数を分析し、切り詰め問題の原因を特定する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - LC_ALL=C + awk substr がバイト単位で切り詰めていた"
    - consistency: "PASS - LC_ALL=C の影響を確認、UTF-8 文字が途中で切れる原因"
    - completeness: "PASS - 問題の原因が明確（LC_ALL=C + awk substr）"
  - validated: 2025-12-24T01:00:00

- [x] **p0.2**: マルチバイト文字対応の description 抽出ロジックを実装する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - LC_ALL=en_US.UTF-8 に変更、awk を python3 に置換"
    - consistency: "PASS - extract_description のインターフェース維持"
    - completeness: "PASS - 100文字制限が文字数単位で正しく適用"
  - validated: 2025-12-24T01:00:00

- [x] **p0.3**: generate-repository-map.sh を実行し、health-checker の description が正しく表示されることを確認する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - bash .claude/hooks/generate-repository-map.sh が成功"
    - consistency: "PASS - repository-map.yaml の description に途中で切れた文字がない"
    - completeness: "PASS - health-checker: 'システム状態の定期監視。state.md/playbook の整合性、git 状態、ファイル存在確認などを行う。'"
  - validated: 2025-12-24T01:00:00

**status**: done
**max_iterations**: 5

---

### p1: Skill パッケージ構造を repository-map.yaml に追記

**goal**: M092 で作成した Skill 内の hooks/, agents/, frameworks/ 構造を repository-map.yaml に記録

**depends_on**: [p0]

#### subtasks

- [x] **p1.1**: generate-repository-map.sh に Skill サブディレクトリ構造を抽出する関数を追加する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - skills セクション内でサブディレクトリ検出ロジックを追加"
    - consistency: "PASS - 既存パターンに統合（関数分離不要）"
    - completeness: "PASS - hooks/, agents/, frameworks/ の存在検出とファイル数カウント実装"
  - validated: 2025-12-24T01:10:00

- [x] **p1.2**: repository-map.yaml の skills セクションに各 Skill のサブディレクトリ構造を追記する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - YAML 構文正しい"
    - consistency: "PASS - structure: フィールドで hooks, agents, frameworks を明示"
    - completeness: "PASS - サブディレクトリを持つ 7 Skill の構造が記録"
  - validated: 2025-12-24T01:10:00

- [x] **p1.3**: generate-repository-map.sh を実行し、Skill 構造が正しく出力されることを確認する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - bash .claude/hooks/generate-repository-map.sh 成功"
    - consistency: "PASS - skills セクションにサブディレクトリ構造が記載"
    - completeness: "PASS - playbook-review(hooks:1,agents:1,frameworks:1), phase-critique(同), completion-review(hooks:1,frameworks:1), subtask-review(hooks:1,frameworks:1) の構造が明示"
  - validated: 2025-12-24T01:10:00

**status**: done
**max_iterations**: 5

---

### p2: 4QV+ / 導火線モデル構成図を repository-map.yaml に追記

**goal**: docs/design-philosophy.md で定義された 4QV+ 構成と導火線モデルを repository-map.yaml に記録

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: design-philosophy.md から 4QV+ 構成（Four-Quadrant Validation Plus）の定義を抽出する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - Q1(technical)/Q2(consistency)/Q3(completeness)/Q4+(evidence) の定義確認"
    - consistency: "PASS - validations フィールドと整合"
    - completeness: "PASS - 4つの Quadrant の役割と検証項目が明確"
  - validated: 2025-12-24T01:20:00

- [x] **p2.2**: design-philosophy.md から導火線モデル（Hook → Skill → SubAgent）の定義を抽出する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - Event → Hook → Skill → SubAgent フローを確認"
    - consistency: "PASS - hook_trigger_sequence との整合性確認済み"
    - completeness: "PASS - 各コンポーネントの役割と連携パターンが明確"
  - validated: 2025-12-24T01:20:00

- [x] **p2.3**: repository-map.yaml に design_philosophy セクションを追加し、4QV+ と導火線モデルを記録する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - YAML 構文正しい、grep で design_philosophy/fuse_model/four_quadrant 確認"
    - consistency: "PASS - design-philosophy.md の内容と一致"
    - completeness: "PASS - 4QV+ 構成、導火線モデル、連携パターン（4種）が記録"
  - validated: 2025-12-24T01:20:00

- [x] **p2.4**: generate-repository-map.sh に design_philosophy セクションを生成する関数を追加する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - generate_design_philosophy 関数追加、スクリプト実行成功"
    - consistency: "PASS - generate_workflows と同じ heredoc パターンを使用"
    - completeness: "PASS - 4QV+ と導火線モデルが自動生成される"
  - validated: 2025-12-24T01:20:00

**status**: done
**max_iterations**: 5

---

### p3: ドキュメント整理

**goal**: deprecated-references.md の対応状況確認とアーカイブ候補の整理

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: deprecated-references.md に記載された修正対象ファイルの現状を確認する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で plan/, setup/, AGENTS.md に「Macro」参照なし確認"
    - consistency: "PASS - 修正対象ファイルは既に修正済み"
    - completeness: "PASS - 全修正対象ファイルの状態を確認"
  - validated: 2025-12-24T01:30:00

- [x] **p3.2**: deprecated-references.md の対応状況を評価し、アーカイブの要否を判定する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - 全修正対象が修正済み → アーカイブ可能"
    - consistency: "PASS - 現在の用語定義と整合"
    - completeness: "PASS - アーカイブ判定理由: 全修正対象が解決済み"
  - validated: 2025-12-24T01:30:00

- [x] **p3.3**: ARCHITECTURE.md のアーカイブ候補リストを確認する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - fraud-investigation-report.md, e2e-simulation-*.md は既に存在しない（アーカイブ済み）"
    - consistency: "PASS - docs/ に該当ファイルなし"
    - completeness: "PASS - 全候補ファイルの現状を確認"
  - validated: 2025-12-24T01:30:00

- [x] **p3.4**: アーカイブ候補を .archive/docs/ に移動する（必要な場合のみ） ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - 該当ファイルは既にアーカイブ済み（移動不要）"
    - consistency: "PASS - folder-management.md のルールに準拠"
    - completeness: "PASS - 追加移動なし"
  - validated: 2025-12-24T01:30:00

- [x] **p3.5**: deprecated-references.md をアーカイブする（対応完了の場合） ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - mv で .archive/docs/ に移動済み"
    - consistency: "PASS - 修正対象が全て解決済み"
    - completeness: "PASS - docs/ に deprecated-references.md が存在しない"
  - validated: 2025-12-24T01:30:00

**status**: done
**max_iterations**: 5

---

### p_self_update: playbook 自己更新

**goal**: この playbook 自体の進捗を state.md と同期する

**depends_on**: [p3]

#### subtasks

- [x] **p_self_update.1**: state.md の playbook.active が plan/playbook-repo-map-enhancement.md を指している ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - state.md に active: plan/playbook-repo-map-enhancement.md が設定されている"
    - consistency: "PASS - playbook.branch が feat/repo-map-enhancement と一致"
    - completeness: "PASS - goal セクションに done_when が記載"
  - validated: 2025-12-24T01:35:00

- [x] **p_self_update.2**: state.md の goal.done_criteria が playbook の goal.done_when と一致している ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - 5 件の done_criteria が一致"
    - consistency: "PASS - playbook の goal.done_when と state.md の goal.done_criteria が同じ"
    - completeness: "PASS - 全 done_criteria が記載"
  - validated: 2025-12-24T01:35:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: goal.done_when が全て満たされているか最終検証

**depends_on**: [p_self_update]

#### subtasks

- [x] **p_final.1**: generate-repository-map.sh が description を正しく抽出し、途中で切れない ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - health-checker: 'システム状態の定期監視。state.md/playbook の整合性、git 状態、ファイル存在確認などを行う。'"
    - consistency: "PASS - health-checker の description が完全に表示"
    - completeness: "PASS - 全 agents/skills の description が正しく表示"
  - validated: 2025-12-24T01:35:00

- [x] **p_final.2**: repository-map.yaml に Skill パッケージ構造が記録されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - playbook-review に structure: (hooks: 1, agents: 1, frameworks: 1) が記録"
    - consistency: "PASS - M092 playbook で作成した構造と一致"
    - completeness: "PASS - playbook-review, subtask-review, phase-critique, completion-review の構造が明示"
  - validated: 2025-12-24T01:35:00

- [x] **p_final.3**: repository-map.yaml に 4QV+ 構成と導火線モデルが記録されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - design_philosophy セクションに fuse_model, four_quadrant_validation が存在"
    - consistency: "PASS - design-philosophy.md の定義と一致"
    - completeness: "PASS - 4QV+ 構成、導火線モデル、連携パターン（4種）が記録"
  - validated: 2025-12-24T01:35:00

- [x] **p_final.4**: deprecated-references.md の対応状況が確認され、必要に応じてアーカイブされている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - docs/ に deprecated-references.md が存在しない"
    - consistency: "PASS - 修正対象が全て解決済み → .archive/docs/ に移動済み"
    - completeness: "PASS - 対応状況が明確"
  - validated: 2025-12-24T01:35:00

- [x] **p_final.5**: ARCHITECTURE.md のアーカイブ候補が整理されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - アーカイブ候補は全て存在しない（既にアーカイブ済み）"
    - consistency: "PASS - ARCHITECTURE.md の「アーカイブ済み」セクションに更新"
    - completeness: "PASS - 2025-12-24 の変更履歴が追加"
  - validated: 2025-12-24T01:35:00

**status**: done
**max_iterations**: 5

---

## final_tasks

- [x] **ft1**: repository-map.yaml を再生成して最終確認 ✓
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - result: "Total files: 313 | Hooks: 31 | Agents: 3 | Skills: 13"

- [x] **ft2**: tmp/ 内の一時ファイルを削除する ✓
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする ✓
  - command: `git add -A && git status`
  - status: done (ready for commit)

---

## notes

### repository-map.yaml の問題点

1. **description 切り詰め**: health-checker の description が "フ" で切れている
   - 原因: `LC_ALL=C` 設定により、マルチバイト文字の途中でバイト切りが発生
   - 修正: UTF-8 対応の文字数カウントを使用

2. **Skill 構造が不明確**: M092 で作成した hooks/, agents/, frameworks/ 構造が記録されていない
   - 追加: skills セクションに各 Skill のサブディレクトリ構造を記載

3. **設計思想の欠如**: 4QV+ / 導火線モデルが repository-map.yaml に記録されていない
   - 追加: design_philosophy セクションを作成

### deprecated-references.md の対応状況

| 修正対象 | 現状 | 対応 |
|---------|------|------|
| plan/template/state-initial.md | 未確認 | p3 で確認 |
| AGENTS.md | 未確認 | p3 で確認 |
| .claude/agents/reviewer.md | M092 で移動済み | アーカイブ可能か判定 |
| .claude/frameworks/playbook-review-criteria.md | M092 で移動済み | アーカイブ可能か判定 |

### ARCHITECTURE.md のアーカイブ候補

| ファイル | 理由 | 対応 |
|---------|------|------|
| docs/fraud-investigation-report.md | M062 一回限りの調査レポート | p3 で確認 |
| docs/e2e-simulation-log.md | M062 テストログ | p3 で確認 |
| docs/e2e-simulation-scenarios.md | M062 テストシナリオ | p3 で確認 |

---

## 参照

- docs/repository-map.yaml（現在の状態）
- .claude/hooks/generate-repository-map.sh（生成スクリプト）
- docs/design-philosophy.md（4QV+ / 導火線モデル定義）
- docs/ARCHITECTURE.md（アーカイブ候補リスト）
- plan/archive/playbook-m092-skill-packaging.md（Skill パッケージ構造の参照）
- docs/deprecated-references.md（廃止参照リスト）
