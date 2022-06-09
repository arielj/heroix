defmodule Heroix.MockedLegendaryBin do
  require Logger

  def install(app_name, opts \\ []) do
    Logger.info(
      "[MockedBin] Running legendary install: #{app_name} (with options #{inspect(opts)}"
    )

    {:ok, 1, 1}
  end

  def run(args, opts \\ []) do
    Logger.info("[MockedBin] Running legendary: #{inspect(args)} (with options #{inspect(opts)}")
    {:ok, 1, 1}
  end

  def kill(pid) do
    Logger.info("[MockedBin] stopping: #{pid}")
  end
end
