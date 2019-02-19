defmodule RedPill.Evaluator do
  @moduledoc """
  Evaluates a file content.
  """

  @type ast() :: {atom(), [...], [ast()]}
  @type line_with_result() :: {String.t(), any()}

  @spec evaluate(String.t()) :: [line_with_result()]
  def evaluate(file_content) do
    with {:ok, ast} <- Code.string_to_quoted(file_content, formatter_metadata: true) do
      file_content_as_list = String.split(file_content, "\n")

      ast
      |> break_into_lines()
      |> evaluate_ast_map()
      |> link_to_original_file(file_content_as_list)
    end
  end

  @spec break_into_lines(ast()) :: %{pos_integer() => ast()}
  defp break_into_lines({:__block__, [], asts}), do: break_into_lines(asts)

  defp break_into_lines({cmd, meta, children} = ast) when is_atom(cmd) do
    line = Keyword.get(meta, :line)

    Map.merge(break_into_lines(children), %{line => ast})
  end

  defp break_into_lines([{_cmd, meta, children} = ast | tail]) do
    line = Keyword.get(meta, :line)
    current = Map.merge(break_into_lines(children), %{line => ast})

    Map.merge(break_into_lines(tail), current)
  end

  defp break_into_lines([]), do: %{}
  defp break_into_lines(_), do: %{}

  @spec evaluate_ast_map(map() | [{String.t(), ast()}]) :: [{integer(), any()}]
  defp evaluate_ast_map(ast_map, bindings \\ [], acc \\ [])

  defp evaluate_ast_map([], _bindings, acc), do: Enum.reverse(acc)

  defp evaluate_ast_map(ast_map, _, _) when is_map(ast_map) do
    evaluate_ast_map(Map.to_list(ast_map))
  end

  defp evaluate_ast_map([{line, ast} | tail], bindings, acc) do
    ast_with_replacements = replace_previous_lines(ast, line, acc)

    {result, new_bindings} = Code.eval_quoted(ast_with_replacements, bindings)

    evaluate_ast_map(tail, new_bindings, [{line, result} | acc])
  end

  @spec replace_previous_lines(ast(), pos_integer(), [any()]) :: ast()
  defp replace_previous_lines({_, _, nil} = ast, _, _), do: ast

  defp replace_previous_lines({cmd, meta, params}, line, previous_results) when is_list(params) do
    new_params =
      params
      |> Enum.map(fn param ->
        case param do
          {:.., _, _} = param ->
            param

          {_, param_meta, _} ->
            param_line = Keyword.get(param_meta, :line)

            if param_line < line do
              {_, new_param} =
                Enum.find(
                  previous_results,
                  fn {result_line, _} -> result_line == param_line end
                )

              if Macro.quoted_literal?(new_param) do
                new_param
              else
                param
              end
            else
              param
            end
        end
      end)

    {cmd, meta, new_params}
  end

  @spec link_to_original_file([{pos_integer(), String.t()}], [String.t()], pos_integer()) :: [
          {String.t(), String.t()}
        ]
  defp link_to_original_file(_, _, current_line \\ 1)
  defp link_to_original_file([], _, _), do: []

  defp link_to_original_file([{line, result} | tail], file_lines_as_list, current_line)
       when line == current_line do
    [
      {Enum.at(file_lines_as_list, current_line - 1), result}
      | link_to_original_file(tail, file_lines_as_list, current_line + 1)
    ]
  end

  defp link_to_original_file(
         [{line, _result} | _tail] = results,
         file_lines_as_list,
         current_line
       )
       when line > current_line do
    [
      {Enum.at(file_lines_as_list, current_line - 1), ""}
      | link_to_original_file(results, file_lines_as_list, current_line + 1)
    ]
  end
end
