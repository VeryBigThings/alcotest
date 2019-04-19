use Mix.Config

config Alcotest.Mixfile.project()[:app],
  phoenix_endpoint: Alcotest.Endpoint,
  gql_endpoint: "api/graphql",
  payloads_path: "test/stubs/gql",
  default_headers: []
