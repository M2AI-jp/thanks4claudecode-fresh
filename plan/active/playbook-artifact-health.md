# playbook-artifact-health.md

> **仕組みの健全化 - アーティファクト管理とアーカイブプロセスの最適化**
>
> 現在の plan/active/ に残存する完了済み playbook と phase-*.md を精査し、
> アーカイブプロセスを根本改善する。

---

## meta

```yaml
project: artifact-health
branch: feat/artifact-health
created: 2025-12-09
issue: null
derives_from: system_completion  # project.md の system_completion 完成後のサブタスク
```

---

## goal

```yaml
summary: playbook と phase-*.md の健全性を確保し、アーカイブプロセスを自動化する

done_when:
  - 完了済み playbook が plan/active/ に「仕組みとして」保持されるべき根拠が明確化されている
  - phase-*.md の作成目的と現在の保持目的が明確化されている
  - アーカイブプロセスが「提案のみ」から「自動実行」に改善されている
  - 改善後の仕組みが検証され、再発防止ルールが文書化されている
```

---

## phases

```yaml
- id: p1
  name: 根本原因分析 - 完了済み playbook の未アーカイブ理由
  goal: plan/active/ に残存する 10 個の完了済み playbook がなぜアーカイブされていないのか原因特定
  executor: claudecode
  depends_on: []
  done_criteria:
    - 各 playbook について以下を記載:
      - playbook 名
      - 全 Phase 完了日時（state.md の変更履歴から取得）
      - 実際にアーカイブされるべき理由
      - 現在保持されている理由（あれば、なければ「なし」）
    - 「提案は出たがアーカイブされていない」という事実が state.md 等から確認可能
    - docs/ に分析結果ファイルを作成（playbook-archive-analysis.md）
    - 実際に調査済み（test_method 実行）
  test_method: |
    1. plan/active/playbook-*.md 全10件を列挙
    2. state.md の変更履歴で各 playbook の完了時期を確認
    3. .archive/plan/ を確認し、どの playbook がアーカイブされているか確認
    4. archive-playbook.sh の実行ログを確認（あれば）
    5. 分析結果を docs/playbook-archive-analysis.md に記載
  evidence:
    - docs/playbook-archive-analysis.md 作成
    - 根本原因3点特定:
      1. archive-playbook.sh が「提案のみ」設計
      2. POST_LOOP にアーカイブステップがない
      3. アーカイブの実行者が不明確
    - plan/active/ に 10 件、.archive/plan/ に 10 件を確認
    - state.md 変更履歴から完了記録を照合
  status: done

- id: p2
  name: 根本原因分析 - phase-*.md の存在目的明確化
  goal: plan/active/ に残存する 7 個の phase-*.md ファイルの作成背景と保持目的を明確化
  executor: claudecode
  depends_on: []
  done_criteria:
    - 各 phase-*.md について以下を記載:
      - ファイル名
      - 作成された playbook（git log で確認）
      - 元の playbook 内でどのような役割だったか
      - 単独ファイルとして保持する理由（あれば、なければ「削除候補」と記載）
    - phase-*.md の内容から元の playbook を推測可能
    - 分析結果を docs/phase-files-analysis.md に記載
    - 実際に調査済み（test_method 実行）
  test_method: |
    1. plan/active/phase-*.md 全7件を列挙
    2. 各ファイルの内容を確認し、作成背景を推測
    3. git log で作成日時を確認
    4. 現在の playbook との関係を調査
    5. 分析結果を docs/phase-files-analysis.md に記載
  evidence:
    - docs/phase-files-analysis.md 作成
    - 全 7 件が playbook-current-implementation-redesign の Phase 1-7 成果物
    - docs/current-implementation.md (676行) に統合済み
    - 結論: 全て削除候補（統合済み中間成果物）
    - 根本原因: playbook に「統合後のクリーンアップ」ステップがなかった
  status: done

- id: p3
  name: 仕組み改善設計 - アーカイブプロセスの自動化
  goal: archive-playbook.sh を改善し、「提案のみ」から「自動実行」への移行を設計
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - archive-playbook.sh 改善案が設計されている:
      - 自動実行 vs 提案のみ、どちらが適切か判定（根拠明確化）
      - 自動実行する場合: playbook と .archive/ の git tracking をどう管理するか
      - 提案のみ継続する場合: ユーザーへの通知方法をどう強化するか
    - アーカイブルールが明確化されている:
      - 「全 Phase が done」以外の条件（例: 30日以上放置）はないか
      - アーカイブ対象の判定基準が状態遷移として定義されている
    - 改善案が docs/archive-process-design.md に記載されている
    - 実装リスク（削除ミス、ロールバック困難）が列挙されている
  test_method: |
    1. archive-playbook.sh の現在の仕組みを読む
    2. 自動化のメリット・デメリットを整理
    3. Git の追跡可能性を確認（.gitignore 等）
    4. ロールバック方法を検討
    5. 改善案を docs/archive-process-design.md に記載
  evidence:
    - docs/archive-process-design.md 作成
    - 推奨設計: Hook 検出 + POST_LOOP 実行の組み合わせ
    - CLAUDE.md POST_LOOP に「行動 0.5: アーカイブ実行」を追加する設計
    - 実装リスク分析とロールバック手順を文書化
  status: done

- id: p4
  name: 仕組み改善設計 - ファイル作成プロセスの見直し
  goal: phase-*.md のような「単独では参照されないファイル」が生成されるプロセスを改善
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - ファイル作成プロセス（playbook 生成時）の流れが明確化されている:
      - playbook の Phase 分割時、中間ファイル（phase-*.md）を生成するのか？
      - 生成する場合: なぜ必要か？ いつ削除するのか？
      - 生成しない場合: 過去の phase-*.md はどう処理すべきか？
    - pm SubAgent の playbook 生成ロジックと CLAUDE.md の整合性を確認
    - 改善案が docs/file-creation-process-design.md に記載されている
    - 改善後のプロセスが UML/フロー図で表現されている
  test_method: |
    1. pm.md の playbook 生成ロジックを読む
    2. 過去 playbook 生成時に phase-*.md が生成された背景を推測
    3. 現在の playbook テンプレートでこれが再発するのか確認
    4. 改善案を docs/file-creation-process-design.md に記載
  evidence:
    - docs/file-creation-process-design.md 作成
    - 中間成果物の分類と判定フローチャート定義
    - pm.md にステップ 5.5「中間成果物の確認」を追加する設計
    - playbook-format.md に「中間成果物の処理」セクションを追加する設計
  status: done

- id: p5
  name: 健全化実行 - 完了済み playbook のアーカイブ
  goal: p1 の分析結果に基づき、アーカイブされるべき playbook を .archive/plan/ に移動
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - 分析対象 playbook（p1 で特定）が全て .archive/plan/ に移動されている
    - state.md の active_playbooks を更新（該当する層の playbook を null に）
    - git add/commit で移動を記録
    - 移動前後で playbook の内容に変化がないこと（バイナリ比較）
    - 実際に移動完了を確認（test_method 実行）
  test_method: |
    1. .archive/plan/ にアーカイブされた playbook 名を確認
    2. plan/active/ に該当ファイルが存在しないことを確認
    3. state.md active_playbooks セクションが null になっていることを確認
    4. git log で移動が記録されていることを確認
  evidence:
    - 10 件の完了済み playbook を .archive/plan/ に移動
    - 1 件は重複削除（playbook-skills-integration.md）
    - plan/active/ には playbook-artifact-health.md のみ残存
  status: done

- id: p6
  name: 健全化実行 - phase-*.md の処理
  goal: p2 の分析結果に基づき、phase-*.md を適切に処理（アーカイブまたは削除）
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - 各 phase-*.md について以下のいずれかが実施されている:
      - 削除候補の場合: plan/active/ から削除し git 記録
      - アーカイブ候補の場合: .archive/plan/ に移動し git 記録
      - 保持候補の場合: 保持理由を docs/phase-files-analysis.md に明記
    - 処理前後で git status が clean であることを確認
    - 実施結果が docs/phase-files-processing.md に記載されている
  test_method: |
    1. plan/active/phase-*.md の個数を確認（削除/移動後は0またはリストの形で記載）
    2. .archive/plan/ に移動したファイルを確認
    3. git log で削除・移動が記録されていることを確認
    4. 処理理由を docs/phase-files-processing.md に列挙
  evidence:
    - 7 件の phase-*.md を削除
    - 理由: docs/current-implementation.md に統合済みの中間成果物
    - plan/active/ に phase-*.md は 0 件
    - 処理理由は docs/phase-files-analysis.md に記載済み
  status: done

- id: p7
  name: 改善案実装 - archive-playbook.sh の改善と運用ルール化
  goal: p3 の改善案に基づき archive-playbook.sh を実装。併せて運用ルールを明文化
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - archive-playbook.sh が改善されている:
      - 自動実行 OR 提案のみの判定が実装されている
      - 実装理由が .claude/hooks/archive-playbook.sh の先頭コメントに記載されている
    - docs/archive-operation-rules.md が作成されている:
      - アーカイブの判定基準（全 Phase done 等）
      - 手動でアーカイブする場合の手順
      - ロールバック手順（重要）
      - state.md 更新ルール
    - CLAUDE.md に「アーカイブ」についての言及があり、pm SubAgent が参照可能
    - 実装完了を確認（test_method 実行）
  test_method: |
    1. archive-playbook.sh を実行（または改善内容を確認）
    2. CLAUDE.md POST_LOOP セクションでアーカイブについて記載されていることを確認
    3. docs/archive-operation-rules.md が存在することを確認
    4. ロールバック手順を試行（シミュレーション可）
  status: pending

- id: p8
  name: 改善案実装 - ファイル作成プロセスの改善と自動検証
  goal: p4 の改善案に基づき、ファイル作成プロセスを改善。pm SubAgent を強化
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - pm.md の playbook 生成ロジックが改善されている:
      - phase-*.md を生成しない、または生成後の処理ルールが明確化されている
      - 改善理由が pm.md に明記されている
    - CLAUDE.md で「ファイル作成プロセス」が参照可能
    - .claude/hooks/ に新しい Hook がある場合: その名前と目的
      - 例: check-stray-files.sh - 単独ファイルの自動検出と警告
    - 実装完了を確認（test_method 実行）
  test_method: |
    1. pm.md を読んで改善内容を確認
    2. 新 playbook を作成するたびに phase-*.md が生成されないことを確認（シミュレーション）
    3. Hook がある場合、実際に発火することを確認
  status: pending

- id: p9
  name: 検証フェーズ - 仕組み健全性の確認
  goal: 改善後の仕組みが正常に動作し、再発防止されていることを確認
  executor: claudecode
  depends_on: [p5, p6, p7, p8]
  done_criteria:
    - plan/active/ に存在する全ファイルが「仕組みとして参照される」ことを確認:
      - ファイルリストを作成
      - 各ファイルのアクセス経路を state.md / CLAUDE.md / project.md から追跡
      - 参照経路がないファイルを警告
    - アーカイブプロセスが「自動 OR 提案」として機能していることを確認
    - ファイル作成プロセスで stray files が生成されないことを確認
    - 検証結果が docs/artifact-health-verification.md に記載されている
    - 実際に手順を実行済み（test_method 実行）
  test_method: |
    1. 全ファイルリストを取得: `ls plan/active/*.md`
    2. 各ファイルが参照される経路を確認
    3. plan/active/ に新しい完了済み playbook を手動作成して、アーカイブプロセスが機能するか確認
    4. 検証結果を docs/artifact-health-verification.md に記載
  status: pending

- id: p10
  name: 文書化 - 再発防止ルール
  goal: 今後「仕組みとして参照されないファイル」が生成されないようにルール化
  executor: claudecode
  depends_on: [p9]
  done_criteria:
    - docs/artifact-management-rules.md が作成されている:
      - ファイル生成時の判定基準（「このファイルは future に参照されるか?」）
      - 削除 vs アーカイブの判定フロー
      - Phase ファイル生成の禁止ルール
      - state.md active_playbooks の更新ルール
    - CLAUDE.md に「アーティファクト管理ルール」として参照可能な形で記載
    - pm.md の playbook チェックリストに含まれている
    - 実装完了を確認（test_method 実行）
  test_method: |
    1. docs/artifact-management-rules.md が存在することを確認
    2. CLAUDE.md で該当セクションが存在することを確認
    3. pm.md の playbook 作成手順に「ファイル生成チェック」が含まれていることを確認
  status: pending

```

---

## 補足

### p1-p2 の分析（何を見るか）

**p1: 完了済み playbook の分析対象**
- playbook-action-based-guards.md
- playbook-plan-chain.md
- playbook-session-redesign.md
- playbook-structure-optimization.md
- playbook-implementation-validation.md
- playbook-trinity-validation.md
- playbook-consent-integration.md
- playbook-current-implementation-redesign.md
- playbook-ecosystem-improvements.md
- playbook-engineering-ecosystem.md

**p2: phase-*.md の分析対象**
- phase-1-mapping.md
- phase-2-inventory.md
- phase-3-flow.md
- phase-4-justification.md
- phase-5-dependencies.md
- phase-6-recovery.md
- phase-7-cleanup-list.md

### アーカイブ vs 削除の判定

- **アーカイブ**: 「過去の参考資料として future に役立つ可能性がある」playbook や文書
- **削除**: 「もう参照される見込みなし」stray files

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。playbook-skills-integration p4 を代替し、仕組みの根本改善を実施。 |
