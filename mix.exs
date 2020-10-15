defmodule ExRunner.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_runner,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: "https://github.com/ndalmia/ex_runner/",
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Elixir library that provides a macro which converts the modules into operations for encapsulating business logics.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Nishant Dalmia"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ndalmia/ex_runner"}
    ]
  end

  defp deps do
    [
      {:ecto, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      source_ref: "v#{@version}",
      source_url: "https://github.com/ndalmia/ex_runner",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
