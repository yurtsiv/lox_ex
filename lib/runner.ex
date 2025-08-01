defmodule Lox.Runner do
  alias Lox.Scanner
  alias Lox.Parser
  alias Lox.Interpreter
  alias Lox.AstPrinter

  def run(source) do
    with {:scan, {:ok, tokens}} <- {:scan, Scanner.run(source)},
         {:parse, {:ok, ast}} <- {:parse, Parser.parse(tokens)} do
      IO.puts("AST: #{AstPrinter.print(ast)}")
      IO.puts("Result: #{Interpreter.evaluate(ast)}")
    else
      _ -> :error
    end
  end
end
