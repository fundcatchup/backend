#![cfg_attr(feature = "fail-on-warnings", deny(warnings))]
#![cfg_attr(feature = "fail-on-warnings", deny(clippy::all))]

pub mod cli;
pub use server::schema;

mod app;
mod group;
mod server;

mod error;
mod primitives;
