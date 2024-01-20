use std::str::FromStr;

use axum::{extract::State, http::Request, middleware::Next, response::Response};
use jsonwebtoken::{decode, DecodingKey, Validation};
use reqwest::header;
use serde::Deserialize;

use super::ServerConfig;
use crate::primitives::*;

// `sub` field for anonymous entity that we get from Oathkeeper
const ANONYMOUS: &str = "anonymous";

#[derive(Deserialize)]
struct Jwks {
    keys: Vec<Jwk>,
}

#[derive(Deserialize)]
struct Jwk {
    alg: String,
    n: String,
    e: String,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct Claims {
    sub: String,
    exp: usize,
    iat: usize,
}

pub async fn extract_user_id<B>(
    config: State<ServerConfig>,
    req: Request<B>,
    next: Next<B>,
) -> Response {
    let authorization_header = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok());

    let mut user: Option<UserId> = None;

    if let Some(authorization_header) = authorization_header {
        let authorization_header = authorization_header.to_string();
        let (_, token) = authorization_header.split_at(7); // Authorzation: (Bearer )xxxx; () length is 7.

        let jwks: Jwks = reqwest::get(&config.jwks_url)
            .await
            .unwrap()
            .json()
            .await
            .unwrap();

        // The first private key found in the JSON Web Key Set would have been used by Oathkeeper
        let jwk = &jwks.keys[0];

        // Create a decoding key
        let decoding_key = DecodingKey::from_rsa_components(&jwk.n, &jwk.e).unwrap();

        // Decode JWT
        let validation = Validation::new(jwk.alg.parse().unwrap());
        let token_data = decode::<Claims>(token, &decoding_key, &validation);
        match token_data {
            Ok(data) => {
                let sub = data.claims.sub;
                if sub != ANONYMOUS {
                    user = Some(UserId::from_str(&sub).expect("couldn't parse user"))
                }
            }
            _ => {}
        }
    }

    let (mut parts, body) = req.into_parts();

    parts.extensions.insert(user);

    let req = Request::from_parts(parts, body);
    let resp = next.run(req).await;
    resp
}
