# ECS Nginx Demo

Tento projekt nasazuje `nginx:alpine` do AWS ECS Fargate pomocí Terraform a GitHub Actions.

## Architektura

- AWS default VPC (načtena přes `data` zdroj, nevytvářena)
- AWS Application Load Balancer (veřejný, port 80)
- AWS ECS Fargate Cluster s 1 běžícím taskem
- nginx:alpine – 256 CPU jednotek, 512 MB paměti
- Health check na `/`
- CloudWatch Logs (`/ecs/<project_name>`)
- Terraform state uložen v S3 bucketu

## Struktura projektu

```
.
├── main.tf                          # Infrastruktura (VPC data, ALB, ECS, IAM, CloudWatch)
├── variables.tf                     # Proměnné
├── outputs.tf                       # Výstupy (ALB DNS, URL)
├── terraform.tfvars                 # Hodnoty proměnných
└── .github/workflows/deploy.yml    # CI/CD pipeline
```

## Příprava před nasazením

### 1. Vytvořte S3 bucket pro Terraform state

Přes AWS Console → S3 → Create bucket (název musí být globálně unikátní):

```
tfstate-<číslo-aws-účtu>-eu-central-1
```

### 2. Upravte backend v `main.tf`

```hcl
backend "s3" {
  bucket = "tfstate-<číslo-aws-účtu>-eu-central-1"   # ← váš bucket
  key    = "ecs-demo/terraform.tfstate"
  region = "eu-central-1"
}
```

### 3. Nastavte GitHub Secrets

V repozitáři: **Settings → Secrets and variables → Actions → New repository secret**

| Secret                  | Hodnota                  |
|-------------------------|--------------------------|
| `AWS_ACCESS_KEY_ID`     | váš AWS access key ID    |
| `AWS_SECRET_ACCESS_KEY` | váš AWS secret key       |

## Nasazení lokálně

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## CI/CD pipeline (GitHub Actions)

Workflow v `.github/workflows/deploy.yml` se spustí automaticky:

| Událost          | Co se provede                                              |
|------------------|------------------------------------------------------------|
| Pull request     | `fmt` → `init` → `validate` → `plan` (výsledek v PR komentáři) |
| Push do `main`   | `fmt` → `init` → `validate` → `apply` → test dostupnosti  |

## Výstup po nasazení

```bash
terraform output load_balancer_url
# http://<alb-dns>.eu-central-1.elb.amazonaws.com
```

Nebo v logu GitHub Actions ve stepu **Get Load Balancer URL**.

## Test dostupnosti

```bash
curl http://<alb-dns-name>
```

Při úspěchu vrátí nginx uvítací stránku (HTTP 200).

## Debugging

```bash
# Stav ECS service
aws ecs describe-services \
  --cluster my-ecs-demo-cluster \
  --services my-ecs-demo-service \
  --region eu-central-1

# Výpis tasků v clusteru
aws ecs list-tasks \
  --cluster my-ecs-demo-cluster \
  --region eu-central-1

# CloudWatch logy
aws logs tail /ecs/my-ecs-demo --follow --region eu-central-1
```

## Vyčištění

```bash
terraform destroy -auto-approve
```

> **Poznámka:** S3 bucket pro Terraform state musíte smazat ručně přes AWS Console, protože Terraform ho nevytvářel.

## Aplikace URL

Po nasazení:

```
Load Balancer: http://<alb-dns>.eu-central-1.elb.amazonaws.com
```
