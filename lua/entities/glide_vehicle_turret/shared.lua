AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Vehicle Turret"

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.BulletDamage = 10
ENT.BulletMaxDistance = 15000

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", "IsFiring" )
    self:NetworkVar( "Entity", "GunUser" )
    self:NetworkVar( "Entity", "GunBody" )
    self:NetworkVar( "Vector", "BulletOffset" )

    self:NetworkVar( "Float", "MinPitch" )
    self:NetworkVar( "Float", "MaxPitch" )
    self:NetworkVar( "Float", "MinYaw" )
    self:NetworkVar( "Float", "MaxYaw" )
end

local IsValid = IsValid
local CurTime = CurTime

function ENT:Think()
    local t = CurTime()

    if SERVER then
        self:NextThink( t )
    end

    if CLIENT then
        self:SetNextClientThink( t )
        self:UpdateSounds()
    end

    local parent = self:GetParent()
    local body = self:GetGunBody()

    if IsValid( parent ) and IsValid( body ) then
        self:UpdateTurret( parent, body, t )
    end

    return true
end

local Clamp = math.Clamp

function ENT:UpdateTurret( parent, body, t )
    local user = self:GetGunUser()

    -- Only let the server and the current user's client to run the logic below.
    if not SERVER and not ( CLIENT and LocalPlayer() == user ) then return end

    if IsValid( user ) then
        self:SetIsFiring( user:KeyDown( 1 ) ) -- IN_ATTACK

        if SERVER then
            SuppressHostEvents( user )
        end

        local fromPos = body:GetPos() + body:GetUp() * self:GetBulletOffset()[3]
        local aimPos = SERVER and user:GlideGetAimPos() or Glide.GetCameraAimPos()
        local dir = aimPos - fromPos
        dir:Normalize()

        local ang = parent:WorldToLocalAngles( dir:Angle() )

        ang[1] = Clamp( ang[1], self:GetMinPitch(), self:GetMaxPitch() )

        local minYaw, maxYaw = self:GetMinYaw(), self:GetMaxYaw()

        if minYaw ~= -1 and maxYaw ~= -1 then
            ang[2] = Clamp( ang[2], minYaw, maxYaw )
        end

        ang[3] = 0

        body:SetLocalAngles( ang )

        if CLIENT then
            self.nextPunch = self.nextPunch or 0

            if self:GetIsFiring() and t > self.nextPunch then
                self.nextPunch = t + 0.1
                Glide.Camera:ViewPunch( -0.03, math.Rand( -0.02, 0.02 ), 0 )
            end
        end
    end

    self.nextFire = self.nextFire or 0

    local isFiring = self:GetIsFiring()

    if isFiring and t > self.nextFire then
        local pos = body:LocalToWorld( self:GetBulletOffset() )
        local ang = body:GetAngles()

        self.nextFire = t + 0.05
        self:FireBullet( pos, ang, user, self:GetRight() )
    end
end

local PLAYER_COMPENSATION_OFFSET = Vector( 0, 0, -30 )

local TraceLine = util.TraceLine

function ENT:FireBullet( pos, ang, attacker, shellDir )
    local dir = ang:Forward()

    if SERVER then
        -- Get the last reported entity that the player thinks they were aiming at
        local ent = self:GetLastAimEntity( attacker )

        if IsValid( ent ) then
            local entPos = ent:IsPlayer() and ent:GetShootPos() + PLAYER_COMPENSATION_OFFSET or ent:GetPos()
            dir = entPos - pos
            dir:Normalize()
        end
    end

    local distance = self.BulletMaxDistance

    local tr = TraceLine( {
        start = pos,
        endpos = pos + dir * distance,
        filter = { self, self:GetParent() }
    } )

    if tr.Hit then
        distance = distance * tr.Fraction

        if CLIENT and IsValid( tr.Entity ) then
            -- Report to the server the last entity we are aiming at
            Glide.StartCommand( Glide.CMD_LAST_AIM_ENTITY, true )
            net.WriteEntity( tr.Entity )
            net.SendToServer()
        end
    end

    self:FireBullets( {
        Attacker = attacker,
        Damage = self.BulletDamage,
        Force = 100,
        Distance = distance,
        Dir = dir,
        Src = pos,
        HullSize = 2,
        Spread = Vector(),
        IgnoreEntity = self:GetParent(),
        TracerName = "MuzzleFlash",
        AmmoType = "SMG1"
    } )

    -- Muzzle flash & trace
    local eff = EffectData()
    eff:SetOrigin( pos )
    eff:SetStart( pos + dir * distance )
    eff:SetScale( 1 )
    eff:SetFlags( tr.Hit and 1 or 0 )
    eff:SetEntity( self )
    util.Effect( "glide_tracer", eff )

    -- Shells
    eff = EffectData()
    eff:SetOrigin( pos - dir * 30 )
    eff:SetEntity( self )
    eff:SetMagnitude( 1 )
    eff:SetRadius( 5 )
    eff:SetScale( 1 )

    -- Throw shells away from the body
    if not shellDir then
        shellDir = pos - self:GetPos()
        shellDir:Normalize()
    end

    eff:SetAngles( shellDir:Angle() )

    util.Effect( "RifleShellEject", eff )
end