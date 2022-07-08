defmodule Heroix.MockedLegendaryBin do
  use HeroixLog, "MockedBin"

  def install(app_name, opts \\ []) do
    log("Running legendary install: #{app_name} (with options #{inspect(opts)}")

    {:ok, 1, 1}
  end

  def run(args, opts \\ [])

  def run(["status"], [:sync]) do
    log("Running legendary: status (with options sync}")
    {:ok, [stdout: ["Epic account: myuser\n"], stderr: []]}
  end

  def run(["install" | _], [:sync]) do
    log("Running legendary: install (with options sync}")
    {:error, [exit_status: 256, stdout: [], stderr: ["Download size: 3 GiB (Compression\n"]]}
  end

  def run(["info" | _], [:sync]) do
    log("Running legendary: info (with options sync}")

    {:ok,
     [stdout: ["{\"manifest\": {\"download_size\": 30000, \"disk_size\": 40000}}"], stderr: []]}
  end

  def run(args, [:sync]) do
    log("Running legendary: #{inspect(args)} (with options sync}")
    {:ok, [stdout: [], stderr: []]}
  end

  def run(args, opts) do
    log("Running legendary: #{inspect(args)} (with options #{inspect(opts)}")
    {:ok, 1, 1}
  end

  def kill(pid) do
    log("Stopping: #{pid}")
  end
end
