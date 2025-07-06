Versuta_son_dog = class({})

LinkLuaModifier( "modifier_versuta_dog", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_versuta_dog_debuff", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_birzha_stunned", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_birzha_bashed", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )

modifier_versuta_dog = class({})

function Versuta_son_dog:Precache(context)
    PrecacheResource("model", "models/creeps/knoll_1/werewolf_boss.vmdl", context)
    PrecacheResource("model", "models/items/courier/shibe_dog_cat/shibe_dog_cat.vmdl", context)
    local particle_list = 
    {
        "particles/units/heroes/hero_lion/lion_spell_voodoo.vpcf",
        "particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf",
        "particles/units/heroes/hero_lycan/lycan_shapeshift_revert.vpcf",
        "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf",
        "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf",
        "particles/units/heroes/hero_ursa/ursa_overpower_buff.vpcf",
        "particles/versuta_status_over.vpcf",
        "particles/units/heroes/hero_pudge/pudge_dismember.vpcf",
        "particles/econ/items/pudge/pudge_immortal_arm/pudge_immortal_arm_rot_gold.vpcf",
    }
    for _, particle_name in pairs(particle_list) do
        PrecacheResource("particle", particle_name, context)
    end
    PrecacheResource("model", "models/items/lycan/ultimate/thegreatcalamityti4/thegreatcalamityti4.vmdl", context)
end

function Versuta_son_dog:GetIntrinsicModifierName()
    return "modifier_versuta_dog"
end

function Versuta_son_dog:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level ) + self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_4")
end

function modifier_versuta_dog:IsHidden()
    return true
end

function modifier_versuta_dog:IsPurgable() return false end

function modifier_versuta_dog:DeclareFunctions()
    local decFuncs =
    {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return decFuncs
end

function modifier_versuta_dog:OnAttackLanded( params )
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if params.target:IsWard() then return end
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    if params.attacker:PassivesDisabled() then return end
    if params.attacker:IsIllusion() then return end
    if not self:GetAbility():IsFullyCastable() then return end

    if not self:GetCaster():HasShard() then
        if params.target:IsMagicImmune() then
            return
        end
    end

    self:GetAbility():UseResources(false, false, false, true)
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_voodoo.vpcf", PATTACH_CUSTOMORIGIN, params.target)     
    ParticleManager:SetParticleControl(self.particle, 0, params.target:GetAbsOrigin())      
    ParticleManager:ReleaseParticleIndex(self.particle)

    if params.target:IsIllusion() then
        params.target:ForceKill(true)
    else
        params.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_versuta_dog_debuff", {duration = duration * (1 - params.target:GetStatusResistance())})
        params.target:EmitSound("Hero_Lion.Hex.Target")
        self:GetParent():EmitSound("versutadog")
    end
end

modifier_versuta_dog_debuff = class({})

function modifier_versuta_dog_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_MODEL_SCALE
    }

    return funcs
end

function modifier_versuta_dog_debuff:GetModifierModelChange()
    return "models/items/courier/shibe_dog_cat/shibe_dog_cat.vmdl"
end

function modifier_versuta_dog_debuff:GetModifierMoveSpeedOverride()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_versuta_dog_debuff:CheckState()
    local state = 
    {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_HEXED] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_SILENCED] = true
    }
    if self:GetCaster():HasTalent("special_bonus_birzha_versuta_5") then
        state = 
        {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_HEXED] = true,
            [MODIFIER_STATE_MUTED] = true,
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_PASSIVES_DISABLED] = true
        }
    end
    return state
end

LinkLuaModifier( "modifier_transform_dog", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_versuta_dog_ultimate", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_versuta_dog_ultimate_speed", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )

Versuta_dog_change = class({})

function Versuta_dog_change:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level ) + self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_2")
end

function Versuta_dog_change:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Versuta_dog_change:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local transformation_time = ability:GetSpecialValueFor("transformation_time")
    local duration = ability:GetSpecialValueFor("duration")
    if not IsServer() then return end
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(self.particle, 0 , caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 1 , caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 2 , caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 3 , caster:GetAbsOrigin())
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    caster:EmitSound("versutault")
    caster:AddNewModifier(caster, ability, "modifier_transform_dog", {duration = transformation_time})
    Timers:CreateTimer(transformation_time, function()
        caster:AddNewModifier(caster, ability, "modifier_versuta_dog_ultimate", {duration = duration})
    end)    
end

modifier_transform_dog = class({})

function modifier_transform_dog:CheckState()   
    local state = {[MODIFIER_STATE_STUNNED] = true}
    return state    
end

function modifier_transform_dog:IsHidden()
    return true
