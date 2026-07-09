<!-- # Here's the complete flow with the missing pieces added. I've kept the examples simple so you can clearly see what is happening at each stage.

# ## Complete OIDC Authentication Flow (GitHub → AWS)

# ### 1. One-time configuration in AWS

# Before GitHub can access AWS, an administrator configures AWS by:

# * Creating an **OIDC Identity Provider** for GitHub (`https://token.actions.githubusercontent.com`).
# * Creating an **IAM role** (for example, `github-action-role`).
# * Adding a **trust policy** to the role that specifies which GitHub repository is allowed to assume it.

# Example trust policy:

# ```json
# {
#   "Effect": "Allow",
#   "Principal": {
#     "Federated": "arn:aws:iam::600627356450:oidc-provider/token.actions.githubusercontent.com"
#   },
#   "Action": "sts:AssumeRoleWithWebIdentity",
#   "Condition": {
#     "StringEquals": {
#       "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
#     },
#     "StringLike": {
#       "token.actions.githubusercontent.com:sub": "repo:emmanuel2500/my-portfolio:ref:refs/heads/main"
#     }
#   }
# }
# ```

# This tells AWS:

# > "Only workflows running from the **main** branch of the **emmanuel2500/my-portfolio** repository may assume this role."

# ---

# ### 2. GitHub starts the workflow

# When the GitHub Actions workflow starts, it has **no AWS credentials**.

# Instead, GitHub requests an **OIDC token** from GitHub's identity service.

# An OIDC token contains information similar to:

# ```text
# iss: https://token.actions.githubusercontent.com
# aud: sts.amazonaws.com
# sub: repo:emmanuel2500/my-portfolio:ref:refs/heads/main
# repository: emmanuel2500/my-portfolio
# actor: emmanuel2500
# workflow: Build and push to ECR
# exp: 1752000000
# ```

# This token is digitally signed by GitHub and proves the identity of the running workflow.

# ---

# ### 3. GitHub sends the OIDC token to AWS

# GitHub sends the token to AWS Security Token Service (STS) and requests:

# > "I'd like to assume the IAM role `github-action-role`."

# ---

# ### 4. AWS verifies the token

# AWS checks:

# * Is the token signed by GitHub?
# * Has the token expired?
# * Is the issuer (`iss`) GitHub?
# * Does the audience (`aud`) equal `sts.amazonaws.com`?
# * Does the repository (`sub`) match the trust policy?

# If every check succeeds, AWS trusts the workflow.

# ---

# ### 5. AWS issues temporary credentials

# AWS STS creates temporary credentials and returns them to GitHub.

# Example:

# ```text
# AWS_ACCESS_KEY_ID=ASIAQWERTY123456
# AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjE...
# Expiration=2026-07-08T22:30:00Z
# ```

# These credentials represent the permissions of the `github-action-role`.

# ---

# ### 6. GitHub uses the temporary credentials

# Now GitHub stores these credentials in the runner environment and uses them automatically for AWS API requests.

# For example, when the workflow executes:

# ```bash
# docker push 600627356450.dkr.ecr.us-east-1.amazonaws.com/my-portfolio:latest
# ```

# the ECR login action first authenticates Docker using those temporary AWS credentials.

# The flow is:

# ```text
# GitHub
#    │
#    │ Temporary AWS credentials
#    ▼
# Amazon ECR Login
#    │
#    ▼
# Docker is authenticated to ECR
#    │
#    ▼
# docker push image
# ```

# Without the temporary credentials, GitHub cannot log in to ECR.

# Without logging in to ECR, Docker cannot push images.

# ---

# ### 7. AWS authorizes every request

# Whenever GitHub sends an AWS API request, AWS checks:

# 1. Are the temporary credentials valid?
# 2. Have they expired?
# 3. Which IAM role issued them?
# 4. Does that role's permission policy allow the requested action?

# For example:

# * `ecr:GetAuthorizationToken`
# * `ecr:PutImage`
# * `ecs:UpdateService`

# If the IAM policy allows the action, AWS completes the request.

# If not, AWS returns **Access Denied**.

# ---

# ## Complete flow

# ```text
# AWS Setup (one time)
#     │
#     ├── Create GitHub OIDC Provider
#     ├── Create IAM Role
#     └── Configure Trust Policy

#             │

# GitHub Workflow Starts
#             │
#             ▼
# GitHub requests an OIDC token
#             │
#             ▼
# GitHub sends OIDC token to AWS STS
#             │
#             ▼
# AWS verifies the token and trust policy
#             │
#             ▼
# AWS issues temporary AWS credentials
#             │
#             ▼
# GitHub receives the credentials
#             │
#             ▼
# GitHub logs in to Amazon ECR using those credentials
#             │
#             ▼
# Docker becomes authenticated to ECR
#             │
#             ▼
# docker push image
#             │
#             ▼
# AWS checks IAM permissions
#             │
#             ▼
# Image is pushed successfully
# ```

# This shows the entire lifecycle: **AWS configuration → GitHub receives an OIDC token → AWS verifies it → STS issues temporary credentials → GitHub uses those credentials to log in to ECR → Docker pushes the image → AWS authorizes each request based on the IAM role's permissions.** -->
