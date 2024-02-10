-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local config_dir = string.format("%sawesome", os.getenv("XDG_CONFIG_HOME"))
local script_dir = config_dir .. "/scripts"
-- terminal = "/usr/bin/konsole --separate --stylesheet=/home/pi/Documents/pi-config/.config/konsole/main.css"
local terminal = "/usr/bin/kitty"
local editor = os.getenv("EDITOR") or "editor"
local editor_cmd = terminal .. " -e " .. editor

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local theme_path = string.format("%s/themes/%s/theme.lua", config_dir, "pi")
beautiful.init(theme_path)
beautiful.tasklist_disable_icon = false
local my_text_font = beautiful.font:gsub("%s%d+$", "") .. " bold 9"

local volume_widget = require('awesome-wm-widgets.pactl-widget.volume')
local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
local weather_widget = require("wttr-widget.weather")
local wttr = weather_widget({
            location = "ccf",
            lang = "fr",
            font = my_text_font,
})

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
                   title = "Oops, there were errors during startup!",
                   text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
                           -- Make sure we don't go into an endless error loop
                           if in_error then return end
                           in_error = true

                           naughty.notify({ preset = naughty.config.presets.critical,
                                            title = "An error happened!",
                                            text = tostring(err) })
                           in_error = false
  end)
end
-- }}}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod3"

local function rotate_screens(direction)
  local current_screen = awful.screen.focused()
  local initial_scren = current_screen
  while (true) do
    awful.screen.focus_relative(direction)
    local next_screen = awful.screen.focused()
    if next_screen == initial_scren then
      return
    end

    local current_screen_tag_name = current_screen.selected_tag.name
    local next_screen_tag_name = next_screen.selected_tag.name

    for _, t in ipairs(current_screen.tags) do
      local fallback_tag = awful.tag.find_by_name(next_screen, t.name)
      local self_clients = t:clients()
      local other_clients

      if not fallback_tag then
        -- if not available, use first tag
        fallback_tag = next_screen.tags[1]
        other_clients = {}
      else
        other_clients = fallback_tag:clients()
      end

      for _, c in ipairs(self_clients) do
        c:move_to_tag(fallback_tag)
      end

      for _, c in ipairs(other_clients) do
        c:move_to_tag(t)
      end
    end
    awful.tag.find_by_name(next_screen, current_screen_tag_name):view_only()
    awful.tag.find_by_name(current_screen, next_screen_tag_name):view_only()
    current_screen = next_screen
  end
end

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
  awful.layout.suit.max,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.tile,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  awful.layout.suit.floating,
  -- awful.layout.suit.tile.left,
  -- awful.layout.suit.fair,
  -- awful.layout.suit.fair.horizontal,
  -- awful.layout.suit.spiral,
  -- awful.layout.suit.spiral.dwindle,
  awful.layout.suit.magnifier,
  -- awful.layout.suit.corner.nw,
  -- awful.layout.suit.corner.ne,
  -- awful.layout.suit.corner.sw,
  -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
  { "hotkeys ", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "restart", awesome.restart },
  { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }
local mymainmenu = {}

if has_fdo then
  mymainmenu = freedesktop.menu.build({
      before = { menu_awesome },
      after =  { menu_terminal }
  })
else
  mymainmenu = awful.menu({
      items = {
        menu_awesome,
        { "Debian", debian.menu.Debian_menu.Debian },
        menu_terminal,
      }
  })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = awful.widget.watch(
  script_dir .. "/awm-date.sh",
  0.25, -- 15 secs
  function(widget, stdout)
    widget:set_markup(stdout)
  end,
  wibox.widget{
    markup = "Waiting…",
    font = my_text_font,
    widget = wibox.widget.textbox
  }
)

