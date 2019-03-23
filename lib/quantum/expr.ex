defmodule Expr do
  @moduledoc """
  A math-expression parser, evaluator and formatter for Elixir.

  ### Supported operators

   - `+`, `-`, `/`, `*`
   - Exponentials with `^`
   - Bitwise operators
     * `<<` `>>` bitshift
     * `&` bitwise and
     * `|` bitwise or
     * `|^` bitwise xor
     * `~` bitwise not (unary)
   - Boolean operators
     * `&&`, `||`, `not`
     * `==`, `!=`, `>`, `>=`, `<`, `<=`
     * Ternary `condition ? if_true : if_false`

  ### Supported functions

   - `sin(x)`, `cos(x)`, `tan(x)`, `exp(x)`
   - `round(n, precision = 0)`, `ceil(n, precision = 0)`, `floor(n, precision = 0)`

  ### Reserved words

   - `true`
   - `false`
   - `nil`

  ### Access to variables in scope

   - `a` with scope `%{"a" => 10}` would evaluate to `10`
   - `a.b` with scope `%{"a" => %{"b" => 42}}` would evaluate to `42`
   - `list[2]` with scope `%{"list" => [1, 2, 3]}` would evaluate to `3`

  ### Data types

   - Boolean: `true`, `false`
   - None: `nil`
   - Integer: `0`, `40`, `-184`
   - Float: `0.2`, `12.`, `.12`
   - String: `"Hello World"`, `"He said: \"Let's write a math parser\""`

  If a variable is not in the scope, `eval/2` will result in `{:error, error}`.
  """

  @doc """
  Evaluates the given expression with no scope.

  If `expr` is a string, it will be parsed first.
  """
  @spec eval(expr::tuple | charlist | String.t) :: {:ok, result::number} | {:error, error::map}
  @spec eval(expr::tuple | charlist | String.t, scope::map) :: {:ok, result::number} | {:error, error::map}

  @spec eval!(expr::tuple | charlist | String.t) :: result::number
  @spec eval!(expr::tuple | charlist | String.t, scope::map) :: result::number
  def eval(expr), do: eval(expr, %{})

  @doc """
  Evaluates the given expression.

  Raises errors when parsing or evaluating goes wrong.
  """
  def eval!(expr), do: eval!(expr, %{})

  @doc """
  Evaluates the given expression with the given scope.

  If `expr` is a string, it will be parsed first.
  """
  def eval!(expr, scope) do
    case Expr.Eval.eval(expr, scope) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def eval(expr, scope) when is_binary(expr) or is_bitstring(expr) do
    with {:ok, parsed} <- parse(expr) do
      eval(parsed, scope)
    end
  end

  def eval(expr, scope) do
    Expr.Tree.reduce(expr, &Expr.Eval.eval(&1, scope))
  end

  @doc """
  Pretty-prints the given expression.

  If `expr` is a string, it will be parsed first.
  """
  @spec format(expr :: tuple | String.t | charlist) :: {:ok, String.t} | {:error, error::map}

  def format(expr) when is_binary(expr) or is_bitstring(expr) do
    case parse(expr) do
      {:ok, expr} ->
        format(expr)
      {:error, _} = error -> error
    end
  end

  def format(expr) do
    try do
      {:ok, Expr.Format.format(expr)}
    rescue
      error -> {:error, error}
    end
  end

  @spec parse(expr :: String.t | charlist) :: {:ok, expr::tuple} | {:error, error::map}
  @doc """
  Parses the given `expr` to a syntax tree.
  """
  def parse(expr) do
    with {:ok, tokens} <- lex(expr) do
      :math_term_parser.parse(tokens)
    else
      {:error, error, _} -> {:error, error}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  """
  def variables(expr) do
    Expr.Tree.reduce(expr, fn
      {:access, variables} ->
        res = Enum.map(variables, fn
          {:variable, var} -> var
          {:index, index} -> variables(index)
        end)
        |> List.flatten
        |> Enum.uniq
        {:ok, res}
      {_operator, a, b, c} ->
        res = Enum.concat([a, b, c])
        |> Enum.uniq
        {:ok, res}
      {_operator, a, b} ->
        res = Enum.concat(a, b)
        |> Enum.uniq
        {:ok, res}
      {_operator, a} -> a
      _ -> {:ok, []}
    end)
  end

  defp lex(string) when is_binary(string) do
    string
    |> String.to_charlist
    |> lex
  end

  defp lex(string) do
    with {:ok, tokens, _} <- :math_term.string(string) do
      {:ok, tokens}
    end
  end
end

defmodule Expr.Format do
  @moduledoc """
  Function definitions on how to pretty-print expressions.

  See `Expr.format/1` for more information.
  """

  @binary_operators [:add, :subtract, :divide, :multiply, :power,
    :and, :or, :xor, :shift_left, :shift_right,
    :eq, :neq, :gt, :gte, :lt, :lte,
    :logical_and, :logical_or]
  @unary_operators [:logical_not, :not]
  @zary_operators []
  @operators Enum.concat([@binary_operators, @unary_operators, @zary_operators])

  @doc """
  """
  @spec format(expr::tuple | number | boolean | nil) :: String.t

  def format(number) when is_integer(number), do: Integer.to_string(number)
  def format(number) when is_float(number), do: Float.to_string(number)
  def format(string) when is_binary(string) do
    # TODO: binary string
  end

  def format({operator, a, b} = expr) when operator in @binary_operators do
    op_string = format(operator)

    lhs = format a
    rhs = format b

    without_parantheses = "#{lhs} #{op_string} #{rhs}"
    with_left_parantheses = "(#{lhs}) #{op_string} #{rhs}"
    with_right_parantheses = "#{lhs} #{op_string} (#{rhs})"
    with_both_parantheses = "(#{lhs}) #{op_string} (#{rhs})"

    result = {
      Expr.parse(without_parantheses),
      Expr.parse(with_left_parantheses),
      Expr.parse(with_right_parantheses),
      Expr.parse(with_both_parantheses)
    }

    case result do
      {{:ok, ^expr}, _, _, _} -> without_parantheses
      {_, {:ok, ^expr}, _, _} -> with_left_parantheses
      {_, _, {:ok, ^expr}, _} -> with_right_parantheses
      {_, _, _, {:ok, ^expr}} -> with_both_parantheses
    end
  end

  def format({:function, name, arguments}) do
    arguments = arguments
    |> Enum.map(&format/1)
    |> Enum.join(", ")

    "#{name}(#{arguments})"
  end

  def format({:factorial, a} = expr) do
    a = format a
    with_parantheses = "(#{a})!"
    without_parantheses = "#{a}!"

    result = {
      Expr.parse(without_parantheses),
      Expr.parse(with_parantheses)
    }

    case result do
      {{:ok, ^expr}, _} -> without_parantheses
      {_, {:ok, ^expr}} -> with_parantheses
    end
  end

  def format({operator, a} = expr) when operator in @unary_operators do
    a = format a
    op = format operator
    with_parantheses = "#{op}(#{a})"
    without_parantheses = "#{op}#{a}"

    result = {
      Expr.parse(without_parantheses),
      Expr.parse(with_parantheses)
    }

    case result do
      {{:ok, ^expr}, _} -> without_parantheses
      {_, {:ok, ^expr}} -> with_parantheses
    end
  end

  def format({:ternary_if, condition, if_true, if_false} = expr) do
    fcondition = format condition
    ftrue = format if_true
    ffalse = format if_false

    v = [false, true]

    permutations = for c <- v, t <- v, f <- v do
      format = "#{parantheses fcondition, c} ? #{parantheses ftrue, t} : #{parantheses ffalse, f}"
      {:ok, expr} = Expr.parse(format)
      {format, expr}
    end

    {format, _} = permutations
    |> Enum.filter(fn {_format, e} -> e == expr end)
    |> List.first

    format
  end


  def format(operator) when operator in @operators do
    case operator do
      :add -> "+"
      :subtract -> "-"
      :divide -> "/"
      :multiply -> "*"
      :power -> "^"
      :and -> "&"
      :or -> "|"
      :xor -> "|^"
      :not -> "~"
      :shift_left -> "<<"
      :shift_right -> ">>"
      :eq -> "=="
      :neq -> "!="
      :gt -> ">"
      :gte -> ">="
      :lt -> "<"
      :lte -> "<="
      :logical_and -> "&&"
      :logical_or -> "||"
      :logical_not -> "not"
    end
  end

  def format({:access, [{:variable, name} | rest]}) do
    case rest do
      [] -> name
      [{:index, _} | _] -> "#{name}#{format {:access, rest}}"
      [{:variable, _} | _] -> "#{name}.#{format {:access, rest}}"
    end
  end

  def format({:access, [{:index, expr} | rest]}) do
    case rest do
      [] -> "[#{format expr}]"
      [{:index, _} | _] -> "[#{format expr}]#{format {:access, rest}}"
      [{:variable, _} | _] -> "[#{format expr}].#{format {:access, rest}}"
    end
  end

  def format(false), do: "false"
  def format(true), do: "true"
  def format(nil), do: "nil"

  def format(expr), do: {:error, "Can't format #{inspect expr}"}

  defp parantheses(expr, true), do: "(#{expr})"
  defp parantheses(expr, false), do: expr
end

defmodule Expr.Compile do
  @moduledoc """
  """

  @conversion [
    add: :+,
    subtract: :-,
    divide: :/,
    multiply: :*,
    logical_and: :&&,
    logical_or: :||,
    eq: :==,
    neq: :!=,
    gt: :>,
    lt: :<,
    gte: :>=,
    lte: :<=,
  ]

  for {expr, elixir} <- @conversion do
    def compile({unquote(expr), a, b}) do
      {:ok, {
        unquote(elixir),
        [],
        [a, b]}}
    end
  end

  def compile(num) when is_number(num), do: {:ok, num}
  def compile(other) when other in [true, false, nil], do: {:ok, other}
end

defmodule Expr.Eval do
  @moduledoc """
  Function definitions on how to evaluate a syntax tree.

  You usually don't need to call `eval/2` yourself, use `Expr.eval/2` instead.
  """

  use Bitwise

  @doc """
  """
  @spec eval(expr::tuple | number, scope::map) :: {:ok, result::number} | {:ok, boolean} | {:ok, nil} | {:error, term}

  # BASIC ARITHMETIC

  def eval({:add, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a + b}
  def eval({:subtract, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a - b}
  def eval({:divide, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a / b}
  def eval({:multiply, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a * b}

  # OTHER OPERATORS

  def eval({:power, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, :math.pow(a, b)}

  # COMPARISION

  def eval({:eq, a, b}, _),
    do: {:ok, equals(a, b)}
  def eval({:neq, a, b}, _),
    do: {:ok, not equals(a, b)}

  def eval({:gt, a, b}, _),
    do: {:ok, a > b}
  def eval({:gte, a, b}, _),
    do: {:ok, a >= b}
  def eval({:lt, a, b}, _),
    do: {:ok, a < b}
  def eval({:lte, a, b}, _),
    do: {:ok, a <= b}

  # LOGICAL COMPARISION

  def eval({:logical_and, a, b}, _)
    when is_boolean(a) and is_boolean(b),
    do: {:ok, a && b}

  def eval({:logical_or, a, b}, _)
    when is_boolean(a) and is_boolean(b),
    do: {:ok, a || b}

  def eval({:logical_not, a}, _)
    when is_boolean(a),
    do: {:ok, not a}

  def eval({:ternary_if, condition, if_true, if_false}, _) do
    if condition do
      {:ok, if_true}
    else
      {:ok, if_false}
    end
  end

  # FUNCTIONS

  def eval({:function, "sin", [a]}, _)
    when is_number(a),
    do: {:ok, :math.sin(a)}
  def eval({:function, "cos", [a]}, _)
    when is_number(a),
    do: {:ok, :math.cos(a)}
  def eval({:function, "tan", [a]}, _)
    when is_number(a),
    do: {:ok, :math.tan(a)}
  def eval({:function, "exp", [a]}, _)
    when is_number(a),
    do: {:ok, :math.exp(a)}

  def eval({:function, "floor", [a]}, _)
    when is_number(a),
    do: {:ok, Float.floor(a)}
  def eval({:function, "floor", [a, precision]}, _)
    when is_number(a) and is_number(precision),
    do: {:ok, Float.floor(a, precision)}

  def eval({:function, "ceil", [a]}, _)
    when is_number(a),
    do: {:ok, Float.ceil(a)}
  def eval({:function, "ceil", [a, precision]}, _)
    when is_number(a) and is_number(precision),
    do: {:ok, Float.ceil(a, precision)}

  def eval({:function, "round", [a]}, _)
    when is_number(a),
    do: {:ok, Float.round(a)}
  def eval({:function, "round", [a, precision]}, _)
    when is_number(a) and is_number(precision),
    do: {:ok, Float.round(a, precision)}

  def eval({:function, "log10", [a]}, _)
    when is_number(a),
    do: {:ok, :math.log10(a)}

  # IDENTITY

  def eval(number, _)
    when is_number(number),
    do: {:ok, number}
  def eval(reserved, _)
    when reserved in [nil, true, false],
    do: {:ok, reserved}
  def eval(string, _)
    when is_binary(string),
    do: {:ok, string}

  # ACCESS

  def eval({:access, _} = expr, scope) do
    eval expr, scope, scope
  end

  # BINARY OPERATORS

  def eval({:not, expr}, _)
    when is_number(expr),
    do: {:ok, bnot(expr)}
  def eval({:and, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, band(a, b)}
  def eval({:or, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, bor(a, b)}
  def eval({:xor, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, bxor(a, b)}

  def eval({:shift_right, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a >>> b}
  def eval({:shift_left, a, b}, _)
    when is_number(a) and is_number(b),
    do: {:ok, a <<< b}

  # CATCH-ALL
  def eval(_expr, _scope), do: {:error, :einval}

  # SPECIAL HANDLING FOR ACCESS

  defp eval({:access, [{:variable, name} | rest]}, scope, root) do
    case Map.get(scope, name, nil) do
      nil -> {:error, :einkey}
      value ->
        eval({:access, rest}, value, root)
    end
  end

  defp eval({:access, [{:index, index} | rest]}, scope, root) do
    {:ok, index} = Expr.Tree.reduce(index, &eval(&1, root))
    case Enum.at(scope, index, nil) do
      nil -> {:error, :einkey}
      value ->
        eval({:access, rest}, value, root)
    end
  end

  defp eval({:access, []}, value, _root), do: {:ok, value}

  defp equals(str, atom) when is_binary(str) and is_atom(atom), do: str == Atom.to_string(atom)
  defp equals(atom, str) when is_binary(str) and is_atom(atom), do: str == Atom.to_string(atom)
  defp equals(a, b), do: a == b
end

defmodule Expr.Tree do
  @moduledoc """
  """

  @doc """
  Works like Enum.reduce, but for trees
  """
  @spec reduce(expr::term, fun::function) :: term

  def reduce({:function, name, args}, fun) do
    # reduce all arguments
    args
    |> Enum.reduce(%{ok: [], error: []}, fn arg, %{ok: oks, error: errors} ->
      case reduce(arg, fun) do
        {:ok, res} ->
          %{ok: [res | oks], error: errors}
        {:error, res} ->
          %{ok: oks, error: [res, errors]}
      end
    end)
    |> case do
      %{error: [], ok: args} ->
        fun.({:function, name, Enum.reverse(args)})
      %{error: errors} -> {:error, errors}
    end
  end

  def reduce({operator, a, b, c}, fun) do
    with {:ok, a} <- reduce(a, fun),
         {:ok, b} <- reduce(b, fun),
         {:ok, c} <- reduce(c, fun) do
      fun.({operator, a, b, c})
    end
  end

  def reduce({operator, a, b}, fun) do
    with {:ok, a} <- reduce(a, fun),
         {:ok, b} <- reduce(b, fun) do
      fun.({operator, a, b})
    end
  end

  def reduce({:access, _} = expr, fun) do
    fun.(expr)
  end

  def reduce({operator, a}, fun) do
    with {:ok, a} <- reduce(a, fun) do
      fun.({operator, a})
    end
  end

  def reduce(other, fun) when is_number(other) or other in [nil, true, false] or is_binary(other) do
    fun.(other)
  end
end

