defmodule Rdtype.SortedSet do
  @doc false
  defmacro __using__(_opts) do
    quote do

      def zadd(key, num, val) do
        Redix.command!(pid(), ["ZADD", key, num, enc(val)])
      end

      def zincrby(key, num, val) do
        Redix.command!(pid(), ~w(ZINCRBY #{key} #{num} #{val}))
      end

      def zrange(key, f, t, :withscores) do
        zrange key, f, t, "WITHSCORES"
      end
      def zrange(key, f, t, withscores \\ "") do
        Redix.command!(pid(), ~w(ZRANGE #{key} #{f} #{t} #{withscores}))
        |> Enum.map(&dec(&1))
      end

      def zrevrangebyscore(key, f, t) do
        zrevrangebyscore key, f, t, []
      end
      def zrevrangebyscore(key, f, t, opts) do
        cmd = ~w(ZREVRANGEBYSCORE #{key} #{f} #{t})
        cmd = cmd ++ if opts[:withscores] do
          ~w(withscores)
        else
          []
        end
        cmd = cmd ++ if opts[:limit] do
          ~w(LIMIT)  ++ opts[:limit]
        else
          []
        end

        r =
          Redix.command!(pid(), cmd)
          |> Enum.map(&dec(&1))

        if opts[:withscores] do
          Enum.chunk r, 2, 2
        else
          r
        end
      end

      def zunionstore(key, cmd) when is_binary(cmd) do
        Redix.command!(pid(), String.split(cmd))
      end
      def zunionstore(key, keys) when is_list(keys) do
        zunionstore(key, keys, [])
      end
      def zunionstore(key, keys, opts) do
        cmd = ~w(ZUNIONSTORE #{key} #{length(keys)} #{Enum.join(keys, " ")})
        cmd = cmd  ++ if opts[:weights] do
          ["WEIGHTS"] ++ opts[:weights]
        else
          []
        end
        cmd = cmd  ++ if opts[:aggregate] do
          ~w(AGGREGATE #{opts[:aggregate]})
        else
          []
        end

        Redix.command!(pid(), cmd)
      end

      # def decr(key) do
        # Redix.command!(pid(), ~w(DECR #{key}))
      # end
    end
  end
end
