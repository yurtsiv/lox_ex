defmodule Lox do
  use Application

  # https://man.freebsd.org/cgi/man.cgi?query=sysexits&apropos=0&sektion=0&manpath=FreeBSD+4.3-RELEASE&format=html
  @exit_codes %{
    incorrect_command: 64,
    compile_error: 65,
    file_not_found: 66,
    runtime_error: 70
  }

  def start(_type, _args) do
    if Mix.env() != :test do
      start_cmd()
    end

    {:ok, self()}
  end

  def start_cmd do
    case System.argv() do
      [] ->
        Lox.Repl.run()

      [path] ->
        run_file(path)

      _ ->
        IO.puts("Usage: mix run -- [script]")
        kill(@exit_codes.incorrect_command)
    end

    {:ok, self()}
  end

  defp run_file(path) do
    case File.read(path) do
      {:ok, source} ->
        run_source(source)

      _ ->
        IO.puts("File not found")
        kill(@exit_codes.file_not_found)
    end
  end

  defp run_source(source) do
    case Lox.Runner.run(source) do
      :scan_error -> kill(@exit_codes.compile_error)
      :parse_error -> kill(@exit_codes.compile_error)
      :runtime_error -> kill(@exit_codes.runtime_error)
      _ -> :ok
    end
  end

  defp kill(exit_code), do: System.halt(exit_code)
end
