defmodule Botter.Router do
  @moduledoc """
  Documentation for `Botter.Router`.
  """

  @doc """
  Creates new scope.
  """
  defmacro scope(name, do: inner)
           when is_binary(name) do
    quote do
      @botter_commands {:scope, unquote(name)}
      unquote(inner)
      @botter_commands :end_scope
    end
  end

  @doc """
  Creates new route.
  """
  defmacro command(name, {:__aliases__, _, _} = module, function, opts \\ [])
           when is_binary(name) and is_atom(function) do
    quote do
      @botter_commands {:command, unquote(name), unquote(module), unquote(function),
                        unquote(opts)}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :botter_commands, accumulate: true)
      @before_compile unquote(__MODULE__)

      def handle(command, context), do: internal_handle(String.split(command, " "), context)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :botter_commands))
  end

  defp compile(elements) do
    {commands, []} = List.foldr(elements, {[], []}, &compile_element/2)

    quote do
      [
        unquote(def_commands(commands))
        | unquote(def_handle(commands))
      ]
    end
  end

  defp compile_element({:command, name, module, function, opts}, {commands, namespace}) do
    {[{get_name(namespace, name), module, function, opts} | commands], namespace}
  end

  defp compile_element({:scope, name}, {commands, namespace}) do
    {commands, [name | namespace]}
  end

  defp compile_element(:end_scope, {commands, namespace}) do
    {commands, List.delete_at(namespace, 0)}
  end

  defp get_name(namespace, name) do
    List.foldl(namespace, name, &Kernel.<>/2)
  end

  defp def_commands(commands) do
    commands =
      commands
      |> Enum.map(fn {name, module, function, _opts} -> {name, module, function} end)
      |> Macro.escape()

    quote do
      def commands, do: unquote(commands)
    end
  end

  defp def_handle(commands) do
    commands =
      Enum.map(commands, fn {name, module, function, _opts} ->
        {head, params} = prepare_params(name)

        quote do
          defp internal_handle(unquote(head), context) do
            res = unquote(module).unquote(function)(context, unquote(params))
            {:ok, res}
          end
        end
      end)

    quote do
      unquote(commands)

      def handle(_context, _params) do
        {:error, :command_not_found}
      end
    end
  end

  defp prepare_params(command) do
    command = parse_command(command)

    params =
      Enum.filter(command, &is_atom/1)
      |> Enum.map(&{&1, {&1, [], Elixir}})

    params = {:%{}, [], params}

    head =
      Enum.map(command, fn
        param when is_atom(param) -> {param, [], Elixir}
        x -> x
      end)

    {head, params}
  end

  defp parse_command(command) do
    command
    |> String.split(" ")
    |> Enum.map(fn word ->
      param = Regex.named_captures(~r/^{(?<param>(.+))}$/, word)

      if param,
        do: param |> Map.fetch!("param") |> String.to_atom(),
        else: word

      # if param do
      #   param |> Map.fetch!("param") |> String.to_atom()
      # else
      #   word
      #   case parse_command_word(word) do
      #     [] -> ""
      #     [word] -> word
      #     word -> word
      #   end
      # end
    end)
  end

  defp parse_command_word(command) do
    ~r/(?<start>){[^}]+}(?<end>)/
    |> Regex.split(command, on: [:start, :end])
    |> Enum.map(fn
      "{" <> param -> String.slice(param, 0..-2) |> String.to_atom()
      str -> str
    end)
    |> Enum.filter(&(&1 != ""))
  end

  defp prepare_word_params(command) do
    command = parse_command_word(command)

    head =
      Enum.reduce(command, nil, fn
        "", acc ->
          acc

        item, nil ->
          Macro.escape(item)

        item, acc when is_binary(item) ->
          quote do: unquote(acc) <> unquote(item)

        item, acc when is_atom(item) ->
          quote do: unquote(acc) <> unquote({item, [], Elixir})
      end)

    params =
      Enum.filter(command, &is_atom/1)
      |> Enum.map(&{&1, {&1, [], Elixir}})

    params = {:%{}, [], params}

    {head, params}
  end
end
