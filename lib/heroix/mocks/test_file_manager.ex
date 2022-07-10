defmodule Heroix.Mocks.TestFileManager do
  def write(_path, content) do
    # IO.puts("New content for #{path}")
    # IO.inspect(content)
    {:ok, content}
  end

  def read(path) do
    # IO.puts("read #{path}")
    File.read(path)
  end
end
