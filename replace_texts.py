import os

def replace_in_file(filepath, replacements):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for old, new in replacements:
            new_content = new_content.replace(old, new)
            
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated {filepath}")
    except Exception as e:
        print(f"Error {filepath}: {e}")

# Add exact replacements here
replacements = [
    # CCTV Loading & Empty
    ("LOADING CAMERAS...", "Loading CCTV data..."),
    ("LOADING CAMERA DATA...", "Loading CCTV data..."),
    ("No Data CCTV", "No CCTV data available"),
    
    # MMT Loading & Empty
    ("Loading MMT Data...", "Loading MMT data..."),
    ("No Data MMT", "No MMT data available"),
    
    # AP Loading & Empty
    ("Loading AP Data...", "Loading AP data..."),
    ("No Data AP", "No AP data available"),
    
    # Labels to Sentence Case
    ("labelText: 'Alamat IP'", "labelText: 'IP address'"),
    ("labelText: 'IP Address'", "labelText: 'IP address'"),
    ("labelText: 'Lokasi'", "labelText: 'Location'"),
    ("labelText: 'Location Name'", "labelText: 'Location name'"),
    ("labelText: 'Location Type'", "labelText: 'Location type'"),
    ("labelText: 'Master Type'", "labelText: 'Master type'"),
    ("labelText: 'Device Type'", "labelText: 'Device type'"),
    ("labelText: 'Device Name'", "labelText: 'Device name'"),
    ("hintText: 'Enter Device Name'", "hintText: 'Enter device name'"),
    ("hintText: 'Entry An IP Address'", "hintText: 'Enter an IP address'"),
    ("hintText: 'Select location'", "hintText: 'Select location'"),
    ("labelText: 'Nama'", "labelText: 'Name'"),
    
    # Action Buttons to Title Case
    ("Text('Add another device')", "Text('Add Another Device')"),
    ("Text('Save')", "Text('Save Changes')"),
    ("Text('Save', style: TextStyle(color: Colors.white))", "Text('Save Changes', style: TextStyle(color: Colors.white))"),
    ("Text('SAVE DATA',", "Text('Save Data',"),
    ("Text('Submit',", "Text('Submit',"),
]

directories = [
    'd:/db/htdocs/monitoringnilam/lib/pages/cctv',
    'd:/db/htdocs/monitoringnilam/lib/pages/mmt',
    'd:/db/htdocs/monitoringnilam/lib/pages/network',
    'd:/db/htdocs/monitoringnilam/lib/pages/devices'
]

for directory in directories:
    if os.path.exists(directory):
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.dart'):
                    replace_in_file(os.path.join(root, file), replacements)
