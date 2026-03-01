import { application } from "controllers/application"

import MobileMenuController from "controllers/mobile_menu_controller"
application.register("mobile-menu", MobileMenuController)

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

import ThemeController from "controllers/theme_controller"
application.register("theme", ThemeController)

import DropdownController from "controllers/dropdown_controller"
application.register("dropdown", DropdownController)

import ClientToolController from "controllers/client_tool_controller"
application.register("client-tool", ClientToolController)

