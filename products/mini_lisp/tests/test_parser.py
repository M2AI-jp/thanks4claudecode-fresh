"""Tests for Mini Lisp parser."""

import pytest

from products.mini_lisp.lexer import tokenize
from products.mini_lisp.parser import parse, ParseError


class TestParseSimpleLists:
    """Test parsing simple lists."""

    def test_simple_addition(self):
        """Test parsing (+ 1 2)."""
        tokens = tokenize("(+ 1 2)")
        ast = parse(tokens)
        assert ast == ['+', 1, 2]

    def test_subtraction(self):
        """Test parsing (- 10 5)."""
        tokens = tokenize("(- 10 5)")
        ast = parse(tokens)
        assert ast == ['-', 10, 5]

    def test_multiplication(self):
        """Test parsing (* 3 4)."""
        tokens = tokenize("(* 3 4)")
        ast = parse(tokens)
        assert ast == ['*', 3, 4]

    def test_empty_list(self):
        """Test parsing empty list ()."""
        tokens = tokenize("()")
        ast = parse(tokens)
        assert ast == []


class TestParseNestedLists:
    """Test parsing nested lists."""

    def test_two_level_nesting(self):
        """Test parsing (+ (* 2 3) 4)."""
        tokens = tokenize("(+ (* 2 3) 4)")
        ast = parse(tokens)
        assert ast == ['+', ['*', 2, 3], 4]

    def test_three_level_nesting(self):
        """Test parsing (+ (* (- 5 2) 3) 4)."""
        tokens = tokenize("(+ (* (- 5 2) 3) 4)")
        ast = parse(tokens)
        assert ast == ['+', ['*', ['-', 5, 2], 3], 4]

    def test_multiple_nested_at_same_level(self):
        """Test parsing (+ (* 2 3) (- 10 5))."""
        tokens = tokenize("(+ (* 2 3) (- 10 5))")
        ast = parse(tokens)
        assert ast == ['+', ['*', 2, 3], ['-', 10, 5]]

    def test_define_with_nested(self):
        """Test parsing (define x (+ 1 2))."""
        tokens = tokenize("(define x (+ 1 2))")
        ast = parse(tokens)
        assert ast == ['define', 'x', ['+', 1, 2]]


class TestParseAtoms:
    """Test parsing atoms."""

    def test_integer_atom(self):
        """Test parsing integer atom."""
        tokens = tokenize("42")
        ast = parse(tokens)
        assert ast == 42

    def test_float_atom(self):
        """Test parsing float atom."""
        tokens = tokenize("3.14")
        ast = parse(tokens)
        assert ast == 3.14

    def test_symbol_atom(self):
        """Test parsing symbol atom."""
        tokens = tokenize("x")
        ast = parse(tokens)
        assert ast == 'x'

    def test_string_atom(self):
        """Test parsing string atom."""
        tokens = tokenize('"hello"')
        ast = parse(tokens)
        assert ast == 'hello'

    def test_negative_number_atom(self):
        """Test parsing negative number atom."""
        tokens = tokenize("-42")
        ast = parse(tokens)
        assert ast == -42


class TestParseMultipleExpressions:
    """Test parsing multiple expressions."""

    def test_two_expressions(self):
        """Test parsing two expressions."""
        tokens = tokenize("(+ 1 2) (- 3 4)")
        ast = parse(tokens)
        assert ast == [['+', 1, 2], ['-', 3, 4]]

    def test_three_expressions(self):
        """Test parsing three expressions."""
        tokens = tokenize("(define x 1) (define y 2) (+ x y)")
        ast = parse(tokens)
        assert ast == [
            ['define', 'x', 1],
            ['define', 'y', 2],
            ['+', 'x', 'y']
        ]

    def test_mixed_atoms_and_lists(self):
        """Test parsing mixed atoms and lists."""
        tokens = tokenize("1 (+ 2 3)")
        ast = parse(tokens)
        assert ast == [1, ['+', 2, 3]]


class TestParseErrors:
    """Test parse error handling."""

    def test_unbalanced_open_paren(self):
        """Test that unbalanced open paren raises ParseError."""
        tokens = tokenize("(+ 1 2")
        with pytest.raises(ParseError, match="expected '\\)'"):
            parse(tokens)

    def test_unbalanced_close_paren(self):
        """Test that unexpected close paren raises ParseError."""
        tokens = tokenize(")")
        with pytest.raises(ParseError, match="Unexpected '\\)'"):
            parse(tokens)

    def test_extra_close_paren(self):
        """Test that extra close paren raises ParseError."""
        tokens = tokenize("(+ 1 2))")
        with pytest.raises(ParseError, match="Unexpected '\\)'"):
            parse(tokens)

    def test_deeply_unbalanced(self):
        """Test deeply unbalanced parens."""
        tokens = tokenize("((( 1 2")
        with pytest.raises(ParseError):
            parse(tokens)


class TestParseLambdaAndDefine:
    """Test parsing lambda and define forms."""

    def test_simple_lambda(self):
        """Test parsing simple lambda."""
        tokens = tokenize("(lambda (x) x)")
        ast = parse(tokens)
        assert ast == ['lambda', ['x'], 'x']

    def test_lambda_with_body(self):
        """Test parsing lambda with expression body."""
        tokens = tokenize("(lambda (x y) (+ x y))")
        ast = parse(tokens)
        assert ast == ['lambda', ['x', 'y'], ['+', 'x', 'y']]

    def test_define_function(self):
        """Test parsing function definition."""
        tokens = tokenize("(define add1 (lambda (n) (+ n 1)))")
        ast = parse(tokens)
        assert ast == ['define', 'add1', ['lambda', ['n'], ['+', 'n', 1]]]

    def test_nested_lambda(self):
        """Test parsing nested lambda (closure)."""
        tokens = tokenize("(lambda (x) (lambda (y) (+ x y)))")
        ast = parse(tokens)
        assert ast == ['lambda', ['x'], ['lambda', ['y'], ['+', 'x', 'y']]]


class TestParseSpecialForms:
    """Test parsing special forms."""

    def test_if_expression(self):
        """Test parsing if expression."""
        tokens = tokenize("(if (> x 0) x 0)")
        ast = parse(tokens)
        assert ast == ['if', ['>', 'x', 0], 'x', 0]

    def test_quote_expression(self):
        """Test parsing quote expression."""
        tokens = tokenize("(quote (1 2 3))")
        ast = parse(tokens)
        assert ast == ['quote', [1, 2, 3]]

    def test_let_expression(self):
        """Test parsing let expression."""
        tokens = tokenize("(let ((x 1) (y 2)) (+ x y))")
        ast = parse(tokens)
        assert ast == ['let', [['x', 1], ['y', 2]], ['+', 'x', 'y']]

    def test_begin_expression(self):
        """Test parsing begin expression."""
        tokens = tokenize("(begin (define x 1) (+ x 1))")
        ast = parse(tokens)
        assert ast == ['begin', ['define', 'x', 1], ['+', 'x', 1]]
