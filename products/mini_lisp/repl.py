"""Mini Lisp REPL - Read-Eval-Print Loop for interactive Lisp programming."""

import sys
import os
from typing import Optional, Any, Tuple

# Support both relative and absolute imports
try:
    from .evaluator import Environment, evaluate, EvaluationError
    from .lexer import tokenize, TokenType
    from .parser import parse, ParseError
except ImportError:
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from products.mini_lisp.evaluator import Environment, evaluate, EvaluationError
    from products.mini_lisp.lexer import tokenize, TokenType
    from products.mini_lisp.parser import parse, ParseError


def _count_parens(text: str) -> int:
    """Count unbalanced parentheses in text.
    
    Returns:
        Positive number if more opening parens than closing.
        Negative number if more closing parens than opening.
        Zero if balanced.
    """
    count = 0
    in_string = False
    escape_next = False
    
    for char in text:
        if escape_next:
            escape_next = False
            continue
        if char == '\\' and in_string:
            escape_next = True
            continue
        if char == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if char == '(':
            count += 1
        elif char == ')':
            count -= 1
    
    return count


def _format_result(result: Any) -> str:
    """Format a result for REPL output.
    
    Args:
        result: The evaluation result.
        
    Returns:
        String representation of the result.
    """
    if result is None:
        return "nil"
    elif result is True:
        return "#t"
    elif result is False:
        return "#f"
    elif isinstance(result, str):
        return f'"{result}"'
    elif isinstance(result, list):
        if len(result) == 0:
            return "()"
        elements = " ".join(_format_result(elem) for elem in result)
        return f"({elements})"
    else:
        return str(result)


def _is_define_form(ast: Any) -> bool:
    """Check if an AST represents a define form.
    
    Args:
        ast: The AST to check.
        
    Returns:
        True if the AST is a define form.
    """
    return isinstance(ast, list) and len(ast) >= 2 and ast[0] == "define"


def _get_define_name(ast: Any) -> str:
    """Get the name being defined from a define form.
    
    Args:
        ast: A define form AST.
        
    Returns:
        The symbol name being defined.
    """
    return ast[1]


def _evaluate_and_format(ast: Any, env: Environment) -> str:
    """Evaluate an AST and format the result appropriately.
    
    For define forms, returns the symbol name.
    For other forms, returns the formatted result.
    
    Args:
        ast: The AST to evaluate.
        env: The environment.
        
    Returns:
        Formatted string representation of the result.
    """
    if _is_define_form(ast):
        name = _get_define_name(ast)
        evaluate(ast, env)  # Side effect: defines the variable
        return name
    else:
        result = evaluate(ast, env)
        return _format_result(result)


def repl(env: Optional[Environment] = None) -> None:
    """Start an interactive Read-Eval-Print Loop.
    
    Args:
        env: Optional environment. Creates a new global environment if not provided.
        
    The REPL supports:
        - Multi-line input (automatically detects unbalanced parentheses)
        - Graceful error handling
        - Exit commands: exit, quit, or Ctrl+D
        
    Example:
        >>> from products.mini_lisp import repl
        >>> repl()  # Start interactive session
        Mini Lisp REPL. Type 'exit' or 'quit' to exit.
        > (+ 1 2)
        3
    """
    if env is None:
        env = Environment()
    
    print("Mini Lisp REPL. Type 'exit' or 'quit' to exit.")
    
    buffer = ""
    prompt = "> "
    
    while True:
        try:
            line = input(prompt)
        except EOFError:
            print()  # Newline after Ctrl+D
            break
        except KeyboardInterrupt:
            print()  # Newline after Ctrl+C
            buffer = ""
            prompt = "> "
            continue
        
        # Check for exit commands
        stripped = line.strip()
        if stripped in ("exit", "quit", "(exit)", "(quit)"):
            break
        
        # Skip empty lines when not in multi-line mode
        if not stripped and not buffer:
            continue
        
        # Accumulate input
        buffer += (" " if buffer else "") + line
        
        # Check parentheses balance
        paren_count = _count_parens(buffer)
        
        if paren_count > 0:
            # Need more input
            prompt = "... "
            continue
        elif paren_count < 0:
            # Too many closing parens
            print(f"Error: Unbalanced parentheses (too many closing)")
            buffer = ""
            prompt = "> "
            continue
        
        # Parentheses are balanced, try to evaluate
        if buffer.strip():
            try:
                tokens = tokenize(buffer)
                ast = parse(tokens)
                
                # Handle multiple expressions
                if isinstance(ast, list) and ast and isinstance(ast[0], list):
                    for expr in ast:
                        print(_evaluate_and_format(expr, env))
                else:
                    print(_evaluate_and_format(ast, env))
                    
            except ParseError as e:
                print(f"Parse Error: {e}")
            except EvaluationError as e:
                print(f"Error: {e}")
            except Exception as e:
                print(f"Error: {e}")
        
        buffer = ""
        prompt = "> "


if __name__ == "__main__":
    repl()
