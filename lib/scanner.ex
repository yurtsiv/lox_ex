defmodule Lox.Scanner do
  alias Lox.Error
  alias Lox.Token
  use Lox.Token.Type

  @keywords %{
    "and" => Type.and(),
    "or" => Type.or(),
    "if" => Type.if(),
    "else" => Type.else(),
    "true" => Type.lox_true(),
    "false" => Type.lox_false(),
    "class" => Type.class(),
    "fun" => Type.fun(),
    "for" => Type.for(),
    "nil" => Type.lox_nil(),
    "print" => Type.print(),
    "return" => Type.return(),
    "super" => Type.super(),
    "this" => Type.this(),
    "var" => Type.var(),
    "while" => Type.while()
  }

  def run(source) do
    Enum.reduce_while(
      0..String.length(source),
      %{
        line: 1,
        start: 0,
        current: 0,
        tokens: [],
        source: source,
        has_error: false
      },
      fn _, state ->
        next_state = scan_token(state)

        if is_at_end(next_state) do
          {:halt, next_state}
        else
          {:cont, %{next_state | start: next_state.current}}
        end
      end
    )
    |> case do
      %{tokens: tokens, has_error: false} ->
        {:ok,
         [%Token{type: Type.eof()} | tokens]
         |> Enum.reverse()}

      _ ->
        :error
    end
  end

  defguard is_digit_guard(c) when c >= "0" and c <= "9"
  defp is_digit(c) when is_digit_guard(c), do: true
  defp is_digit(_c), do: false

  defguard is_alpha_guard(c) when (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"
  defp is_alpha(c) when is_alpha_guard(c), do: true
  defp is_alpha(_c), do: false

  defp is_alpha_numeric(c), do: is_digit(c) or is_alpha(c)

  defp scan_token(state) do
    state = advance(state)
    char = String.at(state.source, state.current - 1)

    case char do
      "(" ->
        add_token(state, Type.left_paren())

      ")" ->
        add_token(state, Type.right_paren())

      "{" ->
        add_token(state, Type.left_brace())

      "}" ->
        add_token(state, Type.right_brace())

      "," ->
        add_token(state, Type.comma())

      "." ->
        add_token(state, Type.dot())

      "-" ->
        add_token(state, Type.minus())

      "+" ->
        add_token(state, Type.plus())

      ";" ->
        add_token(state, Type.semicolon())

      "*" ->
        add_token(state, Type.star())

      "!" ->
        case match(state, "=") do
          {true, state} ->
            add_token(state, Type.bang_equal())

          {false, state} ->
            add_token(state, Type.bang())
        end

      "=" ->
        case match(state, "=") do
          {true, state} ->
            add_token(state, Type.equal_equal())

          {false, state} ->
            add_token(state, Type.equal())
        end

      "<" ->
        case match(state, "=") do
          {true, state} ->
            add_token(state, Type.less_equal())

          {false, state} ->
            add_token(state, Type.less())
        end

      ">" ->
        case match(state, "=") do
          {true, state} ->
            add_token(state, Type.greater_equal())

          {false, state} ->
            add_token(state, Type.greater())
        end

      "/" ->
        case match(state, "/") do
          {true, state} -> skip_until(state, "\n")
          {false, state} -> add_token(state, Type.slash())
        end

      space when space in [" ", "\r", "\t"] ->
        state

      "\n" ->
        inc_line(state)

      "\"" ->
        string(state)

      char when is_digit_guard(char) ->
        number(state)

      char when is_alpha_guard(char) ->
        identifier(state)

      _ ->
        Error.report(state.line, "Unexpected character #{char}")
        put_error(state)
    end
  end

  defp string(state) do
    cond do
      is_at_end(state) ->
        Error.report(state.line, "Unterminated string")

        put_error(state)

      peek(state) == "\"" ->
        state = advance(state)

        slice_from = state.start + 1
        slice_to = state.current - 2

        add_token(
          state,
          Type.string(),
          if slice_to < slice_from do
            ""
          else
            String.slice(state.source, slice_from..slice_to)
          end
        )

      true ->
        if peek(state) == "\n" do
          inc_line(state)
        else
          state
        end
        |> advance()
        |> string()
    end
  end

  defp number(state) do
    state =
      state
      |> advance_while(&(peek(&1) |> is_digit()))
      |> then(fn state ->
        if peek(state) == "." and peek_next(state) |> is_digit() do
          advance(state)
        else
          state
        end
      end)
      |> advance_while(&(peek(&1) |> is_digit()))

    add_token(
      state,
      Type.number(),
      state.source
      |> String.slice(state.start..(state.current - 1))
      |> Float.parse()
      |> then(&elem(&1, 0))
    )
  end

  defp identifier(state) do
    state =
      state
      |> advance_while(&(peek(&1) |> is_alpha_numeric()))

    lexeme = String.slice(state.source, state.start..(state.current - 1))

    add_token(state, Map.get(@keywords, lexeme, Type.identifier()))
  end

  defp add_token(state, type, literal \\ nil) do
    token = %Token{
      type: type,
      lexeme: String.slice(state.source, state.start..(state.current - 1)),
      literal: literal,
      line: state.line
    }

    %{state | tokens: [token | state.tokens]}
  end

  defp advance(state) do
    %{state | current: state.current + 1}
  end

  defp match(state, expected) do
    cond do
      is_at_end(state) ->
        {false, state}

      peek(state) == expected ->
        {
          true,
          %{state | current: state.current + 1}
        }

      true ->
        {false, state}
    end
  end

  defp peek(state), do: String.at(state.source, state.current)

  defp peek_next(state) do
    if state.current + 1 >= String.length(state.source) do
      "\0"
    else
      String.at(state.source, state.current + 1)
    end
  end

  defp is_at_end(state), do: state.current >= String.length(state.source)

  defp skip_until(state, char) do
    if peek(state) == char do
      state
    else
      state
      |> advance()
      |> skip_until(char)
    end
  end

  defp advance_while(state, predicate) do
    if predicate.(state) do
      state
      |> advance()
      |> advance_while(predicate)
    else
      state
    end
  end

  defp inc_line(state), do: %{state | line: state.line + 1}

  defp put_error(state), do: %{state | has_error: true}
end
