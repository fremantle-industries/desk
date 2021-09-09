import Config

# Shared variables
env = config_env() |> Atom.to_string()

# Tai
partition = System.get_env("MIX_TEST_PARTITION")
default_database_url = "postgres://postgres:postgres@localhost:5432/desk_?"
configured_database_url = System.get_env("DATABASE_URL") || default_database_url
database_url = "#{String.replace(configured_database_url, "?", env)}#{partition}"

config :tai, Tai.Orders.OrderRepo,
  url: database_url,
  pool_size: 5

config :tai, order_workers: 2
config :tai, order_workers_max_overflow: 0
config :tai, order_transition_workers: 2

config :tai, send_orders: false
config :tai, fleets: %{}
config :tai, advisor_groups: %{}
config :tai, venues: %{}

# Conditional configuration
if config_env() == :dev do
  # Shared dev variables
  http_port = (System.get_env("HTTP_PORT") || "4000") |> String.to_integer()
  workbench_host = System.get_env("WORKBENCH_HOST") || "workbench.localhost"
  history_host = System.get_env("HISTORY_HOST") || "history.localhost"

  workbench_secret_key_base = System.get_env("WORKBENCH_SECRET_KEY_BASE") || "vJP36v4Gi2Orw8b8iBRg6ZFdzXKLvcRYkk1AaMLYX0+ry7k5XaJXd/LY/itmoxPP"
  workbench_live_view_signing_salt = System.get_env("WORKBENCH_LIVE_VIEW_SIGNING_SALT") || "TolmUusQ6//zaa5GZHu7DG2V3YAgOoP/"
  history_secret_key_base = System.get_env("HISTORY_SECRET_KEY_BASE") || "5E5zaJwG5w2ABR+0p+4GQs1nwzz5e7UbkEa6hlpel6wcrI6CAhWsrKWEecfYFWRF"
  history_live_view_signing_salt = System.get_env("HISTORY_LIVE_VIEW_SIGNING_SALT") || "MXNTK//1Uc1R5wIKBGTZyTPPEQyVxSo3"

  config :tai, venues: %{
    ftx: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Ftx,
      products: "*",
      order_books: "ar-perp btc-perp eth-perp luna-perp"
    ]
  }

  # Workbench
  config :workbench,
         :prometheus_metrics_port,
         {:system, :integer, "WORKBENCH_PROMETHEUS_METRICS_PORT", 9569}

  config :workbench, Workbench.Repo,
    url: database_url,
    pool_size: 5

  config :workbench, WorkbenchWeb.Endpoint,
    http: [port: http_port],
    url: [host: workbench_host, port: http_port],
    render_errors: [view: WorkbenchWeb.ErrorView, accepts: ~w(html json)],
    pubsub_server: Tai.PubSub,
    secret_key_base: workbench_secret_key_base,
    live_view: [signing_salt: workbench_live_view_signing_salt],
    server: false

  config :workbench,
    asset_aliases: %{
      btc: [:xbt],
      usd: [:busd, :pax, :usdc, :usdt, :tusd]
    },
    balance_snapshot: %{
      enabled: {:system, :boolean, "BALANCE_SNAPSHOT_ENABLED", false},
      boot_delay_ms: {:system, :integer, "BALANCE_SNAPSHOT_BOOT_DELAY_MS", 10_000},
      every_ms: {:system, :integer, "BALANCE_SNAPSHOT_EVERY_MS", 60_000},
      btc_usd_venue: {:system, :atom, "BALANCE_SNAPSHOT_BTC_USD_VENUE", :ftx},
      btc_usd_symbol: {:system, :atom, "BALANCE_SNAPSHOT_BTC_USD_SYMBOL", :"btc-perp"},
      usd_quote_venue: {:system, :atom, "BALANCE_SNAPSHOT_USD_QUOTE_VENUE", :ftx},
      usd_quote_asset: {:system, :atom, "BALANCE_SNAPSHOT_USD_QUOTE_ASSET", :usd},
      quote_pairs: [ftx: :usd]
    }

  # History
  config :history,
         :prometheus_metrics_port,
         {:system, :integer, "HISTORY_PROMETHEUS_METRICS_PORT", 9570}

  config :history, History.Repo,
    url: database_url,
    pool_size: 5

  config :history, HistoryWeb.Endpoint,
    http: [port: http_port],
    url: [host: history_host, port: http_port],
    render_errors: [view: HistoryWeb.ErrorView, accepts: ~w(html json)],
    pubsub_server: Tai.PubSub,
    secret_key_base: history_secret_key_base,
    live_view: [signing_salt: history_live_view_signing_salt],
    server: false

  config :history,
    data_adapters: %{
      binance: History.Sources.Binance,
      bitmex: History.Sources.Bitmex,
      bybit: History.Sources.Bybit,
      gdax: History.Sources.Gdax,
      ftx: History.Sources.Ftx,
      okex: History.Sources.OkEx
    }

  # Master Proxy
  config :master_proxy,
    # any Cowboy options are allowed
    http: [:inet6, port: http_port],
    # https: [:inet6, port: 4443],
    backends: [
      %{
        host: ~r/#{workbench_host}/,
        phoenix_endpoint: WorkbenchWeb.Endpoint
      },
      %{
        host: ~r/#{history_host}/,
        phoenix_endpoint: HistoryWeb.Endpoint
      }
    ]

  # Navigation
  config :navigator,
    links: %{
      workbench: [
        %{
          label: "Workbench",
          link: {WorkbenchWeb.Router.Helpers, :balance_all_path, [WorkbenchWeb.Endpoint, :index]},
          class: "text-4xl"
        },
        %{
          label: "Balances",
          link: {WorkbenchWeb.Router.Helpers, :balance_day_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Wallets",
          link: {WorkbenchWeb.Router.Helpers, :wallet_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Accounts",
          link: {WorkbenchWeb.Router.Helpers, :account_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Orders",
          link: {WorkbenchWeb.Router.Helpers, :order_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Positions",
          link: {WorkbenchWeb.Router.Helpers, :position_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Products",
          link: {WorkbenchWeb.Router.Helpers, :product_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Fees",
          link: {WorkbenchWeb.Router.Helpers, :fee_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Venues",
          link: {WorkbenchWeb.Router.Helpers, :venue_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "Advisors",
          link: {WorkbenchWeb.Router.Helpers, :advisor_path, [WorkbenchWeb.Endpoint, :index]}
        },
        %{
          label: "History",
          link: {HistoryWeb.Router.Helpers, :trade_url, [HistoryWeb.Endpoint, :index]}
        }
      ],
      history: [
        %{
          label: "History",
          link: {HistoryWeb.Router.Helpers, :trade_path, [HistoryWeb.Endpoint, :index]},
          class: "text-4xl"
        },
        %{
          label: "Data",
          link: {HistoryWeb.Router.Helpers, :trade_path, [HistoryWeb.Endpoint, :index]}
        },
        %{
          label: "Products",
          link: {HistoryWeb.Router.Helpers, :product_path, [HistoryWeb.Endpoint, :index]}
        },
        %{
          label: "Tokens",
          link: {HistoryWeb.Router.Helpers, :token_path, [HistoryWeb.Endpoint, :index]}
        },
        %{
          label: "Workbench",
          link: {WorkbenchWeb.Router.Helpers, :balance_all_url, [WorkbenchWeb.Endpoint, :index]}
        }
      ]
    }

  # Notifications
  config :notified, pubsub_server: Tai.PubSub

  config :notified,
    receivers: [
      {NotifiedPhoenix.Receivers.Speech, []},
      {NotifiedPhoenix.Receivers.BrowserNotification, []}
    ]

  config :notified_phoenix,
    to_list: {WorkbenchWeb.Router.Helpers, :notification_path, [WorkbenchWeb.Endpoint, :index]}
end

if config_env() == :test do
  config :tai, Tai.Orders.OrderRepo,
    pool: Ecto.Adapters.SQL.Sandbox,
    show_sensitive_data_on_connection_error: true
end
