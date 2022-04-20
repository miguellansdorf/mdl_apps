defmodule MdlAppsWeb.Live.Components.Navbar do
  use MdlAppsWeb, :live_component

  @no_auth_links [
    login: %{
      route_helper: &Routes.live_path/2,
      module: MdlAppsWeb.Live.Auth.Login,
      fa_name: "fingerprint"
    },
    register: %{
      route_helper: &Routes.live_path/2,
      module: MdlAppsWeb.Live.Auth.Register,
      fa_name: "user-pen"
    }
  ]

  @auth_links [
    home: %{route_helper: &Routes.live_path/2, module: MdlAppsWeb.Live.Home, fa_name: "house"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="shrink-0 w-14 h-full bg-zinc-700 flex flex-col justify-between items-center">
      <%= for info <- @links do %>
        <%= live_redirect to: info.link, class: "grow hover:bg-zinc-600 w-full flex justify-center items-center " <> info.add_class do %>
          <FontAwesome.LiveView.icon name={info.fa_name} type="solid" class="w-10 h-10 mx-auto" />
        <% end %>
      <% end %>
    </div>
    """
  end

  def prepare_links(id, socket) do
    links = if socket.assigns.current_user, do: @auth_links, else: @no_auth_links

    for {key, info} <- links, into: [] do
      new_info =
        %{}
        |> Map.put(:link, info.route_helper.(socket, info.module))
        |> Map.put(:fa_name, info.fa_name)

      case key do
        ^id -> Map.put(new_info, :add_class, "fill-sky-500")
        _ -> Map.put(new_info, :add_class, "")
      end
    end
  end
end
