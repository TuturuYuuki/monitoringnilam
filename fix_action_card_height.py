import os
import re

directories = [
    'lib/pages/cctv',
    'lib/pages/mmt',
    'lib/pages/network'
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if '_buildActionCard' not in content:
        return

    new_content = re.sub(
        r'height:\s*isMobile\s*\?\s*65\s*:\s*75,',
        r'constraints: BoxConstraints(minHeight: isMobile ? 65 : 75),',
        content
    )

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Fixed: {filepath}')

for d in directories:
    if os.path.exists(d):
        for root, dirs, files in os.walk(d):
            for file in files:
                if file.endswith('.dart'):
                    process_file(os.path.join(root, file))
