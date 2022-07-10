import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :heroix, HeroixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "FROAXRHLjZ4uCWFLlahuvXhY1AMrda8mu91LYU1NG4h0XIMncUCJuVkfp83A49dB",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :heroix, legendary_config_path: Path.join([File.cwd!(), "test", "fixtures", "legendary"])
config :heroix, heroix_config_path: Path.join([File.cwd!(), "test", "fixtures", "heroix"])
config :heroix, legendary_bin_wrapper: Heroix.Mocks.LegendaryBin
config :heroix, file_manager: Heroix.Mocks.TestFileManager
config :heroix, images_cache: Heroix.Mocks.ImagesCache
