"""Tests for Mini Lisp evaluator."""

import pytest

from products.mini_lisp.evaluator import (
    evaluate,
    run,
    Environment,
    Procedure,
    EvaluationError,
)
from products.mini_lisp.lexer import tokenize
from products.mini_lisp.parser import parse


class TestArithmeticOperations:
    """Test arithmetic operations."""

    def test_addition(self):
        """Test addition."""
        assert run("(+ 1 2)") == 3

    def test_addition_multiple_args(self):
        """Test addition with multiple arguments."""
        assert run("(+ 1 2 3 4 5)") == 15

    def test_subtraction(self):
        """Test subtraction."""
        assert run("(- 10 3)") == 7

    def test_unary_minus(self):
        """Test unary minus."""
        assert run("(- 5)") == -5

    def test_multiplication(self):
        """Test multiplication."""
        assert run("(* 4 5)") == 20

    def test_multiplication_multiple_args(self):
        """Test multiplication with multiple arguments."""
        assert run("(* 2 3 4)") == 24

    def test_division(self):
        """Test division."""
        assert run("(/ 20 4)") == 5.0

    def test_nested_arithmetic(self):
        """Test nested arithmetic expressions."""
        assert run("(+ (* 2 3) (- 10 5))") == 11


class TestDefineAndLookup:
    """Test define and variable lookup."""

    def test_define_number(self):
        """Test defining a number."""
        env = Environment()
        run("(define x 10)", env)
        assert run("x", env) == 10

    def test_define_expression(self):
        """Test defining with expression."""
        env = Environment()
        run("(define y (+ 5 5))", env)
        assert run("y", env) == 10

    def test_use_defined_variable(self):
        """Test using defined variable in expression."""
        env = Environment()
        run("(define x 10)", env)
        assert run("(+ x 5)", env) == 15

    def test_undefined_variable_raises(self):
        """Test that undefined variable raises error."""
        with pytest.raises(EvaluationError, match="Undefined variable"):
            run("undefined_var")

    def test_redefine_variable(self):
        """Test redefining a variable."""
        env = Environment()
        run("(define x 10)", env)
        run("(define x 20)", env)
        assert run("x", env) == 20


class TestIfConditional:
    """Test if conditional."""

    def test_if_true_branch(self):
        """Test if with true condition."""
        assert run("(if (> 5 3) 1 0)") == 1

    def test_if_false_branch(self):
        """Test if with false condition."""
        assert run("(if (< 5 3) 1 0)") == 0

    def test_if_no_else(self):
        """Test if without else branch returns None."""
        assert run("(if #f 1)") is None

    def test_if_nested(self):
        """Test nested if expressions."""
        env = Environment()
        run("(define x 5)", env)
        result = run("(if (> x 10) 1 (if (> x 0) 2 3))", env)
        assert result == 2

    def test_if_with_truthy_value(self):
        """Test if with non-boolean truthy value."""
        assert run("(if 1 10 20)") == 10

    def test_if_with_false_boolean(self):
        """Test if with #f."""
        assert run("(if #f 10 20)") == 20


class TestLambdaAndApplication:
    """Test lambda and function application."""

    def test_simple_lambda(self):
        """Test simple lambda application."""
        assert run("((lambda (x) x) 42)") == 42

    def test_lambda_with_body(self):
        """Test lambda with expression body."""
        assert run("((lambda (x) (+ x 1)) 5)") == 6

    def test_lambda_multiple_params(self):
        """Test lambda with multiple parameters."""
        assert run("((lambda (x y) (+ x y)) 3 4)") == 7

    def test_define_function(self):
        """Test defining a function with lambda."""
        env = Environment()
        run("(define add1 (lambda (n) (+ n 1)))", env)
        assert run("(add1 5)", env) == 6

    def test_wrong_arg_count_raises(self):
        """Test that wrong argument count raises error."""
        with pytest.raises(EvaluationError, match="Expected .* arguments"):
            run("((lambda (x y) (+ x y)) 1)")


class TestListOperations:
    """Test list operations."""

    def test_quote(self):
        """Test quote."""
        assert run("(quote (1 2 3))") == [1, 2, 3]

    def test_car(self):
        """Test car."""
        assert run("(car (quote (1 2 3)))") == 1

    def test_cdr(self):
        """Test cdr."""
        assert run("(cdr (quote (1 2 3)))") == [2, 3]

    def test_cons(self):
        """Test cons."""
        assert run("(cons 1 (quote (2 3)))") == [1, 2, 3]

    def test_list(self):
        """Test list construction."""
        assert run("(list 1 2 3)") == [1, 2, 3]

    def test_null_empty(self):
        """Test null? with empty list."""
        assert run("(null? (quote ()))") is True

    def test_null_non_empty(self):
        """Test null? with non-empty list."""
        assert run("(null? (quote (1)))") is False


