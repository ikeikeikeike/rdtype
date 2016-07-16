defmodule StringsT do
  use Exantenna.Redis,
    uri: "redis://127.0.0.1:6379/9"
    type: :string
end
