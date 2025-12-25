/**
 * 4QV+ Architecture Visualizer
 * Interactive visualization of the Hook → Skill → SubAgent chain
 */

// Component data for modals
const componentData = {
  // SSOT Components
  'state-md': {
    title: 'state.md - Single Source of Truth',
    body: `
      <h4>役割</h4>
      <p>現在状態の真実源。セッション開始時に必ず読み込まれます。</p>

      <h4>構造</h4>
      <div class="code-block">
playbook:
  active: {path}          # 現在の playbook
  branch: {branch}        # 作業ブランチ
  last_archived: {path}   # 最後にアーカイブした playbook

goal:
  milestone: {id}         # 現在のマイルストーン
  phase: {id}            # 現在の Phase
  done_criteria: []      # 完了条件

session:
  last_start: {timestamp}
  last_end: {timestamp}
      </div>

      <h4>信頼度</h4>
      <p>最優先。コンテキストリセット後も状態を保持します。</p>
    `
  },

  'playbook': {
    title: 'playbook - タスク定義',
    body: `
      <h4>役割</h4>
      <p>タスク定義と進捗管理。Phaseごとにsubtasksと検証条件を持ちます。</p>

      <h4>保存場所</h4>
      <p><code>plan/playbook-*.md</code></p>

      <h4>主要セクション</h4>
      <ul>
        <li><strong>meta</strong>: プロジェクト名、ブランチ、reviewed状態</li>
        <li><strong>goal</strong>: 完了条件（done_when）</li>
        <li><strong>context</strong>: 背景情報</li>
        <li><strong>phases</strong>: 作業フェーズとsubtasks</li>
      </ul>

      <h4>検証</h4>
      <p>reviewer SubAgentがレビューし、<code>reviewed: true</code>になるまで作業開始不可。</p>
    `
  },

  'chat-history': {
    title: 'チャット履歴',
    body: `
      <h4>役割</h4>
      <p>会話の文脈情報を保持。</p>

      <h4>注意点</h4>
      <p>コンテキストリセット（/clear、/compact）で消失します。</p>
      <p>そのため、重要な状態は<code>state.md</code>と<code>playbook</code>に永続化する必要があります。</p>

      <h4>信頼度</h4>
      <p>最低。state.mdやplaybookと矛盾する場合は無視されます。</p>
    `
  },

  // Timeline Events
  'session-start': {
    title: 'SessionStart',
    body: `
      <h4>発火タイミング</h4>
      <ul>
        <li><code>startup</code>: 新規セッション開始</li>
        <li><code>resume</code>: 既存セッション再開</li>
        <li><code>clear</code>: /clear コマンド後</li>
        <li><code>compact</code>: コンパクト後の再開</li>
      </ul>

      <h4>Hook ファイル</h4>
      <p><code>.claude/hooks/session.sh</code></p>

      <h4>処理内容</h4>
      <ul>
        <li>state.md 読み込み</li>
        <li>タイムスタンプ更新（session.last_start）</li>
        <li>DRIFT チェック実行</li>
      </ul>
    `
  },

  'user-prompt-submit': {
    title: 'UserPromptSubmit',
    body: `
      <h4>発火タイミング</h4>
      <p>ユーザーがプロンプトを送信した時（Claude処理前）</p>

      <h4>Hook ファイル</h4>
      <p><code>.claude/hooks/prompt.sh</code></p>

      <h4>処理内容</h4>
      <ul>
        <li>State Injection（コンテキスト付加）</li>
        <li>playbook=null検出時 → playbook-init案内</li>
        <li>タスク依頼パターン検出 → Golden Path発動</li>
      </ul>

      <h4>タスク依頼パターン</h4>
      <p>「作って」「実装して」「修正して」「追加して」等を検出</p>
    `
  },

  'pre-tool-use': {
    title: 'PreToolUse',
    body: `
      <h4>発火タイミング</h4>
      <p>ツール実行前（パラメータ作成後、実行前）</p>

      <h4>Hook ファイル</h4>
      <p><code>.claude/hooks/pre-tool.sh</code></p>

      <h4>主要ガード</h4>
      <ul>
        <li><strong>protected-edit.sh</strong>: 保護ファイルブロック</li>
        <li><strong>playbook-guard.sh</strong>: playbook必須チェック</li>
        <li><strong>subtask-guard.sh</strong>: 3点検証確認</li>
        <li><strong>main-branch.sh</strong>: mainブランチ作業ブロック</li>
        <li><strong>critic-guard.sh</strong>: done変更前チェック</li>
      </ul>

      <h4>Exit Code</h4>
      <ul>
        <li><code>0</code>: 続行許可</li>
        <li><code>2</code>: ブロック</li>
      </ul>
    `
  },

  'post-tool-use': {
    title: 'PostToolUse',
    body: `
      <h4>発火タイミング</h4>
      <p>ツール正常完了直後</p>

      <h4>Hook ファイル</h4>
      <p><code>.claude/hooks/post-tool.sh</code></p>

      <h4>処理内容</h4>
      <ul>
        <li>全Phase done検出 → archive-playbook.sh自動実行</li>
        <li>tmp/クリーンアップ</li>
      </ul>

      <h4>archive-playbook.sh 自動実行フロー</h4>
      <ol>
        <li>未コミット変更を自動コミット</li>
        <li>Push（PR作成前に必須）</li>
        <li>PR作成</li>
        <li>playbookアーカイブ（plan/archive/へ移動）</li>
        <li>state.md更新</li>
        <li>PRマージ</li>
        <li>main同期</li>
      </ol>
    `
  },

  'subagent-stop': {
    title: 'SubagentStop',
    body: `
      <h4>発火タイミング</h4>
      <p>サブエージェント（Task）応答完了時</p>

      <h4>Hook ファイル</h4>
      <p><code>.claude/hooks/subagent-stop.sh</code></p>

      <h4>処理内容</h4>
      <ul>
        <li>ログ記録</li>
        <li>リソースクリーンアップ</li>
        <li>残存タスク確認</li>
      </ul>

      <h4>SubAgent残存防止</h4>
      <p>run_in_background=trueは必要な場合のみ使用し、TaskOutputで結果を回収します。</p>
    `
  },

  'stop': {
    title: 'Stop',
    body: `
      <h4>発火タイミング</h4>
      <p>メインClaudeエージェント応答完了時</p>

      <h4>処理内容</h4>
      <ul>
        <li>セッション終了処理</li>
        <li>状態永続化確認</li>
      </ul>
    `
  },

  // SubAgents
  'pm': {
    title: 'pm SubAgent',
    body: `
      <h4>役割</h4>
      <p>playbook作成のエントリーポイント</p>

      <h4>許可ツール</h4>
      <p><code>Read</code>, <code>Write</code>, <code>Edit</code>, <code>Grep</code>, <code>Glob</code>, <code>Bash</code></p>

      <h4>参照ファイル</h4>
      <ul>
        <li>plan/template/playbook-format.md（テンプレート）</li>
        <li>docs/criterion-validation-rules.md（禁止パターン）</li>
        <li>.claude/skills/understanding-check/SKILL.md</li>
      </ul>

      <h4>処理フロー</h4>
      <ol>
        <li>understanding-check（5W1H分析）</li>
        <li>playbook作成</li>
        <li>reviewer呼び出し</li>
        <li>state.md更新</li>
      </ol>
    `
  },

  'reviewer': {
    title: 'reviewer SubAgent',
    body: `
      <h4>役割</h4>
      <p>playbook検証（PASS/FAIL判定）</p>

      <h4>許可ツール</h4>
      <p><code>Read</code>, <code>Grep</code>, <code>Glob</code>, <code>Bash</code></p>
      <p><strong>※ 書き込み権限なし</strong></p>

      <h4>参照ファイル</h4>
      <ul>
        <li>.claude/frameworks/playbook-review-criteria.md</li>
        <li>.claude/frameworks/playbook-reviewer-spec.md</li>
      </ul>

      <h4>検証結果</h4>
      <ul>
        <li>PASS → playbook.reviewed = true</li>
        <li>FAIL → pmに差し戻し（最大3回）</li>
      </ul>
    `
  },

  'critic': {
    title: 'critic SubAgent',
    body: `
      <h4>役割</h4>
      <p>done_criteria検証（報酬詐欺防止）</p>

      <h4>許可ツール</h4>
      <p><code>Read</code>, <code>Grep</code>, <code>Bash</code></p>
      <p><strong>※ 書き込み権限なし → 自己完了防止</strong></p>

      <h4>参照ファイル</h4>
      <ul>
        <li>.claude/frameworks/done-criteria-validation.md</li>
        <li>docs/criterion-validation-rules.md</li>
      </ul>

      <h4>出力</h4>
      <p>CRITIQUE結果（PASS/FAIL + 実行可能な証拠）</p>
    `
  },

  'health-checker': {
    title: 'health-checker SubAgent',
    body: `
      <h4>役割</h4>
      <p>システム状態の健全性チェック</p>

      <h4>許可ツール</h4>
      <p><code>Read</code>, <code>Grep</code>, <code>Glob</code>, <code>Bash</code></p>

      <h4>チェック項目</h4>
      <ul>
        <li>state.md整合性</li>
        <li>playbook存在確認</li>
        <li>DRIFT検出（repository-map.yamlとの差分）</li>
      </ul>
    `
  },

  // Guards
  'protected-edit': {
    title: 'protected-edit.sh',
    body: `
      <h4>役割</h4>
      <p>保護ファイルへの編集をブロック</p>

      <h4>保護対象</h4>
      <p><code>.claude/protected-files.txt</code>に記載されたファイル</p>

      <h4>ハードブロック</h4>
      <ul>
        <li>CLAUDE.md</li>
        <li>その他保護指定ファイル</li>
      </ul>
    `
  },

  'playbook-guard': {
    title: 'playbook-guard.sh',
    body: `
      <h4>役割</h4>
      <p>playbook必須チェック</p>

      <h4>ブロック条件</h4>
      <ul>
        <li>playbook.active == null → BLOCK + playbook-init案内</li>
        <li>reviewed == false → BLOCK + reviewer必須案内</li>
      </ul>

      <h4>バイパス</h4>
      <p>なし（adminモードでも無効）</p>
    `
  },

  'subtask-guard': {
    title: 'subtask-guard.sh',
    body: `
      <h4>役割</h4>
      <p>subtask完了時の3点検証確認</p>

      <h4>検証項目</h4>
      <ul>
        <li><strong>technical</strong>: 技術的な検証</li>
        <li><strong>consistency</strong>: 整合性確認</li>
        <li><strong>completeness</strong>: 完全性確認</li>
      </ul>

      <h4>ブロック条件</h4>
      <p>[ ] → [x] 変更時に3点検証が未確認</p>
    `
  },

  'main-branch': {
    title: 'main-branch.sh',
    body: `
      <h4>役割</h4>
      <p>mainブランチでの作業をブロック</p>

      <h4>ブロック対象</h4>
      <p>main/masterブランチでのEdit/Write</p>

      <h4>例外</h4>
      <p>なし。必ず作業ブランチを切る必要があります。</p>
    `
  },

  // Flow Chain
  'hook': {
    title: 'Hook（トリガー）',
    body: `
      <h4>役割</h4>
      <p>イベント発火時の最初のトリガー</p>

      <h4>主要イベント</h4>
      <ul>
        <li>SessionStart</li>
        <li>UserPromptSubmit</li>
        <li>PreToolUse</li>
        <li>PostToolUse</li>
        <li>SubagentStop</li>
        <li>Stop</li>
      </ul>

      <h4>設定ファイル</h4>
      <p><code>.claude/settings.json</code></p>
    `
  },

  'skill': {
    title: 'Skill（パッケージ）',
    body: `
      <h4>役割</h4>
      <p>ユースケースパッケージ。Hookから呼び出される。</p>

      <h4>主要Skills</h4>
      <ul>
        <li><strong>session-manager</strong>: セッション管理</li>
        <li><strong>access-control</strong>: アクセス制御</li>
        <li><strong>playbook-gate</strong>: playbook強制</li>
        <li><strong>reward-guard</strong>: 報酬詐欺防止</li>
        <li><strong>quality-assurance</strong>: 品質保証</li>
        <li><strong>golden-path</strong>: タスク開始フロー</li>
      </ul>

      <h4>格納場所</h4>
      <p><code>.claude/skills/*/</code></p>
    `
  },

  'subagent': {
    title: 'SubAgent（専門検証）',
    body: `
      <h4>役割</h4>
      <p>専門的な検証を行う独立エージェント</p>

      <h4>主要SubAgents</h4>
      <ul>
        <li><strong>pm</strong>: playbook作成</li>
        <li><strong>reviewer</strong>: playbook検証</li>
        <li><strong>critic</strong>: done_criteria検証</li>
        <li><strong>health-checker</strong>: 健全性チェック</li>
      </ul>

      <h4>設計原則</h4>
      <ul>
        <li>検証系は書き込み権限なし</li>
        <li>作成系は必要最小限の権限</li>
      </ul>
    `
  }
};

