defmodule Lox.Error do
  alias Lox.Token
  use Lox.Token.Type

  defmodule ParseError do
    defexception [:state, message: "prase error"]
  end

  def report(%Token{} = token, message) do
    if token.type == Type.eof() do
      report(token.line, " at end", message)
    else
      report(token.line, " at '#{token.lexeme}'", message)
    end
  end

  def report(line, message) do
    report(line, "", message)
  end

  def report(line, where, message) do
    IO.puts("[line #{line}] Error#{where}: #{message}")
  end
end
