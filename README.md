# Meridian

A polished, modern tic-tac-toe game built in **Godot 4** with **GDScript**. Play on a customizable board (3×3 to 19×19), compete against an intelligent AI, or challenge a friend locally.

![Meridian](https://img.shields.io/badge/Godot-4.x-478CBF?style=flat-square&logo=godot-engine)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/status-In%20Development-yellow?style=flat-square)

---

## 🎮 Gameplay

Unlike classic tic-tac-toe, Meridian is a **modern, skill-based game**:

- **Fill the entire board** — no early wins. The game ends only when all cells are occupied.
- **Score maximal runs** — players earn points for every straight line of 3+ identical marks (horizontal, vertical, and both diagonals).
- **Scoring formula** — a run of length *L* is worth *L* points. Longer lines = bigger rewards. Highest score wins.
- **Multiple modes**:
  - **vs AI** — compete against an intelligent opponent (Easy / Medium / Hard difficulty)
  - **Local 2-player** — pass-and-play with a friend on the same device
- **Customizable boards** — play on 3×3, 5×5, 9×9, 15×15, or any size 3–19.

---

## ✨ Features

- **Smart AI** — depth-limited negamax with alpha-beta pruning, move ordering, and transposition tables; difficulty scales dynamically
- **Responsive design** — works on desktop (Windows) and mobile (portrait); board always square and centered
- **Polished UI** — smooth animations, theme switching (light / dark / optional purple accent), sound & music controls
- **Design system** — built from professional tokens (colors, typography, spacing); flat-fill aesthetic
- **Accessibility** — 44px minimum tap targets, clear visual hierarchy, readable fonts (Sora, Hanken Grotesk, JetBrains Mono)
- **Settings persistence** — saves your last mode, difficulty, board size, theme, and audio preferences

---

## 📁 Project Structure

```
meridian/
├── PROTOTYPE.py              # Original Python reference (rules validation only)
├── CLAUDE.md                 # Authoritative project guide
├── README.md                 # This file
│
├── reference/                # Design reference (not built code)
│   ├── tokens.css            # Design tokens (colors, type, spacing)
│   ├── game.css              # Component styles
│   └── board.js              # Rendering & scoring reference
│
├── assets/
│   ├── branding/             # Logo & icons (SVG)
│   ├── fonts/                # Google Fonts (Sora, Hanken Grotesk, JetBrains Mono)
│   ├── sfx/                  # Sound effects
│   └── music/                # Background music
│
├── scripts/
│   ├── core/                 # Pure game logic (unit-testable)
│   │   ├── board.gd          # Board model
│   │   ├── rules.gd          # Game rules (fill, directions, maximal runs)
│   │   └── scoring.gd        # Score calculation
│   │
│   ├── ai/                   # AI search & evaluation
│   │   ├── search.gd         # Negamax + alpha-beta pruning
│   │   └── evaluator.gd      # Board evaluation & heuristics
│   │
│   └── ui/                   # Scene controllers (UI logic only)
│       ├── main_menu.gd
│       ├── game_setup.gd
│       ├── game_controller.gd
│       ├── game_over.gd
│       └── settings.gd
│
├── scenes/                   # Godot scene files (.tscn)
│   ├── MainMenu.tscn
│   ├── GameSetup.tscn
│   ├── Game.tscn
│   ├── GameOver.tscn
│   ├── Settings.tscn
│   └── Board.tscn
│
├── theme/
│   ├── theme.tres            # Master Godot theme (colors, fonts, sizes)
│   └── fonts/                # Font resources
│
├── tests/                    # GUT / GdUnit4 test suite
│   ├── test_board.gd
│   ├── test_scoring.gd
│   ├── test_rules.gd
│   └── test_ai_search.gd
│
└── export/                   # Export presets
    └── Windows Desktop       # Windows release preset
```

---

## 🚀 Getting Started

### Prerequisites

- **Godot 4.x** ([download](https://godotengine.org/download))
- **GDScript** knowledge (Godot's Python-like scripting language)
- Optional: **GUT** or **GdUnit4** for running tests

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/meridian.git
   cd meridian
   ```

2. **Open in Godot**:
   - Launch Godot 4
   - Select "Open Project" → navigate to the `meridian/` folder
   - Click "Open & Edit"

3. **Import assets** (one-time):
   ```bash
   godot --headless --import
   ```

4. **Run the game**:
   - Press **F5** in the editor, or
   - Go to **Run** → **Play** in the menu

### Run Tests (Headless)

```bash
# Run the full test suite
godot --headless --script=addons/gut/gut_cmdline.gd

# Or export and run a specific test
godot --headless --script=tests/test_scoring.gd
```

### Export for Windows

```bash
godot --headless --export-release "Windows Desktop" ./build/meridian.exe
```

Then run the executable:
```bash
./build/meridian.exe
```

---

## 🎯 Scoring Rules

After the board fills completely, scores are calculated as follows:

1. **Find maximal runs** — identify every straight line of 3+ identical marks in the 4 directions (horizontal, vertical, two diagonals).
2. **A maximal run** — a run is "maximal" if the adjacent cell in that direction is empty or contains a different mark.
3. **Award points** — each maximal run of length *L* contributes *L* points to the player's total.

**Example (5×5 board)**:
- A horizontal run of 3 X's = 3 points for X
- A diagonal run of 5 O's = 5 points for O
- If X and O both have the same total, it's a draw

---

## 🤖 AI

The AI uses **negamax with alpha-beta pruning** to explore moves strategically:

- **Easy** — shallow search (depth 1–2) + random blunder chance
- **Medium** — moderate search (depth 3–4) with move ordering
- **Hard** — deep search (depth 4–6) with transposition tables

The search is **non-blocking** — it runs on a worker thread with a per-move time budget, showing a "thinking" animation while the AI decides.

---

## 🎨 Design

Built with a professional, flat-fill design system:

- **Colors**: Jade (X), Terracotta (O), Amber (highlights)
- **Typography**: Sora (display), Hanken Grotesk (UI), JetBrains Mono (specs)
- **Theme**: Light and Dark modes, optional Purple accent variant
- **Responsive**: Works on desktop (windowed) and mobile (portrait)

See `reference/tokens.css` and `reference/game.css` for the full design spec.

---

## 📋 Development Roadmap

- [x] Core game rules & scoring
- [ ] **Phase 1**: Board model + pure game logic + unit tests
- [ ] **Phase 2**: AI search (negamax + alpha-beta)
- [ ] **Phase 3**: Board rendering (Godot 2D)
- [ ] **Phase 4**: UI & screens (Main Menu, Game Setup, Game, Game Over, Settings)
- [ ] **Phase 5**: Polish + audio + theme persistence
- [ ] **Phase 6**: Windows export + Android prep
- [ ] **Launch**: Itch.io release

---

## 🧪 Testing

Tests are pinned to reference scores generated from `board.js` (not PROTOTYPE.py). The test suite validates:

- Board state management (place, clear, full)
- Scoring (maximal runs in all 4 directions)
- Game rules (no early win, fill-to-end)
- AI evaluation (move quality, search correctness)

Run tests with:
```bash
godot --headless --script=addons/gut/gut_cmdline.gd
```

---

## 🛠️ Built With

- **Godot 4.x** — game engine
- **GDScript** — primary language
- **GUT / GdUnit4** — unit testing
- **Google Fonts** — Sora, Hanken Grotesk, JetBrains Mono
- **Figma / Design Tokens** — design system reference

---

## 📖 Project Guide

See **[CLAUDE.md](./CLAUDE.md)** for the authoritative project guide:
- Detailed rules & scoring definitions
- Hard constraints (no main-thread blocking, pure logic separation)
- Design system specifications
- Suggested conventions & folder layout

---

## 🎵 Audio

Sound & music are optional and user-controllable:

- **SFX**: placement, UI interaction, win, draw, game over
- **Music**: background loop during gameplay
- All audio files live in `assets/sfx/` and `assets/music/`

---

## 📱 Platform Support

- **Windows** — primary target (release-ready)
- **Android** — planned (touch-friendly, portrait-only)
- **macOS / Linux** — future (untested)

---

## 📝 License

This project is licensed under the **MIT License** — see [LICENSE](./LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit with clear messages (`git commit -m "Add feature description"`)
4. Push and open a pull request

For major changes, please open an issue first to discuss.

---

## 👤 Author

**Your Name** — [GitHub](https://github.com/yourusername) | [Email](mailto:you@example.com)

---

## 🙏 Acknowledgments

- **Godot Foundation** for the incredible open-source engine
- **Design reference** from the Meridian design system (tokens.css, game.css, board.js)
- Inspired by classic tic-tac-toe and modern puzzle games

---

## 📧 Support

Have questions or found a bug? Open an [issue](https://github.com/AmirHossein143/meridian/issues) on GitHub.

---

**Happy gaming! 🎮**