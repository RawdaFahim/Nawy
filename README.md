# Nawy - DevOps Hiring Assignment

This repository demonstrates the full CI/CD workflow for a simple Node.js "Hello World" application. It includes containerization, automated GitHub Actions pipeline, infrastructure as code with Terraform to deploy code on the cloud.

---

## 📋 Task Overview

The objective of this task is to:

- Fork and containerize a sample Node.js web application.
- Set up a GitHub Actions CI/CD pipeline that:
  - Lints the code.
  - Builds a Docker image.
  - Pushes the image to Docker Hub.
- Deploy the application using Terraform (either locally or on a cloud provider).

---

## 📁 Project Structure

```bash
.
├── .github/workflows/         # GitHub Actions CI/CD pipeline definition
│   └── main.yml               # Workflow for linting, building, and pushing Docker image
├── node-hello/                # Source code of the Node.js application
│   ├── Dockerfile             # Dockerfile to containerize the app
│   ├── index.js               # Main entry point of the application
│   └── package.json           # Node.js dependencies and metadata
├── terraform/                 # Terraform files to deploy the Docker container
│   ├── main.tf                # Defines resources for Docker provider deployment
│   └── variables.tf           # Variables for deployment customization
├── .dockerignore              # Files to ignore during Docker build
├── .gitignore                 # Files to ignore in Git
└── README.md                  # Project documentation
```

# ✅ Prerequisites

Before you begin, ensure the following tools and accounts are set up:

- [Docker](https://www.docker.com/)
- A [GitHub](https://github.com/) account

---

# Initialize Submodule
Clone the submodule into your repo:
```bash
submodule init 
submodule update
```

---

# 🚀 Running the App Locally

```bash
# Navigate to the project directory
cd Nawy

# Build the Docker image
docker build -t nawy-hello-world .

# Run the container
docker run -p 3000:3000 nawy-hello-world
```
Access the application at [http://localhost:3000](http://localhost:3000)

---

# 🔧 Setting Up GitHub Actions

## Add Secrets to Your GitHub Repository

Go to:

**Settings → Secrets and Variables → Actions → New repository secret**

Create a new environment:
- nawy-env

Add the following secrets:

- `DOCKER_USERNAME` – Your Docker Hub username  
- `DOCKER_PASSWORD` – Your Docker Hub password or personal access token

## CI/CD Workflow

The GitHub Actions workflow is defined in:

.github/workflows/main.yml


It includes the following steps:

- Linting the code with ESLint  
- Building the Docker image  
- Logging in to Docker Hub  
- Pushing the image to Docker Hub  

---

# ☁️ Deploying with Terraform

This project uses the Terraform AWS provider to deploy on ECS.

## 🔐 AWS Credentials Setup

Ensure your AWS credentials are available in the environment where Terraform runs. You can configure them in one of the following ways:

### Option 1: Using Environment Variables

```bash
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key
export AWS_DEFAULT_REGION=us-east-1  # or your preferred region
```
### Option 2: Using the AWS Credentials File

Run the following command:

```bash
aws configure
```
This will store your credentials in `~/.aws/credentials`

## To run terraform

```bash
# Navigate to the Terraform directory
cd terraform

# Initialize the configuration
terraform init

# Preview changes
terraform plan

# Apply the deployment
terraform apply
```
To access the node app. Run the following command to get the public IP of the ECS service:
```bash
aws ecs list-tasks --cluster web-app-cluster
# Will output the task id

aws ecs describe-tasks --cluster web-app-cluster --tasks <task-id> | grep eni

aws ec2 describe-network-interfaces --network-interface-ids <eni-xxxxxxxxxxxx> | grep PublicIp

```

Access the app on the URL:
http://<Public-IP>:3000