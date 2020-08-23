use lambda::{handler_fn, Context};
use serde_json::Value;
use std::env;
use rusoto_cloudfront::{CloudFrontClient, CreateInvalidationRequest, InvalidationBatch, Paths, CloudFront};
use rusoto_core::Region;
use uuid::Uuid;

type Error = Box<dyn std::error::Error + Send + Sync + 'static>;

#[tokio::main]
async fn main() -> Result<(), Error> {
    lambda::run(handler_fn(process)).await?;
    Ok(())
}

async fn process(_event: Value, _: Context) -> Result<(), Error> {
    let distribution_id = match get_distribution_id() {
        Err(e) => return Err(e),
        Ok(id) => id
    };

    match invalidate(&distribution_id).await {
        Err(e) => Err(e),
        Ok(_) => Ok(())
    }
}

fn get_distribution_id() -> Result<String, Error> {
    match env::var("DISTRIBUTION_ID") {
        Ok(id) => Ok(id),
        Err(e) => Err(Error::from(e))
    }
}

async fn invalidate(distribution_id: &String) -> Result<(), Error> {
    let client = CloudFrontClient::new(Region::default());

    let input = CreateInvalidationRequest {
        distribution_id: distribution_id.clone(),
        invalidation_batch: InvalidationBatch {
            caller_reference: Uuid::new_v4().to_string(),
            paths: Paths {
                quantity: 1,
                items: Some(vec!["/*".to_string()])
            }
        }
    };

    match client.create_invalidation(input).await {
        Err(e) => Err(Error::from(e)),
        Ok(_) => Ok(())
    }
}
