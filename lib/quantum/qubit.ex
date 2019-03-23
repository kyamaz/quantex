#
#   Copyright 2019 OpenQL Project developers.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

defmodule Quantum.Qubit do
  @moduledoc """
  Qubit library namespace.
  use `use Quantum.Qubit` to alias `Qubit`.
  """
  @doc false
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
