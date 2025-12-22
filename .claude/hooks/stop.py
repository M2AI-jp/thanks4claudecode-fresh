#!/usr/bin/env python3
"""
stop.py - Session stop hook for Claude Code

Reads state.md, checks review_pending flag, and blocks session end
if review is still pending.
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
            # Handle boolean values
            elif value.lower() == 'true':
                value = True
            elif value.lower() == 'false':
                value = False
            
            result[key] = value
    
    return result


def parse_state_md(state_path: str) -> dict:
    """Parse state.md and extract relevant information."""
    path = Path(state_path)
    
    if not path.exists():
        return {
            'error': f'state.md not found at {state_path}',
            'playbook': {}
        }
    
    content = path.read_text(encoding='utf-8')
    
    return {
        'playbook': extract_yaml_from_section(content, 'playbook')
    }


def main():
    """Main entry point."""
    # Read stdin (Claude Code Hook input)
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        input_data = {}
    
    # Parse state.md (assume we're in repo root)
    state = parse_state_md('state.md')
    
    # Get review_pending flag (default to False if not found)
    playbook = state.get('playbook', {})
    review_pending = playbook.get('review_pending', False)
    
    # Block if review is pending
    if review_pending is True:
        output = {
            'continue': False,
            'decision': 'block',
            'stopReason': 'Review pending. Complete review before ending session.'
        }
    else:
        output = {
            'continue': True
        }
    
    print(json.dumps(output))


if __name__ == '__main__':
    main()
