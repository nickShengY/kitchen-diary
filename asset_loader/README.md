# Kitchen Diary Asset Loader

A modern Windows application for managing kitchen images and animations during development.

## Quick Start

**Double-click `run_asset_loader.bat`** to launch the application.

On first run, it will:
1. Create a Python virtual environment
2. Install all dependencies automatically
3. Launch the Asset Loader

## Features

### Modern Dark UI
- Clean, modern dark theme with accent colors
- Smooth hover effects and visual feedback
- Responsive grid layout

### Drag & Drop Import
- Drag images directly onto the window to import
- Or click "Import Assets" and browse
- Supports PNG, JPG, GIF, WebP formats

### Asset Browser
- **9 Categories**: Actions, Blocks, Cuisines, Ingredients, Ingredient States, Sprites, Tools, Transitions
- **Thumbnail Grid**: Adjustable size with zoom slider (60-150px)
- **Mapping Status**: Green checkmark for mapped assets, orange circle for unmapped

### Multi-Select & Bulk Operations
- **Ctrl+Click** to select multiple assets
- **Select All / Clear** buttons
- Bulk delete, move, duplicate

### Search, Filter & Sort
- **Search**: Type to filter assets by name
- **Filter**: All / Mapped Only / Unmapped Only
- **Sort**: Name, Size, Date (ascending/descending)

### Asset Details Panel
- Large preview (animated GIFs play automatically)
- File info: dimensions, size, date modified
- **Code Mapping**: Shows how asset maps to `kitchenData.ts`
- Video prompt info for actions and cuisines

### Quick Actions
| Action | Description |
|--------|-------------|
| 📂 Open | Open containing folder in Explorer |
| 📋 Copy | Copy file path to clipboard |
| ✏️ Rename | Rename the asset file |
| 📁 Move | Move to another category |
| 📑 Duplicate | Create a copy of the asset |
| 🗑️ Delete | Delete the asset |

### Right-Click Context Menu
Right-click any asset for quick access to all actions.

### Export Reports
- Export full asset inventory to CSV or JSON
- Includes mapping status and metadata

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Double-click | Open in default image viewer |
| Ctrl+Click | Multi-select toggle |
| Right-click | Context menu |

## Requirements

- Windows 10/11
- Python 3.8 or later

## Manual Installation

If the launcher doesn't work:

```bash
cd asset_loader
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python asset_loader.py
```

## File Structure

```
asset_loader/
├── asset_loader.py      # Main application (1500+ lines)
├── requirements.txt     # Dependencies
├── run_asset_loader.bat # Windows launcher
├── run_asset_loader.ps1 # PowerShell launcher
├── .gitignore          # Excludes venv, cache
└── README.md           # This file
```

## Notes

- This tool is for **production use only** - not part of the main app
- Assets are stored in `../kitchen_images/`
- Mappings are read from `../data/kitchenData.ts`
- Video prompts from `../kitchen_images/kitchen_video_prompts.json`
