#!/bin/bash
set -e

# ╔══════════════════════════════════════════════════════════╗
# ║  Mac Windows-Style Setup                                ║
# ║                                                         ║
# ║  KEYBOARD (Karabiner Elements)                          ║
# ║  - Ctrl+C/V/X/A/S/Z/Y/F/G/N/W/T/B/I/L/R → Cmd         ║
# ║  - Swiss German AltGr: @ { } [ ] | \ ~ # €             ║
# ║  - Undo on Z (Swiss Z/Y swap), Redo on Y                ║
# ║  - Home/End cursor and selection keys                    ║
# ║  - Alt+F4 quit, F5 reload, F2 rename in Finder          ║
# ║  - § and < key swap (Mac vs PC position fix)             ║
# ║  - External KB: AltGr fix (built-in unaffected)          ║
# ║                                                         ║
# ║  SCROLL                                                 ║
# ║  - Trackpad: natural / Mouse: reversed (Scroll Reverser)║
# ║                                                         ║
# ║  SYSTEM                                                 ║
# ║  - Key repeat enabled (accent picker off)                ║
# ║  - Screenshots copy to clipboard                        ║
# ║  - All dock/window animations disabled                   ║
# ║  - Desktop background set to black                      ║
# ║                                                         ║
# ║  VS CODE                                                ║
# ║  - Windows Default Keybindings extension                 ║
# ║  - Swiss special char bindings (alt+key)                 ║
# ╚══════════════════════════════════════════════════════════╝

echo "=== MacBook Windows-Style Keyboard Setup ==="
echo ""

echo "[1/5] Installing Karabiner Elements..."
brew install --cask karabiner-elements

echo "[2/5] Cloning Swiss German PC keyboard config..."
cd ~
rm -rf karabiner-config
git clone https://github.com/patrickdobler/karabiner-config.git
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp karabiner-config/personal_shortcuts.json ~/.config/karabiner/assets/complex_modifications/
cp karabiner-config/hypershift_launcher.json ~/.config/karabiner/assets/complex_modifications/

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

# swap right_option <-> right_command on external keyboards only (AltGr fix)
external_swap_rule = {
    'description': 'Swap right_option and right_command for external keyboards (AltGr)',
    'manipulators': [
        {
            'conditions': [{'identifiers': [{'is_built_in_keyboard': False}], 'type': 'device_if'}],
            'from': {'key_code': 'right_option'},
            'to': [{'key_code': 'right_command'}],
            'type': 'basic'
        },
        {
            'conditions': [{'identifiers': [{'is_built_in_keyboard': False}], 'type': 'device_if'}],
            'from': {'key_code': 'right_command'},
            'to': [{'key_code': 'right_option'}],
            'type': 'basic'
        }
    ]
}
rules.insert(0, external_swap_rule)

config['profiles'][0]['complex_modifications']['rules'] = rules

# swap section sign and less-than keys (Mac vs PC layout fix)
simple = config['profiles'][0].setdefault('simple_modifications', [])
simple.append({'from': {'key_code': 'non_us_backslash'}, 'to': [{'key_code': 'grave_accent_and_tilde'}]})
simple.append({'from': {'key_code': 'grave_accent_and_tilde'}, 'to': [{'key_code': 'non_us_backslash'}]})

with open(kpath, 'w') as f:
    json.dump(config, f, indent=4, ensure_ascii=False)

print(f'  Enabled {len(rules)} rules + key swap + external AltGr fix')
"

echo ""
echo "  Open Karabiner Elements and approve the Virtual HID Device"
echo "  in System Settings > Privacy & Security > Input Monitoring"
echo ""

echo "[4/7] Installing Scroll Reverser (natural trackpad + Windows-style mouse scroll)..."
brew install --cask scroll-reverser
defaults write com.pilotmoon.scroll-reverser ReverseX -bool false
defaults write com.pilotmoon.scroll-reverser ReverseMouse -bool true
defaults write com.pilotmoon.scroll-reverser ReverseTrackpad -bool false
defaults write com.pilotmoon.scroll-reverser StartAtLogin -bool true
open "/Applications/Scroll Reverser.app"

echo "[5/7] Enabling key repeat..."
defaults write NSGlobalDomain ApplePressAndHoldEnabled -false

echo "[6/7] Setting screenshots to clipboard..."
defaults write com.apple.screencapture target clipboard

echo "[7/7] Disabling animations and setting black wallpaper..."
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock mineffect -string scale
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
killall Dock

mkdir -p ~/Pictures
convert -size 1x1 xc:black ~/Pictures/black.png 2>/dev/null || python3 -c "
import struct, zlib
def png(w,h,r,g,b):
    raw=b''
    for _ in range(h): raw+=b'\x00'+bytes([r,g,b])*w
    return b'\x89PNG\r\n\x1a\n'+b''.join(chunk(t,d) for t,d in [
        (b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0)),
        (b'IDAT',zlib.compress(raw)),(b'IEND',b'')])
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
open('$HOME/Pictures/black.png','wb').write(png(1,1,0,0,0))
"
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'$HOME'/Pictures/black.png"'

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
