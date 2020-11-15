provider "libvirt" {
    uri = "qemu:///system"
}
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
}

{%   endfor %}

resource "libvirt_domain" "{{iac.name}}-{{instance.key}}-{{count}}" {
    name = "{{iac.name}}-{{instance.key}}-{{count}}"
    description = "roles: {{instance.value.roles|join(',')}}\ncluster: {{iac.name}}"
    vcpu = {{instance_types[instance.value.type].cpu}}
    memory = {{instance_types[instance.value.type].memory}}

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
