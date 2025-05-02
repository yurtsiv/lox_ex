defmodule Lox.Expression do
  alias Lox.Token
  alias __MODULE__, as: Expr

  @type t() :: %__MODULE__{
          body: Expr.Binary.t() | Expr.Grouping.t() | Expr.Literal.t() | Expr.Unary.t()
        }

  defstruct [:body]

  defmodule Binary do
    @type t() :: %__MODULE__{
            left: Expr.t(),
            operator: Token.t(),
            right: Expr.t()
          }

    defstruct [:left, :operator, :right]
  end

  defmodule Grouping do
    @type t() :: %__MODULE__{
            expression: Expr.t()
          }

    defstruct [:expression]
  end

  defmodule Literal do
    @type t() :: %__MODULE__{
            value: term()
          }

    defstruct [:value]
  end

  defmodule Unary do
    @type t() :: %__MODULE__{
            operator: Token.t(),
            right: Expr.t()
          }

    defstruct [:operator, :right]
  end
end
