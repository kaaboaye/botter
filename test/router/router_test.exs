defmodule Botter.RouterTest do
  use ExUnit.Case
  doctest Botter.Router

  defmodule Test do
    def pong(_, _), do: :pong
    def help(_, _), do: :help
    def kick(_, _), do: :kick
  end

  defmodule Test.Router do
    use Botter.Router

    command("ping", Test, :pong)

    scope "!" do
      command("help", Test, :help)

      scope "user " do
        command("kick", Test, :kick)
      end
    end
  end

  test "generates module functions" do
    functions = Test.Router.__info__(:functions)

    assert functions === [commands: 0, handle: 2]
  end

  test "generates list of commands" do
    assert Test.Router.commands() === [
             {"!user kick", Botter.RouterTest.Test, :kick},
             {"!help", Botter.RouterTest.Test, :help},
             {"ping", Botter.RouterTest.Test, :pong}
           ]
  end

  test "handle work for ordinary commands" do
    assert Test.Router.handle("ping", %{}) === {:ok, :pong}
  end

  test "handle work for scoped commands" do
    assert Test.Router.handle("!help", %{}) === {:ok, :help}
  end

  test "nasted scopes works" do
    assert Test.Router.handle("!user kick", %{}) === {:ok, :kick}
  end
end
