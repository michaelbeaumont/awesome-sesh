local os = os
local io = io
local pairs, assert, tostring, table = pairs, assert, tostring, table

local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
module("awesome_sesh")

local debug = false
local delim = "7A01770F"--A589A58C054B259543BFB"

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
    local name_str = ""
    for _, v in pairs(awful.client.getmarked()) do 
        local pid = v.pid
        local this_entry = ""
        local tags = v:tags()
        local tags_str = ""
        for k, v in pairs(tags) do
            tags_str = tags_str..v.name.." "
        end
        name_str = name_str..v.name.."\n"
        local linkf = io.popen("ps -p "..pid.." -o args=")
        local this_cmd = linkf:read("*line")
        cmd_str = cmd_str.."\n"..tags_str.."\n"..this_cmd
        naughty.notify({ preset = naughty.config.presets.normal,
                         title = "Saved "..v.name,
                         text = this_cmd,
                         timeout = 3})
    end
    writeLn(file, name_str)
    writeLn(file, delim)
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

    while move_forward do
        local cur_line = read_line
        local strt_loc, _ = cur_line:find(delim)
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
    while read_line ~= nil do
        local prog = {}
        prog.tags = {}
        for new_tag in read_line:gmatch("%d") do
            table.insert(prog.tags, new_tag)
        end
        read_line = file:read("*line")
        prog.cmd = read_line
        table.insert(new_progs, prog)
        read_line = file:read("*line")
    end
    for _, p in pairs(new_progs) do
        debugNotify({title = "Started:", text = p.cmd})
        awful.util.spawn(p.cmd)
    end
    
end
