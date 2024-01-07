mod config;
pub use config::AppConfig;

use sqlx::{Pool, Postgres};

#[derive(Clone)]
pub struct ApiApp {
    pub pool: Pool<Postgres>,
    #[allow(dead_code)]
    config: AppConfig,
}

impl ApiApp {
    pub fn new(pool: Pool<Postgres>, config: AppConfig) -> Self {
        ApiApp { pool, config }
    }
}
