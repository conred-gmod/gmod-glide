TOOL.Category = "Glide"
TOOL.Name = "#tool.glide_water_driving.name"

TOOL.Information = {
    { name = "left" },
    { name = "right" }
}

local function IsGlideVehicle( ent )
    return IsValid( ent ) and ent.IsGlideVehicle
end

local function GetGlideVehicle( trace )
    local ent = trace.Entity

    if IsGlideVehicle( ent ) then
        return ent
    end

    return false
end

function TOOL:LeftClick( trace )
    local veh = GetGlideVehicle( trace )
    if not veh then return false end

    if SERVER then
        if veh.wheelCount < 1 then
            Glide.SendNotification( self:GetOwner(), {
                text = "#tool.glide_water_driving.no_wheels",
                icon = "materials/icon16/cancel.png",
                sound = "glide/ui/radar_alert.wav",
                immediate = true
            } )

            return false
        end

        veh.traceData.mask = MASK_SOLID + MASK_WATER
    end

    return true
end

function TOOL:RightClick( trace )
    local veh = GetGlideVehicle( trace )
    if not veh then return false end

    if SERVER then
        veh.traceData.mask = nil
    end

    return true
end

function TOOL.BuildCPanel( panel )
    panel:AddControl( "Header", { Description = "#tool.glide_water_driving.desc" } )
end