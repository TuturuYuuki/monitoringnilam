import os
target = r'c:\laragon\www\monitoringnilam\lib\pages\devices\add_device.dart'
lines = open(target, 'r').readlines()
# Fix lines starting from children ]
# 1319 is Children ]
lines[1319:1328] = [
    "                                      ],\n",
    "                                    ),\n",
    "                                  ),\n",
    "                                ),\n",
    "                              ) as dynamic) as Widget,\n",
    "                            );\n",
    "                          },\n",
    "                        ),\n"
]
with open(target, 'w') as f:
    f.writelines(lines)
print('SUCCESS')
