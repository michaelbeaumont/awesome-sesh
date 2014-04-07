-- Author: Michael Beaumont <mjboamail@gmail.com>
local os = os
local io = io
local pairs, assert, tostring, tonumber, table = pairs, assert, tostring, tonumber, table

local client = client
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
module("awesome_sesh")

local debug = false
local delim = "7A01770F"--A589A58C054B259543BFB"

local awesome_sesh_settings = {}

function debugNotify(notification)
    if debug then
        naughty.notify(notification)
    end
end

function writeLn(f, str)
    f:write(str.."\n")
end

function init(save_dir)

    -- Save settings
    awesome_sesh_settings.save_dir = save_dir

    client.connect_signal("focus", function(c)
        if not awful.client.ismarked(c) then
            c.border_color = beautiful.border_focus
        end
    end)

    client.connect_signal("unfocus", function(c)
        if not awful.client.ismarked(c) then
            c.border_color = beautiful.border_normal
        end
    end)

    client.connect_signal("marked", function(c) 
        c.border_color = beautiful.border_marked
    end)

    client.connect_signal("unmarked", function(c) 
        if c == awful.client.focus.history.get(c.screen, 0) then
            c.border_color = beautiful.border_focus
        end
        c.border_color = beautiful.border_normal
    end)
end


-- Save marked windows to session file
function save(id, perm)
    -- Open handle for new sesh file
    local new_sesh_file = assert(io.open(awesome_sesh_settings.save_dir.."/"..id, "w"))
    -- Declare variables for this session
    local cmd_str = ""
    local name_str = "session saved at:"
    
    -- Go through every marked window and save the info
    for _, v in pairs(awful.client.getmarked()) do 
        -- Declare variables for this application
        local pid = v.pid
        local this_entry = ""
        local tags = v:tags()
        local screen_str = v.screen
        local tags_str = ""
        -- Build string for this prog's tags
        for k, v in pairs(tags) do
            tags_str = tags_str..v.name.." "
        end
        -- Description string
        name_str = name_str.."\n"..v.name
        -- TODO replace with pread
        local linkf = io.popen("ps -p "..pid.." -o args=")
        local this_cmd = linkf:read("*line")
        -- String to restore this program
        cmd_str = cmd_str.."\n"..screen_str.."\n"..tags_str.."\n"..this_cmd
        -- Notify for every saved prog
        naughty.notify({ preset = naughty.config.presets.normal,
                         title = "Saved "..v.name,
                         text = this_cmd,
                         timeout = 3})
    end

    -- Write prog info to file
    writeLn(new_sesh_file, name_str)
    -- No newline after this because cmd_str starts with a newline
    new_sesh_file:write(delim)
    writeLn(new_sesh_file, cmd_str)

    new_sesh_file:close()
end

function list(textbox) 
    -- Ls all session files
    local sesh_list = io.popen("ls -1 "..awesome_sesh_settings.save_dir)
    local saved_seshs = sesh_list:lines()
    local show_str = ""

    for l in saved_seshs do
        local cur_sesh_file = assert(io.open(awesome_sesh_settings.save_dir.."/"..l, "r"))

        local sesh_info = cur_sesh_file:read("*line")
        local read_line = cur_sesh_file:read("*line")

        --Loop variables
        local strt_loc = nil
        local cur_line
        local name_str = ""
        local move_forward = true

        --Iterate through the lines, building our list of progs
        --until we hit the delimiter
        while move_forward do
            cur_line = read_line
            strt_loc, _ = cur_line:find(delim)
            --this means read_line is at the line after delim
            --when the loop ends
            read_line = cur_sesh_file:read("*line")
            if strt_loc == 1 or read_line == nil then
                move_forward = false
            else
                name_str = name_str..cur_line.."\n"
            end
        end
        cur_sesh_file:close()

        --Append this session description to the notification to be
        show_str = show_str.."\nSession "..l..":\n"..name_str
    end

    --Show a notification displaying all saved sessions
    local list_box = naughty.notify(
                         { preset = naughty.config.presets.normal,
                           title = "Saved Sessions:",
                           text = show_str
                           --timeout = nil?
                         })

    --Callback for our prompt
    --Destroy the notification and restore the sesh
    local restore_callback = function (choice) 
        naughty.destroy(list_box)
        restore(choice)
    end

    -- Prompt for session to load
    awful.prompt.run({ prompt = "Choose session: " },
                       textbox,
                       restore_callback
                     )
                     
end

function restore(id)

    --change to if nil error session not found
    local sesh_file = assert(io.open(awesome_sesh_settings.save_dir.."/"..id, "r"))

    local name_str = ""
    local move_forward = true

    local read_line = sesh_file:read("*line")
    local sesh_info = read_line

    read_line = sesh_file:read("*line")

    while move_forward do
        local strt_loc, _ = read_line:find(delim)
        --this means read_line is at the line after delim
        --when the loop ends
        read_line = sesh_file:read("*line")
        if strt_loc == 1 or read_line == nil then
            move_forward = false
        end
    end

    local new_progs = {}

    local restore_table = awful.rules.rules

    while read_line ~= nil do
        debugNotify({text="In command search"})
        new_tags = {}

        local new_screen = tonumber(read_line)

        local glob_tags = awful.tag.gettags(new_screen)

        read_line = sesh_file:read("*line")

        for new_tag in read_line:gmatch("%d") do
            debugNotify({text="found tag "..tostring(new_tag)})
            table.insert(new_tags, glob_tags[tonumber(new_tag)])
        end

        read_line = sesh_file:read("*line")
        local new_cmd = read_line

        debugNotify({title = "Found:", text = new_cmd})

        local new_pid = awful.util.spawn(new_cmd)

        table.insert(awful.rules.rules,
                     {rule = { pid = new_pid },
                      callback = function(c)
                          c:tags(new_tags)
                      end
                     })
        read_line = sesh_file:read("*line")
    end

    sesh_file:close()
    awful.rules.rules = restore_table
    
end
