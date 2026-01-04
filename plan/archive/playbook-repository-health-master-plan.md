# plan/playbook-repository-health-master-plan.md

## meta

```yaml
project: repository-health-master-plan
branch: docs/repository-health-master-plan
created: 2026-01-04
issue: null
reviewed: true
review_note: "manual review by codex (reviewer tool unavailable)"
```

## context

```yaml
user_request: >
  かつて fix-backlog.md を生成したが、前段の「全機能が正常に動作するか/必要か」が
  抜けていた。まず上位設計書を作成し、基準整理(2)→依存抽出(1)を行った上で、
  repository-map と ARCHITECTURE.md を最新版に更新し、全機能・ドキュメントの
  メンテナンスを進める。
decisions:
  - 上位設計書を plan/design に新規作成
  - 判定基準を先に定義し、次に依存抽出を行う
  - 依存抽出は hooks → skills → agents の実参照を起点に機械的に実施
  - 更新対象は docs/repository-map.yaml と docs/ARCHITECTURE.md
  - fix-backlog は廃止し、repository-health を SSOT にする
constraints:
  - 証拠ベースで判定（コマンド出力/参照箇所）
  - 最小構成を維持、不要なファイルは増やさない
```

## goal

```yaml
summary: リポジトリ健全性の上位設計と判定基準を確立し、依存抽出結果で主要ドキュメントを更新する
done_when:
  - plan/design/repository-health-master-plan.md が作成され、scope/definitions/workflow/evidence を含む
  - docs/repository-health.md に判定基準と抽出結果（必須/壊れている/不要の分類）が記載されている
  - docs/repository-map.yaml と docs/ARCHITECTURE.md が抽出結果に沿って更新されている
  - docs/repository-health.md に playbook 生成方針が記載されている
```

## phases

### p1: 上位設計書の作成

**goal**: 大規模メンテナンスの全体方針と手順を定義する

#### subtasks

- [x] **p1.1**: plan/design/repository-health-master-plan.md が存在し、scope/definitions/workflow/evidence が明記されている
  - executor: codex
  - validations:
    - technical: "test -f plan/design/repository-health-master-plan.md が PASS"
    - consistency: "plan/design/README.md の設計一覧と矛盾しない"
    - completeness: "scope/definitions/workflow/evidence と playbook 生成方針が記載されている"

- [x] **p1.2**: plan/design/README.md に上位設計書が追加されている
  - executor: codex
  - validations:
    - technical: "rg \"repository-health-master-plan\" plan/design/README.md がヒットする"
    - consistency: "既存の一覧フォーマットに準拠している"
    - completeness: "役割と参照タイミングの説明が不足していない"

**status**: done
**max_iterations**: 5

---

### p2: 判定基準の定義

**goal**: 「必要/壊れている/不要」の判定基準と証拠形式を定義する
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: docs/repository-health.md に判定基準と証拠フォーマットが明記されている
  - executor: codex
  - validations:
    - technical: "rg \"判定基準|evidence\" docs/repository-health.md がヒットする"
    - consistency: "docs/criterion-validation-rules.md と矛盾しない"
    - completeness: "必須/壊れている/不要 の定義が揃っている"

- [x] **p2.2**: docs/repository-health.md に playbook 生成方針が明記されている
  - executor: codex
  - validations:
    - technical: "rg \"playbook 生成方針\" docs/repository-health.md がヒットする"
    - consistency: "repository-health の SSOT 方針と矛盾しない"
    - completeness: "required_broken から playbook を作るルールが定義されている"

**status**: done
**max_iterations**: 5

---

### p3: 依存抽出と分類

**goal**: hooks→skills→agents の実参照に基づき機械的に抽出し分類する
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: hooks/skills/agents の参照チェーンが docs/repository-health.md に記録されている
  - executor: codex
  - validations:
    - technical: "rg \"hooks|skills|agents\" docs/repository-health.md がヒットする"
    - consistency: "実ファイルの存在と参照先が一致している"
    - completeness: "L1/L2/L3 の主要構成が網羅されている"

- [x] **p3.2**: 必須/壊れている/不要 の分類が docs/repository-health.md に反映されている
  - executor: codex
  - validations:
    - technical: "rg \"必須|壊れている|不要\" docs/repository-health.md がヒットする"
    - consistency: "分類根拠が参照証拠と一致している"
    - completeness: "分類から漏れている主要コンポーネントがない"

**status**: done
**max_iterations**: 5

---

### p4: 主要ドキュメント更新

**goal**: 抽出結果を反映して repository-map と ARCHITECTURE を更新する
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: docs/repository-map.yaml が最新化され、抽出結果と一致している
  - executor: codex
  - validations:
    - technical: "rg \"repository-map\" docs/repository-map.yaml が存在する"
    - consistency: "生成結果と docs/repository-health.md が整合している"
    - completeness: "必要なファイルが欠落していない"

- [x] **p4.2**: docs/ARCHITECTURE.md が抽出結果に沿って更新されている
  - executor: codex
  - validations:
    - technical: "rg \"repository-health\" docs/ARCHITECTURE.md がヒットする"
    - consistency: "docs/repository-health.md と分類が一致している"
    - completeness: "必須構成と壊れている構成が明記されている"

**status**: done
**max_iterations**: 5

---

### p5: メンテナンス方針の確定

**goal**: 全機能・ドキュメントのメンテナンス方針を確定する
**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: docs/repository-health.md にメンテナンス方針（修復/削除/保留）が明記されている
  - executor: codex
  - validations:
    - technical: "rg \"メンテナンス\" docs/repository-health.md がヒットする"
    - consistency: "分類結果と方針が整合している"
    - completeness: "必須/壊れている/不要 の全てに方針がある"

**status**: done
**max_iterations**: 5
