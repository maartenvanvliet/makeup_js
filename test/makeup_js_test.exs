defmodule MakeupJsTest do
  use ExUnit.Case

  test "whitespace" do
    assert MakeupJs.lex("   ") == [{:whitespace, %{language: :js}, "   "}]
  end

  test "single line comment" do
    assert MakeupJs.lex("// comment") == [
             {:comment_single, %{language: :js}, ["//", " ", "c", "o", "m", "m", "e", "n", "t"]}
           ]
  end

  test "multi line comment" do
    assert MakeupJs.lex("""
           /*
           comment
           /*
           """) == [
             {:operator, %{language: :js}, "/"},
             {:operator, %{language: :js}, "*"},
             {:whitespace, %{language: :js}, "\n"},
             {:name, %{language: :js}, 'comment'},
             {:whitespace, %{language: :js}, "\n"},
             {:operator, %{language: :js}, "/"},
             {:operator, %{language: :js}, "*"},
             {:whitespace, %{language: :js}, "\n"}
           ]
  end

  test "integers" do
    assert MakeupJs.lex("10") == [{:number_integer, %{language: :js}, "10"}]
    assert MakeupJs.lex("1_000") == [{:number_integer, %{language: :js}, ["1", "_", "000"]}]
    assert MakeupJs.lex("0888") == [{:number_integer, %{language: :js}, "0888"}]
    assert MakeupJs.lex("0777") == [{:number_integer, %{language: :js}, "0777"}]
  end

  test "floats" do
    assert MakeupJs.lex("1.440") == [{:number_float, %{language: :js}, ["1", ".", "440"]}]

    assert MakeupJs.lex("1_050.95") == [
             {:number_float, %{language: :js}, ["1", "_", "050", ".", "95"]}
           ]
  end

  test "keywords" do
    assert MakeupJs.lex("new Array") == [
             {:operator_word, %{language: :js}, [110, 101, 119]},
             {:whitespace, %{language: :js}, " "},
             {:name_builtin, %{language: :js}, 'Array'}
           ]

    assert MakeupJs.lex("const a = 0") == [
             {:keyword_declaration, %{language: :js}, 'const'},
             {:whitespace, %{language: :js}, " "},
             {:name, %{language: :js}, 97},
             {:whitespace, %{language: :js}, " "},
             {:operator, %{language: :js}, "="},
             {:whitespace, %{language: :js}, " "},
             {:number_integer, %{language: :js}, "0"}
           ]
  end
end
