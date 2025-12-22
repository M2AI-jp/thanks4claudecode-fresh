#!/usr/bin/env python3
"""
session_start.py - Session start hook for Claude Code

Reads state.md, parses YAML frontmatter with regex, and outputs
a systemMessage in Claude Code Hook JSON format.
"""

import json
import re
import sys
from pathlib import Path


def extract_yaml_from_section(content: str, section_name: str) -> dict:
    """
    Extract YAML key-value pairs from a markdown section.
    
    Looks for pattern:
    ## section_name
    ```yaml
    key: value
    ```
    """
    # Pattern to find section and its yaml code block
    pattern = rf'## {section_name}\s*\n+```yaml\n(.*?)```'
    match = re.search(pattern, content, re.DOTALL)
    
    if not match:
        return {}
    
    yaml_content = match.group(1)
    result = {}
    
    # Parse simple key: value pairs
    for line in yaml_content.strip().split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        # Handle done_criteria specially (list items)
        if line.startswith('- '):
            continue
            
        # Simple key: value parsing
        if ':' in line:
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip()
            
            # Remove inline comments
            if '#' in value:
                value = value.split('#')[0].strip()
            
            # Handle null values
            if value.lower() == 'null' or value == '':
                value = None
            
            result[key] = value
    
    return result


def parse_state_md(state_path: str) -> dict:
    """Parse state.md and extract relevant information."""
    path = Path(state_path)
    
    if not path.exists():
        return {
            'error': f'state.md not found at {state_path}',
            'focus': {},
            'playbook': {},
            'goal': {}
        }
    
    content = path.read_text(encoding='utf-8')
    
    return {
        'focus': extract_yaml_from_section(content, 'focus'),
        'playbook': extract_yaml_from_section(content, 'playbook'),
        'goal': extract_yaml_from_section(content, 'goal')
    }


def build_message(state: dict) -> str:
    """Build the system message based on state."""
    lines = []
    
    focus = state.get('focus', {})
    playbook = state.get('playbook', {})
    goal = state.get('goal', {})
    
    # Error handling
    if 'error' in state:
        lines.append(f"[WARN] {state['error']}")
        return '\n'.join(lines)
    
    # Focus info
    focus_current = focus.get('current', 'unknown')
    lines.append(f"[Session Start] focus={focus_current}")
    
    # Goal info
    milestone = goal.get('milestone', 'unknown')
    phase = goal.get('phase', 'unknown')
    lines.append(f"  milestone={milestone}, phase={phase}")
    
    # Playbook status
    playbook_active = playbook.get('active')
    
    if playbook_active and playbook_active != 'null':
        lines.append(f"  playbook={playbook_active}")
        lines.append("")
        lines.append("Read state.md and playbook to continue.")
    else:
        lines.append("  playbook=null")
        lines.append("")
        lines.append("[WARN] No active playbook.")
        lines.append("  -> Create playbook before making changes.")
        lines.append("  -> Use Task(subagent_type='pm', prompt='...') to create one.")
    
    return '\n'.join(lines)


def main():
    """Main entry point."""
    # Read stdin (Claude Code Hook input)
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        input_data = {}
    
    # Get trigger type (startup, resume, clear, compact)
    trigger = input_data.get('trigger', 'startup')
    
    # Parse state.md (assume we're in repo root)
    state = parse_state_md('state.md')
    
    # Build message
    message = build_message(state)
    
    # Output in Claude Code Hook format
    output = {
        'continue': True,
        'systemMessage': message
    }
    
    print(json.dumps(output))


if __name__ == '__main__':
    main()
