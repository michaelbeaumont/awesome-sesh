Awesome Sessions
================

This program lets you save open groups of windows and reopen them at a later time.
The idea is to start the program the same way it was started in the first place, any restoring of state within the program should be handled there.

Installation
------------

To use this program, you must call the init function in `rc.lua` and bind a few keys like so:

Include the library at the top of the file:

    local awesome_sesh = require("awesome-sesh/awesome_sesh.lua")

Remove these `connect_signal` calls from `rc.lua`:

    client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
    client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

Call this function somewhere near the end in rc.lua:

    awesome_sesh.init(client)

### Keybindings: ###

Key to mark window:

    awful.key({ modkey, "Shift" }, "m", function (c) awful.client.togglemarked(c) end)

Keys for saving and restoring sessions:

    -- Save marked windows as a session
    awful.key({ modkey, "Shift", "Control" }, "m", function () 
        awesome_sesh.save_sesh(1, true)
    end),

    -- Restore saved session
    awful.key({ modkey, "Shift", "Control" }, "r", function () 
        awesome_sesh.restore_sesh(1)
    end)

TODO
----

* Add support for restoring to the correct tags
* Add support for multiple sessions
