# bashrc-config

Personal Bash configuration with color themes and utility functions.

## Features

- 🎨 Elegant color scheme
- 🕒 Time functions (`now()`, `timestamp()`)
- 🔧 Useful aliases
- 📦 Component extension support

## Installation

### Standalone Installation

```bash
git clone https://github.com/wuyufffan/bashrc-config.git
cd bashrc-config
./install.sh
```

### As Part of my_linux_config

```bash
cd ~/my_linux_config
./install.sh --with-bashrc
```

## Component Extension

Other components (like te-cli) can add their initialization scripts to:

```
~/.config/my_linux_config/components/
├── te-cli.sh
└── other-component.sh
```

These scripts will be automatically sourced by `.bashrc`.

## Structure

```
bashrc-config/
├── .bashrc           # Main configuration
├── install.sh        # Installation script
└── README.md         # This file
```

## License

MIT License
