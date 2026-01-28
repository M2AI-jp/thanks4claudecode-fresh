"""Mini Lisp Lexer - Tokenizes Lisp S-expressions."""

from dataclasses import dataclass
from enum import Enum, auto
from typing import List


class TokenType(Enum):
    """Token types for Mini Lisp."""
    LPAREN = auto()   # (
    RPAREN = auto()   # )
    NUMBER = auto()   # integers and floats
    SYMBOL = auto()   # identifiers like +, -, define, lambda
    STRING = auto()   # "string literals"


@dataclass
class Token:
    """Represents a lexical token."""
    type: TokenType
    value: any

    def __repr__(self) -> str:
        return f"Token({self.type.name}, {self.value!r})"


def tokenize(code: str) -> List[Token]:
    """
    Tokenize Lisp source code into a list of tokens.
    
    Args:
        code: The Lisp source code string to tokenize.
        
    Returns:
        A list of Token objects.
        
    Raises:
        ValueError: If an unterminated string is encountered.
        
    Example:
        >>> tokenize("(+ 1 2)")
        [Token(LPAREN, '('), Token(SYMBOL, '+'), Token(NUMBER, 1), Token(NUMBER, 2), Token(RPAREN, ')')]
    """
    tokens: List[Token] = []
    i = 0
    length = len(code)
    
    while i < length:
        char = code[i]
        
        # Skip whitespace
        if char.isspace():
            i += 1
            continue
        
        # Left parenthesis
        if char == '(':
            tokens.append(Token(TokenType.LPAREN, '('))
            i += 1
            continue
        
        # Right parenthesis
        if char == ')':
            tokens.append(Token(TokenType.RPAREN, ')'))
            i += 1
            continue
        
        # String literal
        if char == '"':
            string_value, end_pos = _read_string(code, i)
            tokens.append(Token(TokenType.STRING, string_value))
            i = end_pos
            continue
        
        # Comment (skip until end of line)
        if char == ';':
            while i < length and code[i] != '\n':
                i += 1
            continue
        
        # Number or negative number
        if char.isdigit() or (char == '-' and i + 1 < length and code[i + 1].isdigit()):
            number_value, end_pos = _read_number(code, i)
            tokens.append(Token(TokenType.NUMBER, number_value))
            i = end_pos
            continue
        
        # Symbol (any other non-whitespace, non-special character)
        if _is_symbol_char(char):
            symbol_value, end_pos = _read_symbol(code, i)
            tokens.append(Token(TokenType.SYMBOL, symbol_value))
            i = end_pos
            continue
        
        # Unknown character - skip it
        i += 1
    
    return tokens


def _read_string(code: str, start: int) -> tuple[str, int]:
    """
    Read a string literal starting at the given position.
    
    Args:
        code: The source code.
        start: Position of the opening quote.
        
    Returns:
        Tuple of (string_value, end_position).
        
    Raises:
        ValueError: If the string is not terminated.
    """
    i = start + 1  # Skip opening quote
    length = len(code)
    result = []
    
    while i < length:
        char = code[i]
        
        if char == '"':
            return ''.join(result), i + 1
        
        if char == '\\' and i + 1 < length:
            # Handle escape sequences
            next_char = code[i + 1]
            if next_char == 'n':
                result.append('\n')
            elif next_char == 't':
                result.append('\t')
            elif next_char == '\\':
                result.append('\\')
            elif next_char == '"':
                result.append('"')
            else:
                result.append(next_char)
            i += 2
            continue
        
        result.append(char)
        i += 1
    
    raise ValueError(f"Unterminated string starting at position {start}")


def _read_number(code: str, start: int) -> tuple[int | float, int]:
    """
    Read a number (integer or float) starting at the given position.
    
    Args:
        code: The source code.
        start: Starting position.
        
    Returns:
        Tuple of (number_value, end_position).
    """
    i = start
    length = len(code)
    has_dot = False
    
    # Handle negative sign
    if i < length and code[i] == '-':
        i += 1
    
    while i < length:
        char = code[i]
        
        if char.isdigit():
            i += 1
        elif char == '.' and not has_dot:
            has_dot = True
            i += 1
        else:
            break
    
    number_str = code[start:i]
    
    if has_dot:
        return float(number_str), i
    else:
        return int(number_str), i


def _read_symbol(code: str, start: int) -> tuple[str, int]:
    """
    Read a symbol starting at the given position.
    
    Args:
        code: The source code.
        start: Starting position.
        
    Returns:
        Tuple of (symbol_value, end_position).
    """
    i = start
    length = len(code)
    
    while i < length and _is_symbol_char(code[i]):
        i += 1
    
    return code[start:i], i


def _is_symbol_char(char: str) -> bool:
    """
    Check if a character can be part of a symbol.
    
    Symbols can contain letters, digits, and various special characters
    commonly used in Lisp (like +, -, *, /, <, >, =, !, ?, etc.)
    """
    if char.isalnum():
        return True
    if char in '+-*/<>=!?_&%^~@#$':
        return True
    return False


# Convenience function for quick testing
if __name__ == "__main__":
    # Test examples
    test_cases = [
        "(+ 1 2)",
        "(define x 10)",
        "(lambda (x y) (+ x y))",
        "(if (> x 0) x (- x))",
        '(print "hello world")',
        "(+ -5 3.14)",
        "; comment\n(+ 1 2)",
    ]
    
    for code in test_cases:
        print(f"Input: {code!r}")
        print(f"Tokens: {tokenize(code)}")
        print()
