-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("wibox")
require("vicious")

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
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/alex/.config/awesome/themes/propio/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ " main ", " web ", " code ", " media ", " misc ", }, s, layouts[1])
end
-- }}}

-- {{{ Menu
games = {
   { "zsnes", "zsnes" },
   { "Sword and Sorcery", "/home/alex/Misc/Games/SwordAndSworceryEP/run.sh" },
   { "SuperMeatBoy", "/home/alex/Misc/Games/supermeatboy/SuperMeatBoy" },
   { "diablo 2", "wine explorer /desktop=0,1366x786 /home/alex/Misc/Games/Diablo2/Diablo\ II.exe" },
   { "w3:ROC", "wine explorer /desktop=0,1366x786 /home/alex/Misc/Games/Warcraft\ III/Warcraft\ III.exe"},
   { "w3:FT", "wine explorer /desktop=0,1366x786 /home/alex/Misc/Games/Warcraft\ III/Frozen\ Throne.exe"}
}

myawesomemenu = {
   { "restart", awesome.restart },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "quit", awesome.quit }
}

mypowermenu = {
   { "shutdown", "sudo halt -p" },
   { "reboot", "sudo reboot"},
   { "suspend", "sudo pm-suspend" }
}
myaudiomenu = {
    {"ardour","ardour2"},
    {"puredata","pd"},
    {"processing","/home/alex/Soundology/Processing/processing"},
    {"qjackctl","qjackctl"},
    {"tuner","fmit"},
    {"xsynth","xsynth-dssi"},
    {"hydrogen","hydrogen"},
    {"calf","calfjackhost"},
    {"seq24","seq24"},
    {"samplv1","samplv1_jack"},
    {"synthv1","synthv1_jack"},
    {"jsampler","jsampler"},
    {"vmpk","vmpk"},
    {"rakarrack","rakarrack"},
    {"kill p.a.",terminal .. " -e killall pulseaudio"}
}

myappsmenu = {
   { "gimp", "gimp" },
   { "v.box", "virtualbox" },
   { "puddletag", "puddletag" },
   { "ranger", terminal .. " -e ranger" },
   { "tmux", terminal .. " -e tmux" },
   { "ncmpcpp", terminal .. " -e ncmpcpp" },
   { "mutt", terminal .. " -e mutt" },
   { "gvim", "gvim" },
   { "weechat", terminal .. " -e weechat-curses" }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu },
                                    { "audio", myaudiomenu},
                                    { "games", games },
                                    { "apps", myappsmenu },
                                    { "chromium", "chromium" },
                                    { "open terminal", terminal },
                                    { "nautilus", "nautilus" },
                                    { "power", mypowermenu}
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Create a laucher widget and a main menu
-- }}}
-- {{{ Wibox
--
--
-- {{{ Volume 
volwidtext = widget({ type = "textbox" })
vicious.register(volwidtext, vicious.widgets.volume,"[ Ô $1 ]", 0.3, "Master")

volwidtext:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("amixer -q sset Master toggle", false) end),
    awful.button({ }, 3, function () awful.util.spawn(terminal .. " -e alsamixer", false) end),
    awful.button({ }, 4, function () awful.util.spawn("amixer -q sset Master 2000+", false) end),
    awful.button({ }, 5, function () awful.util.spawn("amixer -q sset Master 2000-", false) end)
))
-- {{{ Pacman Widget 

pacwidget = widget({ type = "textbox" })
pacwidtoolt = awful.tooltip({objects = { pacwidget, pacwidgettex},})
vicious.register(pacwidget, vicious.widgets.pkg,
                function(widget,args)
                    local io = { popen = io.popen }
                    local s = io.popen("pacman -Qu")
                    local str = ''
                    for line in s:lines() do
                        str = str .. line .. "\n"
                    end
                    if str == '' then
                        pacwidtoolt:set_text("no updates available")
                    else
                        pacwidtoolt:set_text(str)
                    end
                    s:close()
                    return "[ Æ " .. args[1] .. " ]" 
                end,30,"Arch")

pacwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn(terminal .. " -e yaourt -Syua",false) end) 
))
-- {{{ Battery Widget
batwidtext = widget({ type = "textbox" })
batwidtoolt = awful.tooltip({ objects = { batwidtext,batwidget },})

vicious.register(batwidtext,vicious.widgets.bat,
                function(widget, args)
                    if args[1] ~= "-" then
                        btext = 'Pow'
                    else
                        btext = 'Bat'
                    end
                    if args[2] < 13 then
                        return '[ ' .. btext .. '<span color="#da4939"> ' .. args[2] ..'</span> ]'
                    else
                        return "[ " .. btext .. " " .. args[2] .. " ]"
                    end
                end, 5, "BAT0")

batmenu = awful.menu({items = {
			     { "Auto" , function () awful.util.spawn("sudo cpufreq-set -r -g ondemand", false) end },
			     { "Ondemand" , function () awful.util.spawn("sudo cpufreq-set -r -g ondemand", false) end },
			     { "Powersave" , function () awful.util.spawn("sudo cpufreq-set -r -g powersave", false) end },
			     { "Performance" , function () awful.util.spawn("sudo cpufreq-set -r -g performance", false) end }

}
})

batwidtext:buttons(awful.util.table.join(
                awful.button({ }, 1, function () batmenu:toggle() end)
))

-- MPD 
-- Initialize MPD Widget
music_play = widget({ type = "textbox" })
music_play.text = ' à '
music_play:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("ncmpcpp toggle", false) end)
))
  music_pause = awful.widget.launcher({
    image = beautiful.widget_pause,
    command = "ncmpcpp toggle"
  })
  music_pause.visible = false
music_stop = widget({ type = "textbox" })
music_stop.text = ' ä '
music_stop:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("ncmpcpp stop", false) end)
))

