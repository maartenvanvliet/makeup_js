defmodule MakeupJs.Application do
  @moduledoc false
  use Application

  alias Makeup.Registry

  def start(_type, _args) do
    Registry.register_lexer(Makeup.Lexers.JsLexer,
      options: [],
      names: ["js", "javascript"],
      extensions: ["js"]
    )

    Supervisor.start_link([], strategy: :one_for_one)
  end
end
