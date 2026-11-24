-- @description Backwash Receiver (SEND TO TRACK)
-- @author Ruslan Vislov
-- @version 1.0
-- @link Website https://vislovprod.com
-- @about
--   # Backwash Receiver
--   Background script for the SEND TO TRACK button of the Backwash JSFX plugin.
--   It saves the rendered result as a WAV file in the project folder and places
--   it on the selected track. Run it once; it can also start with REAPER.
-- @changelog
--   Initial release
-- Backwash: "SEND TO TRACK" receiver
-- Run this script once (Actions > Show action list > New action > Load ReaScript).
-- It keeps running in the background and waits for the SEND TO TRACK button
-- in the Backwash plugin. It writes a WAV file into the project folder
-- and places it on the selected track (or a new track if none is selected).

-- ============================================================================
-- AUTO-RUN SCRIPT ON REAPER STARTUP
-- ============================================================================
local EXT_SECTION = "ReverseReverbReceiver"
local EXT_KEY = "startup_choice"   -- "yes" / "no" (remembered between sessions)

local function AddToStartup()
    local _, _, sectionID, cmdID = reaper.get_action_context()
    local named = reaper.ReverseNamedCommandLookup(cmdID)
    if not named then return end   -- script is not registered as an action
    local namedID = "_" .. named
    local startupPath = reaper.GetResourcePath() .. "/Scripts/__startup.lua"

    local file = io.open(startupPath, "r")
    local content = file and file:read("*all") or ""
    if file then file:close() end

    -- already in startup: nothing to do
    if content:find(namedID, 1, true) then return end

    -- the user already answered before ("no" is remembered, so we never ask again)
    if reaper.GetExtState(EXT_SECTION, EXT_KEY) ~= "" then return end

    local answer = reaper.ShowMessageBox(
        "Start the Backwash receiver script automatically when REAPER starts?\n\n" ..
        "It is needed for the SEND TO TRACK button in the plugin.\n" ..
        "If you choose No, you will have to run the script manually after every REAPER restart.",
        "Backwash", 4)   -- 4 = Yes / No

    if answer == 6 then        -- Yes
        local block = "\n-- Start script: Backwash Receiver\n" ..
            "local backwash_cmd_name = '" .. namedID .. "'\n" ..
            "reaper.Main_OnCommand(reaper.NamedCommandLookup(backwash_cmd_name), 0)\n"
        file = io.open(startupPath, "a")
        if file then
            file:write(block)
            file:close()
            reaper.SetExtState(EXT_SECTION, EXT_KEY, "yes", true)
        else
            reaper.ShowMessageBox("Could not write to:\n" .. startupPath, "Backwash", 0)
        end
    else                       -- No
        reaper.SetExtState(EXT_SECTION, EXT_KEY, "no", true)
    end
end

AddToStartup()
-- ============================================================================
-- END OF STARTUP BLOCK
-- ============================================================================

local NS = "ReverseReverbSend"
local END_AT_CURSOR = true   -- true: item ENDS at the edit cursor (reverse swell leads into it)
                             -- false: item STARTS at the edit cursor

reaper.gmem_attach(NS)

local function write_wav(path, n, sr)
  local f = io.open(path, "wb")
  if not f then return false end
  local data_bytes = n * 2 * 4
  f:write("RIFF", string.pack("<I4", 4 + (8 + 16) + (8 + 4) + (8 + data_bytes)), "WAVE")
  f:write("fmt ", string.pack("<I4I2I2I4I4I2I2", 16, 3, 2, sr, sr * 8, 8, 32))
  f:write("fact", string.pack("<I4I4", 4, n))
  f:write("data", string.pack("<I4", data_bytes))
  local i = 0
  while i < n do
    local cnt = math.min(2048, n - i)
    local vals = {}
    for k = 0, cnt - 1 do
      local idx = 16 + 2 * (i + k)
      vals[#vals + 1] = reaper.gmem_read(idx)
      vals[#vals + 1] = reaper.gmem_read(idx + 1)
    end
    f:write(string.pack("<" .. string.rep("f", #vals), table.unpack(vals)))
    i = i + cnt
  end
  f:close()
  return true
end

local function insert_item(n, sr)
  local dir = reaper.GetProjectPath("")
  if not dir or dir == "" then dir = reaper.GetResourcePath() .. "/ReverseReverb" end
  reaper.RecursiveCreateDirectory(dir, 0)
  local sep = package.config:sub(1, 1)
  local path = dir .. sep .. os.date("ReverseReverb_%Y%m%d_%H%M%S") .. ".wav"
  if not write_wav(path, n, sr) then
    reaper.ShowMessageBox("Could not write file:\n" .. path, "Backwash", 0)
    return
  end

  reaper.Undo_BeginBlock()
  local tr = reaper.GetSelectedTrack(0, 0)
  if not tr then
    reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
    tr = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "Backwash", true)
  end

  local src = reaper.PCM_Source_CreateFromFile(path)
  if not src then
    reaper.ShowMessageBox("Could not open file:\n" .. path, "Backwash", 0)
    reaper.Undo_EndBlock("Insert Backwash item", -1)
    return
  end
  -- build the peak cache right away, otherwise the waveform may be missing / wrong when zooming out
  if reaper.PCM_Source_BuildPeaks(src, 0) ~= 0 then
    while reaper.PCM_Source_BuildPeaks(src, 1) ~= 0 do end
    reaper.PCM_Source_BuildPeaks(src, 2)
  end
  local len = reaper.GetMediaSourceLength(src)
  local cur = reaper.GetCursorPosition()
  local pos = END_AT_CURSOR and math.max(0, cur - len) or cur

  local item = reaper.AddMediaItemToTrack(tr)
  local take = reaper.AddTakeToMediaItem(item)
  reaper.SetMediaItemTake_Source(take, src)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len)
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "Backwash", true)
  reaper.UpdateItemInProject(item)
  reaper.Undo_EndBlock("Insert Backwash item", -1)
  reaper.UpdateArrange()
end

local function loop()
  if reaper.gmem_read(0) == 1 then
    local n = math.floor(reaper.gmem_read(1))
    local sr = math.floor(reaper.gmem_read(2) + 0.5)
    if n > 0 and sr > 0 then insert_item(n, sr) end
    reaper.gmem_write(0, 0)
  end
  reaper.defer(loop)
end

loop()
