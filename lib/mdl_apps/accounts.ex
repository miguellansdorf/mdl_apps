defmodule MdlApps.Accounts do
  @moduledoc """
  Defines the accounts context
  """

  alias MdlApps.Repo
  alias MdlApps.Accounts.User
  alias MdlApps.Accounts.UserToken
  alias MdlApps.Accounts.UserNotifier

  import Ecto.Query, only: [from: 2]

  @doc """
  Ecto.Changeset for user registration
  """
  @spec change_user_registration(%User{}, map, keyword) :: Ecto.Changeset.t()
  def change_user_registration(user, attrs, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  @doc """
  Ecto.Changeset for user password reset
  """
  @spec change_user_reset_password(%User{}, map, keyword) :: Ecto.Changeset.t()
  def change_user_reset_password(user, attrs, opts \\ []) do
    User.password_reset_changeset(user, attrs, opts)
  end

  @doc """
  Ecto.Changeset for user password change
  """
  @spec change_user_change_password(%User{}, map, keyword) :: Ecto.Changeset.t()
  def change_user_change_password(user, attrs, curr_user, opts \\ []) do
    User.password_change_changeset(user, attrs, curr_user, opts)
  end

  @doc """
  Ecto.Changeset for user avatar change
  """
  @spec change_user_change_avatar(%User{}, map) :: Ecto.Changeset.t()
  def change_user_change_avatar(user, attrs) do
    User.avatar_changeset(user, attrs)
  end

  @doc """
  Creates a new user
  """
  @spec register_user(map) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    change_user_registration(%User{}, attrs)
    |> Repo.insert()
  end

  @doc """
  Get user by id
  """
  @spec get_user!(non_neg_integer) :: %User{} | Ecto.NoResultsError
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Get user by email
  """
  @spec get_user_by_email(String.t()) :: %User{} | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Get user by login credentials using either username or email and password
  """
  @spec get_user_by_credentials(String.t(), String.t()) ::
          {:ok, %User{}} | {:error, :invalid_credentials}
  def get_user_by_credentials(login, password) when is_binary(login) and is_binary(password) do
    query = from u in User, where: u.username == ^login or u.email == ^login

    with %User{} = user <- Repo.one(query), true <- User.verify_password(user, password) do
      {:ok, user}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Get user by session token
  """
  @spec get_user_by_session_token(String.t()) :: %User{} | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Send confirmation instructions to user's email
  """
  @spec send_user_confirmation_instructions(%User{}, function) ::
          {:error, :already_confirmed} | {:ok, Swoosh.Email.t()} | {:error, String.t()}
  def send_user_confirmation_instructions(user, url_func) when is_function(url_func, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, url_func.(encoded_token))
    end
  end

  @doc """
  Confirm user using the token sent to their email
  """
  @spec confirm_user(String.t()) :: {:ok, %User{}} | :error
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirmation_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_context_query(user, ["confirm"]))
  end

  @doc """
  Create a new session token for user
  """
  @spec generate_user_session_token(%User{}) :: String.t()
  def generate_user_session_token(user) do
    {session_token, token} = UserToken.build_session_token(user)
    Repo.insert!(token)
    session_token
  end

  @doc """
  Delete session token
  """
  @spec delete_session_token(String.t()) :: :ok
  def delete_session_token(token) when is_binary(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Send reset password instructions to user's email
  """
  @spec send_user_reset_password_instructions(%User{}, function) ::
          {:ok, Swoosh.Email.t()} | {:error, String.t()}
  def send_user_reset_password_instructions(user, url_func) when is_function(url_func, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, url_func.(encoded_token))
  end

  @doc """
  Verify the token for password reset
  """
  @spec verify_user_reset_password_token(String.t()) :: :ok | :error
  def verify_user_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} <- Repo.one(query) do
      :ok
    else
      _ -> :error
    end
  end

  @doc """
  Reset the user's password
  """
  @spec reset_password_user(String.t(), map) :: {:ok, %User{}} | :error
  def reset_password_user(token, attrs) when is_binary(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(reset_password_user_multi(user, attrs)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp reset_password_user_multi(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_reset_changeset(user, attrs))
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_context_query(user, ["reset_password", "session"])
    )
  end

  @doc """
  Change the user's password
  """
  @spec change_user_password(%User{}, map, binary) ::
          {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def change_user_password(user, attrs, session_token) do
    changeset = User.password_change_changeset(user, attrs, user, should_verify: true)

    if changeset.valid? do
      {:ok, %{user: updated_user}} =
        Repo.transaction(change_user_password_multi(user, changeset, session_token))

      {:ok, updated_user}
    else
      {:error, changeset}
    end
  end

  defp change_user_password_multi(user, changeset, session_token) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_context_excluding_token_query(
        user,
        ["reset_password", "session"],
        session_token
      )
    )
  end

  @doc """
  Update the user's avatar
  """
  @spec change_user_avatar(%User{}, map) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def change_user_avatar(user, attrs) do
    User.avatar_changeset(user, attrs)
    |> Repo.update()
  end
end
