# Jenkins CI/CD Pipeline Runbook

This project implements a fully dynamic CI/CD pipeline for a Node.js Express application. All configurations and credentials are managed via parameters and secure credential bindings.

## Prerequisites

1.  **Jenkins Server**: Installed with Pipeline, Git, Credentials Binding, Docker Pipeline, and SSH Agent plugins.
2.  **Docker**: Installed on Jenkins and configured for the `jenkins` user.
3.  **AWS EC2**: Provisioned using the provided Terraform module.
4.  **Docker Hub**: Account and repository created.

## Setup Instructions

### 1. Infrastructure Provisioning (Terraform)

1.  `cd terraform`
2.  Update `terraform.tfvars` with your settings (Region, Instance Type, Key Name).
3.  `terraform init && terraform apply -auto-approve`
4.  Note the `web_server_public_ip`.

### 2. Jenkins Credentials

You must create the following credentials in Jenkins (**Manage Jenkins** -> **Manage Credentials**):

*   **registry_creds**: Kind "Username with password" (Docker Hub credentials).
*   **ec2_ssh**: Kind "SSH Username with private key" (Username: `ec2-user`, Private Key: your `updated` key found in Downloads).

### 3. Local Jenkins with ngrok (Optional)

If running Jenkins on `localhost:8080`, use ngrok to enable GitHub Webhooks:

1.  Run `ngrok http 8080`.
2.  Update **Jenkins URL** in System Settings with the ngrok address.
3.  Add a Webhook in GitHub: `https://<ngrok-id>.ngrok-free.app/github-webhook/`.

### 4. Pipeline Configuration

1.  Create a **Pipeline** job in Jenkins.
2.  Select "This project is parameterized" and add the following String Parameters:
    *   `DOCKER_HUB_USER`: Your Docker Hub username.
    *   `DOCKER_HUB_REPO`: Your repository name.
    *   `EC2_PUBLIC_IP`: `13.60.151.71` (Static Elastic IP)
    *   `APP_VERSION`: The version tag for the image (e.g., `1.0.0`).
4.  Enable **GitHub hook trigger for GITScm polling** under Build Triggers.
5.  Select **Pipeline script from SCM** (Git) and set the **Script Path** to `Jenkinsfile`.

## Pipeline Best Practices Implemented

*   **Credential Masking**: Using `credentials()` and `sshagent` ensures secrets are never leaked in logs.
*   **Zero Hardcoding**: Every variable is configurable via Jenkins parameters.
*   **Build Hooks**: `options` block includes `buildDiscarder` and `timestamps` for better log management.
*   **Clean Workspace**: Uses `cleanWs()` in the `post` block to save disk space on Jenkins agents.
*   **Build Arguments**: Docker image is built with dynamic arguments for versioning.

## Verification

Access the application via the static Elastic IP:

`http://13.60.151.71/`

You should see:

```json
{
  "message": "Deployment successful via Jenkins Best Practices Pipeline!",
  "version": "1.0.0"
}
```

## Cleanup

*   **Containers**: Handled automatically on EC2 after each deployment.
*   **Infrastructure**: Run `terraform destroy -auto-approve` inside the `terraform/` directory.
