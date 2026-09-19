"""Restore a protected release keystore and enforce its pinned certificate."""
import base64
import hashlib
import os
from pathlib import Path
import re
import subprocess


def prepare(env):
    required = ['ANDROID_SIGNING_KEYSTORE_BASE64', 'ANDROID_SIGNING_PASSWORD',
                'ANDROID_SIGNING_ALIAS', 'ANDROID_SIGNING_CERT_SHA256',
                'RUNNER_TEMP', 'GITHUB_ENV']
    if any(not env.get(name) for name in required):
        raise ValueError('Release signing is not configured. Follow SIGNING_SETUP.md; no debug fallback is allowed.')
    expected = env['ANDROID_SIGNING_CERT_SHA256'].replace(':', '').lower().strip()
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        raise ValueError('Invalid pinned certificate SHA-256')
    path = Path(env['RUNNER_TEMP']) / 'shan-release.p12'
    if path.exists():
        raise ValueError('Temporary signing path already exists; refusing to overwrite it')
    try:
        raw = base64.b64decode(env['ANDROID_SIGNING_KEYSTORE_BASE64'], validate=True)
        with path.open('xb') as stream:
            os.chmod(path, 0o600)
            stream.write(raw)
        result = subprocess.run(['keytool', '-exportcert', '-storetype', 'PKCS12',
            '-keystore', str(path), '-alias', env['ANDROID_SIGNING_ALIAS'],
            '-storepass:env', 'ANDROID_SIGNING_PASSWORD'],
            env=env, capture_output=True, check=False)
        if result.returncode:
            raise ValueError('Cannot read the signing certificate; verify keystore, alias and password')
        actual = hashlib.sha256(result.stdout).hexdigest()
        if actual != expected:
            raise ValueError('Signing certificate changed; refusing to build an incompatible update')
        with open(env['GITHUB_ENV'], 'a') as stream:
            stream.write(f'SHAN_SIGNING_STORE={path}\n')
        print('Release signing certificate verified:', actual)
    except Exception:
        path.unlink(missing_ok=True)
        raise


if __name__ == '__main__':
    try:
        prepare(dict(os.environ))
    except Exception as error:
        raise SystemExit(str(error))
