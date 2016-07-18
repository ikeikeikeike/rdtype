defmodule Rdtype do

  defmodule Coder do
    use Behaviour
    @callback enc(message::any) :: message::String.t | {:error, term}
    @callback dec(message::String.t) :: message::any | {:error, term}
  end

  @doc false
  defmacro __using__(opts) do
    quote do

      @__using_resource__ unquote(opts)

      def pid do
        opts = @__using_resource__
        case Redix.start_link(opts[:uri], name: __MODULE__) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      end

      defp enc(val) do
        opts = @__using_resource__
        case opts[:coder] do
          nil -> val
          cde when not is_bitstring(val) ->
            cde.enc(val)
          _   -> val
        end
      end

      defp dec(val) do
        opts = @__using_resource__
        case opts[:coder] do
          nil -> val
          cde ->
            case Poison.decode(val) do
              {:ok, val}  -> val
              {:error, _} -> val
            end
        end
      end

      def keys(key) do
        Redix.command!(pid, ~w(KEYS #{key}))
      end

      def exists(key) when is_bitstring(key) do
        Redix.command!(pid, ~w(EXISTS #{key}))
      end
      def exists(keys) do
        Redix.command!(pid, ["EXISTS"] ++ keys)
      end

      def expire(key, val) do
        Redix.command!(pid, ~w(EXPIRE #{key} #{val}))
      end

      def ttl(key) do
        Redix.command!(pid, ~w(TTL #{key}))
      end

      def pttl(key) do
        Redix.command!(pid, ~w(PTTL #{key}))
      end

      def type(key) do
        Redix.command!(pid, ~w(TYPE #{key}))
      end

      def ping do
        Redix.command!(pid, ~w(PING))
      end

      def flushdb do
        Redix.command!(pid, ~w(FLUSHDB))
      end

      # def flushall do
      #   Redix.command!(pid, ~w(FLUSHALL))
      # end

      case @__using_resource__[:type] do
        :string ->
          def get(""),  do: nil
          def get(nil), do: nil
          def get(key) when is_bitstring(key) do
            case Redix.command!(pid, ~w(GET #{key})) do
              nil -> nil
              val -> dec(val)
            end
          end
          def get(keys) when is_list(keys), do: mget keys

          def mget(keys) when is_list(keys) do
            Redix.command!(pid, ["MGET"] ++ keys)
            |> Enum.map(&dec(&1))
          end

          def set(key, val) do
            Redix.command!(pid, ~w(SET #{key} #{enc(val)}))
          end

          defdelegate add(key, val), to: __MODULE__, as: :append
          def append(key, val) do
            Redix.command!(pid, ~w(APPEND #{key} #{enc(val)}))
          end

          def incr(key) do
            Redix.command!(pid, ~w(INCR #{key}))
          end

          def incrby(key, val) do
            Redix.command!(pid, ~w(INCRBY #{key} #{val}))
          end

          def incrbyfloat(key, val) do
            case Redix.command!(pid, ~w(INCRBYFLOAT #{key} #{val})) do
              nil -> nil
              val ->
                {f, _} = Float.parse(val)
                 f
            end
          end

          def decr(key) do
            Redix.command!(pid, ~w(DECR #{key}))
          end

        :list ->
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

        _ -> nil
      end
    end
  end
end
