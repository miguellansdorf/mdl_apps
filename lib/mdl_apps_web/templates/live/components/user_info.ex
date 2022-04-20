defmodule MdlAppsWeb.Live.Components.UserInfo do
  use MdlAppsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="absolute right-0 bottom-0 bg-sky-500 rounded-full px-4 py-2 flex items-center gap-2">
      <div class="w-10 h-10">
        <.live_component module={MdlAppsWeb.Live.Components.Avatar} id="avatar" seed={@user.username} style={@user.avatar} />
      </div>
      <%= live_redirect to: Routes.live_path(@socket, MdlAppsWeb.Live.Account.Profile), class: "pr-2 border-r border-zinc-800" do %>
        <span class="text-white"><%= @user.username %></span>
      <% end %>
      <%= link to: Routes.session_path(@socket, :delete), method: :delete, class: "hover:fill-red-500 flex justify-center items-center" do %>
          <FontAwesome.LiveView.icon name="right-from-bracket" type="solid" class="w-6 h-6" />
        <% end %>
    </div>
    """
  end
end
