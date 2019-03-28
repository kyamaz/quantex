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

defmodule QuantEx.Processor do
  @moduledoc """
  Circuit library namespace.
  use `use QuantEx.Qpu` to alias `Qpu`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias QuantEx.Qpu
    end
  end
end

defmodule QuantEx.Qpu do
  @moduledoc """
  """

  alias QuantEx.Qpu

  defstruct n: 0, profile: {}

  @type t(num, lis) :: %Qpu{n: num, profile: lis}
  @type t :: %Qpu{n: non_neg_integer, profile: list}
  @opaque qpu :: %Qpu{}

  defimpl Inspect, for: Qit do
    def inspect(q, _opts) do
      "Qpu[#{q.n}]:(#{inspect q.profile})"
    end
  end

  @spec new(integer, tuple) :: qpu
  def new(nn, prof) when is_number(nn) and is_tuple(prof) do
    %Qpu{n: nn, profile: prof}
  end

  @spec qpu?(term) :: boolean
  def qpu?(%Qpu{}), do: true
  def qpu?(_), do: false

end
