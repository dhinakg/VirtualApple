import base64
import plistlib
from pathlib import Path
from pprint import pprint

while True:
    text = input("Enter base64 string: ").strip()
    if not text:
        break

    try:
        raw = base64.b64decode(text)
        Path("opaque.plist").write_bytes(raw)
        plist = plistlib.loads(raw)
        pprint(plist)
    except Exception as e:
        print(e)
        continue
