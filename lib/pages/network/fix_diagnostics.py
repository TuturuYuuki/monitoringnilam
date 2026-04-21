import os
import re

files = {
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_cy2.dart': 'NetworkCY2Page',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_cy3.dart': 'NetworkCY3Page',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_gate.dart': 'NetworkGatePage',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_parking.dart': 'NetworkParkingPage'
}

for filepath, classname in files.items():
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix constructor
    content = content.replace('const NetworkPage({super.key});', f'const {classname}({{super.key}});')
    
    # Fix withOpacity
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    
    # Fix usage of context across async gaps (simple search/replace for snackbars/dialogs)
    # This is trickier to automate perfectly but we can add context.mounted checks where possible
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed {filepath}")

# Fix main.dart
main_path = r'd:\db\htdocs\monitoringnilam\lib\main.dart'
if os.path.exists(main_path):
    with open(main_path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    with open(main_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed {main_path}")
