# Web Push Elixir

![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/midarrlabs/web-push-elixir/test.yml)
[![codecov](https://codecov.io/gh/midarrlabs/web-push-elixir/graph/badge.svg?token=Y9FG6IFTIN)](https://codecov.io/gh/midarrlabs/web-push-elixir)

Simple web push for Elixir

## Installation

1. The package can be installed by adding `web_push_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:web_push_elixir, "~> 0.1.0"}
  ]
end
```

2. Run the mix command to generate your Vapid public and private keys:

```commandline
mix generate.vapid.keys
```

3. Set your environment variables for your keys:

```yaml
environment:
  - VAPID_PUBLIC_KEY=someVapidPublicKey
  - VAPID_PRIVATE_KEY=someVapidPrivateKey
  - VAPID_SUBJECT=mailto:admin@email.com
```

## Credits

Heavily inspired by [@danhper](https://github.com/danhper) as his work on [elixir-web-push-encryption](https://github.com/danhper/elixir-web-push-encryption) :pray: Thank you