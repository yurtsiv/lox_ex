defmodule Lox.InterpreterTest do
  use ExUnit.Case

  alias Lox.Scanner
  alias Lox.Parser
  alias Lox.Interpreter

  @error_messages Interpreter.error_messages()

  test "literal" do
    assert {:ok, 1.0} = run("1")
    assert {:ok, "test"} = run("\"test\"")
  end

  test "unary minus" do
    assert {:ok, -1.0} = run("-1")
    assert {:ok, -0.0} = run("-0")

    {:error, error} = run("-\"a\"")
    assert error.message == @error_messages.operand_number
  end

  test "bang" do
    assert {:ok, true} = run("!false")
    assert {:ok, false} = run("!true")
    assert {:ok, true} = run("!nil")
    assert {:ok, false} = run("!0")
    assert {:ok, false} = run("!1")
    assert {:ok, false} = run("!-1")
    assert {:ok, false} = run("!\"\"")
    assert {:ok, false} = run("!\"\test\"")
  end

  test "number operands" do
    for [operator_name, operator] <- [
          ["greater", ">"],
          ["greater equal", ">="],
          ["less", ">"],
          ["less equal", ">="],
          ["binary minus", "-"],
          ["slash", "/"]
        ] do
      {:error, error} = run("1 #{operator} \"\"")
      assert error.message == @error_messages.right_operand_number, "#{operator_name} right"

      {:error, error} = run("\"\" #{operator} 1")
      assert error.message == @error_messages.left_operand_number, "#{operator_name} left"

      {:error, error} = run("\"\" #{operator} \"\"")
      assert error.message == @error_messages.operands_numbers, "#{operator_name} both"
    end
  end

  test "greater" do
    check_number_operands(">")
    assert {:ok, true} = run("2 > 1")
    assert {:ok, false} = run("0 > 0.0")
    assert {:ok, false} = run("-0.0 > 0")
    assert {:ok, false} = run("1 > 2")
    assert {:ok, false} = run("1 > 1")
  end

  test "greater equal" do
    check_number_operands(">=")
    assert {:ok, true} = run("2 >= 1")
    assert {:ok, true} = run("0 >= 0.0")
    assert {:ok, true} = run("-0.0 >= 0")
    assert {:ok, true} = run("1 >= 1")
    assert {:ok, false} = run("1 >= 2")
  end

  test "less" do
    check_number_operands("<")
    assert {:ok, false} = run("2 < 1")
    assert {:ok, false} = run("0 < 0.0")
    assert {:ok, false} = run("-0.0 < 0")
    assert {:ok, true} = run("1 < 2")
    assert {:ok, false} = run("1 < 1")
  end

  test "less equal" do
    check_number_operands("<=")
    assert {:ok, false} = run("2 <= 1")
    assert {:ok, true} = run("0 <= 0.0")
    assert {:ok, true} = run("-0.0 <= 0")
    assert {:ok, true} = run("1 <= 1")
    assert {:ok, true} = run("1 <= 2")
  end

  defp check_number_operands(operator) do
    {:error, error} = run("1 #{operator} \"\"")
    assert error.message == @error_messages.right_operand_number, "#{operator} right"

    {:error, error} = run("\"\" #{operator} 1")
    assert error.message == @error_messages.left_operand_number, "#{operator} left"

    {:error, error} = run("\"\" #{operator} \"\"")
    assert error.message == @error_messages.operands_numbers, "#{operator} both"
  end

  defp run(source) do
    {:ok, tokens} = Scanner.run(source)
    {:ok, ast} = Parser.parse(tokens)

    Interpreter.run(ast)
  end
end
