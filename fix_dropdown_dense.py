import os
import re

directories = ['lib/pages/cctv', 'lib/pages/mmt', 'lib/pages/network']
for root in directories:
    if not os.path.exists(root): continue
    for file in os.listdir(root):
        filepath = os.path.join(root, file)
        if not filepath.endswith('.dart'): continue
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace:
        #           isExpanded: true,
        # with:
        #           isExpanded: true,
        #           isDense: true,
        # Only in the DropdownButton<String> widget!
        
        content = re.sub(r'isExpanded:\s*true,\s*dropdownColor:', 'isExpanded: true,\n          isDense: true,\n          dropdownColor:', content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Added isDense: true to {filepath}')
