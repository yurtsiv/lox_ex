defmodule Lox.ScannerTest do
  use ExUnit.Case
  alias Lox.Scanner
  alias Lox.Token
  alias Lox.Token.Type

  test "recognizes all tokens" do
    assert {:ok, tokens} =
             Scanner.run("""
             ( ) { } , . - + ; * / ! != = == > >= < <=
             identifier \"string\" 123 123.2 true false
             and or if else class fun for
             nil print return super this var while
             """)

    assert [
             Type.left_paren(),
             Type.right_paren(),
             Type.left_brace(),
             Type.right_brace(),
             Type.comma(),
             Type.dot(),
             Type.minus(),
             Type.plus(),
             Type.semicolon(),
             Type.star(),
             Type.slash(),
             Type.bang(),
             Type.bang_equal(),
             Type.equal(),
             Type.equal_equal(),
             Type.greater(),
             Type.greater_equal(),
             Type.less(),
             Type.less_equal(),
             Type.identifier(),
             Type.string(),
             Type.number(),
             Type.number(),
             Type.lox_true(),
             Type.lox_false(),
             Type.and(),
             Type.or(),
             Type.if(),
             Type.else(),
             Type.class(),
             Type.fun(),
             Type.for(),
             Type.lox_nil(),
             Type.print(),
             Type.return(),
             Type.super(),
             Type.this(),
             Type.var(),
             Type.while(),
             Type.eof()
           ] == Enum.map(tokens, & &1.type)
  end

  test "skips whitespaces" do
    assert {:ok, [_, _, _]} = Scanner.run("x \r\t\ny")
  end

  test "skips comments" do
    assert {:ok, [_, _, _, _]} =
             Scanner.run("""
             a
             // comment
             b
             // comment
             // comment
             c
             """)
  end

  test "counts line numbers correctly" do
    {:ok,
     [
       %Token{line: 1},
       %Token{line: 4},
       %Token{line: 5},
       %Token{line: 5},
       %Token{line: 7},
       %Token{line: 9},
       _
     ]} =
      Scanner.run("""
      a
      // comment
      // comment
      b
      string = "
      test
      "

      c
      """)
  end

  test "fails on invalid characters" do
    assert :error = Scanner.run("(╯°□°）╯︵ ┻━┻")
  end

  test "fails on unterminated strings" do
    assert :error = Scanner.run("s = \"string")
  end
end
