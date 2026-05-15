# Repository Guidelines

## Project Structure & Module Organization

This is an Elixir Mix library for sending encrypted Web Push notifications.
Core source lives in `lib/`: `lib/web_push_elixir.ex` contains the public
notification API and crypto/header logic, `lib/web_push_elixir/application.ex`
starts supervision, and `lib/mix/tasks/generate_vapid_keys.ex` defines the VAPID
key generator task. Runtime and test configuration are in `config/`. Tests live
in `test/`, with shared local HTTP behavior in `test/support/mock_server.ex`.
The browser demo and GitHub Pages assets are in `example/`.

## Build, Test, and Development Commands

- `mix deps.get` installs Hex dependencies.
- `mix compile` compiles the library and checks for compile-time errors.
- `mix test` runs the ExUnit suite; tests start a local Plug/Cowboy server on
  port `4040`.
- `mix coveralls.json` runs test coverage in the same format used by CI.
- `mix format` formats all Elixir files according to Mix formatter defaults.
- `mix generate.vapid.keys` generates sample VAPID keys for local configuration.
- `mix precommit` checks formatting, compiles with warnings as errors, and runs
  the test suite. Run this before every commit.

## Coding Style & Naming Conventions

Use standard Elixir formatting: two-space indentation, pipeline-friendly
function chains, and `snake_case` for functions, variables, and test names.
Modules use `PascalCase` under the `WebPushElixir` namespace, with Mix tasks
under `Mix.Tasks.*`. Prefer pattern matching and tagged tuples such as
`{:ok, response}` and `{:error, reason}` for control flow. Keep comments sparse;
public behavior should be documented with `@doc` examples when helpful.

## Testing Guidelines

Tests use ExUnit and should be named `*_test.exs`. Add focused tests next to the
behavior being changed, and use `test/support/mock_server.ex` for push-service
HTTP responses instead of calling external services. When changing request
headers, encryption payload behavior, or error handling, assert both return
tuples and relevant response/request fields. Run `mix test` before submitting;
run `mix coveralls.json` for changes that affect coverage-sensitive logic.

## Commit & Pull Request Guidelines

Recent history uses short imperative messages, often with Conventional Commit
prefixes such as `build(deps): bump jason from 1.4.4 to 1.4.5`, `build: 0.8.0`,
and `ci: revert test`. Run `mix precommit` before every commit, then keep
commits scoped and descriptive. Pull requests should include a concise summary,
test results, linked issues when applicable, and note any configuration or
example asset changes. Screenshots are only useful for changes under `example/`.

## Security & Configuration Tips

Never commit real VAPID private keys. Use placeholders in docs and configure
`vapid_public_key`, `vapid_private_key`, and `vapid_subject` through environment
specific config or application runtime configuration.