mytextclock:connect_signal(
  "button::press",
  function(self, lx, ly, button, mods, metadata)
    -- local cmd = string.format("kitty -p 'font=Courier 10 Pitch,18,-1,5,50,0,0,0,0,0' --hold -e '%s/scripts/awm-cal.sh'", config_dir)
    local cmd = string.format("kitty -o font_family='Courier 10 Pitch' -o font_size=18 --hold -e '%s/scripts/awm-cal.sh'", config_dir)
    awful.util.spawn(cmd, false)
end)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
  awful.button({ }, 1, function(t) t:view_only() end),
  awful.button({ modkey }, 1, function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
  end),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
  end),
  awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
  awful.button({ }, 1, function (c)
      if c == client.focus then
        c.minimized = true
      else
        c:emit_signal(
          "request::activate",
          "tasklist",
          {raise = true}
        )
      end
  end),
  awful.button({ }, 3, function()
      awful.menu.client_list({ theme = { width = 250 } })
  end),
  awful.button({ }, 4, function ()
      awful.client.focus.byidx(1)
  end),
  awful.button({ }, 5, function ()
      awful.client.focus.byidx(-1)
end))

local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)
  end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
-- screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    -- set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(
      gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
      screen  = s,
      filter  = awful.widget.taglist.filter.all,
      buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
      screen  = s,
      filter  = awful.widget.tasklist.filter.focused,
      buttons = tasklist_buttons
    }

    local spaceWdg = {
      layout   = wibox.container.constraint,
      widget = wibox.container.margin,
      strategy = "min",
      width    = 10,
    }

    local audio_wdg = nil
    local battery_wdg = nil
    local cpu_wdg = nil
    local weather_wdg = nil
    s.systray = nil

    if s == screen.primary then
      audio_wdg = {
        layout = awful.widget.only_on_screen,
        screen = screen.primary, -- Only display on primary screen
        volume_widget{
          widget_type = 'arc',
          mixer_cmd = terminal .. " -e 'alsamixer'"
        }
      }

      battery_wdg = {
        layout = awful.widget.only_on_screen,
        screen = screen.primary, -- Only display on primary screen
        battery_widget({
            show_current_level = true,
            display_notification = true,
            bg_color = beautiful.pi_wibar_bg,
            timeout = 15,
            -- low_level_color = beautiful.fg_urgent,
            -- medium_level_color = beautiful.fg_warning,
            warning_msg_title = "⚡ WARNING !",
            warning_msg_text = "Battery is discharged…",
            notification_position = "top_right",
            arc_thickness = 2,
            enable_battery_warning = true,
            path_to_icons = "/usr/share/icons/hicolor/scalable/status/",
        })
      }

      cpu_wdg = {
        layout = awful.widget.only_on_screen,
        screen = screen.primary, -- Only display on primary screen
        cpu_widget({
            width = 70,
            step_width = 2,
            step_spacing = 0,
            color = '#434c5e'
        })
      }

      weather_wdg = {
        layout = awful.widget.only_on_screen,
        screen = screen.primary, -- Only display on primary screen
        wttr,
      }

      s.systray = wibox.widget.systray()
    end


    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        bg = beautiful.pi_wibar_bg,
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
      layout = wibox.layout.align.horizontal,
      { -- Left widgets
        layout = wibox.layout.fixed.horizontal,
        mylauncher,
        s.mytaglist,
        s.mypromptbox,
      },
      s.mytasklist, -- Middle widget
      { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        cpu_wdg,
        spaceWdg,
        battery_wdg,
        spaceWdg,
        audio_wdg,
        spaceWdg,
        weather_wdg,
        spaceWdg,
        {
          layout = awful.widget.only_on_screen,
          screen = screen.primary, -- Only display on primary screen
          mytextclock,
        },
        spaceWdg,
        {
          layout = awful.widget.only_on_screen,
          screen = screen.primary, -- Only display on primary screen
          s.systray,
        },
        s.mylayoutbox,
      },
    }
