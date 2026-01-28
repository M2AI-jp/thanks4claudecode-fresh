"""Mini Lisp main entry point."""

import sys
import os
from typing import Optional

# Add repo root to path for direct script execution
_script_dir = os.path.dirname(os.path.abspath(__file__))
_repo_root = os.path.dirname(os.path.dirname(_script_dir))
if _repo_root not in sys.path:
    sys.path.insert(0, _repo_root)

from products.mini_lisp.evaluator import Environment, evaluate, EvaluationError
from products.mini_lisp.lexer import tokenize
from products.mini_lisp.parser import parse, ParseError
from products.mini_lisp.repl import repl, _format_result, _evaluate_and_format


def run_code(code: str, env: Optional[Environment] = None) -> None:
    """Parse and evaluate Lisp code, printing each result.
    
    Args:
        code: Lisp source code (may contain multiple expressions).
        env: Optional environment. Creates a new global environment if not provided.
    """
    if env is None:
        env = Environment()
    
    try:
        tokens = tokenize(code)
        ast = parse(tokens)
        
        # Handle multiple top-level expressions
        if isinstance(ast, list) and ast and isinstance(ast[0], list):
            for expr in ast:
                print(_evaluate_and_format(expr, env))
        else:
            print(_evaluate_and_format(ast, env))
            
    except ParseError as e:
        print(f"Parse Error: {e}", file=sys.stderr)
        sys.exit(1)
    except EvaluationError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    """Main entry point for Mini Lisp.
    
    If stdin has piped input, reads and evaluates it.
    If stdin is a tty, starts interactive REPL.
    """
    if sys.stdin.isatty():
        # Interactive mode - start REPL
        repl()
    else:
        # Piped input - read and evaluate
        code = sys.stdin.read()
        if code.strip():
            run_code(code)


if __name__ == "__main__":
    main()
