defmodule Lox.Runner do
  alias Lox.Scanner
  alias Lox.Parser
  alias Lox.AstPrinter

  def run(source) do
    with {:scan, {:ok, tokens}} <- {:scan, Scanner.run(source)},
         {:parse, {:ok, ast}} <- {:parse, Parser.parse(tokens)} do
      IO.puts(AstPrinter.print(ast))
    else
      _ -> :error
    end
  end
end
