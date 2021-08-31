defmodule TypeUnion do
  @moduledoc false

  defmacro __using__([]) do
    quote do
      import unquote(__MODULE__), only: [typeunion: 2, typeunion: 3]
    end
  end

  defmacro typeunion(name, elements, mode \\ :type) do
    quote bind_quoted: [name: name, elements: elements, mode: mode, module: __MODULE__] do
      ast = module._form_type_definition_ast(name, elements, mode)
      Module.eval_quoted(__MODULE__, ast)
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
