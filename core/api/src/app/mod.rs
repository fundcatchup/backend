mod config;
pub use config::AppConfig;

use sqlx::{Pool, Postgres};

use crate::{
    group::{Group, Groups, NewGroup},
    primitives::*,
};

#[derive(Clone)]
pub struct ApiApp {
    pub pool: Pool<Postgres>,
    #[allow(dead_code)]
    config: AppConfig,

    groups: Groups,
}

impl ApiApp {
    pub fn new(pool: Pool<Postgres>, config: AppConfig) -> Self {
        ApiApp {
            groups: Groups::new(pool.clone()),

            pool: pool.clone(),
            config,
        }
    }

    pub async fn create_group(
        &self,
        user: UserId,
        mut new_group: NewGroup,
    ) -> anyhow::Result<Group> {
        // Ensure user creating the group is a member of that group
        new_group.members.insert(user);

        self.groups.create(new_group).await
    }
}
