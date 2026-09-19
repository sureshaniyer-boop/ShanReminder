"""Run once on the owner's computer: protect a permanent key in GitHub Secrets.

Requires Python 3.9+, Java keytool and authenticated GitHub CLI (gh).
No private key or password is printed or committed. Keep an independent backup.
"""
import argparse
import base64
import getpass
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


REPO = 'sureshaniyer-boop/ShanReminder'


def run(args, data=None, env=None):
    result = subprocess.run(args, input=data, capture_output=True, env=env)
    if result.returncode:
        raise RuntimeError(f'{args[0]} {args[1]} failed. Check authentication, permissions or the supplied key. Secret values are not logged.')
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--keystore', required=True, help='Private .p12 path outside the repository')
    parser.add_argument('--create', action='store_true', help='Explicitly create a new identity; incompatible with old debug-signed APKs')
    parser.add_argument('--alias', default='shanreminder')
    args = parser.parse_args()
    for name in ['gh', 'keytool']:
        if not shutil.which(name):
            raise RuntimeError(f'Install {name} and add it to PATH before continuing')
    path = Path(args.keystore).expanduser().resolve()
    repo_root = Path(__file__).resolve().parents[1]
    if path == repo_root or repo_root in path.parents:
        raise RuntimeError('Store the private keystore outside the repository')
    variables = json.loads(run(['gh', 'variable', 'list', '--repo', REPO, '--json', 'name,value']))
    pin = next((v['value'] for v in variables if v['name'] == 'ANDROID_SIGNING_CERT_SHA256'), None)
    secrets = json.loads(run(['gh', 'secret', 'list', '--repo', REPO, '--json', 'name']))
    configured = any(v['name'].startswith('ANDROID_SIGNING_') for v in secrets)
    if args.create and (path.exists() or pin or configured):
        raise RuntimeError('An identity already exists. Reuse its original keystore without --create; do not rotate it.')
    if not args.create and not path.is_file():
        raise RuntimeError('Existing keystore not found. Recover its backup; do not replace a lost key casually.')
    if configured and not pin:
        raise RuntimeError('Signing secrets exist without a certificate pin. Review the existing identity before changing it.')
    password = getpass.getpass('Keystore password (keystore and key must share this password): ')
    if len(password) < 12:
        raise RuntimeError('Use a strong password of at least 12 characters')
    if args.create and getpass.getpass('Confirm password: ') != password:
        raise RuntimeError('Passwords do not match')
    env = dict(os.environ, SHAN_LOCAL_SIGNING_PASSWORD=password)
    if args.create:
        path.parent.mkdir(parents=True, exist_ok=True)
        run(['keytool', '-genkeypair', '-keystore', str(path), '-storetype', 'PKCS12',
            '-alias', args.alias, '-keyalg', 'RSA', '-keysize', '3072', '-validity', '10000',
            '-dname', 'CN=ShanReminder', '-storepass:env', 'SHAN_LOCAL_SIGNING_PASSWORD',
            '-keypass:env', 'SHAN_LOCAL_SIGNING_PASSWORD'], env=env)
        os.chmod(path, 0o600)
    der = run(['keytool', '-exportcert', '-keystore', str(path), '-storetype', 'PKCS12',
        '-alias', args.alias, '-storepass:env', 'SHAN_LOCAL_SIGNING_PASSWORD'], env=env)
    fingerprint = hashlib.sha256(der).hexdigest()
    if pin and pin.replace(':', '').strip().lower() != fingerprint:
        raise RuntimeError('This key differs from the pinned identity. No GitHub settings were changed.')
    print('Certificate SHA-256:', fingerprint)
    print('Keep this keystore and its password in your own secure backups:', path)
    if input('Type BACKED UP after making that backup: ').strip() != 'BACKED UP':
        raise RuntimeError('Setup stopped before uploading secrets. Reuse this file without --create when ready.')
    if not pin:
        run(['gh', 'variable', 'set', 'ANDROID_SIGNING_CERT_SHA256', '--repo', REPO], fingerprint.encode())
    values = {'ANDROID_SIGNING_KEYSTORE_BASE64': base64.b64encode(path.read_bytes()),
              'ANDROID_SIGNING_PASSWORD': password.encode(),
              'ANDROID_SIGNING_ALIAS': args.alias.encode()}
    for name, value in values.items():
        run(['gh', 'secret', 'set', name, '--repo', REPO], value)
    print('Protected release identity configured. You can now enable the signed release workflow.')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        raise SystemExit(str(error))
