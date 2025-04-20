defmodule Lox.Token do
  defstruct [:type, :lexeme, :literal, :line]

  defmodule Type do
    types = [
      :left_paren,
      :right_paren,
      :left_brace,
      :right_brace,
      :comma,
      :dot,
      :minus,
      :plus,
      :semicolon,
      :slash,
      :star,
      :eof,

      # One or two character tokens
      :bang,
      :bang_equal,
      :equal,
      :equal_equal,
      :greater,
      :greater_equal,
      :less,
      :less_equal,

      # Literals
      :identifier,
      :string,
      :number,

      # Keywords
      :and,
      :or,
      :if,
      :else,
      :lox_true,
      :lox_false,
      :class,
      :fun,
      :for,
      :lox_nil,
      :print,
      :return,
      :super,
      :this,
      :var,
      :while
    ]

    for type <- types do
      def unquote(type)(), do: unquote(type)
    end
  end
end
