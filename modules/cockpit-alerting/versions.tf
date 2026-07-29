terraform {
  required_version = ">= 1.6.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.79.0, < 3.0.0"
    }
    mimir = {
      source  = "fgouteroux/mimir"
      version = "= 0.2.4" // DON'T UPGRADE THIS VERSION IF YOU HAVE NOT REVIEWED THE CODE, BECAUSE IT'S NOT AN OFFICIAL PROVIDER
    }
  }
}
