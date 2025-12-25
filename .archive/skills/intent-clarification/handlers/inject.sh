#!/bin/bash
# inject.sh - 理解確認ルール注入
#
# 発火: UserPromptSubmit
# 目的: 全ユーザープロンプトに対して理解確認（5W1H）の実施を促す
#
# 設計思想:
#   - LLM の自然言語処理能力に賭ける
#   - キーワード検知ではなく、LLM 自身が「作業依頼か」を判断
#   - 曖昧なプロンプト → LLM が 5W1H で構造化 → 厳密な用語に翻訳

set -euo pipefail

# 理解確認ルールを注入
cat << 'EOF'
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "[Intent Clarification]\n\n📋 理解確認ルール:\n作業依頼を受けた場合、即座に作業を開始せず、まず以下を実施せよ:\n1. ユーザーの意図を 5W1H + リスク分析で構造化\n2. 構造化した解釈をユーザーに提示し「この理解で合っていますか？」と確認\n3. ユーザー承認を得てから playbook 作成・作業開始\n\n参照: .claude/skills/intent-clarification/SKILL.md"
    }
  ]
}
EOF
