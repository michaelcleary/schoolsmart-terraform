terraform {
  backend "s3" {
    bucket         = "schoolsmart-terraform-config"
    key            = "schoolsmart-website.tfstate"   # Adjust the path as needed
    region         = "eu-west-2"                   # Your bucket's region
    encrypt        = true                          # State file encryption
  }
}
