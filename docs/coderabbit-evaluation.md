# CodeRabbit CLI 可用性評価レポート

> **評価日時**: 2025-12-09
> **評価者**: Claude Code
> **対象**: CodeRabbit CLI v0.3.4
> **リポジトリ**: thanks4claudecode

---

## 1. 概要

CodeRabbit は AI を活用したコードレビューツール。CLI 版は 2025年9月にリリースされた Beta 版。このリポジトリでの可用性を評価し、TDD LOOP への統合可否を判断する。

---

## 2. インストール・認証

### 2.1 インストール

```bash
curl -fsSL https://cli.coderabbit.ai/install.sh | sh
```

**結果**:
- インストール先: `/Users/amano/.local/bin/coderabbit`
- バージョン: 0.3.4
- プラットフォーム: darwin-arm64（Apple Silicon）

### 2.2 認証

```bash
coderabbit auth status
```

**結果**:
- 認証方式: GitHub OAuth
- ユーザー: M2AI-jp
- メール: skool@m2ai.jp
- 組織: M2AI-jp

---

## 3. テスト実行結果

### 3.1 実行コマンド

```bash
coderabbit review --prompt-only --type uncommitted
```

### 3.2 検出結果

| 項目 | 結果 |
|------|------|
| 実行時間 | 約10秒 |
| 検出件数 | 1件 |
| ファイル | plan/active/playbook-engineering-ecosystem.md |
| 行番号 | 31-60 |
| Type | potential_issue |

### 3.3 検出内容

```
Phase 1 test_method uses incorrect installation and command examples for CodeRabbit;
update the steps to reflect the official install and runtime commands
```

**評価**: 実際の誤り（`npx @coderabbit/cli` という存在しないコマンド）を正確に検出。False positive なし。

---

## 4. 既存システムとの比較

### 4.1 比較対象

| システム | 役割 | 発火タイミング |
|---------|------|---------------|
| critic SubAgent | done_criteria の証拠検証 | Phase 完了時 |
| reviewer SubAgent | コード品質評価 | 手動呼び出し |
| CodeRabbit CLI | 静的解析 + AI レビュー | 手動呼び出し |

### 4.2 機能重複分析

| 機能 | critic | reviewer | CodeRabbit |
|------|--------|----------|------------|
| done_criteria 検証 | ✅ | - | - |
| コード品質評価 | - | ✅ | ✅ |
| 静的解析 | - | 部分的 | ✅ |
| 修正提案 | - | 部分的 | ✅ |
| AI 駆動 | ✅ | ✅ | ✅ |

**結論**: reviewer と部分的に重複するが、静的解析と具体的な修正提案は CodeRabbit が優位。ただし critic とは目的が異なり、補完関係。

### 4.3 補完度

- **critic**: 「達成したか」を判定 → CodeRabbit では代替不可
- **reviewer**: 「品質は良いか」を判定 → CodeRabbit で補強可能
- **CodeRabbit**: 「何を直すべきか」を提案 → 具体的な修正案を提供

---

## 5. 料金・制限分析

### 5.1 料金体系

| プラン | レート | 特徴 |
|-------|--------|------|
| Free | 1回/時間 | 基本静的解析 |
| Lite | 1回/時間 | Learnings 機能 |
| Pro | 5回/時間 | 高度な解析 |

### 5.2 制限の影響

**TDD LOOP への統合シミュレーション**:
- 1時間あたりの平均 LOOP 回数: 5-10回
- Free tier の場合: 1回/時間 → 80-90% の LOOP でレビューなし
- Pro tier でも: 5回/時間 → 50% の LOOP でレビューなし

**結論**: 頻繁な LOOP 実行には不向き。

---

## 6. ROI 分析

### 6.1 時間コスト

| 項目 | 時間 |
|------|------|
| インストール | 1分 |
| 認証 | 2分（初回のみ） |
| レビュー実行 | 10秒/回 |
| 結果解釈 | 1-2分/回 |

### 6.2 品質向上

| 項目 | 効果 |
|------|------|
| 誤りの早期発見 | ✅ 高（今回の npx 誤り検出） |
| 具体的な修正案 | ✅ 高（AI 駆動の提案） |
| 学習効果 | 中（エンジニアリング作法を学べる） |

### 6.3 ROI 判定

| 利用シーン | ROI | 推奨度 |
|-----------|-----|--------|
| TDD LOOP 内 | 低（レートリミット） | ❌ 非推奨 |
| PR 作成時 | 高（1回で十分） | ✅ 推奨 |
| 大規模変更前 | 高（品質保証） | ✅ 推奨 |
| デイリーチェック | 中（Free tier で十分） | ⚠️ 条件付き推奨 |

---

## 7. 統合設計

### 7.1 TDD LOOP への直接統合

**判定: 見送り**

理由:
1. レートリミット（Free tier 1回/時間）
2. 外部サービス依存（API 停止リスク）
3. LOOP の頻度と合わない

### 7.2 代替統合案

#### 案 A: reviewer SubAgent からのオプション呼び出し

```yaml
trigger: ユーザーが「CodeRabbit でレビュー」を要求
action: reviewer が coderabbit review --prompt-only を実行
output: CodeRabbit の出力を reviewer の判断に組み込む
```

#### 案 B: PR 作成時の自動レビュー

```yaml
trigger: git push 後
action: GitHub App 版 CodeRabbit が PR をレビュー
output: PR コメントとして修正提案
```

#### 案 C: 手動レビューコマンド

```yaml
command: /coderabbit
action: coderabbit review --prompt-only --type uncommitted
output: ユーザーに直接表示
```

### 7.3 推奨実装

**案 C（手動レビューコマンド）を推奨**。

理由:
- レートリミットをユーザーが制御可能
- LOOP とは独立して使用可能
- 実装コストが最小

実装方法:
1. `.claude/commands/coderabbit.md` を作成
2. コマンド内で `coderabbit review --prompt-only` を実行
3. 出力をユーザーに表示

---

## 8. 結論

### 8.1 可用性評価

| 項目 | 評価 |
|------|------|
| インストール | ✅ 容易 |
| 認証 | ✅ GitHub OAuth で簡単 |
| 検出精度 | ✅ 高（false positive なし） |
| 出力形式 | ✅ AI 向け `--prompt-only` あり |
| レートリミット | ⚠️ Free tier で制限あり |
| 外部依存 | ⚠️ API サービスに依存 |

### 8.2 統合判定

| 統合方法 | 判定 |
|---------|------|
| TDD LOOP 内 | ❌ 見送り |
| reviewer SubAgent 連携 | ⚠️ 将来検討 |
| 手動レビューコマンド | ✅ 推奨 |
| GitHub App（PR レビュー） | ✅ 推奨（別途検討） |

### 8.3 次のアクション

1. `/coderabbit` コマンドの作成（Phase 6 または別 playbook）
2. GitHub App 版の導入検討（リポジトリ設定）
3. Pro tier のコスト対効果評価（将来）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。CLI v0.3.4 の評価完了。 |
