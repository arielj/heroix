defmodule HeroixWeb.LoginView do
  use HeroixWeb, :live_view

  alias Heroix.SessionManager

  @sid_url "https://www.epicgames.com/id/api/redirect?"

  def mount(_, _, socket) do
    {:ok, assign(socket, login_in_progress: false, sid: "", error: nil)}
  end

  def render(assigns) do
    url = @sid_url

    ~H"""
    <section id="login">
      <h1>Login</h1>
      <%= if @login_in_progress do %>
        Wait...
      <% else %>
        <h3>Instructions</h3>
        <ol>
          <li>Follow this link <%= link "SID", to: url, target: "_blank" %> (it opens in a new window).</li>
          <li>It will ask you to login to Epic if you are not logged in.</li>
          <li>
            It will redirect you to a new page with text content like
            <pre>
              {"redirectUrl":"https://epicgames.com/account/personal","authorizationCode":null,"sid":"1234123412341234"}
            </pre>
          </li>
          <li>Copy the content for the "sid". In the example above: select the text 1234123412341234, right click and copy to clipboard.</li>
          <li>Paste the copied "sid" into the next input.</li>
          <li>Press the "Login" button.</li>
        </ol>

        <%= if @error do %>
          An error ocurred: <%= @error %>
        <% end %>

        <form phx-change="sid-changed">
          <input name="sid" value={@sid} />
          <button type="button" phx-click="login" disabled={@sid == ""}>Login</button>
        </form>
      <% end %>
    </section>
    """
  end

  def handle_event("sid-changed", %{"_target" => ["sid"], "sid" => sid}, socket) do
    sid = sid |> String.trim()
    {:noreply, assign(socket, :sid, sid)}
  end

  def handle_event("login", _, socket) do
    SessionManager.login(socket.assigns.sid)
    {:noreply, assign(socket, login_in_progress: true, error: nil)}
  end

  def handle_info(%{event: "login_error", payload: %{error: error}}, socket) do
    {:noreply, assign(socket, login_in_progress: false, error: error)}
  end

  def handle_info(event, socket) do
    IO.inspect("Unhandled info: #{inspect(event)}")
    {:noreply, socket}
  end

  def logged_in_state_updates, do: [login_in_progress: false, error: nil]
end
