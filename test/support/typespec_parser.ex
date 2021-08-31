defmodule Test.Support.TypespecParser do
  @moduledoc false

  defmodule Typespec do
    @moduledoc false

    @enforce_keys ~w[name mode elements]a
    defstruct @enforce_keys

    @type t :: %__MODULE__{
      name: atom(),
      mode: :type | :typep | :opaque,
      elements: nonempty_list(atom())
    }
  end

  @spec fetch_types(atom() | binary()) :: MapSet.t(Typespec.t())
  def fetch_types(module) do
    {:ok, types} = Code.Typespec.fetch_types(module)

    types
    |> Stream.filter(&parsable?/1)
    |> Stream.map(&parse_type/1)
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

    elements = parse_union(union)

    %Typespec{
      name: name,
      mode: mode,
      elements: elements
    }
  end

  defp parse_union(union) do
    Enum.map(union, fn {:atom, _, atom} -> atom end)
  end
end
