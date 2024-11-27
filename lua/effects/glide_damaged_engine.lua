local Clamp = math.Clamp
local RandomInt = math.random
local RandomFloat = math.Rand

local SMOKE_MAT = "particle/smokesprites_000"

function EFFECT:Init( data )
    local origin = data:GetOrigin()
    local angles = data:GetAngles()
    local velocity = data:GetStart()
    local health = data:GetColor() / 255
    local width = data:GetMagnitude() / 2000
    local scale = data:GetScale()

    local emitter = ParticleEmitter( origin, false )
    if not IsValid( emitter ) then return end

    local color = 255 * Clamp( health * 3, 0, 1 )
    local alpha = 120 * Clamp( 1 - health, 0, 1 )

    velocity[3] = velocity[3] + Clamp( velocity:Length() * 0.15, 0, 100 )

    local gravity = Vector( velocity[1], velocity[2], 0 )
    local right = angles:Right()
    local forward = angles:Forward()

    for _ = 1, 10 do
        local p = emitter:Add( SMOKE_MAT .. RandomInt( 9 ), origin + right * RandomFloat( -width, width ) )
        if p then
            p:SetDieTime( 0.8 )
            p:SetStartAlpha( alpha )
            p:SetEndAlpha( 0 )
            p:SetStartSize( 3 * scale )
            p:SetEndSize( 8 * scale )
            p:SetRoll( RandomFloat( -1, 1 ) )

            gravity[3] = velocity[3] + RandomFloat( 50, 100 ) * scale

            p:SetAirResistance( 120 )
            p:SetGravity( gravity )
            p:SetVelocity( velocity + forward * RandomInt( 20, 40 ) * scale )
            p:SetColor( color, color, color )
            p:SetLighting( true )
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end