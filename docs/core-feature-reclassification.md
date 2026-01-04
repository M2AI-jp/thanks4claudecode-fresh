# core-feature-reclassification.md

> SSOT: event unit architecture dependency mapping.
> Boundary = Hook event timing. One unit = Hook -> components -> skills/subagents -> docs.

---

## 0. Principles

- Event timing is the only boundary. Functional grouping is secondary.
- Each event unit is self-contained: validator/context/guardrail/telemetry/retry/snapshot + chain.
- Hooks are thin dispatchers. All logic lives inside event units.
- Docs exist only if referenced by an event unit or by the unit interface contract.

---

## 1. Event Unit Interface (target contract)

Each unit implements the same component set:

- `validator`: normalize and validate raw hook input
- `context-injector`: emit the minimum context for the unit
- `guardrail`: policy checks + hard block conditions
- `telemetry`: event-scoped logs (success/failure/perf)
- `retry`: backoff strategy for transient failures (optional)
- `snapshot`: pre-action state capture for recovery (optional)
- `chain`: invokes skills/subagents and orchestrates outputs

Target layout (not yet implemented):

```
.claude/events/
  <event-unit>/
    validator.sh
    context-injector.sh
    guardrail.sh
    telemetry.sh
    retry.sh          # optional
    snapshot.sh       # optional
    chain.sh
```

Event unit IDs (canonical):

- session-start
- user-prompt-submit
- pre-tool-edit
- pre-tool-bash
- post-tool-edit
- subagent-stop
- pre-compact
- stop
- session-end
- notification

---

## 2. Ideal Event Unit Map (design blueprint)

Format:
`event unit -> components -> chain -> required docs/templates -> outputs`

### session-start
- Components: validator, context-injector, telemetry, guardrail
- Chain: session-manager/start -> quality-assurance/health -> quality-assurance/integrity
- Docs: state.md, docs/repository-map.yaml, docs/ARCHITECTURE.md
- Outputs: session status + drift warnings + coherence warnings

### user-prompt-submit
- Components: validator, context-injector, telemetry, guardrail
- Chain: prompt-analyzer -> term-translator (if needed) -> understanding-check -> playbook-init -> pm -> reviewer
- Docs: plan/template/playbook-format.md, plan/template/planning-rules.md,
        docs/criterion-validation-rules.md, docs/ai-orchestration.md, docs/git-operations.md,
        docs/folder-management.md, docs/ARCHITECTURE.md, AGENTS.md
- Outputs: analysis summary, playbook draft, reviewer verdict

### pre-tool-edit
- Components: validator, guardrail, telemetry, snapshot
- Chain: session-manager/init-guard -> access-control/main-branch -> post-loop/pending-guard -> access-control/protected-edit
        -> playbook-gate/playbook-guard -> playbook-gate/depends-check -> playbook-gate/executor-guard
        -> reward-guard/critic-guard -> reward-guard/subtask-guard -> reward-guard/phase-status-guard
        -> reward-guard/scope-guard
- Docs: state.md, playbook.active, .claude/protected-files.txt, .claude/frameworks/done-criteria-validation.md
- Outputs: allow/block + guard reasons

### pre-tool-bash
- Components: validator, guardrail, telemetry, retry (network-aware)
- Chain: access-control/bash-check -> reward-guard/coherence -> quality-assurance/lint
- Docs: state.md, scripts/contract.sh
- Outputs: allow/block + guard reasons

### post-tool-edit
- Components: validator, telemetry
- Chain: playbook-gate/archive-playbook -> playbook-gate/cleanup -> git-workflow/create-pr-hook
- Docs: docs/archive-operation-rules.md, docs/folder-management.md, docs/repository-map.yaml
- Outputs: archive/cleanup/PR actions

### subagent-stop
- Components: telemetry, validator
- Chain: subagent-stop logger -> playbook-gate/archive-playbook (pseudo Edit)
- Docs: state.md
- Outputs: subagent log + playbook completion check

### pre-compact
- Components: context-injector, validator, telemetry, snapshot
- Chain: session-manager/compact
- Docs: state.md, playbook.active
- Outputs: additionalContext (minimal resume pointers)

### stop
- Components: telemetry, snapshot
- Chain: (none yet)
- Docs: state.md
- Outputs: end-of-response summary

### session-end
- Components: validator, telemetry, snapshot
- Chain: session-manager/end
- Docs: state.md
- Outputs: end-of-session health summary + warnings

### notification
- Components: telemetry
- Chain: (none yet)
- Docs: none
- Outputs: notification log

---

## 3. Current Implementation Map (as-is)

### session-start
- Dispatcher: `.claude/hooks/session.sh` (SessionStart)
- Unit chain: `.claude/events/session-start/chain.sh`
- Components (current):
  - validator: `session-manager/handlers/start.sh` (state schema load, hook validation)
  - context-injector: `session-manager/handlers/start.sh` (state/playbook pointers)
  - telemetry: `session-manager/handlers/start.sh` (stdout warnings)
- Missing: dedicated guardrail/telemetry units; auto health/integrity/coherence chain

