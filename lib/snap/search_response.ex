defmodule Snap.SearchResponse do
  @moduledoc """
  Represents the response from ElasticSearch's [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html).

  Implements `Enumerable`, so you can iterate directly over the struct.
  """
  defstruct [:took, :timed_out, :_shards, :hits, :_scroll_id, :pit_id]

  def new(response) do
    %__MODULE__{
      took: response["took"],
      timed_out: response["timed_out"],
      _shards: response["_shards"],
      hits: Snap.Hits.new(response["hits"]),
      _scroll_id: response["_scroll_id"],
      pit_id: response["pit_id"]
    }
  end

  @type t :: %__MODULE__{
          took: integer(),
          timed_out: boolean(),
          _shards: map(),
          hits: Snap.Hits.t(),
          _scroll_id: String.t() | nil,
          pit_id: map() | nil
        }

  defimpl Enumerable do
    def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}, &1, fun)}
    end

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: []}}, {:cont, acc}, _fun),
      do: {:done, acc}

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: [head | tail]}}, {:cont, acc}, fun) do
      reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: tail}}, fun.(head, acc), fun)
    end

    def count(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}) do
      {:ok, Enum.count(hits)}
    end

    def member?(response, elem) do
      {:ok, Enum.member?(response.hits.hits, elem)}
    end

    def slice(_response), do: {:error, __MODULE__}
  end
end
