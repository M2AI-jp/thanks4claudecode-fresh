#!/usr/bin/env python3
"""FizzBuzz implementation."""


def fizzbuzz(n: int) -> str:
    """Return FizzBuzz result for a given number."""
    if n % 15 == 0:
        return "FizzBuzz"
    elif n % 3 == 0:
        return "Fizz"
    elif n % 5 == 0:
        return "Buzz"
    else:
        return str(n)


def main():
    """Print FizzBuzz for numbers 1 to 100."""
    for i in range(1, 101):
        print(fizzbuzz(i))


if __name__ == "__main__":
    main()
