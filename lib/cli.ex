defmodule RedPill.CLI do
  @moduledoc """
  Application entrypoint.
  """

  alias RedPill.{Evaluator, LineCommenter}

  def main([]), do: "No file specified"

  def main([file | _rest]) do
    case File.read(file) do
      {:ok, content} ->
        content
        |> Evaluator.evaluate()
        |> LineCommenter.comment_lines()
        |> IO.puts()

      {:error, :enoent} ->
        "File not found"
    end
  end
end
