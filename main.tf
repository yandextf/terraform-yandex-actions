data "yandex_compute_image" "runner" {
  name = var.image
}

resource "yandex_compute_instance_group" "vms" {
  name               = var.name
  service_account_id = var.service_account

  instance_template {
    name        = "runner-{instance.zone}-{instance.index}"
    hostname    = "runner-{instance.zone}-{instance.index}"
    platform_id = var.platform_id

    resources {
      cores         = var.cpu
      core_fraction = var.core_fraction
      memory        = var.mem
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.runner.id
        size     = var.disk_size
        type     = var.disk_type
      }
    }

    network_interface {
      subnet_ids = var.subnets
    }

    labels = {
      name = var.name
      env  = var.folder
    }

    metadata = {
      user-data = templatefile("docker-compose.yml", {
        github_url    = var.github_url
        github_token  = var.github_token
        github_labels = var.github_labels
      })
      ssh-keys = var.ssh_key
    }

    network_settings {
      type = "STANDARD"
    }

    scheduling_policy {
      preemptible = true
    }
  }

  allocation_policy {
    zones = var.zones
  }

  scale_policy {
    fixed_scale {
      size = var.group_size
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }
}