defmodule HeroixLog do
  defmacro __using__(tag) do
    quote do
      require Logger

      def log(to_log) do
        Logger.info("[#{unquote(tag)}] #{inspect(to_log)}")
        to_log
      end
    end
  end
end
