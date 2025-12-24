# playbook-feature-verification.md

> **Self-Healing Layer 3 完成: Hook 故障の自動検知と修復**

---

## meta

```yaml
project: feature-verification
branch: feat/feature-verification
created: 2025-12-24
issue: null
reviewed: true
roles:
  worker: claudecode  # Shell スクリプト実装のみ
```

---

## goal

```yaml
summary: SessionStart で Hook の存在・実行権限を自動検証し、問題を自動修復または警告する
done_when:
  - SessionStart で settings.json に登録された全 Hook の存在・実行権限を自動検証する
  - 問題検出時に警告メッセージが表示される
  - 自動修復可能な問題（chmod +x）は自動修復される
```

---

## phases

### p1: Hook 検証関数の実装

**goal**: settings.json から Hook を抽出し、存在・実行権限を検証する関数を実装する

#### subtasks

- [ ] **p1.1**: start.sh に verify_hooks 関数が存在し、settings.json を解析している
  - executor: claudecode
  - validations:
    - technical: "grep -A30 'verify_hooks' .claude/skills/session-manager/handlers/start.sh で関数を確認"
    - consistency: "settings.json の hooks セクションの構造と整合していることを確認"
    - completeness: "PreToolUse, PostToolUse, SessionStart, UserPromptSubmit の全イベントを対象としていることを確認"

- [ ] **p1.2**: Hook のパス抽出ロジックが正しく動作する
  - executor: claudecode
  - validations:
    - technical: "settings.json から 'bash .claude/hooks/*.sh' パターンを jq で抽出できることを確認"
    - consistency: "抽出パスが実際の Hook ファイルパスと一致することを確認"
    - completeness: "全ての Hook タイプが抽出されることを確認"

- [ ] **p1.3**: ファイル存在チェックが実装されている
  - executor: claudecode
  - validations:
    - technical: "test -f によるファイル存在チェックが実装されていることを確認"
    - consistency: "抽出されたパスに対してチェックが実行されることを確認"
    - completeness: "存在しないファイルが検出された場合にエラーメッセージが生成されることを確認"

- [ ] **p1.4**: 実行権限チェックが実装されている
  - executor: claudecode
  - validations:
    - technical: "test -x による実行権限チェックが実装されていることを確認"
    - consistency: "ファイル存在後に実行権限チェックが行われることを確認"
    - completeness: "実行権限がないファイルが検出された場合にエラーメッセージが生成されることを確認"

**status**: pending
**max_iterations**: 5

---

### p2: 自動修復機能の実装

**goal**: 自動修復可能な問題（実行権限なし）を自動で修復する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: 実行権限がないファイルに chmod +x を自動適用する
  - executor: claudecode
  - validations:
    - technical: "chmod +x コマンドが条件付きで実行されることを確認"
    - consistency: "自動修復は実行権限の問題のみに限定されていることを確認"
    - completeness: "修復後に再度実行権限チェックが行われることを確認"

- [ ] **p2.2**: 自動修復時にログメッセージが出力される
  - executor: claudecode
  - validations:
    - technical: "修復メッセージに '[AUTO-FIX]' または同等の表示が含まれることを確認"
    - consistency: "修復対象ファイルパスがログに含まれることを確認"
    - completeness: "修復成功/失敗が明示されることを確認"

- [ ] **p2.3**: 自動修復不可能な問題（ファイル不存在）は警告のみ出力する
  - executor: claudecode
  - validations:
    - technical: "ファイル不存在の場合に修復を試みないことを確認"
    - consistency: "警告メッセージに '[WARN]' が含まれることを確認"
    - completeness: "問題のあるファイルパスと対応方法が表示されることを確認"

**status**: pending
**max_iterations**: 5

---

### p3: SessionStart への統合

**goal**: verify_hooks 関数を SessionStart フローに統合する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: start.sh の初期化フローで verify_hooks が呼び出される
  - executor: claudecode
  - validations:
    - technical: "start.sh で verify_hooks 関数が呼び出されることを確認"
    - consistency: "state.md 読み込み前または直後に実行されることを確認"
    - completeness: "エラーがあっても致命的エラーとせず、警告を出力して続行することを確認"

- [ ] **p3.2**: 検証結果がセッション開始メッセージに含まれる
  - executor: claudecode
  - validations:
    - technical: "Hook 検証結果がセッション開始の出力に含まれることを確認"
    - consistency: "問題なしの場合は簡潔なメッセージ、問題ありの場合は詳細表示となることを確認"
    - completeness: "全 Hook の検証結果がサマリーとして表示されることを確認"

- [ ] **p3.3**: 検証は settings.json が存在する場合のみ実行される
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/settings.json による存在チェックがあることを確認"
    - consistency: "settings.json がない場合はスキップされ、エラーにならないことを確認"
    - completeness: "スキップ時にログが出力されることを確認"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされていることを検証する

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: SessionStart で全 Hook の存在・実行権限が検証される
  - executor: claudecode
  - validations:
    - technical: "echo '{\"trigger\":\"startup\"}' | bash .claude/hooks/session.sh を実行し、Hook 検証が行われることを確認"
    - consistency: "settings.json に登録された全 Hook が対象であることを確認"
    - completeness: "PreToolUse, PostToolUse, SessionStart, UserPromptSubmit の全タイプが検証されることを確認"

- [ ] **p_final.2**: 問題検出時に警告メッセージが表示される
  - executor: claudecode
  - validations:
    - technical: "テスト用に実行権限を削除したファイルで検証し、警告が表示されることを確認"
    - consistency: "警告メッセージに問題のファイルパスが含まれることを確認"
    - completeness: "問題の種類（不存在/権限なし）が明示されることを確認"

- [ ] **p_final.3**: 自動修復可能な問題が自動修復される
  - executor: claudecode
  - validations:
    - technical: "chmod -x で実行権限を削除後、SessionStart を実行し、自動修復されることを確認"
    - consistency: "修復後に ls -la で実行権限が付与されていることを確認"
    - completeness: "修復ログが出力されることを確認"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
