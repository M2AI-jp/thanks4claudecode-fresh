# playbook-architecture-visualizer.md

> **ARCHITECTURE.md（4QV+ 導火線モデル）をインタラクティブに視覚化する HTML/CSS/JS ウェブサイトを作成する**

---

## meta

```yaml
project: architecture-visualizer
branch: feat/architecture-visualizer
created: 2025-12-25
issue: null
reviewed: true
```

---

## goal

```yaml
summary: ARCHITECTURE.md（4QV+ 導火線モデル）を視覚化したインタラクティブな HTML/CSS/JS ウェブサイトを作成する
done_when:
  - tmp/sample-website/index.html が存在し、ローカルサーバーで閲覧可能である
  - SessionStart から PostToolUse までの主要フローがタイムライン形式で視覚化されている
  - フロー遷移アニメーションが動作する
  - 各コンポーネントクリックで詳細ポップアップが表示される
```

---

## context

> **ARCHITECTURE.md から抽出した視覚化対象の情報**

### 4QV+ 導火線モデル

```
Hook（トリガー）→ Skill（パッケージ）→ SubAgent（専門検証）
```

### 主要 Hook イベント（タイムライン表示対象）

| 順序 | イベント | 説明 |
|------|----------|------|
| 1 | SessionStart | セッション開始/再開時（startup/resume/clear/compact） |
| 2 | UserPromptSubmit | ユーザープロンプト送信時（Claude 処理前） |
| 3 | PreToolUse | ツール実行前（パラメータ作成後、実行前） |
| 4 | PostToolUse | ツール正常完了直後 |
| 5 | SubagentStop | サブエージェント応答完了時 |
| 6 | Stop | メイン Claude エージェント応答完了時 |

### 各イベントの詳細（ポップアップ表示用）

#### SessionStart
- Hook: `.claude/hooks/session.sh`
- 処理: state.md 読み込み、タイムスタンプ更新、DRIFT チェック
- 書き込み: state.md（session.last_start）

#### UserPromptSubmit
- Hook: `.claude/hooks/prompt.sh`
- 処理: playbook=null 検出時に playbook-init 案内
- タスク依頼パターン検出 → pm SubAgent チェーン

#### PreToolUse
- Hook: `.claude/hooks/pre-tool.sh`
- Guards:
  - protected-edit.sh（保護ファイル）
  - playbook-guard.sh（playbook 必須）
  - subtask-guard.sh（3点検証）
  - main-branch.sh（main ブランチブロック）

#### PostToolUse
- Hook: `.claude/hooks/post-tool.sh`
- 処理: 全 Phase done 検出 → archive-playbook.sh（自動実行）

### SubAgent 一覧（ポップアップ表示用）

| SubAgent | 役割 | 許可ツール |
|----------|------|-----------|
| pm | playbook 作成 | Read, Write, Edit, Grep, Glob, Bash |
| reviewer | playbook 検証 | Read, Grep, Glob, Bash |
| critic | done_criteria 検証 | Read, Grep, Bash |
| health-checker | 健全性チェック | Read, Grep, Glob, Bash |

### SSOT 信頼度階層

```
1. state.md          ← 最優先（現在状態）
2. playbook          ← タスク定義・進捗
3. チャット履歴      ← コンテキストリセットで消失
```

---

## phases

### p1: HTML 構造作成

**goal**: ウェブサイトの基本 HTML 構造を作成する

#### subtasks

- [x] **p1.1**: tmp/sample-website/index.html が存在し、基本的な HTML5 構造を含む
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/sample-website/index.html でファイル存在を確認"
    - consistency: "HTML5 の doctype、head、body が正しく構成されている"
    - completeness: "タイムライン表示用の div 要素、ポップアップ用のモーダル要素が含まれている"

**status**: done
**max_iterations**: 5

---

### p2: CSS スタイリング

