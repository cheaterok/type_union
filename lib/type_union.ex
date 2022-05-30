defmodule TypeUnion do
  @moduledoc false

  for mode <- ~w[type typep opaque]a do
    defmacro unquote(mode)(name, elements) do
      elements =
        if is_list(elements) do
          Macro.escape(elements)
        else
          elements
        end

      quote bind_quoted: [
        name: name, elements: elements,
        mode: unquote(mode), module: __MODULE__
      ] do
        ast = module._form_type_definition_ast(name, elements, mode)
        Module.eval_quoted(__MODULE__, ast)
      end
    end
  end

  def _form_type_definition_ast(name, elements, mode) do
    type_union =
      elements
      |> Enum.reverse()
      |> Enum.reduce(fn element, acc ->
        quote do: unquote(element) | unquote(acc)
      end)

    name_var = Macro.var(name, nil)

    type_ast = quote do: unquote(name_var) :: unquote(type_union)

    case mode do
      :type -> quote do: @type unquote(type_ast)
      :typep -> quote do: @typep unquote(type_ast)
      :opaque -> quote do: @opaque unquote(type_ast)
    end
  end
end
