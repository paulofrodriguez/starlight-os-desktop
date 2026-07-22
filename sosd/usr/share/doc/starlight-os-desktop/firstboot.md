# First boot

`starlight-firstboot.service` runs once after networking is available. It records
non-secret hardware data locally, enables Flathub, and installs Ubuntu's
recommended proprietary NVIDIA driver when compatible NVIDIA hardware exists.
Failures do not prevent the desktop from starting.

