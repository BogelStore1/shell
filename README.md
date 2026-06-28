# BogelShell Protect v2.1

> **Shell Script Obfuscation Tool** — Bash-native, modular, cross-platform

[![Version](https://img.shields.io/badge/version-2.1.0-cyan)](https://github.com/BogelStore1/shell)
[![Platform](https://img.shields.io/badge/platform-Linux%20|%20OpenWRT%20|%20Termux-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

---

## ⚠️ Disclaimer

BogelShell Protect performs **OBFUSCATION**, not strong cryptographic encryption.

- It is designed to deter **casual reading** of your shell scripts.
- A skilled Bash user may be able to reverse it.
- **Do NOT use this to protect passwords, API keys, or sensitive secrets.**
- Only files encrypted by BogelShell Protect can be decrypted with this tool.

---

## Table of Contents

1. [Install](#install)
2. [Uninstall](#uninstall)
3. [Update](#update)
4. [Command Reference](#command-reference)
5. [Interactive Mode](#interactive-mode)
6. [Non-interactive / Bot / Website Mode](#non-interactive--bot--website-mode)
7. [JSON Mode](#json-mode)
8. [Integration Examples](#integration-examples)
9. [Troubleshooting](#troubleshooting)
10. [Limitations](#limitations--obfuscation-scope)

---

## Install

### Linux (Ubuntu, Debian, CentOS, AlmaLinux, Rocky Linux)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BogelStore1/shell/main/install.sh)
```

Or clone manually:

```bash
git clone https://github.com/BogelStore1/shell.git bogelshell-protect
cd bogelshell-protect
bash install.sh
```

**Install location:** `/opt/bogelshell-protect`
**Command:** `/usr/local/bin/bogelshell`

### Termux (Android)

```bash
pkg install git bash coreutils
bash <(curl -fsSL https://raw.githubusercontent.com/BogelStore1/shell/main/install.sh)
```

**Install location:** `~/.bogelshell-protect`
**Command:** `$PREFIX/bin/bogelshell`

### OpenWRT

```bash
opkg update && opkg install git bash coreutils-base64 gzip
bash <(curl -fsSL https://raw.githubusercontent.com/BogelStore1/shell/main/install.sh)
```

**Install location:** `/root/bogelshell-protect`
**Command:** `/usr/bin/bogelshell`

---

## Uninstall

```bash
# Via command (recommended)
bogelshell uninstall

# Or run the uninstaller directly
bash /opt/bogelshell-protect/uninstall.sh
```

The uninstaller:
- Removes the install directory
- Removes the `bogelshell` command
- **Does NOT delete** your personal script files

---

## Update

```bash
bogelshell update
```

Pulls the latest version from GitHub automatically.

---

## Command Reference

| Command | Description |
|---|---|
| `bogelshell` | Open interactive main menu |
| `bogelshell enc` | Open Encrypt Script menu |
| `bogelshell dec` | Open Decrypt Script menu |
| `bogelshell about` | Show About page |
| `bogelshell update` | Auto-update from GitHub |
| `bogelshell uninstall` | Remove BogelShell Protect |
| `bogelshell version` | Show version |
| `bogelshell help` | Show help |

### Non-interactive options

| Option | Description |
|---|---|
| `--input <file>` | Input script path |
| `--output <file>` | Output file path |
| `--json` | Output result as JSON |
| `--quiet` | Suppress progress output |
| `--force` | Overwrite output if exists |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Error |

---

## Interactive Mode

Launch the menu:

```bash
bogelshell
```

Navigate with number keys:

```
[1] Encrypt Script
[2] Decrypt Script
[3] About
[4] Update
[5] Uninstall
[0] Exit
```

Submenus prompt for file paths interactively.

---

## Non-interactive / Bot / Website Mode

Use `--input` and `--output` to skip all prompts:

```bash
# Encrypt
bogelshell enc --input script.sh --output script-enc.sh

# Decrypt
bogelshell dec --input script-enc.sh --output script.sh

# Force overwrite existing output
bogelshell enc --input script.sh --output script-enc.sh --force

# Silent (no progress output)
bogelshell enc --input script.sh --output script-enc.sh --quiet
```

---

## JSON Mode

Add `--json` to get machine-readable output. Perfect for Telegram bots, web panels, and API backends.

```bash
bogelshell enc --input install.sh --output install-enc.sh --json
```

**Success response:**

```json
{
  "status": true,
  "mode": "encrypt",
  "input": "install.sh",
  "output": "install-enc.sh",
  "message": "Encrypt success"
}
```

**Error response:**

```json
{
  "status": false,
  "mode": "encrypt",
  "message": "Input file not found: install.sh"
}
```

**JSON mode rules:**
- No ASCII logo
- No ANSI color codes
- No interactive prompts
- Exit code `0` on success, `1` on error

---

## Integration Examples

### Node.js

```javascript
const { execFile } = require("child_process");

function encryptScript(input, output) {
  return new Promise((resolve, reject) => {
    execFile(
      "bogelshell",
      ["enc", "--input", input, "--output", output, "--json", "--force"],
      (err, stdout, stderr) => {
        try {
          const result = JSON.parse(stdout);
          if (result.status) {
            resolve(result);
          } else {
            reject(new Error(result.message));
          }
        } catch (e) {
          reject(new Error("Failed to parse response: " + stdout));
        }
      }
    );
  });
}

// Usage
encryptScript("script.sh", "script-enc.sh")
  .then(r => console.log("Success:", r.output))
  .catch(e => console.error("Error:", e.message));
```

### PHP

```php
<?php

function bogelEncrypt(string $input, string $output, bool $force = false): array {
    $args = ["bogelshell", "enc", "--input", escapeshellarg($input),
             "--output", escapeshellarg($output), "--json"];
    if ($force) {
        $args[] = "--force";
    }
    $cmd = implode(" ", $args);
    $raw = shell_exec($cmd . " 2>&1");
    $result = json_decode($raw, true);
    if (!$result) {
        return ["status" => false, "message" => "Invalid response: " . $raw];
    }
    return $result;
}

// Usage
$result = bogelEncrypt("script.sh", "script-enc.sh", force: true);
if ($result["status"]) {
    echo "Encrypted: " . $result["output"] . PHP_EOL;
} else {
    echo "Error: " . $result["message"] . PHP_EOL;
}
```

### Telegram Bot (Node.js + node-telegram-bot-api)

```javascript
const TelegramBot = require("node-telegram-bot-api");
const { execFile } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const bot = new TelegramBot("YOUR_BOT_TOKEN", { polling: true });

bot.on("document", async (msg) => {
  const chatId = msg.chat.id;
  const file = msg.document;

  if (!file.file_name.endsWith(".sh")) {
    return bot.sendMessage(chatId, "Please send a .sh file to encrypt.");
  }

  // Download the file
  const fileLink = await bot.getFileLink(file.file_id);
  const tmpIn = path.join(os.tmpdir(), file.file_name);
  const tmpOut = path.join(os.tmpdir(), file.file_name.replace(".sh", "-enc.sh"));

  // Download (use axios/fetch in production)
  const https = require("https");
  const writeStream = fs.createWriteStream(tmpIn);
  https.get(fileLink, (res) => res.pipe(writeStream));

  writeStream.on("finish", () => {
    execFile(
      "bogelshell",
      ["enc", "--input", tmpIn, "--output", tmpOut, "--json", "--force"],
      async (err, stdout) => {
        try {
          const result = JSON.parse(stdout);
          if (result.status) {
            await bot.sendDocument(chatId, tmpOut, {
              caption: "✅ Script encrypted by BogelShell Protect",
            });
          } else {
            await bot.sendMessage(chatId, `❌ Error: ${result.message}`);
          }
        } catch (e) {
          await bot.sendMessage(chatId, "❌ Internal error");
        } finally {
          fs.unlinkSync(tmpIn);
          if (fs.existsSync(tmpOut)) fs.unlinkSync(tmpOut);
        }
      }
    );
  });
});

bot.onText(/\/start/, (msg) => {
  bot.sendMessage(
    msg.chat.id,
    "👋 Send a `.sh` file and I'll encrypt it with BogelShell Protect!"
  );
});
```

### Encrypt via CLI

```bash
# Basic encrypt
bogelshell enc --input myscript.sh --output myscript-enc.sh

# Force overwrite + quiet
bogelshell enc --input myscript.sh --output myscript-enc.sh --force --quiet

# JSON output for automation
bogelshell enc --input myscript.sh --output myscript-enc.sh --json --force
```

### Decrypt via CLI

```bash
# Basic decrypt
bogelshell dec --input myscript-enc.sh --output myscript-restored.sh

# Force + quiet
bogelshell dec --input myscript-enc.sh --output myscript-restored.sh --force --quiet

# JSON output
bogelshell dec --input myscript-enc.sh --output myscript-restored.sh --json --force
```

---

## Troubleshooting

### `bogelshell: command not found`

- Ensure the installer completed successfully
- For Termux: add `$PREFIX/bin` to your PATH:
  ```bash
  export PATH="$PREFIX/bin:$PATH"
  ```
- For standard Linux: check `/usr/local/bin/bogelshell` exists and is executable

### `Input file not found`

- Make sure you are passing the correct path
- Use absolute paths when calling from bots/scripts

### `File is not a valid BogelShell Protect encrypted file`

- Only files encrypted by **BogelShell Protect v2** can be decrypted
- Check the file starts with `# BOGELSHELL_PROTECT_FORMAT=2`

### `Output file already exists`

- Add `--force` to overwrite automatically
- Or delete the output file first

### `Output directory is not writable`

- Check write permissions on the output directory
- Use `chmod` or run as the appropriate user

### `Compression/encoding failed`

- Ensure `gzip` and `base64` are installed
- On Termux: `pkg install coreutils`
- On OpenWRT: `opkg install gzip coreutils-base64`

### `git clone failed` (during install/update)

- Check your internet connection
- Verify the repo URL: `https://github.com/BogelStore1/shell.git`
- On restricted networks, try: `git config --global http.sslVerify false` (not recommended for production)

---

## Limitations / Obfuscation Scope

| What it protects against | Status |
|---|---|
| Casual reading / copy-paste | ✅ Effective |
| Quick `cat` / `head` inspection | ✅ Effective |
| Distribution of readable source | ✅ Effective |
| Determined reverse engineering | ❌ Not guaranteed |
| Strong cryptographic secrecy | ❌ Not applicable |
| Protecting embedded passwords/tokens | ❌ Not safe |

**How obfuscation works:**

```
Encrypt:  source → gzip (compress) → base64 (encode) → rev (flip) → self-executing wrapper
Decrypt:  wrapper payload → rev (flip back) → base64 -d (decode) → gunzip → source
```

The output is a self-contained Bash script that decodes and executes itself at runtime.

**File format markers** (lines 1-2 of encrypted file):

```bash
# BOGELSHELL_PROTECT_FORMAT=2
# BOGELSHELL_PROTECT_MODE=OBFUSCATED
```

---

## Project Structure

```
bogelshell-protect/
├── install.sh          # Installer (cross-platform)
├── uninstall.sh        # Uninstaller
├── update.sh           # Auto-updater
├── main.sh             # Entry point + CLI dispatcher
├── modules/
│   ├── encrypt.sh      # Encrypt module (interactive + CLI)
│   ├── decrypt.sh      # Decrypt module (interactive + CLI)
│   └── about.sh        # About page
├── lib/
│   ├── color.sh        # ANSI color helpers
│   ├── progress.sh     # Progress bar + spinner
│   ├── random.sh       # Random string/key generators
│   ├── validate.sh     # File & format validators
│   ├── builder.sh      # Core obfuscation engine
│   ├── loader.sh       # Logo & banner display
│   ├── cli.sh          # CLI argument parser
│   └── json.sh         # JSON output helpers
├── assets/
│   └── logo.txt        # ASCII logo
└── README.md
```

---

## License

MIT — © BogelStore

---

*BogelShell Protect v2.1 — Shell Script Obfuscation Tool*
