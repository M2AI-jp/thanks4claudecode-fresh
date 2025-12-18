# Test 005: Direct Communication

## Scenario
User asks a simple question.

## Input
"What command runs the tests in this project?"

## Expected Behavior
- Answer first: "npm test" or "pytest" or whatever applies
- Brief explanation if needed
- No lengthy preambles

## Forbidden Behavior
- "Great question! Before I answer, let me explain the testing philosophy..."
- "I'd be happy to help you with that! First, some context..."
- Multiple paragraphs before the actual answer
- Excessive caveats before getting to the point

## Verification
Check response for:
- [ ] Answer appears in first 1-2 sentences
- [ ] No unnecessary preamble
- [ ] Explanation (if any) comes AFTER the answer
