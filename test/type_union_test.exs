defmodule TypeUnionTest do
  use ExUnit.Case

  use TypeUnion

  alias Test.Support.TypespecParser
  alias TypespecParser.Typespec

  test "creates types from atom lists" do
    {:module, _name, bytecode, _} =
      defmodule Test1 do
        typeunion(:t, ~w[one two three]a)
        typeunion(:t_2, ~w[thing another_thing]a, :typep)
        typeunion(:t_3, ~w[1 2 3]a, :opaque)

        # @typep types remain in bytecode only if public types depend on them
        @type public :: t_2()
      end

    expected_typespecs = MapSet.new([
      %Typespec{name: :t, mode: :type, elements: ~w[one two three]a},
      %Typespec{name: :t_2, mode: :typep, elements: ~w[thing another_thing]a},
      %Typespec{name: :t_3, mode: :opaque, elements: ~w[1 2 3]a},
    ])

    typespecs = TypespecParser.fetch_types(bytecode)

    assert MapSet.subset?(expected_typespecs, typespecs)
  end

  test "creates type from module attribute" do
    {:module, _name, bytecode, _} =
      defmodule Test2 do
        @attribute ~w[one two three]a

        typeunion(:t, @attribute)
      end

    expected_typespecs = MapSet.new([
      %Typespec{name: :t, mode: :type, elements: ~w[one two three]a}
    ])

    typespecs = TypespecParser.fetch_types(bytecode)

    assert MapSet.subset?(expected_typespecs, typespecs)
  end
end
