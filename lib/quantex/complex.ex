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

defmodule QuantEx.Complex do
  @moduledoc """
  Tensor library namespace.
  use `use QuantEx.Complex` to alias `Complex`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Complex
    end
  end
end

defmodule Complex do
  @moduledoc """
  Functions for complex numbers.
  """

  import Kernel, except: [abs: 1, div: 2]

  defstruct re: 0.0, im: 0.0

  @typep t(real, imag) :: %Complex{re: real, im: imag}
  @typep t :: %Complex{re: number, im: number}

  @opaque complex :: %Complex{}
  @type real_complex :: t | number

  defimpl Inspect, for: Complex do
    def inspect(complex, _opts) do
      "(#{complex.re})+(#{complex.im})i"
    end
  end

  @spec is_complex(term) :: boolean
  def is_complex(%Complex{}), do: true

  @spec new(number, number) :: complex
  def new(real \\ 0.0, imag \\ 0.0), do: %Complex{re: real, im: imag}

  @spec convert(real_complex) :: t
  def convert(x = %Complex{}), do: x
  def convert(r), do: new(r, 0.0)

  @doc guard: true
  @spec is_complex(complex) :: boolean
  def is_complex(term) do
    true
  end

  @spec to_complex(number, number) :: complex
  def to_complex(real \\ 0.0, imag \\ 0.0), do: new(real, imag)

  @doc """
    Parses a complex number from a string.

    #### Examples
      iex> Complex.parse("1.1+2.2i")
      %Complex{im: 2.2, re: 1.1}
      iex> Complex.parse("-1.1+-2.2i")
      %Complex{im: -2.2, re: -1.1}
  """
  @spec parse(String.t()) :: complex
  def parse(str) do
    [_, real, imag] = Regex.run(~r/([-]?\d+\.\d+)\+([-]?\d+\.\d+)i/, str)
    new(String.to_float(real), String.to_float(imag))
  end

  @spec real(real_complex) :: number
  def real(c), do: c.r

  @spec imag(real_complex) :: number
  def imag(c), do: c.i

  @spec i(real_complex) :: number
  def i(c), do: imag(c)

  @spec add(real_complex, real_complex) :: real_complex
  def add(%Complex{re: r1, im: i1}, %Complex{re: r2, im: i2}) do
    new r1 + r2, i1 + i2
  end
  def add(%Complex{re: r1, im: i}, r2), do: new(r1 + r2, i)
  def add(r1, %Complex{re: r2, im: i}), do: new(r1 + r2, i)
  def add(a, b), do: a + b
  def add(a), do: &add(a, &1)
  def add, do: &add(&1)

  @spec sub(real_complex, real_complex) :: real_complex
  def sub(%Complex{re: r1, im: i1}, %Complex{re: r2, im: i2}) do
    new r1 - r2, i1 - i2
  end
  def sub(%Complex{re: r1, im: i}, r2), do: new(r1 - r2, i)
  def sub(r1, %Complex{re: r2, im: i}), do: new(r1 - r2, -i)
  def sub(a, b), do: a - b
  def sub(a), do: &sub(a, &1)
  def sub, do: &sub(&1)

  @spec mul(real_complex, real_complex) :: real_complex
  def mul(%Complex{re: r1, im: i1}, %Complex{re: r2, im: i2}) do
    new r1*r2 - i1*i2, r1*i2 + i1*r2
  end
  def mul(%Complex{re: r, im: i}, x), do: new(x*r, x*i)
  def mul(x, %Complex{re: r, im: i}), do: new(x*r, x*i)
  def mul(a, b), do: a*b
  def mul(a), do: &mul(a, &1)
  def mul, do: &mul(&1)

  @spec div(real_complex, real_complex) :: t | float
  def div(%Complex{re: r1, im: i1}, %Complex{re: r2, im: i2}) do
    if Kernel.abs(r2) >= Kernel.abs(i2) do
      rat = i2/r2
      den = r2 + i2*rat

      Complex.new (r1 + i1*rat)/den, (i1 - r1*rat)/den
    else
      rat = r2/i2
      den = r2*rat + i2

      Complex.new (r1*rat + i1)/den, (i1*rat - r1)/den
    end
  end
  def div(%Complex{re: r, im: i}, x), do: new(r/x, i/x)
  def div(a, b = %Complex{}), do: div(convert(a), b)
  def div(a, b), do: a/b
  def div(a), do: &div(a, &1)
  def div, do: &div(&1)

  @spec equal?(real_complex, real_complex) :: boolean
  def equal?(%Complex{re: r1, im: i1}, %Complex{re: r2, im: i2}) do
    r1 == r2 and i1 == i2
  end
  def equal?(a, b), do: equal?(convert(a), convert(b))

  @spec neg(a) :: a when a: real_complex
  def neg(%Complex{re: r, im: i}), do: new(-r, -i)
  def neg(x), do: -x

  @spec abs(real_complex) :: number
  def abs(%Complex{re: r, im: i}), do: hypot(r, i)
  def abs(x), do: Kernel.abs(x)

  @spec conj(t) :: t
  @spec conj(a) :: a when a: number
  def conj(%Complex{re: r, im: i}), do: new(r, -i)
  def conj(x), do: x

  @spec hypot(number, number) :: float
  defp hypot(a, b) do
    a = abs(a)
    b = abs(b)

    if a == 0 do
      0.0
    else
      :math.sqrt(a*a + b*b)
    end
  end

end
