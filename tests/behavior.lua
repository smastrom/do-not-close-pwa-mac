-- Run with Lua 5.3+ from the repository root.
local taps, front, hit = {}, nil, nil
local types = {leftMouseDown=1, leftMouseUp=2, keyDown=3}
hs = {
 logger={new=function() return {i=function() end,w=function() end} end},
 alert={show=function() end}, keycodes={map={q=12,w=13}},
 application={frontmostApplication=function() return front end,
 applicationForPID=function(pid) return pid == 42 and hit.app or nil end},
 axuielement={systemElementAtPosition=function() return hit end},
 eventtap={event={types=types},new=function(_, callback)
 local tap={callback=callback,running=false}
 function tap:start() self.running=true end
 function tap:stop() self.running=false end
 taps[#taps+1]=tap; return tap end},
}
local function app(bid)
 return {bundleID=function() return bid end,name=function() return 'Test' end,
 hide=function(self) self.hidden=true; return true end,
 kill=function(self) self.quit=true end}
end
local function event(kind,key,flags)
 return {getType=function() return kind end,getKeyCode=function() return key end,
 getFlags=function() return flags or {} end,location=function() return {x=100,y=100} end}
end
local spoon=dofile('DoNotClosePWA.spoon/init.lua'):start()
local mouse, key=taps[1].callback,taps[2].callback
for _,bid in ipairs({'com.apple.Safari.WebApp.93A0AD2F','com.google.Chrome.app.test','com.microsoft.edgemac.Dev.app.test'}) do
 front=app(bid)
 assert(key(event(3,13,{cmd=true})) == true and front.hidden)
 front.hidden=false
 assert(key(event(3,12,{cmd=true})) == true and front.hidden)
 assert(key(event(3,12,{cmd=true,alt=true})) == true and front.quit)
 assert(key(event(3,13,{cmd=true,ctrl=true})) == false)
 assert(key(event(3,13,{cmd=true,alt=true})) == false)
end
front=app('com.apple.Safari')
assert(key(event(3,13,{cmd=true})) == false and not front.hidden)
local background=app('com.apple.Safari.WebApp.background')
hit={app=background,attributeValue=function(_,name) if name=='AXSubrole' then return 'AXCloseButton' end end,pid=function() return 42 end}
assert(mouse(event(1)) == true and background.hidden and not front.hidden)
assert(mouse(event(2)) == true)
assert(mouse(event(2)) == false)
hit.attributeValue=function() return nil end
assert(mouse(event(1)) == false)
hit=nil
assert(mouse(event(1)) == false)
hs.axuielement.systemElementAtPosition=function() error('AX unavailable') end
assert(mouse(event(1)) == false)
spoon:start()
assert(not taps[1].running and not taps[2].running and taps[3].running)
spoon:stop()
assert(not taps[3].running and not taps[4].running)
print('All behavior checks passed')
