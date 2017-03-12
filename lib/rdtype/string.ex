defmodule Rdtype.String do
  @doc false
  defmacro __using__(_opts) do
    quote do
      def get(""),  do: nil
      def get(nil), do: nil
      def get(key) when is_bitstring(key) do
        case Redix.command!(pid(), ~w(GET #{key})) do
          nil -> nil
          val -> dec(val)
        end
      end
      def get(keys) when is_list(keys), do: mget keys

      def mget(keys) when is_list(keys) do
        Redix.command!(pid(), ["MGET"] ++ keys)
        |> Enum.map(&dec(&1))
      end

      def set(key, val) do
        Redix.command!(pid(), ["SET", key, enc(val)])
      end

      defdelegate add(key, val), to: __MODULE__, as: :append
      def append(key, val) do
        Redix.command!(pid(), ["APPEND", key, enc(val)])
      end

      def incr(key) do
        Redix.command!(pid(), ~w(INCR #{key}))
      end

      def incrby(key, val) do
        Redix.command!(pid(), ~w(INCRBY #{key} #{val}))
      end

      def incrbyfloat(key, val) do
        case Redix.command!(pid(), ~w(INCRBYFLOAT #{key} #{val})) do
          nil -> nil
          val ->
            {f, _} = Float.parse(val)
             f
        end
      end

      def decr(key) do
        Redix.command!(pid(), ~w(DECR #{key}))
      end
    end
  end
end