class TestComparisonOperations:
    """Test comparison operations."""

    def test_equal(self):
        """Test equality."""
        assert run("(= 5 5)") is True
        assert run("(= 5 3)") is False

    def test_less_than(self):
        """Test less than."""
        assert run("(< 3 5)") is True
        assert run("(< 5 3)") is False

    def test_greater_than(self):
        """Test greater than."""
        assert run("(> 5 3)") is True
        assert run("(> 3 5)") is False

    def test_less_equal(self):
        """Test less than or equal."""
        assert run("(<= 3 5)") is True
        assert run("(<= 5 5)") is True
        assert run("(<= 5 3)") is False

    def test_greater_equal(self):
        """Test greater than or equal."""
        assert run("(>= 5 3)") is True
        assert run("(>= 5 5)") is True
        assert run("(>= 3 5)") is False


class TestBegin:
    """Test begin expression."""

    def test_begin_single(self):
        """Test begin with single expression."""
        assert run("(begin 42)") == 42

    def test_begin_multiple(self):
        """Test begin with multiple expressions."""
        env = Environment()
        result = run("(begin (define x 1) (define y 2) (+ x y))", env)
        assert result == 3

    def test_begin_returns_last(self):
        """Test that begin returns last expression."""
        assert run("(begin 1 2 3)") == 3

    def test_begin_empty(self):
        """Test empty begin."""
        assert run("(begin)") is None


class TestRecursion:
    """Test recursive functions."""

    def test_factorial(self):
        """Test factorial function."""
        env = Environment()
        run("""
            (define fact
                (lambda (n)
                    (if (<= n 1)
                        1
                        (* n (fact (- n 1))))))
        """, env)
        assert run("(fact 5)", env) == 120
        assert run("(fact 0)", env) == 1
        assert run("(fact 1)", env) == 1

    def test_sum_recursive(self):
        """Test recursive sum function."""
        env = Environment()
        run("""
            (define sum
                (lambda (n)
                    (if (<= n 0)
                        0
                        (+ n (sum (- n 1))))))
        """, env)
        assert run("(sum 5)", env) == 15

    def test_countdown(self):
        """Test countdown recursive function."""
        env = Environment()
        run("""
            (define countdown
                (lambda (n)
                    (if (<= n 0)
                        (quote done)
                        (countdown (- n 1)))))
        """, env)
        assert run("(countdown 3)", env) == 'done'


class TestLogicOperations:
    """Test logic operations."""

    def test_and_true(self):
        """Test and with all true."""
        assert run("(and #t #t)") is True

    def test_and_false(self):
        """Test and with false."""
        assert run("(and #t #f)") is False

    def test_and_short_circuit(self):
        """Test and short-circuits."""
        env = Environment()
        # Should not evaluate second expression
        result = run("(and #f (undefined_var))", env)
        assert result is False

    def test_or_true(self):
        """Test or with true."""
        assert run("(or #f #t)") is True

    def test_or_false(self):
        """Test or with all false."""
        assert run("(or #f #f)") is False

    def test_or_short_circuit(self):
        """Test or short-circuits."""
        env = Environment()
        # Should not evaluate second expression
        result = run("(or #t (undefined_var))", env)
        assert result is True

    def test_not(self):
        """Test not."""
        assert run("(not #t)") is False
        assert run("(not #f)") is True


class TestLet:
    """Test let expression."""

    def test_simple_let(self):
        """Test simple let binding."""
        assert run("(let ((x 5)) x)") == 5

    def test_let_multiple_bindings(self):
        """Test let with multiple bindings."""
        assert run("(let ((x 1) (y 2)) (+ x y))") == 3

    def test_let_shadowing(self):
        """Test let shadowing outer variable."""
        env = Environment()
        run("(define x 10)", env)
        result = run("(let ((x 5)) x)", env)
        assert result == 5
        # Outer x should be unchanged
        assert run("x", env) == 10


class TestCond:
    """Test cond expression."""

    def test_cond_first_true(self):
        """Test cond with first clause true."""
        assert run("(cond (#t 1) (#t 2))") == 1

    def test_cond_second_true(self):
        """Test cond with second clause true."""
        assert run("(cond (#f 1) (#t 2))") == 2

    def test_cond_else(self):
        """Test cond with else clause."""
        assert run("(cond (#f 1) (else 2))") == 2

    def test_cond_no_match(self):
        """Test cond with no matching clause."""
        assert run("(cond (#f 1) (#f 2))") is None


class TestTypePredicates:
    """Test type predicates."""

    def test_number_predicate(self):
        """Test number? predicate."""
        assert run("(number? 42)") is True
        assert run("(number? 3.14)") is True
        # String literals in Lisp need to be quoted for the type check
        # because without quote they are looked up as variables
        assert run("(number? (quote hello))") is False

    def test_list_predicate(self):
        """Test list? predicate."""
        assert run("(list? (quote (1 2)))") is True
        assert run("(list? 42)") is False

    def test_procedure_predicate(self):
        """Test procedure? predicate."""
        assert run("(procedure? +)") is True
        assert run("(procedure? (lambda (x) x))") is True
        assert run("(procedure? 42)") is False

    def test_symbol_predicate(self):
        """Test symbol? predicate."""
        assert run("(symbol? (quote x))") is True
        assert run("(symbol? 42)") is False
