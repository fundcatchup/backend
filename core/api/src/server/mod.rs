mod config;
pub use config::ServerConfig;

use async_graphql::{EmptySubscription, Schema};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::{routing::get, Extension, Router};
use axum_tracing_opentelemetry::middleware::{OtelAxumLayer, OtelInResponseLayer};

mod graphql;
pub use graphql::schema;

use crate::app::ApiApp;

pub async fn graphql_handler(
    schema: Extension<Schema<graphql::Query, graphql::Mutation, EmptySubscription>>,
    Extension(config): Extension<ServerConfig>,
    req: GraphQLRequest,
) -> GraphQLResponse {
    let mut req = req.into_inner();

    req = req.data(config);

    schema.execute(req).await.into()
}

async fn playground() -> impl axum::response::IntoResponse {
    axum::response::Html(async_graphql::http::playground_source(
        async_graphql::http::GraphQLPlaygroundConfig::new("/graphql"),
    ))
}

async fn run_api_gql_server(config: ServerConfig, api_app: ApiApp) -> anyhow::Result<()> {
    let schema = graphql::schema(Some(api_app.clone()));

    let app = Router::new()
        .route("/graphql", get(playground).post(graphql_handler))
        .layer(OtelInResponseLayer::default())
        .layer(OtelAxumLayer::default())
        .layer(Extension(schema))
        .layer(Extension(config.clone()));

    println!("Starting graphql server on port {}", config.api_server_port);
    axum::Server::bind(&std::net::SocketAddr::from((
        [0, 0, 0, 0],
        config.api_server_port,
    )))
    .serve(app.into_make_service())
    .await?;

    Ok(())
}

pub async fn run(config: ServerConfig, api_app: ApiApp) -> anyhow::Result<()> {
    run_api_gql_server(config, api_app).await
}
