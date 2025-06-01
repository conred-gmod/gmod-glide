
if not Glide.ACFIntegration then
    function Glide.FireFlare(pos, ang, vel, owner)
        local flare = ents.Create( "glide_flare" )
        flare:SetPos( startPos )
        flare:SetAngles( ang )
        flare:SetOwner( owner )
        flare:Spawn()

        local phys = flare:GetPhysicsObject()

        if IsValid( phys ) then
            phys:SetVelocityInstantaneous( vel + flare:GetForward() * 1000 )
        end
    end

    local flares = Glide.flares or {}

    Glide.flares = flares

    function Glide.TrackFlare( flare )
        flares[#flares + 1] = flare
    end

    local IsValid = IsValid
    local flarePos, flareDir, dist
    local closestDist, closestEnt

    function Glide.GetClosestFlare( pos, dir, radius )
        closestDist = radius * radius
        closestEnt = nil

        for _, ent in ipairs( flares ) do
            if IsValid( ent ) then
                flarePos = ent:GetPos()
                flareDir = flarePos - pos
                flareDir:Normalize()

                dist = pos:DistToSqr( flarePos )

                if dist < closestDist and dir:Dot( flareDir ) > 0.2 then
                    closestDist = dist
                    closestEnt = ent
                end
            end
        end

        return closestEnt, closestDist
    end

    -- Periodically cleanup the flares table
    local Remove = table.remove

    timer.Create( "Glide.CleanupFlares", 1, 0, function()
        for i = #flares, 1, -1 do
            if not IsValid( flares[i] ) then
                Remove( flares, i )
            end
        end
    end )

else
    function Glide.FireFlare(pos, ang, vel, owner)
        local avgFac = 1 - math.Rand(0.5,1.0)
        -- From ACE:
        -- 513 is 300 temperature for a standard 40mm flare. This is 1x an aircraft moving at 300 mph. I've added some extra measure. 1.71 * temp needed.
        local temp = 641 * avgFac 

        ACF_CreateFlare(pos, vel + ang:Forward() * 1000, owner, {
            Lifetime = 80,
            Temp = temp,
            RadarSig = 0.1
        })
    end
end

