# {Agent Name} SubAgent

> **{One-line description of the agent's responsibility}**

---

## Role

{Detailed description of this agent's role in the system.}

---

## Responsibilities

```yaml
primary:
  - {Main responsibility}
  - {Another key responsibility}

secondary:
  - {Supporting task}
  - {Additional capability}
```

---

## Input Contract

```yaml
required:
  - name: prompt
    type: string
    description: The task or question to process

optional:
  - name: context
    type: object
    description: Additional context for the task
```

---

## Output Format

```yaml
success:
  format: |
    ## Result
    {Structured output description}

    ## Evidence
    - {Supporting information}

    ## Recommendation
    {Next steps or guidance}

failure:
  format: |
    ## Error
    {Error description}

    ## Cause
    {Root cause analysis}

    ## Recovery
    {Suggested recovery steps}
```

---

## Decision Logic

```yaml
when:
  condition: {Condition description}
  action: {What the agent does}
  output: {Expected output}

when:
  condition: {Another condition}
  action: {Different action}
  output: {Different output}
```

---

## Constraints

```yaml
must:
  - {Required behavior}
  - {Mandatory action}

must_not:
  - {Prohibited action}
  - {Forbidden behavior}

should:
  - {Recommended behavior}
  - {Best practice}
```

---

## Tools Available

```yaml
allowed:
  - Read: {When to use}
  - Grep: {When to use}
  - Glob: {When to use}
  - Bash: {When to use, if allowed}

prohibited:
  - {Tools this agent should not use}
```

---

## Integration Points

| Component | Interaction |
|-----------|-------------|
| {Calling component} | {How it calls this agent} |
| {Downstream component} | {What this agent produces for it} |

---

## Error Handling

```yaml
recoverable:
  - error: {Error type}
    recovery: {How to recover}

fatal:
  - error: {Critical error type}
    action: {What to do - usually escalate to user}
```

---

## Examples

### Example 1: {Common Case}

**Input:**
```
{Example prompt}
```

**Output:**
```
{Expected response}
```

### Example 2: {Edge Case}

**Input:**
```
{Edge case prompt}
```

**Output:**
```
{How agent handles it}
```
