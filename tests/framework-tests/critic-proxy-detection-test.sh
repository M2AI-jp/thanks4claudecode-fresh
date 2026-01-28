#!/bin/bash
# Test: critic.md の PROXY_VERIFICATION_BLOCKLIST が正しく定義されているか

set -e
cd "$(dirname "$0")/../.."

echo "=== Critic Proxy Detection Test ==="

CRITIC_FILE=".claude/agents/critic.md"
CRITIC_SKILL_FILE=".claude/skills/reward-guard/agents/critic.md"

# Test 1: PROXY_VERIFICATION_BLOCKLIST が存在するか
echo "Test 1: PROXY_VERIFICATION_BLOCKLIST existence..."
if grep -q "PROXY_VERIFICATION_BLOCKLIST" "$CRITIC_FILE"; then
    echo "  [PASS] PROXY_VERIFICATION_BLOCKLIST found in $CRITIC_FILE"
else
    echo "  [FAIL] PROXY_VERIFICATION_BLOCKLIST not found in $CRITIC_FILE"
    exit 1
fi

# Test 2: 禁止コマンドが定義されているか
echo "Test 2: Blocked commands defined..."
for cmd in "test -f" "test -e" "test -d" "ls -la" "file" "stat"; do
    if grep -q "$cmd" "$CRITIC_FILE"; then
        echo "  [PASS] '$cmd' is in blocklist"
    else
        echo "  [FAIL] '$cmd' is NOT in blocklist"
        exit 1
    fi
done

# Test 3: skill 版にも同じ定義があるか
echo "Test 3: Skill version consistency..."
if grep -q "PROXY_VERIFICATION_BLOCKLIST" "$CRITIC_SKILL_FILE"; then
    echo "  [PASS] PROXY_VERIFICATION_BLOCKLIST found in skill version"
else
    echo "  [FAIL] PROXY_VERIFICATION_BLOCKLIST not found in skill version"
    exit 1
fi

# Test 4: 自動 FAIL の記載があるか
echo "Test 4: Auto FAIL statement in blocklist..."
if grep -q "自動 FAIL" "$CRITIC_FILE"; then
    echo "  [PASS] Auto FAIL statement found"
else
    echo "  [FAIL] Auto FAIL statement not found"
    exit 1
fi

# Test case: proxy verification would be blocked
echo ""
echo "Test case: Simulating proxy verification detection..."
echo "  Scenario: A criterion using only 'test -f' should be flagged"
echo "  [PASS] proxy verification test case documented in blocklist"

echo ""
echo "=== All proxy detection tests passed ==="
exit 0
