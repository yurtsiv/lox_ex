defmodule Lox.Runner do
  alias Lox.Scanner
  def run(source) do
    Scanner.run(source)
    |> IO.inspect()
  end
end
