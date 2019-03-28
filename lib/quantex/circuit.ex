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

defmodule QuantEx.Circuit do
  @moduledoc """
  Circuit library namespace.
  use `use QuantEx.Qit` to alias `Qit`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias QuantEx.Qit
    end
  end
end

defmodule QuantEx.Qit do
  @moduledoc """
  """

  use QuantEx.Unitary
  alias QuantEx.Qit

  defstruct n: 0, gates: []

  @type t(num, lis) :: %Qit{n: num, gates: lis}
  @type t :: %Qit{n: non_neg_integer, gates: list}
  @opaque circuit :: %Qit{}

  defimpl Inspect, for: Qit do
    def inspect(q, _opts) do
      "Qit[#{q.n}]:(#{inspect q.gates})"
    end
  end

  @spec new(integer, list) :: circuit
  def new(nn, list) when is_number(nn) and is_list(list) do
    %Qit{n: nn, gates: list}
  end

  @spec circuit?(term) :: boolean
  def circuit?(%Qit{}), do: true
  def circuit?(_), do: false

end
