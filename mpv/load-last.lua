-- Load last watched video via keybind
--
-- =======
-- License
-- =======
--
-- load-last.lua - enables functionality to enable a keybind to load last
--                 watched video in mpv
-- Copyright (C) 2025  Ira Peach
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU Affero General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
-- details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
-- ============
-- Installation
-- ============
--
-- 1. Place in mpv's scripts/ directory (win32 "%APPDATA%/mpv/script"; unix
--    "~/.config/mpv").
--
-- 2. Configure watch history saving in mpv.conf (win32
--    "%APPDATA%/mpv/mpv.conf"; unix "~/.config/mpv/mpv.conf"):
--
--      # Enable watch history (required for load_last/load-last-watched and
--      # select/select-watch-history)
--      save-watch-history
--
-- 3. (optional) Enable position saving in mpv.conf:
--
--      # Enable position saving
--      save-position-on-quit=yes
--      resume-playback=yes
--      write-filename-in-watch-later-config
--
-- 4. Configure the following binding in input.conf (win32
--    "%APPDATA%/mpv/input.conf"; unix "~/.config/mpv/input.conf"):
--
--      g-i script-binding load_last/load-last-watched
--
--    (you may change this to a suitable keybinding)
--
-- Ensure you have watch history via the g-h menu.  Once you do, you should be
-- able to close the menu and use g-i to open the first menu item without going
-- into the menu.

mp = require("mp")
utils = require("mp.utils")

function expand_path(path)
    return mp.command_native({"expand-path", path})
end

function p(property)
    return mp.get_property_native(property)
end

function pp(property)
    value = p(property)
    if value == nil then
        value = "nil"
    else
        value = "'" .. value .. "'"
    end
    print("property '" .. property .. "': " .. value .. "")
end

function load_last_watched()
    local current_file = mp.get_property("filename") or ""
    local save_watch_history = p("save-watch-history")
    if not save_watch_history then
        print("save-watch-history is false; not proceeding.")
        return
    end
    local watch_history_path = mp.get_property("watch-history-path")
    print("watch_history_path = '" .. watch_history_path .. "'")
    print("save-watch-history is true; proceeding.")
    local history_file_path = mp.command_native(
        {"expand-path", mp.get_property("watch-history-path")})
    local history_file, error_message = io.open(history_file_path)
    if not history_file then
        show_warning(mp.get_property_native("save-watch-history")
                     and error_message
                     or "Enable --save-watch-history to jump to recently played files.")
        return
    end
    local last_line = nil
    for line in history_file:lines() do
        last_line = line
    end
    if not last_line then
        mp.msg.warn("No history entries.")
        history_file:close()
        return
    end
    local entry = utils.parse_json(last_line)
    history_file:close()
    if not (entry and entry.path) then
        mp.msg.warn(history_file_path .. ": Parse error at last_line 1")
        return
    end
    mp.commandv("loadfile", entry.path)
end

-- script-binding load_last/load-last-watched
mp.add_key_binding(nil, "load-last-watched", load_last_watched)
mp.register_script_message("load-last-watched", load_last_watched)
