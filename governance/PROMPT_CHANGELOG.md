# Prompt Changelog

> Change log for CLAUDE.md (Frozen Constitution)
> All changes to CLAUDE.md MUST be recorded here.

---

## [Unreleased]

(No unreleased changes)

---

## [2.0.0] - 2025-12-24

### Added
- Section 1: 設計思想（purpose, problem_statement, solution trinity）
- Section 2: 保護アーキテクチャ（4QV+ 導火線モデル、L1-L3 レイヤー構造）
- reward_fraud_prevention ルール（critic による独立検証必須）

### Changed
- 全セクションを YAML 形式に統一（LLM 向け最適化）
- 日本語に統一（言語混在を解消）
- セクション構成を 12 → 7 に再編（MECE 化）
- 行数を 262 → 230 に削減（12% 圧縮）

### Removed
- Section 2 (Operating Principles) - 汎用的すぎるため削除
- Section 3 (Non-Negotiables) - Core Contract に統合
- Section 4 (Quality Bar) - 実行プロトコルに統合
- Section 6 (Communication Rules) - 汎用的すぎるため削除
- Section 9 (Prohibited Actions) - Core Contract に統合
- Section 12 (Admin Mode Contract) - Core Contract に統合

### Rationale
CLAUDE.md は LLM のシステムプロンプトとして機能する。以下の問題を解決：
1. **設計思想の欠如**: 「なぜこのフレームワークが存在するか」が不明だった
2. **MECE でない**: Non-Negotiables と Prohibited Actions が重複
3. **汎用的すぎる**: セクション 2-6 は一般的な Claude ルールで冗長
4. **保護メカニズム不明**: 4QV+ アーキテクチャへの言及がなかった
5. **言語混在**: 英語/日本語が混在

### Risk Assessment
- CLAUDE.md は全セッションで読み込まれる最重要ファイル
- 大規模な再編のため、意図しない動作変更のリスクあり
- 移行期間は旧バージョンとの差分を監視

### Verification
1. 設計思想が明記されていることを確認: `grep "problem_statement" CLAUDE.md`
2. 4QV+ アーキテクチャが記載されていることを確認: `grep "導火線モデル" CLAUDE.md`
3. コア契約が維持されていることを確認: `grep "golden_path" CLAUDE.md`
4. タスク依頼時のフローが正しく動作することをテスト

---

## [1.2.0] - 2025-12-24

### Changed
- Section 11 (Core Contract) の golden_path.action を修正
  - 旧: `Task(subagent_type='pm', prompt='playbook を作成')`
  - 新: `Skill(skill='playbook-init')` を呼ぶ（Hook→Skill→SubAgent チェーン経由）
- 直接 Task(pm) を呼ぶことを禁止事項として明記

### Rationale
CLAUDE.md の記述が「Task(subagent_type='pm') を直接呼べ」と誤解を招き、期待される Hook→Skill→SubAgent チェーンを無視する動作を誘発していた。テスト結果で Skill(playbook-init) を呼ばずに直接 Task(pm) を呼ぶ違反が確認されたため、正しいフローを明記する。

### Risk Assessment
- CLAUDE.md は全セッションで読み込まれる重要ファイル
- 誤った記述は全ての LLM 動作に影響する
- 修正により Golden Path の意図通りの動作が保証される

### Verification
1. `grep "Skill(playbook-init)" CLAUDE.md` で新しい記述が見つかること
2. タスク依頼時に Skill 経由で pm が呼ばれることを確認
3. scripts/e2e-contract-test.sh で回帰テスト

---

## [1.1.0] - 2025-12-18

### Added
- Section 11: Core Contract（Golden Path, Playbook Gate, Reviewer Gate）
- Section 12: Admin Mode Contract（admin 権限の境界を明確化）

### Rationale
Core Contract を CLAUDE.md に明記し、admin モードでも回避不可のルールを確立。

---

## [1.0.0] - 2025-12-18

### Added
- Initial frozen constitution for Claude (CLAUDE.md)
- 10 sections covering principles, constraints, quality bar, workflow
- Change Control section (Section 10)
- Version history tracking

### Changed
- Reduced from 648 lines to 215 lines
- Extracted all procedures to RUNBOOK.md
- Removed volatile content (specific milestones, tool details)

### Governance Added
- `governance/PROMPT_CHANGELOG.md` (this file)
- `scripts/lint_prompts.py` for automated validation
- `.github/workflows/prompt-lint.yml` for CI enforcement
- `eval/` directory for regression tests

### Rationale
The previous CLAUDE.md was too long (648 lines), contained volatile information that required frequent updates, and had no change control mechanism. This refactor establishes CLAUDE.md as a stable "constitution" that changes rarely, with procedures moved to RUNBOOK.md which can evolve freely.

---

## Template for Future Changes

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New section or rule

### Changed
- Modification to existing content

### Removed
- Deleted content

### Rationale
Why this change was necessary.

### Risk Assessment
Potential impacts of this change.

### Verification
How to verify this change works correctly.
```
