"""
Kitchen Diary Asset Loader
A modern Windows-based application for managing kitchen images and animations.
For production use only - not part of the main application.

Features:
- Drag and drop import
- Modern dark UI with animations
- Multi-select and bulk operations
- Asset preview with zoom
- Code mapping viewer
- Search, filter, and sort
- Export reports
"""

import os
import sys
import json
import shutil
import re
import csv
from pathlib import Path
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import threading
import subprocess

import customtkinter as ctk
from PIL import Image, ImageTk, ImageDraw, ImageFilter
import tkinter as tk
from tkinter import filedialog, messagebox

# Try to import drag-drop support
try:
    from tkinterdnd2 import DND_FILES, TkinterDnD
    DND_AVAILABLE = True
except ImportError:
    DND_AVAILABLE = False
    print("Note: tkinterdnd2 not installed. Drag-drop will use fallback.")

# Configure CustomTkinter
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

# ============================================================================
# Constants and Configuration
# ============================================================================

ASSET_CATEGORIES = {
    "actions": ("Cooking Actions", "🔪"),
    "blocks": ("Recipe Blocks", "📦"),
    "cuisines": ("Cuisine Types", "🌍"),
    "ingredients": ("Raw Ingredients", "🥕"),
    "ingredient_states": ("Ingredient States", "🍳"),
    "sprites/actions": ("Action Sprites", "🎬"),
    "sprites/ingredients": ("Ingredient Sprites", "🎨"),
    "tools": ("Kitchen Tools", "🍴"),
    "transitions": ("State Transitions", "➡️")
}

CUISINE_NAMES = {
    "1": "Italian", "2": "Chinese", "3": "Mexican", "4": "French",
    "5": "Japanese", "6": "American", "7": "Indian", "8": "Thai",
    "9": "Korean", "10": "Mediterranean"
}

# Modern color scheme
COLORS = {
    "bg_dark": "#1a1a2e",
    "bg_medium": "#16213e",
    "bg_light": "#0f3460",
    "accent": "#e94560",
    "accent_hover": "#ff6b6b",
    "success": "#4ecca3",
    "warning": "#ffc107",
    "text": "#eaeaea",
    "text_muted": "#a0a0a0",
    "border": "#2a2a4a",
    "card": "#1f1f3a",
    "card_hover": "#2a2a5a",
    "selected": "#3a3a7a"
}

class SortOption(Enum):
    NAME_ASC = "Name (A-Z)"
    NAME_DESC = "Name (Z-A)"
    SIZE_ASC = "Size (Small first)"
    SIZE_DESC = "Size (Large first)"
    DATE_ASC = "Date (Oldest first)"
    DATE_DESC = "Date (Newest first)"

class FilterOption(Enum):
    ALL = "All Assets"
    MAPPED = "Mapped Only"
    UNMAPPED = "Unmapped Only"

# ============================================================================
# Data Classes
# ============================================================================

@dataclass
class AssetInfo:
    """Information about a single asset file."""
    path: Path
    name: str
    category: str
    size: tuple = (0, 0)
    file_size: int = 0
    modified_time: float = 0
    mapping: Optional[Dict[str, Any]] = None
    is_selected: bool = False

    @property
    def is_mapped(self) -> bool:
        return self.mapping is not None

    @property
    def display_name(self) -> str:
        return self.name.replace('.png', '').replace('.gif', '').replace('_', ' ').title()


# ============================================================================
# Kitchen Data Parser
# ============================================================================

class KitchenDataParser:
    """Parser for kitchenData.ts to extract mappings."""

    def __init__(self, kitchen_data_path: Path):
        self.kitchen_data_path = kitchen_data_path
        self.ingredients: Dict[str, Dict] = {}
        self.tools: Dict[str, Dict] = {}
        self.actions: Dict[str, Dict] = {}
        self._parse()

    def _parse(self):
        if not self.kitchen_data_path.exists():
            return

        content = self.kitchen_data_path.read_text(encoding='utf-8')

        # Parse ingredients
        ing_pattern = r"\{\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*emoji:\s*'([^']+)',\s*category:\s*'([^']+)'"
        for match in re.finditer(ing_pattern, content):
            self.ingredients[match.group(1)] = {
                'id': match.group(1), 'name': match.group(2),
                'emoji': match.group(3), 'category': match.group(4)
            }

        # Parse tools
        tool_pattern = r"\{\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*icon:\s*(\w+),\s*type:\s*'([^']+)'"
        for match in re.finditer(tool_pattern, content):
            self.tools[match.group(1)] = {
                'id': match.group(1), 'name': match.group(2),
                'icon': match.group(3), 'type': match.group(4)
            }

        # Parse actions
        action_pattern = r"\{\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*verb:\s*'([^']+)',\s*icon:\s*'([^']+)'"
        for match in re.finditer(action_pattern, content):
            self.actions[match.group(1)] = {
                'id': match.group(1), 'name': match.group(2),
                'verb': match.group(3), 'icon': match.group(4)
            }

    def get_mapping_for_asset(self, asset_name: str, category: str) -> Optional[Dict]:
        clean_name = asset_name.lower().replace('.png', '').replace('.gif', '')

        if category == "ingredients":
            return self.ingredients.get(clean_name)
        elif category == "tools":
            return self.tools.get(clean_name.replace('tool_', ''))
        elif category == "actions":
            return self.actions.get(clean_name.replace('action_', ''))
        elif category == "ingredient_states":
            parts = clean_name.split('_')
            if parts:
                ing = self.ingredients.get(parts[0])
                if ing:
                    return {**ing, 'state': '_'.join(parts[1:]) if len(parts) > 1 else 'raw'}
        elif category == "transitions":
            parts = clean_name.split('_')
            if 'to' in parts:
                idx = parts.index('to')
                base = parts[0] if idx > 0 else ''
                ing = self.ingredients.get(base)
                if ing:
                    return {**ing, 'from': parts[idx-1] if idx > 0 else 'raw',
                            'to': '_'.join(parts[idx+1:])}
        elif category == "cuisines":
            if clean_name in CUISINE_NAMES:
                return {'id': clean_name, 'name': CUISINE_NAMES[clean_name]}
        return None


# ============================================================================
# Modern UI Components
# ============================================================================

class ModernCard(ctk.CTkFrame):
    """A modern card component with hover effects."""

    def __init__(self, master, **kwargs):
        super().__init__(master, corner_radius=12, fg_color=COLORS["card"],
                         border_width=1, border_color=COLORS["border"], **kwargs)
        self.bind("<Enter>", self._on_enter)
        self.bind("<Leave>", self._on_leave)

    def _on_enter(self, e):
        self.configure(fg_color=COLORS["card_hover"])

    def _on_leave(self, e):
        self.configure(fg_color=COLORS["card"])


