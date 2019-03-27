#
#   Copyright 2018-2019 piacere.
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

defmodule QuantEx do
  @moduledoc """
  Documentation for QuantEx ( Elixir Quantum Computing module ).
  QuantEx library namespace.
  """

  @unary [
    abs: :abs,
    qubit: :qubit
  ]


  @binary [
    +: :+,
    -: :-,
    *: :*,
    /: :/,
    if: :if,
    unless: :unless,
    div: :div
  ]
  
  @doc false
  defmacro __using__(_opts) do
    ops = Enum.map(@unary, fn({op, _}) -> {op, 1} end)
          ++
          Enum.map(@binary, fn({op, _}) -> {op, 2} end)

    quote do
      import Kernel, except: unquote(ops)
      use QuantEx.Complex
      use QuantEx.Qubit
      use QuantEx.Unitary
      use QuantEx.Circuit
      use QuantEx.Operator
      import QuantEx.Qop, only: unquote(ops)

      alias Complex, as: C
      alias Qubit, as: Q
      alias Unitary, as: U
    end
  end

  Enum.each @unary, fn({op, name}) ->
    @doc false
    def unquote(op)(a) do
      QuantEx.Qop.unquote(name)(a)
    end
  end

  macros = [if: :if, unless: :unless]
  Enum.each @binary -- macros, fn({op, name}) ->
    @doc false
    def unquote(op)(a, b) do
      QuantEx.Qop.unquote(name)(a, b)
    end
  end

end
