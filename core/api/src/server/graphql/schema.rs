use crate::primitives::*;
use async_graphql::*;

#[derive(SimpleObject)]
struct Globals {
    version: String,
}

pub struct Query;

#[Object]
impl Query {
    async fn whoami(&self, ctx: &Context<'_>) -> Option<String> {
        let user_id = ctx.data_unchecked::<Option<UserId>>();

        match user_id {
            Some(user_id) => Some(user_id.to_string()),
            _ => None,
        }
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
