defmodule TypeUnionTest do
  use ExUnit.Case

  require TypeUnion

  alias Test.Support.Typespec

  test "creates all kinds of types" do
    {:module, _name, bytecode, _} =
      defmodule Test1 do
        TypeUnion.type :t_1, ~w[one two three]a
        TypeUnion.typep :t_2, ~w[thing another_thing]a
        TypeUnion.opaque :t_3, ~w[1 2 3]a

        # @typep types remain in bytecode only if public types depend on them
        @type public :: t_2()
      end

    typespecs = Typespec.fetch_types(bytecode)

    expected_typespecs = MapSet.new([
      %Typespec{name: :t_1, mode: :type, elements: ~w[one two three]a},
      %Typespec{name: :t_2, mode: :typep, elements: ~w[thing another_thing]a},
      %Typespec{name: :t_3, mode: :opaque, elements: ~w[1 2 3]a},
    ])

    assert MapSet.subset?(expected_typespecs, typespecs)
  end

  test "creates type from module attribute" do
    {:module, _name, bytecode, _} =
      defmodule Test2 do
        @attribute ~w[one two three]a

        TypeUnion.type :t, @attribute
      end

    expected_typespec = %Typespec{
      name: :t, mode: :type, elements: ~w[one two three]a
    }

    typespecs = Typespec.fetch_types(bytecode)

    assert expected_typespec in typespecs
  end

  test "creates type from integer enumerables" do
    {:module, _name, bytecode, _} =
      defmodule Test3 do
        TypeUnion.type :t_1, [1, 2, 3]
        TypeUnion.opaque :t_2, 1..3
      end

    expected_typespecs = MapSet.new([
      %Typespec{name: :t_1, mode: :type, elements: [1, 2, 3]},
      %Typespec{name: :t_2, mode: :opaque, elements: [1, 2, 3]},
    ])

    typespecs = Typespec.fetch_types(bytecode)

    assert MapSet.subset?(expected_typespecs, typespecs)
  end

  test "creates type from list of types" do
    {:module, _name, bytecode, _} =
      defmodule Test4 do
        TypeUnion.type :t, [atom(), nonempty_list(integer() | float()), nil]
      end

    expected_typespec = %Typespec{
      name: :t,
      mode: :type,
      elements: [:atom, {:nonempty_list, [:integer, :float]}, nil]
    }

    typespecs = Typespec.fetch_types(bytecode)

    assert expected_typespec in typespecs
  end
end
