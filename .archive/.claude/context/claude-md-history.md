# CLAUDE.md 変更履歴

> **目的**: CLAUDE.md の変更履歴を保存
>
> CLAUDE.md から分離された「履歴」機能。過去の変更履歴として参照可能。

---

## 履歴（新しい順）

| 日時 | 内容 |
|------|------|
| 2025-12-10 | V6.0: コンテキスト・アーキテクチャ再設計。CONSENT/POST_LOOP/CONTEXT_EXTERNALIZATION を Skill 化。 |
| 2025-12-09 | V5.5: SKILLS_CHAIN 追加。SubAgents → Skills の呼び出し連鎖を明記。全ファイルへのアクセス経路マップ。 |
| 2025-12-09 | V5.4: CONTEXT_EXTERNALIZATION 追加。context-log.md でプロンプト→意図→処理→結果を記録。コンテキストの外部化。 |
| 2025-12-09 | V5.3: LOOP に静的解析ステップ追加。lint-check.sh で ESLint/ShellCheck/Ruff を自動実行。 |
| 2025-12-09 | V5.2: 合意プロセス（CONSENT）。INIT に フェーズ 4.5 追加。playbook=null 時に [理解確認] を強制。ユーザー応答待ちを例外許可。 |
| 2025-12-08 | V5.1: 計画の連鎖（Plan Derivation）。project.done_when → playbook の自動導出。INIT/POST_LOOP 更新。 |
| 2025-12-08 | V5.0: アクションベース Guards。session 分類廃止。Edit/Write 時のみ playbook チェック。意図推測不要に。 |
| 2025-12-08 | V4.1: 構造的強制。Hook が session を TASK にリセット → NLU で判断 → 安全側フォール。キーワード判定完全廃止。 |
| 2025-12-08 | V4.0: session 自動判定システム。prompt-validator.sh がキーワード判定 → state.md 自動更新。Claude 依存を排除。 |
| 2025-12-08 | V3.4: PROMPT_VALIDATION 追加。全プロンプトを project.md と照合。ROADMAP_CHECK を置換。 |
| 2025-12-08 | V3.3: CONTEXT.md 廃止。state.md/project.md/playbook を真実源に。INIT 簡素化。 |
| 2025-12-08 | V3.2: 報酬詐欺防止強化。LOOP に根拠確認、CRITIQUE に検証項目追加。 |
| 2025-12-02 | V3.1: 複数階層 plan 運用（roadmap）対応。 |
| 2025-12-02 | V3.0: 二層構造化。core を 200 行以下に最小化。 |
| 2025-12-02 | V2.1: CONTEXT セクション追加。 |
| 2025-12-02 | V2.0: メタ認知強化版。 |
| 2025-12-01 | V1.0: 初版。 |
