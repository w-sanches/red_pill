defmodule RedPill.LineCommenterTest do
  use ExUnit.Case

  alias RedPill.LineCommenter

  describe "comment_lines/1" do
    test "comments lines with #=>" do
      input = [{"foo #=>", "bar"}]

      assert LineCommenter.comment_lines(input) == """
             foo #=> "bar"\
             """
    end

    test "ignores lines without #=>" do
      input = [{"foo", "bar"}, {"foo #=>", "bar"}]

      assert LineCommenter.comment_lines(input) == """
             foo
             foo #=> "bar"\
             """
    end

    test "aligns multiple line comments" do
      input = [
        {"foo #=>", "bar"},
        {"fooo #=>", "bar"},
        {"fo #=>", "bar"},
        {"foooo #=>", "bar"}
      ]

      assert LineCommenter.comment_lines(input) == """
             foo   #=> "bar"
             fooo  #=> "bar"
             fo    #=> "bar"
             foooo #=> "bar"\
             """
    end
  end
end