### user-prompt-submit
- Dispatcher: `.claude/hooks/prompt.sh`
- Unit chain: `.claude/events/user-prompt-submit/chain.sh`
- Components (current):
  - context-injector: `prompt.sh` (state + progress injection)
  - validator: `prompt-analyzer` subagent (manual enforcement via marker)
- Missing: unit telemetry, explicit guardrail, unit-level validator script

### pre-tool-edit
- Dispatcher: `.claude/hooks/pre-tool.sh` (PreToolUse)
- Unit chain: `.claude/events/pre-tool-edit/chain.sh`
- Components (current):
  - validator: `session-manager/handlers/init-guard.sh`
  - guardrail: access-control + playbook-gate + reward-guard scripts
- Missing: telemetry, snapshot, event-scoped validator

### pre-tool-bash
- Dispatcher: `.claude/hooks/pre-tool.sh`
- Unit chain: `.claude/events/pre-tool-bash/chain.sh`
- Components (current):
  - validator: `access-control/guards/bash-check.sh` + `scripts/contract.sh`
  - guardrail: `reward-guard/guards/coherence.sh` + `quality-assurance/checkers/lint.sh`
- Missing: telemetry, retry

### post-tool-edit
- Dispatcher: `.claude/hooks/post-tool.sh`
- Unit chain: `.claude/events/post-tool-edit/chain.sh`
- Components (current):
  - chain: archive-playbook -> cleanup -> create-pr-hook
- Missing: unit validator/telemetry

### subagent-stop
- Dispatcher: `.claude/hooks/subagent-stop.sh`
- Unit chain: `.claude/events/subagent-stop/chain.sh`
- Components (current):
  - telemetry: `.claude/logs/subagent.log`
  - chain: archive-playbook (pseudo Edit)
- Missing: event-level validator/guardrail

### pre-compact
- Dispatcher: `.claude/events/pre-compact/chain.sh` (PreCompact hook)
- Components (current):
  - context-injector: additionalContext output only
- Missing: validator, telemetry, snapshot

### stop / session-end / notification
- Dispatcher: `.claude/settings.json` (Stop/SessionEnd/Notification → chain)
- Unit chains: `.claude/events/stop/chain.sh`, `.claude/events/session-end/chain.sh`, `.claude/events/notification/chain.sh`
- Components (current):
  - stop: no-op placeholder
  - session-end: `session-manager/handlers/end.sh`
  - notification: no-op placeholder
- Missing: unit-level validator/guardrail/telemetry/snapshot

---

## 4. Missing Components Map (new work assumed)

Target files (to be created):

- `.claude/events/session-start/{validator,context-injector,telemetry,guardrail,chain}.sh`
- `.claude/events/user-prompt-submit/{validator,context-injector,telemetry,guardrail,chain}.sh`
- `.claude/events/pre-tool-edit/{validator,guardrail,telemetry,snapshot,chain}.sh`
- `.claude/events/pre-tool-bash/{validator,guardrail,telemetry,retry,chain}.sh`
- `.claude/events/post-tool-edit/{validator,telemetry,chain}.sh`
- `.claude/events/subagent-stop/{validator,telemetry,chain}.sh`
- `.claude/events/pre-compact/{validator,context-injector,telemetry,snapshot,chain}.sh`
- `.claude/events/stop/{telemetry,snapshot,chain}.sh`
- `.claude/events/session-end/{validator,telemetry,snapshot,chain}.sh`
- `.claude/events/notification/{telemetry,chain}.sh`

Dispatcher updates (target):

- Hooks call event unit `chain.sh` instead of direct skill scripts.
- Unit components are invoked by `chain.sh` in fixed order:
  1. validator
  2. context-injector
  3. guardrail
  4. snapshot (if needed)
  5. chain (skills/subagents)
  6. telemetry (always)

---

## 5. Migration Plan (3)

1. Introduce `.claude/events/` layout with empty stubs for all units.
2. Move existing logic into unit components without behavior changes:
   - pre-tool guards -> pre-tool-edit/pre-tool-bash guardrail
   - prompt state injection -> user-prompt-submit context-injector
   - subagent-stop logging -> subagent-stop telemetry
3. Add telemetry format + log targets for all units.
4. Wire hooks to unit `chain.sh` dispatchers.
5. Add missing units: stop/session-end/notification.
6. Remove legacy direct calls once all hooks dispatch to event units.

---

## 6. Doc Retention Rule (1)

Allowed docs are only those referenced in this map plus core entry points:

- `CLAUDE.md`
- `AGENTS.md`
- `RUNBOOK.md`
- `README.md`
- `state.md`
- `docs/ARCHITECTURE.md`
- `docs/core-feature-reclassification.md`
- `docs/repository-health.md`
- `docs/repository-map.yaml`
- `docs/criterion-validation-rules.md`
- `docs/ai-orchestration.md`
- `docs/git-operations.md`
- `docs/folder-management.md`
- `docs/archive-operation-rules.md`
- `plan/template/playbook-format.md`
- `plan/template/planning-rules.md`
- `plan/template/playbook-examples.md`
- `governance/PROMPT_CHANGELOG.md`

Temporary exception: design artifacts referenced by state/playbook may remain
until the state is reset.

Everything else is non-core and should be removed or archived.
