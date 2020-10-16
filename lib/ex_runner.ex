defmodule ExRunner do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      import ExRunner, only: [input: 1, output: 1, embed_object: 2]
      import Ecto.Changeset
      import Ecto.Query

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro input(schema) do
    quote do
      defmodule Input do
        @moduledoc false
        use Ecto.Schema

        @primary_key false
        embedded_schema unquote(schema)
      end
    end
  end

  @doc false
  defmacro output(schema) do
    quote do
      defmodule Output do
        @moduledoc false
        use Ecto.Schema

        @primary_key false
        embedded_schema unquote(schema)
      end
    end
  end

  @doc false
  defmacro embed_object(name, schema) do
    quote do
      defmodule unquote(name) do
        @moduledoc false
        use Ecto.Schema

        @primary_key false
        embedded_schema unquote(schema)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      def run(params) when is_list(params) do
        params |> Enum.into(%{}) |> run()
      end

      def run(params) when is_nil(params) do
        run(%{})
      end

      def run(%_{} = params) do
        params |> Map.from_struct() |> run()
      end

      @doc """
      Runs the operation. Argument can be a map, a keyword list or a struct. If the operation is successful, it returns {:ok, output}. In other cases, it returns {:error, changeset}
      """
      def run(%{} = params) do
        input = ExRunner.Parser.parse(__MODULE__.Input, params)
        changeset = EctoMorph.generate_changeset(input, __MODULE__.Input)
        changeset = Map.put(changeset, :params, input)

        if changeset.valid? do
          changeset = validate(changeset)
          if changeset.valid? do
            response = execute(changeset)
            cond do
              is_nil(response) -> {:ok, %{}}
              is_nil(Map.get(response, :valid?)) ->
                output = ExRunner.Parser.parse(__MODULE__.Output, response)
                changeset = EctoMorph.generate_changeset(output, __MODULE__.Output)
                if changeset.valid?, do: {:ok, output}, else: raise Ecto.InvalidChangesetError, changeset: changeset
              true -> {:error, response}
            end
          else
            {:error, changeset}
          end
        else
          {:error, changeset}
        end
      end

      @doc """
      Implements the bang for run function. Argument can be a map, a keyword list or a struct. If the operation is successful, it returns output. In other cases, it raises Ecto.InvalidChangesetError.
      """
      def run!(params) do
        case run(params) do
          {:ok, response} -> response
          {:error, changeset} -> raise Ecto.InvalidChangesetError, changeset: changeset
        end
      end
    end
  end
end
