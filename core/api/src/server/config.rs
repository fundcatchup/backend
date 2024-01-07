use serde::Deserialize;

#[derive(Clone, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ServerConfig {
    #[serde(default = "default_api_server_port")]
    pub api_server_port: u16,
}

fn default_api_server_port() -> u16 {
    4051
}
