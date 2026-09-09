# terraform-aws-infra

Module-based Terraform project: VPC networking, security groups, and an
ALB + Auto Scaling Group running a backend service on EC2, split into
`dev` and `prod` environments, deployed via GitHub Actions using OIDC
(no long-lived AWS access keys anywhere).

## Structure

```
modules/
  networking/   VPC, public+private subnets across AZs, IGW, NAT gateway(s), route tables
  security/     ALB SG (open to internet) -> EC2 SG (only open to ALB SG) - security group chaining
  compute/      ALB, target group, launch template, ASG. user_data.sh.tpl pulls + runs the backend Docker image
envs/
  dev/          Calls the 3 modules with dev-sized values. Own state file, own tfvars.
  prod/         Same module calls, prod-sized values (bigger instances, HA NAT, more state file isolation)
.github/workflows/terraform.yml   CI/CD pipeline
```

Each env directory is a **separate root module with its own state** — this is
deliberate. Sharing one state file across dev and prod means a mistake in dev
can touch prod's real resources. Same `.tf` logic, different `terraform.tfvars`
and a different state `key`.

## 1. One-time setup: remote state backend

Terraform state should never live only on a laptop or in git. Create these
once, manually (only need to do this once ever, not per-env):

```bash
aws s3api create-bucket --bucket YOUR-terraform-state-bucket --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket YOUR-terraform-state-bucket \
  --versioning-configuration Status=Enabled

aws dynamodb create-table --table-name YOUR-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then replace `REPLACE-ME-terraform-state-bucket` and `REPLACE-ME-terraform-locks`
in `envs/dev/providers.tf` and `envs/prod/providers.tf` with your real names.

## 2. One-time setup: GitHub OIDC auth to AWS (no access keys)

This is the modern, secure way to let GitHub Actions authenticate to AWS —
GitHub issues a short-lived signed token per workflow run, and AWS trusts it
directly. No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets exist anywhere.

**Step A — create the OIDC identity provider in AWS (once per account):**

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Step B — create an IAM role GitHub Actions can assume.**
Trust policy (`trust-policy.json`) — restrict `sub` to your exact repo and
branch, don't leave it wide open:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-GH-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

```bash
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document file://trust-policy.json

# Attach a policy scoped to what Terraform actually needs to manage
# (VPC, EC2, ELB, IAM-for-instance-profiles, ASG, etc.) - avoid AdministratorAccess.
aws iam attach-role-policy \
  --role-name github-actions-terraform \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/YourScopedTerraformPolicy
```

**Step C — add the role ARN as a GitHub secret:**

Repo → Settings → Secrets and variables → Actions → New repository secret:
- Name: `AWS_GHA_ROLE_ARN`
- Value: `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform`

That's the only secret the pipeline needs.

**Step D (recommended) — protect `prod` with manual approval.**
Repo → Settings → Environments → create an environment named `prod` → add
yourself as a required reviewer. The workflow's `apply` job already references
`environment: ${{ matrix.env }}`, so pushes to `main` will pause for approval
before touching prod.

## 3. Running locally (before pushing, or for a first manual run)

```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

Same for `envs/prod`. Always run `plan` and read it — never `apply` blind,
especially on prod.

## 4. How the pipeline behaves

- **Pull request** touching `modules/**` or `envs/**` → runs `fmt -check`,
  `validate`, and `plan` for both dev and prod, posts the plan as a PR comment.
  Nothing is applied yet — this is your review step.
- **Merge to `main`** → runs `apply` for dev, then prod (`max-parallel: 1`, dev
  always goes first). Prod pauses for manual approval if you set up the
  GitHub Environment protection rule above.

## 5. Backend service image

`docker_image` in each env's `terraform.tfvars` points at whatever registry
you publish to (ECR, GHCR, Docker Hub). Update the value and re-run
`terraform apply` (or bump the ASG's launch template) to roll out a new
version. For a real blue/green rollout, look at swapping this ASG-based
approach for **CodeDeploy** or an **ASG instance refresh** — a natural next
step once this baseline is working, and directly relevant to DOP-C02's
deployment strategies domain.

## Notes / things to adjust before using this for real

- No SSH access is opened by default (`ssh_allowed_cidrs = []`) — use **AWS
  Systems Manager Session Manager** to shell into instances instead of
  opening port 22. Attach the `AmazonSSMManagedInstanceCore` policy to the
  EC2 instance profile if you need this (not yet wired into the compute
  module — add an `aws_iam_instance_profile` + `iam_instance_profile` on the
  launch template).
- The IAM policy attached to `github-actions-terraform` should be scoped to
  exactly the services this project touches, not `AdministratorAccess`.
- `docker_image` defaults to a placeholder — point it at your real registry.
