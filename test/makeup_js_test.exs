defmodule MakeupJsTest do
  use ExUnit.Case

  import Makeup.Lexers.JsLexer.Testing, only: [lex: 1]

  test "whitespace" do
    assert lex("   ") == [{:whitespace, %{}, "   "}]
  end

  test "single line comment" do
    assert lex("// comment") == [
             {:comment_single, %{}, "// comment"}
           ]
  end

  test "multi line comment" do
    assert lex("""
           /*
           comment
           /*
           """) == [
             {:operator, %{}, "/"},
             {:operator, %{}, "*"},
             {:whitespace, %{}, "\n"},
             {:name, %{}, "comment"},
             {:whitespace, %{}, "\n"},
             {:operator, %{}, "/"},
             {:operator, %{}, "*"},
             {:whitespace, %{}, "\n"}
           ]
  end

  test "integers" do
    assert lex("10") == [{:number_integer, %{}, "10"}]
    assert lex("1_000") == [{:number_integer, %{}, "1_000"}]
    assert lex("0888") == [{:number_integer, %{}, "0888"}]
    assert lex("0777") == [{:number_integer, %{}, "0777"}]
  end

  test "floats" do
    assert lex("1.440") == [{:number_float, %{}, "1.440"}]

    assert lex("1_050.95") == [
             {:number_float, %{},  "1_050.95"}
           ]
  end

  test "keywords" do
    assert lex("new Array") == [
             {:operator_word, %{}, "new"},
             {:whitespace, %{}, " "},
             {:name_builtin, %{}, "Array"}
           ]

    assert lex("const a = 0") == [
             {:keyword_declaration, %{}, "const"},
             {:whitespace, %{}, " "},
             {:name, %{}, "a"},
             {:whitespace, %{}, " "},
             {:operator, %{}, "="},
             {:whitespace, %{}, " "},
             {:number_integer, %{}, "0"}
           ]
  end
end
