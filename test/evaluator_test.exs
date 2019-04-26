defmodule RedPill.EvaluatorTest do
  use ExUnit.Case

  alias RedPill.Evaluator

  describe "evaluate/1" do
    test "evaluates a statement" do
      code = """
      a = 1 + 1
      """

      evaluated_code = [
        {"a = 1 + 1", 2}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "evaluates multi-line statements" do
      code = """
      0..2
      |> Enum.join(",")
      """

      evaluated_code = [
        {"0..2", 0..2},
        {"|> Enum.join(\",\")", "0,1,2"}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "evaluates range assignments" do
      code = """
      x = 0..3
      x
      |> Enum.max()
      """

      evaluated_code = [
        {"x = 0..3", 0..3},
        {"x", 0..3},
        {"|> Enum.max()", 3}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "evaluates multiple statements" do
      code = """
      a = 0..2
      b = 0..3
      """

      evaluated_code = [
        {"a = 0..2", 0..2},
        {"b = 0..3", 0..3}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "keeps track of variables" do
      code = """
      a = 1
      a = a + 1
      a = a + 1
      """

      evaluated_code = [
        {"a = 1", 1},
        {"a = a + 1", 2},
        {"a = a + 1", 3}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "pipe starting with list" do
      code = """
      [1, 2, 3]
      |> Enum.map(fn val -> val * 2 end)
      """

      evaluated_code = [
        {"[1, 2, 3]", [1, 2, 3]},
        {"|> Enum.map(fn val -> val * 2 end)", [2, 4, 6]}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end

    test "correctly handles multilined functions" do
      code = """
      [1, 2, 3]
      |> Enum.map(fn val ->
        val * 2
      end)
      """

      evaluated_code = [
        {"[1, 2, 3]", [1, 2, 3]},
        {"|> Enum.map(fn val ->", [2, 4, 6]},
        {"val * 2", [2, 4, 6]},
        {"end)", [2, 4, 6]}
      ]

      assert Evaluator.evaluate(code) == evaluated_code
    end
  end
end
