defmodule Quantum.Qubit do
  @moduledoc """
  Qubit library namespace.
  use `use Quantum.Qubit` to alias `Qubit`.
  """

  defmacro __using__(_opts) do
    quote do
      alias Tensor.Qubit
    end
  end

end

defmodule Tensor.Qubit do

  alias Tensor.{Tensor, TBase, Qubit}
  use TBase, n: 0

  @type t(list, sh, num) :: %Qubit{to_list: list, shape: sh, n: num}
  @type t :: %Qubit{to_list: list, shape: list, n: integer}

  @opaque qubit :: %Qubit{}

  defimpl Inspect, for: Qubit do
    def inspect(q, _opts) do
      "Qubit[#{q.n}]:" <>
      "Tensor[#{q.shape |> Enum.join("x")}] (#{inspect q.to_list})"
    end
  end

  @spec new(list) :: qubit
  def new(list) when is_list(list) do
    l = Kernel.length(list)
    %Qubit{to_list: list, shape: [l], n: round(:math.log2(l))}
  end

  @spec new(integer, Tensor.tensor) :: qubit
  def new(num \\ nil, state \\ nil) do
    %Qubit{to_list: state.to_list, shape: state.shape, n: num}
  end

end
