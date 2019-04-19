defmodule Alcotest do
  @moduledoc """
    Lightweight and compact way to make integration tests for
    GraphQL queries and mutations using `ExUnit` and `Phoenix.ConnTest`.
  """
  @endpoint Confex.get_env(@project_name, :phoenix_endpoint)
  @project_name Alcotest.MixProject.project()[:app]

  require Logger
  import Phoenix.ConnTest, only: [post: 3, build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]

  def gql_call(path, opts \\ []) do
    vars = Keyword.get(opts, :vars, %{})

    operation_name =
      opts
      |> Keyword.get(:operation_name, extract_operation_name(path))
      |> Macro.camelize()

    auth = Keyword.get(opts, :auth, nil)
    debug = Keyword.get(opts, :debug, false)

    headers =
      Keyword.get(opts, :headers, [])
      |> Kernel.++(Confex.get_env(@project_name, :default_headers))
      |> auth_header(auth)

    response =
      path
      |> load_gql_operation()
      |> create_gql_payload(operation_name, vars)
      |> create_gql_call(headers)

    if debug do
      Logger.info("""
        GraphQL call: #{query_name}\n
        #{response}
      """)
    end

    get_in(response, ["data", decapitalize(query_name)])
  end

  defp create_gql_call(request_body, req_headers \\ []) do
    build_conn()
    |> put_headers(req_headers)
    |> post(get_gql_endpoint(), request_body)
    |> Map.get(:resp_body)
    |> Poison.decode!()
  end

  defp load_gql_query(subpath) do
    File.read!(get_payloads_path() <> subpath <> ".graphql")
  end

  defp create_gql_payload(query, operation_name \\ "", variables \\ %{}) do
    %{
      "query" => query,
      "operationName" => operation_name,
      "variables" => variables
    }
  end

  defp extract_query_name(path) do
    path
    |> String.split("/")
    |> List.last()
  end

  def auth_header(headers, nil), do: headers
  def auth_header(headers, auth), do: headers ++ [{"authorization", auth}]

  defp put_headers(conn, headers) do
    Enum.reduce(headers, conn, fn
      {hname, hval}, _acc -> put_req_header(conn, hname, hval)
    end)
  end

  defp decapitalize(string) when is_binary(string) do
    {first, rest} = String.split_at(string, 1)
    String.downcase(first) <> rest
  end

  defp get_gql_endpoint, do: Confex.get_env(@project_name, :gql_endpoint)

  defp get_payloads_path, do: Confex.get_env(@project_name, :payloads_path)
end
