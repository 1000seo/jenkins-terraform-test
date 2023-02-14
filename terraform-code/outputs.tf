# --- root/outputs.tf ---

output "terraform-test" {
    value       = module.networking
}

output "instance"{
    value       = module.compute
}