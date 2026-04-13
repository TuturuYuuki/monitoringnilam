#!/usr/bin/env python3
"""
Batch replace remaining Indonesian UI text with English across all Dart files
Handles variants with styling and special formatting
"""
import os
from pathlib import Path

# Additional replacement patterns for variants with styling
additional_replacements = {
    "const Text('Batal', style": "const Text('Cancel', style",
    "Text('Batal', style": "Text('Cancel', style",
    "Text('Batal')": "Text('Cancel')",
    "'Batal'": "'Cancel'",
    "const Text('Simpan', style": "const Text('Save', style",
    "Text('Simpan', style": "Text('Save', style",
    "Text('Simpan')": "Text('Save')",
    "'Simpan'": "'Save'",
    "const Text('Tutup', style": "const Text('Close', style",
    "Text('Tutup', style": "Text('Close', style",
    "Text('Tutup')": "Text('Close')",
    "'Tutup'": "'Close'",
    "const Text('Hapus', style": "const Text('Delete', style",
    "Text('Hapus', style": "Text('Delete', style",
    "const Text('Keluar', style": "const Text('Logout', style",
    "Text('Keluar', style": "Text('Logout', style",
    "Text('Keluar')": "Text('Logout')",
    "'Keluar'": "'Logout'",
}

lib_path = Path('lib')
updated_files = set()

for dart_file in lib_path.rglob('*.dart'):
    try:
        content = dart_file.read_text('utf-8')
        original = content
        
        for old, new in additional_replacements.items():
            if old in content:
                content = content.replace(old, new)
        
        if content != original:
            dart_file.write_text(content, 'utf-8')
            updated_files.add(dart_file.name)
            print(f"✓ Updated: {dart_file.name}")
    except Exception as e:
        print(f"✗ Error processing {dart_file.name}: {e}")

print(f"\n✓ Total files updated: {len(updated_files)}")
