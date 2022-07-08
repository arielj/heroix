# Heroix

Heroic Games Launcher, but written in Elixir + Phoenix LiveView (+ elixir-desktop in the future)

# THIS IS NOT INTENDED TO BE A REPLACEMENT FOR HEROIC GAMES LAUNCHER, THIS IS AN ELIXIR PRACTICE PROJECT USING HEROIC AS INSPIRATION

# THIS IS IN REALLY EARLY ALPHA STAGE, USE IT AT YOUR OWN RISK, IT'S BUGY, MISSING A LOT OF FEATURES, UGLY, BADLY DOCUMENTED

## Why?

I want to learn more about Elixir and Phoenix LiveView and I don't like to practice with generic application ideas with fake requirements, I want to re-create a complex application to force myself into takling the issues I find and not skip them.

I also want to learn more about Legendary and how to integrate with it, and find ideas to apply to Heroic Games Launcher.

Keep in mind this is just a practice project for me, I'm sharing this in case it helps other people.

Maybe in the future it is a valid alternative as a game launcher, but that's not my objective and I don't plan to implement all the features listed above as a goal, those are just for me for reference but not a roadmap of any kind for this project.

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
- Images cache
- Install / stop install
- Installation progress in game screen and downloads screen
- Uninstall
- Enqueue games to download
- Save game config in Legendary's config.ini (config.ini gets updated, only for specific game config)
- Install dialog (with customizable base path)
- Login (using SID)
- Resume installation (show correct progress calculating previously downloaded files)

## WIP

- Install queue visualizer (needs more details on each game in the list, does not show available updates, would be nice to keep a log of finished/stopped installations)
- Cancel installation (can be stopped, but needs more details)
- UI to change legendary's config (legendary and defaults)
- UI to change game's legendary config

## TODO

- Selective downloads
- Anticheat status
- Show error when trying to install a DLC without the main game
- Handle ENV variables to game's config
- Handle default game's config and default game's ENV variables
- Import
- Update (dialog with details)
- Delete partial installation
- Visual hints for games in queue and installing in library
- Refresh action
- Wine downloader
- More tests
- I18n
- A11y
- Themes
- Cloud saves
- hide games
- game categories
- about screen (version of tools, etc)
- elixir-desktop stuff (standalone app, tray icon)
- gamepad navigation
- Download/update legendary
- Pre/Post game scripts (pre script is a legendary feature!)
- Game OS version picker (Mac/Windows)
- Game versions configuration (install older version?)
- GOG integration
- Add custom games (title, image, executable?)

## Links

Heroic Games Launcher: https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher
Legendary: https://github.com/derrod/legendary#usage

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
