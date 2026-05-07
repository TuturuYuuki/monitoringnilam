import os
import re

directories = ['lib/pages/cctv', 'lib/pages/mmt', 'lib/pages/network']
mapping = {
    'cctv.dart': 'CY 1',
    'cctv_cy2.dart': 'CY 2',
    'cctv_cy3.dart': 'CY 3',
    'cctv_gate.dart': 'GATE',
    'cctv_parking.dart': 'PARKING',
    'mmt_monitoring.dart': 'CY 1',
    'mmt_monitoring_cy2.dart': 'CY 2',
    'mmt_monitoring_cy3.dart': 'CY 3',
    'mmt_monitoring_gate.dart': 'GATE',
    'mmt_monitoring_parking.dart': 'PARKING',
    'network.dart': 'CY 1',
    'network_cy2.dart': 'CY 2',
    'network_cy3.dart': 'CY 3',
    'network_gate.dart': 'GATE',
    'network_parking.dart': 'PARKING',
}

for root in directories:
    if not os.path.exists(root): continue
    for file in os.listdir(root):
        if file in mapping:
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            expected_val = mapping[file]
            
            content = re.sub(r'value:\s*[\"\']Select Area[\"\']', f"value: '{expected_val}'", content)
            
            content = re.sub(r'const\s*DropdownMenuItem\s*\(\s*value:\s*[\"\']Select Area[\"\'],\s*child:\s*Text\([\"\']Select Area[\"\']\),\s*\),', '', content)
            
            content = re.sub(r'if\s*\([^)]*newValue\s*==\s*[\"\']Select Area[\"\'][^)]*\)\s*return;', 'if (newValue == null) return;', content)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Updated {filepath}')
