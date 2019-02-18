defmodule Botter.MixProject do
  use Mix.Project

  def project do
    [
      name: "Botter",
      app: :botter,
      version: "0.0.1",
      elixir: "~> 1.8",
      source_url: "https://github.com/kaaboaye/botter",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A simple framework for creating command bots",
      package: [
        licenses: ["i dont know yet"],
        links: %{"GitHub" => "https://github.com/kaaboaye/botter"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
