# playbook-m063-repository-cleanup.md

> **リポジトリ洗浄 - 無効参照・孤立ファイル・壊れた Hook の削除**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m063-repository-cleanup
created: 2025-12-17
issue: null
derives_from: M063
reviewed: true
```

---

## goal

```yaml
summary: リポジトリから無効な参照、孤立ファイル、壊れた Hook を削除し、整合性を回復する
done_when:
  - 孤立ファイル（plan-guard.md, CLAUDE-ref.md, context-externalization/, execution-management/）が削除されている
  - protected-files.txt から存在しないファイルへの参照が削除されている
  - 壊れた Hook（check-file-dependencies.sh, doc-freshness-check.sh, update-tracker.sh）が削除されている
  - settings.json から削除した Hook の登録が削除されている
  - ドキュメント（repository-map.yaml, CLAUDE.md 等）が更新されている
```

---

## phases

### p1: 孤立ファイルの削除

**goal**: 他から参照されていないファイルを削除する

#### subtasks

- [ ] **p1.1**: .claude/agents/plan-guard.md が削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/agents/plan-guard.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在しないこと"
    - consistency: "repository-map.yaml から参照が削除されること（p4で実施）"
    - completeness: "関連する全ての参照が削除されること"

- [ ] **p1.2**: .claude/CLAUDE-ref.md が削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/CLAUDE-ref.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在しないこと"
    - consistency: "CLAUDE.md から参照されていないこと"
    - completeness: "関連する全ての参照が削除されること"

- [ ] **p1.3**: .claude/skills/context-externalization/ ディレクトリが削除されている
  - executor: claudecode
  - test_command: `test ! -d .claude/skills/context-externalization && echo PASS || echo FAIL`
  - validations:
    - technical: "ディレクトリが存在しないこと"
    - consistency: "skills/CLAUDE.md から参照が削除されること（p4で実施）"
    - completeness: "ディレクトリ内の全ファイルが削除されること"

- [ ] **p1.4**: .claude/skills/execution-management/ ディレクトリが削除されている
  - executor: claudecode
  - test_command: `test ! -d .claude/skills/execution-management && echo PASS || echo FAIL`
  - validations:
    - technical: "ディレクトリが存在しないこと"
    - consistency: "skills/CLAUDE.md から参照が削除されること（p4で実施）"
    - completeness: "ディレクトリ内の全ファイルが削除されること"

**status**: pending
**max_iterations**: 3

---

### p2: 無効な参照の修正

**goal**: 存在しないファイルへの参照を削除する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: protected-files.txt から `BLOCK:.claude/hooks/check-state-update.sh` が削除されている
  - executor: claudecode
  - test_command: `! grep -q 'check-state-update.sh' .claude/protected-files.txt && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当行が見つからないこと"
    - consistency: "他の BLOCK 行は維持されていること"
    - completeness: "存在しないファイルへの全参照が削除されること"

**status**: pending
**max_iterations**: 3

---

### p3: 壊れた Hook の削除 + settings.json 更新

**goal**: 依存ファイルが存在しない Hook を削除し、登録を解除する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: .claude/hooks/check-file-dependencies.sh が削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/hooks/check-file-dependencies.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在しないこと"
    - consistency: "settings.json から登録が削除されること（p3.4で実施）"
    - completeness: "file-dependencies.yaml が存在しないため Hook は不要"

- [ ] **p3.2**: .claude/hooks/doc-freshness-check.sh が削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/hooks/doc-freshness-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在しないこと"
    - consistency: "settings.json から登録が削除されること（p3.4で実施）"
    - completeness: "current-implementation.md が存在しないため Hook は不要"

- [ ] **p3.3**: .claude/hooks/update-tracker.sh が削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/hooks/update-tracker.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在しないこと"
    - consistency: "settings.json から登録が削除されること（p3.4で実施）"
    - completeness: "generate-implementation-doc.sh が存在しないため Hook は不要"

- [ ] **p3.4**: settings.json から削除した Hook の登録が全て削除されている
  - executor: claudecode
  - test_command: `! grep -E 'check-file-dependencies|doc-freshness-check|update-tracker' .claude/settings.json && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当する登録が見つからないこと"
    - consistency: "他の Hook 登録は維持されていること"
    - completeness: "削除した 3 つの Hook 全ての登録が削除されていること"

- [ ] **p3.5**: settings.json が有効な JSON 形式である
  - executor: claudecode
  - test_command: `cat .claude/settings.json | python3 -m json.tool > /dev/null 2>&1 && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON パースエラーがないこと"
    - consistency: "既存の設定が破壊されていないこと"
    - completeness: "全ての Hook 登録が有効であること"

**status**: pending
**max_iterations**: 5

---

### p4: ドキュメント更新

**goal**: 削除したファイルの参照をドキュメントから削除する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: repository-map.yaml が再生成されている
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && ! grep -E 'plan-guard|CLAUDE-ref|context-externalization|execution-management|check-file-dependencies|doc-freshness-check|update-tracker' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "generate-repository-map.sh が正常に実行できること"
    - consistency: "削除したファイルがマップに含まれていないこと"
    - completeness: "全ての現存ファイルがマップに含まれていること"

