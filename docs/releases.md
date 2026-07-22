# Release process

1. Select a supported Ubuntu LTS and test its package availability.
2. Update `SOSD_VERSION`, release name, installer branding, and documentation.
3. Review package and licensing changes.
4. Run validation and static tests from a clean checkout.
5. Build twice from clean state and compare manifests and ISO checksums.
6. Boot-test BIOS and UEFI paths in QEMU and test installation on an empty disk.
7. Test representative Intel, AMD, and NVIDIA hardware.
8. Sign the checksum and release metadata with the project release key.
9. Publish the ISO, checksum, signature, source commit, package manifest, and
   known issues.
10. Keep previous supported images available for rollback.

GitHub Actions validates every relevant commit. ISO production is initially
manual through `workflow_dispatch`; automatic publication should be enabled
only after signing keys, snapshot mirrors, installer tests, and artifact
retention are production-ready.

Commercial distribution requires a separate legal review of trademarks,
codecs, firmware, proprietary-driver consent, export requirements, and licenses.

