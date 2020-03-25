import json
import yaml

with open('mirage.flatpak.base.yaml') as f:
    base = yaml.load(f, Loader=yaml.FullLoader)

with open('flatpak-pip.json') as f:
    modules = json.load(f)['modules']

# set some modules in front as dependencies and dropping matrix-nio
# which is declared separately
front = []
back = []
for m in modules:
    n = m['name']
    if n.startswith('python3-') and \
       n[len('python3-'):] in ['multidict', 'cffi', 'pytest-runner', 'setuptools-scm']:
        front.append(m)
    else:
        back.append(m)

# replace placeholder with modules
phold = None
for i in range(len(base['modules'])):
    if base['modules'][i]['name'] == 'PLACEHOLDER PYTHON DEPENDENCIES':
        phold = i
        break

base['modules'] = base['modules'][:i] + front + back + base['modules'][i+1:]

with open('mirage.flatpak.yaml', 'w') as f:
    f.write(yaml.dump(base, sort_keys=False, indent=2))
    #json.dump(base, f, indent=4)
