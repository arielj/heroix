defmodule Heroix.LegendaryBin do
  def install(app_name, args \\ []) do
    args = ["-v", "install", app_name] ++ ["-y"] ++ args

    # add {:group, 0} and :kill_group for installations
    # needed to properly kill the installation process and all the workers when stopped
    :exec.run([bin_path() | args], [:stdout, :stderr, :monitor, :kill_group, {:group, 0}])
  end

  # TODO: no feedback to the user for now when fetching the list
  def run(args = ["list"]) do
    :exec.run([bin_path() | args], [])
  end

  def run(args, opts \\ []) do
    :exec.run([bin_path() | args], opts ++ [:stdout, :stderr, :monitor])
  end

  def kill(nil), do: nil

  def kill(pid) do
    :exec.stop(pid)
  end

  defp bin_path() do
    [os, bin_name] =
      case :os.type() do
        {:unix, :linux} -> ["linux", "legendary"]
        {:win32, _} -> ["win32", "legendary.exe"]
        {_, _} -> ["darwin", "legendary"]
      end

    Path.join([File.cwd!(), "priv", "bins", os, bin_name])
  end
end
