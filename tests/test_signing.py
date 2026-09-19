import base64
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from tools.configure_release_signing import configure
from tools.prepare_signing import prepare


class SigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.key = Path(cls.temp.name) / 'test.p12'
        cls.env = dict(os.environ, ANDROID_SIGNING_PASSWORD='temporary-test-password')
        subprocess.run(['keytool', '-genkeypair', '-keystore', str(cls.key),
            '-storetype', 'PKCS12', '-alias', 'test', '-keyalg', 'RSA',
            '-keysize', '2048', '-validity', '1', '-dname', 'CN=Test',
            '-storepass:env', 'ANDROID_SIGNING_PASSWORD'], env=cls.env,
            capture_output=True, check=True)
        der = subprocess.run(['keytool', '-exportcert', '-keystore', str(cls.key),
            '-alias', 'test', '-storepass:env', 'ANDROID_SIGNING_PASSWORD'],
            env=cls.env, capture_output=True, check=True).stdout
        cls.pin = hashlib.sha256(der).hexdigest()

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def environment(self, folder):
        return dict(self.env, ANDROID_SIGNING_ALIAS='test',
            ANDROID_SIGNING_KEYSTORE_BASE64=base64.b64encode(self.key.read_bytes()).decode(),
            ANDROID_SIGNING_CERT_SHA256=self.pin, RUNNER_TEMP=folder,
            GITHUB_ENV=str(Path(folder) / 'env'))

    def test_missing_credentials_fail_closed(self):
        with self.assertRaises(ValueError):
            prepare({})

    def test_matching_key_is_restored_privately(self):
        with tempfile.TemporaryDirectory() as folder:
            prepare(self.environment(folder))
            path = Path(folder) / 'shan-release.p12'
            self.assertEqual(path.read_bytes(), self.key.read_bytes())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertIn(str(path), (Path(folder) / 'env').read_text())

    def test_changed_certificate_is_rejected_and_removed(self):
        with tempfile.TemporaryDirectory() as folder:
            env = self.environment(folder)
            env['ANDROID_SIGNING_CERT_SHA256'] = '0' * 64
            with self.assertRaisesRegex(ValueError, 'certificate changed'):
                prepare(env)
            self.assertFalse((Path(folder) / 'shan-release.p12').exists())
            self.assertFalse((Path(folder) / 'env').exists())

    def test_wrong_password_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            env = self.environment(folder)
            env['ANDROID_SIGNING_PASSWORD'] = 'incorrect'
            with self.assertRaises(ValueError):
                prepare(env)
            self.assertFalse((Path(folder) / 'shan-release.p12').exists())

    def test_release_configuration_replaces_debug(self):
        source = 'android {\n    compileOptions {\n    }\n    buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName("debug")\n        }\n    }\n}\n'
        output = configure(source)
        self.assertNotIn('getByName("debug")', output)
        self.assertIn('getByName("release")', output)
        self.assertIn('create("release")', output)
        self.assertIn('isCoreLibraryDesugaringEnabled = true', output)

    def test_unexpected_flutter_template_is_rejected(self):
        with self.assertRaises(ValueError):
            configure('android { buildTypes {} }')


if __name__ == '__main__':
    unittest.main()
