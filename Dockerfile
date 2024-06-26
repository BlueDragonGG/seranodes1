# This GitHub Action demonstrates building a Docker image,
# pushing it to Docker Hub, and creating a Render build
# preview with every push to the main branch.
#
# This Action requires setting the following secrets:
#
# - DOCKERHUB_USERNAME
# - DOCKERHUB_ACCESS_TOKEN (create in Docker Hub)
# - RENDER_API_KEY (create from the Account Settings page)
# - RENDER_SERVICE_ID (the service to create a preview for)
#
# You must also set env.DOCKERHUB_REPOSITORY_URL below.
#
# Remember to delete previews when you're done with them!
# You can do this from the Render Dashboard or via the
# Render API.

name: Preview Docker Image on Render

# Fires whenever commits are pushed to the main branch
# (including when a PR is merged)
on:
  push:
    branches: [ "main" ]

env:
  # Replace with the URL for your image's repository
  DOCKERHUB_REPOSITORY_URL: REPLACE_ME
jobs:

  build:

    runs-on: ubuntu-latest

    steps:
    - name: Check out the repo
      uses: actions/checkout@v3

    - name: Build the Docker image
      run: docker build . --file Dockerfile --tag $DOCKERHUB_REPOSITORY_URL:$(date +%s)

    - name: Log in to Docker Hub
      uses: docker/login-action@v2.2.0
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_ACCESS_TOKEN }}

    - name: Docker Metadata action
      uses: docker/metadata-action@v4.6.0
      id: meta
      with:
        images: ${{env.DOCKERHUB_REPOSITORY_URL}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4.1.1
      id: build
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

    - name: Create Render service preview
      uses: fjogeleit/http-request-action@v1
      with:
        # Render API endpoint for creating a service preview
        url: 'https://api.render.com/v1/services/${{ secrets.RENDER_SERVICE_ID }}/preview'
        method: 'POST'

        # All Render API requests require a valid API key.
        bearerToken: ${{ secrets.RENDER_API_KEY }}

        # Here we specify the digest of the image we just
        # built. You can alternatively provide the image's
        # tag (main) instead of a digest.
        data: '{"imagePath": "${{ env.DOCKERHUB_REPOSITORY_URL }}@${{ steps.build.outputs.digest }}"}'
