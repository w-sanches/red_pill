defmodule RedPill.LineCommenter do
  @moduledoc """
  Adds comments with results to the correct line in a document.
  """

  alias RedPill.Evaluator

  @type chunk() :: {Evaluator.line_with_result(), non_neg_integer()}
  @type length() :: non_neg_integer()

  @line_ending_mark "#=>"
  @line_ending_mark_length String.length(@line_ending_mark)

  @spec comment_lines([Evaluator.line_with_result()]) :: String.t()
  def comment_lines(lines) do
    lines
    |> divide_in_chunks()
    |> chunks_to_max_length()
    |> write_comments()
    |> Enum.join("\n")
  end

  @spec divide_in_chunks([Evaluator.line_with_result()], non_neg_integer()) :: [chunk()]
  defp divide_in_chunks(list, chunk \\ 0)
  defp divide_in_chunks([], _index), do: []
  defp divide_in_chunks([{"", ""} | tail], chunk), do: ["" | divide_in_chunks(tail, chunk + 1)]

  defp divide_in_chunks([{line, _comment} = head | tail], chunk) do
    if String.ends_with?(line, @line_ending_mark) do
      [{head, chunk} | divide_in_chunks(tail, chunk)]
    else
      [{head, chunk + 1} | divide_in_chunks(tail, chunk + 1)]
    end
  end

  @spec chunks_to_max_length([chunk()]) :: [{Evaluator.line_with_result(), length()} | String.t()]
  defp chunks_to_max_length(chunks) do
    chunks
    |> Enum.chunk_by(fn line ->
      case line do
        {_, index} -> index
        _ -> true
      end
    end)
    |> Enum.map(&chunk_to_max_length/1)
    |> Enum.flat_map(fn x -> x end)
  end

  defp chunk_to_max_length([""]), do: [""]

  defp chunk_to_max_length(chunk) do
    max_length =
      chunk
      |> Enum.map(fn {{line, _comment}, _index} -> String.length(line) end)
      |> Enum.max()

    Enum.map(chunk, fn {line, _index} -> {line, max_length} end)
  end

  @spec write_comments([{Evaluator.line_with_result(), length()} | String.t()]) :: [String.t()]
  defp write_comments([]), do: []
  defp write_comments(["" | tail]), do: ["" | write_comments(tail)]

  defp write_comments([{{line, comment}, length} | tail]) do
    new_line =
      if String.ends_with?(line, @line_ending_mark) do
        line
        |> String.slice(0..-(1 + @line_ending_mark_length))
        |> String.pad_trailing(length - @line_ending_mark_length)
        |> Kernel.<>("#{@line_ending_mark} #{inspect(comment)}")
      else
        line
      end

    [new_line | write_comments(tail)]
  end
end
