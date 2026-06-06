output "instance_public_ip" {
  value = oci_core_instance.app.public_ip
}

output "instance_id" {
  value = oci_core_instance.app.id
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/knup_oci ubuntu@${oci_core_instance.app.public_ip}"
}

output "frontend_public_ip" {
  value = oci_core_instance.frontend.public_ip
}

output "frontend_ssh_command" {
  value = "ssh -i ~/.ssh/knup_oci ubuntu@${oci_core_instance.frontend.public_ip}"
}