class AssetThumbnail(ctk.CTkFrame):
    """A modern clickable thumbnail widget."""

    def __init__(self, master, asset: AssetInfo, on_click, on_double_click,
                 on_right_click, thumbnail_size=100):
        super().__init__(master, corner_radius=10, fg_color=COLORS["card"],
                         border_width=2, border_color=COLORS["card"])

        self.asset = asset
        self.on_click = on_click
        self.on_double_click = on_double_click
        self.on_right_click = on_right_click
        self.thumbnail_size = thumbnail_size
        self._selected = False
        self._photo = None

        # Main container
        self.inner = ctk.CTkFrame(self, fg_color="transparent")
        self.inner.pack(fill="both", expand=True, padx=3, pady=3)

        # Image container with rounded corners effect
        self.img_frame = ctk.CTkFrame(self.inner, fg_color=COLORS["bg_medium"],
                                       corner_radius=8, height=thumbnail_size,
                                       width=thumbnail_size)
        self.img_frame.pack(padx=5, pady=5)
        self.img_frame.pack_propagate(False)

        # Load image
        self._load_image()

        # Asset name
        display_name = asset.name[:18] + "..." if len(asset.name) > 18 else asset.name
        self.name_label = ctk.CTkLabel(self.inner, text=display_name,
                                        font=("Segoe UI", 11),
                                        text_color=COLORS["text"])
        self.name_label.pack(pady=(0, 2))

        # Status indicator
        if asset.is_mapped:
            status_text = "✓ Mapped"
            status_color = COLORS["success"]
        else:
            status_text = "○ Unmapped"
            status_color = COLORS["warning"]

        self.status_label = ctk.CTkLabel(self.inner, text=status_text,
                                          font=("Segoe UI", 9),
                                          text_color=status_color)
        self.status_label.pack(pady=(0, 5))

        # Bind events to all children
        self._bind_events(self)

    def _load_image(self):
        try:
            img = Image.open(self.asset.path)

            # Handle animated GIFs - show first frame
            if hasattr(img, 'n_frames') and img.n_frames > 1:
                img.seek(0)

            # Create thumbnail with aspect ratio
            img.thumbnail((self.thumbnail_size - 10, self.thumbnail_size - 10),
                          Image.Resampling.LANCZOS)

            # Convert to RGBA if needed
            if img.mode != 'RGBA':
                img = img.convert('RGBA')

            self._photo = ctk.CTkImage(light_image=img, dark_image=img,
                                        size=(img.width, img.height))

            self.image_label = ctk.CTkLabel(self.img_frame, image=self._photo, text="")
            self.image_label.place(relx=0.5, rely=0.5, anchor="center")

        except Exception as e:
            self.image_label = ctk.CTkLabel(self.img_frame, text="⚠️",
                                             font=("Segoe UI", 24))
            self.image_label.place(relx=0.5, rely=0.5, anchor="center")

    def _bind_events(self, widget):
        widget.bind("<Button-1>", self._handle_click)
        widget.bind("<Double-Button-1>", self._handle_double_click)
        widget.bind("<Button-3>", self._handle_right_click)
        widget.bind("<Enter>", self._on_enter)
        widget.bind("<Leave>", self._on_leave)

        for child in widget.winfo_children():
            self._bind_events(child)

    def _handle_click(self, e):
        ctrl_held = e.state & 0x4
        self.on_click(self.asset, ctrl_held)

    def _handle_double_click(self, e):
        self.on_double_click(self.asset)

    def _handle_right_click(self, e):
        self.on_right_click(self.asset, e)

    def _on_enter(self, e):
        if not self._selected:
            self.configure(fg_color=COLORS["card_hover"])

    def _on_leave(self, e):
        if not self._selected:
            self.configure(fg_color=COLORS["card"])

    def set_selected(self, selected: bool):
        self._selected = selected
        if selected:
            self.configure(fg_color=COLORS["selected"],
                           border_color=COLORS["accent"])
        else:
            self.configure(fg_color=COLORS["card"],
                           border_color=COLORS["card"])


class DropZone(ctk.CTkFrame):
    """A drop zone for drag-and-drop import."""

    def __init__(self, master, on_drop):
        super().__init__(master, corner_radius=15, fg_color=COLORS["bg_medium"],
                         border_width=3, border_color=COLORS["border"],
                         height=150)

        self.on_drop = on_drop
        self.pack_propagate(False)

        # Icon
        self.icon_label = ctk.CTkLabel(self, text="📂",
                                        font=("Segoe UI", 48))
        self.icon_label.pack(pady=(20, 5))

        # Text
        self.text_label = ctk.CTkLabel(self, text="Drag & Drop Images Here",
                                        font=("Segoe UI", 14, "bold"),
                                        text_color=COLORS["text"])
        self.text_label.pack()

        self.subtext_label = ctk.CTkLabel(self,
                                           text="or click to browse • PNG, JPG, GIF, WebP",
                                           font=("Segoe UI", 11),
                                           text_color=COLORS["text_muted"])
        self.subtext_label.pack(pady=(2, 20))

        # Bind click
        self.bind("<Button-1>", self._browse_files)
        self.icon_label.bind("<Button-1>", self._browse_files)
        self.text_label.bind("<Button-1>", self._browse_files)
        self.subtext_label.bind("<Button-1>", self._browse_files)

    def _browse_files(self, e=None):
        files = filedialog.askopenfilenames(
            title="Select Images to Import",
            filetypes=[
                ("Image files", "*.png *.jpg *.jpeg *.gif *.webp"),
                ("All files", "*.*")
            ]
        )
        if files:
            self.on_drop(list(files))

    def highlight(self, active=True):
        if active:
            self.configure(border_color=COLORS["accent"],
                           fg_color=COLORS["bg_light"])
        else:
            self.configure(border_color=COLORS["border"],
                           fg_color=COLORS["bg_medium"])


class ZoomSlider(ctk.CTkFrame):
    """Thumbnail size zoom slider."""

    def __init__(self, master, on_change, initial=100):
        super().__init__(master, fg_color="transparent")

        ctk.CTkLabel(self, text="🔍", font=("Segoe UI", 12)).pack(side="left", padx=(0, 5))

        self.slider = ctk.CTkSlider(self, from_=60, to=150, number_of_steps=9,
                                     width=100, command=on_change)
        self.slider.set(initial)
        self.slider.pack(side="left")

        self.value_label = ctk.CTkLabel(self, text=f"{initial}px",
                                         font=("Segoe UI", 10),
                                         text_color=COLORS["text_muted"],
                                         width=40)
        self.value_label.pack(side="left", padx=(5, 0))

    def update_label(self, value):
        self.value_label.configure(text=f"{int(value)}px")


# ============================================================================
# Asset Browser with Grid View
# ============================================================================

