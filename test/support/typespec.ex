defmodule Test.Support.Typespec do
  @moduledoc false

  @enforce_keys ~w[name mode elements]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    name: atom(),
    mode: :type | :typep | :opaque,
    elements: nonempty_list(atom())
  }

  @spec fetch_types(atom() | binary()) :: MapSet.t(__MODULE__.t())
  def fetch_types(module) do
    {:ok, types} = Code.Typespec.fetch_types(module)

    types
    |> Enum.filter(&parsable?/1)
    |> Enum.map(&parse_type/1)
    |> MapSet.new()
  end

  defp parsable?({_mode, description}) do
    match?(
      {_name, {:type, _, :union, _union}, []},
      description
    )
  end

  defp parse_type({mode, description}) do
    {name, {:type, _, :union, union}, []} = description

    %__MODULE__{
      name: name,
      mode: mode,
      elements: Enum.map(union, &parse_element/1)
    }
  end

  defp parse_element(element) do
    case element do
      {:atom, _, atom} -> atom
      {:integer, _, integer} -> integer
      {:type, _, type, []} -> type
      {:type, _, type, [{:type, _, :union, types}]} -> {type, Enum.map(types, &parse_element/1)}
    end
  end
end
