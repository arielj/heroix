defmodule Heroix.MockedLegendaryBin do
  use HeroixLog, "MockedBin"

  def install(app_name, opts \\ []) do
    log("Running legendary install: #{app_name} (with options #{inspect(opts)}")

    {:ok, 1, 1}
  end

  def run(args, opts \\ []) do
    log("Running legendary: #{inspect(args)} (with options #{inspect(opts)}")
    {:ok, 1, 1}
  end

  def kill(pid) do
    log("Stopping: #{pid}")
  end
end