end
function modifier_transform_dog:IsPurgable() return false end

function modifier_transform_dog:OnDestroy()
    if not IsServer() then return end     
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_revert.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(particle, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 3, self:GetCaster():GetAbsOrigin())     
end

modifier_versuta_dog_ultimate = class({})

function modifier_versuta_dog_ultimate:IsPurgable() return false end

function modifier_versuta_dog_ultimate:DeclareFunctions()  
    local decFuncs = 
    {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
    }
    return decFuncs 
end

function modifier_versuta_dog_ultimate:GetModifierModelChange()
    return "models/items/lycan/ultimate/thegreatcalamityti4/thegreatcalamityti4.vmdl"
end

function modifier_versuta_dog_ultimate:GetEffectName()
    return "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf"
end

function modifier_versuta_dog_ultimate:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_versuta_dog_ultimate:OnCreated()
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    self.crit_chance = self:GetAbility():GetSpecialValueFor("crit_chance") + self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_7")
    self.crit_damage = self:GetAbility():GetSpecialValueFor("crit_damage")  
    if not IsServer() then return end
    self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_versuta_dog_ultimate_speed", { duration = duration } )
end

function modifier_versuta_dog_ultimate:OnRefresh()
    self:OnCreated()
end

function modifier_versuta_dog_ultimate:GetModifierPreAttack_CriticalStrike()
    if not IsServer() then return end                  
    if RollPercentage(self.crit_chance) then        
        return self.crit_damage
    end
    return nil
end

modifier_versuta_dog_ultimate_speed = class({})

function modifier_versuta_dog_ultimate_speed:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
    }

    return funcs
end
function modifier_versuta_dog_ultimate_speed:GetModifierMoveSpeed_Absolute()
    return 650
end

function modifier_versuta_dog_ultimate_speed:IsHidden()
    return true
end

function modifier_versuta_dog_ultimate_speed:IsPurgable() return false end

function modifier_versuta_dog_ultimate_speed:OnCreated()
    if IsServer() then
        self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddParticle(self.particle, false, false, -1, false, false)
    end
end

LinkLuaModifier( "modifier_versuta_rage_buff", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )

Versuta_Rage = class({})

function Versuta_Rage:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function Versuta_Rage:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Versuta_Rage:OnSpellStart()
    if not IsServer() then return end  
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")

    caster:EmitSound("Hero_Ursa.Overpower")

    caster:EmitSound("versutaursa")

    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_3)

    if caster:HasModifier("modifier_versuta_rage_buff") then
        caster:RemoveModifierByName("modifier_versuta_rage_buff")
    end

    caster:AddNewModifier(caster, ability, "modifier_versuta_rage_buff", {duration = duration})
end

modifier_versuta_rage_buff = class({})

function modifier_versuta_rage_buff:IsPurgable() return true end

function modifier_versuta_rage_buff:OnCreated()
    local max_attacks = self:GetAbility():GetSpecialValueFor("max_attacks") + self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_1")
    self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")

    if not IsServer() then return end 
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_overpower_buff.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
    ParticleManager:SetParticleControlEnt(particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 2, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    self:AddParticle(particle, false, false, -1, false, false)

    self:SetStackCount(max_attacks)
end

function modifier_versuta_rage_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_versuta_rage_buff:StatusEffectPriority()
    return 10
end

function modifier_versuta_rage_buff:GetStatusEffectName()
    return "particles/versuta_status_over.vpcf"
end

function modifier_versuta_rage_buff:DeclareFunctions()
    local decFuncs = 
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS_UNIQUE,
        MODIFIER_EVENT_ON_ATTACK
    }
    return decFuncs
end

function modifier_versuta_rage_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_versuta_rage_buff:OnAttack( keys )
    if keys.attacker == self:GetCaster() then
        local current_stacks = self:GetStackCount()
        if current_stacks > 1 then
            self:DecrementStackCount()
        else
            self:Destroy()
        end
    end
end

function modifier_versuta_rage_buff:GetModifierAttackRangeBonusUnique()
    return self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_6")
end

LinkLuaModifier( "modifier_Versuta_pudge_scepter", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )

modifier_Versuta_pudge_scepter = class({})

function modifier_Versuta_pudge_scepter:IsHidden() return true end
function modifier_Versuta_pudge_scepter:IsPurgable() return false end

Versuta_pudge = class({})

