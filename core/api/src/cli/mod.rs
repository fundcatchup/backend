mod config;
mod db;

pub use config::Config;
use config::EnvOverride;

use clap::{Parser, Subcommand};

use std::path::PathBuf;

#[derive(Parser)]
#[clap(long_about = None)]
struct Cli {
    #[clap(subcommand)]
    command: Command,

    /// Directory for storing tokens + pid file
    #[clap(
        short,
        long,
        env = "API_HOME",
        default_value = ".api",
        value_name = "DIRECTORY"
    )]
    api_home: String,
}

#[derive(Subcommand)]
enum Command {
    /// Api Daemon
    Daemon {
        /// Configuration File
        #[clap(
            short,
            long,
            env = "API_CONFIG",
            default_value = "api.yml",
            value_name = "FILE"
        )]
        config_path: PathBuf,

        /// Database Configuration
        #[clap(env = "PG_CON")]
        pg_con: String,

        #[clap(subcommand)]
        command: DaemonCommand,
    },
}

#[derive(Subcommand)]
enum DaemonCommand {
    /// Runs:
    /// GraphQL API to do primary operations,
    Servers,
    /// Healthchecks connectivity to all services
    Healthcheck,
}

pub async fn run() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Command::Daemon {
            config_path,
            pg_con,
            command,
        } => {
            common::store_pid(cli.api_home)?;
            let config = Config::from_path(config_path, EnvOverride { db_con: pg_con })?;
            tracing::init_tracer(config.tracing)?;

            match command {
                DaemonCommand::Servers => {
                    let pool = db::init_pool(&config.db).await?;
                    let app = crate::app::ApiApp::new(pool, config.app);

                    crate::server::run(config.server, app).await
                }
                DaemonCommand::Healthcheck => {
                    db::init_pool(&config.db).await?;
                    Ok(())
                }
            }?;

            Ok(())
        }
    }
}
