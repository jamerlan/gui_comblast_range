function widget:GetInfo()
  return {
    name      = "Comblast Range v2",
    desc      = "Draws a circle that displays commander blast range",
    author    = "TheFatController",
    date      = "January 24, 2009",
    license   = "MIT/X11",
    layer     = 0,
    version   = 2,
    enabled   = true  -- loaded by default
  }
end

-- project page on github: https://github.com/jamerlan/gui_comblast_range

--Changelog
-- v2 [teh]decay Fix spectator mode + replace hardcoded radius with one from weaponDef + handle luaui reload situation

local GetUnitPosition     = Spring.GetUnitPosition
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local spGetTeamUnits	= Spring.GetTeamUnits
local lower                 = string.lower

local blastCircleDivs = 100
local weapNamTab		  = WeaponDefNames
local weapTab		      = WeaponDefs
local udefTab				= UnitDefs

local explodeTag = "deathExplosion"
local selfdTag = "selfDExplosion"
local aoeTag = "damageAreaOfEffect"

local commanders = {}

local spectatorMode = false

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

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
      if commanders[unitID] then
        commanders[unitID] = nil
      end
    end
end

function widget:DrawWorldPreUnit()
  gl.DepthTest(true)

  for unitID in pairs(commanders) do
    local x,y,z = GetUnitPosition(unitID)
    local udef = udefTab[GetUnitDefID(unitID)]
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
    local _, _, spec, teamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    if spec then
        spectatorMode = true

        local roster = Spring.GetPlayerRoster(1, true)
        for _, player in ipairs(roster) do
            local teamId = player[3]
            if teamId ~= nil then
                Spring.Echo("teamId" .. teamId)
                for _, unitID in ipairs(spGetTeamUnits(teamId)) do
                    if udefTab[GetUnitDefID(unitID)].canManualFire then
                        commanders[unitID] = true
                    end
                end
            end
        end
    else
        for _, unitID in ipairs(spGetTeamUnits(teamId)) do
            if udefTab[GetUnitDefID(unitID)].canManualFire then
                commanders[unitID] = true
            end
        end
    end
end