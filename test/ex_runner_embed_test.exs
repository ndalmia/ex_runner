defmodule ExRunnerEmbedTest do
  use ExUnit.Case
  doctest ExRunner

  defmodule ProcessUserData do
    use ExRunner
  
    embed_object Profile do
      field :name, :string
      field :picture, :string
      field :mobile_numbers, {:array, :string}
    end
  
    embed_object Address do
      field :address, :string
      field :country, :string
    end
  
    input do
      field :id, :integer
      embeds_one :profile, ProcessUserData.Profile
      embeds_many :addresses, ProcessUserData.Address
    end
  
    output do
      field :id, :integer
      embeds_one :profile, ProcessUserData.Profile
      embeds_many :addresses, ProcessUserData.Address
    end
  
    defp validate(changeset) do
      changeset
      |> validate_required([:id])
      |> EctoMorph.validate_nested_changeset([:profile], fn changeset ->
        changeset
        |> validate_required([:name, :picture])
      end)
      |> EctoMorph.validate_nested_changeset([:addresses], fn changeset ->
        changeset
        |> validate_required([:address, :country])
        |> validate_inclusion(:country, ["US", "NL"])
      end)
    end
  
    defp execute(changeset) do
      changeset.params |> process_data
    end
  
    defp process_data(data) do
      profile = data.profile
      processed_picture = "processed_picture"
      profile = Map.put(profile, :picture, processed_picture)
      Map.put(data, :profile, profile)
    end
  end

  test "run embed operation with wrong validations" do
    {result, response} = ProcessUserData.run(%{addresses: [%{}]})
    assert (result == :error &&
            response.errors == [id: {"can't be blank", [validation: :required]}] &&
            response.changes.profile.errors == [name: {"can't be blank", [validation: :required]}, picture: {"can't be blank", [validation: :required]}] &&
            Enum.at(response.changes.addresses, 0).errors == [address: {"can't be blank", [validation: :required]}, country: {"can't be blank", [validation: :required]}])
  end

  test "run embed operation with correct validations" do
    data = %{
      id: 1,
      profile: %{
        name: "Nishant",
        picture: "picture",
        mobile_numbers: ["9999999999"]
      },
      addresses: [
        %{
          address: "address",
          country: "US"
        }
      ]
    }

    profile = data.profile
    profile = Map.put(profile, :picture, "processed_picture")
    processed_data = Map.put(data, :profile, profile)

    {result, response} = ProcessUserData.run(data)
    assert (result == :ok && response == processed_data)
  end
end
  