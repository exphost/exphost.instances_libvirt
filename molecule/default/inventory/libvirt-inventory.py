#!/usr/bin/env python
### conf section
URI = 'qemu:///system'
NAME_FILTER = 'placeholder'
STATE_MASK = None
STATE_MASK = [0,1,2,3,4,5,6,7,8]
#NAME_FILTER = '^exphost-.*'

import libvirt
import re
import json
import yaml
import os
import sys
with open("/tmp/tak.txt", "w") as f:
    f.write("DATA")

with open(os.path.join(os.path.dirname(sys.argv[0]), "group_vars/all/iac.yml"), "r") as f:
    iac = yaml.safe_load(f)
    NAME_FILTER = '^{name}-.*'.format(name=iac['iac']['name'])



name_filter_re = re.compile(NAME_FILTER)

conn = libvirt.open(URI)

inventory = {}
inventory['all'] = {'hosts': []}

for domain in conn.listAllDomains():

    if not name_filter_re.match(domain.name()):
        continue
    if STATE_MASK and not domain.state()[0] in STATE_MASK:
        continue

    inventory['all']['hosts'].append(domain.name())

    try:
        addresses = domain.interfaceAddresses(1)
        ### Take the eth0 interface
        ip_address = addresses['eth0']['addrs'][0]['addr']
        if "_meta" not in inventory:
            inventory['_meta'] = {'hostvars': {}}
        if domain not in inventory['_meta']['hostvars']:
            inventory["_meta"]['hostvars'][domain.name()] = {}
        inventory['_meta']['hostvars'][domain.name()]['ansible_host'] = ip_address
    except libvirt.libvirtError:
        pass

    try:
        metadata = domain.metadata(type=0, uri=None)
        for desc_line in metadata.split("\n"):
            if desc_line.startswith("roles: "):
                roles = desc_line.split("roles:")[1].strip().split(",")
                for role in roles:
                    if role not in inventory:
                        inventory[role] = {'hosts': []}
                    inventory[role]['hosts'].append(domain.name())

    except libvirt.libvirtError:
        pass
print(json.dumps(inventory, indent=4, sort_keys=True))
