defmodule MdlAppsWeb.Live.Account.Components.ChangePassword do
  use MdlAppsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form let={f} for={@password_changeset} class="flex flex-col justify-center items-center" phx-change="validate_password" phx-submit="change_password">
        <div class="form-group">
            <FontAwesome.LiveView.icon name="key" type="solid" class="w-8 h-8 shrink-0 fill-sky-500" />
            <%= password_input f, :current_password, placeholder: "Current password", class: "grow", phx_debounce: "500", value: input_value(f, :current_password), required: true %>
        </div>
        <%= error_tag f, :current_password %>
    
        <div class="form-group">
            <FontAwesome.LiveView.icon name="key" type="solid" class="w-8 h-8 shrink-0 fill-sky-500" />
            <%= password_input f, :password, placeholder: "New password", class: "grow", phx_debounce: "500", value: input_value(f, :password), required: true %>
        </div>
        <%= error_tag f, :password %>
    
        <div class="form-group">
            <FontAwesome.LiveView.icon name="key" type="solid" class="w-8 h-8 shrink-0 fill-sky-500" />
            <%= password_input f, :password_confirmation, placeholder: "Repeat new password", class: "grow", phx_debounce: "500", value: input_value(f, :password_confirmation), required: true %>
        </div>
        <%= error_tag f, :password_confirmation %>
    
        <%= submit "Change password", class: "bg-sky-500 text-white py-1 px-2 rounded-lg hover:bg-zinc-600 transition" %>
      </.form>
    </div>
    """
  end
end
