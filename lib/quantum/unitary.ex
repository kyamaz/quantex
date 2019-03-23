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

defmodule Quantum.Unitary do
  @moduledoc """
  Tensor library namespace.
  use `use Quantum.Unitary` to alias `Unitary`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Tensor.Unitary
    end
  end

end

defmodule Tensor.Unitary do

  alias Tensor.{Tensor, TBase, Unitary}
  use TBase, [n: 0, t: [] ]

  @type t(shape, list, num, target) :: %Unitary{n: num, t: target, shape: shape, to_list: list}
  @type t :: %Unitary{n: integer, t: [integer], to_list: list, shape: list}

  @opaque unitary :: %Unitary{}

  defimpl Inspect, for: Unitary do
    def inspect(u, _opts) do
      "Unitary[#{u.n} | #{u.t |> Enum.join(",")}]:" <>
      "Tensor[#{u.shape |> Enum.join("x")}] (#{inspect u.to_list})"
    end
  end

  @spec new(list) :: unitary
  def new(list) when is_list(list) do
    flist = list |> List.flatten
    l = round(:math.sqrt(Kernel.length(flist)))
    nn = round(:math.log2(l))
    %Unitary{to_list: flist, shape: [l, l], n: nn, t: [] }
  end

end
