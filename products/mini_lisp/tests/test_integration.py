"""Integration tests for Mini Lisp."""

import pytest

from products.mini_lisp.evaluator import (
    evaluate,
    run,
    Environment,
    EvaluationError,
)
from products.mini_lisp.lexer import tokenize
from products.mini_lisp.parser import parse


class TestFibonacci:
    """Test Fibonacci sequence implementation."""

    def test_fibonacci_basic(self):
        """Test basic Fibonacci values."""
        env = Environment()
        run("""
            (define fib
                (lambda (n)
                    (if (<= n 1)
                        n
                        (+ (fib (- n 1)) (fib (- n 2))))))
        """, env)
        assert run("(fib 0)", env) == 0
        assert run("(fib 1)", env) == 1
        assert run("(fib 2)", env) == 1
        assert run("(fib 3)", env) == 2
        assert run("(fib 4)", env) == 3
        assert run("(fib 5)", env) == 5
        assert run("(fib 10)", env) == 55

    def test_fibonacci_sequence(self):
        """Test generating Fibonacci sequence."""
        env = Environment()
        run("""
            (define fib
                (lambda (n)
                    (if (<= n 1)
                        n
                        (+ (fib (- n 1)) (fib (- n 2))))))
        """, env)
        run("""
            (define fib-list
                (lambda (n)
                    (if (<= n 0)
                        (quote ())
                        (cons (fib (- n 1)) (fib-list (- n 1))))))
        """, env)
        result = run("(fib-list 7)", env)
        # Returns in reverse order: fib(6), fib(5), ..., fib(0)
        assert result == [8, 5, 3, 2, 1, 1, 0]


class TestClosureBehavior:
    """Test closure and lexical scoping behavior."""

    def test_make_adder(self):
        """Test make-adder closure."""
        env = Environment()
        run("(define make-adder (lambda (n) (lambda (x) (+ x n))))", env)
        run("(define add5 (make-adder 5))", env)
        run("(define add10 (make-adder 10))", env)
        assert run("(add5 3)", env) == 8
        assert run("(add10 3)", env) == 13

    def test_counter_closure(self):
        """Test counter using closure and set!."""
        env = Environment()
        run("""
            (define make-counter
                (lambda ()
                    (let ((count 0))
                        (lambda ()
                            (begin
                                (set! count (+ count 1))
                                count)))))
        """, env)
        run("(define counter1 (make-counter))", env)
        run("(define counter2 (make-counter))", env)
        assert run("(counter1)", env) == 1
        assert run("(counter1)", env) == 2
        assert run("(counter2)", env) == 1
        assert run("(counter1)", env) == 3
        assert run("(counter2)", env) == 2

    def test_closure_captures_environment(self):
        """Test that closure captures the environment at definition time."""
        env = Environment()
        run("(define x 10)", env)
        run("(define get-x (lambda () x))", env)
        assert run("(get-x)", env) == 10
        run("(define x 20)", env)
        # Should return 20 because x is looked up dynamically
        # but from the captured environment
        assert run("(get-x)", env) == 20


class TestNestedFunctionDefinitions:
    """Test nested function definitions."""

    def test_inner_function(self):
        """Test inner function definition."""
        env = Environment()
        run("""
            (define outer
                (lambda (x)
                    (begin
                        (define inner (lambda (y) (+ x y)))
                        (inner 5))))
        """, env)
        assert run("(outer 10)", env) == 15

    def test_mutual_helper(self):
        """Test function using helper function."""
        env = Environment()
        run("""
            (define square (lambda (x) (* x x)))
        """, env)
        run("""
            (define sum-of-squares
                (lambda (x y)
                    (+ (square x) (square y))))
        """, env)
        assert run("(sum-of-squares 3 4)", env) == 25

    def test_higher_order_function(self):
        """Test higher-order function (map-like)."""
        env = Environment()
        run("""
            (define apply-twice
                (lambda (f x)
                    (f (f x))))
        """, env)
        run("(define add1 (lambda (x) (+ x 1)))", env)
        assert run("(apply-twice add1 5)", env) == 7

    def test_compose(self):
        """Test function composition."""
        env = Environment()
        run("""
            (define compose
                (lambda (f g)
                    (lambda (x) (f (g x)))))
        """, env)
        run("(define add1 (lambda (x) (+ x 1)))", env)
        run("(define double (lambda (x) (* x 2)))", env)
        run("(define add1-then-double (compose double add1))", env)
        assert run("(add1-then-double 5)", env) == 12  # (5 + 1) * 2


class TestErrorHandling:
    """Test error handling."""

    def test_undefined_variable(self):
        """Test undefined variable error."""
        with pytest.raises(EvaluationError, match="Undefined variable"):
            run("undefined_variable")

    def test_undefined_function(self):
        """Test calling undefined function."""
        with pytest.raises(EvaluationError, match="Undefined variable"):
            run("(undefined_function 1 2)")

    def test_wrong_arity(self):
        """Test wrong number of arguments."""
        env = Environment()
        run("(define add (lambda (x y) (+ x y)))", env)
        with pytest.raises(EvaluationError, match="Expected .* arguments"):
            run("(add 1)", env)

    def test_call_non_function(self):
        """Test calling a non-function."""
        env = Environment()
        run("(define x 42)", env)
        with pytest.raises(EvaluationError, match="Cannot call non-function"):
            run("(x 1 2)", env)

    def test_set_undefined(self):
        """Test set! on undefined variable."""
        with pytest.raises(EvaluationError, match="Undefined variable"):
            run("(set! undefined_var 10)")


