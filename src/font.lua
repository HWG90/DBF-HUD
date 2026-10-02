-- Native text bounds; no rectangle glyph renderer.
local M={}
function M.supported(name)return HUD.native_font_data.faces[name or 'bigblue']~=nil end
function M.measure(text,size,name,continuous)
    local face=HUD.native_font_data.faces[name or 'bigblue']
    local sr=rawget(_G,'stingray')
    if sr and HUD.native_font then local f,m,active=HUD.native_font.resolve(sr,name,false);face=active end
    if not face then return 0,-size*.2,#text*size*.6,size*.8 end
    local factor=size/face.em;local left,bottom,right,top,offset=0,0,0,0,0
    local digits=text:match('^(%d%d%d%d*)')
    local fixed
    if digits then
        fixed={0,0,0,0,0}
        for digit=48,57 do local g=face.glyphs[digit] or face.glyphs[63];fixed[1]=math.max(fixed[1],g[1]);fixed[2]=math.min(fixed[2],g[2]);fixed[3]=math.min(fixed[3],g[3]);fixed[4]=math.max(fixed[4],g[4]);fixed[5]=math.max(fixed[5],g[5]) end
    end
    for i=1,#text do
        local g=face.glyphs[text:byte(i)] or face.glyphs[63]
        if fixed and i<=#digits then g=fixed end
        left=math.min(left,offset+g[2]);bottom=math.min(bottom,g[3])
        right=math.max(right,offset+g[4]);top=math.max(top,g[5]);offset=offset+g[1]
    end
    return left*factor,bottom*factor,right*factor,top*factor
end
function M.numeric_parts(command)
    local digits=command.numeric_display and command.text:match('^(%d%d%d%d*)')
    if not digits then return {{text=command.text,dx=0,alpha=1}} end
    local face=HUD.native_font_data.faces[command.font or 'bigblue']
    local sr=rawget(_G,'stingray')
    if sr then local f,m,active=HUD.native_font.resolve(sr,command.font,false);face=active end
    local advance=command.size*.6
    if face then
        advance=0
        for digit=48,57 do advance=math.max(advance,(face.glyphs[digit] or face.glyphs[63])[1]*command.size/face.em) end
    end
    local leading=digits:match('^(0*)') or '';local dim=math.min(#leading,#digits-1)
    local parts={}
    for i=1,#digits do parts[#parts+1]={text=digits:sub(i,i),dx=(i-1)*advance,alpha=i<=dim and 1/3 or 1} end
    if #command.text>#digits then parts[#parts+1]={text=command.text:sub(#digits+1),dx=#digits*advance,alpha=1} end
    return parts
end
return M
