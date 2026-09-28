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

import PollController from "controllers/poll_controller"
application.register("poll", PollController)

import UploaderController from "controllers/uploader_controller"
application.register("uploader", UploaderController)

import ToolFilterController from "controllers/tool_filter_controller"
application.register("tool-filter", ToolFilterController)

import BillingToggleController from "controllers/billing_toggle_controller"
application.register("billing-toggle", BillingToggleController)

import CountUpController from "controllers/count_up_controller"
application.register("count-up", CountUpController)

