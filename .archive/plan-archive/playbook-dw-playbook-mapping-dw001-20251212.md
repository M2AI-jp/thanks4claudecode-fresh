# playbook-dw-playbook-mapping-dw001

> **1 done_when = 1 playbook ルール明文化**

---

## meta

```yaml
playbook: playbook-dw-playbook-mapping-dw001
created: 2025-12-12
issue: null
derives_from: DW-001
status: draft
reviewed: false
```

---

## goal

```yaml
summary: "pm, playbook-format.md, CLAUDE.md に「1 done_when = 1 playbook」ルール追加"
done_criteria:
  - pm.md に「1 done_when = 1 playbook」ルールが明記されている
  - playbook-format.md に「derives_from」説明と「1 done_when = 1 playbook」の関係が記載されている
  - CLAUDE.md の「タスク標準化」セクションに「1 done_when = 1 playbook」への参照が含まれている
  - 変更内容が整合性を持ち、重複や矛盾がない
```

---

## phases

### Phase 1: 現状分析

> 既存ドキュメントの構造を把握し、どこにルール追加すべきか検討。

#### done_criteria

- pm.md の現在の記述内容を把握している
- playbook-format.md の derives_from セクションを確認している
- CLAUDE.md の「タスク標準化」セクションを確認している

#### tasks

```yaml
tasks:
  - id: p1-t1
    name: pm.md の現状確認
    subtasks:
      - step: "pm.md を読み込み、playbook 作成フロー全体を把握"
        executor: claudecode
        criteria: "pm.md の内容を理解し、どこに「1 done_when = 1 playbook」ルールを追加すべきか判断している"
        status: "[x]"
      - step: "pm.md 内の「playbook 作成フロー」セクションを特定"
        executor: claudecode
        criteria: "pm.md に playbook 作成手順が記載されているセクションが特定されている"
        status: "[x]"

  - id: p1-t2
    name: playbook-format.md の現状確認
    subtasks:
      - step: "playbook-format.md を読み込み、derives_from フィールドの説明を確認"
        executor: claudecode
        criteria: "derives_from フィールドの役割と使用方法を理解している"
        status: "[x]"
      - step: "playbook-format.md 内に「1 done_when = 1 playbook」への言及があるかを確認"
        executor: claudecode
        criteria: "現在の playbook-format.md に該当ルールの記載があるか（または欠落しているか）を判定"
        status: "[x]"

  - id: p1-t3
    name: CLAUDE.md の現状確認
    subtasks:
      - step: "CLAUDE.md の「タスク標準化」セクションを読み込み、現在の内容を把握"
        executor: claudecode
        criteria: "CLAUDE.md 内の「タスク標準化」セクションが特定され、その内容を理解している"
        status: "[x]"
      - step: "「タスク標準化」セクションに「1 done_when = 1 playbook」への記載があるかを確認"
        executor: claudecode
        criteria: "現在の記載状況（あり/なし）を判定している"
        status: "[x]"

  - id: p1-t4
    name: ルール追加箇所の決定
    subtasks:
      - step: "上記確認結果から、各ドキュメントに追加すべき内容をまとめる"
        executor: claudecode
        criteria: "pm.md, playbook-format.md, CLAUDE.md のそれぞれで、何をどこに追加すべきかをドキュメント化している"
        status: "[x]"
```

---

### Phase 2: ルール追加

> ドキュメントに「1 done_when = 1 playbook」ルールを明記。

#### done_criteria

- pm.md に「1 done_when = 1 playbook」ルールが追加されている
- playbook-format.md に explains_from との関係が追加されている
- CLAUDE.md の「タスク標準化」セクションが更新されている
- 全ドキュメント間で整合性が保たれている

#### tasks

