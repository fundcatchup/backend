use serde::Deserialize;

#[derive(Clone, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct AppConfig {}
