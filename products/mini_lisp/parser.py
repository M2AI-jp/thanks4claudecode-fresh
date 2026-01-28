"""Mini Lisp Parser - Converts tokens to an Abstract Syntax Tree."""

from typing import List, Any, Union

from .lexer import Token, TokenType


# AST type alias: nested lists with atoms (int, float, str)
AST = Union[int, float, str, List["AST"]]


class ParseError(Exception):
    """Raised when parsing fails."""
    pass


def parse(tokens: List[Token]) -> AST | List[AST]:
    """
    Parse a list of tokens into an Abstract Syntax Tree.
    
    Args:
        tokens: List of Token objects from the lexer.
        
    Returns:
        An AST represented as nested Python lists.
        - Numbers become Python int/float
        - Symbols become Python strings
        - S-expressions become Python lists
        
        If multiple top-level expressions exist, returns a list of ASTs.
        If a single expression exists, returns that AST directly.
        
    Raises:
        ParseError: If the tokens cannot be parsed.
        
    Example:
        >>> from products.mini_lisp.lexer import tokenize
        >>> parse(tokenize("(+ 1 2)"))
        ['+', 1, 2]
        >>> parse(tokenize("(define x (+ 1 2))"))
        ['define', 'x', ['+', 1, 2]]
    """
    if not tokens:
        return []
    
    parser = _Parser(tokens)
    expressions = parser.parse_all()
    
    # Return single expression directly, multiple as a list
    if len(expressions) == 1:
        return expressions[0]
    return expressions


class _Parser:
    """Internal parser class that maintains parsing state."""
    
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0
    
    def parse_all(self) -> List[AST]:
        """Parse all top-level expressions."""
        expressions = []
        while not self._is_at_end():
            expressions.append(self._parse_expression())
        return expressions
    
    def _parse_expression(self) -> AST:
        """Parse a single expression."""
        token = self._peek()
        
        if token is None:
            raise ParseError("Unexpected end of input")
        
        if token.type == TokenType.LPAREN:
            return self._parse_list()
        elif token.type == TokenType.RPAREN:
            raise ParseError("Unexpected ')'")
        else:
            return self._parse_atom()
    
    def _parse_list(self) -> List[AST]:
        """Parse an S-expression (list)."""
        self._consume(TokenType.LPAREN, "Expected '('")
        
        elements: List[AST] = []
        
        while True:
            token = self._peek()
            
            if token is None:
                raise ParseError("Unexpected end of input, expected ')'")
            
            if token.type == TokenType.RPAREN:
                self._advance()  # consume ')'
                break
            
            elements.append(self._parse_expression())
        
        return elements
    
    def _parse_atom(self) -> AST:
        """Parse an atom (number, symbol, or string)."""
        token = self._advance()
        
        if token.type == TokenType.NUMBER:
            return token.value  # Already int or float
        elif token.type == TokenType.SYMBOL:
            return token.value  # String representing the symbol
        elif token.type == TokenType.STRING:
            return token.value  # String literal
        else:
            raise ParseError(f"Unexpected token type: {token.type}")
    
    def _peek(self) -> Token | None:
        """Look at the current token without consuming it."""
        if self._is_at_end():
            return None
        return self.tokens[self.pos]
    
    def _advance(self) -> Token:
        """Consume and return the current token."""
        token = self.tokens[self.pos]
        self.pos += 1
        return token
    
    def _consume(self, expected_type: TokenType, error_message: str) -> Token:
        """Consume a token of the expected type, or raise an error."""
        token = self._peek()
        
        if token is None:
            raise ParseError(f"{error_message}, got end of input")
        
        if token.type != expected_type:
            raise ParseError(f"{error_message}, got {token.type.name}")
        
        return self._advance()
    
    def _is_at_end(self) -> bool:
        """Check if we've consumed all tokens."""
        return self.pos >= len(self.tokens)


# Convenience function for quick testing
if __name__ == "__main__":
    from .lexer import tokenize
    
    # Test examples
    test_cases = [
        "(+ 1 2)",
        "(define x 10)",
        "(define x (+ 1 2))",
        "(lambda (x y) (+ x y))",
        "(if (> x 0) x (- x))",
        '(print "hello world")',
        "(+ -5 3.14)",
        "42",  # Single atom
        "(+ 1 2) (- 3 4)",  # Multiple expressions
    ]
    
    for code in test_cases:
        print(f"Input: {code!r}")
        tokens = tokenize(code)
        print(f"Tokens: {tokens}")
        ast = parse(tokens)
        print(f"AST: {ast}")
        print()