// DOM Elements
const modal = document.getElementById('modal');
const modalTitle = document.getElementById('modalTitle');
const modalBody = document.getElementById('modalBody');
const modalClose = document.getElementById('modalClose');
const startAnimationBtn = document.getElementById('startAnimation');
const resetAnimationBtn = document.getElementById('resetAnimation');

// Animation state
let isAnimating = false;
let animationTimeouts = [];

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  initEventListeners();
});

function initEventListeners() {
  // SSOT items
  document.querySelectorAll('.ssot-item').forEach(item => {
    item.addEventListener('click', () => {
      const component = item.dataset.component;
      showModal(component);
    });
  });

  // Timeline items
  document.querySelectorAll('.timeline-item').forEach(item => {
    item.addEventListener('click', () => {
      const event = item.dataset.event;
      showModal(event);
    });
  });

  // SubAgent cards
  document.querySelectorAll('.subagent-card').forEach(card => {
    card.addEventListener('click', () => {
      const subagent = card.dataset.subagent;
      showModal(subagent);
    });
  });

  // Guards
  document.querySelectorAll('.guard').forEach(guard => {
    guard.addEventListener('click', (e) => {
      e.stopPropagation();
      const guardName = guard.dataset.guard;
      showModal(guardName);
    });
  });

  // Flow items
  document.querySelectorAll('.flow-item').forEach(item => {
    item.addEventListener('click', () => {
      const flow = item.dataset.flow;
      showModal(flow);
    });
  });

  // Modal close
  modalClose.addEventListener('click', hideModal);
  modal.addEventListener('click', (e) => {
    if (e.target === modal) hideModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') hideModal();
  });

  // Animation buttons
  startAnimationBtn.addEventListener('click', startAnimation);
  resetAnimationBtn.addEventListener('click', resetAnimation);
}

