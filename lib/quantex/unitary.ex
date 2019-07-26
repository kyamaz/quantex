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

defmodule QuantEx.Unitary do
  @moduledoc """
  Unitary library namespace.
  use `use QuantEx.Unitary` to alias `Unitary`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Tensor.Unitary
    end
  end

end

defmodule Tensor.Unitary do

  use QuantEx.Complex
  alias Tensor.{Tensor, Unitary}

  use Tensor, n: 0

  alias Tensor, as: T
  alias Complex, as: C

  @type t(nn, sh, arr) :: %Unitary{n: nn, shape: sh, to_list: arr}
  @type t :: %Unitary{n: non_neg_integer, shape: list(non_neg_integer), to_list: list}
  @opaque unitary :: %Unitary{}

  defimpl Inspect, for: Unitary do
    def inspect(u, _opts) do
      "Unitary[#{u.n}]:" <>
      "Tensor[#{u.shape |> Enum.join("x")}] (#{inspect u.to_list})"
    end
  end

  @spec is_unitary(term) :: boolean
  def is_unitary(s), do: is_map(s) && Map.has_key?(s, :__struct__) && s.__struct__ == Unitary

  @spec unitary?(term) :: boolean
  def unitary?(%Unitary{}), do: true
  def unitary?(_), do: false

  @spec new(list) :: unitary
  def new(lis) when is_list(lis) do
    flist = lis |> List.flatten
    l = round(:math.sqrt(Kernel.length(flist)))
    nn = round(:math.log2(l))
    %Unitary{n: nn, shape: [l, l], to_list: flist }
  end

  @spec add(unitary, unitary) :: unitary
  def add(a = %Unitary{}, b = %Unitary{}) do
    if a.n == b.n do
       x()
    else
       %Unitary{}
    end
  end

  defp r1_2, do:  Complex.div(1, :math.sqrt(2))

  @spec x() :: unitary
  def x, do: new([C.new(0), C.new(1), C.new(1), C.new(0)])
  @spec y() :: unitary
  def y, do: new([C.new(0), C.new(0,-1), C.new(0,1), C.new(0)])
  @spec z() :: unitary
  def z, do: new([C.new(1), C.new(0), C.new(0), C.new(-1)])
  @spec h() :: unitary
  def h, do: new([C.new(r1_2()), C.new(r1_2()), C.new(r1_2()), C.new(-1*r1_2())])
  @spec cx() :: unitary
  def cx,  do: new([C.new(1), C.new(0), C.new(0), C.new(0),
                    C.new(0), C.new(1), C.new(0), C.new(0),
                    C.new(0), C.new(0), C.new(0), C.new(1),
                    C.new(0), C.new(0), C.new(1), C.new(0)
                   ])
  @spec swap() :: unitary
  def swap,  do: new([C.new(1), C.new(0), C.new(0), C.new(0),
                    C.new(0), C.new(0), C.new(1), C.new(0),
                    C.new(0), C.new(1), C.new(0), C.new(0),
                    C.new(0), C.new(0), C.new(0), C.new(1)
                   ])

end
