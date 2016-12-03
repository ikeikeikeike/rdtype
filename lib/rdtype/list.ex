defmodule Rdtype.List do
  @doc false
  defmacro __using__(_opts) do
    quote do
      defdelegate shift(key), to: __MODULE__, as: :lpop
      def lpop(key) do
        case Redix.command!(pid, ~w(LPOP #{key})) do
          nil -> nil
          val -> dec(val)
        end
      end

      defdelegate pop(key), to: __MODULE__, as: :rpop
      def rpop(key) do
        case Redix.command!(pid, ~w(RPOP #{key})) do
          nil -> nil
          val -> dec(val)
        end
      end

      defdelegate unshift(key, val), to: __MODULE__, as: :lpush
      def lpush(key, val) do
        Redix.command!(pid, ~w(LPUSH #{key} #{enc(val)}))
      end

      defdelegate push(key, val), to: __MODULE__, as: :rpush
      def rpush(key, val) do
        Redix.command!(pid, ~w(RPUSH #{key} #{enc(val)}))
      end

      defdelegate clear, to: __MODULE__, as: :flushdb

      defdelegate length(key), to: __MODULE__, as: :llen
      def llen(key) do
        Redix.command!(pid, ~w(LLEN #{key}))
      end

      def take(key, 0), do: []
      def take(key, t) when t > 0, do: lrange(key, 0, t - 1)
      def take(key, t) when t < 0, do: lrange(key, t, -1)

      defdelegate slice(key, f, t), to: __MODULE__, as: :lrange
      def lrange(key, f, t) do
        Redix.command!(pid, ~w(LRANGE #{key} #{f} #{t}))
        |> Enum.map(&dec(&1))
      end

      def all(key) do
        Redix.command!(pid, ~w(LRANGE #{key} 0 -1))
        |> Enum.map(&dec(&1))
      end
    end
  end
end
