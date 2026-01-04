# コア機能再分類報告書

> **視点**: 「正常に動作していなくてもいいが、正常に動作すればより良くなる機能がコア機能」
>
> 作成日: 2026-01-04
> 根拠: FizzBuzz ドッグフーディング (plan/playbook-fizzbuzz-dogfooding.md)

---

## 1. 分類基準の転換

| 従来の基準 | 新しい基準 |
|------------|------------|
| 参照チェーンで必須か | 動作すれば価値が高いか |
| 存在しないと契約破綻 | 動作すればシステムが改善 |
| required / optional | **潜在価値ベース** |

---

## 2. 再分類結果

### Tier 1: 確認済みコア（正常動作 + 高価値）

ドッグフーディングで動作を確認。これらは**絶対に削除不可**。

| 機能 | 検証結果 | 価値 |
|------|----------|------|
| prompt-analyzer 強制 | 動作確認 | プロンプト分類の自動化 |
| main ブランチ保護 | 動作確認 | 安全性確保 |
| codex-delegate | 動作確認 | コード実装の委譲 |
| pm + reviewer フロー | 動作確認 | playbook 品質保証 |
| playbook 作成チェーン | 動作確認 | タスク構造化 |

---

### Tier 2: 潜在的コア（未動作/部分動作 + 高価値）

**動作すればシステムが大幅に改善する**。修復・改善の優先度が高い。

| 機能 | 現状 | 動作すれば得られる価値 | 優先度 |
|------|------|------------------------|--------|
| **critic 強制呼び出し** | 未発火 | 報酬詐欺防止（自己承認バイアス排除） | **Critical** |
| **reward-guard** | 未発火 | Phase 完了の独立検証 | **Critical** |
| **playbook gate** | 未検証 | playbook なしの変更をブロック | **High** |
| **coderabbit タイミング** | 部分動作 | コードレビュー自動化 | **High** |
| **git-workflow Hook** | 未発火 | PR 作成の自動化・標準化 | **Medium** |

#### なぜこれらがコアか

```
CLAUDE.md の設計思想:
  「LLM の自己承認バイアスを構造的に防止する」

→ critic / reward-guard が動作しないと、この設計思想が実現しない
→ 動作していなくても「コア」である
```

---

### Tier 3: 未接続コア（設計済み + Hook 未接続だが価値あり）

**動作すれば価値が高い。Hook 接続を検討すべき。**

| 機能 | 現状 | 動作すれば得られる価値 | 優先度 |
|------|------|------------------------|--------|
| **critic** | 未発火 | 報酬詐欺防止（自己承認バイアス排除） | **Critical** |
| **health-checker** | 未使用 | orphan 検出、整合性監視 | **High** |
| **coherence-checker** | 手動 | ドキュメント乖離検出 | **High** |
| **abort-playbook** | 手動 | playbook クリーンアップ | **Medium** |

---

### Tier 4: 重複・不要な Skill

**既存機能と重複、または価値が低い。削除可能。**

| 機能 | 理由 |
|------|------|
| lint-checker | quality-assurance/checkers/lint.sh が Hook 接続済み。重複。 |
| test-runner | pnpm test 直接実行で十分。ラッパーの価値低い。 |
| deploy-checker | CI/CD で代替可能。 |
| context-management | ガイダンスのみ。Claude が直接実行。 |
| frontend-design | 毎回発火は重い。手動で十分。 |
| setup-guide | 初期設定専用。一度使えば不要。 |

---

### Tier 5: 要修復（required_broken）

参照があるが実体がない。修復または参照削除が必要。

| ファイル | 潜在価値 | 対策 |
|----------|----------|------|
| docs/4qv-architecture.md | **高**（設計理解） | 新規作成 |
| docs/coding-standards.md | **高**（コード品質） | 新規作成 |
| docs/file-creation-process-design.md | 中（ファイル作成ルール） | 参照削除で可 |
| workflow/generate-repository-map.sh | 低（パス違い） | 参照パス修正 |
| lib/contract.sh | 低（パス違い） | 参照パス修正 |

---

## 3. 優先度マトリクス

```
                    動作すれば価値が高い
                           ↑
                           |
    Tier 2              |  Tier 1
    (潜在的コア)          |  (確認済みコア)
    修復優先             |  維持
                           |
    ←───────────────────+───────────────────→
    未動作                 |                正常動作
                           |
    Tier 4              |  Tier 3
    (便利機能)            |  (強化機能)
    削除可               |  あれば良い
                           |
                           ↓
                    動作しても価値が低い
```

---

## 4. 結論

### コア機能の定義（ユーザー視点）

**コア機能 = Tier 1 + Tier 2**

