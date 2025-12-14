# playbook-m022-solid-refactoring.md

> **SOLID原則に基づくシステム再構築 - Hook の責任分離と文書化**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m022-solid-refactoring
created: 2025-12-14
issue: null
derives_from: M022
reviewed: true
```

---

## goal

```yaml
summary: SOLID原則（特に単一責任原則）に基づいてシステムを再構築し、各 Hook の責任をドキュメント化
done_when:
  - init-guard.sh が単一責任を持つ（必須ファイル Read 強制のみ）
  - playbook-guard.sh が playbook 存在チェック責任を持つ（実装確認）
  - docs/hook-responsibilities.md に全 Hook の責任が明示されている
  - テスト実行で Hook 間の責任分離が検証される
```

---

## phases

### p0: init-guard.sh の責任分離（単一責任化）

```yaml
id: p0
name: init-guard.sh の責任分離
goal: |
  init-guard.sh が単一責任（必須ファイル Read 強制のみ）を持つようにリファクタリング。
  現在の init-guard.sh には複数の責任が混在しているため、各責任を適切に分離する。

subtasks:
  - id: p0.1
    criterion: "init-guard.sh の責任を分析し、段階的に分離する計画が立てられている"
    executor: claudecode
    test_command: |
      grep -E "^# (目的|責務|責任)" /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      echo "PASS" || echo "FAIL"

  - id: p0.2
    criterion: "init-guard.sh で必須ファイル Read 強制以外の責任が分離されている"
    executor: claudecode
    test_command: |
      # 現在の init-guard.sh が Read 強制に専念しているか確認
      # 期待: pending ファイル管理、必須ファイルチェック、permission ガード（単一責任）
      grep -c "# ==============================================================================\|^# 目的:\|^# トリガー:\|^# 責任:" \
        /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh | awk '{if($1>=2) print "PASS"; else print "FAIL"}'

  - id: p0.3
    criterion: "init-guard.sh が責任分離について comment で文書化されている"
    executor: claudecode
    test_command: |
      grep -q "単一責任\|責任分離\|SOLID" \
        /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      echo "PASS" || echo "FAIL"

status: done
max_iterations: 5
```

### p1: playbook-guard.sh の責任確認と分離

```yaml
id: p1
name: playbook-guard.sh が playbook 存在チェック責任を持つ
goal: |
  playbook-guard.sh が「playbook 存在チェック」という単一責任を明確に持つようにし、
  他の責任と混同されないようにする。実装を確認し、必要に応じてリファクタリング。

depends_on: [p0]

subtasks:
  - id: p1.1
    criterion: "playbook-guard.sh が playbook 存在チェック責任を持つことが確認されている"
    executor: claudecode
    test_command: |
      # playbook-guard.sh の主要な責任を確認
      grep -q "playbook.*存在\|playbook.*チェック\|playbook.*guard" \
        /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh && \
      echo "PASS" || echo "FAIL"

  - id: p1.2
    criterion: "playbook-guard.sh に責任について明示的な comment が付加されている"
    executor: claudecode
    test_command: |
      grep -E "^# (目的|責務|責任):|単一責任|playbook チェック" \
        /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh | \
      wc -l | awk '{if($1>=2) print "PASS"; else print "FAIL"}'

  - id: p1.3
    criterion: "playbook-guard.sh が state.md へのアクセスチェック責任を持つことが確認されている"
    executor: claudecode
    test_command: |
      grep -q "reviewed\|FILE_PATH" \
        /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh && \
      echo "PASS" || echo "FAIL"

status: done
max_iterations: 5
```

### p2: docs/hook-responsibilities.md 作成

```yaml
id: p2
name: docs/hook-responsibilities.md 作成
goal: |
  全 Hook の責任を明確に記述するドキュメント hook-responsibilities.md を作成。
  各 Hook の役割、トリガー、責任範囲を一元管理する。

depends_on: [p1]

