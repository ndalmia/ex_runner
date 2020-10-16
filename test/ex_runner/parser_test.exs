defmodule ExRunner.ParserTest do
  use ExUnit.Case
  doctest ExRunner.Parser

  defmodule UserLogin do
    use Ecto.Schema
    @primary_key false
    embedded_schema do
      field :date, :date
    end
  end

  defmodule UserProfile do
    use Ecto.Schema
    @primary_key false
    embedded_schema do
      field :picture, :string
    end
  end

  defmodule User do
    use Ecto.Schema
    @primary_key false
    embedded_schema do
      field :email, :string
      field :password, :string
      embeds_many :logins, UserLogin
      embeds_one :profile, UserProfile
    end
  end

  test "parse nil" do
    data = nil
    parsed_data = ExRunner.Parser.parse(ExRunner.ParserTest.User, data)

    assert Enum.sort(Map.keys(parsed_data)) == Enum.sort([:email, :password, :logins, :profile])
  end

  test "parse with nil embeds" do
    data = %{
      email: "test@test.com",
      password: "test"
    }
    parsed_data = ExRunner.Parser.parse(ExRunner.ParserTest.User, data)

    assert Enum.sort(Map.keys(parsed_data)) == Enum.sort([:email, :password, :logins, :profile])
  end

  test "parse with embeds and few keys as strings" do
    data = %{
      email: "test@test.com",
      password: "test",
      profile: %{
        picture: "picture",
        filtered_key1: "hello",
        filtered_key2: %{
          test: true
        },
        filtered_key3: [%{
          test: true
        }]
      },
      logins: [
        %{
          date: "25 jan 2020",
          filtered_key1: "hello",
          filtered_key2: %{
            test: true
          },
          filtered_key3: [%{
            test: true
          }]
        }
      ],
      filtered_key1: "hello",
      filtered_key2: %{
        test: true
      },
      filtered_key3: [%{
        test: true
      }]
    }

    data = Map.delete(data, :password)
    data = Map.put(data, "password", "test")

    profile = data.profile

    profile = Map.delete(profile, :picture)
    profile = Map.put(profile, "picture", "picture")

    data = Map.put(data, :profile, profile)

    parsed_data = ExRunner.Parser.parse(ExRunner.ParserTest.User, data)

    assert Enum.sort(Map.keys(parsed_data)) == Enum.sort([:email, :password, :logins, :profile]) &&
           Enum.sort(Map.keys(parsed_data.profile)) == Enum.sort([:picture]) &&
           Enum.sort(Map.keys(Enum.at(parsed_data.logins, 0))) == Enum.sort([:date])
  end
end
