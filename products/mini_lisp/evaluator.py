"""Mini Lisp Evaluator - Evaluates AST with environment and closures."""

from typing import Any, Callable, Dict, List, Optional, Union

from .parser import AST


class EvaluationError(Exception):
    """Raised when evaluation fails."""
    pass


class Environment:
    """
    Environment for variable bindings with parent scope support.
    
    Supports lexical scoping through parent chain lookup.
    """
    
    def __init__(self, parent: Optional["Environment"] = None):
        """
        Create a new environment.
        
        Args:
            parent: Optional parent environment for lexical scoping.
        """
        self._bindings: Dict[str, Any] = {}
        self._parent = parent
    
    def define(self, name: str, value: Any) -> None:
        """
        Define a variable in the current environment.
        
        Args:
            name: Variable name.
            value: Value to bind.
        """
        self._bindings[name] = value
    
    def lookup(self, name: str) -> Any:
        """
        Look up a variable in this environment or parent scopes.
        
        Args:
            name: Variable name to look up.
            
        Returns:
            The value bound to the name.
            
        Raises:
            EvaluationError: If the variable is not found.
        """
        if name in self._bindings:
            return self._bindings[name]
        if self._parent is not None:
            return self._parent.lookup(name)
        raise EvaluationError(f"Undefined variable: {name}")
    
    def set(self, name: str, value: Any) -> None:
        """
        Set a variable that already exists in some scope.
        
        Args:
            name: Variable name.
            value: New value.
            
        Raises:
            EvaluationError: If the variable is not found.
        """
        if name in self._bindings:
            self._bindings[name] = value
        elif self._parent is not None:
            self._parent.set(name, value)
        else:
            raise EvaluationError(f"Undefined variable: {name}")


class Procedure:
    """
    A user-defined procedure (lambda/closure).
    
    Captures the environment at creation time for lexical scoping.
    """
    
    def __init__(self, params: List[str], body: AST, env: Environment):
        """
        Create a new procedure.
        
        Args:
            params: List of parameter names.
            body: The body expression (AST).
            env: The environment captured at definition time.
        """
        self.params = params
        self.body = body
        self.env = env
    
    def __call__(self, *args: Any) -> Any:
        """
        Call the procedure with arguments.
        
        Creates a new environment extending the captured environment,
        binds parameters to arguments, and evaluates the body.
        
        Args:
            *args: Arguments to pass to the procedure.
            
        Returns:
            The result of evaluating the body.
            
        Raises:
            EvaluationError: If argument count doesn't match parameters.
        """
        if len(args) != len(self.params):
            raise EvaluationError(
                f"Expected {len(self.params)} arguments, got {len(args)}"
            )
        
        # Create new environment extending captured environment
        local_env = Environment(parent=self.env)
        
        # Bind parameters to arguments
        for param, arg in zip(self.params, args):
            local_env.define(param, arg)
        
        return evaluate(self.body, local_env)
    
    def __repr__(self) -> str:
        return f"<procedure ({' '.join(self.params)})>"


def _create_global_environment() -> Environment:
    """Create the global environment with built-in functions."""
    env = Environment()
    
    # Arithmetic operations
    env.define("+", lambda *args: sum(args))
    env.define("-", lambda a, b=None: -a if b is None else a - b)
    
    # Multiplication
    def multiply(*args):
        result = 1
        for arg in args:
            result *= arg
        return result
    env.define("*", multiply)
    
    # Division
    def divide(a, b=None):
        if b is None:
            return 1 / a
        return a / b
    env.define("/", divide)
    
    # Comparison operations
    env.define("=", lambda a, b: a == b)
    env.define("<", lambda a, b: a < b)
    env.define(">", lambda a, b: a > b)
    env.define("<=", lambda a, b: a <= b)
    env.define(">=", lambda a, b: a >= b)
    
    # List operations
    env.define("car", lambda lst: lst[0])
    env.define("cdr", lambda lst: lst[1:])
    env.define("cons", lambda a, b: [a] + (b if isinstance(b, list) else [b]))
    env.define("list", lambda *args: list(args))
    env.define("null?", lambda lst: lst == [] or lst is None)
    
    # Logic operations
    # Note: and/or are special forms handled in evaluate()
    env.define("not", lambda x: not x)
    
    # Type predicates
    env.define("number?", lambda x: isinstance(x, (int, float)))
    env.define("symbol?", lambda x: isinstance(x, str))
    env.define("list?", lambda x: isinstance(x, list))
    env.define("procedure?", lambda x: callable(x))
    
    # Boolean constants
    env.define("#t", True)
    env.define("#f", False)
    env.define("true", True)
    env.define("false", False)
    
    return env


# Global environment singleton (lazily initialized)
_global_env: Optional[Environment] = None


def _get_global_env() -> Environment:
    """Get or create the global environment."""
    global _global_env
    if _global_env is None:
        _global_env = _create_global_environment()
    return _global_env


