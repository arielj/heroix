import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :heroix, HeroixWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "ktj0dI/xRCuG3HYg0g/tKhcf3DlRGA0WiqSFI9KxQiVZ81ovXqN6NJaILvPEDrZO",
  reloadable_compilers: [:gettext, :phoenix, :elixir, :phoenix_sass],
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :heroix, HeroixWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/sass/.*(sass|scss)$",
      ~r"priv/static/.*(js|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/heroix_web/(live|views)/.*(ex)$",
      ~r"lib/heroix_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :heroix, legendary_config_path: Path.join([System.user_home(), ".config", "legendary"])
config :heroix, heroix_config_path: Path.join([System.user_home(), ".config", "heroix"])

config :heroix, :phoenix_sass,
  pattern: "sass/*.scss",
  output_dir: "static/assets",
  output_style: 3
