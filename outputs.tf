output "client_id" {
  value = module.azuread.client_id
}

output "client_secret" {
  value     = module.azuread.client_secret
  sensitive = true
}

output "vm_public_ip" {
  value = module.vm.vm_public_ip
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}