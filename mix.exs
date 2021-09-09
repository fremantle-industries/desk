defmodule Desk.MixProject do
  use Mix.Project

  def project do
    [
      app: :desk,
      version: "0.0.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:postgrex, "~> 0.15"},
      # {:tai, "~> 0.0.69"},
      {:tai, github: "fremantle-industries/tai", sparse: "apps/tai", branch: "main", override: true},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:history, "~> 0.0.11", only: :dev},
      # {:workbench, "~> 0.0.12", only: :dev},
      {:workbench, github: "fremantle-industries/workbench", branch: "replace-advisor-groups-with-fleets", override: true, only: :dev},
      {:logger_file_backend, "~> 0.0.12", only: :dev},
      {:master_proxy, "~> 0.1", only: :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases(:dev) do
    aliases()
    |> Keyword.put(
      :setup, [
        "setup.deps",
        "setup.tai",
        "setup.workbench",
        "setup.history",
        "ecto.setup",
        "run priv/repo/seeds.exs"
      ])
  end

  defp aliases(_) do
    aliases()
    |> Keyword.put(
      :setup,
      [
        "setup.deps",
        "setup.tai",
        "ecto.setup",
        "run priv/repo/seeds.exs"
      ]
    )
  end

  defp aliases do
    [
      "setup.deps": ["deps.get"],
      "setup.tai": ["tai.gen.migration"],
      "setup.workbench": ["workbench.gen.migration"],
      "setup.history": ["history.gen.migration"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "test.watch": ["ecto.create --quiet", "ecto.migrate", "test.watch"]
    ]
  end
end
