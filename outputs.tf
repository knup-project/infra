output "instance_public_ip" {
  value = oci_core_instance.app.public_ip
}

output "instance_id" {
  value = oci_core_instance.app.id
}

output "atp_id" {
  value = oci_database_autonomous_database.knup.id
}

output "atp_connection_urls" {
  value = oci_database_autonomous_database.knup.connection_urls
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_ed25519 ubuntu@${oci_core_instance.app.public_ip}"
}
