defmodule Hello.Rep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reps" do
    field :days, :integer
    field :desc, :string
    field :name, :string
    field :stars, :integer
    field :url, :string
    field :real_url, :string
    field :fork, :integer
    field :watch, :integer
    field :grp_name, :string
    field :grp_desc, :string

    timestamps()
  end

  @doc false
  def changeset(rep, attrs) do
    rep
    |> cast(attrs, [:name, :desc, :stars, :days, :url, :real_url, :fork, :watch, :grp_name, :grp_desc])
    |> validate_required([:name, :desc, :stars, :days, :url, :grp_name, :grp_desc])
  end
end
