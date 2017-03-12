defmodule Rdtype.Set do
  @doc false
  defmacro __using__(_opts) do
    quote do
      defdelegate add(key, val), to: __MODULE__, as: :sadd
      def sadd(key, val) do
        Redix.command!(pid(), ["SADD", key, enc(val)])
      end

      defdelegate length(key), to: __MODULE__, as: :scard
      def scard(key) do
        Redix.command!(pid(), ["SCARD", key])
      end

      defdelegate pop(key), to: __MODULE__, as: :spop
      def spop(key) do
        case Redix.command!(pid(), ["SPOP", key]) do
          nil -> nil
          val -> dec(val)
        end
      end

      defdelegate member(key, val), to: __MODULE__, as: :sismember
      def sismember(key, val) do
        case Redix.command!(pid(), ["SISMEMBER", key, enc(val)]) do
          1 -> true
          0 -> false
        end
      end

      defdelegate all(key), to: __MODULE__, as: :smembers
      def smembers(key) do
        Redix.command!(pid(), ["SMEMBERS", key])
        |> Enum.map(&dec(&1))
      end
    end
  end
end
