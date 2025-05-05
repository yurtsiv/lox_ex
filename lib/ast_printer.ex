defmodule Lox.AstPrinter do
  alias Lox.Expression, as: Expr

  def print(%Expr{body: body}) do
    print(body)
  end

  def print(%Expr.Binary{left: left, operator: operator, right: right}) do
    parenthesize(operator.lexeme, [left, right])
  end

  def print(%Expr.Grouping{expression: expr}) do
    parenthesize("group", [expr])
  end

  def print(%Expr.Literal{value: value}) do
    "#{value || "nil"}"
  end

  def print(%Expr.Unary{operator: operator, right: right}) do
    parenthesize(operator.lexeme, [right])
  end

  def parenthesize(name, exprs) do
    exprs
    |> Enum.map(&print/1)
    |> Enum.join(" ")
    |> then(&"(#{name} #{&1})")
  end
end
