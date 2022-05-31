defmodule TypeUnion do
  @moduledoc false

  for mode <- ~w[type typep opaque]a do
    defmacro unquote(mode)(name, elements) do
      define_type(unquote(mode), name, elements)
    end
  end

  defp define_type(mode, name, elements) do
    elements =
      if is_list(elements) do
        Macro.escape(elements)
      else
        elements
      end

    quote bind_quoted: [
            name: name,
            elements: elements,
            mode: mode,
            module: __MODULE__
          ] do
      name
      |> module._form_type_definition(elements, mode)
      |> then(&Module.eval_quoted(__MODULE__, &1))
    end
  end

  def _form_type_definition(name, elements, mode) do
    elements
    |> Enum.reverse()
    |> Enum.reduce(fn element, acc ->
      quote do: unquote(element) | unquote(acc)
    end)
    |> then(&quote do: unquote(Macro.var(name, nil)) :: unquote(&1))
    |> then(&quote do: @(unquote(mode)(unquote(&1))))
  end
end
