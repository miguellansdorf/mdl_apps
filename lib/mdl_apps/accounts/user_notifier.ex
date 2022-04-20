defmodule MdlApps.Accounts.UserNotifier do
  @moduledoc """
  Defines functions for sending emails to users
  """
  import Swoosh.Email
  alias MdlApps.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"MdlApps", "noreply@mdlapps.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Sends confirmation instructions to the user for account confirmation
  """
  @spec deliver_confirmation_instructions(%MdlApps.Accounts.User{}, binary) ::
          {:ok, term} | {:error, term}
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation Instructions", """
    ------------------------------------
    Hi #{user.username}

    Thanks for making an account with us at MdlApps.
    Please follow the following url to complete your registration

    #{url}

    If this isn't you then please ignore this message
    ------------------------------------
    """)
  end

  @doc """
  Sends instructions to the user for resetting their password
  """
  @spec deliver_reset_password_instructions(%MdlApps.Accounts.User{}, binary) ::
          {:ok, term} | {:error, term}
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset Password Instructions", """
    ------------------------------------
    Hi #{user.username}

    Please follow the following url to reset your password

    #{url}

    If this isn't you then please ignore this message
    ------------------------------------
    """)
  end
end
