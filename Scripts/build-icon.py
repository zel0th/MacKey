#!/usr/bin/env python3
from pathlib import Path
import struct
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='mackey-icon-') as temporary:
    folder = Path(temporary)
    subprocess.run(['swift', '-module-cache-path', str(folder / 'cache'), str(root / 'Scripts/draw-icon.swift'), str(folder / 'images')], check=True)
    chunks = []
    for size, code in [(16,b'icp4'),(32,b'icp5'),(64,b'icp6'),(128,b'ic07'),(256,b'ic08'),(512,b'ic09'),(1024,b'ic10')]:
        name = f'icon_{size}x{size}.png' if size <= 512 else 'icon_512x512@2x.png'
        data = (folder / 'images' / name).read_bytes()
        chunks.append(code + struct.pack('>I', len(data) + 8) + data)
    body = b''.join(chunks)
    (root / 'Design/AppIcon.icns').write_bytes(b'icns' + struct.pack('>I', len(body) + 8) + body)
