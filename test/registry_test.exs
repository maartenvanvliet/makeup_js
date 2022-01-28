defmodule Makeup.Lexers.JsLexer.RegistryTest do
  use ExUnit.Case, async: true

  alias Makeup.Registry
  alias Makeup.Lexers.JsLexer

  describe "the Js lexer has successfully registered itself:" do
    test "language name" do
      assert {:ok, {JsLexer, []}} == Registry.fetch_lexer_by_name("js")
      assert {:ok, {JsLexer, []}} == Registry.fetch_lexer_by_name("javascript")
    end

    test "file extension" do
      assert {:ok, {JsLexer, []}} == Registry.fetch_lexer_by_extension("js")
    end
  end
end