- [ ] **p4.2**: .claude/skills/CLAUDE.md から削除した Skill の参照が削除されている
  - executor: claudecode
  - test_command: `! grep -E 'context-externalization|execution-management' .claude/skills/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当行が見つからないこと"
    - consistency: "他の Skill 参照は維持されていること"
    - completeness: "削除した 2 つの Skill 全ての参照が削除されていること"

- [ ] **p4.3**: .claude/agents/CLAUDE.md から削除した SubAgent の参照が削除されている
  - executor: claudecode
  - test_command: `! grep -q 'plan-guard' .claude/agents/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当行が見つからないこと"
    - consistency: "他の SubAgent 参照は維持されていること"
    - completeness: "plan-guard への全ての参照が削除されていること"

- [ ] **p4.4**: docs/hook-responsibilities.md から削除した Hook の説明が削除されている
  - executor: claudecode
  - test_command: `! grep -E 'check-file-dependencies|doc-freshness-check|update-tracker' docs/hook-responsibilities.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当行が見つからないこと"
    - consistency: "他の Hook の説明は維持されていること"
    - completeness: "削除した 3 つの Hook 全ての説明が削除されていること"

**status**: pending
**max_iterations**: 5

---

### p5: CLAUDE.md スリム化（オプション）

**goal**: CLAUDE.md の「あるべき姿」セクションを docs/design/ に移動する

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: docs/design/solid-principles.md が作成されている
  - executor: claudecode
  - test_command: `test -f docs/design/solid-principles.md && grep -q 'SOLID' docs/design/solid-principles.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、SOLID の説明が含まれていること"
    - consistency: "CLAUDE.md の内容と一致していること"
    - completeness: "M015-M023 の全説明が移動されていること"

- [ ] **p5.2**: CLAUDE.md から「あるべき姿」セクションが削除されている
  - executor: claudecode
  - test_command: `! grep -q '## あるべき姿' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セクションヘッダーが存在しないこと"
    - consistency: "他のセクションが破壊されていないこと"
    - completeness: "「あるべき姿」の全内容が削除されていること"

- [ ] **p5.3**: CLAUDE.md に docs/design/solid-principles.md への参照が追加されている
  - executor: claudecode
  - test_command: `grep -q 'docs/design/solid-principles.md' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "参照が存在すること"
    - consistency: "参照先ファイルが実際に存在すること"
    - completeness: "参照が適切な場所（参照ドキュメントセクション等）に配置されていること"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 全ての done_when が満たされていることを最終確認する

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: 孤立ファイルが全て削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/agents/plan-guard.md && test ! -f .claude/CLAUDE-ref.md && test ! -d .claude/skills/context-externalization && test ! -d .claude/skills/execution-management && echo PASS || echo FAIL`
  - validations:
    - technical: "全ての孤立ファイルが存在しないこと"
    - consistency: "ドキュメントから参照が削除されていること"
    - completeness: "リストアップされた全ファイルが削除されていること"

- [ ] **p_final.2**: protected-files.txt が正常である
  - executor: claudecode
  - test_command: `! grep -q 'check-state-update.sh' .claude/protected-files.txt && echo PASS || echo FAIL`
  - validations:
    - technical: "存在しないファイルへの参照がないこと"
    - consistency: "他の BLOCK 行が正常であること"
    - completeness: "全ての無効参照が削除されていること"

- [ ] **p_final.3**: 壊れた Hook が全て削除されている
  - executor: claudecode
  - test_command: `test ! -f .claude/hooks/check-file-dependencies.sh && test ! -f .claude/hooks/doc-freshness-check.sh && test ! -f .claude/hooks/update-tracker.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "全ての壊れた Hook が存在しないこと"
    - consistency: "settings.json から登録が削除されていること"
    - completeness: "リストアップされた全 Hook が削除されていること"

- [ ] **p_final.4**: settings.json が正常である
  - executor: claudecode
  - test_command: `cat .claude/settings.json | python3 -m json.tool > /dev/null 2>&1 && ! grep -E 'check-file-dependencies|doc-freshness-check|update-tracker' .claude/settings.json && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON が有効であること"
    - consistency: "削除した Hook の登録がないこと"
    - completeness: "全ての Hook 登録が有効なファイルを参照していること"

- [ ] **p_final.5**: ドキュメントが全て更新されている
  - executor: claudecode
  - test_command: `! grep -E 'plan-guard|CLAUDE-ref|context-externalization|execution-management|check-file-dependencies|doc-freshness-check|update-tracker' docs/repository-map.yaml .claude/skills/CLAUDE.md .claude/agents/CLAUDE.md docs/hook-responsibilities.md 2>/dev/null && echo PASS || echo FAIL`
  - validations:
    - technical: "削除したファイルへの参照がないこと"
    - consistency: "全ドキュメントが更新されていること"
    - completeness: "全ての参照が削除されていること"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。リポジトリ洗浄計画を V12 チェックボックス形式で定義。 |
