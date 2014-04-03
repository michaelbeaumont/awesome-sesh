local os = os
local io = io
local pairs, assert, tostring, tonumber, table = pairs, assert, tostring, tonumber, table

local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
module("awesome_sesh")

local debug = false
local delim = "7A01770F"--A589A58C054B259543BFB"

-- pread instead of popen
function debugNotify(notification)
    if debug then
        naughty.notify(notification)
    end
end

function writeLn(f, str)
    f:write(str.."\n")
end

function init(client)
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


function save_marked(id, perm)
    local file = assert(io.open(os.getenv("HOME").."/.awesome_saved"..id, "w"))
    local cmd_str = ""
    local name_str = "session saved at:"
    for _, v in pairs(awful.client.getmarked()) do 
        local pid = v.pid
        local this_entry = ""
        local tags = v:tags()
        local tags_str = ""
        for k, v in pairs(tags) do
            tags_str = tags_str..v.name.." "
        end
        name_str = name_str.."\n"..v.name
        local linkf = io.popen("ps -p "..pid.." -o args=")
        local this_cmd = linkf:read("*line")
        cmd_str = cmd_str.."\n"..tags_str.."\n"..this_cmd
        naughty.notify({ preset = naughty.config.presets.normal,
                         title = "Saved "..v.name,
                         text = this_cmd,
                         timeout = 3})
    end
    writeLn(file, name_str)
    --no newline after this because cmd_str starts with a newline
    file:write(delim)
    writeLn(file, cmd_str)
    file:close()
end

function list_saved() 
    linkf = io.popen("ls "..os.getenv("HOME").."/.awesome_saved")
    cmd = linkf:read("*line")
end

function restore_sesh(id)
    local file = assert(io.open(os.getenv("HOME").."/.awesome_saved"..id, "r"))

    local name_str = ""
    local move_forward = true

    local read_line = file:read("*line")
    local sesh_info = read_line

    read_line = file:read("*line")

    while move_forward do
        local cur_line = read_line
        local strt_loc, _ = cur_line:find(delim)
        --this means read_line is at the line after delim
        --when the loop ends
        read_line = file:read("*line")
        if strt_loc == 1 or read_line == nil then
            move_forward = false
        else
            name_str = name_str..cur_line.."\n"
        end
    end
    naughty.notify({ preset = naughty.config.presets.normal,
                     title = "Session contains:",
                     text = name_str,
                     timeout = 3})

    local new_progs = {}

    local restore_table = awful.rules.rules

    while read_line ~= nil do
        debugNotify({text="In command search"})
        new_tags = {}

        local glob_tags = awful.tag.gettags(1)--p.screen)

        for new_tag in read_line:gmatch("%d") do
            debugNotify({text="found tag "..tostring(new_tag)})
            table.insert(new_tags, glob_tags[tonumber(new_tag)])
        end

        read_line = file:read("*line")
        local new_cmd = read_line

        debugNotify({title = "Found:", text = new_cmd})

        local new_pid = awful.util.spawn(new_cmd)

        table.insert(awful.rules.rules, { 
                rule = { pid = new_pid},
                callback = function(c)
                    c:tags(new_tags)
                end
            })
        read_line = file:read("*line")
    end

    awful.rules.rules = restore_table
    
end
