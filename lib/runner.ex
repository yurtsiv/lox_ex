defmodule Lox.Runner do
  alias Lox.Scanner
  alias Lox.Parser
  alias Lox.Interpreter
  alias Lox.AstPrinter

  def run(source) do
    with {:ok, tokens} <- Scanner.run(source),
         {:ok, ast} <- Parser.parse(tokens),
         {:ok, result} <- Interpreter.run(ast) do
      IO.puts("AST: #{AstPrinter.print(ast)}")
      IO.puts("Result: #{result}")
    else
      _ -> :error
    end
  end
end
