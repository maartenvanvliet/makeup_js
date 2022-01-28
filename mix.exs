defmodule MakeupJs.MixProject do
  use Mix.Project

  @version "0.1.0"

  @url "https://github.com/maartenvanvliet/makeup_js"
  def project do
    [
      app: :makeup_js,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Package
      package: package(),
      description: description(),
      aliases: aliases(),
      docs: docs()
    ]
  end

  defp aliases do
    [
      docs: &build_docs/1
    ]
  end

  defp description do
    """
    Js lexer for the Makeup syntax highlighter.
    """
  end

  defp package do
    [
      maintainers: ["Maarten van Vliet"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url},
      files: ~w(LICENSE README.md lib mix.exs .formatter.exs)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [],
      mod: {MakeupJs.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:makeup, "~> 1.0"}
    ]
  end

  def docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      main: "Makeup.Lexers.CLexer"
    ]
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["MakeupJs", @version, Mix.Project.compile_path()]
    opts = ~w[--main Makeup.Lexers.JsLexer --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
