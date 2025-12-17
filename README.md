# thanks4claudecode

> **📦 Experimental Archive（実験博物館）**
>
> このリポジトリは「Claude Code の自律性を向上させる実験」の記録です。
> 新規開発は終了しました。概念の再利用は別リポジトリで行ってください。

---

## 位置づけ

```yaml
status: archived（実験完了・博物館化）
disposition: Experimental Archive
reason: |
  53 コンポーネントの複雑性、Hook 相互依存、報酬詐欺の構造的限界を
  学んだ上で、「テンプレートとしては重すぎ、廃棄するには学びが多い」
  と判断。実験の記録として保存する。
```

詳細: [docs/final-decision.md](docs/final-decision.md)

---

## 何を実験したか（5 つの機能）

| 機能 | 目的 | 結果 |
|------|------|------|
| 報酬詐欺防止 | 「完了」と言いながら未完了を防ぐ | △ critic 呼び出し依存 |
| 計画駆動開発 | playbook なしでコードを書かせない | ✓ 動作（Hook で強制） |
| 構造的強制 | LLM の意思に依存しない行動制御 | ✓ 動作（Hook で強制） |
| 3層自動運用 | project → playbook → phase 自動進行 | △ フレームワークとしては動作 |
| コンテキスト外部化 | チャット履歴に依存しない状態管理 | ✓ 動作（state.md） |

---

## 学んだこと

1. **Hook は 3 個程度が限界** - 8 個以上は相互依存で破綻
2. **CLAUDE.md は 200 行以内** - それ以上は毎セッション読めない
3. **自己検証は構造的に不可能** - LLM が自分を騙すのを LLM は検出できない
4. **「完全自動」は幻想** - 人間の判断は必ず必要
5. **sed バイパスは原理的に防げない** - 構造的強制の限界

---

## コンポーネント構成（最終状態）

| コンポーネント | 数 | 役割 |
|----------------|-----|------|
| Hook | 30 | 構造的強制 |
| SubAgent | 6 | 検証・計画 |
| Skill | 9 | 専門知識 |
| Command | 8 | 操作ショートカット |

詳細: [docs/component-taxonomy.md](docs/component-taxonomy.md)

---

## ファイル構造

```
.
├── CLAUDE.md               # ルールブック（198行）
├── state.md                # 現在の状態（Single Source of Truth）
├── plan/
│   ├── project.md          # 回復プロジェクト計画
│   └── archive/            # アーカイブ済み playbook
├── .claude/
│   ├── hooks/              # Hook（構造的強制）
│   ├── agents/             # SubAgent
│   ├── skills/             # Skill
│   └── settings.json       # Hook 登録
└── docs/
    ├── final-decision.md   # 最終決定
    ├── e2e-tests/          # E2E テスト結果
    └── *.md                # 各種ドキュメント
```

---

## 再利用のガイド

このリポジトリから再利用できる概念：

| 概念 | ファイル | 推奨 |
|------|----------|------|
| playbook-guard | `.claude/hooks/playbook-guard.sh` | 軽量化して再利用可 |
| state.md パターン | `state.md` | そのまま再利用可 |
| critic 検証 | `.claude/agents/critic.md` | 概念を参考に再設計 |
| 3層構造 | `CLAUDE.md` | 簡略化して再利用可 |

**注意**: 全体をそのままコピーしないこと。複雑すぎて動作不安定。

---

## 関連ドキュメント

- [docs/final-decision.md](docs/final-decision.md) - 博物館化の決定理由
- [docs/e2e-tests/README.md](docs/e2e-tests/README.md) - E2E テスト結果
- [docs/security-modes.md](docs/security-modes.md) - admin モード仕様
- [docs/boot-context.md](docs/boot-context.md) - セッション開始ガイド

---

## 連絡先

[M2AI-jp](https://github.com/M2AI-jp) が管理。

- Issue: ドキュメント修正のみ受け付け
- PR: ドキュメント修正のみ受け付け
- 新機能リクエスト: 受け付けません

リポジトリ: https://github.com/M2AI-jp/thanks4claudecode
