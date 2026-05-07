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
        
        # Remove the modified DropdownMenuItem
        # It looks like:
        # const DropdownMenuItem(
        #   value: 'CY 2',
        #   child: Text("Select Area"),
        # ),
        # where 'CY 2' could be anything.
        content = re.sub(r'const\s*DropdownMenuItem\s*\(\s*value:\s*[\"\'][^\"\']+[\"\'],\s*child:\s*Text\([\"\']Select Area[\"\']\),\s*\),', '', content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Cleaned {filepath}')
