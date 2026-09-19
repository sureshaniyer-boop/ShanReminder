"""Wire the generated Flutter Android shell to an explicit release identity."""
from pathlib import Path
import sys


def configure(text):
    marker = 'signingConfig = signingConfigs.getByName("debug")'
    if text.count(marker) != 1 or text.count('    buildTypes {') != 1:
        raise ValueError('Flutter template changed; refusing an unverified signing configuration')
    config = '''    signingConfigs {
        create("release") {
            storeFile = file(requireNotNull(System.getenv("SHAN_SIGNING_STORE")))
            storePassword = requireNotNull(System.getenv("ANDROID_SIGNING_PASSWORD"))
            keyAlias = requireNotNull(System.getenv("ANDROID_SIGNING_ALIAS"))
            keyPassword = requireNotNull(System.getenv("ANDROID_SIGNING_PASSWORD"))
            storeType = "PKCS12"
        }
    }

'''
    text = text.replace('    buildTypes {', config + '    buildTypes {')
    text = text.replace(marker, 'signingConfig = signingConfigs.getByName("release")')
    if text.count('compileOptions {\n') != 1:
        raise ValueError('Flutter compileOptions template changed')
    text = text.replace('compileOptions {\n',
        'compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n', 1)
    text += '\n dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'
    return text


if __name__ == '__main__':
    path = Path(sys.argv[1])
    path.write_text(configure(path.read_text()))
