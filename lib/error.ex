defmodule Lox.Error do
  def report(line, message) do
    IO.puts("[line #{line}] Error: #{message}")
  end
end
