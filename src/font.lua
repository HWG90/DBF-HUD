-- Pixel glyph geometry: no native font calls, handle conversions or asset loading.
local M={}
function M.pixel(size) return math.max(1,math.floor(size/12+0.5)) end
function M.supported(name) return name=='bigblue' or (HUD.nerd_font_data and HUD.nerd_font_data[name]~=nil) end
function M.measure(text,size,name)
    local face=HUD.nerd_font_data and HUD.nerd_font_data[name or 'bigblue']
    if face then
        local scale=size/face.em;local left,bottom,right,top,offset=0,0,0,0,0
        for i=1,#text do local g=face.glyphs[text:byte(i)] or face.glyphs[63];local b=g.bounds
            left=math.min(left,offset+b[1]);bottom=math.min(bottom,b[2]);right=math.max(right,offset+b[3]);top=math.max(top,b[4]);offset=offset+g.advance
        end
        return left*scale,bottom*scale,right*scale,top*scale
    end
    local p=M.pixel(size);local left,bottom,right,top=0,0,0,0
    for i=1,#text do
        local g=HUD.font_data[text:byte(i)] or HUD.font_data[63]
        local b=g.bounds;local offset=(i-1)*8
        left=math.min(left,offset+b[1]);bottom=math.min(bottom,b[2])
        right=math.max(right,offset+b[3]);top=math.max(top,b[4])
    end
    return left*p,bottom*p,right*p,top*p
end
function M.draw(text,size,x,y,emit,name)
    local face=HUD.nerd_font_data and HUD.nerd_font_data[name or 'bigblue']
    if face then
        local scale=size/face.em;local offset=0
        for i=1,#text do local g=face.glyphs[text:byte(i)] or face.glyphs[63]
            for _,r in ipairs(g.runs) do emit(x+(offset+r[1])*scale,y+r[2]*scale,r[3]*scale,r[4]*scale) end
            offset=offset+g.advance
        end
        return
    end
    local p=M.pixel(size)
    x=math.floor(x+0.5);y=math.floor(y+0.5)
    for i=1,#text do
        local g=HUD.font_data[text:byte(i)] or HUD.font_data[63]
        local offset=(i-1)*8*p
        for _,r in ipairs(g.runs) do emit(x+offset+r[1]*p,y+r[2]*p,r[3]*p,r[4]*p) end
    end
end
return M
