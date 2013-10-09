function widget:GetInfo()
    return {
        name      = "Comblast Range v7",
        desc      = "Draws a circle that displays commander blast range",
        author    = "TheFatController and [teh]decay",
        date      = "January 24, 2009",
        license   = "MIT/X11",
        layer     = 0,
        version   = 7,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/jamerlan/gui_comblast_range

--Changelog
-- v2 [teh]decay Fix spectator mode + replace hardcoded radius with one from weaponDef + handle luaui reload situation
-- v3 [teh]decay Draw circles for visible enemy commanders too! +Fix spectator mode when /fullspecview is used + code speedup
-- v4 [teh]decay Some minor improvements and fixes
-- v5 [teh]decay fix spectator mode again (thx to jK)
-- v6 [teh]decay True dgun radius added
-- v7 [teh]decay Handle shared commanders correctly

local GetUnitPosition     = Spring.GetUnitPosition
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local lower                 = string.lower
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo

local blastCircleDivs = 100
local weapNamTab		  = WeaponDefNames
local weapTab		      = WeaponDefs
local udefTab				= UnitDefs

local explodeTag = "deathExplosion"
local selfdTag = "selfDExplosion"
local aoeTag = "damageAreaOfEffect"

local dgunRange = WeaponDefNames["armcom_arm_disintegrator"].range + WeaponDefNames["armcom_arm_disintegrator"].damageAreaOfEffect

local commanders = {}

local spectatorMode = false
local notInSpecfullmode = false

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if UnitDefs[unitDefID].canManualFire then
        commanders[unitID] = true
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if commanders[unitID] then
        commanders[unitID] = nil
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not spectatorMode then
        local unitDefID = GetUnitDefID(unitID)
        if UnitDefs[unitDefID].canManualFire then
            commanders[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if UnitDefs[unitDefID].canManualFire then
        commanders[unitID] = true
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if UnitDefs[unitDefID].canManualFire then
        commanders[unitID] = true
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if UnitDefs[unitDefID].canManualFire then
        commanders[unitID] = true
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
        if commanders[unitID] then
            commanders[unitID] = nil
        end
    end
end

function widget:DrawWorldPreUnit()
    local _, specFullView, _ = spGetSpectatingState()

    if not specFullView then
        notInSpecfullmode = true
    else
        if notInSpecfullmode then
            detectSpectatorView()
        end
        notInSpecfullmode = false
    end

    gl.DepthTest(true)

    for unitID in pairs(commanders) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]
            local blastRadius = 380;

            local deathBlastId = weapNamTab[lower(udef[explodeTag])].id
            local selfdBlastId = weapNamTab[lower(udef[selfdTag])].id

            local deathBlastRadius = weapTab[deathBlastId][aoeTag]
            local selfdBlastRadius = weapTab[selfdBlastId][aoeTag]

            if deathBlastRadius ~= selfdBlastRadius then
                gl.Color(1, 0, 0, .5)
                glDrawGroundCircle(x, y, z, deathBlastRadius, blastCircleDivs)
            end

            gl.Color(1, 1, 0, .5)
            glDrawGroundCircle(x, y, z, selfdBlastRadius, blastCircleDivs)

            gl.Color(0, 0, 1, .5)
            glDrawGroundCircle(x, y, z, dgunRange, blastCircleDivs)
        end
    end
    gl.DepthTest(false)
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function widget:Initialize()
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = spGetPlayerInfo(spGetMyPlayerID())

    if spec then
        spectatorMode = true
    end

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local udefId = GetUnitDefID(unitID)
            if udefId ~= nil then
                if udefTab[udefId].canManualFire then
                    commanders[unitID] = true
                end
            end
        end
    end
end
