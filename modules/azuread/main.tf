resource "azuread_application" "first_project" {
  display_name = "first_project"
}

resource "azuread_service_principal" "user_1" {
  client_id = azuread_application.first_project.client_id
}

resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.user_1.id
  end_date             = "2025-06-30T23:59:59Z"
}

output "client_id" {
  value = azuread_application.first_project.client_id
}

output "client_secret" {
  value     = azuread_service_principal_password.password.value
  sensitive = true
}

