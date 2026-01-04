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

### Tier 3: 強化機能（未動作 + 中価値）

動作すれば品質が向上するが、なくてもコア契約は維持される。

| 機能 | 現状 | 動作すれば得られる価値 | 優先度 |
|------|------|------------------------|--------|
| coherence-checker | 手動 | state.md / playbook の整合性自動チェック | Medium |
| test-runner | 手動 | テスト自動化 | Medium |
| health-checker | 未使用 | システム状態の定期監視 | Low |
| lint-checker | 手動 | コード品質チェック自動化 | Low |

---

### Tier 4: 便利機能（optional + 低価値）

削除しても問題ない。

| 機能 | 理由 |
|------|------|
| abort-playbook | 手動中断手段（なくても Ctrl+C で対応可） |
| context-management | ガイダンスのみ（Claude が直接実行） |
| deploy-checker | 手動検証（CI/CD で代替可） |
| frontend-design | 手動（特定用途のみ） |
| setup-guide | 初期設定専用（一度使えば不要） |

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
| Tier 3（強化） | 4 | あれば良い |
| Tier 4（便利） | 5 | 削除可 |
| Tier 5（broken） | 5 | 修復 or 参照削除 |

---

## 5. 削除可能ファイル一覧

> **判定基準**: Tier 4（便利機能）+ 参照がないファイル + 重複ファイル
>
> コメントは削除理由を記載

### Skills（削除可能）

```
.claude/skills/abort-playbook/
  # 理由: 手動中断手段。Ctrl+C や /abort-playbook で代替可能。
  # Hook から強制呼び出しなし。ユーザーが明示的に呼ぶ必要がある。

.claude/skills/coherence-checker/
  # 理由: 手動整合性チェック。Hook チェーンに組み込まれていない。
  # 価値はあるが optional。削除しても動作に影響なし。

.claude/skills/context-management/
  # 理由: ガイダンスのみ。実際の処理は Claude が直接実行。
  # Skill として存在する意味が薄い。

.claude/skills/deploy-checker/
  # 理由: 手動検証用。CI/CD パイプラインで代替可能。
  # Hook から呼び出されない。

.claude/skills/frontend-design/
  # 理由: フロントエンドデザイン専用。特定用途に限定。
  # 汎用フレームワークには不要。

.claude/skills/lint-checker/
  # 理由: 手動 lint チェック。IDE や pre-commit hook で代替可能。
  # Hook チェーンに組み込まれていない。

.claude/skills/test-runner/
  # 理由: 手動テスト実行。npm test / pytest で直接実行可能。
  # Skill としてラップする価値が低い。
```

### SubAgents（削除可能）

```
.claude/skills/quality-assurance/agents/health-checker.md
  # 理由: 任意の監視機能。Hook から強制呼び出しなし。
  # 定期監視の仕組み自体が未実装。

.claude/skills/session-manager/agents/setup-guide.md
  # 理由: 初期設定専用。一度使えば不要。
  # セットアップ完了後は呼び出されない。
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

### 参照を先に削除すべきファイル

以下は参照が残っているため、参照を削除してから本体を削除する:

| ファイル | 参照元 | 対処 |
|----------|--------|------|
| docs/readme.md | critic.md:161 | 参照削除後に本体削除 |
| .claude/lib/common.sh | pre-tool.sh:15 | source 行を削除 |

### 削除してはいけないもの（誤って Tier 4 に見えるが Tier 2/3）

| ファイル | 理由 |
|----------|------|
| .claude/skills/quality-assurance/ | reviewer, coderabbit-delegate を含む（Tier 1/2） |
| .claude/skills/reward-guard/ | critic を含む（Tier 2） |
| .claude/skills/git-workflow/ | Hook から参照あり（Tier 2） |

---

## 7. 推奨削除順序

1. **即時削除可能**（参照なし）
   - .claude/logs/, .claude/session-history/, .claude/.session-init/, tmp/, .tmp/, evidence/, eval/, .ruff_cache/
   - これらは .gitignore に追加して管理

2. **参照削除後に削除**
   - docs/readme.md（critic.md の参照削除後）
   - .claude/lib/common.sh（pre-tool.sh の source 削除後）

3. **運用方針次第**
   - plan/archive/, .archive/（履歴として残すか削除するか）
   - docs/audit-report.md, docs/harness-self-awareness-design.md

4. **Skill 削除（慎重に）**
   - abort-playbook, coherence-checker, context-management, deploy-checker, frontend-design, lint-checker, test-runner
   - 削除前に SKILL.md 内の参照を確認
