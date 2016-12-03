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
          use Rdtype.String
        :list ->
          use Rdtype.List
        :sorted_set ->
          use Rdtype.SortedSet

        _ -> nil
      end
    end
  end
end
