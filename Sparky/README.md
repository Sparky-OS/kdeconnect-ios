# KDE Connect with Flat Headset

This native KDE Connect iPhone build adds a virtual-monitor page for a paired computer.
It checks the computer's protocol-v2 capabilities and opens Flat Headset with a fixed `flatheadset://catch` action.
Flat Headset confirms its own pairing with the same computer and owns the virtual monitor and RDP session while in the foreground.
No address, certificate, password or session credential crosses the application URL boundary.
No shared Keychain entitlement is assumed.

The upstream base is KDE Connect iOS a303639652c1cf486bd6fb61335970723c2085a7.
The native app keeps KDE Connect's TLS certificate pinning and explicit pairing confirmation.
The UUID uses this app's default Keychain access group rather than KDE's signing team's group.
The virtual-monitor page refuses unpaired, unreachable and incompatible peers and reports an unanswered capability query after ten seconds.
All twelve added messages are native resources in ten languages.

## Build and package

The `ios-unsigned.yml` workflow in Sparky-OS/flat-headset checks out this repository at an exact commit and runs these commands on its hosted Mac:

```sh
bash Sparky/build_unsigned.sh "$RUNNER_TEMP/kdeconnect-iphone"
bash Sparky/package_unsigned.sh "$RUNNER_TEMP/kdeconnect-iphone" "$GITHUB_WORKSPACE/kdeconnect-artifact" "$KDECONNECT_COMMIT" "$GITHUB_SHA"
```

The result is an unsigned arm64 IPA for iOS 16 and later, its SHA-256 and a `kdeconnect` entry for the renewal manifest.
No account, certificate or secret is needed to build.
The native build is pending its first hosted verification.

OpenSSL 4.0.1 is fetched from its own release with the hash in `openssl-source.json` and built with `no-shared no-module`.
The legacy provider is built into libcrypto because the upstream identity import for iOS 16 and 17 uses RC2 in its PKCS12 certificate bag.
Flat Headset's different OpenSSL configuration intentionally remains without that provider.
The old OpenSSL binary Swift package is removed; the three remaining source packages are pinned by revision.
The upstream SwiftLint build-plugin dependency is removed from this unsigned build; `-skipPackagePluginValidation` would skip validation, not the plugin's execution.
App package checks reject embedded frameworks, dynamic libraries, extensions, provisioning profiles and signatures.
Package licenses accompany the application.

## Linux checks

Run in an isolated Debian testing environment without a network, with Clang, GNUstep Base development files, GCC, Make and Python:

```sh
bash Sparky/test_protocol.sh build/protocol
# Fetch the hash-checked source before disconnecting the test container's network.
bash Sparky/build_openssl.sh host sources/openssl build/openssl
cc -Wall -Wextra -Werror -I build/openssl/install/include Sparky/Tests/CryptoTest.c build/openssl/install/lib/libcrypto.a -ldl -pthread -o build/crypto-test
OPENSSL_MODULES=/nonexistent OPENSSL_CONF=/nonexistent build/crypto-test
```

The protocol test compiles the actual Objective-C policy using GNUstep Foundation and checks pairing, reachability, versions, malformed capabilities, revocation, timeout and certificate equality.
The crypto test checks both identity-container formats against the static library without a provider directory.
Neither executes Apple's Security framework, SwiftUI, Bonjour nor the Keychain.
The hosted compile checks the native API use; first installation, network pairing and Security import remain device observations.
Wait until all three phone packages are ready before the single signing and installation session.
