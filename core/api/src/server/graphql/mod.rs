mod schema;

use async_graphql::*;

pub use schema::*;

use crate::app::ApiApp;

pub fn schema(app: Option<ApiApp>) -> Schema<Query, Mutation, EmptySubscription> {
    let schema = Schema::build(Query, Mutation, EmptySubscription)
        .enable_federation()
        .limit_complexity(100);
    if let Some(app) = app {
        schema.data(app).finish()
    } else {
        schema.finish()
    }
}
