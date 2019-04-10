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

defmodule QuantEx.Operator do
  @moduledoc """
  Operator library namespace.
  use `use QuantEx.Operator` to alias `Qop`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias QuantEx.Qop
    end
  end

end

defmodule QuantEx.Qop do
  @moduledoc """
  """

  require Math

  import Kernel, except: [+: 2, -: 2, *: 2,
                          ===: 2,
                          if: 2, unless: 2
                          ]

  defstruct nm: nil, n: 1, t: 0, c: [], opts: nil

  alias QuantEx.Qop

  @type t(opts_type) :: %Qop{nm: atom, n: non_neg_integer, t: non_neg_integer, c: list(non_neg_integer), opts: opts_type}
  @type t :: %Qop{nm: atom, n: non_neg_integer, t: non_neg_integer, c: list(non_neg_integer), opts: any}
  @opaque qop :: %Qop{}

  defimpl Inspect, for: Qop do
    def inspect(qop, _opts) do
      "#{qop.n}-qubit operator: #{qop.nm}(#{qop.t},[#{inspect qop.c}]) opts:#{inspect qop.opts}"
    end
  end

  @spec new(atom, non_neg_integer, non_neg_integer, list(non_neg_integer), C.real_complex) :: qop
  def new(name, target \\ 0, options \\ nil, nqubits \\ 1, controls \\ nil),
    do: %Qop{nm: name, n: nqubits, t: target, c: controls, opts: options}

  @spec is_qop(term) :: boolean
  def is_qop(s), do: is_map(s) && Map.has_key?(s, :__struct__) && s.__struct__ == Qop

  use QuantEx.Complex
  use QuantEx.Qubit
  use QuantEx.Unitary
  use QuantEx.Tensor
  use QuantEx.Circuit

  alias Complex, as: C
  alias Qubit, as: Q
  alias Unitary, as: U
  alias Tensor, as: T

  @doc """

  ## Examples

    iex> import Kernel, except: [===: 2]
    iex> import QuantEx.Qop
    iex> import QuantEx.Complex
    iex> Complex.new(1) === Complex.new(1)
    true

  """
  @spec C.real_complex === C.real_complex :: C.real_complex
  def left === right, do: C.equal?(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [+: 2]
    iex> import QuantEx.Qop
    iex> 1 + 2
    3

  """
  @spec C.real_complex + C.real_complex :: C.real_complex
  def left + right, do: C.add(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [-: 2]
    iex> import QuantEx.Qop
    iex> 2 - 1
    1

  """
  @spec C.real_complex - C.real_complex :: C.real_complex
  def left - right, do: C.sub(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [*: 2]
    iex> import QuantEx.Qop
    iex> 2 * 3
    6

  """
  @spec C.real_complex * C.real_complex :: C.real_complex
  def left * right, do: C.mul(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [/: 2]
    iex> import QuantEx.Qop
    iex> 6 / 2
    3.0

  """
  @spec C.real_complex / C.real_complex :: C.real_complex
  def left / right, do: C.div(left, right)

  defdelegate abs(real_complex), to: C
  defdelegate div(real_complex, real_complex), to: C

  @doc """

  ## Examples

    iex> import Kernel, except: [if: 2]
    iex> import QuantEx.Qop
    iex> if(true, do: true)
    true
    iex> if(true, do: true, else: false)
    true
    iex> if(false, do: true, else: false)
    false

  """
  defmacro if(condition, clauses) do
    build_if(condition, clauses)
  end

  defp optimize_boolean({:case, meta, args}) do
    {:case, [{:optimize_boolean, true} | meta], args}
  end

  defp build_if(condition, do: do_clause) do
    build_if(condition, do: do_clause, else: nil)
  end

  defp build_if(condition, do: do_clause, else: else_clause) do
    optimize_boolean(
      quote do
        case unquote(condition) do
          x when :"Elixir.Kernel".in(x, [false, nil]) -> unquote(else_clause)
          _ -> unquote(do_clause)
        end
      end
    )
  end

  defp build_if(_condition, _arguments) do
    raise ArgumentError,
          "invalid or duplicate keys for if, only \"do\" and an optional \"else\" are permitted"
  end

  @doc """

  ## Examples

    iex> import Kernel, except: [if: 2, unless: 2]
    iex> import QuantEx.Qop
    iex> unless(true, do: true)
    nil
    iex> unless(true, do: true, else: false)
    false
    iex> unless(false, do: true, else: false)
    true

  """
  defmacro unless(condition, clauses) do
    build_unless(condition, clauses)
  end

  defp build_unless(condition, do: do_clause) do
    build_unless(condition, do: do_clause, else: nil)
  end

  defp build_unless(condition, do: do_clause, else: else_clause) do
    quote do
      if(unquote(condition), do: unquote(else_clause), else: unquote(do_clause))
    end
  end

  defp build_unless(_condition, _arguments) do
    raise ArgumentError,
          "invalid or duplicate keys for unless, only \"do\" and an optional \"else\" are permitted"
  end

  @doc """
  create pure state qubit
  """
  @spec pure(list) :: Q.qubit
  defdelegate pure(list), to: Q

  @spec pure(integer, T.tensor) :: Q.qubit
  defdelegate pure(num, state), to: Q

  def qubit(list), do: pure(list)
  def qubit(num, state), do: pure(num, state)

  @doc """
  U1 gate. - 1 qubit operator

  ## Examples

    #iex> QuantEx.Qop.x.n
    #1
    #iex> QuantEx.Qop.x.shape
    #[2, 2]

  """
  @spec u1(Qit.circuit, qop) :: Qit.circuit
  def u1(circ = %Qit{}, op1 = %Qop{}) do
    %Qit{n: max(circ.n, op1.n), gates: circ.gates ++ op1}
  end
  @spec u1(qop, qop) :: Qit.circuit
  def u1(op2 = %Qop{}, op1 = %Qop{}) do
    %Qit{n: max(op1.n, op2.n), gates: [op2, op1]}
  end
  @spec u1(U.unitary, qop) :: Qit.circuit
  def u1(u = %Unitary{}, op1 = %Qop{}) do
    %Qit{n: max(u.n, op1.n), gates: [op1]}  # FIXME: must use u
  end
  @spec u1(C.complex, qop) :: Qit.circuit
  def u1(c = %Complex{}, op1 = %Qop{}) do
    if is_map(c), do: false
    %Qit{n: op1.n, gates: [op1]}  # FIXME: must use c
  end
  @spec u1(number, qop) :: Qit.circuit
  def u1(c, op1 = %Qop{}) when is_number(c) do
    %Qit{n: op1.n, gates: [op1]} # FIXME: must use c
  end

  @spec u1(C.real_complex, C.real_complex, C.real_complex, non_neg_integer, atom) :: qop
  def u1(a1 = %Complex{}, a2 = %Complex{}, a3 = %Complex{}, target, name)
   when is_number(target) and is_atom(name) do
      %Qop{nm: :u1, n: 1, t: target, opts: [a1, a2, a3]}
  end
  def u1(a1, a2 = %Complex{}, a3 = %Complex{}, target, name)
   when is_number(a1) and is_number(target) and is_atom(name) do
  end
  def u1(a1 = %Complex{}, a2, a3 = %Complex{}, target, name)
   when is_number(a2) and is_number(target) and is_atom(name) do
  end
  def u1(a1 = %Complex{}, a2 = %Complex{}, a3, target, name)
   when is_number(a3) and is_number(target) and is_atom(name) do
  end
  def u1(a1 = %Complex{}, a2, a3, target, name)
   when is_number(a2) and is_number(a3) and is_number(target) and is_atom(name) do
  end
  def u1(a1, a2 = %Complex{}, a3, target, name)
   when is_number(a2) and is_number(a3) and is_number(target) and is_atom(name) do
  end
  def u1(a1, a2, a3 = %Complex{}, target, name)
   when is_number(a2) and is_number(a3) and is_number(target) and is_atom(name) do
  end
  def u1(a1, a2, a3, target, name)
   when is_number(a1) and is_number(a2) and is_number(a3)
    and is_number(target) and is_atom(name) do
  end

  @spec u1(C.real_complex, C.real_complex, non_neg_integer, atom) :: qop
  def u1(a1 = %Complex{}, a2 = %Complex{}, target, name)
      when is_number(target) and is_atom(name) do
  end
  def u1(m, a1 = %Complex{}, a2 = %Complex{}, target, name)
      when is_map(m) and is_number(target) and is_atom(name) do
  end

  def u1(a1, a2 = %Complex{}, target, name)
      when is_number(a1) and is_number(target) and is_atom(name) do
  end
  def u1(m, a1, a2 = %Complex{}, target, name)
      when is_map(m) and is_number(a1) and is_number(target) and is_atom(name) do
  end

  def u1(a1 = %Complex{}, a2, target, name)
      when is_number(a2) and is_number(target) and is_atom(name) do
  end
  def u1(m, a1 = %Complex{}, a2, target, name)
      when is_map(m) and is_number(a2)
       and is_number(target) and is_atom(name) do
  end

  def u1(a1, a2, target, name)
      when is_number(a1) and is_number(a2)
        and is_integer(target) and target > 0 and is_atom(name) do
  end
  def u1(m, a1, a2, target, name)
      when is_map(m) and is_number(a1) and is_number(a2)
       and is_integer(target) and target > 0 and is_atom(name) do
  end

  @spec u1(C.reql_complex, non_neg_integer, atom) :: qop
  def u1(a1 = %Complex{}, target, name)
      when is_integer(target) and target > 0 and is_atom(name) do
  end
  @spec u1(map, C.reql_complex, non_neg_integer, atom) :: qop
  def u1(m, a1 = %Complex{}, target, name)
      when is_map(m) and is_integer(target) and target > 0 and is_atom(name) do
  end

  @spec u1(U.unitary, non_neg_integer, atom) :: qop
  def u1(a1 = %Unitary{}, target, name)
      when is_atom(name) and is_integer(target) and target > 0 do
    new(name, target, a1, 1)
  end
  @spec u1(map, U.unitary, non_neg_integer, atom) :: Qit.circut
  def u1(m, a1 = %Unitary{}, target, name)
      when is_map(m) and is_atom(name) and is_integer(target) and target > 0 do
    u = u1(a1, target, name)
    u1(m , u)
  end

  @spec u1(U.unitary, non_neg_integer) :: qop
  def u1(a1 = %Unitary{}, target)
      when is_integer(target) and target > 0 do
    new(:u1, target, a1, 1)
  end
  @spec u1(map, U.unitary, non_neg_integer) :: Qit.circuit
  def u1(m, a1 = %Unitary{}, target)
     when is_map(m) and is_integer(target) and target > 0, do: u1(m, u1(a1, target))

  @spec u1(list(C.real_complex), non_neg_integer, atom) :: qop
  def u1(a1, target, name)
      when is_list(a1) and is_integer(target) and target > 0, do: u1(U.new(a1), target, name)
  @spec u1(map,list(C.real_complex), non_neg_integer, atom) :: Qit.circuit
  def u1(m, a1, target, name)
      when is_map(m) and is_list(a1) and is_integer(target) and target > 0 do
        u = u1(U.new(a1), target, name)
        u1(m, u)
      end

  @spec u1(list(C.real_complex), non_neg_integer) :: qop
  def u1(a1, target)
      when is_list(a1) and is_integer(target) and target > 0, do: u1(U.new(a1),target, :u1)
  @spec u1(map, list(C.real_complex), non_neg_integer) :: qop
  def u1(m, a1, target)
      when is_map(m) and is_list(a1) and is_integer(target) and target > 0 do
        u = u1(U.new(a1),target, :u1)
        u1(m, u)
      end

  @doc """
  X gate.

  ## Examples

    iex> QuantEx.Qop.x.n
    1
    iex> QuantEx.Qop.x.shape
    [2, 2]

  """
  @spec x(non_neg_integer, Qit.circuit) :: Qit.circuit
  @spec x(non_neg_integer, U.unitary) :: Qit.circuit
  @spec x(non_neg_integer, Q.qubit) :: Qit.circuit
  @spec x(non_neg_integer, C.real_complex) :: Qit.circuit
  def x(a1, a2) when is_integer(a1) do
    case { Qit.is_circuit(a2) } do
      {true} -> nil #FIXME: should implement
    end
    case { U.is_unitary(a2) } do
      {true} -> nil #FIXME: should implement
    end
    case { Q.is_qubit(a2) } do
      {true} -> nil #FIXME: should implement
    end
    case { is_number(a2) or C.is_complex(a2) } do
      {true} -> new(:coeff, opts: a2) * new(:x, a1)
    end
  end
  @spec x(non_neg_integer) :: qop
  def x(t \\ nil), do: new(:x, t)


  @doc """
  Y gate.

  ## Examples

    iex> QuantEx.Qop.y.n
    1
    iex> QuantEx.Qop.y.shape
    [2, 2]

  """
  @spec y(integer, Q.qubit) :: Qit.circuit
  @spec y(integer) :: U.unitary
  @spec y() :: U.unitary
  def y(n, q), do: nil
  def y(n), do: &y(n, &1)
  def y, do: U.new([C.new(0), C.new(0,-1), C.new(0,1), C.new(0)])

  @doc """
  Z gate.

  ## Examples

    iex> QuantEx.Qop.z.n
    1
    iex> QuantEx.Qop.z.shape
    [2, 2]

  """
  @spec z(integer, Q.qubit) :: Qit.circuit
  @spec z(integer) :: U.unitary
  @spec z() :: U.unitary
  def z(n, q), do: nil
  def z(n), do: &z(n, &1)
  def z, do: U.new([C.new(1), C.new(0), C.new(0), C.new(-1)])

  defp r1_2, do:  Complex.div(1, :math.sqrt(2))

  @doc """
  H(Hadamard) gate.

  ## Examples

    iex> QuantEx.Qop.h.n
    1
    iex> QuantEx.Qop.h.shape
    [2, 2]

  """
  @spec h(integer, Q.qubit) :: Qit.circuit
  @spec h(integer) :: U.unitary
  @spec h() :: U.unitary
  def h(n, q), do: nil
  def h(n), do: &h(n, &1)
  def h, do: U.new([C.new(r1_2()), C.new(r1_2()), C.new(r1_2()), C.new(-1*r1_2())])

  @doc """
  CX(CNOT) gate.

  ## Examples

    iex> QuantEx.Qop.cx.n
    2
    iex> QuantEx.Qop.cx.shape
    [4, 4]
    iex> QuantEx.Qop.cnot.n
    2
    iex> QuantEx.Qop.cnot.shape
    [4, 4]

  """
  @spec cx(integer, Q.qubit) :: Qit.circuit
  @spec cx(integer) :: U.unitary
  @spec cx() :: U.unitary
  def cx(n, q), do: nil
  def cx(n), do: &cx(n, &1)
  def cx, do: U.new([C.new(1), C.new(0), C.new(0), C.new(0),
                     C.new(0), C.new(1), C.new(0), C.new(0),
                     C.new(0), C.new(0), C.new(0), C.new(1),
                     C.new(0), C.new(0), C.new(1), C.new(0)
                    ])

  @spec cnot(integer, Q.qubit) :: Qit.circuit
  @spec cnot(integer) :: U.unitary
  @spec cnot() :: U.unitary
  def cnot(n, q), do: cx(n, q)
  def cnot(n), do: cx(n)
  def cnot, do: cx()

# @doc """
# Calculate tensor product.<br>
# TODO: Later, transfer to Numexy github
#
# ## Examples
#   iex> Q.tensordot( Q.q0(), Q.q0(), 0 )
#   Numexy.new( [ 1, 0, 0, 0 ] )
#   iex> Q.tensordot( Q.q0(), Q.q1(), 0 )
#   Numexy.new( [ 0, 1, 0, 0 ] )
#   iex> Q.tensordot( Q.q1(), Q.q0(), 0 )
#   Numexy.new( [ 0, 0, 1, 0 ] )
#   iex> Q.tensordot( Q.q1(), Q.q1(), 0 )
#   Numexy.new( [ 0, 0, 0, 1 ] )
# """
# def tensordot( %Array{ array: xm, shape: _xm_shape }, %Array{ array: ym, shape: _ym_shape }, _axes ) do
#   xv = List.flatten( xm )
#   yv = List.flatten( ym )
#   xv
#   |> Enum.map( fn x -> yv |> Enum.map( fn y -> x * y end ) end )
#   |> List.flatten
#   |> Numexy.new
# end
end
