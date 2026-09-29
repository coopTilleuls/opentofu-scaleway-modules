terraform {
  required_version = ">= 1.6.0"

  required_providers {
    mimir = {
      source  = "fgouteroux/mimir"
      version = "= 0.2.4" // DON'T UPGRADE THIS VERSION IF YOU HAVE NOT REVIEWED THE CODE, BECAUSE IT'S NOT AN OFFICIAL PROVIDER
    }
  }
}
