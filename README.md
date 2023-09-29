
# Web Push Elixir

Simple web push library for Elixir

<a href="https://github.com/midarrlabs/web-push-elixir/actions/workflows/test.yml">
    <img src="https://github.com/midarrlabs/web-push-elixir/actions/workflows/test.yml/badge.svg" alt="Test Status">
</a>
<a href="https://codecov.io/gh/midarrlabs/web-push-elixir">
    <img src="https://codecov.io/gh/midarrlabs/web-push-elixir/branch/main/graph/badge.svg?token=8PJVJG09RK&style=flat-square" alt="Code Coverage">
</a>
<a href="https://hex.pm/packages/web_push_elixir">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/web_push_elixir.svg">
</a>
<a href="https://hexdocs.pm/web_push_elixir">
    <img alt="Hex Docs" src="http://img.shields.io/badge/api-docs-blue.svg?style=flat">
</a>


## Prerequisities

* Elixir 1.15, OTP 24 / 25 / 26

## Installation

1. Add `web_push_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:web_push_elixir, "~> 0.2.0"}
  ]
end
```

2. Run mix command to generate your Vapid public and private keys:

```commandline
mix generate.vapid.keys
```

3. Set environment variables for your generated keys:

```yaml
environment:
  - VAPID_PUBLIC_KEY=someVapidPublicKey
  - VAPID_PRIVATE_KEY=someVapidPrivateKey
  - VAPID_SUBJECT=mailto:admin@email.com
```

## Usage

`WebPushElixir` provides a simple `send_notification/2` function that accepts 2 arguments:

* `subscription`: the subscription information received from the client ([example](https://midarrlabs.github.io/web-push-elixir/))
* `message`: the message string.

```elixir
subscription = '{"endpoint":"https://some-push-service","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}'
message = "Some message"

WebPushElixir.send_notification(subscription, message)
```

For more information on how to subscribe a client, permission UX and more - take a look at [https://web.dev/notifications/](https://web.dev/notifications/)

## Run tests

```commandline
mix test
```

## License

Web Push Elixir is open-sourced software licensed under the [MIT license](LICENSE).


## Credits

Heavily inspired by [elixir-web-push-encryption](https://github.com/danhper/elixir-web-push-encryption)
