defmodule Lox.Interpreter do
  alias Lox.Expression, as: Expr
  use Lox.Token.Type

  def evaluate(%Expr.Unary{operator: operator, right: right}) do
    right = evaluate(right)

    case operator.type do
      Type.minus() ->
        -right

      Type.bang() ->
        is_truthy(right)

      _ ->
        nil
    end
  end

  def evaluate(%Expr.Binary{operator: operator, left: left, right: right}) do
    left = evaluate(left)
    right = evaluate(right)

    case operator.type do
      Type.greater() ->
        left > right

      Type.greater_equal() ->
        left >= right

      Type.less() ->
        left < right

      Type.less_equal() ->
        left <= right

      Type.bang_equal() ->
        left != right

      Type.equal_equal() ->
        left == right

      Type.minus() ->
        left - right

      Type.plus() ->
        evaluate_plus(left, right)

      Type.slash() ->
        left / right

      Type.star() ->
        left * right
    end
  end

  def evaluate(%Expr.Literal{value: value}), do: value

  defp is_truthy(nil), do: false
  defp is_truthy(value) when is_boolean(value), do: value
  defp is_truthy(_value), do: true

  defp evaluate_plus(left, right) when is_binary(left) and is_binary(right) do
    "#{left}#{right}"
  end

  defp evaluate_plus(left, right) do
    left + right
  end
end
