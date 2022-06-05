defmodule Heroix.LegendaryBin do
  def run(args = ["-y", "install" | _]) do
    # add {:group, 0} and :kill_group for installations
    # needed to properly kill the installation process and all the workers when stopped
    :exec.run([bin_path() | args], [:stdout, :stderr, :monitor, :kill_group, {:group, 0}])
  end

  def run(args) do
    :exec.run([bin_path() | args], [:stdout, :stderr, :monitor])
  end

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