def evaluate(ast: AST, env: Optional[Environment] = None) -> Any:
    """
    Evaluate an AST in the given environment.
    
    Args:
        ast: The AST to evaluate (from parser).
        env: The environment for variable bindings. If None, uses global env.
        
    Returns:
        The result of evaluation.
        
    Raises:
        EvaluationError: If evaluation fails.
        
    Example:
        >>> from products.mini_lisp import tokenize, parse
        >>> from products.mini_lisp.evaluator import evaluate, Environment
        >>> env = Environment()
        >>> evaluate(parse(tokenize("(+ 1 2)")), env)
        3
    """
    # Use global environment if none provided
    if env is None:
        env = _get_global_env()
    
    # If env has no parent and is not the global env, set global as parent
    if env._parent is None and env is not _get_global_env():
        env._parent = _get_global_env()
    
    # Atom: number
    if isinstance(ast, (int, float)):
        return ast
    
    # Atom: symbol (variable reference)
    if isinstance(ast, str):
        return env.lookup(ast)
    
    # List: could be special form or function call
    if isinstance(ast, list):
        if not ast:
            return []  # Empty list evaluates to empty list
        
        # Check for special forms
        first = ast[0]
        
        if first == "quote":
            # (quote expr) - return expression unevaluated
            if len(ast) != 2:
                raise EvaluationError("quote requires exactly 1 argument")
            return ast[1]
        
        if first == "define":
            # (define name value) - bind value to name
            if len(ast) != 3:
                raise EvaluationError("define requires exactly 2 arguments")
            name = ast[1]
            if not isinstance(name, str):
                raise EvaluationError(f"define name must be a symbol, got {type(name)}")
            value = evaluate(ast[2], env)
            env.define(name, value)
            return value
        
        if first == "set!":
            # (set! name value) - update existing variable
            if len(ast) != 3:
                raise EvaluationError("set! requires exactly 2 arguments")
            name = ast[1]
            if not isinstance(name, str):
                raise EvaluationError(f"set! name must be a symbol, got {type(name)}")
            value = evaluate(ast[2], env)
            env.set(name, value)
            return value
        
        if first == "if":
            # (if test conseq alt) - conditional
            if len(ast) < 3 or len(ast) > 4:
                raise EvaluationError("if requires 2 or 3 arguments")
            test = evaluate(ast[1], env)
            if test:  # Truthy
                return evaluate(ast[2], env)
            elif len(ast) == 4:
                return evaluate(ast[3], env)
            else:
                return None  # No else branch, return None
        
        if first == "lambda":
            # (lambda (params) body) - create closure
            if len(ast) != 3:
                raise EvaluationError("lambda requires exactly 2 arguments")
            params = ast[1]
            if not isinstance(params, list):
                raise EvaluationError("lambda params must be a list")
            for p in params:
                if not isinstance(p, str):
                    raise EvaluationError(f"lambda parameter must be a symbol, got {p}")
            body = ast[2]
            return Procedure(params, body, env)
        
        if first == "begin":
            # (begin expr1 expr2 ...) - evaluate all, return last
            if len(ast) < 2:
                return None
            result = None
            for expr in ast[1:]:
                result = evaluate(expr, env)
            return result
        
        if first == "and":
            # (and expr1 expr2 ...) - short-circuit and
            if len(ast) < 2:
                return True
            result = True
            for expr in ast[1:]:
                result = evaluate(expr, env)
                if not result:
                    return result
            return result
        
        if first == "or":
            # (or expr1 expr2 ...) - short-circuit or
            if len(ast) < 2:
                return False
            for expr in ast[1:]:
                result = evaluate(expr, env)
                if result:
                    return result
            return False
        
        if first == "let":
            # (let ((var1 val1) (var2 val2)) body) - local bindings
            if len(ast) != 3:
                raise EvaluationError("let requires exactly 2 arguments")
            bindings = ast[1]
            body = ast[2]
            local_env = Environment(parent=env)
            for binding in bindings:
                if not isinstance(binding, list) or len(binding) != 2:
                    raise EvaluationError("let binding must be (var value)")
                var, val = binding
                if not isinstance(var, str):
                    raise EvaluationError("let variable must be a symbol")
                local_env.define(var, evaluate(val, env))
            return evaluate(body, local_env)
        
        if first == "cond":
            # (cond (test1 expr1) (test2 expr2) ... (else exprN))
            for clause in ast[1:]:
                if not isinstance(clause, list) or len(clause) < 2:
                    raise EvaluationError("cond clause must be (test expr)")
                test = clause[0]
                if test == "else":
                    return evaluate(clause[1], env)
                if evaluate(test, env):
                    return evaluate(clause[1], env)
            return None
        
        # Function application
        func = evaluate(first, env)
        args = [evaluate(arg, env) for arg in ast[1:]]
        
        if callable(func):
            try:
                return func(*args)
            except TypeError as e:
                raise EvaluationError(f"Error calling function: {e}")
        else:
            raise EvaluationError(f"Cannot call non-function: {func}")
    
    raise EvaluationError(f"Cannot evaluate: {ast}")


