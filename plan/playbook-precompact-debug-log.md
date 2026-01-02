# playbook-precompact-debug-log.md

> **PreCompact 設計の刷新: snapshot.json 廃止 → 最小ポインタ設計**

---

## meta

```yaml
project: precompact-redesign
branch: fix/restore-demo-files
created: 2026-01-02
updated: 2026-01-02
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: |
  PreCompact Hook の設計を刷新。
  snapshot.json を廃止し、additionalContext の最小ポインタのみで復元する設計に変更。
  関連ドキュメント（ARCHITECTURE.md, repository-map.yaml）も同期更新。

done_when:
  - compact.sh が最小ポインタ（playbook/phase/branch）のみを additionalContext に出力する
  - snapshot.json 作成コードが削除されている
  - start.sh から restore_from_snapshot が削除されている
  - ARCHITECTURE.md に PreCompact セクションと全 Skills が記載されている
  - repository-map.yaml が最新状態に同期されている
```

---

## context

```yaml
5w1h:
  who: Claude Code フレームワーク開発者
  what: PreCompact 設計の刷新（snapshot.json 廃止）
  when: 2026-01-02
  where: compact.sh, start.sh, ARCHITECTURE.md, repository-map.yaml
  why: |
    - snapshot.json は .claude/ 配下にあり compact で削除される
    - additionalContext が唯一確実に読まれる復元橋
    - データ分散を避け、永続データは playbook に集約
  how: |
    1. compact.sh を最小ポインタ出力に簡素化
    2. start.sh から snapshot 復元コードを削除
    3. ARCHITECTURE.md を実装と同期
    4. repository-map.yaml を自動再生成

design_decision:
  永続データ: playbook に集約（SSOT の延長）
  復元橋: additionalContext（最小ポインタのみ）
  snapshot.json: 廃止（.claude/ 配下は compact で削除されるため）

additionalContext_minimal_set:
  - resume_instruction: 必須（1行で「何を読むか」）
  - playbook: 必須
  - phase: 必須
  - branch: 任意（便利）
```

---

## phases

### p1: compact.sh 刷新

**goal**: snapshot.json 廃止、最小ポインタ設計に変更

#### subtasks

- [x] **p1.1**: snapshot.json 作成コードを削除
  - executor: claudecode
  - validations:
    - technical: "grep 'SNAPSHOT_FILE' compact.sh が存在しない"
    - consistency: "additionalContext 出力のみ残る"
    - completeness: "デバッグログコードも削除"

- [x] **p1.2**: additionalContext を最小セットに簡素化
  - executor: claudecode
  - validations:
    - technical: "compact.sh が playbook/phase/branch/resume_instruction のみ出力"
    - consistency: "159行 → 68行（57%削減）"
    - completeness: "JSON 形式で正しく出力"

**status**: done

---

### p2: start.sh 同期

**goal**: snapshot.json 復元コードを削除

#### subtasks

- [x] **p2.1**: restore_from_snapshot 関数を削除
  - executor: claudecode
  - validations:
    - technical: "grep 'restore_from_snapshot' start.sh が存在しない"
    - consistency: "他の機能に影響なし"
    - completeness: "関数定義と呼び出しの両方を削除"

**status**: done

---

### p3: ARCHITECTURE.md 同期

**goal**: 実装とドキュメントの整合性を確保

#### subtasks

- [x] **p3.1**: PreCompact セクション（1.5節）を追加
  - executor: claudecode
  - validations:
    - technical: "ARCHITECTURE.md に PreCompact セクションが存在"
    - consistency: "最小ポインタ設計が明記"
    - completeness: "設計思想、出力フィールド、状態遷移を記載"

- [x] **p3.2**: 欠落 Skills（13個）を追加
  - executor: claudecode
  - validations:
    - technical: "全 21 Skills が記載されている"
    - consistency: "実際のファイル構造と一致"
    - completeness: "各 Skill の構造が記載"

- [x] **p3.3**: 欠落 SubAgents（3個）を追加
  - executor: claudecode
  - validations:
    - technical: "prompt-analyzer, term-translator, executor-resolver が記載"
    - consistency: "ツール制限テーブルにも追記"
    - completeness: "SubAgent セクションに説明を追加"

- [x] **p3.4**: 既存セクションの補完
  - executor: claudecode
  - validations:
    - technical: "role-resolver.sh, merge-pr.sh, integrity.sh 等が追記"
    - consistency: "実際のファイル構造と一致"
    - completeness: "全ての欠落ファイルを補完"

**status**: done

---

### p4: repository-map.yaml 同期

**goal**: 自動生成で最新状態に同期

#### subtasks

- [x] **p4.1**: generate-repository-map.sh を実行
  - executor: claudecode
  - validations:
    - technical: "bash .claude/hooks/generate-repository-map.sh が成功"
    - consistency: "Total files, Hooks, Agents, Skills のカウントが正確"
    - completeness: "全セクションが更新"

**status**: done

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p1, p2, p3, p4]

#### subtasks

- [ ] **p_final.1**: compact.sh が最小ポインタのみ出力
  - executor: claudecode
  - validations:
    - technical: "echo '{}' | bash compact.sh で最小セットのみ出力"
    - consistency: "snapshot.json 作成なし"
    - completeness: "playbook/phase/branch/resume_instruction のみ"

- [ ] **p_final.2**: start.sh に復元コードなし
  - executor: claudecode
  - validations:
    - technical: "grep 'snapshot' start.sh が存在しない"
    - consistency: "正常に動作する"
    - completeness: "関数と呼び出しの両方が削除済み"

- [ ] **p_final.3**: ARCHITECTURE.md が実装と同期
  - executor: claudecode
  - validations:
    - technical: "全 Skills/SubAgents が記載"
    - consistency: "PreCompact セクションに最小ポインタ設計が明記"
    - completeness: "変更履歴が更新済み"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更をコミットする
  - command: `git add -A && git commit`
  - status: pending

- [ ] **ft2**: PR 作成またはマージ
  - status: pending
