# Playbook: Golden Path Chain Fix

```yaml
meta:
  project: golden-path-fix
  branch: fix/golden-path-chain
  created: 2025-12-24
  reviewed: true

context:
  what: Golden Path チェーン（Hook → Skill → SubAgent）の根本問題を修正
  why: playbook-init Skill が存在せず、チェーンが動作しない
  who: フレームワーク自体の修正
  when: 即時
  where: .claude/skills/, .claude/hooks/
  how: 不足している Skill を作成し、参照の不整合を修正

goal:
  summary: Golden Path チェーンを完全に動作させる
  done_when:
    - playbook-init Skill が存在する
    - playbook-guard.sh の穴が修正されている
    - 全ての参照が整合している
    - 統合テストで Hook → Skill → SubAgent チェーンが動作する

phases:
  - id: p1
    name: 根本問題の修正
    goal: playbook-init Skill 作成と参照修正
    executor: claudecode
    done_criteria:
      - .claude/skills/playbook-init/SKILL.md が存在する
      - playbook-guard.sh の exit 0 が exit 2 に修正されている
      - pm.md の参照不整合が修正されている
      - golden-path/SKILL.md の参照が整合している
    status: in_progress
```
