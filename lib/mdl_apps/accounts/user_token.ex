defmodule MdlApps.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @rand_bytes 32
  @hash_algorithm :sha256

  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @session_validity_in_days 60

  schema "users_tokens" do
    field :context, :string
    field :sent_to, :string
    field :token, :binary
    belongs_to :user, MdlApps.Accounts.User

    timestamps(updated_at: false)
  end

  @doc """
  Builds a hashed token for instructions sent to the user's email for the given context
  """
  @spec build_email_token(%MdlApps.Accounts.User{}, binary) :: {binary, %__MODULE__{}}
  def build_email_token(user, context) do
    build_hashed_token(user, context)
  end

  defp build_hashed_token(user, context) do
    token = :crypto.strong_rand_bytes(@rand_bytes)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {
      Base.url_encode64(token, padding: false),
      %__MODULE__{
        token: hashed_token,
        context: context,
        sent_to: user.email,
        user_id: user.id
      }
    }
  end

  @doc """
  Builds a session token
  """
  @spec build_session_token(%MdlApps.Accounts.User{}) :: {binary, %__MODULE__{}}
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_bytes)

    {
      token,
      %__MODULE__{
        token: token,
        context: "session",
        user_id: user.id
      }
    }
  end

  @doc """
  Verifies the token sent by the user for the given context
  """
  @spec verify_email_token_query(binary, binary) :: :error | {:ok, Ecto.Query.t()}
  def verify_email_token_query(encoded_token, context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Creates the query for getting a user by session token
  """
  @spec verify_session_token_query(binary) :: {:ok, Ecto.Query.t()}
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Query for the given token and context
  """
  @spec token_and_context_query(binary, binary) :: Ecto.Query.t()
  def token_and_context_query(token, context) do
    from __MODULE__, where: [token: ^token, context: ^context]
  end

  @doc """
  Query for all tokens for the user
  """
  @spec users_and_context_query(%MdlApps.Accounts.User{}, :all) :: Ecto.Query.t()
  def users_and_context_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  @doc """
  Query for user tokens for the given contexts
  """
  @spec user_and_context_query(%MdlApps.Accounts.User{}, list(binary)) :: Ecto.Query.t()
  def user_and_context_query(user, [_ | _] = contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @doc """
  Query for user tokens for the given contexts not including the provided token
  """
  @spec user_and_context_excluding_token_query(%MdlApps.Accounts.User{}, list(binary), binary) ::
          Ecto.Query.t()
  def user_and_context_excluding_token_query(user, [_, _] = contexts, token) do
    from t in __MODULE__,
      where: t.user_id == ^user.id and t.context in ^contexts and t.token != ^token
  end
end
