# ExRunner

Elixir library that provides a macro which converts the modules into operations for encapsulating business logics. It uses **[Ecto Schema](https://hexdocs.pm/ecto/Ecto.Schema.html)** (`embedded_schema`) for defining input / output and **[Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html)** for the validations. :)

## Installation

It can be installed by adding `ex_runner` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_runner, "~> 0.2.0"}
  ]
end
```

## Usage

Let's take an example to understand how this library works. 

**Example - Write an operation which creates the user session by taking email and password.**

**Step 1** - Define a module and add `use ExRunner`.

```elixir
defmodule CreateSession do
  use ExRunner
end
```

**Step 2** - Define input and output for the operation. Input is what will be given as parameters to this operation and Output is what will get returned from the operation as a result.

```elixir
defmodule CreateSession do
  use ExRunner

  input do
    field :email, :string
    field :password, :string
  end

  output do
    field :session_id, Ecto.UUID
  end
end
```

This is just [Ecto Schema](https://hexdocs.pm/ecto/Ecto.Schema.html) For complex schema definition, [embeds_one](https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3) and [embeds_many](https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_many/3) can be used.

**Step 3** - Define validate function which adds the required validations on the inputs passed to the operation.

```elixir
defmodule CreateSession do
  use ExRunner

  input do
    field :email, :string
    field :password, :string
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
end
```

Validate function takes changeset as argument, `params` of which contains the input passed and schema is of type input defined in step 2.

For complex validations, read [Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html)

**Step 4**- Define execute function which performs business logic with the inputs provided. 

```elixir
defmodule CreateSession do
  use ExRunner

  input do
    field :email, :string
    field :password, :string
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
    params = changeset.params

    case (params.email == "test@test.com" and params.password == "test") do
      true -> %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}
      false -> add_error(changeset, :credentials, "are invalid")
    end
  end
end
```

Execute function takes changeset as argument. Inputs / parameters can be found in `changeset.params`.
To add an error, just call add_error of Ecto.Changeset. 

In case of :ok, return the needed response of type output defined in step 4. 

In case of :error, return Ecto.Changeset.

**Step 5** - Try running the operation.

```elixir
# run with valid credentials
> CreateSession.run(email: "test@test.com", password: "test")
{:ok, %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}}

# run! with valid credentials
> CreateSession.run!(email: "test@test.com", password: "test")
%{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}

# run with invalid email format
> CreateSession.run(email: "test", password: "test")
{:error,
#Ecto.Changeset<
  action: nil,
  changes: %{email: "test", password: "testi"},
  errors: [email: {"has invalid format", [validation: :format]}],
  data: #CreateSession.Input<>,
  valid?: false
>}

# run! with invalid email format
> CreateSession.run(email: "test", password: "test")
# raises Ecto.InvalidChangesetError 

# run with invalid credentials
> CreateSession.run(email: "test@test.com", password: "test1")
{:error,
#Ecto.Changeset<
  action: nil,
  changes: %{email: "test@test.com", password: "testi"},
  errors: [credentials: {"are invalid", []}],
  data: #CreateSession.Input<>,
  valid?: false
>}

# run! with invalid credentials
> CreateSession.run!(email: "test@test.com", password: "test1")
# raises Ecto.InvalidChangesetError 
```

I recommend reading [How does the library work internally ?](#how-does-the-library-work-internally) to understand in detail.

## Examples

1 - Write an operation which creates the user session by taking email and password.

```elixir
defmodule CreateSession do
  use ExRunner

  input do
    field :email, :string
    field :password, :string
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
    params = changeset.params

    case (params.email == "test@test.com" and params.password == "test") do
      true -> %{session_id: "870df8e8-3107-4487-8316-81e089b8c2cf"}
      false -> add_error(changeset, :credentials, "are invalid")
    end
  end
end
```

2 - (Embed Example) - Write an operation which takes the user data, process and return them.

```elixir
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
```


## How does the library work internally ?

`run ` can be called either with a keyword list or a map.

1 - It first filters the input and permits only the ones defined in input schema. Even if string keys gets passed to run, it converts them to atoms. This is also true for embeds_one and embeds_many.

2 - It checks the input against the field types defined in input. If invalid, it returns {:error, changeset}

3 - It calls validate which has been defined in the module. If invalid, it returns {:error, changeset}

4 - It calls execute which has been defined in the module. If execute returns changeset, it returns {:error, changeset}. If execute returns other than changeset, it stores it as output.

5 - It filters the output and permits only the ones defined in output schema. This is also true for embeds_one and embeds_many.

6 - It checks the output against the field types defined in output. If invalid, it raises Ecto.InvalidChangesetError.

7 - It returns the output as map finally. {:ok, output}

In case of `run!`, if the returned tuple is of {:error}, it raises errors. if the returned tuple is of {:ok}, it returns output.

