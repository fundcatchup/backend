use serde::Deserialize;

#[derive(Clone, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ServerConfig {
    #[serde(default = "default_api_server_port")]
    pub api_server_port: u16,
    #[serde(default = "default_jwks_url")]
    pub jwks_url: String,
}

fn default_api_server_port() -> u16 {
    4051
}

fn default_jwks_url() -> String {
    "http://localhost:4456/.well-known/jwks.json".to_string()
}
