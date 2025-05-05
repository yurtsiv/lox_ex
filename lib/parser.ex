defmodule Lox.Parser do
  @doc """
  Recursive descent parser for the following grammar:

  expression     → equality ;
  equality       → comparison ( ( "!=" | "==" ) comparison )* ;
  comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  term           → factor ( ( "-" | "+" ) factor )* ;
  factor         → unary ( ( "/" | "*" ) unary )* ;
  unary          → ( "!" | "-" ) unary
                   | primary ;
  primary        → NUMBER | STRING | "true" | "false" | "nil"
                   | "(" expression ")" ;
  """

  alias Lox.Error
  alias Lox.Expression, as: Expr
  alias Lox.Token
  alias Lox.Token.Type

  @spec parse(tokens: [Token.t()]) :: {:ok, Expr.t()} | :error
  def parse(tokens) do
    try do
      {expr, _} =
        expression(%{
          current: 0,
          tokens: tokens,
          tokens_count: Enum.count(tokens)
        })

      {:ok, expr}
    rescue
      parse_error ->
        %Error.ParseError{state: state} = parse_error

        IO.puts("Synchronized state")
        synchronize(state) |> IO.inspect()

        :error
    end
  end

  defp expression(state), do: equality(state)

  defp equality(state) do
    {expr, state} = comparison(state)

    Enum.reduce_while(state.current..state.tokens_count, %{expr: expr, state: state}, fn _, acc ->
      case match([Type.bang_equal(), Type.equal_equal()], acc.state) do
        {true, state} ->
          operator = previous(state)
          {right, state} = comparison(state)

          expr = %Expr.Binary{left: acc.expr, operator: operator, right: right}

          {:cont, %{expr: expr, state: state}}

        {false, _} ->
          {:halt, acc}
      end
    end)
    |> then(&{&1.expr, &1.state})
  end

  defp comparison(state) do
    {expr, state} = term(state)

    Enum.reduce_while(state.current..state.tokens_count, %{expr: expr, state: state}, fn _, acc ->
      case match([Type.greater(), Type.greater_equal(), Type.less_equal()], acc.state) do
        {true, state} ->
          operator = previous(state)
          {right, state} = term(state)

          expr = %Expr.Binary{left: acc.expr, operator: operator, right: right}

          {:cont, %{expr: expr, state: state}}

        {false, _} ->
          {:halt, acc}
      end
    end)
    |> then(&{&1.expr, &1.state})
  end

  defp term(state) do
    {expr, state} = factor(state)

    Enum.reduce_while(state.current..state.tokens_count, %{expr: expr, state: state}, fn _, acc ->
      case match([Type.minus(), Type.plus()], acc.state) do
        {true, state} ->
          operator = previous(state)
          {right, state} = factor(state)

          expr = %Expr.Binary{left: acc.expr, operator: operator, right: right}

          {:cont, %{expr: expr, state: state}}

        {false, _} ->
          {:halt, acc}
      end
    end)
    |> then(&{&1.expr, &1.state})
  end

  defp factor(state) do
    {expr, state} = unary(state)

    Enum.reduce_while(state.current..state.tokens_count, %{expr: expr, state: state}, fn _, acc ->
      case match([Type.slash(), Type.star()], acc.state) do
        {true, state} ->
          operator = previous(state)
          {right, state} = unary(state)

          expr = %Expr.Binary{left: acc.expr, operator: operator, right: right}

          {:cont, %{expr: expr, state: state}}

        {false, _} ->
          {:halt, acc}
      end
    end)
    |> then(&{&1.expr, &1.state})
  end

  defp unary(state) do
    case match([Type.bang(), Type.minus()], state) do
      {true, state} ->
        operator = previous(state)
        {right, state} = unary(state)
        expr = %Expr.Unary{operator: operator, right: right}
        {expr, state}

      {false, state} ->
        primary(state)
    end
  end

  defp primary(state) do
    [
      {
        Type.lox_false(),
        fn state ->
          {%Expr.Literal{value: false}, state}
        end
      },
      {
        Type.lox_true(),
        fn state ->
          {%Expr.Literal{value: true}, state}
        end
      },
      {
        Type.lox_nil(),
        fn state ->
          {%Expr.Literal{value: nil}, state}
        end
      },
      {
        [Type.number(), Type.string()],
        fn state ->
          {%Expr.Literal{value: previous(state).literal}, state}
        end
      },
      {
        Type.left_paren(),
        fn state ->
          {expr, state} = expression(state)
          state = consume(Type.right_paren(), state, "Expect ')' after expression.")
          {%Expr.Grouping{expression: expr}, state}
        end
      }
    ]
    |> Enum.find_value(fn {type_or_types, handler} ->
      type_or_types
      |> List.wrap()
      |> match(state)
      |> case do
        {true, state} ->
          handler.(state)

        _ ->
          false
      end
    end)
    |> case do
      nil ->
        error(state, "Expect expression.")

      res ->
        res
    end
  end

  defp consume(type, state, error_message) do
    if check(type, state) do
      advance(state)
    else
      error(peek(state), error_message)
    end
  end

  defp error(state, error_message) do
    token = peek(state)

    Error.report(token, error_message)

    raise Error.ParseError, state: state
  end

  defp match(types, state) do
    types
    |> Enum.any?(&check(&1, state))
    |> case do
      false -> {false, state}
      true -> {true, advance(state)}
    end
  end

  defp check(type, state) do
    if is_at_end(state) do
      false
    else
      peek(state).type == type
    end
  end

  defp advance(state) do
    %{state | current: state.current + 1}
  end

  defp peek(state), do: Enum.at(state.tokens, state.current)

  defp previous(state), do: Enum.at(state.tokens, state.current - 1)

  defp is_at_end(state), do: state.current >= state.tokens_count

  defp synchronize(state) do
    state = advance(state)

    Enum.reduce_while(state.current..state.tokens_count, state, fn _, state ->
      cond do
        is_at_end(state) ->
          {:halt, state}

        is_sync_point(state) ->
          {:halt, state}

        true ->
          {:cont, advance(state)}
      end
    end)
  end

  defp is_sync_point(state) do
    previous(state).type == Type.semicolon() or
      peek(state).type in [
        Type.class(),
        Type.fun(),
        Type.var(),
        Type.for(),
        Type.if(),
        Type.while(),
        Type.print(),
        Type.return()
      ]
  end
end
