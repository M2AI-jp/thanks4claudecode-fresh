# Codex 評価レポート

## 目的と前提
- docs/hook-evaluation.md, docs/subagent-evaluation.md, docs/skill-evaluation.md を読んだ上で、削除候補の妥当性・リスク・改善策を技術/設計観点で評価。

## 1. 削除判定の妥当性
- Hooks: depends-check.sh, check-file-dependencies.sh, doc-freshness-check.sh は情報提示のみで削除妥当。対して lint-check.sh・update-tracker.sh/ generate-implementation-doc.sh・failure-logger.sh・test-hooks.sh は品質/観測性/回帰検知を補完しており、単純削除は弱い。create-pr-hook.sh は重複だが feature-map / tech-stack で参照されているため、削除するなら周辺ドキュメント更新が前提。
- SubAgents: plan-guard.md, health-checker.md は CLAUDE.md から未参照だが、tech-stack.md・feature-map.md・doc-reference-audit.md で存在前提になっているため、現状の「削除候補」は根拠が弱い（ドキュメント整合性を欠く）。
- Skills: summary と個別判定が矛盾（context-externalization, context-management, plan-management は本文では保持推奨だがサマリーで削除候補）。state/plan-management は内容が旧構造なだけでドメイン知識を含むため、即削除ではなく改訂が妥当。execution-management, beginner-advisor, frontend-design は用途外で削除妥当性が高い。learning は failure-logger との将来連携を考えると温存余地あり。

## 2. 見落としリスク
- 品質ゲート低下: lint-check.sh 削除でローカル即時フィードバックが消える。CI 代替が未整備なら品質リスク増。test-hooks.sh 削除で Hook 変更時の回帰検知がなくなる。
- ドキュメント整合性崩壊: create-pr-hook.sh, plan-guard.md, health-checker.md を消すと feature-map.md, tech-stack.md, current-implementation.md, doc-reference-audit.md が破綻。依存ドキュメント更新を伴わない削除は危険。
- 学習/ナレッジ喪失: failure-logger.sh と learning Skill を同時に外すと将来の自己改善経路が閉ざされる。state/plan-management/context-系 Skill を削除すると旧構造から現行構造への移行知識が失われ、オンボーディング効率が下がる。
- コンテキスト継承の弱体化: context-externalization/context-management を消すと /compact や Phase 完了時の情報外部化ガイドがなくなり、長期セッションでの意図追跡が困難。
- 将来拡張の阻害: execution-management を消すと複数 playbook 並行運用を再導入する際にガイドが消滅し、再設計コストが上がる。

## 3. 改善提案
- 削除前に「必須 / 任意 / 廃止予定」の3分類を再整理し、doc-reference-audit.md, feature-map.md, current-implementation.md, tech-stack.md を一括更新するデprecation プランを用意する。特に create-pr-hook.sh, plan-guard.md, health-checker.md は参照先更新が完了するまで残すか、置き換え stub を残す。
- lint-check.sh, test-hooks.sh, failure-logger.sh, learning Skill は「オプション（デフォルト off）」として残し、settings.json や運用ルールで opt-in/opt-out を明示。学習系は将来の自動改善計画と紐づけてロードマップ化する。
- state/plan-management Skill は削除ではなく現行の project/playbook/phase 用語へ改訂して再分類する（「旧版」として archive し、新版を提供）。context-externalization/context-management も同様に、削除ではなく compact/pre-compact 手順に統合。
- execution-management, beginner-advisor, frontend-design は用途外で削除する場合でも、削除理由と代替（外部リソースや CLAUDE.md への移設）を明記し、後方互換を期待する他ドキュメントからのリンク切れを防ぐ。
- 削除決定時は settings.json や運用フローに「この Hook/SubAgent/Skill が存在しない場合のフォールバック」を明文化し、欠落時の異常検出（health check）を追加して不整合を即座に検知する。
