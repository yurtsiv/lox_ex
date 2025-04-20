defmodule Lox.Repl do
  def run do
    case IO.gets("> ") do
      {:error, _} ->
        :ok

      :eof ->
        :ok

      line ->
        Lox.Runner.run(line)
        run()
    end
  end
end
