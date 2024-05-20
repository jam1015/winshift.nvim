local config = require("winshift.config")
local api = vim.api
local M = {}

--#region TYPES

---@class HiSpec
---@field fg string
---@field bg string
---@field ctermfg integer
---@field ctermbg integer
---@field gui string
---@field sp string
---@field blend integer
---@field default boolean

---@class HiLinkSpec
---@field force boolean
---@field default boolean

--#endregion

---@param name string Syntax group name.
---@param attr string Attribute name.
---@param trans boolean Translate the syntax group (follows links).
function M.get_hl_attr(name, attr, trans)
  local id = api.nvim_get_hl_id_by_name(name)
  if id and trans then
    id = vim.fn.synIDtrans(id)
  end
  if not id then
    return
  end

  local value = vim.fn.synIDattr(id, attr)
  if not value or value == "" then
    return
  end

  return value
end

---@param groups string|string[] Syntax group name, or an ordered list of
---groups where the first found value will be returned.
---@param trans boolean Translate the syntax group (follows links). True by default.
function M.get_fg(groups, trans)
  if type(trans) ~= "boolean" then trans = true end

  if type(groups) == "table" then
    local v
    for _, group in ipairs(groups) do
      v = M.get_hl_attr(group, "fg", trans)
      if v then return v end
    end
    return
  end

  return M.get_hl_attr(groups, "fg", trans)
end

---@param groups string|string[] Syntax group name, or an ordered list of
---groups where the first found value will be returned.
---@param trans boolean Translate the syntax group (follows links). True by default.
function M.get_bg(groups, trans)
  if type(trans) ~= "boolean" then trans = true end

  if type(groups) == "table" then
    local v
    for _, group in ipairs(groups) do
      v = M.get_hl_attr(group, "bg", trans)
      if v then return v end
    end
    return
  end

  return M.get_hl_attr(groups, "bg", trans)
end

---@param groups string|string[] Syntax group name, or an ordered list of
---groups where the first found value will be returned.
---@param trans boolean Translate the syntax group (follows links). True by default.
function M.get_gui(groups, trans)
  if type(trans) ~= "boolean" then trans = true end
  if type(groups) ~= "table" then groups = { groups } end

  local hls
  for _, group in ipairs(groups) do
    hls = {}
    local attributes = {
      "bold",
      "italic",
      "reverse",
      "standout",
      "underline",
      "undercurl",
      "strikethrough"
    }

    for _, attr in ipairs(attributes) do
      if M.get_hl_attr(group, attr, trans) == "1" then
        table.insert(hls, attr)
      end
    end

    if #hls > 0 then
      return table.concat(hls, ",")
    end
  end
end

---@param group string Syntax group name.
---@param opt HiSpec
function M.hi(group, opt)
  local use_tc = vim.o.termguicolors
  local g = use_tc and "gui" or "cterm"

  if not use_tc then
    if opt.ctermfg then
      opt.fg = opt.ctermfg
    end
    if opt.ctermbg then
      opt.bg = opt.ctermbg
    end

    local fg_256 = M.rgbtox256(opt.fg)
    local bg_256 = M.rgbtox256(opt.bg)

		if fg_256 then
			opt.fg = fg_256
		end

		if bg_256 then
			opt.bg = bg_256
		end
  end

  vim.cmd(string.format(
    "hi %s %s %s %s %s %s %s",
    opt.default and "def" or "",
    group,
    opt.fg and (g .. "fg=" .. opt.fg) or "",
    opt.bg and (g .. "bg=" .. opt.bg) or "",
    opt.gui and ((use_tc and "gui=" or "cterm=") .. opt.gui) or "",
    opt.sp and ("guisp=" .. opt.sp) or "",
    opt.blend and ("blend=" .. opt.blend) or ""
  ))
end

---@param from string Syntax group name.
---@param to? string Syntax group name. (default: `"NONE"`)
---@param opt? HiLinkSpec
function M.hi_link(from, to, opt)
  opt = opt or {}
  vim.cmd(string.format(
    "hi%s %s link %s %s",
    opt.force and "!" or "",
    opt.default and "default" or "",
    from,
    to or "NONE"
  ))
