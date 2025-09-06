defmodule Lox.Runner do
  alias Lox.Scanner
  alias Lox.Parser
  alias Lox.Interpreter
  alias Lox.AstPrinter

  def run(source) do
    with {:scan, {:ok, tokens}} <- {:scan, Scanner.run(source)},
         {:parse, {:ok, ast}} <- {:parse, Parser.parse(tokens)},
         {:run, {:ok, result}} <- {:run, Interpreter.run(ast)} do
      IO.puts("AST: #{AstPrinter.print(ast)}")
      IO.puts("Result: #{result}")
    else
      {:scan, _} -> :scan_error
      {:parse, _} -> :parse_error
      {:run, _} -> :runtime_error
    end
  end
end
