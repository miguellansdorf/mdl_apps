defmodule MdlApps.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @avatar_styles [
    adventurer: "adventurer",
    "adventurer-neutral": "adventurer-neutral",
    avataaars: "avataaars",
    "big-ears": "big-ears",
    "big-ears-neutral": "big-ears-neutral",
    "big-smile": "big-smile",
    bottts: "bottts",
    croodles: "croodles",
    "croodles-neutral": "croodles-neutral",
    identicon: "identicon",
    initials: "initials",
    micah: "micah",
    miniavs: "miniavs",
    "open-peeps": "open-peeps",
    personas: "personas",
    "pixel-art": "pixel-art",
    "pixel-art-neutral": "pixel-art-neutral"
  ]

  schema "users" do
    field :confirmed_at, :naive_datetime
    field :email, :string
    field :password, :string, redact: true
    field :username, :string
    field :avatar, :string, default: "initials"

    timestamps()
  end

  @doc false
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_username()
    |> validate_email()
    |> validate_password(opts)
  end

  @doc false
  def password_reset_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_password(opts)
  end

  @doc false
  def password_change_changeset(user, attrs, curr_user, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_current_password(curr_user, Map.get(attrs, "current_password", ""), opts)
    |> validate_password(opts)
  end

  @doc false
  def avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [:avatar])
    |> validate_inclusion(:avatar, Keyword.values(@avatar_styles))
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 6, max: 20)
    |> validate_format(:username, ~r/^[^\s]+$/, message: "must not contain whitespace")
    |> unsafe_validate_unique(:username, MdlApps.Repo)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must contain @ and no whitespace")
    |> unsafe_validate_unique(:email, MdlApps.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    hash_password = Keyword.get(opts, :hash_password, true)

    changeset =
      changeset
      |> validate_required([:password])
      |> validate_length(:password, min: 8, max: 30)
      |> validate_format(:password, ~r/[a-z]+/,
        message: "must contain at least 1 lowercase character"
      )
      |> validate_format(:password, ~r/[A-Z]+/,
        message: "must contain at least 1 uppercase character"
      )
      |> validate_format(:password, ~r/[0-9]+/, message: "must contain at least 1 number")
      |> validate_confirmation(:password, required: true)

    if hash_password do
      add_password_hash(changeset)
    else
      changeset
    end
  end

  defp validate_current_password(changeset, user, password, opts) do
    case Keyword.get(opts, :should_verify, true) do
      false ->
        changeset

      true ->
        if verify_password(user, password) do
          changeset
        else
          add_error(changeset, :current_password, "Invalid current password")
        end
    end
  end

  defp add_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password: Pbkdf2.hash_pwd_salt(password))
  end

  defp add_password_hash(changeset), do: changeset

  @doc false
  def confirmation_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc false
  def verify_password(user, password) do
    Pbkdf2.verify_pass(password, user.password)
  end
end
