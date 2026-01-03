# playbook-self-evaluation-defense.md

## meta

```yaml
project: self-evaluation-defense
branch: refactor/skill-audit-v2
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: LLM 自己評価バイアス（報酬詐欺）防衛設計のフレームワークドキュメントを作成する
done_when:
  - .claude/frameworks/self-evaluation-defense.md が存在する
  - 5つの核心（Goodhart, 自己採点脆弱性, 攻略パターン, 防衛原則, 実装パターン）が構造化されている
  - CLAUDE.md の報酬詐欺防止セクションと整合性がある
```

---

## context

```yaml
5w1h:
  who: Claude（LLM）が参照・内在化する
  what: LLM 自己評価バイアス防衛設計のフレームワークドキュメント
  when: 現セッションで完了
  where: .claude/frameworks/self-evaluation-defense.md
  why: 自己評価バイアス（報酬詐欺）に関する洞察を Claude 自身が深く理解できるよう永続化
  how: 5つの核心を構造化ドキュメントとして記述

analysis_result:
  source: inline-analysis
  timestamp: 2026-01-03T14:00:00Z
  data:
    summary: 単発のドキュメント作成タスク。内容は既に分析済み。
    risks:
      technical: []
      scope: []
      dependency: []
    ambiguity: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T14:00:00Z
  summary: |
    LLM 自己評価バイアス防衛設計ドキュメントを作成。
    5つの核心を構造化して .claude/frameworks/self-evaluation-defense.md に配置。
```

---

## phases

### p1: ドキュメント作成

**goal**: 5つの核心を構造化したフレームワークドキュメントを作成する

#### subtasks

- [x] **p1.1**: .claude/frameworks/self-evaluation-defense.md が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f 実行、ファイル存在確認"
    - consistency: "PASS - CLAUDE.md の報酬詐欺防止セクションと整合性確認済"
    - completeness: "PASS - 5つの核心が全て含まれている"
  - validated: 2026-01-03T14:15:00

- [x] **p1.2**: Goodhart の法則と LLM のセクションが定義されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 1.1 存在確認"
    - consistency: "PASS - 概念の説明が正確"
    - completeness: "PASS - 指標最適化の問題が説明されている"
  - validated: 2026-01-03T14:15:00

- [x] **p1.3**: 自己採点の脆弱性セクションが定義されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 1.2 存在確認"
    - consistency: "PASS - 脆弱性の本質が説明されている"
    - completeness: "PASS - なぜ壊れやすいかが説明されている"
  - validated: 2026-01-03T14:15:00

- [x] **p1.4**: 三つの攻略パターンセクションが定義されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 2 存在確認"
    - consistency: "PASS - 3パターンが全て記載されている"
    - completeness: "PASS - Pattern A/B/C が含まれる"
  - validated: 2026-01-03T14:15:00

- [x] **p1.5**: 防衛設計原則セクションが定義されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 3 存在確認"
    - consistency: "PASS - 5原則が全て記載されている"
    - completeness: "PASS - 3.1-3.5 が含まれる"
  - validated: 2026-01-03T14:15:00

- [x] **p1.6**: 実装パターンセクションが定義されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 4 存在確認"
    - consistency: "PASS - パターンが実装可能な形式"
    - completeness: "PASS - 4.1-4.3 が含まれる"
  - validated: 2026-01-03T14:15:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: .claude/frameworks/self-evaluation-defense.md が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f 実行、EXISTS 確認"
    - consistency: "PASS - ファイルパスが正しい"
    - completeness: "PASS - ファイルは 400 行以上"
  - validated: 2026-01-03T14:16:00

- [x] **p_final.2**: 5つの核心が構造化されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 10 セクション見出しを確認"
    - consistency: "PASS - 各セクションが独立した見出しを持つ"
    - completeness: "PASS - Goodhart、自己採点脆弱性、攻略パターン、防衛原則、実装パターンが含まれる"
  - validated: 2026-01-03T14:16:00

- [x] **p_final.3**: CLAUDE.md との整合性がある
  - executor: claudecode
  - validations:
    - technical: "PASS - CLAUDE.md の reward_fraud_prevention セクションと比較完了"
    - consistency: "PASS - 用語と概念が一致している（報酬詐欺、critic、独立検証）"
    - completeness: "PASS - CLAUDE.md で言及されている概念が全てカバーされている"
  - validated: 2026-01-03T14:16:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
