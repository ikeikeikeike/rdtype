# Rdtype

Calling Redis Data Types in easily way.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `rdtype` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rdtype, github: "ikeikeikeike/rdtype"}]
    end
    ```

  2. Ensure `rdtype` is started before your application:

    ```elixir
    def application do
      [applications: [:rdtype]]
    end
    ```

## Usage

```elixir
defmodule StringsT do
  use Rdtype,
    type: :string,
    uri: "redis://127.0.0.1:6379/12"
end

test "ping" do
  assert "PONG" == StringsT.ping
end

test "strings.get" do
  assert "OK"  == StringsT.clear

  assert nil   == StringsT.get "get"
  assert "OK"  == StringsT.set "get", "get"
  assert "get" == StringsT.get "get"
end

test "strings.get when is_list" do
  assert "OK" == StringsT.clear

  assert "OK" == StringsT.set "get1", "get1"
  assert "OK" == StringsT.set "get2", "get2"
  assert ["get1", "get2"] == StringsT.get ["get1", "get2"]
end

test "strings.mget" do
  assert "OK" == StringsT.clear

  assert "OK" == StringsT.set "mget1", "mget1"
  assert "OK" == StringsT.set "mget2", "mget2"
  assert ["mget1", "mget2"] == StringsT.mget ["mget1", "mget2"]
end

test "strings.set" do
  assert "OK" == StringsT.set "set", "set"
  assert "set" == StringsT.get "set"
end

test "strings.append" do
  assert "OK" == StringsT.clear

  assert 6 == StringsT.add "append", "append"
  assert 12 == StringsT.add "append", "append"
  assert "appendappend" == StringsT.get "append"
end

test "strings.incrby" do
  assert "OK" == StringsT.clear

  assert 10 == StringsT.incrby "incrby", 10
  assert 30 == StringsT.incrby "incrby", 20
end

test "strings.incrbyfloat" do
  assert "OK" == StringsT.clear

  assert 10.1 == StringsT.incrbyfloat "incrbyfloat", 10.1
  assert 30.3 == StringsT.incrbyfloat "incrbyfloat", 20.2
end

test "strings.incr" do
  assert "OK" == StringsT.clear

  assert 1 == StringsT.incr "incr"
  assert 2 == StringsT.incr "incr"
end

test "strings.decr" do
  assert "OK" == StringsT.clear

  assert 1  == StringsT.incr "incr"
  assert 2  == StringsT.incr "incr"
  assert 1  == StringsT.decr "incr"
  assert 0  == StringsT.decr "incr"
  assert -1 == StringsT.decr "incr"
end
```
