#!/bin/bash
set -e

echo "=== MacBook Windows-Style Keyboard Setup ==="
echo ""

echo "[1/5] Installing Karabiner Elements..."
brew install --cask karabiner-elements

echo "[2/5] Cloning Swiss German PC keyboard config..."
cd ~
rm -rf karabiner-pc-qwertz
git clone https://github.com/leohoe/karabiner-pc-qwertz.git
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp karabiner-pc-qwertz/personal_shortcuts.json ~/.config/karabiner/assets/complex_modifications/
cp karabiner-pc-qwertz/hypershift_launcher.json ~/.config/karabiner/assets/complex_modifications/

echo "[3/5] Enabling PC-Style and Swiss keyboard rules..."
python3 -c "
import json, os

kpath = os.path.expanduser('~/.config/karabiner/karabiner.json')
with open(kpath) as f:
    config = json.load(f)

mods_path = os.path.expanduser('~/.config/karabiner/assets/complex_modifications/personal_shortcuts.json')
with open(mods_path) as f:
    mods = json.load(f)

keep = ['PC-Style', 'PC Style', 'Swiss', 'Home to', 'End to', 'Shift+Home', 'Shift+End', 'Control+Home', 'Control+End', 'Paste without formatting', 'Finder: Use F2']
rules = [r for r in mods.get('rules', []) if any(k in r.get('description', '') for k in keep)]

config['profiles'][0]['complex_modifications']['rules'] = rules

simple = config['profiles'][0].setdefault('simple_modifications', [])
simple.append({'from': {'key_code': 'non_us_backslash'}, 'to': [{'key_code': 'grave_accent_and_tilde'}]})
simple.append({'from': {'key_code': 'grave_accent_and_tilde'}, 'to': [{'key_code': 'non_us_backslash'}]})

with open(kpath, 'w') as f:
    json.dump(config, f, indent=4, ensure_ascii=False)

print(f'  Enabled {len(rules)} rules + key swap')
"

echo ""
echo "  Open Karabiner Elements and approve the Virtual HID Device"
echo "  in System Settings > Privacy & Security > Input Monitoring"
echo ""

echo "[4/5] Enabling key repeat..."
defaults write NSGlobalDomain ApplePressAndHoldEnabled -false

echo "[5/5] Setting screenshots to clipboard..."
defaults write com.apple.screencapture target clipboard

KPATH="$HOME/Library/Application Support/Code/User/keybindings.json"
if command -v code &> /dev/null; then
    echo ""
    echo "=== VS Code ==="
    code --install-extension ms-vscode.vs-keybindings

    mkdir -p "$(dirname "$KPATH")"
    SWISS='[
      {"key":"alt+8","command":"type","args":{"text":"{"},"when":"editorTextFocus"},
      {"key":"alt+9","command":"type","args":{"text":"}"},"when":"editorTextFocus"},
      {"key":"alt+5","command":"type","args":{"text":"["},"when":"editorTextFocus"},
      {"key":"alt+6","command":"type","args":{"text":"]"},"when":"editorTextFocus"},
      {"key":"alt+7","command":"type","args":{"text":"|"},"when":"editorTextFocus"},
      {"key":"alt+n","command":"type","args":{"text":"~"},"when":"editorTextFocus"},
      {"key":"alt+3","command":"type","args":{"text":"#"},"when":"editorTextFocus"},
      {"key":"alt+g","command":"type","args":{"text":"@"},"when":"editorTextFocus"},
      {"key":"alt+shift+7","command":"type","args":{"text":"\\\\"},"when":"editorTextFocus"},
      {"key":"alt+e","command":"type","args":{"text":"€"},"when":"editorTextFocus"}
    ]'

    if [ -f "$KPATH" ]; then
        python3 -c "
import json
fix = json.loads('''$SWISS''')
with open('$KPATH') as f: existing = json.load(f)
existing.extend(fix)
with open('$KPATH', 'w') as f: json.dump(existing, f, indent=2)
print('  Merged Swiss keybindings')
"
    else
        echo "$SWISS" > "$KPATH"
        echo "  Created VS Code keybindings"
    fi
fi

echo ""
echo "=== Done ==="
