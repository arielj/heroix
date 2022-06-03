defmodule Heroix.LegendaryBin do
  def run(args) do
    # {:group, 0} and :kill_group are needed to properly kill the installation process and all the workers
    :exec.run([bin_path() | args], [:stdout, :stderr, :monitor, :kill_group, {:group, 0}])
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