end
)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
               awful.button({ }, 3, function () mymainmenu:toggle() end),
               awful.button({ }, 4, awful.tag.viewnext),
               awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
  -- awful.key({}, "XF86AudioLowerVolume", function ()
  --     awful.util.spawn("amixer -q -D pulse sset Master 5%-", false) end),
  -- awful.key({}, "XF86AudioRaiseVolume", function ()
  --     awful.util.spawn("amixer -q -D pulse sset Master 5%+", false) end),
  -- awful.key({}, "XF86AudioMute", function ()
  --     awful.util.spawn("amixer -D pulse set Master 1+ toggle", false) end),
  awful.key({}, "XF86AudioRaiseVolume", function () volume_widget:inc(5) end),
  awful.key({}, "XF86AudioLowerVolume", function () volume_widget:dec(5) end),
  awful.key({}, "XF86AudioMute", function () volume_widget:toggle() end),
  -- Media Keys
  awful.key({}, "XF86AudioPlay", function()
      awful.util.spawn("playerctl play-pause", false) end),
  awful.key({}, "XF86AudioNext", function()
      awful.util.spawn("playerctl next", false) end),
  awful.key({}, "XF86AudioPrev", function()
      awful.util.spawn("playerctl previous", false) end),

  awful.key({ modkey }, "b",
    function ()
      myscreen = awful.screen.focused()
      myscreen.mywibox.visible = not myscreen.mywibox.visible
    end,
    {description = "toggle statusbar/wibox"}
  ),
  awful.key({ modkey }, "=", function ()
      local s = awful.screen.focused().systray
      if s ~= nil then
        s.visible = not s.visible
      end
  end, {description = "Toggle systray visibility", group = "custom"}),
  awful.key({modkey, "Shift"   }, "k",      hotkeys_popup.show_help,
    {description="show help", group="awesome"}),
  awful.key({modkey,           }, "Left",   awful.tag.viewprev,
    {description = "view previous", group = "tag"}),
  awful.key({modkey,           }, "Right",  awful.tag.viewnext,
    {description = "view next", group = "tag"}),
  awful.key({modkey,           }, "Escape", awful.tag.history.restore,
    {description = "go back", group = "tag"}),

  awful.key({"Mod1", }, "Tab", function() awful.client.focus.byidx(1) end,
    {description = "focus next by index", group = "client"}
  ),
  awful.key({"Mod1", "Shift"}, "Tab", function() awful.client.focus.byidx(-1) end,
    {description = "focus previous by index", group = "client"}
  ),
  awful.key({modkey, "Control"}, "Tab",
    function ()
      awful.client.focus.history.previous()
      if client.focus then
        client.focus:raise()
      end
    end,
    {description = "go back", group = "client"}),
  awful.key({modkey, }, "w", function() mymainmenu:show() end,
    {description = "show main menu", group = "awesome"}),

  -- Layout manipulation
  awful.key({modkey,}, "*", function () awful.client.swap.byidx(1) end,
    {description = "swap with next client by index", group = "client"}),

  awful.key({modkey, "Shift"}, "*", function () awful.client.swap.byidx(-1) end,
    {description = "swap with previous client by index", group = "client"}),

  awful.key({ modkey,}, "Tab", function () awful.screen.focus_relative( 1) end,
    {description = "focus the next screen", group = "screen"}),

  awful.key({ modkey, "Shift"}, "Tab", function () awful.screen.focus_relative(-1) end,
    {description = "focus the previous screen", group = "screen"}),

  awful.key({modkey, "Shift"}, "o", function() rotate_screens(-1) end,
    {description = "rotate screens right", group = "screen"}),

  -- awful.key({modkey, "Control", "Shift"}, "s", function() rotate_screens(1) end,
  --   {description = "rotate screens left", group = "screen"}),

  awful.key({ modkey,}, "u", awful.client.urgent.jumpto,
    {description = "jump to urgent client", group = "client"}),

  awful.key({ modkey,}, "Up", function () awful.tag.incmwfact( 0.05) end,
    {description = "increase master width factor", group = "layout"}),

  awful.key({ modkey,}, "Down", function () awful.tag.incmwfact(-0.05) end,
    {description = "decrease master width factor", group = "layout"}),

  awful.key({ modkey, "Shift"}, "Up", function () awful.tag.incnmaster( 1, nil, true) end,
    {description = "increase the number of master clients", group = "layout"}),

  awful.key({ modkey, "Shift"}, "Down", function () awful.tag.incnmaster(-1, nil, true) end,
    {description = "decrease the number of master clients", group = "layout"}),

  awful.key({ modkey, "Control" }, "Up", function () awful.tag.incncol( 1, nil, true) end,
    {description = "increase the number of columns", group = "layout"}),

  awful.key({ modkey, "Control" }, "Down",     function () awful.tag.incncol(-1, nil, true) end,
    {description = "decrease the number of columns", group = "layout"}),

  awful.key({ modkey, }, "space", function () awful.layout.inc( 1) end,
    {description = "select next", group = "layout"}),

  awful.key({ modkey, "Shift"}, "space", function () awful.layout.inc(-1) end,
    {description = "select previous", group = "layout"}),

  awful.key({ modkey, "Shift" }, "n",
    function ()
      local c = awful.client.restore()
      if c then
        c:emit_signal("request::activate", "key.unminimize", {raise = true})
      end
    end,
    {description = "restore minimized", group = "client"}),

  -- Standard program
  awful.key({modkey, "Shift"}, "Return", function () awful.spawn(terminal) end,
    {description = "open a terminal", group = "launcher"}),
  awful.key({modkey, "Shift"}, "r", awesome.restart,
    {description = "reload awesome", group = "awesome"}),
  awful.key({modkey, "Shift", "Control"}, "q", awesome.quit,
    {description = "quit awesome", group = "awesome"}),
  awful.key({modkey, "Shift"}, "l",
    function() awful.spawn("i3lock --color=#3f3f3f --ignore-empty-password") end,
    {description = "lock awesome", group = "awesome"}),
  awful.key({modkey, "Shift", "Control"}, "s",
    function() awful.spawn("sudo /home/pi/bin/suspend.sh") end,
    {description = "suspend", group = "awesome"}),
  awful.key({modkey,}, "Print",
    function() awful.spawn("/home/pi/bin/screenshot.sh") end,
    {description = "screenshot", group = "awesome"}),
  awful.key({"Mod4",}, "m", wttr.toggle_tooltip,
    {description="show weather tooltip", group="awesome"}),
  awful.key({"Mod4", "Shift"}, "m", wttr.show_forecast,
    {description="show weather forecast", group="awesome"}),

  -- Prompt
  awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end,
    {description = "run prompt", group = "launcher"}),
  awful.key({modkey, "Shift"}, "x",
    function ()
      awful.prompt.run {
        prompt       = "Run Lua code: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
    end,
    {description = "lua execute prompt", group = "awesome"}),

  -- Menubar
  awful.key({ modkey }, "p", function() menubar.show() end,
    {description = "show the menubar", group = "launcher"})
)

