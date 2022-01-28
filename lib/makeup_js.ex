defmodule Makeup.Lexers.JsLexer do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  import Makeup.Lexer.Combinators
  import Makeup.Lexer.Groups
  import Makeup.Lexers.JsLexer.Helper
  import NimbleParsec

  @behaviour Makeup.Lexer

  ###################################################################
  # Step #1: tokenize the input (into a list of tokens)
  ###################################################################

  any_char = utf8_char([]) |> token(:error)

  # unicode_bom = ignore(utf8_char([@unicode_bom]))

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> token(:whitespace)

  # Numbers
  digits = ascii_string([?0..?9], min: 1)
  bin_digits = ascii_string([?0..?1], min: 1)
  hex_digits = ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)
  oct_digits = ascii_string([?0..?7], min: 1)

  # Digits in an integer may be separated by underscores
  number_bin_part = with_optional_separator(bin_digits, "_")
  number_oct_part = with_optional_separator(oct_digits, "_")
  number_hex_part = with_optional_separator(hex_digits, "_")
  integer = with_optional_separator(digits, "_")

  # Tokens for the lexer
  number_bin = string("0b") |> concat(number_bin_part) |> token(:number_bin)
  number_oct = string("0o") |> concat(number_oct_part) |> token(:number_oct)
  number_hex = string("0x") |> concat(number_hex_part) |> token(:number_hex)
  # Base 10
  number_integer = token(integer, :number_integer)

  # Floating point numbers
  float_scientific_notation_part =
    ascii_string([?e, ?E], 1)
    |> optional(string("-"))
    |> concat(integer)

  number_float =
    integer
    |> string(".")
    |> concat(integer)
    |> optional(float_scientific_notation_part)
    |> token(:number_float)

  variable =
    ascii_char([?_, ?A..?Z, ?a..?z])
    |> repeat(ascii_char([?_, ?0..?9, ?A..?Z, ?a..?z]))
    |> token(:name)

  operator_name = word_from_list(~W(
      -> + -  * / % ++ -- ~ ^ & && | ||
      =  += -= *= /= &= |= %= ^= << >>
      <<= >>= > < >= <= == != ! ? :
    ))

  operator = token(operator_name, :operator)

  normal_char =
    string("?")
    |> utf8_string([], 1)
    |> token(:string_char)

  escape_char =
    string("?\\")
    |> utf8_string([], 1)
    |> token(:string_char)

  punctuation =
    word_from_list(
      ["\\\\", ":", ";", ",", "."],
      :punctuation
    )

  delimiters_punctuation =
    word_from_list(
      ~W( ( \) [ ] { }),
      :punctuation
    )

  comment = many_surrounded_by(parsec(:root_element), "/*", "*/")

  delimiter_pairs = [
    delimiters_punctuation,
    comment
  ]

  unicode_char_in_string =
    string("\\u")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> token(:string_escape)

  escaped_char =
    string("\\")
    |> utf8_string([], 1)
    |> token(:string_escape)

  interpolation = many_surrounded_by(parsec(:root_element), "${", "}", :string_interpol)

  combinators_inside_string = [
    unicode_char_in_string,
    escaped_char
  ]

  interpolated_combinators_inside_string = [interpolation] ++ combinators_inside_string

  string_keyword =
    choice([
      string_like("\"", "\"", combinators_inside_string, :string_symbol),
      string_like("'", "'", combinators_inside_string, :string_symbol)
    ])
    |> concat(token(string(":"), :punctuation))

  keyword =
    string_keyword
    |> concat(whitespace)

  back_quoted_string = string_like("\`", "\`", interpolated_combinators_inside_string, :string)
  double_quoted_string = string_like("\"", "\"", combinators_inside_string, :string)
  single_quoted_string = string_like("'", "'", combinators_inside_string, :string)
  line = repeat(lookahead_not(ascii_char([?\n])) |> utf8_string([], 1))

  inline_comment =
    string("//")
    |> concat(line)
    |> token(:comment_single)

  multiline_comment = string_like("/*", "*/", combinators_inside_string, :comment_multiline)

  root_element_combinator =
    choice(
      [
        whitespace,
        # Comments
        multiline_comment,
        inline_comment,
        keyword,
        # Strings
        back_quoted_string,
        single_quoted_string,
        double_quoted_string
      ] ++
        [
          # Chars
          escape_char,
          normal_char
        ] ++
        delimiter_pairs ++
        [
          # Operators
          operator,
          # Numbers
          number_bin,
          number_oct,
          number_hex,
          # Floats must come before integers
          number_float,
          number_integer,
          # Names
          variable,
          punctuation,
          # If we can't parse any of the above, we highlight the next character as an error
          # and proceed from there.
          # A lexer should always consume any string given as input.
          any_char
        ]
    )

  # By default, don't inline the lexers.
  # Inlining them increases performance by ~20%
  # at the cost of doubling the compilation times...
  @inline false

  @doc false
  def __as_js_language__({ttype, meta, value}) do
    {ttype, Map.put(meta, :language, :js), value}
  end

  # Semi-public API: these two functions can be used by someone who wants to
  # embed an Elixir lexer into another lexer, but other than that, they are not
  # meant to be used by end-users.

  # @impl Makeup.Lexer
  defparsec(
    :root_element,
    root_element_combinator |> map({__MODULE__, :__as_js_language__, []}),
    inline: @inline
  )

  # @impl Makeup.Lexer
  defparsec(
    :root,
    repeat(parsec(:root_element)),
    inline: @inline
  )

  ###################################################################
  # Step #2: postprocess the list of tokens
  ###################################################################

  @operator_word ~w(
    typeof
    instanceof
    in
    void
    delete
    new
  ) |> Enum.map(&String.to_charlist/1)

  @keyword_declarations ~w(
    var
    let
    const
    with
    function
    class
  ) |> Enum.map(&String.to_charlist/1)

  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#reserved_keywords_as_of_ecmascript_2015
  @reserved_words_2015 ~w(
    break
    case
    catch
    continue
    debugger
    default
    do
    else
    export
    extends
    finally
    for
    if
    import
    return
    super
    switch
    this
    throw
    try
    while
    yield
    from
  ) |> Enum.map(&String.to_charlist/1)

  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#future_reserved_keywords
  @future_reserved_keywords ~w(
    enum
    implements
    interface
    package
    private
    protected
    public
    static
    yield
    await
    ) |> Enum.map(&String.to_charlist/1)

  @keyword_reserved @reserved_words_2015 ++ @future_reserved_keywords

  @builtin_words ~w(
    Array
    Boolean
    Date
    BigInt
    Function
    Math
    ArrayBuffer
    Number
    Object
    RegExp
    String
    Promise
    Proxy
    decodeURI
    decodeURIComponent
    encodeURI
    encodeURIComponent
    eval
    isFinite
    isNaN
    parseFloat
    parseInt
    DataView
    document
    window
    globalThis
    global
    Symbol
    Intl
    WeakSet
    WeakMap
    Set
    Map
    Reflect
    JSON
    Atomics
    Int8Array
    Int16Array
    Int32Array
    BigInt64Array
    Float32Array
    Float64Array
    Uint8ClampedArray
    Uint8Array
    Uint16Array
    Uint32Array
    BigUint64Array
    ) |> Enum.map(&String.to_charlist/1)

  @keyword_constant ~W(
    null true false undefined NaN Infinity
  ) |> Enum.map(&String.to_charlist/1)

  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []), do: postprocess_helper(tokens)

  defp postprocess_helper([]), do: []

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @operator_word,
    do: [{:operator_word, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword_declarations,
    do: [{:keyword_declaration, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword_constant,
    do: [{:keyword_constant, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, text} | tokens]) when text in @keyword_reserved,
    do: [{:keyword_reserved, attrs, text} | postprocess_helper(tokens)]

  defp postprocess_helper([{:name, attrs, builtin} | tokens]) when builtin in @builtin_words do
    [
      {:name_builtin, attrs, builtin}
      | postprocess_helper(tokens)
    ]
  end

  # match function names. They are followed by parens...
  defp postprocess_helper([{:name, attrs, text}, {:punctuation, %{language: :js}, "("} | tokens]) do
    [
      {:name_function, attrs, text},
      {:punctuation, %{language: :js}, "("} | postprocess_helper(tokens)
    ]
  end

  # Otherwise, don't do anything with the current token and go to the next token.
  defp postprocess_helper([token | tokens]), do: [token | postprocess_helper(tokens)]

  ###################################################################
  # Step #3: highlight matching delimiters
  ###################################################################

  @impl Makeup.Lexer
  defgroupmatcher(:match_groups,
    parentheses: [
      open: [[{:punctuation, %{language: :js}, "("}]],
      close: [[{:punctuation, %{language: :js}, ")"}]]
    ],
    list: [
      open: [
        [{:punctuation, %{language: :js}, "["}]
      ],
      close: [
        [{:punctuation, %{language: :js}, "]"}]
      ]
    ],
    curly: [
      open: [
        [{:punctuation, %{language: :js}, "{"}]
      ],
      close: [
        [{:punctuation, %{language: :js}, "}"}]
      ]
    ]
  )

  @impl Makeup.Lexer
  def lex(text, opts \\ []) do
    group_prefix = Keyword.get(opts, :group_prefix, random_prefix(10))
    {:ok, tokens, "", _, _, _} = root(text)

    tokens
    |> postprocess([])
    |> match_groups(group_prefix)
  end
end
