-- Pixel glyph geometry: no native font calls, handle conversions or asset loading.
local M={}
function M.pixel(size) return math.max(1,math.floor(size/12+0.5)) end
function M.measure(text,size)
    local p=M.pixel(size);local left,bottom,right,top=0,0,0,0
    for i=1,#text do
        local g=AA.font_data[text:byte(i)] or AA.font_data[63]
        local b=g.bounds;local offset=(i-1)*8
        left=math.min(left,offset+b[1]);bottom=math.min(bottom,b[2])
        right=math.max(right,offset+b[3]);top=math.max(top,b[4])
    end
    return left*p,bottom*p,right*p,top*p
end
function M.draw(text,size,x,y,emit)
    local p=M.pixel(size)
    x=math.floor(x+0.5);y=math.floor(y+0.5)
    for i=1,#text do
        local g=AA.font_data[text:byte(i)] or AA.font_data[63]
        local offset=(i-1)*8*p
        for _,r in ipairs(g.runs) do emit(x+offset+r[1]*p,y+r[2]*p,r[3]*p,r[4]*p) end
    end
end
return M
