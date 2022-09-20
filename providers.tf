terraform {
  cloud {
    organization = "code4romania"

    workspaces {
      tags = [
        "website-factory",
        "azure"
      ]
    }
  }
}