| Tier | 件数 | 方針 |
|------|------|------|
| Tier 1（確認済み） | 5 | 維持 |
| Tier 2（潜在的） | 5 | **修復・改善が最優先** |
| Tier 3（未接続コア） | 4 | **Hook 接続を検討** |
| Tier 4（重複・不要） | 6 | 削除可 |
| Tier 5（broken） | 5 | 修復 or 参照削除 |

---

## 5. 削除可能ファイル一覧

> **判定基準**: Tier 4（重複・不要）
>
> コメントは削除理由を記載

### Skills（削除可能）

```
.claude/skills/lint-checker/
  # 理由: quality-assurance/checkers/lint.sh が Hook 接続済み。重複。

.claude/skills/test-runner/
  # 理由: pnpm test 直接実行で十分。ラッパーの価値低い。

.claude/skills/deploy-checker/
  # 理由: CI/CD で代替可能。

.claude/skills/context-management/
  # 理由: ガイダンスのみ。Claude が直接実行。

.claude/skills/frontend-design/
  # 理由: 毎回発火は重い。手動で十分。
```

### SubAgents（削除可能）

```
.claude/skills/session-manager/agents/setup-guide.md
  # 理由: 初期設定専用。一度使えば不要。
```

### 削除してはいけない（Tier 3: 未接続コア）

```
.claude/skills/abort-playbook/         # playbook クリーンアップに必要
.claude/skills/coherence-checker/      # ドキュメント乖離検出に価値あり
.claude/skills/quality-assurance/agents/health-checker.md  # orphan 検出に価値あり
```

### Supporting files（削除可能）

```
.claude/lib/common.sh
  # 理由: 共通関数ライブラリだが、参照が弱い。
  # 各 Hook/Script が直接処理を実装しており、共通化されていない。

.claude/hooks/generate-repository-map.sh
  # 理由: repository-map.yaml 自動生成。optional 機能。
  # 手動で yaml を更新しても問題ない。
```

### Docs（削除可能）

```
docs/audit-report.md
  # 理由: 監査記録。参照元は ARCHITECTURE.md のみ。
  # 削除しても動作に影響なし。履歴として残すなら archive へ。

docs/harness-self-awareness-design.md
  # 理由: 設計履歴・思考記録。運用には不要。
  # 参照なし。設計意図の記録として残すなら archive へ。

docs/readme.md
  # 理由: 例示のみ。critic.md から参照されているが、例としてのみ。
  # 参照を削除すれば削除可能。
```

### 生成物・一時ファイル（削除可能）

```
.claude/logs/
  # 理由: ログ出力先。運用で蓄積されるが、.gitignore で管理すべき。
  # リポジトリには含めない方が良い。

.claude/session-history/
  # 理由: セッション履歴。コンテキスト継続用だが、.gitignore で管理すべき。

.claude/.session-init/
  # 理由: セッション初期化一時ファイル。.gitignore で管理すべき。

tmp/
  # 理由: 一時作業ディレクトリ。.gitignore で管理すべき。
  # ただし tmp/fizzbuzz.py はドッグフーディング成果物として残す場合あり。

.tmp/
  # 理由: 一時ファイル。.gitignore で管理すべき。

evidence/
  # 理由: 証拠収集用。タスク完了後は不要。.gitignore で管理すべき。

eval/
  # 理由: 評価用。開発時のみ使用。.gitignore で管理すべき。

.ruff_cache/
  # 理由: Ruff lint キャッシュ。.gitignore で管理すべき。
```

### アーカイブ（削除可能）

```
plan/archive/
  # 理由: 完了した playbook のアーカイブ。
  # 履歴として残すか、定期的に削除するかは運用方針次第。

.archive/
  # 理由: 古い設計ドキュメントのアーカイブ。
  # 必要に応じて参照するが、削除しても動作に影響なし。
```

---

## 6. 削除時の注意事項

### 削除してはいけないもの

| ファイル | 理由 |
|----------|------|
| .claude/skills/quality-assurance/ | reviewer, coderabbit-delegate, lint.sh を含む（コア） |
| .claude/skills/reward-guard/ | critic を含む（コア） |
| .claude/skills/git-workflow/ | Hook から参照あり（コア） |
| .claude/skills/abort-playbook/ | playbook クリーンアップに必要（未接続コア） |
| .claude/skills/coherence-checker/ | ドキュメント乖離検出に価値あり（未接続コア） |
| health-checker.md | orphan 検出に価値あり（未接続コア） |

---

## 7. 推奨削除順序

1. **即時削除可能**（参照なし）
   - .claude/logs/, .claude/session-history/, .claude/.session-init/, tmp/, .tmp/, evidence/, eval/, .ruff_cache/
   - これらは .gitignore に追加して管理

2. **Skill 削除（Tier 4 のみ）**
   - lint-checker, test-runner, deploy-checker, context-management, frontend-design
   - setup-guide

3. **運用方針次第**
   - plan/archive/, .archive/（履歴として残すか削除するか）
   - docs/audit-report.md, docs/harness-self-awareness-design.md