def _is_multiple_expressions(ast: AST) -> bool:
    """
    Check if AST represents multiple top-level expressions.
    
    The parser returns a list of ASTs for multiple expressions.
    We need to distinguish between:
    - A single expression that is a list (e.g., (+ 1 2) -> ['+', 1, 2])
    - Multiple expressions (e.g., (+ 1 2) (- 3 4) -> [['+', 1, 2], ['-', 3, 4]])
    
    The key difference is that in the multiple case, ALL elements are lists
    (since each top-level expression must be a list or atom).
    """
    if not isinstance(ast, list) or len(ast) == 0:
        return False
    
    # Single expression that starts with a symbol is NOT multiple expressions
    # e.g., ['+', 1, 2] or ['define', 'x', 10]
    if isinstance(ast[0], str):
        return False
    
    # If first element is a number or the list is mixed, it's a function call
    # e.g., [[lambda, ...], 5] is a lambda call, not multiple expressions
    if isinstance(ast[0], (int, float)):
        return False
    
    # Check if it looks like multiple s-expressions
    # Each element should be a non-empty list starting with a symbol or another list
    # BUT we need to be careful: ((lambda (x) x) 5) is one expression, not two
    
    # A better heuristic: if ANY element is not a list, it's a single expression
    for element in ast:
        if not isinstance(element, list):
            return False
    
    # All elements are lists. Still could be a lambda call like ((lambda (x) x) (quote (1 2)))
    # The key insight is: the parser returns multiple expressions only when there are
    # multiple independent top-level forms. We can check this by seeing if this structure
    # would make sense as a single function call.
    
    # For a lambda call like ((lambda ...) arg1 arg2), the first element should be
    # a lambda expression, i.e., start with 'lambda'
    if ast[0] and isinstance(ast[0][0], str) and ast[0][0] == 'lambda':
        return False
    
    return True


def run(code: str, env: Optional[Environment] = None) -> Any:
    """
    Parse and evaluate a Lisp code string.
    
    Args:
        code: Lisp source code.
        env: Optional environment. Uses global if not provided.
        
    Returns:
        The result of evaluation.
        
    Example:
        >>> from products.mini_lisp.evaluator import run
        >>> run("(+ 1 2)")
        3
    """
    from .lexer import tokenize
    from .parser import parse
    
    tokens = tokenize(code)
    ast = parse(tokens)
    
    # Handle multiple top-level expressions
    if _is_multiple_expressions(ast):
        result = None
        for expr in ast:
            result = evaluate(expr, env)
        return result
    
    return evaluate(ast, env)


if __name__ == "__main__":
    # Test examples
    env = Environment()
    
    test_cases = [
        ("(+ 1 2)", 3),
        ("(- 10 3)", 7),
        ("(* 4 5)", 20),
        ("(/ 20 4)", 5.0),
        ("(> 5 3)", True),
        ("(< 5 3)", False),
        ("(define x 10)", 10),
        ("(+ x 5)", 15),
        ("(add1 5)", 6),  # After defining add1 below
        ("(if (> 5 3) 1 0)", 1),
        ("(quote (1 2 3))", [1, 2, 3]),
        ("(car (quote (1 2 3)))", 1),
        ("(cdr (quote (1 2 3)))", [2, 3]),
        ("(cons 1 (quote (2 3)))", [1, 2, 3]),
        ("(list 1 2 3)", [1, 2, 3]),
        ("(null? (quote ()))", True),
        ("(null? (quote (1)))", False),
        ("(begin (define y 1) (define y (+ y 1)) y)", 2),
        ("((lambda (x) (+ x 1)) 5)", 6),
        ("(let ((a 1) (b 2)) (+ a b))", 3),
        ("(and #t #t)", True),
        ("(and #t #f)", False),
        ("(or #f #t)", True),
        ("(not #f)", True),
    ]
    
    # First define add1
    run("(define add1 (lambda (n) (+ n 1)))", env)
    
    print("Running evaluator tests...")
    for code, expected in test_cases:
        try:
            result = run(code, env)
            status = "PASS" if result == expected else f"FAIL (got {result})"
            print(f"  {code} => {result}  [{status}]")
        except Exception as e:
            print(f"  {code} => ERROR: {e}")
    
    # Test closure/recursion
    print("\nTesting closure and recursion...")
    run("(define make-adder (lambda (n) (lambda (x) (+ x n))))", env)
    run("(define add5 (make-adder 5))", env)
    result = run("(add5 10)", env)
    print(f"  Closure test (add5 10): {result} [{'PASS' if result == 15 else 'FAIL'}]")
    
    # Factorial using recursion
    run("""
        (define fact 
            (lambda (n) 
                (if (<= n 1) 
                    1 
                    (* n (fact (- n 1))))))
    """, env)
    result = run("(fact 5)", env)
    print(f"  Factorial (fact 5): {result} [{'PASS' if result == 120 else 'FAIL'}]")
    
    # Test multiple expressions
    print("\nTesting multiple expressions...")
    result = run("(define a 1) (define b 2) (+ a b)", env)
    print(f"  Multiple expressions: {result} [{'PASS' if result == 3 else 'FAIL'}]")
