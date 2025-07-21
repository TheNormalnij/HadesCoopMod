-- This files has modifed Super Giant Games code
-- Not licensed

---@class GameModifed
local GameModifed = {}

function GameModifed.AdvancedTooltipModifedHandler(triggerArgs)
    if IsScreenOpen("Codex") then
        AttemptOpenCodexBoonInfo()
        return
    end

    if ScreenAnchors.RunDepthId == nil then
        ShowDepthCounter()
    else
        HideDepthCounter()
    end

    if ( not IsInputAllowed({}) and not GameState.WaitingForChoice ) or ( CurrentRun ~= nil and CurrentRun.Hero == nil ) or ( CurrentDeathAreaRoom ~= nil and CurrentDeathAreaRoom.ShowResourceUIOnly ) then
        return
    end

    if ScreenAnchors.TraitTrayScreen ~= nil and ScreenAnchors.TraitTrayScreen.CanClose then
        CloseAdvancedTooltipScreen()
    else
        ShowDepthCounter()
        ShowAdvancedTooltip( { AutoPin = false, } )
    end
end

return GameModifed