end

function M.get_colors()
  return {
    white = M.get_fg("Normal") or "White",
    red = M.get_fg("Keyword") or "Red",
    green = M.get_fg("Character") or "Green",
    yellow = M.get_fg("PreProc") or "Yellow",
    blue = M.get_fg("Include") or "Blue",
    purple = M.get_fg("Define") or "Purple",
    cyan = M.get_fg("Conditional") or "Cyan",
    dark_red = M.get_fg("Keyword") or "DarkRed",
    orange = M.get_fg("Number") or "Orange",
  }
end

function M.get_hl_groups()
  local hl_focused = config.get_config().focused_hl_group
  local reverse = M.get_hl_attr(hl_focused, "reverse") == "1"
  local bg_focused = reverse
    and (M.get_fg({ hl_focused, "Normal" }) or "white")
    or (M.get_bg({ hl_focused, "Normal" }) or "white")
  local fg_focused = reverse and (M.get_bg({ hl_focused, "Normal" }) or "black") or nil

  return {
    Normal = { fg = fg_focused, bg = bg_focused },
    EndOfBuffer = { fg = bg_focused, bg = bg_focused },
    LineNr = { fg = M.get_fg("LineNr"), bg = bg_focused, gui = M.get_gui("LineNr") },
    CursorLineNr = { fg = M.get_fg("CursorLineNr"), bg = bg_focused, gui = M.get_gui("CursorLineNr") },
    SignColumn = { fg = M.get_fg("SignColumn"), bg = bg_focused },
    FoldColumn = { fg = M.get_fg("FoldColumn"), bg = bg_focused },
    WindowPicker = { fg = "#ededed", bg = "#4493c8", ctermfg = 255, ctermbg = 33, gui = "bold" },
  }
end

M.hl_links = {
  LineNrAbove = "WinShiftLineNr",
  LineNrBelow = "WinShiftLineNr",
}

------------------------ begin ISC licensed code
-- translated from the code found in colour.c in tmux

-- Copyright (c) 2008 Nicholas Marriott <nicholas.marriott@gmail.com>
-- Copyright (c) 2016 Avi Halachmi <avihpit@yahoo.com>

-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


local function hex_to_rgb(hex)
  -- Check if the input is a string
  if type(hex) ~= "string" then
    return nil
  end

  if string.match(hex, "^#%x%x%x%x%x%x$") then
    local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  else
    return nil, nil, nil
  end
end

function M.v2ci(v)
  if v < 48 then return 0
  elseif v < 115 then return 1
  else return math.floor((v - 35) / 40)
  end
end

function M.color_index(ir, ig, ib)
  return 36 * ir + 6 * ig + ib
end

function M.dist_square(A, B, C, a, b, c)
  return (A-a)^2 + (B-b)^2 + (C-c)^2
end

-- checkss if input is a  hex value, if it is return a similar 256 value integer, else return nil
function M.rgbtox256(hex)
  local r, g, b = hex_to_rgb(hex)
  if r == nil then return nil end

  local ir, ig, ib = M.v2ci(r), M.v2ci(g), M.v2ci(b)
  local average = (r + g + b) / 3
  local gray_index = average > 238 and 23 or math.floor((average - 3) / 10)
  local i2cv = {0, 0x5f, 0x87, 0xaf, 0xd7, 0xff}
  local cr, cg, cb = i2cv[ir + 1], i2cv[ig + 1], i2cv[ib + 1]
  local gv = 8 + 10 * gray_index

  local color_err = M.dist_square(cr, cg, cb, r, g, b)
  local gray_err = M.dist_square(gv, gv, gv, r, g, b)

  if color_err <= gray_err then
    return 16 + M.color_index(ir, ig, ib)
  else
    return 232 + gray_index
  end
end
---------------------- end ISC licensed code


function M.setup()
  for name, opt in pairs(M.get_hl_groups()) do
    M.hi("WinShift" .. name, opt)
  end

  for from, to in pairs(M.hl_links) do
    M.hi_link("WinShift" .. from, to, { default = true })
  end
end

return M
