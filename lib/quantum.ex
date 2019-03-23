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

defmodule Quantum do
  @moduledoc """
  Quantum library namespace.
  """
  @zary [
  ]

  @unary [
    abs: :abs,
    qubit: :qubit
  ]

  @binary [
    +: :+,
    -: :-,
    *: :*,
    /: :/,
    div: :div
  ]
  
  @doc false
  defmacro __using__(_opts) do
    ops = Enum.map(@zary, fn({op, _}) -> {op, 0} end)
          ++
          Enum.map(@unary, fn({op, _}) -> {op, 1} end)
          ++
          Enum.map(@binary, fn({op, _}) -> {op, 2} end)

    quote do
      import Kernel, except: unquote(ops)
      use Quantum.Complex
      use Quantum.Qubit
      use Quantum.Unitary
      use Quantum.Circuit
      use Quantum.Operator
      import Quantum.Qop, only: unquote(ops)
      alias Complex, as: C
      alias Qubit, as: Q
      alias Unitary, as: U
    end
  end

  Enum.each @zary, fn({op, name}) ->
    @doc false
    def unquote(op)() do
      Quantum.Qop.unquote(name)()
    end
  end

  Enum.each @unary, fn({op, name}) ->
    @doc false
    def unquote(op)(a) do
      Quantum.Qop.unquote(name)(a)
    end
  end

  Enum.each @binary, fn({op, name}) ->
    @doc false
    def unquote(op)(a, b) do
      Quantum.Qop.unquote(name)(a, b)
    end
  end

end
