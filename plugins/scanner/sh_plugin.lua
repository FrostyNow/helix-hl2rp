local PLUGIN = PLUGIN

PLUGIN.name = "Player Scanners Util"
PLUGIN.description = "Adds functions that allow players to control scanners."
PLUGIN.author = "Chessnut, Riggs"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.lang.AddTable("english", {
	cmdPhotoCache = "Opens the scanner photo cache.",
	combineOnly = "Only Combine Players can view the scanner photo cache!",
	noScannerPlugin = "The server is missing the 'scanner' plugin.",
})
ix.lang.AddTable("korean", {
	cmdPhotoCache = "저장된 스캐너 사진을 확인합니다.",
	cacheCmbOnly = "콤바인 플레이어만 저장된 스캐너 사진을 확인할 수 있습니다!",
	noScannerPlugin = "이 서버에 'scanner' 플러그인이 없습니다.",
})

if ( CLIENT ) then
	PLUGIN.PICTURE_WIDTH = 580
	PLUGIN.PICTURE_HEIGHT = 420
end

ix.util.Include("sv_photos.lua")
ix.util.Include("cl_photos.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

ix.command.Add("PhotoCache", {
	description = "@cmdPhotoCache",
	OnRun = function(self, ply)
		if !(ply:IsCombine() and Schema:CanPlayerSeeCombineOverlay(ply)) then
			return "@cacheCmbOnly"
		end
		
		ply:ConCommand("ix_scanner_photocache")
	end
})