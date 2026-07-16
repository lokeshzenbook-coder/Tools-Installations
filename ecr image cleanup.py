#!/usr/bin/env python3

"""
AWS ECR Image Cleanup Script

Features:
- Cleans up old Docker images from ECR
- Keeps the latest N images
- Supports Dry Run mode
- Logs deleted images
- Handles multiple repositories

Author: DevSecOps Automation
"""

import boto3
import logging
from botocore.exceptions import ClientError

# ----------------------------
# Configuration
# ----------------------------

AWS_REGION = "us-east-1"

KEEP_IMAGES = 10

DRY_RUN = True

# ----------------------------
# Logging
# ----------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger(__name__)

# ----------------------------
# AWS Client
# ----------------------------

ecr = boto3.client(
    "ecr",
    region_name=AWS_REGION
)


def get_repositories():
    """Return all ECR repositories."""

    paginator = ecr.get_paginator("describe_repositories")

    repositories = []

    for page in paginator.paginate():

        repositories.extend(page["repositories"])

    return repositories


def cleanup_repository(repository_name):
    """Delete old images while keeping latest N images."""

    logger.info(f"Processing repository: {repository_name}")

    paginator = ecr.get_paginator("describe_images")

    images = []

    for page in paginator.paginate(
            repositoryName=repository_name):

        images.extend(page["imageDetails"])

    if len(images) <= KEEP_IMAGES:

        logger.info(
            f"Repository '{repository_name}' has only "
            f"{len(images)} images. Skipping."
        )

        return

    images.sort(
        key=lambda x: x["imagePushedAt"],
        reverse=True
    )

    images_to_delete = images[KEEP_IMAGES:]

    logger.info(
        f"Deleting {len(images_to_delete)} images..."
    )

    for image in images_to_delete:

        image_digest = image["imageDigest"]

        try:

            if DRY_RUN:

                logger.info(
                    f"[Dry Run] Would delete {image_digest}"
                )

            else:

                ecr.batch_delete_image(

                    repositoryName=repository_name,

                    imageIds=[
                        {
                            "imageDigest": image_digest
                        }
                    ]
                )

                logger.info(
                    f"Deleted {image_digest}"
                )

        except ClientError as error:

            logger.error(error)


def main():

    repositories = get_repositories()

    logger.info(
        f"Found {len(repositories)} repositories"
    )

    for repo in repositories:

        cleanup_repository(
            repo["repositoryName"]
        )


if __name__ == "__main__":

    main()