function Versuta_pudge:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function Versuta_pudge:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Versuta_pudge:OnSpellStart()
    local caster = self:GetCaster()
    local level = self:GetLevel()
    local count = 1 + self:GetCaster():FindTalentValue("special_bonus_birzha_versuta_8")
    caster:EmitSound("versutapudge")
    for i = 1, count do
        self.pudge = CreateUnitByName("npc_pudge_"..level, caster:GetAbsOrigin() + RandomVector(250), true, caster, caster, caster:GetTeamNumber())
        self.pudge:SetOwner(caster)
        if self:GetCaster():HasScepter() then
            self.pudge:AddNewModifier(self:GetCaster(), self, "modifier_Versuta_pudge_scepter", {})
        end
        FindClearSpaceForUnit(self.pudge, self.pudge:GetAbsOrigin(), true)
        self.pudge:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = self:GetSpecialValueFor("duration")})
        local dismember = self.pudge:FindAbilityByName("versuta_dismember")
        dismember:SetLevel(self:GetLevel())
        local pudge_rot_custom = self.pudge:FindAbilityByName("pudge_rot_custom")
        pudge_rot_custom:SetLevel(self:GetLevel())
    end
end

function Spawn( entityKeyValues )
    if not IsServer() then
        return
    end
    if thisEntity == nil then
        return
    end

    TargetAbility_2 = thisEntity:FindAbilityByName( "versuta_dismember" )
    thisEntity:SetContextThink( "PudgeThink", PudgeThink, FrameTime() )
end

function PudgeThink()
    if ( not thisEntity:IsAlive() ) then
        return -1 
    end
  
    if GameRules:IsGamePaused() == true then
        return 1 
    end

    local OWNER = thisEntity:GetOwner()
    local Owner_location = OWNER:GetAbsOrigin()
    local Pudge_loc = thisEntity:GetAbsOrigin()
    local vector_distance = Owner_location - Pudge_loc
    local distance = vector_distance:Length2D()



    local enemies = FindUnitsInRadius( OWNER:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_CLOSEST, false )
    for i = #enemies, 1, -1 do
        if enemies[i] ~= nil and enemies[i]:HasModifier("modifier_versuta_dismember") then
            table.remove(enemies, i)
        end
    end
    if #enemies > 0 and not thisEntity:IsChanneling() then
        enemy = enemies[1]
        if enemy ~= nil then
            if TargetAbility_2 ~= nil and TargetAbility_2:IsFullyCastable()  then
                if enemy:IsAlive() then
                    ExecuteOrderFromTable({
                        UnitIndex = thisEntity:entindex(),
                        TargetIndex = enemy:entindex(),
                        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                        AbilityIndex = TargetAbility_2:entindex(),
                    })
                end
            else
                local order = 
                {
                    UnitIndex = thisEntity:entindex(),
                    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    Position = enemy:GetAbsOrigin() + RandomVector( RandomFloat(-100, 100))
                }   
                ExecuteOrderFromTable(order)
            end
        end
    else
        if not thisEntity:IsChanneling() then
            local order = 
            {
                UnitIndex = thisEntity:entindex(),
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
                TargetIndex = OWNER:entindex()
            }   
            ExecuteOrderFromTable(order)
        end  
    end
    return 1  
end

versuta_dismember = class({})

LinkLuaModifier( "modifier_versuta_dismember", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )

function versuta_dismember:OnAbilityPhaseStart()
    local target = self:GetCursorTarget()
    if target and target:HasModifier("modifier_versuta_dismember") then
        return false
    end
    return true
end

function versuta_dismember:GetChannelTime()
    self.duration = self:GetSpecialValueFor( "duration" )
    if self:GetCaster():HasModifier("modifier_Versuta_pudge_scepter") then
        self.duration  = self.duration + 1 
    end
    return self.duration
end

function versuta_dismember:OnSpellStart()
    if not IsServer() then return end
    self.target = self:GetCursorTarget()
    
    if self.target:TriggerSpellAbsorb( self ) then
        self.target = nil
        self:GetCaster():Interrupt()
    else
        self.target:AddNewModifier( self:GetCaster(), self, "modifier_versuta_dismember", { duration = self:GetChannelTime() * ( 1 - self.target:GetStatusResistance() ) } )
        self.target:Interrupt()
        self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_ABSORIGIN, self.target)
        ParticleManager:SetParticleControlEnt(self.pfx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
    end
end

function versuta_dismember:OnChannelFinish( bInterrupted )
    if self.target ~= nil then
        self.target:RemoveModifierByName( "modifier_versuta_dismember" )
    end
    if self.pfx then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
    end
end

modifier_versuta_dismember = class({})

function modifier_versuta_dismember:IsPurgable()
    return false
end

function modifier_versuta_dismember:IsPurgeException()
    return true
end

function modifier_versuta_dismember:OnCreated( kv )
    self.dismember_damage = self:GetAbility():GetSpecialValueFor( "dismember_damage" )
    self.tick_rate = self:GetAbility():GetSpecialValueFor( "tick_rate" )

    if IsServer() then
        self:GetParent():InterruptChannel()
        self:OnIntervalThink()
        self:StartIntervalThink( self.tick_rate )
    end
end

function modifier_versuta_dismember:OnDestroy()
    if IsServer() then
        self:GetCaster():InterruptChannel()
    end
end

function modifier_versuta_dismember:OnIntervalThink()
    if IsServer() then
        local flDamage = self.dismember_damage
        

        local damage = {
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = flDamage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        }

        ApplyDamage( damage )
        self:GetCaster():Heal( flDamage, self:GetAbility() )
        EmitSoundOn( "Hero_Pudge.Dismember", self:GetParent() )
    end
end

function modifier_versuta_dismember:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_INVISIBLE] = false,
    }

    return state
