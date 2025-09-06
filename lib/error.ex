defmodule Lox.Error do
  alias Lox.Token
  alias Lox.Error

  use Lox.Token.Type

  defmodule ParseError do
    defexception [:state, :token, message: "Parse error"]
  end

  defmodule RuntimeError do
    defexception [:token, :type, message: "Runtime error"]
  end

  def report(%Error.ParseError{} = error) do
    report(error.token, error.message)
  end

  def report(%Error.RuntimeError{} = error) do
    report(error.token, error.message)
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
