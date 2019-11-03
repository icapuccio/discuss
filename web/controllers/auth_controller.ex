defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug Ueberauth

  alias Discuss.User

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    changeset = User.changeset(%User{}, user_params(auth))
    signin(conn, changeset)
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: topic_path(conn, :index))
  end

  # Private

  defp user_params(auth) do
    %{
      email: auth.info.email,
      provider: "github",
      uid: to_string(auth.uid),
      token: auth.credentials.token
    }
  end

  defp signin(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_id, user.id)
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error signing in")
    end
    |> redirect(to: topic_path(conn, :index))
  end

  defp insert_or_update_user(%{changes: changes}) do
    case Repo.get_by(User, %{provider: changes.provider, uid: changes.uid}) do
      nil  -> %User{} # User not found, we build one
      user -> user
    end
    |> User.changeset(changes)
    |> Repo.insert_or_update
  end
end
