use sqlx::Error as SqlxError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApplicationError {
    #[error("ApplicationError - SqlxError: {0}")]
    SqlxError(#[from] SqlxError),
    #[error("UnAuthenticated")]
    UnAuthenticated,
}
