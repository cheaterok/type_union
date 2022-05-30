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
    type_union =
      elements
      |> Enum.reverse()
      |> Enum.reduce(fn element, acc ->
        quote do: unquote(element) | unquote(acc)
      end)

    name_var = Macro.var(name, nil)

    type_ast = quote do: unquote(name_var) :: unquote(type_union)

    case mode do
      :type -> quote do: @type(unquote(type_ast))
      :typep -> quote do: @typep(unquote(type_ast))
      :opaque -> quote do: @opaque(unquote(type_ast))
    end
  end
end
