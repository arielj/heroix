defmodule Heroix.MockedLegendaryBin do
  require Logger

  def run(args) do
    Logger.info("[MockedBin] Running legendary: #{inspect(args)}")
    {:ok, 1, 1}
  end

  def kill(pid) do
    Logger.info("[MockedBin] stopping: #{pid}")
  end
end
