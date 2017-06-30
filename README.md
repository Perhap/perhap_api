# PerhapAPI

Perhap is an event store written in elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `perhap_api` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:perhap_api, "~> 0.0.1"}]
    end
    ```

  2. Ensure `perhap_api` is started before your application:

    ```elixir
    def application do
      [applications: [:perhap_api]]
    end
    ```

