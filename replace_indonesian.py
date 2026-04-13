#!/usr/bin/env python3
"""
Batch replace Indonesian UI text with English across all Dart files
"""
import os
from pathlib import Path

# Define replacement patterns
replacements = {
    "const Text('Batal')": "const Text('Cancel')",
    "const Text('Simpan')": "const Text('Save')",
    "const Text('Tutup')": "const Text('Close')",
    "const Text('Verifikasi')": "const Text('Verify')",
    "const Text('Hapus')": "const Text('Delete')",
    "const Text('Keluar')": "const Text('Logout')",
    "Text('Batal')": "Text('Cancel')",
    "Text('Simpan')": "Text('Save')",
    "Text('Tutup')": "Text('Close')",
    "Text('Verifikasi')": "Text('Verify')",
    "Text('Hapus')": "Text('Delete')",
    "Text('Keluar')": "Text('Logout')",
    "'Perangkat dihapus'": "'Deleted Device'",
    "'Yakin ingin keluar?'": "'Are you sure you want to exit?'",
    "'Silakan Masukkan Kode OTP 6 Digit'": "'Please Enter 6-Digit OTP Code'",
}

lib_path = Path('lib')
updated_files = []

for dart_file in lib_path.rglob('*.dart'):
    try:
        content = dart_file.read_text('utf-8')
        original = content
        
        for old, new in replacements.items():
            content = content.replace(old, new)
        
        if content != original:
            dart_file.write_text(content, 'utf-8')
            updated_files.append(dart_file.name)
            print(f"✓ Updated: {dart_file.name}")
    except Exception as e:
        print(f"✗ Error processing {dart_file.name}: {e}")

print(f"\n✓ Total files updated: {len(updated_files)}")
