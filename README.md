# MakeupJs

## [![Hex pm](http://img.shields.io/hexpm/v/makeup_js.svg?style=flat)](https://hex.pm/packages/makeup_js) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/makeup_js) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)![.github/workflows/elixir.yml](https://github.com/maartenvanvliet/makeup_js/workflows/.github/workflows/elixir.yml/badge.svg)

<!-- MDOC !-->

A `Makeup` lexer for Javascript.

It's incomplete as of yet and could be expanded to Typescript and jsx/tsx.

## Installation

The package can be installed
by adding `makeup_js` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:makeup_js, "~> 0.1.0"}
  ]
end
```
The lexer will be automatically registered in Makeup for the languages "javascript" as well as the extensions ".js" and ".javascript".