class AssetBrowser(ctk.CTkScrollableFrame):
    """Modern scrollable grid of asset thumbnails."""

    def __init__(self, master, on_select, on_double_click, on_right_click):
        super().__init__(master, corner_radius=0, fg_color=COLORS["bg_dark"])

        self.on_select = on_select
        self.on_double_click = on_double_click
        self.on_right_click = on_right_click
        self.thumbnails: List[AssetThumbnail] = []
        self.selected_assets: Set[AssetInfo] = set()
        self.columns = 5
        self.thumbnail_size = 100

    def set_thumbnail_size(self, size: int):
        self.thumbnail_size = int(size)
        # Recalculate columns based on available width
        self._update_columns()

    def _update_columns(self):
        width = self.winfo_width()
        if width > 1:
            self.columns = max(2, width // (self.thumbnail_size + 20))

    def load_assets(self, assets: List[AssetInfo]):
        # Clear existing
        for thumb in self.thumbnails:
            thumb.destroy()
        self.thumbnails.clear()
        self.selected_assets.clear()

        if not assets:
            # Show empty state
            empty_label = ctk.CTkLabel(self, text="No assets found",
                                        font=("Segoe UI", 14),
                                        text_color=COLORS["text_muted"])
            empty_label.grid(row=0, column=0, pady=50)
            return

        self._update_columns()

        # Create thumbnails
        for i, asset in enumerate(assets):
            thumb = AssetThumbnail(self, asset,
                                    self._on_thumbnail_click,
                                    self._on_thumbnail_double_click,
                                    self._on_thumbnail_right_click,
                                    self.thumbnail_size)
            row = i // self.columns
            col = i % self.columns
            thumb.grid(row=row, column=col, padx=6, pady=6, sticky="nw")
            self.thumbnails.append(thumb)

    def _on_thumbnail_click(self, asset: AssetInfo, ctrl_held: bool):
        if ctrl_held:
            # Toggle selection
            if asset in self.selected_assets:
                self.selected_assets.remove(asset)
            else:
                self.selected_assets.add(asset)
        else:
            # Single select
            self.selected_assets.clear()
            self.selected_assets.add(asset)

        # Update visual state
        for thumb in self.thumbnails:
            thumb.set_selected(thumb.asset in self.selected_assets)

        self.on_select(list(self.selected_assets))

    def _on_thumbnail_double_click(self, asset: AssetInfo):
        self.on_double_click(asset)

    def _on_thumbnail_right_click(self, asset: AssetInfo, event):
        # Ensure asset is selected
        if asset not in self.selected_assets:
            self.selected_assets.clear()
            self.selected_assets.add(asset)
            for thumb in self.thumbnails:
                thumb.set_selected(thumb.asset in self.selected_assets)

        self.on_right_click(list(self.selected_assets), event)

    def select_all(self):
        self.selected_assets = set(thumb.asset for thumb in self.thumbnails)
        for thumb in self.thumbnails:
            thumb.set_selected(True)
        self.on_select(list(self.selected_assets))

    def clear_selection(self):
        self.selected_assets.clear()
        for thumb in self.thumbnails:
            thumb.set_selected(False)
        self.on_select([])


# ============================================================================
# Details Panel
# ============================================================================

class AssetDetailsPanel(ctk.CTkFrame):
    """Panel showing details of selected assets."""

    def __init__(self, master, on_action):
        super().__init__(master, corner_radius=12, fg_color=COLORS["bg_medium"])

        self.on_action = on_action
        self.current_assets: List[AssetInfo] = []
        self._photo = None
        self._gif_frames = []
        self._gif_index = 0
        self._gif_playing = False

        # Header
        self.header = ctk.CTkLabel(self, text="Asset Details",
                                    font=("Segoe UI", 16, "bold"),
                                    text_color=COLORS["text"])
        self.header.pack(anchor="w", padx=15, pady=(15, 10))

        # Preview container
        self.preview_frame = ctk.CTkFrame(self, fg_color=COLORS["bg_dark"],
                                           corner_radius=10, height=250)
        self.preview_frame.pack(fill="x", padx=15, pady=5)
        self.preview_frame.pack_propagate(False)

        self.preview_label = ctk.CTkLabel(self.preview_frame,
                                           text="Select an asset\nto preview",
                                           font=("Segoe UI", 12),
                                           text_color=COLORS["text_muted"])
        self.preview_label.place(relx=0.5, rely=0.5, anchor="center")

        # Info section
        self.info_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.info_frame.pack(fill="x", padx=15, pady=10)

        self.name_label = ctk.CTkLabel(self.info_frame, text="",
                                        font=("Segoe UI", 14, "bold"),
                                        text_color=COLORS["text"],
                                        wraplength=280)
        self.name_label.pack(anchor="w")

        self.details_label = ctk.CTkLabel(self.info_frame, text="",
                                           font=("Segoe UI", 11),
                                           text_color=COLORS["text_muted"],
                                           justify="left")
        self.details_label.pack(anchor="w", pady=(5, 0))

        # Mapping section
        self.mapping_header = ctk.CTkLabel(self, text="Code Mapping",
                                            font=("Segoe UI", 13, "bold"),
                                            text_color=COLORS["text"])
        self.mapping_header.pack(anchor="w", padx=15, pady=(10, 5))

        self.mapping_text = ctk.CTkTextbox(self, height=120,
                                            font=("Consolas", 10),
                                            fg_color=COLORS["bg_dark"],
                                            text_color=COLORS["text"])
        self.mapping_text.pack(fill="x", padx=15, pady=(0, 10))

        # Quick actions
        self.actions_label = ctk.CTkLabel(self, text="Quick Actions",
                                           font=("Segoe UI", 13, "bold"),
                                           text_color=COLORS["text"])
        self.actions_label.pack(anchor="w", padx=15, pady=(5, 5))

        self.actions_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.actions_frame.pack(fill="x", padx=15, pady=(0, 15))

        # Action buttons
        btn_style = {"width": 90, "height": 32, "corner_radius": 8,
                     "font": ("Segoe UI", 11)}

        self.btn_open = ctk.CTkButton(self.actions_frame, text="📂 Open",
                                       command=lambda: self.on_action("open"),
                                       fg_color=COLORS["bg_light"], **btn_style)
        self.btn_open.grid(row=0, column=0, padx=3, pady=3)

        self.btn_copy = ctk.CTkButton(self.actions_frame, text="📋 Copy",
                                       command=lambda: self.on_action("copy"),
                                       fg_color=COLORS["bg_light"], **btn_style)
        self.btn_copy.grid(row=0, column=1, padx=3, pady=3)

        self.btn_rename = ctk.CTkButton(self.actions_frame, text="✏️ Rename",
                                         command=lambda: self.on_action("rename"),
                                         fg_color=COLORS["bg_light"], **btn_style)
        self.btn_rename.grid(row=0, column=2, padx=3, pady=3)

        self.btn_move = ctk.CTkButton(self.actions_frame, text="📁 Move",
                                       command=lambda: self.on_action("move"),
                                       fg_color=COLORS["bg_light"], **btn_style)
        self.btn_move.grid(row=1, column=0, padx=3, pady=3)

        self.btn_duplicate = ctk.CTkButton(self.actions_frame, text="📑 Duplicate",
                                            command=lambda: self.on_action("duplicate"),
                                            fg_color=COLORS["bg_light"], **btn_style)
        self.btn_duplicate.grid(row=1, column=1, padx=3, pady=3)

        self.btn_delete = ctk.CTkButton(self.actions_frame, text="🗑️ Delete",
                                         command=lambda: self.on_action("delete"),
                                         fg_color=COLORS["accent"],
                                         hover_color=COLORS["accent_hover"],
                                         **btn_style)
        self.btn_delete.grid(row=1, column=2, padx=3, pady=3)

    def show_assets(self, assets: List[AssetInfo]):
        self.current_assets = assets
        self._stop_gif()

        if not assets:
            self.preview_label.configure(image=None,
                                          text="Select an asset\nto preview")
            self.name_label.configure(text="")
            self.details_label.configure(text="")
            self.mapping_text.delete("1.0", "end")
            return

        if len(assets) == 1:
            self._show_single_asset(assets[0])
        else:
            self._show_multiple_assets(assets)

    def _show_single_asset(self, asset: AssetInfo):
        # Load preview
        try:
            img = Image.open(asset.path)

            # Check for animated GIF
            if hasattr(img, 'n_frames') and img.n_frames > 1:
                self._load_gif_animation(asset.path)
            else:
                img.thumbnail((230, 230), Image.Resampling.LANCZOS)
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                self._photo = ctk.CTkImage(light_image=img, dark_image=img,
                                            size=(img.width, img.height))
                self.preview_label.configure(image=self._photo, text="")

        except Exception as e:
            self.preview_label.configure(image=None, text=f"Error: {e}")

        # Update info
        self.name_label.configure(text=asset.display_name)

        details = f"📁 {asset.category}\n"
        details += f"📐 {asset.size[0]} × {asset.size[1]} px\n"
        details += f"💾 {asset.file_size / 1024:.1f} KB\n"
        details += f"📅 {datetime.fromtimestamp(asset.modified_time).strftime('%Y-%m-%d %H:%M')}"
        self.details_label.configure(text=details)

        # Update mapping
        self.mapping_text.delete("1.0", "end")
        if asset.mapping:
            self.mapping_text.insert("1.0", json.dumps(asset.mapping, indent=2))
        else:
            self.mapping_text.insert("1.0",
                "⚠️ No mapping found\n\n"
                "This asset is not referenced in kitchenData.ts")

    def _show_multiple_assets(self, assets: List[AssetInfo]):
        self.preview_label.configure(image=None,
                                      text=f"📦 {len(assets)} assets selected")

        total_size = sum(a.file_size for a in assets)
        mapped = sum(1 for a in assets if a.is_mapped)

        self.name_label.configure(text=f"{len(assets)} Assets Selected")

        details = f"✓ {mapped} mapped, ○ {len(assets) - mapped} unmapped\n"
        details += f"💾 Total: {total_size / 1024:.1f} KB"
        self.details_label.configure(text=details)

        self.mapping_text.delete("1.0", "end")
        self.mapping_text.insert("1.0", "Multiple assets selected.\n"
                                  "Use bulk actions to manage them.")

    def _load_gif_animation(self, path):
        """Load and play animated GIF."""
        try:
            img = Image.open(path)
            self._gif_frames = []

            for frame in range(img.n_frames):
                img.seek(frame)
                frame_img = img.copy()
                frame_img.thumbnail((230, 230), Image.Resampling.LANCZOS)
                if frame_img.mode != 'RGBA':
                    frame_img = frame_img.convert('RGBA')
                photo = ctk.CTkImage(light_image=frame_img, dark_image=frame_img,
                                      size=(frame_img.width, frame_img.height))
                self._gif_frames.append(photo)

            self._gif_index = 0
            self._gif_playing = True
            self._animate_gif()

        except Exception:
            pass

    def _animate_gif(self):
        if not self._gif_playing or not self._gif_frames:
            return

        self.preview_label.configure(image=self._gif_frames[self._gif_index], text="")
        self._gif_index = (self._gif_index + 1) % len(self._gif_frames)
        self.after(100, self._animate_gif)

    def _stop_gif(self):
        self._gif_playing = False
        self._gif_frames = []


# ============================================================================
# Context Menu
# ============================================================================

class ContextMenu(tk.Menu):
    """Right-click context menu for assets."""

    def __init__(self, master, on_action):
        super().__init__(master, tearoff=0, bg=COLORS["bg_medium"],
                         fg=COLORS["text"], activebackground=COLORS["accent"],
                         activeforeground="white", font=("Segoe UI", 10))

        self.on_action = on_action

        self.add_command(label="📂 Open in Explorer", command=lambda: on_action("open"))
        self.add_command(label="📋 Copy Path", command=lambda: on_action("copy"))
        self.add_separator()
        self.add_command(label="✏️ Rename", command=lambda: on_action("rename"))
        self.add_command(label="📑 Duplicate", command=lambda: on_action("duplicate"))
        self.add_command(label="📁 Move to Category...", command=lambda: on_action("move"))
        self.add_separator()
        self.add_command(label="🗑️ Delete", command=lambda: on_action("delete"))

    def show(self, event):
        try:
            self.tk_popup(event.x_root, event.y_root)
        finally:
            self.grab_release()


# ============================================================================
# Dialogs
# ============================================================================

class RenameDialog(ctk.CTkToplevel):
    """Dialog for renaming an asset."""

    def __init__(self, master, current_name: str, on_rename):
        super().__init__(master)
        self.title("Rename Asset")
        self.geometry("400x150")
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=COLORS["bg_dark"])

        self.on_rename = on_rename
        self.result = None

        # Center on parent
        self.update_idletasks()
        x = master.winfo_x() + (master.winfo_width() // 2) - 200
        y = master.winfo_y() + (master.winfo_height() // 2) - 75
        self.geometry(f"+{x}+{y}")

        ctk.CTkLabel(self, text="Enter new name:",
                     font=("Segoe UI", 12)).pack(anchor="w", padx=20, pady=(20, 5))

        self.name_var = ctk.StringVar(value=current_name.rsplit('.', 1)[0])
        self.entry = ctk.CTkEntry(self, textvariable=self.name_var, width=360)
        self.entry.pack(padx=20, pady=5)
        self.entry.select_range(0, 'end')
        self.entry.focus()

        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(pady=20)

        ctk.CTkButton(btn_frame, text="Cancel", width=100,
                      fg_color=COLORS["bg_light"],
                      command=self.destroy).pack(side="left", padx=10)
        ctk.CTkButton(btn_frame, text="Rename", width=100,
                      fg_color=COLORS["accent"],
                      command=self._do_rename).pack(side="left", padx=10)

        self.entry.bind("<Return>", lambda e: self._do_rename())
        self.bind("<Escape>", lambda e: self.destroy())

    def _do_rename(self):
        new_name = self.name_var.get().strip()
        if new_name:
            self.on_rename(new_name)
        self.destroy()


class MoveDialog(ctk.CTkToplevel):
    """Dialog for moving assets to another category."""

    def __init__(self, master, categories: List[str], on_move):
        super().__init__(master)
        self.title("Move to Category")
        self.geometry("350x200")
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=COLORS["bg_dark"])

        self.on_move = on_move

        ctk.CTkLabel(self, text="Select target category:",
                     font=("Segoe UI", 12)).pack(anchor="w", padx=20, pady=(20, 10))

        self.category_var = ctk.StringVar(value=categories[0])
        for cat in categories:
            display_name = ASSET_CATEGORIES.get(cat, (cat, ""))[0]
            ctk.CTkRadioButton(self, text=display_name, variable=self.category_var,
                               value=cat).pack(anchor="w", padx=30, pady=2)

        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(pady=20)

        ctk.CTkButton(btn_frame, text="Cancel", width=100,
                      fg_color=COLORS["bg_light"],
                      command=self.destroy).pack(side="left", padx=10)
        ctk.CTkButton(btn_frame, text="Move", width=100,
                      fg_color=COLORS["accent"],
                      command=self._do_move).pack(side="left", padx=10)

    def _do_move(self):
        self.on_move(self.category_var.get())
        self.destroy()


class ExportDialog(ctk.CTkToplevel):
    """Dialog for exporting asset report."""

    def __init__(self, master, stats: Dict, on_export):
        super().__init__(master)
        self.title("Export Asset Report")
        self.geometry("450x350")
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=COLORS["bg_dark"])

        self.on_export = on_export

        ctk.CTkLabel(self, text="Export Asset Report",
                     font=("Segoe UI", 16, "bold")).pack(pady=(20, 10))

        # Stats preview
        stats_frame = ctk.CTkFrame(self, fg_color=COLORS["bg_medium"],
                                    corner_radius=10)
        stats_frame.pack(fill="x", padx=20, pady=10)

        total = sum(stats.values())
        ctk.CTkLabel(stats_frame, text=f"Total Assets: {total}",
                     font=("Segoe UI", 12, "bold")).pack(pady=10)

        for cat, count in sorted(stats.items()):
            name = ASSET_CATEGORIES.get(cat, (cat, ""))[0]
            ctk.CTkLabel(stats_frame, text=f"{name}: {count}",
                         font=("Segoe UI", 11),
                         text_color=COLORS["text_muted"]).pack()

        # Export options
        ctk.CTkLabel(self, text="Export Format:",
                     font=("Segoe UI", 12)).pack(anchor="w", padx=20, pady=(20, 5))

        self.format_var = ctk.StringVar(value="csv")
        formats_frame = ctk.CTkFrame(self, fg_color="transparent")
        formats_frame.pack(anchor="w", padx=20)

        ctk.CTkRadioButton(formats_frame, text="CSV", variable=self.format_var,
                           value="csv").pack(side="left", padx=10)
        ctk.CTkRadioButton(formats_frame, text="JSON", variable=self.format_var,
                           value="json").pack(side="left", padx=10)

        # Buttons
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(pady=20)

        ctk.CTkButton(btn_frame, text="Cancel", width=100,
                      fg_color=COLORS["bg_light"],
                      command=self.destroy).pack(side="left", padx=10)
        ctk.CTkButton(btn_frame, text="Export", width=100,
                      fg_color=COLORS["success"],
                      command=self._do_export).pack(side="left", padx=10)

    def _do_export(self):
        self.on_export(self.format_var.get())
        self.destroy()


