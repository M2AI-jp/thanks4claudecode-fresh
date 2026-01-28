"""Tests for Mini Lisp lexer."""

import pytest

from products.mini_lisp.lexer import tokenize, Token, TokenType


class TestTokenizeSimpleExpressions:
    """Test tokenizing simple expressions."""

    def test_simple_addition(self):
        """Test tokenizing (+ 1 2)."""
        tokens = tokenize("(+ 1 2)")
        assert len(tokens) == 5
        assert tokens[0] == Token(TokenType.LPAREN, '(')
        assert tokens[1] == Token(TokenType.SYMBOL, '+')
        assert tokens[2] == Token(TokenType.NUMBER, 1)
        assert tokens[3] == Token(TokenType.NUMBER, 2)
        assert tokens[4] == Token(TokenType.RPAREN, ')')

    def test_nested_expression(self):
        """Test tokenizing nested expression (+ (* 2 3) 4)."""
        tokens = tokenize("(+ (* 2 3) 4)")
        assert len(tokens) == 9
        assert tokens[0].type == TokenType.LPAREN
        assert tokens[1].value == '+'
        assert tokens[2].type == TokenType.LPAREN
        assert tokens[3].value == '*'
        assert tokens[4].value == 2
        assert tokens[5].value == 3
        assert tokens[6].type == TokenType.RPAREN
        assert tokens[7].value == 4
        assert tokens[8].type == TokenType.RPAREN

    def test_subtraction_with_negative(self):
        """Test tokenizing (- 10 -5)."""
        tokens = tokenize("(- 10 -5)")
        assert len(tokens) == 5
        assert tokens[2].value == 10
        assert tokens[3].value == -5


class TestTokenizeSymbols:
    """Test tokenizing symbols."""

    def test_define_keyword(self):
        """Test tokenizing define."""
        tokens = tokenize("(define x 10)")
        assert tokens[1] == Token(TokenType.SYMBOL, 'define')
        assert tokens[2] == Token(TokenType.SYMBOL, 'x')

    def test_lambda_keyword(self):
        """Test tokenizing lambda."""
        tokens = tokenize("(lambda (x) x)")
        assert tokens[1] == Token(TokenType.SYMBOL, 'lambda')

    def test_if_keyword(self):
        """Test tokenizing if."""
        tokens = tokenize("(if (> x 0) x 0)")
        assert tokens[1] == Token(TokenType.SYMBOL, 'if')

    def test_special_symbols(self):
        """Test tokenizing special symbols like >, <, =, etc."""
        tokens = tokenize("(>= <= = != + - * /)")
        symbols = [t.value for t in tokens if t.type == TokenType.SYMBOL]
        assert '>=' in symbols
        assert '<=' in symbols
        assert '=' in symbols
        assert '+' in symbols
        assert '-' in symbols
        assert '*' in symbols
        assert '/' in symbols


class TestTokenizeNumbers:
    """Test tokenizing numbers."""

    def test_integer(self):
        """Test tokenizing integers."""
        tokens = tokenize("42")
        assert len(tokens) == 1
        assert tokens[0] == Token(TokenType.NUMBER, 42)

    def test_float(self):
        """Test tokenizing floating point numbers."""
        tokens = tokenize("3.14")
        assert len(tokens) == 1
        assert tokens[0] == Token(TokenType.NUMBER, 3.14)

    def test_negative_integer(self):
        """Test tokenizing negative integers."""
        tokens = tokenize("-42")
        assert len(tokens) == 1
        assert tokens[0] == Token(TokenType.NUMBER, -42)

    def test_negative_float(self):
        """Test tokenizing negative floats."""
        tokens = tokenize("-3.14")
        assert len(tokens) == 1
        assert tokens[0] == Token(TokenType.NUMBER, -3.14)

    def test_multiple_numbers(self):
        """Test tokenizing multiple numbers."""
        tokens = tokenize("1 2.5 -3 -4.5")
        assert len(tokens) == 4
        assert tokens[0].value == 1
        assert tokens[1].value == 2.5
        assert tokens[2].value == -3
        assert tokens[3].value == -4.5


class TestTokenizeStrings:
    """Test tokenizing string literals."""

    def test_simple_string(self):
        """Test tokenizing simple string."""
        tokens = tokenize('"hello"')
        assert len(tokens) == 1
        assert tokens[0] == Token(TokenType.STRING, 'hello')

    def test_string_with_spaces(self):
        """Test tokenizing string with spaces."""
        tokens = tokenize('"hello world"')
        assert len(tokens) == 1
        assert tokens[0].value == 'hello world'

    def test_string_with_escape_sequences(self):
        """Test tokenizing string with escape sequences."""
        tokens = tokenize(r'"hello\nworld"')
        assert len(tokens) == 1
        assert tokens[0].value == 'hello\nworld'

    def test_string_in_expression(self):
        """Test tokenizing string in expression."""
        tokens = tokenize('(print "hello")')
        assert len(tokens) == 4
        assert tokens[2] == Token(TokenType.STRING, 'hello')

    def test_unterminated_string_raises(self):
        """Test that unterminated string raises ValueError."""
        with pytest.raises(ValueError, match="Unterminated string"):
            tokenize('"hello')


class TestTokenizeEmpty:
    """Test tokenizing empty and whitespace input."""

    def test_empty_input(self):
        """Test tokenizing empty string."""
        tokens = tokenize("")
        assert tokens == []

    def test_whitespace_only(self):
        """Test tokenizing whitespace only."""
        tokens = tokenize("   \t\n  ")
        assert tokens == []

    def test_comment_only(self):
        """Test tokenizing comment only."""
        tokens = tokenize("; this is a comment")
        assert tokens == []

    def test_comment_with_code(self):
        """Test tokenizing code with comment."""
        tokens = tokenize("; comment\n(+ 1 2)")
        assert len(tokens) == 5
        assert tokens[1].value == '+'
