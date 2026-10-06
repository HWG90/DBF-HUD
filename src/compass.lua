local M={}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.heading(matrix)
    if not matrix or not finite(matrix[5]) or not finite(matrix[6]) then return nil end
    if matrix[5]^2+matrix[6]^2<1e-8 then return nil end
    return math.deg(math.atan2(matrix[5],matrix[6]))%360
end
function M.ticks(heading)
    if not finite(heading)then return nil end
    heading=heading%360;local out={};local names={'N','NE','E','SE','S','SW','W','NW'}
    for angle=0,345,15 do
        local delta=(angle-heading+180)%360-180
        if math.abs(delta)<=90 then out[#out+1]={position=(delta+90)/180,label=angle%45==0 and names[angle/45+1] or nil}end
    end
    return out,heading
end
return M
