defmodule RdtypeTest do
  use ExUnit.Case
  doctest Rdtype

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

  test "keys" do
    assert "OK"  == StrJ.flushdb
    assert "OK"  == StrJ.set "key", "keys"
    assert "OK"  == StrJ.set "keys", "keys"
    assert "OK"  == StrJ.set "knockout", "keys"

    assert ["keys", "key", "knockout"]  == StrJ.keys "k*"
  end

  test "exists" do
    assert "OK"  == StrJ.flushdb
    assert "OK"  == StrJ.set "exist", "keys"
    assert "OK"  == StrJ.set "exists", "keys"

    assert 1 == StrJ.exists "exist"
    assert 2 == StrJ.exists ["exist", "exists"]
  end

  test "expire & ttl & pttl" do
    assert "OK"  == StrJ.flushdb
    assert "OK"  == StrJ.set "mykey", "Hello"

    assert 1  == StrJ.expire "mykey", 10
    assert 1  == StrJ.expire "mykey", 10
    assert 10 == StrJ.ttl "mykey"

    assert "OK" == StrJ.set "mykey", "Unk"
    assert -1 == StrJ.ttl "mykey"
    assert -1 == StrJ.pttl "mykey"

    assert 1  == StrJ.expire "mykey", 1
    assert 100 < StrJ.pttl "mykey"
  end

  test "type" do
    assert "OK"  == StrJ.flushdb
    assert "OK"  == StrJ.set "type", "keys"

    assert "string" == StrJ.type "type"
  end

  test "ping" do
    assert "PONG" == StrT.ping
  end

  # String

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

  # List

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

  test "list.llen & list.length" do
    assert "OK" == ListT.clear

    assert 0 == ListT.length "length"

    assert 1 == ListT.push "length", 2
    assert 2 == ListT.push "length", "pop"

    assert 2 == ListT.llen "length"
    assert 2 == ListT.length "length"
  end

  test "list.slice & list.lrange" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.push "lrange", 1
    assert 2 == ListJ.push "lrange", 2
    assert 3 == ListJ.push "lrange", 3
    assert 4 == ListJ.push "lrange", 4
    assert 5 == ListJ.push "lrange", 5
    assert 6 == ListJ.push "lrange", 6

    assert [1] == ListJ.lrange "lrange", 0, 0
    assert [1] == ListJ.slice "lrange", 0, 0
    assert [1, 2, 3, 4] == ListJ.slice "lrange", 0, 3
    assert [3, 4, 5, 6] == ListJ.slice "lrange", 2, 5
  end

  test "list.take" do
    assert "OK" == ListJ.clear

    assert 1 == ListJ.push "lrange", 1
    assert 2 == ListJ.push "lrange", 2
    assert 3 == ListJ.push "lrange", 3
    assert 4 == ListJ.push "lrange", 4
    assert 5 == ListJ.push "lrange", 5
    assert 6 == ListJ.push "lrange", 6

    assert [] == ListJ.take "lrange", 0
    assert [] == ListJ.take "lrange", -0
    assert [1] == ListJ.take "lrange", 1
    assert [6] == ListJ.take "lrange", -1
    assert [1, 2] == ListJ.take "lrange", 2
    assert [5, 6] == ListJ.take "lrange", -2
  end

  test "list.first" do

  end

  test "list.last" do

  end

end
