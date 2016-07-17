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

  defmodule Json do
    @behaviour Rdtype.Coder

    def enc(message), do: Poison.encode! message
    def dec(message), do: Poison.decode! message
  end

  defmodule StrT do
    use Rdtype,
      type: :string,
      uri: "redis://127.0.0.1:6379/12"
  end

  defmodule StrJ do
    use Rdtype,
      type: :string,
      coder: Json,
      uri: "redis://127.0.0.1:6379/12"
  end

  test "ping" do
    assert "PONG" == StrT.ping
  end

  test "string.get" do
    assert "OK"  == StrT.flushdb

    assert nil   == StrT.get "get"
    assert "OK"  == StrT.set "get", "get"
    assert "get" == StrT.get "get"
  end

  test "string.get when is_list" do
    assert "OK" == StrT.flushdb

    assert "OK" == StrT.set "get1", "get1"
    assert "OK" == StrT.set "get2", "get2"
    assert ["get1", "get2"] == StrT.get ["get1", "get2"]
  end

  test "string.mget" do
    assert "OK" == StrT.flushdb

    assert "OK" == StrT.set "mget1", 1
    assert "OK" == StrT.set "mget2", "mget2"
    assert ["1", "mget2"] == StrT.mget ["mget1", "mget2"]
  end

  test "string.set" do
    assert "OK" == StrT.set "set", "set"
    assert "set" == StrT.get "set"
  end

  test "string.set with coder" do
    assert "OK" == StrJ.set "set", %{"set" => "set"}
    assert %{"set" => "set"} == StrJ.get "set"
  end

  test "string.append with coder" do
    assert "OK" == StrJ.flushdb

    assert 6 == StrJ.add "append", "append"
    assert 12 == StrJ.add "append", "append"
    assert "appendappend" == StrJ.get "append"
  end

  test "string.append" do
    assert "OK" == StrT.flushdb

    assert 6 == StrT.add "append", "append"
    assert 12 == StrT.add "append", "append"
    assert "appendappend" == StrT.get "append"
  end

  test "string.incrby" do
    assert "OK" == StrT.flushdb

    assert 10 == StrT.incrby "incrby", 10
    assert 30 == StrT.incrby "incrby", 20
  end

  test "string.incrbyfloat" do
    assert "OK" == StrT.flushdb

    assert 10.1 == StrT.incrbyfloat "incrbyfloat", 10.1
    assert 30.3 == StrT.incrbyfloat "incrbyfloat", 20.2
  end

  test "string.incr" do
    assert "OK" == StrT.flushdb

    assert 1 == StrT.incr "incr"
    assert 2 == StrT.incr "incr"
  end

  test "string.decr" do
    assert "OK" == StrT.flushdb

    assert 1  == StrT.incr "incr"
    assert 2  == StrT.incr "incr"
    assert 1  == StrT.decr "incr"
    assert 0  == StrT.decr "incr"
    assert -1 == StrT.decr "incr"
  end

  defmodule ListT do
    use Rdtype,
      type: :list,
      uri: "redis://127.0.0.1:6379/13"
  end

  defmodule ListJ do
    use Rdtype,
      type: :list,
      coder: Json,
      uri: "redis://127.0.0.1:6379/13"
  end

  test "list.unshift" do
    assert "OK" == ListT.clear

    assert 1 == ListT.unshift "unshift", 1
    assert 2 == ListT.unshift "unshift", "unshift"
    assert ["unshift", "1"] == ListT.all "unshift"
  end

  test "list.push" do
    assert "OK" == ListT.clear

    assert 1 == ListT.push "push", 1
    assert 2 == ListT.push "push", "push"
    assert ["1", "push"] == ListT.all "push"
  end

  test "list.unshift with coder" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.unshift "unshift", 1
    assert 2 == ListJ.unshift "unshift", "jump"
    assert 3 == ListJ.unshift "unshift", %{"hop" => "step"}
    assert [%{"hop" => "step"}, "jump", 1] == ListJ.all "unshift"
  end

  test "list.push with coder" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.push "push", 1
    assert 2 == ListJ.push "push", "hop"
    assert 3 == ListJ.push "push", %{"step" => "jump"}
    assert [1, "hop", %{"step" => "jump"}] == ListJ.all "push"
  end

  test "list.shift" do
    assert "OK" == ListT.clear

    assert 1 == ListT.unshift "shift", 2
    assert 2 == ListT.unshift "shift", "shift"

    assert "shift" == ListT.shift "shift"
    assert "2" == ListT.shift "shift"
  end

  test "list.pop" do
    assert "OK" == ListT.clear

    assert 1 == ListT.push "pop", 2
    assert 2 == ListT.push "pop", "pop"

    assert "pop" == ListT.pop "pop"
    assert "2" == ListT.pop "pop"
  end

  test "list.shift with coder" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.unshift "shift", 2
    assert 2 == ListJ.unshift "shift", "shift"
    assert 3 == ListJ.unshift "shift", [1, %{"shift" => "shift", "coder" => 1}]

    assert [1, %{"shift" => "shift", "coder" => 1}] == ListJ.shift "shift"
    assert "shift" == ListJ.shift "shift"
    assert 2 == ListJ.shift "shift"
  end

  test "list.pop with coder" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.push "pop", 2
    assert 2 == ListJ.push "pop", "pop"
    assert 3 == ListJ.push "pop", [2, %{"shift" => "shift", "pop" => 1}]

    assert [2, %{"shift" => "shift", "pop" => 1}] == ListJ.pop "pop"
    assert "pop" == ListJ.pop "pop"
    assert 2 == ListJ.pop "pop"
  end

```
