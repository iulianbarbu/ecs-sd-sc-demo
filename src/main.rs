//! Run with
//!
//! ```not_rust
//! cargo run
//! ```

use axum::{response::Html, routing::get, Router};

#[tokio::main]
async fn main() {
    // build our application with a route
    let app = Router::new()
        .route("/", get(handler))
        .route("/call2", get(handler_call2))
        .route("/call1", get(handler_call1));

    // run it
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    println!("listening on {}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}

async fn handler() -> Html<&'static str> {
    Html("<h1>Hello, World from ecs-sd-sc-demo!</h1>")
}

async fn handler_call2() -> Html<String> {
    let client = reqwest::Client::new();
    let req = client
        .get("http://service2.cluster.internal:3000/")
        .build()
        .unwrap();
    let resp = client.execute(req).await.unwrap();
    let body = resp.bytes().await.unwrap();
    Html(String::from_utf8(body.to_vec()).unwrap())
}

async fn handler_call1() -> Html<String> {
    let client = reqwest::Client::new();
    let req = client
        .get("http://service1.cluster.internal:3000/")
        .build()
        .unwrap();
    let resp = client.execute(req).await.unwrap();
    let body = resp.bytes().await.unwrap();
    Html(String::from_utf8(body.to_vec()).unwrap())
}
