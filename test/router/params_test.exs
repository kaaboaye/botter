defmodule Botter.Router.ParamsTest do
  use ExUnit.Case

  defmodule Test do
    def say(_, %{msg: msg}), do: msg
    def params(_, params), do: params
  end

  defmodule Test.Router do
    use Botter.Router

    command("say {msg}", Test, :say)

    scope "!" do
      scope "kick " do
        command("{user}", Test, :params)
      end
    end

    command("hay {p1} dsa", Test, :params)
  end

  test "generates module functions" do
    functions = Test.Router.__info__(:functions)

    assert functions === [commands: 0, handle: 2]
  end

  test "can handle one param command" do
    msg = "test-message"

    assert {:ok, ^msg} = Test.Router.handle("say #{msg}", nil)
  end

  test "can handle param in scoped command" do
    user = "user"

    assert {:ok, %{user: ^user}} = Test.Router.handle("!kick #{user}", nil)
  end

  test "can handle text after apram" do
    p1 = "param1"

    assert {:ok, %{p1: ^p1}} = Test.Router.handle("hay #{p1} dsa", nil)
  end
end
