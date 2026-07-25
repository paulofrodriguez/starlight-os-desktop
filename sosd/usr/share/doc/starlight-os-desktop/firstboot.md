# First boot

`starlight-firstboot.service` runs once after networking is available. It records
non-secret hardware data locally and enables Flathub. Failures do not prevent
the desktop from starting.
