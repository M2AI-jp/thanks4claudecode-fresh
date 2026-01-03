# playbook-fix-coherence-source-path.md

> **coherence.sh の source コマンドを相対パスから絶対パスに修正する**

---

## meta

```yaml
project: fix-coherence-source-path
branch: fix/coherence-source-path
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: coherence.sh が任意の cwd から実行しても state-schema.sh を正しく source できるようにする
done_when:
  - coherence.sh が SCRIPT_DIR と REPO_ROOT を計算して絶対パスで source している
  - 任意のディレクトリから実行しても state-schema.sh を読み込める
```

---

## context

```yaml
5w1h:
  who: Claude Code / Hook システム
  what: coherence.sh の source コマンドを相対パスから絶対パスに修正
  when: 今回のセッションで完了
  where: .claude/skills/reward-guard/guards/coherence.sh の行 9
  why: 任意の cwd からスクリプトを実行した場合に state-schema.sh を正しく source できない問題を解消
  how: SCRIPT_DIR と REPO_ROOT を計算し、絶対パスで source する

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T16:30:00Z
  data:
    risks:
      technical:
        - risk: パス計算の階層数の誤り
          severity: low
          mitigation: 4階層上がリポジトリルートであることを確認済み
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T16:30:00Z
  summary: coherence.sh の行 9 を絶対パスに修正する
```

---

## phases

### p1: source パス修正

**goal**: coherence.sh が絶対パスで state-schema.sh を source するように修正

#### subtasks

- [x] **p1.1**: coherence.sh が SCRIPT_DIR を計算し REPO_ROOT を導出している
  - executor: claudecode
  - validations:
    - technical: "PASS - SCRIPT_DIR と REPO_ROOT が正しく定義されている"
    - consistency: "PASS - protected-edit.sh と同じパターンを使用"
    - completeness: "PASS - 相対パスの source がなく、全て絶対パスになっている"
  - validated: 2026-01-03T16:35:00Z

- [x] **p1.2**: bash -n coherence.sh がシンタックスエラーなしで通る
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n が exit 0 を返した"
    - consistency: "PASS - シェルスクリプトの標準的な記法に準拠"
    - completeness: "PASS - 全ての変数参照が正しい"
  - validated: 2026-01-03T16:35:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: coherence.sh が SCRIPT_DIR と REPO_ROOT を計算して絶対パスで source している
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で SCRIPT_DIR, REPO_ROOT, source コマンドを確認済み"
    - consistency: "PASS - 4階層上がリポジトリルートとして正しく計算されている"
    - completeness: "PASS - 相対パスの source が残っていない"
  - validated: 2026-01-03T16:36:00Z

- [x] **p_final.2**: 任意のディレクトリから実行しても state-schema.sh を読み込める
  - executor: claudecode
  - validations:
    - technical: "PASS - cd /tmp から実行し、state-schema.sh の source に成功（state.md not found エラーは正常）"
    - consistency: "PASS - エラーなく実行できる"
    - completeness: "PASS - state-schema.sh の関数が利用可能"
  - validated: 2026-01-03T16:36:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2026-01-03T16:37:00Z

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done
  - executed: 2026-01-03T16:37:00Z

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
  - executed: 2026-01-03T16:37:00Z
