defmodule Rdtype do
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
          cde -> cde.parse!(val)
        end
      end

      defp dec(val) do
        opts = @__using_resource__
        case opts[:coder] do
          nil -> val
          cde -> cde.parse!(val)
        end
      end

      def ping do
        Redix.command!(pid, ~w(PING))
      end

      def flushdb do
        Redix.command!(pid, ~w(FLUSHDB))
      end
      defdelegate clear, to: __MODULE__, as: :flushdb

      # def clearall do
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

          def append(key, val) do
            Redix.command!(pid, ~w(APPEND #{key} #{enc(val)}))
          end
          defdelegate add(key, val), to: __MODULE__, as: :append

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
          def lpop(key) do
            case Redix.command!(pid, ~w(LPOP #{key})) do
              nil -> nil
              val -> dec(val)
            end
          end
          defdelegate shift(key), to: __MODULE__, as: :lpop

          def all(key) do
            Redix.command!(pid, ~w(LRANGE #{key} 0 -1))
            |> Enum.map(&dec(&1))
          end

        _ -> nil
      end
    end
  end
end
