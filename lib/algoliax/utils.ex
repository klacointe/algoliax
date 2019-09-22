defmodule Algoliax.MissingRepoError do
  defexception [:message]

  @impl true
  def exception(index_name) do
    %__MODULE__{message: "No repo configured for index #{index_name}"}
  end
end

defmodule Algoliax.MissingIndexNameError do
  defexception [:message]

  @impl true
  def exception(_) do
    %__MODULE__{message: "No index_name configured"}
  end
end

defmodule Algoliax.Utils do
  @moduledoc false

  @attribute_prefix "algoliax_attr_"
  @batch_size 500

  import Ecto.Query

  def prefix_attribute(attribute) do
    :"#{@attribute_prefix}#{attribute}"
  end

  def unprefix_attribute(attribute) do
    attribute
    |> Atom.to_string()
    |> String.replace(@attribute_prefix, "")
    |> String.to_atom()
  end

  def index_name(settings) do
    index_name = Keyword.get(settings, :index_name)

    if index_name do
      index_name
    else
      raise Algoliax.MissingIndexNameError
    end
  end

  def repo(settings) do
    index_name = Keyword.get(settings, :index_name)
    repo = Keyword.get(settings, :repo)

    if repo do
      repo
    else
      raise Algoliax.MissingRepoError, index_name
    end
  end

  def find_in_batches(repo, query, id, exectute) do
    q =
      if id > 0 do
        from(q in query, limit: ^@batch_size, where: q.id > ^id, order_by: q.id)
      else
        from(q in query, limit: ^@batch_size, order_by: q.id)
      end

    results = repo.all(q)

    response = exectute.(results)

    if length(results) == @batch_size do
      last_id = results |> List.last() |> Map.get(:id)

      find_in_batches(repo, query, last_id, exectute)
    else
      response
    end
  end
end