clientkeys = gears.table.join(
  awful.key({ modkey, "Shift"}, "f",
    function (c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    {description = "toggle fullscreen", group = "client"}),

  awful.key({modkey, }, "x", function (c) c:kill() end,
    {description = "close", group = "client"}),

  awful.key({modkey, }, "f", awful.client.floating.toggle,
    {description = "toggle floating", group = "client"}),

  awful.key({modkey, }, "s", function (c) c.sticky = not c.sticky end,
    {description = "toggle sticky", group = "client"}),

  awful.key({modkey, }, "Return", function (c) c:swap(awful.client.getmaster()) end,
    {description = "move to master", group = "client"}),

  awful.key({modkey,}, "o", function (c) c:move_to_screen() end,
    {description = "move to screen", group = "client"}),

  awful.key({modkey, }, "t", function (c) c.ontop = not c.ontop end,
    {description = "toggle keep on top", group = "client"}),


  awful.key({modkey, }, "n",
    function (c)
      -- The client currently has the input focus, so it cannot be
      -- minimized, since minimized clients can't have the focus.
      c.minimized = true
    end ,
    {description = "minimize", group = "client"}),
  awful.key({ modkey,           }, "m",
    function (c)
      c.maximized = not c.maximized
      c:raise()
    end ,
    {description = "(un)maximize", group = "client"}),
  awful.key({ modkey, }, "v",
    function (c)
      c.maximized_vertical = not c.maximized_vertical
      c:raise()
    end ,
    {description = "(un)maximize vertically", group = "client"}),
  awful.key({ modkey, }, "h",
    function (c)
      c.maximized_horizontal = not c.maximized_horizontal
      c:raise()
    end ,
    {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = gears.table.join(
    globalkeys,
    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9,
      function ()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          tag:view_only()
        end
      end,
      {description = "view tag #"..i, group = "tag"}),
    -- Toggle tag display.
    awful.key({ modkey, "Control" }, "#" .. i + 9,
      function ()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end,
      {description = "toggle tag #" .. i, group = "tag"}),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
      function ()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:move_to_tag(tag)
          end
        end
      end,
      {description = "move focused client to tag #"..i, group = "tag"}),
    -- Toggle tag on focused client.
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
      function ()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:toggle_tag(tag)
          end
        end
      end,
      {description = "toggle focused client on tag #" .. i, group = "tag"})
  )
end

local clientbuttons = gears.table.join(
  awful.button({ }, 1, function (c)
      c:emit_signal("request::activate", "mouse_click", {raise = true})
  end),
  awful.button({ modkey }, 1, function (c)
      c:emit_signal("request::activate", "mouse_click", {raise = true})
      awful.mouse.client.move(c)
  end),
  awful.button({ modkey }, 3, function (c)
      c:emit_signal("request::activate", "mouse_click", {raise = true})
      awful.mouse.client.resize(c)
  end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  { rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen
    }
  },

  -- Floating clients.
  { rule_any = {
      instance = {
        "DTA",  -- Firefox addon DownThemAll.
        "copyq",  -- Includes session name in class.
        "pinentry",
      },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin",  -- kalarm.
        "Sxiv",
        "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui",
        "veromix",
        "xtightvncviewer"},

      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester",  -- xev.
      },
      role = {
        "AlarmWindow",  -- Thunderbird's calendar.
        "ConfigManager",  -- Thunderbird's about:config.
        "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
      }
  }, properties = { floating = true }},

  -- Remove titlebars to normal clients
  { rule_any = {type = { "normal" }
               }, properties = { titlebars_enabled = false }
  },
  -- Add titlebars to normal clients and dialogs
  { rule_any = {type = { "dialog" }
               }, properties = { titlebars_enabled = true }
  },

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- { rule = { class = "Firefox" },
  --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal(
  "manage",
  function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
      -- Prevent clients from being unreachable after screen count changes.
      awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal(
  "request::titlebars",
  function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
      awful.button({ }, 1, function()
          c:emit_signal("request::activate", "titlebar", {raise = true})
          awful.mouse.client.move(c)
      end),
      awful.button({ }, 3, function()
          c:emit_signal("request::activate", "titlebar", {raise = true})
          awful.mouse.client.resize(c)
      end)
    )

    awful.titlebar(c) : setup {
      { -- Left
        -- awful.titlebar.widget.iconwidget(c),
        buttons = buttons,
        layout  = wibox.layout.fixed.horizontal
      },
      { -- Middle
        { -- Title
          align  = "center",
          widget = awful.titlebar.widget.titlewidget(c)
        },
        buttons = buttons,
        layout  = wibox.layout.flex.horizontal
      },
      { -- Right
        awful.titlebar.widget.floatingbutton (c),
        awful.titlebar.widget.maximizedbutton(c),
        awful.titlebar.widget.stickybutton   (c),
        awful.titlebar.widget.ontopbutton    (c),
        awful.titlebar.widget.closebutton    (c),
        layout = wibox.layout.fixed.horizontal()
      },
      layout = wibox.layout.align.horizontal
                              }
  end
)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal(
  "mouse::enter",
  function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
  end
)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Autorun
awful.spawn.with_shell(os.getenv("XDG_CONFIG_HOME") .. "/awesome/scripts/awm-autostart.sh")
-- }}}
