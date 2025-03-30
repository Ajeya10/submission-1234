# AWS Cost Optimization Toolkit 🚀

![AWS Cost Optimization](https://img.shields.io/badge/AWS-Cost_Optimization-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure_Code-blue?logo=terraform)
![Python](https://img.shields.io/badge/Python-Lambda_Functions-green?logo=python)
![License](https://img.shields.io/badge/License-MIT-green)

A comprehensive solution to reduce AWS costs through automated resource cleanup, tagging enforcement, and cost visibility.

## 📦 Projects Overview

### 1. **Orphaned EBS Volume Cleanup** 🔍
**Technology**: AWS Lambda (Python) + IAM  
**Purpose**: Automatically identifies and deletes unattached EBS volumes and their snapshots  
**Key Features**:
- Checks volume attachment status daily
- Validates snapshots before deletion
- Maintains audit trail of deleted resources
- Whitelisting capability for protected resources

### 2. **Tag Enforcement Policy** 🏷️
**Technology**: Terraform + AWS Config  
**Purpose**: Enforces mandatory tagging compliance across all AWS resources  
**Key Features**:
- Requires `Owner`, `CostCenter`, `Environment` tags
- Auto-remediates non-compliant resources
- Integrates with AWS Organizations
- Email notifications for non-compliant resources

### 3. **Cost Visibility Pipeline** 📊
**Technology**: AWS CUR + Athena + Terraform  
**Purpose**: Provides granular cost analysis and reporting  
**Key Features**:
- Daily Parquet-formatted CUR reports
- Athena SQL interface for cost queries
- Automated S3 storage lifecycle
- Pre-built Grafana dashboards

## 🛠️ Architecture

```mermaid
graph LR
    A[CUR_AWS_Cost_&_Usage_Report] -->|CSV/Parquet| B[S3_Bucket]
    B --> C[Athena]
    D[Tag Policy] --> E[All AWS Resources]
    F[Lambda] --> G[EC2/EBS Cleanup]
    G --> H[Slack Alerts]
