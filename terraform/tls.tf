resource "tls_private_key" "talos_ca_private_key" {
  algorithm = "RSA"
}

resource "local_file" "talos_ca_key" {
  content  = tls_private_key.talos_ca_private_key.private_key_pem
  filename = "${path.module}/certs/talos-ca.key"
}

resource "tls_self_signed_cert" "talos_ca_cert" {
  private_key_pem   = tls_private_key.talos_ca_private_key.private_key_pem
  is_ca_certificate = true
  subject {
    country             = "RU"
    province            = "Moscow"
    locality            = "Moscow"
    common_name         = "Talos Root CA"
    organization        = "Talos"
    organizational_unit = "Talos"
  }

  validity_period_hours = 43800 // 5 years

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "talos_ca_cert" {
  content  = tls_self_signed_cert.talos_ca_cert.cert_pem
  filename = "${path.module}/certs/talos-ca.crt"
}
