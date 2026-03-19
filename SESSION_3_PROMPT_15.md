# PROMPT 15 — Stimulus Controllers + Importmap

## Context
Session 3 frontend build. Copy Stimulus JS controllers and register them.

## Instructions

Run these commands exactly:

```bash
# 1. Copy all Stimulus controllers
cp session3_files/javascript/controllers/command_palette_controller.js app/javascript/controllers/command_palette_controller.js
cp session3_files/javascript/controllers/chat_panel_controller.js app/javascript/controllers/chat_panel_controller.js
cp session3_files/javascript/controllers/role_switcher_controller.js app/javascript/controllers/role_switcher_controller.js
cp session3_files/javascript/controllers/period_selector_controller.js app/javascript/controllers/period_selector_controller.js
cp session3_files/javascript/controllers/dismissible_controller.js app/javascript/controllers/dismissible_controller.js
cp session3_files/javascript/controllers/sidebar_controller.js app/javascript/controllers/sidebar_controller.js
```

## 2. Register controllers in app/javascript/controllers/index.js

Check if the file exists first. If it does, add registrations for each new controller. If not, create it.

The file should import and register all 6 controllers with the Stimulus application. Example pattern:

```javascript
import { application } from "controllers/application"

import CommandPaletteController from "controllers/command_palette_controller"
application.register("command-palette", CommandPaletteController)

import ChatPanelController from "controllers/chat_panel_controller"
application.register("chat-panel", ChatPanelController)

import RoleSwitcherController from "controllers/role_switcher_controller"
application.register("role-switcher", RoleSwitcherController)

import PeriodSelectorController from "controllers/period_selector_controller"
application.register("period-selector", PeriodSelectorController)

import DismissibleController from "controllers/dismissible_controller"
application.register("dismissible", DismissibleController)

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)
```

If the app uses `eagerLoadControllersFrom` or `lazyLoadControllersFrom` instead of manual registration, that is fine — Stimulus will auto-discover the controllers by filename convention.

After running, verify:
```bash
ls -la app/javascript/controllers/*.js
cat app/javascript/controllers/index.js
```

Expected: 6 new controller files + the existing index.js and application.js.
