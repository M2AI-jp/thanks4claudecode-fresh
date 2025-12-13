# Skill Test Scenarios

> **10個の Skill テストシナリオ（機能別 MECE 分類）**

---

## 状態管理系

### Skill: state

**Trigger:** state.md 更新時、focus 切り替え時、done_criteria 判定時
**Expected:**
- state.md の正しい更新
- playbook との整合性維持
- レイヤー構造の管理

**Verify:**
```bash
# state.md の構造が正しいことを確認
grep -E 'focus:|playbook:|goal:' state.md && echo PASS || echo FAIL
```

### Skill: plan-management

**Trigger:** playbook 作成時、phase 遷移時
**Expected:**
- 3層計画管理（project→playbook→phase）
- milestone との紐付け
- phase 進捗の追跡

**Verify:**
```bash
# playbook に derives_from が設定されていることを確認
grep -q 'derives_from:' plan/active/playbook-*.md && echo PASS || echo FAIL
```

---

## 品質管理系

### Skill: lint-checker

**Trigger:** .ts/.tsx/.js/.jsx/.sh 変更時
**Expected:**
- ESLint 実行
- 型チェック実行
- コーディング規約検証

**Verify:**
```bash
# TypeScript ファイルがある場合、lint が実行されることを確認
ls *.ts 2>/dev/null && npx eslint --ext .ts . || echo "No TS files"
```

### Skill: test-runner

**Trigger:** *.test.* / *.spec.* / test/ 変更時
**Expected:**
- Unit テスト実行
- E2E テスト実行
- テスト結果の報告

**Verify:**
```bash
# テストファイルがある場合、テストが実行されることを確認
ls test/*.test.* 2>/dev/null && npm test || echo "No test files"
```

### Skill: deploy-checker

**Trigger:** done_criteria に「デプロイ」「本番」が含まれる時
**Expected:**
- デプロイ準備検証
- 環境変数チェック
- ビルドチェック

**Verify:**
```bash
# デプロイ前チェックが実行されることを確認
# git status, npm run build 等
```

---

## 学習系

### Skill: learning

**Trigger:** エラー発生時、critic FAIL 時
**Expected:**
- 失敗パターンの記録
- 過去の失敗からの学習
- 同じ問題の繰り返し防止

**Verify:**
```bash
# failures.log に記録されていることを確認
test -f .claude/logs/failures.log && echo PASS || echo FAIL
```

---

## プロセス系

### Skill: consent-process

**Trigger:** playbook=null で新規タスク開始時
**Expected:**
- [理解確認] プロセスの実行
- 5W1H 形式での構造化
- ユーザー承認の取得

**Verify:**
```bash
# consent ファイルの存在確認
test -d .claude/consent && echo PASS || echo FAIL
```

### Skill: context-externalization

**Trigger:** Phase 完了時
**Expected:**
- コンテキストの外部化
- 重要情報の保存
- compact 前の準備

**Verify:**
```bash
# snapshot.json の存在確認
test -f .claude/snapshot.json && echo PASS || echo FAIL
```

### Skill: post-loop

**Trigger:** playbook の全 Phase が done
**Expected:**
- 自動コミット
- playbook アーカイブ
- project.milestone 更新
- /clear 推奨アナウンス
- 次 milestone の playbook 作成

**Verify:**
```bash
# アーカイブが作成されていることを確認
ls plan/archive/playbook-*.md 2>/dev/null && echo PASS || echo "No archives"
```

### Skill: context-management

**Trigger:** /compact 実行時、コンテキスト管理時
**Expected:**
- /compact 最適化
- 履歴要約
- 重要情報の保持

**Verify:**
```bash
# compact 後も state.md が正しいことを確認
grep -q 'focus:' state.md && echo PASS || echo FAIL
```

---

## Skill 呼び出しフロー検証

### シナリオ: Phase 完了からコンテキスト管理まで

```
1. Phase 完了判定
   → critic Skill による検証
   → lint-checker, test-runner の呼び出し

2. Phase PASS
   → context-externalization で状態保存
   → post-loop で次の処理

3. playbook 完了
   → /clear 推奨
   → context-management で履歴要約
```

**Verify:**
```bash
# Skill 呼び出しログを確認
grep -E 'lint-checker|test-runner|post-loop' .claude/logs/*.log 2>/dev/null
```

---

## Skill 設定ファイル確認

```bash
# Skill 定義ファイルの存在確認
ls .claude/skills/*/skill.md .claude/skills/*/SKILL.md 2>/dev/null | wc -l
# 期待値: 10 以上
```
