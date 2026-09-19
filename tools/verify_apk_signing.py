"""Verify the built APK cryptographically and compare its signer to the pin."""
import os
from pathlib import Path
import re
import subprocess
import sys


def verify(path, env):
    expected = env.get('ANDROID_SIGNING_CERT_SHA256', '').replace(':', '').strip().lower()
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        raise ValueError('A valid pinned release certificate is required')
    root = Path(env.get('ANDROID_HOME') or env.get('ANDROID_SDK_ROOT') or '')
    candidates = list(root.glob('build-tools/*/apksigner'))
    if not candidates:
        raise ValueError('Android apksigner tool is missing')
    def version(p):
        return tuple(int(x) for x in re.findall(r'\d+', p.parent.name))
    tool = max(candidates, key=version)
    result = subprocess.run([str(tool), 'verify', '--verbose', '--print-certs', str(path)],
        capture_output=True, text=True)
    if result.returncode:
        raise ValueError('APK signature verification failed; refusing to upload')
    fingerprints = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)', result.stdout)
    if len(fingerprints) != 1 or fingerprints[0].lower() != expected:
        raise ValueError('Built APK signer does not match the permanent identity')
    print('APK signature verified with the pinned release identity:', expected)


if __name__ == '__main__':
    try:
        verify(Path(sys.argv[1]), dict(os.environ))
    except Exception as error:
        raise SystemExit(str(error))
