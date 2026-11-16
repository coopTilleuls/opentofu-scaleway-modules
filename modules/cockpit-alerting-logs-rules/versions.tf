terraform {
  required_version = ">= 1.6.0"

  required_providers {
    loki = {
      source  = "fgouteroux/loki"
      version = "= 0.0.6" // DON'T UPGRADE THIS VERSION IF YOU HAVE NOT REVIEWED THE CODE, BECAUSE IT'S NOT AN OFFICIAL PROVIDER
    }
  }
}
