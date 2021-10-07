/**
 * Copyright 2021 SchedMD LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "cluster_name" {
  description = "Cluster name"
  value       = module.slurm_cluster.cluster_name
}

output "config" {
  description = "Cluster configuration details"
  value       = module.slurm_cluster.config
  sensitive   = true
}

output "vpc" {
  description = "vpc details"
  value       = module.slurm_cluster.vpc
}

output "controller_template" {
  description = "Controller template details"
  value       = module.slurm_cluster.controller_template
}

output "login_template" {
  description = "Login template details"
  value       = module.slurm_cluster.login_template
}

output "compute_templates" {
  description = "Compute template details"
  value       = module.slurm_cluster.compute_template
}
