# infra

Rebuilds my laptop from a fresh Arch install: packages, niri + DankMaterialShell (dux-shell),
dotfiles, Outlook/Teams web apps, services, firewall, quiet boot.

- `bootstrap.sh` - the one thing you run
- `local/` - the Ansible playbook (`vars/packages.yml` is the package list,
  `vars/pwas.yml` the web apps)
- `aur-packages.txt` - the few AUR-only packages, built with yay
- `scripts/drift.sh` - shows packages installed here but missing from the playbook

---

## Rebuilding a laptop

### 1. Install Arch

Boot the Arch ISO. Connect to wifi if needed:

```
iwctl station wlan0 connect "Your SSID"
```

Run `archinstall` and pick:

| Setting | Choose |
| --- | --- |
| Disk configuration | Use the whole disk, ext4, **encrypt** (LUKS) with a passphrase |
| Bootloader | **systemd-boot**, Unified kernel images: **yes** |
| Kernels | `linux` and `linux-lts` |
| Profile | **Minimal** (the playbook installs the desktop) |
| Audio | Pipewire |
| Network | **NetworkManager** |
| User | `michael`, with superuser (sudo) rights |
| Timezone | Australia/Brisbane |

Install, then reboot into the new system.

### 2. Run the bootstrap

Log in at the text console as `michael`. Connect to wifi:

```
nmcli device wifi connect "Your SSID" --ask
```

Download the script, read it, run it:

```
curl -fsSL https://raw.githubusercontent.com/eblakem/infra/main/bootstrap.sh -o bootstrap.sh
less bootstrap.sh
bash bootstrap.sh              # work laptop
bash bootstrap.sh --personal   # anything else (no DisplayLink, camera, Citrix)
```

It will ask you for two things:

1. **GitHub login.** It shows a code. Open https://github.com/login/device on
   your phone and enter it. (Needed because dotfiles is a private repo.)
2. **Your sudo password** ("BECOME password"), once.

Then it runs unattended for a while. Expect 20-40 minutes.

### 3. Reboot

```
sudo reboot
```

You should land on the tuigreet login, then niri with DMS.

### 4. After the first boot

These steps involve secrets or interactive logins, so they aren't automated:

- [ ] **Bitwarden** - open it and log in. Everything below comes from there.
- [ ] **SSH key** - restore `~/.ssh/id_ed25519` (+ `.pub`), then
      `chmod 600 ~/.ssh/id_ed25519`. Switch the repos to SSH:
      `git -C ~/dotfiles remote set-url origin git@github.com:eblakem/dotfiles.git`
      (same for `~/infra`).
- [ ] **age key for sops** - restore `~/.config/sops/age/keys.txt`.
- [ ] **Podman container secrets** - restore the `*.env` files in
      `~/.config/containers/systemd/`.
- [ ] **Reolink viewer** - restore `~/.config/reolink-cred` (`admin:<password>`,
      one line), then `chmod 600 ~/.config/reolink-cred`. It's gitignored in dotfiles.
- [ ] **Chromium** - open it. Outlook, Teams, draw.io, GitHub and Spotify install themselves
      within a minute or so. Sign in to each.
- [ ] **mise** - `mise install` to pull node and the other tools.
- [ ] **Unlock the disk with the TPM** (optional, no passphrase at boot):
      ```
      lsblk -f                                  # find the crypto_LUKS partition, e.g. nvme0n1p2
      sudo systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
      echo 'rd.luks.options=tpm2-device=auto' | sudo tee /etc/cmdline.d/tpm.conf
      sudo mkinitcpio -P
      ```
- [ ] **Secure Boot** (optional) - `sbctl` is installed; follow
      https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#sbctl

---

## Keeping it up to date

The playbook is only useful if it matches the laptop. Every so often:

```
~/infra/scripts/drift.sh
```

Add anything new to `local/vars/packages.yml` (or `aur-packages.txt` if
`pacman -Si <pkg>` can't find it), commit, push.

Re-running the whole thing on an existing machine is safe:

```
cd ~/infra/local && ansible-playbook main.yml -K
```

Config files themselves live in the dotfiles repo - commit there as usual.

## Notes

- **No AUR build user.** Almost everything comes from the official repos or
  [Chaotic-AUR](https://aur.chaotic.cx) (prebuilt AUR packages), so plain
  pacman is enough. The AUR-only leftovers are built by `yay` as you.
- **Web apps** are force-installed through Chromium policy
  (`/etc/chromium/policies/managed/web-apps.json`), so Chromium won't let you
  uninstall them. Remove them from `local/vars/pwas.yml` instead.
- **Teams Always Visible** (unpacked extension in dotfiles) is loaded with
  `--load-extension` in `~/.config/chromium-flags.conf`.