function showModal(componentId) {
  const data = componentData[componentId];
  if (!data) return;

  modalTitle.textContent = data.title;
  modalBody.innerHTML = data.body;
  modal.classList.add('show');
}

function hideModal() {
  modal.classList.remove('show');
}

function startAnimation() {
  if (isAnimating) return;
  isAnimating = true;

  // Reset first
  resetAnimation(false);

  const timelineItems = document.querySelectorAll('.timeline-item');
  const flowItems = document.querySelectorAll('.flow-item');
  const subagentCards = document.querySelectorAll('.subagent-card');

  // Animate timeline items sequentially
  timelineItems.forEach((item, index) => {
    const timeout = setTimeout(() => {
      // Remove highlight from previous
      if (index > 0) {
        timelineItems[index - 1].classList.remove('highlighted');
        timelineItems[index - 1].classList.add('active');
      }

      // Add highlight to current
      item.classList.add('highlighted');

      // Animate corresponding flow item at certain points
      if (index === 0) {
        // Hook
        flowItems[0].classList.add('highlighted');
      } else if (index === 1) {
        // Skill
        flowItems[0].classList.remove('highlighted');
        flowItems[0].classList.add('active');
        flowItems[1].classList.add('highlighted');
      } else if (index === 4) {
        // SubAgent
        flowItems[1].classList.remove('highlighted');
        flowItems[1].classList.add('active');
        flowItems[2].classList.add('highlighted');

        // Also highlight SubAgent cards
        subagentCards.forEach((card, cardIndex) => {
          const cardTimeout = setTimeout(() => {
            card.classList.add('highlighted');
          }, cardIndex * 200);
          animationTimeouts.push(cardTimeout);
        });
      }

    }, index * 1500);

    animationTimeouts.push(timeout);
  });

  // Final cleanup
  const finalTimeout = setTimeout(() => {
    timelineItems[timelineItems.length - 1].classList.remove('highlighted');
    timelineItems[timelineItems.length - 1].classList.add('active');
    flowItems[2].classList.remove('highlighted');
    flowItems[2].classList.add('active');
    isAnimating = false;
  }, timelineItems.length * 1500);

  animationTimeouts.push(finalTimeout);
}

function resetAnimation(updateState = true) {
  // Clear all timeouts
  animationTimeouts.forEach(clearTimeout);
  animationTimeouts = [];

  // Reset all elements
  document.querySelectorAll('.timeline-item').forEach(item => {
    item.classList.remove('active', 'highlighted');
  });

  document.querySelectorAll('.flow-item').forEach(item => {
    item.classList.remove('active', 'highlighted');
  });

  document.querySelectorAll('.subagent-card').forEach(card => {
    card.classList.remove('highlighted');
  });

  if (updateState) {
    isAnimating = false;
  }
}
