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

  use Quantum.Complex

  alias Complex, as: C
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
    flist = list |> List.flatten
    l = Kernel.length(flist)
    %Qubit{to_list: flist, shape: [l], n: round(:math.log2(l))}
  end

  @spec new(integer, Tensor.tensor) :: qubit
  def new(num \\ nil, state \\ nil) do
    %Qubit{to_list: state.to_list, shape: state.shape, n: num}
  end

  @spec pure(list) :: qubit
  @spec pure(integer, Tensor.tensor) :: qubit
  def pure(list) when is_list(list), do: new(list)
  def pure(num \\ nil, state \\ nil), do: new(num, state)

  defp r1_2, do:  C.div(1, :math.sqrt(2))

  @doc """
  q0:    |0>  ... [ 1, 0 ]
  q1:    |1>  ... [ 0, 1 ]
  qP:    |+> = 1/sqrt(2) |0> + 1/sqrt(2) |1>
  qM:    |-> = 1/sqrt(2) |0> - 1/sqrt(2) |1>
  qH:    H|0> = |+>

  ## Examples

    iex> Qubit.q0.n
    1
    iex> Qubit.q1.n
    1

  """
  @spec q0 :: qubit
  def q0, do: Qubit.new([C.new(1), C.new(0)])
  @spec q1 :: qubit
  def q1, do: Qubit.new([C.new(0), C.new(1)])
  @spec qP :: qubit
  def qP,do: Qubit.new([C.new(r1_2()), C.new(r1_2())])
  @spec qM :: qubit
  def qM,do: Qubit.new([C.new(r1_2()), C.new(-1*r1_2())])
  @spec qH :: qubit
  def qH,do: qP()

  @doc """
  q00:    |00>  ... [ 1, 0, 0, 0]
  q00:    |01>  ... [ 0, 1, 0, 0]
  q00:    |10>  ... [ 0, 0, 1, 0]
  q00:    |11>  ... [ 0, 0, 0, 1]
  qHH:    1/2 |00> + 1/2 |01> + 1/2 |10> + 1/2 |11>

  ## Examples

    iex> Qubit.q00.n
    2
    iex> Qubit.q01.n
    2
    iex> Qubit.q10.n
    2
    iex> Qubit.q11.n
    2
    iex> Qubit.qHH.n
    2

  """
  @spec q00 :: qubit
  def q00, do: Qubit.new([C.new(1), C.new(0), C.new(0), C.new(0)])
  @spec q01 :: qubit
  def q01, do: Qubit.new([C.new(0), C.new(1), C.new(0), C.new(0)])
  @spec q10 :: qubit
  def q10, do: Qubit.new([C.new(0), C.new(0), C.new(1), C.new(0)])
  @spec q11 :: qubit
  def q11, do: Qubit.new([C.new(0), C.new(0), C.new(0), C.new(1)])
  @spec qHH :: qubit
  def qHH, do: Qubit.new([C.new(0.5), C.new(0.5), C.new(0.5), C.new(0.5)])

  @doc """
  Bell State, entanglement state
  qPsiP:    |Psi+> = 1/sqrt(2) |00> + 1/sqrt(2) |11>
  qPsiM:    |Psi-> = 1/sqrt(2) |00> - 1/sqrt(2) |11>
  qPhiP:    |Phi+> = 1/sqrt(2) |01> + 1/sqrt(2) |10>
  qPhiM:    |Phi-> = 1/sqrt(2) |01> - 1/sqrt(2) |10>

  ## Examples

    iex> Qubit.qPsiP.n
    2
    iex> Qubit.qPsiM.n
    2
    iex> Qubit.qPhiP.n
    2
    iex> Qubit.qPhiM.n
    2

  """
  @spec qPsiP :: qubit
  def qPsiP, do: Qubit.new([C.new(r1_2()), C.new(0), C.new(0), C.new(r1_2())])
  @spec qPsiM :: qubit
  def qPsiM, do: Qubit.new([C.new(r1_2()), C.new(0), C.new(0), C.new(-1*r1_2())])
  @spec qPhiP :: qubit
  def qPhiP, do: Qubit.new([C.new(0), C.new(r1_2()), C.new(r1_2()), C.new(0)])
  @spec qPhiM :: qubit
  def qPhiM, do: Qubit.new([C.new(0), C.new(r1_2()), C.new(-1*r1_2()), C.new(0)])

end
