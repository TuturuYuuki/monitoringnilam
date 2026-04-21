import os
import re

network_files = [
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_cy2.dart',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_cy3.dart',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_gate.dart',
    r'd:\db\htdocs\monitoringnilam\lib\pages\network\network_parking.dart'
]

for filepath in network_files:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Fix dropdown value -> initialValue
    content = content.replace('value: selectedLocation,', 'initialValue: selectedLocation,')
    
    # 2. Add mounted check before showDialog in _showEditForm
    content = content.replace('var selectedYard = matchedOption?[\'container_yard\'] ?? tower.containerYard;\n    showDialog(', 
                              'var selectedYard = matchedOption?[\'container_yard\'] ?? tower.containerYard;\n    if (!mounted) return;\n    showDialog(')
    
    # 3. Fix context.mounted checks
    content = content.replace('if (!mounted) return;\n                  Navigator.pop(context);', 
                              'if (!context.mounted) return;\n                  Navigator.pop(context);')
    content = content.replace('if (!mounted) return;\n                Navigator.pop(context);', 
                              'if (!context.mounted) return;\n                Navigator.pop(context);')

    # 4. Remove extra closing brace at the end
    # The files end with:
    #   }
    #   }
    #   
    # (Two closing braces for _confirmDelete and the State class, but line 1491 has an extra one)
    # Let's count braces or look for the specific pattern at the end.
    if content.strip().endswith('}\n  }'):
        # This is correct: one for method, one for class
        pass
    elif content.strip().endswith('}\n  }\n  }'):
        # This is incorrect: extra brace
        content = content.rstrip()
        if content.endswith('}'):
            content = content[:-1].rstrip()
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Refined {filepath}")
