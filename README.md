# Web Push Elixir

Simple web push library for Elixir.

![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/midarrlabs/web-push-elixir/test.yml)
[![codecov](https://codecov.io/gh/midarrlabs/web-push-elixir/graph/badge.svg?token=Y9FG6IFTIN)](https://codecov.io/gh/midarrlabs/web-push-elixir)

## Installation

1. Add `web_push_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:web_push_elixir, "~> 0.1.0"}
  ]
end
```

2. Run mix command to generate your Vapid public and private keys:

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

## Usage

`WebPushElixir` provides a simple public API `send_notification/2` that accepts 2 arguments:

* `subscription`: is the subscription information received from the client.
* `message`: is a message string.

```elixir
subscription = '{"endpoint":"https://some-push-service","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}'
message = "Some message"

WebPushElixir.send_notification(subscription, message)
```

For more information on how to subscribe a client, permission UX and more - have a look at [https://web.dev/notifications/](https://web.dev/notifications/)


## Credits

Heavily inspired by [elixir-web-push-encryption](https://github.com/danhper/elixir-web-push-encryption)
