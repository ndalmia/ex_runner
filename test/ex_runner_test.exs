defmodule ExRunnerTest do
  use ExUnit.Case
  doctest ExRunner

  defmodule CreateSession do
    use ExRunner

    input do
      field :email, :string
      field :password, :string
      field :output_type, :string
    end

    output do
      field :session_id, Ecto.UUID
    end

    defp validate(changeset) do
      changeset
      |> validate_required([:email, :password])
      |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_length(:password, min: 4)
    end
  
    defp execute(changeset) do
      params = changeset.changes

      case check_credentials(params) do
        true -> generate_session(params)
        false -> add_error(changeset, :credentials, "are invalid")
      end
    end

    defp check_credentials(params) do
      (params.email == "test@test.com" and params.password == "test")
    end

    defp generate_session(params) do
      case params.output_type do
        nil -> %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}
        "only_session" -> %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}
        "session_and_test" -> %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf", test: true}
        "invalid_session" -> %{session_id: 1}
      end
    end
  end

  test "run operation with wrong email type" do
    {result, response} = CreateSession.run(email: 1, password: "1234")
    assert (result == :error && response.errors == [email: {"is invalid", [type: :string, validation: :cast]}])
  end

  test "run operation with wrong validations" do
    {result, response} = CreateSession.run(email: "test", password: "1234")
    assert (result == :error && response.errors == [email: {"has invalid format", [validation: :format]}])
  end

  test "run! operation with wrong validations" do
    assert_raise Ecto.InvalidChangesetError, fn ->
      CreateSession.run!(email: "test", password: "1234")
    end
  end

  test "run operation with wrong credentials" do
    {result, response} = CreateSession.run(email: "test@test.com", password: "1234")
    assert (result == :error && response.errors == [credentials: {"are invalid", []}])
  end

  test "run! operation with wrong credentials" do
    assert_raise Ecto.InvalidChangesetError, fn ->
      CreateSession.run!(email: "test@test.com", password: "1234")
    end
  end

  test "run operation with correct credentials and only_session output" do
    assert CreateSession.run(email: "test@test.com", password: "test", output_type: "only_session") == {:ok, %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}}
  end

  test "run! operation with correct credentials and only_session output" do
    assert CreateSession.run!(email: "test@test.com", password: "test", output_type: "only_session") == %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}
  end

  test "run operation with correct credentials and session_and_test output" do
    assert CreateSession.run(email: "test@test.com", password: "test", output_type: "session_and_test") == {:ok, %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}}
  end

  test "run operation with correct credentials and invalid_session output" do
    assert_raise Ecto.InvalidChangesetError, fn ->
      CreateSession.run(email: "test@test.com", password: "test", output_type: "invalid_session")
    end
  end
  
end