end

function modifier_versuta_dismember:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }

    return funcs
end

function modifier_versuta_dismember:GetOverrideAnimation()
    return ACT_DOTA_DISABLED
end


LinkLuaModifier( "modifier_pudge_rot_custom", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_pudge_rot_custom_debuff", "abilities/heroes/versuta.lua", LUA_MODIFIER_MOTION_NONE )

pudge_rot_custom = class({})

function pudge_rot_custom:GetIntrinsicModifierName()
    return "modifier_pudge_rot_custom"
end

modifier_pudge_rot_custom = class({})

function modifier_pudge_rot_custom:IsPurgable() return false end
function modifier_pudge_rot_custom:OnCreated()
    if not IsServer() then return end
    self.rot_radius = self:GetAbility():GetSpecialValueFor("rot_radius")
    if self:GetCaster():HasModifier("modifier_Versuta_pudge_scepter") then
        self.rot_radius = self.rot_radius + 150
    end
    self.rot_tick = self:GetAbility():GetSpecialValueFor("rot_tick")
    self.rot_damage = self:GetAbility():GetSpecialValueFor("rot_damage") * self.rot_tick
    
    self.pfx = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_immortal_arm/pudge_immortal_arm_rot_gold.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.pfx, 1, Vector(self.rot_radius, 1, self.rot_radius))
    self:AddParticle(self.pfx, false, false, -1, false, false)  
    
    self:GetParent():EmitSound("Hero_Pudge.Rot")
    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_ROT)
    self:OnIntervalThink()
    self:StartIntervalThink(self.rot_tick)
end

function modifier_pudge_rot_custom:OnIntervalThink()
    if not IsServer() then return end
    if not self:GetParent():IsAlive() then
        if not self:IsNull() then
            self:Destroy()
        end
    end
    self.rot_radius = self:GetAbility():GetSpecialValueFor("rot_radius")
    if self:GetCaster():HasModifier("modifier_Versuta_pudge_scepter") then
        self.rot_radius = self.rot_radius + 150
    end
    self.rot_tick = self:GetAbility():GetSpecialValueFor("rot_tick")
    self.rot_damage = (self:GetAbility():GetSpecialValueFor("rot_damage") + self:GetCaster():GetOwner():FindTalentValue("special_bonus_birzha_versuta_3")) * self.rot_tick

    if self.pfx then
        ParticleManager:SetParticleControl(self.pfx, 1, Vector(self.rot_radius, 1, self.rot_radius))
    end
    local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.rot_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
    for _, enemy in pairs(units) do
        ApplyDamage({ victim = enemy, attacker = self:GetCaster(), damage = self.rot_damage, damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NONE, ability = self:GetAbility() })
    end
end

function modifier_pudge_rot_custom:OnDestroy()
    if not IsServer() then return end
    self:GetParent():StopSound("Hero_Pudge.Rot")
end

function modifier_pudge_rot_custom:IsAura() 
    return true 
end

function modifier_pudge_rot_custom:IsAuraActiveOnDeath() 
    return false 
end

function modifier_pudge_rot_custom:GetAuraRadius() 
    if self.rot_radius then 
        return self.rot_radius 
    end 
end

function modifier_pudge_rot_custom:GetAuraSearchFlags() 
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_pudge_rot_custom:GetAuraSearchTeam() 
    return DOTA_UNIT_TARGET_TEAM_ENEMY 
end

function modifier_pudge_rot_custom:GetAuraSearchType() 
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC 
end

function modifier_pudge_rot_custom:GetModifierAura() 
    return "modifier_pudge_rot_custom_debuff" 
end

modifier_pudge_rot_custom_debuff = class({})

function modifier_pudge_rot_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("rot_slow")
    end
end


