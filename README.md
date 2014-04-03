Awesome Sessions
================

This program lets you save open groups of windows and reopen them at a later time.
The idea is to start the program the same way it was started in the first place, any restoring of state within the program should be handled there.
(for now, we'll see how useful this is without direct support for state)

Installation
------------

To use this program, you must call the init function in `rc.lua` and bind a few keys:

Include the library at the top of the file:

    local awesome_sesh = require("awesome-sesh/awesome_sesh.lua")

Remove these `connect_signal` calls from `rc.lua`:

    client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
    client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

Call this function somewhere near the end in rc.lua:

    awesome_sesh.init()

### Keybindings: ###

Key to mark window:

    awful.key({ modkey, "Shift" }, "m", function (c) awful.client.togglemarked(c) end)

Keys for saving and restoring sessions:

    
    -- Use marked windows to save to quick session
    awful.key({ modkey, "Shift", "Control" }, "m", function () 
        awesome_sesh.save("Quick Session", true)
    end),

    -- Restore from quick session
    awful.key({ modkey, "Shift", "Control" }, "r", function () 
        awesome_sesh.restore("Quick Session")
    end),

    -- List sessions, the widget to show the prompt box should be passed here
    awful.key({ modkey, "Shift", "Control" }, "l", function () 
        awesome_sesh.list(mypromptbox[mouse.screen].widget)
    end)

TODO
----

* Add support for saving multiple sessions (restoring complete)
* Save the screen of marked clients