music_prev = widget({ type = "textbox" })
music_prev.text = ' â '
music_prev:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("ncmpcpp prev", false) end)
))


music_next = widget({ type = "textbox" })
music_next.text = ' ã '
music_next:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("ncmpcpp next", false) end)
))

mpdwidget = widget({ type = "textbox" })
vicious.register(mpdwidget, vicious.widgets.mpd,
    function (widget, args)
        if args["{state}"] == "Stop" then 
            music_play.text = ' à '
            music_prev.text = ''
            music_next.text = ''
            music_stop.text = ''
            return "[ Î ]"
        elseif args["{state}"] == "Pause" then
            music_play.text = ' à '
            music_prev.text = ' â '
            music_next.text = ' ã '
            music_stop.text = ' ä '
            return "[ Î  Paused ]"
        else 
            music_stop.text = ' ä '
            music_prev.text = ' â '
            music_next.text = ' ã '
            music_play.text = ' á '
            return "[ Î  " .. args["{Title}"]..' - '.. args["{Artist}"] .. " ]"
        end
    end, 0.5)

mpdwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn(terminal .. " -e ncmpcpp", false) end)
))

-- Os info

network = widget({ type = "textbox" })
vicious.register(network, vicious.widgets.net, "[ Ð ${wlan0 down_kb} Ñ ${wlan0 up_kb} ]")

hdspace = widget({ type = "textbox" })
vicious.register(hdspace, vicious.widgets.fs, "[ Ê / ${/ avail_gb}/${/ size_gb}GB ]")

hdspace2 = widget({ type = "textbox" })
vicious.register(hdspace2, vicious.widgets.fs, "[ Ê /home ${/home avail_gb}/${/home size_gb}GB ]")
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Separators
leftsquare = widget({ type = "textbox" })
leftsquare.text = '['
rightsquare = widget({ type = "textbox" })
rightsquare.text = ']'

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", height = "15", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        batwidtext,
        pacwidget,
        volwidtext,
        network,
        hdspace2,
        hdspace,
        rightsquare,
        music_stop,
        music_next,
        music_prev,
        music_play,
        leftsquare,
        mpdwidget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end

-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Shift"   }, "n", function () awful.util.spawn("nautilus") end),
    awful.key({ modkey, "Shift"   }, "i", function () awful.util.spawn("chromium") end),
    awful.key({ modkey,           }, "i", function () awful.util.spawn("dwb") end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "x",     function () mypromptbox[mouse.screen]:run() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     size_hints_honor = false,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "Vlc" },
      properties = { floating = true , tag = tags[1][4]} },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true, tag = tags[1][4] } },
    -- Set Chromium to always map on tags number 2 of screen 1.
    { rule = { class = "Chromium"}, properties = {tag = tags[1][2] }},
    { rule = { class = "dwb"}, properties = {tag = tags[1][2] }},
    { rule = { class = "banshee"}, properties = {tag = tags[1][4] }},
    { rule = { class = "Gvim"}, properties = {size_hints_honor = false}},
    { rule = { class = "URxvt"}, properties = {size_hints_honor = false}},
    --   properties = { tag = tags[1][2] } ,
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
--
-- Autostart {{{  

awful.util.spawn_with_shell("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
awful.util.spawn_with_shell("compton -cG -o 0.38 -O 200 -I 200 -t 0.02 -l 0.02 -r 3.2 -D2 -m 0.88")

-- }}}
