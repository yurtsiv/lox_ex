defmodule Lox do
  use Application

  def start(_type, _args) do
    case System.argv() do
      [] ->
        Lox.Repl.run()

      [path] ->
        run_file(path)

      _ ->
        IO.puts("Usage: mix run -- [script]")
    end

    {:ok, self()}
  end

  defp run_file(path) do
    case File.read(path) do
      {:ok, script} -> Lox.Runner.run(script)
      _ -> IO.puts("Invalid file")
    end
  end
end
