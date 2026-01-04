# planning-rules.md - 計画策定の職能定義

> **計画策定（Planning）の責務と方法論を定義する。**
>
> インプットの種類に依存しない、普遍的な計画策定ルール。

---

## 1. PM の責務

```yaml
責務:
  - ヒアリング結果から playbook を作成する
  - Phase を MECE に分割する
  - 各 Phase の done_criteria を定義する
  - 担当者（executor）を割り当てる

成果物:
  - playbook-{project}.md

品質基準:
  - done_criteria が検証可能である（曖昧禁止）
  - Phase 間の依存関係が明確
  - オフラインタスク（user 担当）が漏れていない
```

---

## 2. ヒアリングフロー（標準化）

> **新規ユーザーへのヒアリングを標準化し、品質のばらつきを防ぐ**

### 2.1 必須質問（3問以内に圧縮）

```yaml
Q1: 何を作りたいですか？
  目的: ゴールの明確化
  例: 「ChatGPT クローンで可愛いキャラクターがしゃべるアプリ」

Q2: デプロイ先は？
  選択肢:
    - Vercel（推奨: 無料枠、Next.js と相性良い）
    - GCP Cloud Run
    - AWS
    - ローカルのみ
  目的: テンプレート選択に必要

Q3: 使用する外部サービスは？
  選択肢例:
    - AI API: OpenAI / Anthropic / その他
    - DB: Neon / Supabase / PlanetScale / なし
    - 認証: Auth.js / Clerk / なし
    - 決済: Stripe / なし
  目的: 技術スタック決定
```

### 2.2 オプション質問（必要に応じて）

```yaml
Q4: 追加機能は？
  - 音声合成
  - 画像生成
  - ファイルアップロード
  目的: スコープ確定

Q5: 納期や優先度は？
  目的: Phase の優先順位決定
```

### 2.3 type 判定

```yaml
ヒアリング結果から自動判定:
  - Web UI + DB + 認証 → web_app
  - CLI ツール → automation
  - 記事・ドキュメント → natural_language
  - データ分析 → data_analysis
```

### 2.4 ヒアリング結果 → playbook 生成

```
ヒアリング完了
    ↓
type を判定
    ↓
playbook-format.md に従って playbook を生成
    ↓
state.md の session を task に変更
    ↓
開発開始
```

---

## 3. 計画策定フロー

```
1. ヒアリング結果を読む（2. ヒアリングフロー参照）
       ↓
2. goal（最終目標）を定義する
       ↓
3. goal を Phase に分解する
       ↓
4. 各 Phase の done_criteria を定義する
       ↓
5. executor を割り当てる
       ↓
6. 依存関係を明記する
       ↓
7. playbook-format.md に従って記述する
```

---

## 3. Phase 分解の原則

```yaml
MECE:
  - 漏れなく（全ての作業を網羅）
  - 重複なく（同じ作業が複数 Phase にない）

粒度:
  - 1 Phase = 1 機能 = 1 日以内で完了可能
  - 大きすぎる → 分割する
  - 小さすぎる → 統合する

依存関係:
  - 独立した Phase は並列実行可能
  - 依存がある場合は depends_on で明記
```

---

## 4. done_criteria の書き方

```yaml
良い例:
  - "README.md が存在し、プロジェクト概要が記載されている"
  - "npm test が exit code 0 で終了する"
  - "http://localhost:3000 でトップページが表示される"

悪い例:
  - "ドキュメントを書く" ← 何が done か不明
  - "テストする" ← 何をテストするか不明
  - "いい感じにする" ← 検証不可能

検証可能性チェック:
  1. コマンドで確認できるか?（ls, npm test, curl）
  2. 目視で確認できるか?（画面キャプチャ、出力結果）
  3. YES/NO で判定できるか?
```

---

## 5. executor の割り当て

```yaml
codex（AI）:
  - コード実装
  - テスト実行
  - ファイル操作
  - ドキュメント生成

user（人間）:
  - 外部サービスの登録（Vercel, GCP, Stripe）
  - 認証情報の取得（API キー）
  - 意思決定（デザイン選択、機能優先度）
  - 支払い情報の入力

判定基準:
  - "登録" "サインアップ" "契約" → user
  - "API キー" "シークレット" → user
  - "選んでください" "決めてください" → user
  - それ以外 → codex
```

---

## 6. 干渉チェックの組み込み

```yaml
Phase 完了時に確認すること:
  - 新規ファイルが保護対象に干渉していないか
  - 既存の CLAUDE.md を意図せず変更していないか
  - state.md との整合性が保たれているか

done_criteria に含めるべき項目:
  - "coherence.sh が PASS する"
  - "保護ファイルへの変更がない（git diff で確認）"
```

---

## 7. リファクタリング Phase の挿入

```yaml
タイミング:
  - 3 Phase ごとに 1 回のリファクタリング Phase を検討
  - または、技術的負債が visible になった時点

リファクタリング Phase の done_criteria 例:
  - "関数の最大行数が 50 行以下"
  - "ファイルの最大行数が 500 行以下"
  - "重複コードが除去されている"
  - "既存テストが全て PASS する"

禁止事項:
  - 機能追加とリファクタリングの混在
  - done_criteria に無い「改善」
```

---

## 8. 計画の保全と健全性（Plan Health）

```yaml
SSOT:
  - docs/core-feature-reclassification.md を設計の唯一基準とする
  - docs/ARCHITECTURE.md はユーザーフローの説明書として維持する

整合性:
  - state.md の playbook.active と plan/playbook-*.md を一致させる
  - context セクションに analysis_result と user_approved_understanding を必ず残す

参照の健全性:
  - ファイル削除/移動の後は rg で参照切れを除去
  - bash .claude/hooks/generate-repository-map.sh を実行し、差分を更新
  - セッション開始時に DRIFT が出たら ARCHITECTURE を同期する

自動化ギャップ対策:
  - UserPromptSubmit → prompt-analyzer → playbook-init → pm → reviewer の自動化を維持する
  - 自動化が未完なら playbook に「自動化補完」サブタスクを追加する

孤立 playbook 対応:
  - playbook.active が null なのに playbook が残る場合は整理する
  - 状態修復は pm 経由、またはアーカイブで確定する
```

---

## 9. よくある失敗パターン

```yaml
オフラインタスク漏れ:
  問題: user が実行すべきタスクを codex に割り当てる
  対策: "登録" "キー" "契約" を検索して executor を確認

done_criteria 曖昧:
  問題: "〜する" だけで完了条件が不明
  対策: "〜が〜である" の形式で書く

Phase 粒度過大:
  問題: 1 Phase が数日かかる
  対策: 1 日以内で完了可能な粒度に分割

依存関係未記載:
  問題: Phase 順序が不明で混乱
  対策: depends_on を必ず記載
```

---

## 10. 出力フォーマット

PM は以下のフォーマットで playbook を出力する:

```markdown
# playbook-{project}.md

## meta
project: {プロジェクト名}
created: {作成日}

## goal
summary: {1行の目標}
done_when:
  - {最終完了条件1}
  - {最終完了条件2}

## phases
{playbook-format.md の形式に従う}
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-01 | 初版作成。計画策定の職能を分離。 |
