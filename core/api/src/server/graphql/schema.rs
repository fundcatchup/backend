use async_graphql::*;

use crate::{
    app::ApiApp,
    error::ApplicationError,
    group::{Group, NewGroup},
    primitives::*,
};

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
    async fn create_group(&self, ctx: &Context<'_>, new_group: NewGroup) -> Result<Group> {
        let user_id = ctx.data_unchecked::<Option<UserId>>();
        let app = ctx.data_unchecked::<ApiApp>();

        if let Some(user_id) = user_id {
            let group = app.create_group(*user_id, new_group).await?;
            return Ok(group);
        }

        Err(ApplicationError::UnAuthenticated.into())
    }
}