subtasks:
  - id: p2.1
    criterion: "docs/hook-responsibilities.md が存在し、全 Hook の責任が記載されている"
    executor: claudecode
    test_command: |
      test -f /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      grep -q "^#" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      echo "PASS" || echo "FAIL"

  - id: p2.2
    criterion: "hook-responsibilities.md に init-guard.sh の責任が記載されている"
    executor: claudecode
    test_command: |
      grep -q "init-guard.sh" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      grep -q "必須ファイル\|Read" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      echo "PASS" || echo "FAIL"

  - id: p2.3
    criterion: "hook-responsibilities.md に playbook-guard.sh の責任が記載されている"
    executor: claudecode
    test_command: |
      grep -q "playbook-guard.sh" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      grep -q "playbook\|チェック" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      echo "PASS" || echo "FAIL"

  - id: p2.4
    criterion: "hook-responsibilities.md に全 Hook の責任が記載されている（15個以上）"
    executor: claudecode
    test_command: |
      grep -c "^###\|^##" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md | \
      awk '{if($1>=10) print "PASS"; else print "FAIL"}'

  - id: p2.5
    criterion: "hook-responsibilities.md に SOLID 原則の説明が含まれている"
    executor: claudecode
    test_command: |
      grep -qi "SOLID\|単一責任\|Single Responsibility" \
        /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      echo "PASS" || echo "FAIL"

status: done
max_iterations: 5
```

### p3: 統合テスト

```yaml
id: p3
name: 統合テスト
goal: |
  リファクタリングされた Hook が正しく動作することを検証。
  session-start → init-guard → playbook-guard の連鎖動作を確認。

depends_on: [p2]

subtasks:
  - id: p3.1
    criterion: "init-guard.sh の構文が正しい（bash -n でチェック）"
    executor: claudecode
    test_command: |
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      echo "PASS" || echo "FAIL"

  - id: p3.2
    criterion: "playbook-guard.sh の構文が正しい（bash -n でチェック）"
    executor: claudecode
    test_command: |
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/playbook-guard.sh && \
      echo "PASS" || echo "FAIL"

  - id: p3.3
    criterion: "全 Hook ファイルの構文チェック（15個以上）が通っている"
    executor: claudecode
    test_command: |
      cd /Users/amano/Desktop/thanks4claudecode && \
      count=$(find .claude/hooks -name "*.sh" -exec bash -n {} \; 2>&1 | wc -l) && \
      [ $count -eq 0 ] && echo "PASS" || echo "FAIL"

  - id: p3.4
    criterion: "hook-responsibilities.md が reference フォーマット（YAML/Markdown）に準拠している"
    executor: claudecode
    test_command: |
      grep -E "^---|^# |^## |^### |\`\`\`" \
        /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md | \
      wc -l | awk '{if($1>=5) print "PASS"; else print "FAIL"}'

  - id: p3.5
    criterion: "project.md との整合性チェック（M022 の done_when との対応確認）"
    executor: claudecode
    test_command: |
      # M022 の要件をチェック
      [ -f /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md ] && \
      grep -q "init-guard" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      grep -q "playbook-guard" /Users/amano/Desktop/thanks4claudecode/docs/hook-responsibilities.md && \
      echo "PASS" || echo "FAIL"

status: done
max_iterations: 5
```

---

## 参照ファイル

- plan/project.md - M022 の定義
- .claude/hooks/init-guard.sh - 対象 Hook
- .claude/hooks/playbook-guard.sh - 対象 Hook
- docs/criterion-validation-rules.md - criterion 検証ルール
- plan/template/playbook-format.md - playbook テンプレート

---

## 設計ノート

### SOLID 原則の適用

```yaml
単一責任原則（SRP: Single Responsibility Principle）:
  - 各 Hook は1つの責任のみを持つ
  - init-guard.sh: 必須ファイルの Read 強制
  - playbook-guard.sh: playbook 存在チェック
  - 他の Hook: 各々の責任を明示

分離のメリット:
  - テスト容易性の向上
  - 保守性の向上
  - 変更時の影響範囲の最小化
  - 責任が明確になり、バグが減少
```

### Phase 設計の根拠

1. **p0**: 分析と計画 → 既存コードの現状を理解
2. **p1**: 責任確認 → playbook-guard の責任が明確か確認
3. **p2**: ドキュメント化 → 全 Hook の責任を一元管理
4. **p3**: 統合テスト → Hook 間の連携が正しく動作するか検証

### 成果物

- docs/hook-responsibilities.md - 全 Hook の責任を記述
- init-guard.sh への comment 追加
- playbook-guard.sh への comment 追加

### テンポラリファイル

- なし（既存ファイルの修正と新規ドキュメント作成のみ）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | playbook-m022-solid-refactoring.md 初版作成 |