```yaml
tasks:
  - id: p2-t1
    name: pm.md に「1 done_when = 1 playbook」ルールを追加
    subtasks:
      - step: "pm.md を開き、playbook 作成フロー説明を確認"
        executor: claudecode
        criteria: "pm.md が Edit ツールで開かれ、内容が表示されている"
        status: "[x]"
      - step: "「playbook 作成フロー」セクション内に「1 done_when = 1 playbook」ルール説明を追加"
        executor: claudecode
        criteria: "pm.md に以下のルール説明が含まれている: 『1 done_when（project.md の done_when）に対して、1 つの playbook が生成される関係が確立される』"
        status: "[x]"
      - step: "ルール追加に伴う関連文の修正・補足を実施"
        executor: claudecode
        criteria: "pm.md 内に重複・矛盾がなく、ルール説明が他セクションと整合している"
        status: "[x]"

  - id: p2-t2
    name: playbook-format.md に「1 done_when = 1 playbook」関係を追加
    subtasks:
      - step: "playbook-format.md を開き、derives_from セクションを確認"
        executor: claudecode
        criteria: "playbook-format.md の derives_from 説明が表示されている"
        status: "[x]"
      - step: "derives_from セクション内に『1 done_when = 1 playbook』の関係を明記"
        executor: claudecode
        criteria: "playbook-format.md に『done_when.id を設定してくださいと説明し、複数の done_when に対応する playbook は作成しない』という説明が含まれている"
        status: "[x]"

  - id: p2-t3
    name: CLAUDE.md の「タスク標準化」セクションを更新
    subtasks:
      - step: "CLAUDE.md の「タスク標準化」セクションを開き、現在の内容を確認"
        executor: claudecode
        criteria: "CLAUDE.md の該当セクションが表示されている"
        status: "[x]"
      - step: "「タスク標準化」セクション内に『1 done_when = 1 playbook』への参照を追加"
        executor: claudecode
        criteria: "CLAUDE.md に『全タスク開始は pm SubAgent 経由必須。1 done_when に対して 1 つの playbook を生成』という説明が含まれている"
        status: "[x]"

  - id: p2-t4
    name: 全ドキュメント間の整合性確認
    subtasks:
      - step: "pm.md, playbook-format.md, CLAUDE.md の該当セクションを横断的に確認"
        executor: claudecode
        criteria: "3つのドキュメントで『1 done_when = 1 playbook』ルールが一貫した表現で記載されている"
        status: "[x]"
      - step: "矛盾がないか、重複がないかを検証"
        executor: claudecode
        criteria: "ドキュメント間の記述に矛盾がなく、役割分担が明確である（pm.md: why/when, playbook-format.md: how, CLAUDE.md: mandate）"
        status: "[x]"
```

---

### Phase 3: 検証と統合テスト

> 追加したルールが実際に機能するか、pm が遵守できるかを検証。

#### done_criteria

- pm が『1 done_when = 1 playbook』ルールに従い、新規 playbook を作成している
- playbook に derives_from が正しく設定されている
- ドキュメント全体に矛盾がない

#### tasks

```yaml
tasks:
  - id: p3-t1
    name: pm が『1 done_when = 1 playbook』ルールを理解・遵守しているか検証
    subtasks:
      - step: "新規タスク開始シナリオで pm がルール通りに動作するか simulation を実行"
        executor: claudecode
        criteria: "pm が project.md の done_when を参照し、1つの done_when に対して 1つの playbook を生成する動作をシミュレートしている"
        status: "[x]"
      - step: "複数の done_when がある場合、pm が複数の playbook（同数）を順序立てて生成するか確認"
        executor: claudecode
        criteria: "pm が「複数の done_when → 複数の playbook」という正しいマッピングを実装している動作確認ができている"
        status: "[x]"

  - id: p3-t2
    name: derives_from フィールドが正しく設定される仕組みを検証
    subtasks:
      - step: "생성된 playbook の derives_from フィールドを確認"
        executor: claudecode
        criteria: "playbook の meta セクションに『derives_from: DW-001』のように対応する done_when.id が明記されている"
        status: "[x]"
      - step: "複数の playbook がそれぞれ異なる done_when.id を指していることを確認"
        executor: claudecode
        criteria: "각 playbook の derives_from が unique である（重複していない）"
        status: "[x]"

  - id: p3-t3
    name: ドキュメント全体の整合性を最終確認
    subtasks:
      - step: "pm.md, playbook-format.md, CLAUDE.md, project.md, playbook の全ドキュメントを横断的に読む"
        executor: claudecode
        criteria: "『1 done_when = 1 playbook』ルールが全ドキュメントで一貫している"
        status: "[x]"
      - step: "ユーザーの指示『DW-001 単位で、1 つ playbook が生成されるように仕様変更して欲しい』が達成されているか確認"
        executor: claudecode
        criteria: "ドキュメント修正により、ユーザーの要望が実装されている（pm の動作が変わる見込みがある）"
        status: "[x]"
```

---

## 参照

- .claude/agents/pm.md - pm SubAgent 仕様書
- plan/template/playbook-format.md - playbook テンプレート
- CLAUDE.md - LLM の振る舞いルール
