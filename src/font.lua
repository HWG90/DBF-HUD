-- Native text bounds; no rectangle glyph renderer.
local M={}
function M.supported(name)return HUD.native_font_data.faces[name or 'bigblue']~=nil end
function M.measure(text,size,name,continuous)
    local face=HUD.native_font_data.faces[name or 'bigblue']
    local sr=rawget(_G,'stingray')
    if sr and HUD.native_font then local f,m,active=HUD.native_font.resolve(sr,name,false);face=active end
    if not face then return 0,-size*.2,#text*size*.6,size*.8 end
    local factor=size/face.em;local left,bottom,right,top,offset=0,0,0,0,0
    for i=1,#text do
        local g=face.glyphs[text:byte(i)] or face.glyphs[63]
        left=math.min(left,offset+g[2]);bottom=math.min(bottom,g[3])
        right=math.max(right,offset+g[4]);top=math.max(top,g[5]);offset=offset+g[1]
    end
    return left*factor,bottom*factor,right*factor,top*factor
end
return M
