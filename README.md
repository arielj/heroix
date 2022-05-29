# Heroix

Heroic Games Launcher, but written in Elixir + Phoenix LiveView (+ elixir-desktop in the future)

## Requirements

Erlang OTP (I'm using Erlang/OTP 25)
Elixir (I'm using Elixir 1.13.4)

## Setup

Install dependencies with `mix deps.get`

## Start

- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Icons

Using https://www.icofont.com/icons, use the `FontIconComponent` component in heex, pass the icon name as the `icon` prop/attribute.

## Done

- List user's games (with installed status)
- Library view (filter, order)
- Game view (some info, install/uninstall, launch/stop actions)
- - State is reactive to running games and installing/uninstalling them
- Settings view (basic skeleton to handle global settings)
- Basic install queue (no view yet)
- Images cache

## TODO

- Install dialog
- Installation progress in game view
- Cancel installation
- Resume installation
- Install queue visualizer
- Visual hints for games in queue and installing in library
- Installation-related settings (install folder, more?)
- Game launch-related settings (wine, prefix)
- Login
- Refresh action
- Wine downloader
- More tests
- I18n
- A11y
- Themes
- Cloud saves
- elixir-desktop stuff (standalone app, tray icon)
- Customize launch command
- Pre/Post game scripts
- Game OS version picker (Mac/Windows)
- GOG integration

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