# ============================================================================
# Main Application
# ============================================================================

class AssetLoaderApp(ctk.CTk if not DND_AVAILABLE else TkinterDnD.Tk):
    """Main application window."""

    def __init__(self):
        super().__init__()

        self.title("Kitchen Diary Asset Loader")
        self.geometry("1500x950")
        self.minsize(1200, 750)
        if DND_AVAILABLE:
            self.configure(bg=COLORS["bg_dark"])
        else:
            self.configure(fg_color=COLORS["bg_dark"])

        # Find project paths
        self.project_root = self._find_project_root()
        self.kitchen_images_path = self.project_root / "kitchen_images"
        self.kitchen_data_path = self.project_root / "data" / "kitchenData.ts"
        self.prompts_path = self.kitchen_images_path / "kitchen_video_prompts.json"

        # Initialize parser
        self.data_parser = KitchenDataParser(self.kitchen_data_path)
        self.video_prompts = self._load_video_prompts()

        # State
        self.all_assets: Dict[str, List[AssetInfo]] = {}
        self.filtered_assets: List[AssetInfo] = []
        self.current_category = "actions"
        self.current_sort = SortOption.NAME_ASC
        self.current_filter = FilterOption.ALL
        self.thumbnail_size = 100

        # Setup UI
        self._setup_ui()
        self._setup_drag_drop()

        # Load assets
        self._load_all_assets()
        self._show_category("actions")

        # Validate required paths
        self._check_required_paths()

    def _find_project_root(self) -> Path:
        current = Path(__file__).parent.parent
        if (current / "kitchen_images").exists():
            return current
        cwd = Path.cwd()
        if (cwd / "kitchen_images").exists():
            return cwd
        for parent in Path(__file__).parents:
            if (parent / "kitchen_images").exists():
                return parent
        return Path.cwd()

    def _load_video_prompts(self) -> Dict:
        try:
            if self.prompts_path.exists():
                return json.loads(self.prompts_path.read_text(encoding='utf-8'))
        except:
            pass
        return {}

    def _check_required_paths(self):
        missing = []
        if not self.kitchen_images_path.exists():
            missing.append(str(self.kitchen_images_path))
        if not self.kitchen_data_path.exists():
            missing.append(str(self.kitchen_data_path))

        if missing:
            messagebox.showwarning(
                "Missing Project Files",
                "The following required paths are missing:\n\n"
                + "\n".join(missing)
                + "\n\nThe app will still run, but mappings may be empty until these exist."
            )

    def _setup_ui(self):
        """Setup the main UI layout."""
        # Grid configuration
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # ========== Sidebar ==========
        self.sidebar = ctk.CTkFrame(self, width=240, corner_radius=0,
                                     fg_color=COLORS["bg_medium"])
        self.sidebar.grid(row=0, column=0, sticky="nsw")
        self.sidebar.grid_rowconfigure(20, weight=1)
        self.sidebar.grid_propagate(False)

        # Logo
        logo_frame = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        logo_frame.grid(row=0, column=0, padx=15, pady=(20, 25), sticky="ew")

        ctk.CTkLabel(logo_frame, text="🍳", font=("Segoe UI", 32)).pack(side="left")
        title_frame = ctk.CTkFrame(logo_frame, fg_color="transparent")
        title_frame.pack(side="left", padx=10)
        ctk.CTkLabel(title_frame, text="Kitchen Diary",
                     font=("Segoe UI", 16, "bold"),
                     text_color=COLORS["text"]).pack(anchor="w")
        ctk.CTkLabel(title_frame, text="Asset Loader",
                     font=("Segoe UI", 11),
                     text_color=COLORS["text_muted"]).pack(anchor="w")

        # Categories header
        ctk.CTkLabel(self.sidebar, text="CATEGORIES",
                     font=("Segoe UI", 10, "bold"),
                     text_color=COLORS["text_muted"]).grid(row=1, column=0,
                                                           padx=20, pady=(10, 5),
                                                           sticky="w")

        # Category buttons
        self.category_buttons: Dict[str, ctk.CTkButton] = {}
        for i, (cat_id, (cat_name, cat_icon)) in enumerate(ASSET_CATEGORIES.items()):
            btn = ctk.CTkButton(self.sidebar,
                                 text=f" {cat_icon}  {cat_name}",
                                 command=lambda c=cat_id: self._show_category(c),
                                 fg_color="transparent",
                                 text_color=COLORS["text"],
                                 hover_color=COLORS["bg_light"],
                                 anchor="w", height=36,
                                 font=("Segoe UI", 12))
            btn.grid(row=i+2, column=0, padx=10, pady=1, sticky="ew")
            self.category_buttons[cat_id] = btn

        # Stats section
        stats_header = ctk.CTkLabel(self.sidebar, text="STATISTICS",
                                     font=("Segoe UI", 10, "bold"),
                                     text_color=COLORS["text_muted"])
        stats_header.grid(row=15, column=0, padx=20, pady=(20, 5), sticky="w")

        self.stats_frame = ctk.CTkFrame(self.sidebar, fg_color=COLORS["bg_dark"],
                                         corner_radius=10)
        self.stats_frame.grid(row=16, column=0, padx=10, pady=5, sticky="ew")

        self.stats_labels: Dict[str, ctk.CTkLabel] = {}

        # Action buttons at bottom
        actions_frame = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        actions_frame.grid(row=21, column=0, padx=10, pady=15, sticky="sew")

        self.import_btn = ctk.CTkButton(actions_frame, text="📥 Import Assets",
                                         command=self._show_import_zone,
                                         fg_color=COLORS["accent"],
                                         hover_color=COLORS["accent_hover"],
                                         height=40, font=("Segoe UI", 12, "bold"))
        self.import_btn.pack(fill="x", pady=5)

        self.export_btn = ctk.CTkButton(actions_frame, text="📊 Export Report",
                                         command=self._show_export_dialog,
                                         fg_color=COLORS["bg_light"],
                                         height=36, font=("Segoe UI", 11))
        self.export_btn.pack(fill="x", pady=5)

        # ========== Main Content ==========
        self.main_frame = ctk.CTkFrame(self, corner_radius=0,
                                        fg_color=COLORS["bg_dark"])
        self.main_frame.grid(row=0, column=1, sticky="nsew", padx=0, pady=0)
        self.main_frame.grid_columnconfigure(0, weight=1)
        self.main_frame.grid_rowconfigure(2, weight=1)

        # Toolbar
        self.toolbar = ctk.CTkFrame(self.main_frame, fg_color=COLORS["bg_medium"],
                                     height=60, corner_radius=0)
        self.toolbar.grid(row=0, column=0, columnspan=2, sticky="ew")
        self.toolbar.grid_propagate(False)

        # Category title
        self.category_title = ctk.CTkLabel(self.toolbar, text="Cooking Actions",
                                            font=("Segoe UI", 20, "bold"),
                                            text_color=COLORS["text"])
        self.category_title.pack(side="left", padx=20, pady=15)

        self.asset_count_label = ctk.CTkLabel(self.toolbar, text="",
                                               font=("Segoe UI", 11),
                                               text_color=COLORS["text_muted"])
        self.asset_count_label.pack(side="left", padx=5)

        # Right side toolbar items
        toolbar_right = ctk.CTkFrame(self.toolbar, fg_color="transparent")
        toolbar_right.pack(side="right", padx=15)

        # Zoom slider
        self.zoom_slider = ZoomSlider(toolbar_right, self._on_zoom_change)
        self.zoom_slider.pack(side="right", padx=10)

        # Sort dropdown
        self.sort_var = ctk.StringVar(value=SortOption.NAME_ASC.value)
        self.sort_menu = ctk.CTkOptionMenu(toolbar_right,
                                            values=[s.value for s in SortOption],
                                            variable=self.sort_var,
                                            command=self._on_sort_change,
                                            width=140)
        self.sort_menu.pack(side="right", padx=5)
        ctk.CTkLabel(toolbar_right, text="Sort:",
                     font=("Segoe UI", 11)).pack(side="right", padx=(10, 5))

        # Filter dropdown
        self.filter_var = ctk.StringVar(value=FilterOption.ALL.value)
        self.filter_menu = ctk.CTkOptionMenu(toolbar_right,
                                              values=[f.value for f in FilterOption],
                                              variable=self.filter_var,
                                              command=self._on_filter_change,
                                              width=120)
        self.filter_menu.pack(side="right", padx=5)
        ctk.CTkLabel(toolbar_right, text="Filter:",
                     font=("Segoe UI", 11)).pack(side="right", padx=(10, 5))

        # Search bar
        self.search_frame = ctk.CTkFrame(self.main_frame, fg_color="transparent",
                                          height=50)
        self.search_frame.grid(row=1, column=0, columnspan=2, sticky="ew",
                               padx=15, pady=10)

        self.search_var = ctk.StringVar()
        self.search_var.trace_add("write", self._on_search)
        self.search_entry = ctk.CTkEntry(self.search_frame, width=400,
                                          height=40, corner_radius=20,
                                          placeholder_text="🔍 Search assets...",
                                          textvariable=self.search_var,
                                          font=("Segoe UI", 12))
        self.search_entry.pack(side="left")

        # Select all / Clear selection buttons
        self.select_all_btn = ctk.CTkButton(self.search_frame, text="Select All",
                                             command=self._select_all,
                                             fg_color=COLORS["bg_light"],
                                             width=90, height=36)
        self.select_all_btn.pack(side="left", padx=(15, 5))

        self.clear_sel_btn = ctk.CTkButton(self.search_frame, text="Clear",
                                            command=self._clear_selection,
                                            fg_color=COLORS["bg_light"],
                                            width=70, height=36)
        self.clear_sel_btn.pack(side="left", padx=5)

        self.refresh_btn = ctk.CTkButton(self.search_frame, text="🔄 Refresh",
                                          command=self._refresh_assets,
                                          fg_color=COLORS["bg_light"],
                                          width=90, height=36)
        self.refresh_btn.pack(side="right", padx=5)

        # Content area (browser + details)
        self.content_frame = ctk.CTkFrame(self.main_frame, fg_color="transparent")
        self.content_frame.grid(row=2, column=0, sticky="nsew", padx=15, pady=(0, 15))
        self.content_frame.grid_columnconfigure(0, weight=3)
        self.content_frame.grid_columnconfigure(1, weight=0)
        self.content_frame.grid_rowconfigure(0, weight=1)

        # Asset browser
        self.asset_browser = AssetBrowser(self.content_frame,
                                           self._on_asset_select,
                                           self._on_asset_double_click,
                                           self._on_asset_right_click)
        self.asset_browser.grid(row=0, column=0, sticky="nsew", padx=(0, 10))

        # Details panel
        self.details_panel = AssetDetailsPanel(self.content_frame,
                                                self._handle_asset_action)
        self.details_panel.grid(row=0, column=1, sticky="nsew")

        # Drop zone (initially hidden)
        self.drop_zone = None

        # Context menu
        self.context_menu = ContextMenu(self, self._handle_asset_action)

        # Status bar
        self.status_var = ctk.StringVar(value="Ready")
        self.status_bar = ctk.CTkLabel(self.main_frame, textvariable=self.status_var,
                                        font=("Segoe UI", 10),
                                        text_color=COLORS["text_muted"])
        self.status_bar.grid(row=3, column=0, sticky="w", padx=15, pady=(0, 10))

    def _setup_drag_drop(self):
        """Setup drag and drop support."""
        if DND_AVAILABLE:
            self.drop_target_register(DND_FILES)
            self.dnd_bind('<<Drop>>', self._on_drop)
            self.dnd_bind('<<DragEnter>>', self._on_drag_enter)
            self.dnd_bind('<<DragLeave>>', self._on_drag_leave)

    def _on_drop(self, event):
        """Handle file drop."""
        files = self.tk.splitlist(event.data)
        valid_files = [f for f in files
                       if Path(f).suffix.lower() in ['.png', '.jpg', '.jpeg', '.gif', '.webp']]
        if valid_files:
            self._import_files(valid_files)

        if self.drop_zone:
            self.drop_zone.highlight(False)

    def _on_drag_enter(self, event):
        if self.drop_zone:
            self.drop_zone.highlight(True)

    def _on_drag_leave(self, event):
        if self.drop_zone:
            self.drop_zone.highlight(False)

    def _load_all_assets(self):
        """Load all assets from kitchen_images directory."""
        self.all_assets.clear()
        stats = {}

        for cat_id in ASSET_CATEGORIES.keys():
            cat_path = self.kitchen_images_path / cat_id
            if not cat_path.exists():
                stats[cat_id] = 0
                self.all_assets[cat_id] = []
                continue

            assets = []
            for file_path in cat_path.glob("*"):
                if file_path.suffix.lower() in ['.png', '.jpg', '.jpeg', '.gif', '.webp']:
                    try:
                        img = Image.open(file_path)
                        size = img.size
                        img.close()

                        mapping = self.data_parser.get_mapping_for_asset(
                            file_path.name, cat_id)

                        # Add video prompts
                        if cat_id == "actions":
                            key = file_path.stem
                            if key in self.video_prompts.get('actions', {}):
                                mapping = mapping or {}
                                mapping['video_prompt'] = self.video_prompts['actions'][key]
                        elif cat_id == "cuisines":
                            key = file_path.stem
                            if key in self.video_prompts.get('cuisines', {}):
                                mapping = mapping or {}
                                mapping['video_prompt'] = self.video_prompts['cuisines'][key]

                        stat = file_path.stat()
                        asset = AssetInfo(
                            path=file_path,
                            name=file_path.name,
                            category=cat_id,
                            size=size,
                            file_size=stat.st_size,
                            modified_time=stat.st_mtime,
                            mapping=mapping
                        )
                        assets.append(asset)
                    except Exception as e:
                        print(f"Error loading {file_path}: {e}")

            self.all_assets[cat_id] = assets
            stats[cat_id] = len(assets)

        self._update_stats(stats)

    def _update_stats(self, stats: Dict[str, int]):
        """Update statistics display."""
        for label in self.stats_labels.values():
            label.destroy()
        self.stats_labels.clear()

        total = sum(stats.values())
        mapped = sum(1 for assets in self.all_assets.values()
                     for a in assets if a.is_mapped)

        row = 0
        self.stats_labels['total'] = ctk.CTkLabel(
            self.stats_frame, text=f"📦 Total: {total}",
            font=("Segoe UI", 12, "bold"))
        self.stats_labels['total'].grid(row=row, column=0, padx=10, pady=(10, 2), sticky="w")
        row += 1

        self.stats_labels['mapped'] = ctk.CTkLabel(
            self.stats_frame, text=f"✓ Mapped: {mapped}",
            font=("Segoe UI", 11), text_color=COLORS["success"])
        self.stats_labels['mapped'].grid(row=row, column=0, padx=10, pady=2, sticky="w")
        row += 1

        self.stats_labels['unmapped'] = ctk.CTkLabel(
            self.stats_frame, text=f"○ Unmapped: {total - mapped}",
            font=("Segoe UI", 11), text_color=COLORS["warning"])
        self.stats_labels['unmapped'].grid(row=row, column=0, padx=10, pady=(2, 10), sticky="w")

    def _show_category(self, category: str):
        """Show assets for a specific category."""
        self.current_category = category

        # Update button states
        for cat_id, btn in self.category_buttons.items():
            if cat_id == category:
                btn.configure(fg_color=COLORS["bg_light"])
            else:
                btn.configure(fg_color="transparent")

        # Update title
        cat_name, cat_icon = ASSET_CATEGORIES.get(category, (category, ""))
        self.category_title.configure(text=f"{cat_icon} {cat_name}")

        # Apply filters and show
        self._apply_filters_and_show()

    def _apply_filters_and_show(self):
        """Apply current filters and sorting, then display assets."""
        assets = self.all_assets.get(self.current_category, []).copy()

        # Apply search filter
        query = self.search_var.get().lower()
        if query:
            assets = [a for a in assets if query in a.name.lower()]

        # Apply mapping filter
        if self.current_filter == FilterOption.MAPPED:
            assets = [a for a in assets if a.is_mapped]
        elif self.current_filter == FilterOption.UNMAPPED:
            assets = [a for a in assets if not a.is_mapped]

        # Apply sorting
        if self.current_sort == SortOption.NAME_ASC:
            assets.sort(key=lambda a: a.name.lower())
        elif self.current_sort == SortOption.NAME_DESC:
            assets.sort(key=lambda a: a.name.lower(), reverse=True)
        elif self.current_sort == SortOption.SIZE_ASC:
            assets.sort(key=lambda a: a.file_size)
        elif self.current_sort == SortOption.SIZE_DESC:
            assets.sort(key=lambda a: a.file_size, reverse=True)
        elif self.current_sort == SortOption.DATE_ASC:
            assets.sort(key=lambda a: a.modified_time)
        elif self.current_sort == SortOption.DATE_DESC:
            assets.sort(key=lambda a: a.modified_time, reverse=True)

        self.filtered_assets = assets
        self.asset_browser.load_assets(assets)

        total = len(self.all_assets.get(self.current_category, []))
        showing = len(assets)
        self.asset_count_label.configure(text=f"({showing} of {total})")
        self.status_var.set(f"Showing {showing} assets")

    def _on_search(self, *args):
        self._apply_filters_and_show()

    def _on_sort_change(self, value):
        for opt in SortOption:
            if opt.value == value:
                self.current_sort = opt
                break
        self._apply_filters_and_show()

    def _on_filter_change(self, value):
        for opt in FilterOption:
            if opt.value == value:
                self.current_filter = opt
                break
        self._apply_filters_and_show()

    def _on_zoom_change(self, value):
        self.thumbnail_size = int(value)
        self.zoom_slider.update_label(value)
        self.asset_browser.set_thumbnail_size(self.thumbnail_size)
        self._apply_filters_and_show()

    def _on_asset_select(self, assets: List[AssetInfo]):
        self.details_panel.show_assets(assets)

    def _on_asset_double_click(self, asset: AssetInfo):
        # Open in default image viewer
        self._open_path(asset.path)

    def _on_asset_right_click(self, assets: List[AssetInfo], event):
        self.context_menu.show(event)

    def _select_all(self):
        self.asset_browser.select_all()

    def _clear_selection(self):
        self.asset_browser.clear_selection()

    def _refresh_assets(self):
        self._load_all_assets()
        self._apply_filters_and_show()
        self.status_var.set("Assets refreshed")

    def _handle_asset_action(self, action: str):
        """Handle asset actions from details panel or context menu."""
        assets = self.details_panel.current_assets

        if not assets:
            return

        if action == "open":
            self._open_path(assets[0].path.parent)

        elif action == "copy":
            paths = "\n".join(str(a.path) for a in assets)
            self.clipboard_clear()
            self.clipboard_append(paths)
            self.status_var.set(f"Copied {len(assets)} path(s) to clipboard")

        elif action == "rename":
            if len(assets) == 1:
                RenameDialog(self, assets[0].name,
                             lambda n: self._do_rename(assets[0], n))

        elif action == "duplicate":
            for asset in assets:
                self._do_duplicate(asset)
            self._refresh_assets()

        elif action == "move":
            categories = [c for c in ASSET_CATEGORIES.keys()
                          if c != self.current_category]
            MoveDialog(self, categories,
                       lambda c: self._do_move(assets, c))

        elif action == "delete":
            if messagebox.askyesno("Confirm Delete",
                                    f"Delete {len(assets)} asset(s)?"):
                for asset in assets:
                    try:
                        os.remove(asset.path)
                    except Exception as e:
                        messagebox.showerror("Error", f"Failed to delete {asset.name}: {e}")
                self._refresh_assets()

    def _do_rename(self, asset: AssetInfo, new_name: str):
        """Rename an asset."""
        ext = asset.path.suffix
        new_path = asset.path.parent / f"{new_name}{ext}"

        if new_path.exists():
            messagebox.showerror("Error", "A file with that name already exists.")
            return

        try:
            asset.path.rename(new_path)
            self._refresh_assets()
            self.status_var.set(f"Renamed to {new_name}{ext}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to rename: {e}")

    def _do_duplicate(self, asset: AssetInfo):
        """Duplicate an asset."""
        base = asset.path.stem
        ext = asset.path.suffix
        counter = 1
        new_path = asset.path.parent / f"{base}_copy{ext}"

        while new_path.exists():
            counter += 1
            new_path = asset.path.parent / f"{base}_copy{counter}{ext}"

        try:
            shutil.copy2(asset.path, new_path)
            self.status_var.set(f"Created {new_path.name}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to duplicate: {e}")

    def _do_move(self, assets: List[AssetInfo], target_category: str):
        """Move assets to another category."""
        target_dir = self.kitchen_images_path / target_category
        target_dir.mkdir(parents=True, exist_ok=True)

        moved = 0
        for asset in assets:
            try:
                new_path = target_dir / asset.name
                if new_path.exists():
                    # Add suffix
                    base = asset.path.stem
                    ext = asset.path.suffix
                    counter = 1
                    while new_path.exists():
                        new_path = target_dir / f"{base}_{counter}{ext}"
                        counter += 1

                shutil.move(asset.path, new_path)
                moved += 1
            except Exception as e:
                messagebox.showerror("Error", f"Failed to move {asset.name}: {e}")

        self._refresh_assets()
        self.status_var.set(f"Moved {moved} asset(s) to {ASSET_CATEGORIES[target_category][0]}")

    def _show_import_zone(self):
        """Show/toggle import drop zone."""
        if self.drop_zone and self.drop_zone.winfo_exists():
            self.drop_zone.destroy()
            self.drop_zone = None
        else:
            self.drop_zone = DropZone(self.search_frame, self._import_files, DND_AVAILABLE)
            self.drop_zone.pack(side="left", padx=20, fill="x", expand=True)

    def _open_path(self, path: Path):
        try:
            os.startfile(path)
        except Exception as e:
            messagebox.showerror("Open Error", f"Failed to open {path}: {e}")

    def _import_files(self, files: List[str]):
        """Import files to current category."""
        target_dir = self.kitchen_images_path / self.current_category
        target_dir.mkdir(parents=True, exist_ok=True)

        imported = 0
        for file_path in files:
            try:
                src = Path(file_path)
                dest = target_dir / src.name

                if dest.exists():
                    base = src.stem
                    ext = src.suffix
                    counter = 1
                    while dest.exists():
                        dest = target_dir / f"{base}_{counter}{ext}"
                        counter += 1

                shutil.copy2(src, dest)
                imported += 1
            except Exception as e:
                messagebox.showerror("Import Error", f"Failed to import {src.name}: {e}")

        if imported > 0:
            self._refresh_assets()
            self.status_var.set(f"Imported {imported} asset(s)")

        # Hide drop zone
        if self.drop_zone:
            self.drop_zone.destroy()
            self.drop_zone = None

    def _show_export_dialog(self):
        """Show export report dialog."""
        stats = {cat: len(assets) for cat, assets in self.all_assets.items()}
        ExportDialog(self, stats, self._do_export)

    def _do_export(self, format_type: str):
        """Export asset report."""
        file_path = filedialog.asksaveasfilename(
            title="Save Report",
            defaultextension=f".{format_type}",
            filetypes=[(f"{format_type.upper()} files", f"*.{format_type}")]
        )

        if not file_path:
            return

        try:
            all_assets = []
            for assets in self.all_assets.values():
                all_assets.extend(assets)

            if format_type == "csv":
                with open(file_path, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    writer.writerow(['Name', 'Category', 'Path', 'Size (KB)',
                                     'Dimensions', 'Mapped', 'Mapping'])
                    for asset in all_assets:
                        writer.writerow([
                            asset.name,
                            asset.category,
                            str(asset.path),
                            f"{asset.file_size / 1024:.1f}",
                            f"{asset.size[0]}x{asset.size[1]}",
                            "Yes" if asset.is_mapped else "No",
                            json.dumps(asset.mapping) if asset.mapping else ""
                        ])

            elif format_type == "json":
                data = {
                    "exported_at": datetime.now().isoformat(),
                    "total_assets": len(all_assets),
                    "categories": {},
                    "assets": []
                }

                for cat, assets in self.all_assets.items():
                    data["categories"][cat] = {
                        "name": ASSET_CATEGORIES[cat][0],
                        "count": len(assets)
                    }

                for asset in all_assets:
                    data["assets"].append({
                        "name": asset.name,
                        "category": asset.category,
                        "path": str(asset.path),
                        "size_kb": round(asset.file_size / 1024, 1),
                        "dimensions": list(asset.size),
                        "is_mapped": asset.is_mapped,
                        "mapping": asset.mapping
                    })

                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2)

            self.status_var.set(f"Report exported to {file_path}")
            messagebox.showinfo("Export Complete", f"Report saved to:\n{file_path}")

        except Exception as e:
            messagebox.showerror("Export Error", f"Failed to export: {e}")


def main():
    app = AssetLoaderApp()
    app.mainloop()


if __name__ == "__main__":
    main()
