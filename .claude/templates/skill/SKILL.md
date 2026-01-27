# {Skill Name} Skill

> **{Short description of the skill's purpose}**

---

## Purpose

{Detailed description of what this skill does and why it exists.}

---

## When to Use

```yaml
triggers:
  - {Condition or event that triggers this skill}
  - {Another trigger condition}

invocation:
  - Skill(skill='{skill-name}')
  - Skill(skill='{skill-name}', args='{arguments}')
  - /{skill-name}

prerequisites:
  - {Required state or conditions}
  - {Dependencies}
```

---

## Input

```yaml
required:
  - name: {input_name}
    type: {string|number|boolean|object}
    description: {What this input represents}

optional:
  - name: {optional_input}
    type: {type}
    default: {default_value}
    description: {Description}
```

---

## Output

```yaml
success:
  type: {output_type}
  format: |
    {Example output format}

failure:
  type: error
  format: |
    {Error message format}
```

---

## Required Action

**{Brief summary of what must happen when this skill is invoked.}**

### Step 1: {First Step Name}

{Description of what to do in step 1.}

```yaml
actions:
  - {Specific action}
  - {Another action}

validation:
  - {How to verify this step completed}
```

### Step 2: {Second Step Name}

{Description of step 2.}

### Step 3: {Third Step Name}

{Description of step 3.}

---

## Prohibited

```yaml
never:
  - {Action that is explicitly forbidden}
  - {Another prohibited action}

required:
  - {Action that must always happen}
  - {Mandatory behavior}
```

---

## Examples

### Example 1: {Simple Case}

```
Input: {example input}
Output: {expected output}
```

### Example 2: {Complex Case}

```
Input: {example input with options}
Output: {expected output}
```

---

## Related Files

| File | Role |
|------|------|
| {path/to/related/file} | {What this file does} |
| {another/file} | {Its role} |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | {YYYY-MM-DD} | Initial version |
