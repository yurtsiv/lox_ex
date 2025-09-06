defmodule Lox.Interpreter do
  alias Lox.Expression, as: Expr
  alias Lox.Error

  use Lox.Token.Type

  def run(expression) do
    try do
      res = evaluate(expression)

      {:ok, res}
    rescue
      runtime_error ->
        Error.report(runtime_error)
        :error
    end
  end

  defp evaluate(%Expr.Unary{operator: operator, right: right}) do
    right = evaluate(right)

    case operator.type do
      Type.minus() ->
        check_number_operand(operator, right)

        -right

      Type.bang() ->
        is_truthy(right)

      _ ->
        nil
    end
  end

  defp evaluate(%Expr.Binary{operator: operator, left: left, right: right}) do
    left = evaluate(left)
    right = evaluate(right)

    case operator.type do
      Type.greater() ->
        check_number_operands(operator, left, right)

        left > right

      Type.greater_equal() ->
        check_number_operands(operator, left, right)

        left >= right

      Type.less() ->
        check_number_operands(operator, left, right)

        left < right

      Type.less_equal() ->
        check_number_operands(operator, left, right)

        left <= right

      Type.bang_equal() ->
        left != right

      Type.equal_equal() ->
        left == right

      Type.minus() ->
        check_number_operands(operator, left, right)

        left - right

      Type.plus() ->
        evaluate_plus(operator, left, right)

      Type.slash() ->
        check_number_operands(operator, left, right)

        if right == 0 do
          raise Error.RuntimeError, token: operator, message: "Division by zero"
        end

        left / right

      Type.star() ->
        check_number_operands(operator, left, right)

        left * right
    end
  end

  defp evaluate(%Expr.Literal{value: value}), do: value

  defp is_truthy(nil), do: false
  defp is_truthy(value) when is_boolean(value), do: value
  defp is_truthy(_value), do: true

  defp evaluate_plus(_token, left, right)
       when (is_binary(left) and is_binary(right)) or (is_binary(left) and is_number(right)) or
              (is_number(left) and is_binary(right)) do
    "#{number_to_string(left)}#{number_to_string(right)}"
  end

  defp evaluate_plus(_token, left, right) when is_number(left) and is_number(right) do
    left + right
  end

  defp evaluate_plus(token, _left, _right) do
    raise Error.RuntimeError, token: token, message: "Operands must be numbers or strings"
  end

  defp check_number_operand(token, operand) do
    if not is_number(operand) do
      raise Error.RuntimeError, token: token, message: "Operand must be a number"
    end
  end

  defp check_number_operands(token, left, right) do
    cond do
      not is_number(left) and not is_number(right) -> "Operands must be numbers"
      not is_number(left) -> "Left operand must be a number"
      not is_number(right) -> "Right operand must be a number"
      true -> nil
    end
    |> case do
      nil ->
        nil

      message ->
        raise Error.RuntimeError, token: token, message: message
    end
  end

  defp number_to_string(number) when is_number(number) do
    String.trim_trailing("#{number}", ".0")
  end

  defp number_to_string(number) when is_binary(number), do: number
end