**goal**: タイムライン形式のレイアウトとアニメーションを CSS で実装する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: tmp/sample-website/style.css が存在し、タイムラインのスタイルが定義されている
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/sample-website/style.css でファイル存在を確認"
    - consistency: "index.html から link タグで正しく参照されている"
    - completeness: "タイムライン、ノード、接続線、アニメーション、ポップアップのスタイルが含まれている"

**status**: done
**max_iterations**: 5

---

### p3: JavaScript インタラクション

**goal**: フロー遷移アニメーションとポップアップ機能を JS で実装する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: tmp/sample-website/script.js が存在し、インタラクション機能が実装されている
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/sample-website/script.js でファイル存在を確認"
    - consistency: "index.html から script タグで正しく参照されている"
    - completeness: "フロー遷移アニメーション関数、クリックイベントハンドラー、ポップアップ表示/非表示機能が含まれている"

- [x] **p3.2**: 「Start Animation」ボタンクリックでフローアニメーションが順次実行される
  - executor: claudecode
  - validations:
    - technical: "ブラウザで index.html を開き、ボタンクリックでアニメーションが動作することを確認"
    - consistency: "アニメーションの順序が ARCHITECTURE.md のイベント順（SessionStart → UserPromptSubmit → PreToolUse → PostToolUse）と一致"
    - completeness: "各ノードが順次ハイライトされ、接続線がアニメーションする"

- [x] **p3.3**: 各コンポーネントクリックで詳細ポップアップが表示される
  - executor: claudecode
  - validations:
    - technical: "ブラウザで各ノードをクリックし、ポップアップが表示されることを確認"
    - consistency: "ポップアップ内容が ARCHITECTURE.md の該当セクションと一致"
    - completeness: "全ての主要コンポーネント（SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, SubAgents）にポップアップが設定されている"

**status**: done
**max_iterations**: 5

---

### p4: 動作確認

**goal**: ローカルサーバーで動作確認を行う

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: python -m http.server で tmp/sample-website/ を配信し、localhost で閲覧可能である
  - executor: user
  - validations:
    - technical: "cd tmp/sample-website && python -m http.server 8080 を実行し、http://localhost:8080 にアクセスできることを確認"
    - consistency: "表示されるコンテンツが index.html の内容と一致"
    - completeness: "CSS と JS が正しく読み込まれ、スタイルとインタラクションが動作する"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: tmp/sample-website/index.html が存在し、ローカルサーバーで閲覧可能である
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/sample-website/index.html && test -f tmp/sample-website/style.css && test -f tmp/sample-website/script.js で全ファイル存在を確認"
    - consistency: "3つのファイルが正しく連携している"
    - completeness: "HTML から CSS と JS が参照され、単体で動作可能な状態"

- [x] **p_final.2**: SessionStart から PostToolUse までの主要フローがタイムライン形式で視覚化されている
  - executor: claudecode
  - validations:
    - technical: "index.html を開き、縦方向のタイムラインが表示されることを確認"
    - consistency: "タイムラインの順序が ARCHITECTURE.md と一致（SessionStart → UserPromptSubmit → PreToolUse → PostToolUse）"
    - completeness: "各イベントがノードとして表示され、接続線で繋がっている"

- [x] **p_final.3**: フロー遷移アニメーションが動作する
  - executor: claudecode
  - validations:
    - technical: "ブラウザで「Start Animation」ボタンをクリックし、アニメーションが実行されることを確認"
    - consistency: "アニメーションの順序が正しい"
    - completeness: "全ノードが順次ハイライトされる"

- [x] **p_final.4**: 各コンポーネントクリックで詳細ポップアップが表示される
  - executor: claudecode
  - validations:
    - technical: "各ノードをクリックし、ポップアップが表示されることを確認"
    - consistency: "ポップアップ内容が ARCHITECTURE.md と整合"
    - completeness: "全主要コンポーネントにポップアップが設定されている"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' ! -path 'tmp/sample-website/*' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-25 | 初版作成 |
