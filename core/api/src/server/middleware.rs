use std::str::FromStr;

use axum::{http::Request, middleware::Next, response::Response};

use crate::primitives::UserId;

pub async fn extract_user_id<B>(req: Request<B>, next: Next<B>) -> Response {
    let headers = req.headers();
    println!("{:?}", headers);

    let (mut parts, body) = req.into_parts();

    let req = Request::from_parts(parts, body);
    let resp = next.run(req).await;
    resp
}
