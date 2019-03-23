defmodule Quantum do
  @moduledoc """
  Quantum library namespace.
  """
  @zary [
    x:  :x,
    q0: :q0,
    q1: :q1
  ]

  @unary [
    abs: :abs
  ]

  @binary [
    +: :+,
    -: :-,
    *: :*,
    div: :div,
    /: :/,
    # ==: :equal?
  ]

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
      import Quantum.Qop, only: unquote(ops)
      alias Complex, as: C
      alias Qubit, as: Q
      alias Unitary, as: U
      alias Quantum.Qop
    end
  end

  Enum.each @zary, fn({op, name}) ->
    def unquote(op)() do
      Quantum.Qop.unquote(name)()
    end
  end

  Enum.each @unary, fn({op, name}) ->
    def unquote(op)(a) do
      Quantum.Qop.unquote(name)(a)
    end
  end

  Enum.each @binary, fn({op, name}) ->
    def unquote(op)(a, b) do
      Quantum.Qop.unquote(name)(a, b)
    end
  end
end
