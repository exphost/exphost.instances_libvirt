provider "libvirt" {
    uri = "{{ lookup('env', 'QEMU_URI') | default( instance.value.provider.configs.uri | default('qemu:///system', true) , true) }}"
}
terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

{% if instance.value.user_data|default(False) %}
resource "libvirt_cloudinit_disk" "cloudinit-{{iac.name}}-{{instance.key}}" {
  name           = "cloundinit-{{iac.name}}-{{instance.key}}.iso"
  user_data      = <<EOF
#cloud-config
{{instance.value.user_data|default('')|to_nice_yaml(indent=2)}}
EOF
  pool = "{{instance.value.disks[0].pool}}"
}
{% endif %}

{% for count in range(instance.value.count) %}
{%   for disk in instance.value.disks|default([]) %}
resource "libvirt_volume" "volume_{{iac.name}}-{{instance.key}}-{{count}}-{{disk.name}}" {
    name = "volume_{{iac.name}}-{{instance.key}}-{{count}}-{{disk.name}}"
    pool = "{{disk.pool}}"
{%  if disk.base_name|default(False) %}
    base_volume_name = "{{disk.base_name}}"
{%  elif disk.source|default(False) %}
    source = "{{disk.source}}"
{%  endif %}

{%  if disk.size | default(False) %}
    size = "{{ disk.size|human_to_bytes }}"
{%  endif %}
}

{%   endfor %}

resource "libvirt_domain" "{{iac.name}}-{{instance.key}}-{{count}}" {
    name = "{{iac.name}}-{{instance.key}}-{{count}}"
    description = "roles: {{instance.value.roles|join(',')}}\ncluster: {{iac.name}}\nhostname: {{instance.key}}-{{count}}"
    vcpu = {{instance_types[instance.value.type].cpu}}
    memory = {{instance_types[instance.value.type].memory}}

    cpu = {
      mode = "host-passthrough" 
    }

{% if instance.value.user_data|default(False) %}
    cloudinit = libvirt_cloudinit_disk.cloudinit-{{iac.name}}-{{instance.key}}.id
{%  endif %}

{%    for disk in instance.value.disks|default([]) %}
    disk {
        volume_id = libvirt_volume.volume_{{iac.name}}-{{instance.key}}-{{count}}-{{disk.name}}.id
        scsi      = "true"
    }
{%   endfor %}
{%   for network in instance.value.networks|default([]) %}
    network_interface {
{%     if network.name|default(false) %}
        network_name = "{{network.name}}"
{%     endif %}
{%     if network.bridge|default(false) %}
        bridge = "{{network.bridge}}"
{%     endif %}
{%     if network.mac_addresses|default(false) %}
{%       if count < network.mac_addresses|length %}
        mac            = "{{network.mac_addresses[count]}}"
{%       endif %}
{%     elif network.mac_addresses_mask|default(false) %}
        mac            = "{{network.mac_addresses_mask }}
{%-       for octet in range(((17 - network.mac_addresses_mask|length ) /3)|int, 0, -1) -%}
         :{{'%02d'|format((count-network.mac_addresses|default([])|length)%(256**(octet))//(256**(octet-1)))}}
{%-       endfor -%}"
{%     endif %}
    }
{%   endfor %}

    xml {
        xslt = file("qemu.xslt")
    }
}
{% endfor %}
