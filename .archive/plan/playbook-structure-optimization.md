# playbook-structure-optimization.md

> **目的**: ファイル構造の最適化 + 新規ユーザー向け plan テンプレート作成

---

## meta

```yaml
branch: feat/next-discussion
issue: null
created: 2025-12-08
```

---

## goal

```yaml
summary: CONTEXT.md 整理 + Mermaid 図最適化 + plan/setup 構造最適化 + 新規ユーザーテンプレート
done_when:
  - CONTEXT.md が不要になり、init-guard.sh が state.md のみを必須とする
  - Mermaid 図が DocBase 形式で表示可能
  - plan/ と setup/ の構造が新規ユーザー向けに最適化されている
  - 新規ユーザーがフォーク後、0 から多層計画を開始できるテンプレートが存在する
```

---

## phases

### p0: CONTEXT.md 整理

```yaml
status: done
goal: init-guard.sh と session-start.sh から CONTEXT.md 参照を削除
done_criteria:
  - init-guard.sh が state.md のみを必須とする
  - session-start.sh が CONTEXT.md を参照しない
  - state.md の参照ファイルセクションが更新されている
evidence:
  - init-guard.sh: REQUIRED_FILES=("state.md") に変更済み
  - session-start.sh: product/workspace/plan-template の Read 指示から CONTEXT.md 削除済み
  - state.md: 参照ファイルを CLAUDE.md, project.md, architecture-*.md に更新済み
```

### p1: アーキテクチャ文書を物語形式に変換

```yaml
status: done
goal: architecture-features.md と architecture-plan.md を人間に優しい物語形式に変換
done_criteria:
  - 物語形式で擬人化されている（ユーザー指示による方針変更）
  - 日本語で読みやすい
  - 複雑な概念が比喩で説明されている
evidence:
  - architecture-features.md: Hooks/SubAgents/Skills を擬人化した物語
  - architecture-plan.md: 3層計画を会社組織、4レイヤーをビルのフロアに例えた物語
  - ユーザーから「物語形式の方がまだマシ」「擬人化して」との指示
```

### p2: plan/ 構造分析・最適化

```yaml
status: done
goal: plan/ ディレクトリの構造を分析し、新規ユーザー向けに最適化
done_criteria:
  - 開発用ファイル（playbook-validation.md 等）が .archive に移動
  - plan/active/ に現在進行中の playbook のみ存在
  - plan/template/ に新規ユーザー向けテンプレートが存在
  - plan/project.md が新規ユーザー向け初期状態にリセット可能
evidence:
  - .archive/plan/active/: playbook-validation.md, playbook-e2e-validation.md, playbook-autonomy-enhancement.md を退避
  - plan/active/: playbook-structure-optimization.md のみ
  - plan/template/: project-format.md, playbook-format.md, playbook-examples.md, planning-rules.md, state-initial.md
  - plan/README.md: 構造説明を追加
```

### p3: setup/ 構造分析・最適化

```yaml
status: done
goal: setup/ ディレクトリの構造を分析し、新規ユーザー向けに最適化
done_criteria:
  - setup/playbook-setup.md が新規ユーザーで即動作可能
  - setup/CATALOG.md が最新のテンプレートを反映
  - 不要なファイルがない
evidence:
  - setup/playbook-setup.md: Phase 0-8 完備、スキルレベル分岐対応
  - setup/CATALOG.md: 最新テンプレートを参照（CONTEXT.md 参照削除済み）
  - 不要ファイル: なし（必要最小限）
```

### p4: 新規ユーザー向け plan テンプレート作成

```yaml
status: done
goal: フォーク後、0 から多層計画を開始できる仕組みを作成
done_criteria:
  - plan/template/project-format.md が新規ユーザー向け
  - plan/template/state-initial.md が新規ユーザー向け初期状態
  - setup 完了後に plan/project.md が自動生成される仕組み
  - 多層計画（Macro → Medium → Micro）が 0 から構築可能
evidence:
  - plan/template/project-format.md: 新規ユーザー向け Macro 計画テンプレート
  - plan/template/state-initial.md: 初期状態（focus.current=setup）
  - setup/playbook-setup.md Phase 8: project.md 生成を明記
  - planning-rules.md: 3層計画の構築ルールを定義
```

### p5: 最終確認・コミット

```yaml
status: done
goal: 全変更をコミットし、main にマージ
done_criteria:
  - 全ファイルがコミット済み
  - critic PASS
evidence:
  - git status: clean（コミット 49b8279）
  - critic: 全 Phase (p0-p5) PASS
```