class TestDeepNesting:
    """Test deep nesting scenarios."""

    def test_deep_arithmetic_nesting(self):
        """Test deeply nested arithmetic."""
        result = run("(+ (+ (+ (+ 1 2) 3) 4) 5)")
        assert result == 15

    def test_deep_if_nesting(self):
        """Test deeply nested if expressions."""
        result = run("""
            (if #t
                (if #t
                    (if #t
                        (if #t
                            42
                            0)
                        0)
                    0)
                0)
        """)
        assert result == 42

    def test_deep_function_call(self):
        """Test deeply nested function calls."""
        env = Environment()
        run("(define f (lambda (x) (+ x 1)))", env)
        assert run("(f (f (f (f (f 0)))))", env) == 5

    def test_deep_let_nesting(self):
        """Test deeply nested let expressions."""
        result = run("""
            (let ((a 1))
                (let ((b (+ a 1)))
                    (let ((c (+ b 1)))
                        (let ((d (+ c 1)))
                            (+ a (+ b (+ c d)))))))
        """)
        assert result == 10  # 1 + 2 + 3 + 4

    def test_deep_list_operations(self):
        """Test deeply nested list operations."""
        result = run("(car (cdr (cdr (quote (1 2 3 4 5)))))")
        assert result == 3


class TestComplexPrograms:
    """Test complex programs."""

    def test_length_function(self):
        """Test list length function."""
        env = Environment()
        run("""
            (define length
                (lambda (lst)
                    (if (null? lst)
                        0
                        (+ 1 (length (cdr lst))))))
        """, env)
        assert run("(length (quote ()))", env) == 0
        assert run("(length (quote (1)))", env) == 1
        assert run("(length (quote (1 2 3 4 5)))", env) == 5

    def test_append_function(self):
        """Test list append function."""
        env = Environment()
        run("""
            (define append
                (lambda (lst1 lst2)
                    (if (null? lst1)
                        lst2
                        (cons (car lst1) (append (cdr lst1) lst2)))))
        """, env)
        result = run("(append (quote (1 2)) (quote (3 4)))", env)
        assert result == [1, 2, 3, 4]

    def test_reverse_function(self):
        """Test list reverse function."""
        env = Environment()
        run("""
            (define append
                (lambda (lst1 lst2)
                    (if (null? lst1)
                        lst2
                        (cons (car lst1) (append (cdr lst1) lst2)))))
        """, env)
        run("""
            (define reverse
                (lambda (lst)
                    (if (null? lst)
                        (quote ())
                        (append (reverse (cdr lst)) (list (car lst))))))
        """, env)
        result = run("(reverse (quote (1 2 3 4 5)))", env)
        assert result == [5, 4, 3, 2, 1]

    def test_map_function(self):
        """Test map-like function."""
        env = Environment()
        run("""
            (define map
                (lambda (f lst)
                    (if (null? lst)
                        (quote ())
                        (cons (f (car lst)) (map f (cdr lst))))))
        """, env)
        run("(define double (lambda (x) (* x 2)))", env)
        result = run("(map double (quote (1 2 3 4 5)))", env)
        assert result == [2, 4, 6, 8, 10]

    def test_filter_function(self):
        """Test filter-like function."""
        env = Environment()
        run("""
            (define filter
                (lambda (pred lst)
                    (if (null? lst)
                        (quote ())
                        (if (pred (car lst))
                            (cons (car lst) (filter pred (cdr lst)))
                            (filter pred (cdr lst))))))
        """, env)
        run("(define even? (lambda (x) (= 0 (- x (* 2 (/ x 2))))))", env)
        # Note: Our division returns float, so we need integer division workaround
        run("(define positive? (lambda (x) (> x 0)))", env)
        result = run("(filter positive? (quote (-2 -1 0 1 2 3)))", env)
        assert result == [1, 2, 3]

    def test_reduce_function(self):
        """Test reduce/fold-like function."""
        env = Environment()
        run("""
            (define reduce
                (lambda (f init lst)
                    (if (null? lst)
                        init
                        (reduce f (f init (car lst)) (cdr lst)))))
        """, env)
        result = run("(reduce + 0 (quote (1 2 3 4 5)))", env)
        assert result == 15
        result = run("(reduce * 1 (quote (1 2 3 4 5)))", env)
        assert result == 120


class TestEdgeCases:
    """Test edge cases."""

    def test_empty_begin(self):
        """Test empty begin."""
        assert run("(begin)") is None

    def test_empty_and(self):
        """Test empty and."""
        assert run("(and)") is True

    def test_empty_or(self):
        """Test empty or."""
        assert run("(or)") is False

    def test_single_element_list(self):
        """Test single element list operations."""
        assert run("(car (quote (1)))") == 1
        assert run("(cdr (quote (1)))") == []

    def test_nested_quote(self):
        """Test nested quote."""
        result = run("(quote (quote (1 2 3)))")
        assert result == ['quote', [1, 2, 3]]

    def test_boolean_in_arithmetic(self):
        """Test boolean values in context."""
        # True and False should work in conditionals
        assert run("(if true 1 2)") == 1
        assert run("(if false 1 2)") == 2

    def test_float_comparison(self):
        """Test floating point comparison."""
        assert run("(< 3.14 3.15)") is True
        assert run("(> 3.14 3.13)") is True

    def test_mixed_int_float_arithmetic(self):
        """Test mixed integer and float arithmetic."""
        result = run("(+ 1 2.5)")
        assert result == 3.5

    def test_zero_division(self):
        """Test division by zero."""
        with pytest.raises(Exception):  # ZeroDivisionError wrapped
            run("(/ 1 0)")

    def test_multiple_expressions_return_last(self):
        """Test that multiple expressions return the last value."""
        env = Environment()
        result = run("(define x 1) (define y 2) (+ x y)", env)
        assert result == 3
