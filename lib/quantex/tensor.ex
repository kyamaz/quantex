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

defmodule QuantEx.Tensor do
  @moduledoc """
  Tensor library namespace.
  use `use QuantEx.Tensor` to alias `Tensor`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Tensor.Tensor
    end
  end
end

defmodule Tensor.Tensor do
  @base_fields [shape: [1], to_list: []]
  defmacro __using__(fields) do
    fields = fields ++ @base_fields
    quote do
      defstruct unquote(fields)
    end
  end

  alias Tensor.Tensor
  defstruct [shape: [1], to_list: []]     # shape is upper to lower

  use QuantEx.Complex
  alias Complex, as: C

  @behaviour Numbers.Numeric

  @type t(sh, arr) :: %Tensor{shape: sh, to_list: arr}
  @type t :: %Tensor{shape: list(non_neg_integer), to_list: list(C.real_complex)}
  @opaque tensor :: %Tensor{}

  defmodule ArithmeticError do
    defexception message: "Tensor arithmetic error."
  end

  defmodule DimensionError do
    defexception message: "Tensor dimension error."
  end

  defimpl Inspect, for: Tensor do
    def inspect(tensor, _opts) do
      "Tensor[#{tensor.shape |> Enum.reverse |> Enum.join("x")}] (#{inspect tensor.to_list})"
    end
  end

  defimpl Enumerable do

    @spec count(atom() | %{dimensions: any()}) :: {:ok, any()}
    def count(tensor), do: {:ok, Enum.reduce(tensor.shape, 1, &(&1 * &2))}

    @spec member?(any(), any()) :: {:error, Enumerable.Tensor.Tensor}
    def member?(_tensor, _element), do: {:error, __MODULE__}

    def reduce(tensor, acc, fun) do
      tensor
      # |> Tensor.slices
      |> do_reduce(acc, fun)
    end

    defp do_reduce(_,       {:halt, acc}, _fun),   do: {:halted, acc}
    defp do_reduce(list,    {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(list, &1, fun)}
    defp do_reduce([],      {:cont, acc}, _fun),   do: {:done, acc}
    defp do_reduce([h | t], {:cont, acc}, fun),    do: do_reduce(t, fun.(h, acc), fun)

    @spec slice(any()) :: {:error, Enumerable.Tensor.Tensor}
    def slice(_tensor) do
      {:error, __MODULE__}
    end

  end

  @doc """
  """
  @spec new([], [non_neg_integer]) :: tensor
  def new(nested_list_of_values, sh \\ []) do
    lists = nested_list_of_values
            |> List.flatten
    shapes = sh |> Enum.reverse
    %Tensor{to_list: lists, shape: shapes}
  end

  @doc """
  """
  @spec is_tensor(term) :: boolean
  def is_tensor(s), do: is_map(s) && Map.has_key?(s, :__struct__) && s.__struct__ == Tensor

  @doc """
  """
  @spec tensor?(tensor) :: boolean
  def tensor?(%Tensor{}), do: true

  @doc """
  """
  @spec vector?(tensor) :: boolean
  def vector?(%Tensor{shape: [_]}), do: true
  def vector?(%Tensor{}), do: false

  @doc """
  """
  @spec matrix?(tensor) :: boolean
  def matrix?(%Tensor{shape: [_,_]}), do: true
  def matrix?(%Tensor{}), do: false

  @doc """
  """
  @spec order(tensor) :: non_neg_integer
  def order(tensor) do
    length(tensor.shape)
  end

  @doc """
  """
  @spec dimensions(tensor) :: [non_neg_integer]
  def dimensions(tensor = %Tensor{}) do
    tensor.shape |> Enum.reverse
  end

  @doc """
  """
  @spec shapes(tensor) :: [non_neg_integer]
  def shapes(tensor = %Tensor{}) do
    tensor.shape
  end

  @doc """
  """
  @spec to_list(tensor) :: list
  def to_list(tensor = %Tensor{}) do
    tensor.to_list
  end

  @doc """
  """
  @spec lift(tensor) :: tensor
  def lift(tensor) do
    %Tensor{
      shape: [1|tensor.shape],
      to_list: tensor.to_list
    }
  end

  #@doc """
  #@spec slice(tensor) :: tensor || []
  #@spec slices(tensor) :: tensor || []
  #"""

  @spec map(tensor, (any -> any)) :: tensor
  def map(tensor, fun) do
    %Tensor{tensor | to_list: tensor.to_list |> Enum.map(fun)}
  end

  @doc """
  """
  def merge_with_index(tensor_a = %Tensor{shape: dimensions}, tensor_b = %Tensor{shape: dimensions}, fun) do
    %Tensor{}
  end
  def merge_with_index(_tensor_a, _tensor_b, _fun) do
    raise DimensionError
  end

  @doc """
  """
  @spec merge(%Tensor{}, %Tensor{}, (a, a -> any)) :: %Tensor{} when a: any
  def merge(tensor_a, tensor_b, fun) do
    merge_with_index(tensor_a, tensor_b, fn _k, a, b -> fun.(a, b) end)
  end

  @doc """
  """
  @spec add(tensor , tensor) :: tensor
  @spec add(Numeric.t, tensor) :: tensor
  @spec add(tensor, Numeric.t) :: tensor
  def add(a = %Tensor{}, b = %Tensor{}), do: add_tensor(a, b)
  def add(a = %Tensor{}, b), do: add_number(a, b)
  def add(a, b = %Tensor{}), do: add_number(a, b)

  @doc """
  """
  @spec add_tensor(tensor, tensor) :: tensor
  def add_tensor(tensor_a = %Tensor{}, tensor_b = %Tensor{}) do
    Tensor.merge(tensor_a, tensor_b, &(Numbers.add(&1, &2)))
  end

  @doc """
  """
  @spec add_number(tensor, Numeric.t) :: tensor
  def add_number(a = %Tensor{}, b) do
    Tensor.map(a, &(Numbers.add(&1, b)))
  end
  def add_number(a, b = %Tensor{}) do
    Tensor.map(b, &(Numbers.add(a, &1)))
  end

  @doc """
  """
  @spec sub(tensor , tensor) :: tensor
  @spec sub(Numeric.t, tensor) :: tensor
  @spec sub(tensor, Numeric.t) :: tensor
  def sub(a = %Tensor{}, b = %Tensor{}), do: sub_tensor(a, b)
  def sub(a = %Tensor{}, b), do: sub_number(a, b)
  def sub(a, b = %Tensor{}), do: sub_number(a, b)

  @doc """
  """
  @spec sub_tensor(tensor, tensor) :: tensor
  def sub_tensor(tensor_a = %Tensor{}, tensor_b = %Tensor{}) do
    Tensor.merge(tensor_a, tensor_b, &(Numbers.sub(&1, &2)))
  end

  @doc """
  """
  @spec sub_number(tensor, Numeric.t) :: tensor
  def sub_number(a = %Tensor{}, b) do
    Tensor.map(a, &(Numbers.sub(&1, b)))
  end
  def sub_number(a, b = %Tensor{}) do
    Tensor.map(b, &(Numbers.sub(a, &1)))
  end

  @doc """
  """
  @spec mult(tensor , tensor) :: tensor
  @spec mult(Numeric.t, tensor) :: tensor
  @spec mult(tensor, Numeric.t) :: tensor
  def mult(a = %Tensor{}, b = %Tensor{}), do: mult_tensor(a, b)
  def mult(a = %Tensor{}, b), do: mult_number(a, b)
  def mult(a, b = %Tensor{}), do: mult_number(a, b)

  @doc """
  """
  @spec mult_tensor(tensor, tensor) :: tensor
  def mult_tensor(tensor_a = %Tensor{}, tensor_b = %Tensor{}) do
    Tensor.merge(tensor_a, tensor_b, &(Numbers.mult(&1, &2)))
  end

  @doc """
  """
  @spec mult_number(tensor, number) :: tensor
  def mult_number(a = %Tensor{}, b) do
    Tensor.map(a, &(Numbers.mult(&1, b)))
  end
  def mult_number(a, b = %Tensor{}) do
    Tensor.map(b, &(Numbers.mult(a, &1)))
  end

  @doc """
  """
  @spec div(tensor , tensor) :: tensor
  @spec div(Numeric.t, tensor) :: tensor
  @spec div(tensor, Numeric.t) :: tensor
  def div(a = %Tensor{}, b = %Tensor{}), do: div_tensor(a, b)
  def div(a = %Tensor{}, b), do: div_number(a, b)
  def div(a, b = %Tensor{}), do: div_number(a, b)

  @doc """
  """
  @spec div_tensor(tensor, tensor) :: tensor
  def div_tensor(tensor_a = %Tensor{}, tensor_b = %Tensor{}) do
    Tensor.merge(tensor_a, tensor_b, &(Numbers.div(&1, &2)))
  end

  @doc """
  """
  @spec div_number(tensor, number) :: tensor
  def div_number(a = %Tensor{}, b) do
    Tensor.map(a, &(Numbers.div(&1, b)))
  end
  def div_number(a, b = %Tensor{}) do
    Tensor.map(b, &(Numbers.div(a, &1)))
  end

  @doc """
  """
  @spec swap(list, non_neg_integer, non_neg_integer) :: list
  defp swap(list, a, b) when a < b do
    {h, rest} = Enum.split(list, a)
    {center, t} = Enum.split(rest, b - a)
    h ++ [hd(t)] ++ tl(center) ++ [hd(center)] ++ tl(t)
  end
  defp swap(list, a, b) when b < a, do: swap(list, b, a)
  defp swap(list, a, a), do: list

end
