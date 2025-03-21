# main.terraform

# 1. main.tf 파일을 생성하고, terraform backend 설정을 위한 코드를 작성합니다.
provider "aws" {
  region = "ap-northeast-2"
}

# 2. s3 버킷 생성 및 버전 관리 활성화
resource "aws_s3_bucket" "terraform_state" {
    bucket = "981128-roklee-practice5"
  
}

resource "aws_s3_bucket_versioning" "enalbed" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
  
}

# 3. s3 버킷에 SSE 서버 측 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
  
}

# 4. s3 버킷에 public access block 설정
# s3 bucket에 명시적 public access 비활성화 코드 작성 및 텍스트 에디터 종료
resource "aws_s3_bucket_public_access_block" "public_access_block" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets  = true
  
}

# 5. DynamoDB를 이용한 상태 파일 Lock 처리

resource "aws_dynamodb_table" "terraform_lock" {
    name           = "981128-roklee-practice5"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
}