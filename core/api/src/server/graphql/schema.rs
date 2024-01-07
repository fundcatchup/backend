use async_graphql::*;

#[derive(SimpleObject)]
struct Globals {
    version: String,
}

pub struct Query;

#[Object]
impl Query {
    async fn globals(&self) -> Result<Globals> {
        Ok(Globals {
            version: "0.0.0-development".to_string(),
        })
    }
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn globals2(&self) -> Result<Globals> {
        Ok(Globals {
            version: "0.0.0-development".to_string(),
        })
    }
}
