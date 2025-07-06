LinkLuaModifier( "modifier_hellfire_blast_slow", "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hellfire_blast_illusion", "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_birzha_stunned", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_birzha_bashed", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_birzha_stunned_purge", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )

Papich_HellFire_Blast = class({})

function Papich_HellFire_Blast:Precache(context)
    local particle_list = 
    {
        "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_warmup.vpcf",
        "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_cast.vpcf",
        "particles/papich/skeletonking_hellfireblast.vpcf",
        "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast.vpcf",
        "particles/papich/status_effect_wraithking_ghosts.vpcf",
        "particles/papich/skeletonking_hellfireblast_explosion.vpcf",
        "particles/papich/skeletonking_hellfireblast_debuff.vpcf",
        "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_explosion.vpcf",
        "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_debuff.vpcf",
        "particles/papich/status_effect_wraithking_ghosts.vpcf",
        "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf",
        "particles/birzhapass/papich_critical_effect.vpcf",
        "particles/generic_gameplay/generic_lifesteal.vpcf",
        "particles/papich_crit_overhead_buff.vpcf",
    }
    for _, particle_name in pairs(particle_list) do
        PrecacheResource("particle", particle_name, context)
    end
end

function Papich_HellFire_Blast:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function Papich_HellFire_Blast:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Papich_HellFire_Blast:GetAbilityTextureName()
    if self:GetCaster():HasModifier("modifier_papich_hand_effect") then
        return "Papich/HellFireBlast_bp"
    end
    return "Papich/HellFireBlast"
end

function Papich_HellFire_Blast:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function Papich_HellFire_Blast:OnAbilityPhaseStart()
    local particle_effect = "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_warmup.vpcf"

    if self:GetCaster():HasModifier("modifier_papich_hand_effect") then
        particle_effect = "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_cast.vpcf"
    end

    local particle = ParticleManager:CreateParticle(particle_effect, PATTACH_CUSTOMORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
    return true
end

function Papich_HellFire_Blast:OnSpellStart(new_target)
    local target
    if new_target == nil then
        target = self:GetCursorTarget()
    else
        target = new_target
    end
    if not IsServer() then return end

    local particle = "particles/papich/skeletonking_hellfireblast.vpcf"

    if self:GetCaster():HasModifier("modifier_papich_hand_effect") then
        particle = "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast.vpcf"
    end

    local info = 
    {
        EffectName = particle,
        Ability = self,
        iMoveSpeed = 1000,
        Source = self:GetCaster(),
        Target = target,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }
    ProjectileManager:CreateTrackingProjectile( info )
    self:GetCaster():EmitSound("PapichHellfire_Blast")
end

function Papich_HellFire_Blast:OnProjectileHit( target, vLocation )
    if not IsServer() then return end
    if target ~= nil and ( not target:IsMagicImmune() ) and ( not target:TriggerSpellAbsorb( self ) ) then
        local stun_duration = self:GetSpecialValueFor( "duration" ) + self:GetCaster():FindTalentValue("special_bonus_birzha_papich_4")
        local stun_damage = self:GetSpecialValueFor( "damage" )
        local slow_duration = stun_duration
        local damage =
         {
            victim = target,
            attacker = self:GetCaster(),
            damage = stun_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        }
        ApplyDamage( damage )
        target:AddNewModifier(self:GetCaster(), self, "modifier_birzha_stunned_purge", {duration = stun_duration * (1 - target:GetStatusResistance())})
        target:AddNewModifier( self:GetCaster(), self, "modifier_hellfire_blast_slow", { duration = (slow_duration*2) * (1 - target:GetStatusResistance())} )
        target:EmitSound("Hero_SkeletonKing.Hellfire_BlastImpact")
        if self:GetCaster():HasTalent("special_bonus_birzha_papich_6") then
            local illusions = BirzhaCreateIllusion(self:GetCaster(), self:GetCaster(), 
            {
                outgoing_damage = self:GetSpecialValueFor("illusion_outgoing") - 100,
                incoming_damage = self:GetSpecialValueFor("illusion_incoming") - 100,
                bounty_base     = self:GetCaster():GetLevel()*2, 
                bounty_growth   = nil,
                outgoing_damage_structure   = nil,
                outgoing_damage_roshan      = nil,
                duration = (slow_duration*2) * (1 - target:GetStatusResistance())
            }, 
            1, 108, false, false)
            for k, illusion in pairs(illusions) do
                FindClearSpaceForUnit(illusion, target:GetAbsOrigin(), true)
                illusion:AddNewModifier(self:GetCaster(), self, "modifier_hellfire_blast_illusion", {target = target:entindex()})
                illusion:MoveToTargetToAttack(target)
                illusion:EmitSound("Hero_Terrorblade.Reflection")
            end
        end
    end
    return true
end

modifier_hellfire_blast_illusion = class({})

function modifier_hellfire_blast_illusion:IsPurgable() return false end
function modifier_hellfire_blast_illusion:IsHidden() return true end

function modifier_hellfire_blast_illusion:OnCreated(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self:StartIntervalThink(0.1)
end

function modifier_hellfire_blast_illusion:OnIntervalThink()
    if not IsServer() then return end
    if self.target ~= nil and not self.target:IsAlive() then self:GetParent():ForceKill(false) return end
    self:GetParent():MoveToTargetToAttack(self.target)
end

function modifier_hellfire_blast_illusion:GetStatusEffectName()
    return "particles/papich/status_effect_wraithking_ghosts.vpcf"
end

function modifier_hellfire_blast_illusion:StatusEffectPriority()
    return 999999
end

function modifier_hellfire_blast_illusion:CheckState()
    local state = 
    {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
    return state
end

modifier_hellfire_blast_slow = class({})

function modifier_hellfire_blast_slow:IsPurgable() return false end
function modifier_hellfire_blast_slow:IsPurgeException() return true end

function modifier_hellfire_blast_slow:OnCreated( kv )
    self.per_damage = self:GetAbility():GetSpecialValueFor( "per_damage" )
    self.move_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
    self:StartIntervalThink( 1 )

    local particle_effect = "particles/papich/skeletonking_hellfireblast_explosion.vpcf"
    local particle_debuff = "particles/papich/skeletonking_hellfireblast_debuff.vpcf"

    if self:GetCaster():HasModifier("modifier_papich_hand_effect") then
        particle_effect = "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_explosion.vpcf"
        particle_debuff = "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_debuff.vpcf"
    end

    local particle = ParticleManager:CreateParticle(particle_effect, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    local particle_debuff_off = ParticleManager:CreateParticle(particle_debuff, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(particle_debuff_off, false, false, -1, false, false)
end

function modifier_hellfire_blast_slow:OnRefresh( kv )
    self.per_damage = self:GetAbility():GetSpecialValueFor( "per_damage" )
    self.move_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
    self:StartIntervalThink( 1 )
end

function modifier_hellfire_blast_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_hellfire_blast_slow:GetModifierMoveSpeedBonus_Percentage( params )
    return self.move_slow
end

function modifier_hellfire_blast_slow:OnIntervalThink()
    if not IsServer() then return end
    local damage = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.per_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }
    ApplyDamage( damage )
end

Papich_reincarnation = class({})

LinkLuaModifier("modifier_papich_reincarnation_wraith_form_buff",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_papich_reincarnation_wraith_form",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)

function Papich_reincarnation:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level ) + self:GetCaster():FindTalentValue("special_bonus_birzha_papich_2")
end

function Papich_reincarnation:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Papich_reincarnation:GetIntrinsicModifierName()
    return "modifier_papich_reincarnation_wraith_form_buff"
end

modifier_papich_reincarnation_wraith_form_buff = class({})

function modifier_papich_reincarnation_wraith_form_buff:IsHidden()
    return true
end

function modifier_papich_reincarnation_wraith_form_buff:IsPurgable()
    return false
end

function modifier_papich_reincarnation_wraith_form_buff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_papich_reincarnation_wraith_form_buff:OnTakeDamage(params)
    if not IsServer() then return end
    if self:GetParent() ~= params.unit then return end
    if self:GetParent() == params.attacker then return end
    if self:GetParent():IsIllusion() then return end
    if self:GetParent():HasModifier("modifier_item_uebator_active") then
        return
    end
    if self:GetParent():HasModifier("modifier_item_aeon_disk_buff") then
        return
    end
    if not self:GetParent():HasModifier("modifier_item_uebator_cooldown") and self:GetParent():HasModifier("modifier_item_uebator") then
        return
    end
    for i = 0, 5 do 
        local item = self:GetParent():GetItemInSlot(i)
        if item then
            if item:GetName() == "item_aeon_disk" then
                if item:IsFullyCastable() then
                    return
                end
            end
        end        
    end
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    if params.damage > 0 and self:GetParent():GetHealth() <= 1 and self:GetAbility():IsFullyCastable() then
        self:GetParent():SetHealth(1)
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_papich_reincarnation_wraith_form", {duration = duration, killer = params.attacker:entindex()})
    end          
end

function modifier_papich_reincarnation_wraith_form_buff:GetMinHealth()
    if self:GetAbility():IsFullyCastable() and not self:GetParent():IsIllusion() then
        return 1
    end
end

modifier_papich_reincarnation_wraith_form = class({})
function modifier_papich_reincarnation_wraith_form:IsPurgable() return false end

function modifier_papich_reincarnation_wraith_form:OnCreated(data)
    if not IsServer() then return end
    self.killer = EntIndexToHScript(data.killer)
    if self.killer and not self.killer:IsHero() and self.killer:GetOwner() then
        self.killer = self.killer:GetOwner()
    end
    self.heal_counter = 0
	self.damage_counter = 0
    self:GetParent():EmitSound("PapichReincarnate")
    self.has_scepter = self:GetCaster():HasScepter()
    if self:GetParent():HasShard() then
        local Papich_HellFire_Blast = self:GetParent():FindAbilityByName("Papich_HellFire_Blast")
        if Papich_HellFire_Blast and Papich_HellFire_Blast:GetLevel() > 0 then
            local radius = self:GetAbility():GetSpecialValueFor("scepter_radius")
            local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, 0, false ) 
            for _, enemy in pairs(enemies) do
                Papich_HellFire_Blast:OnSpellStart(enemy)
            end
        end
    end
end


function modifier_papich_reincarnation_wraith_form:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,        
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_EVENT_ON_HEAL_RECEIVED,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_papich_reincarnation_wraith_form:GetAbsoluteNoDamageMagical(params)
    self:DamageHero(params)
    return 1
end

function modifier_papich_reincarnation_wraith_form:GetAbsoluteNoDamagePhysical(params)
    self:DamageHero(params)
    return 1
end

function modifier_papich_reincarnation_wraith_form:GetAbsoluteNoDamagePure(params)
    self:DamageHero(params)
    return 1
end

function modifier_papich_reincarnation_wraith_form:DamageHero(params)
    if not IsServer() then return end
    if params.attacker and self:GetRemainingTime() >= 0 then
		self.damage_counter = self.damage_counter + params.damage
    end
end

function modifier_papich_reincarnation_wraith_form:OnHealReceived(params)
	if params.unit == self:GetParent() and self:GetRemainingTime() >= 0 then
		self.heal_counter = self.heal_counter + params.gain
	end
end

function modifier_papich_reincarnation_wraith_form:GetDisableHealing()
    return 1
end

function modifier_papich_reincarnation_wraith_form:CheckState()
    return
    {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_papich_reincarnation_wraith_form:GetStatusEffectName()
    return "particles/papich/status_effect_wraithking_ghosts.vpcf"
end

function modifier_papich_reincarnation_wraith_form:OnTakeDamage(params)
    if not IsServer() then return end
    if self:GetParent() ~= params.attacker then return end
    if self:GetParent() == params.unit then return end
    if params.unit:IsBuilding() then return end
    if params.unit:IsWard() then return end
    if not self.has_scepter then return end
    if params.inflictor == nil and not self:GetParent():IsIllusion() and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then 
        local heal = self:GetAbility():GetSpecialValueFor("scepter_lifesteal") / 100 * params.damage
        self:GetParent():Heal(heal, self:GetAbility())
        local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker )
        ParticleManager:ReleaseParticleIndex( effect_cast )
    end
end

function modifier_papich_reincarnation_wraith_form:OnDestroy()
    if not IsServer() then return end
    self:GetAbility():UseResources(false, false, false, true)
    print("Heal: ", self.heal_counter, "Damage: ", self.damage_counter)
    if self.has_scepter then
        if self.damage_counter < self.heal_counter and self.heal_counter > 0 then
            self:GetParent():SetHealth(math.max(1, self.heal_counter - self.damage_counter))
        else
            self:GetParent():Kill(self:GetAbility(), self.killer)
        end
    else
        self:GetParent():Kill(self:GetAbility(), self.killer)
    end
end

LinkLuaModifier("modifier_streamsnipers_buff",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_streamsnipers_buff_talent",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_streamsnipers_debuff",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)

Papich_StreamSnipers = class({})

function Papich_StreamSnipers:GetBehavior()
    local behavior = DOTA_ABILITY_BEHAVIOR_PASSIVE
    if self:GetCaster():HasTalent("special_bonus_birzha_papich_3") then
        behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    end
    return behavior
end

function Papich_StreamSnipers:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_streamsnipers_buff_talent", {duration = self:GetSpecialValueFor("talent_duration")})
    self:GetCaster():EmitSound("papich_stream")
    local radius = self:GetSpecialValueFor( "aura_radius" )
    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, 0, false )
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(self:GetCaster(), self, "modifier_streamsnipers_debuff", {duration = self:GetSpecialValueFor("talent_duration")})
    end
end

function Papich_StreamSnipers:GetCooldown(iLevel)
    if self:GetCaster():HasTalent("special_bonus_birzha_papich_3") then
        return self:GetSpecialValueFor("talent_cooldown")
    end
end

function Papich_StreamSnipers:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function Papich_StreamSnipers:GetIntrinsicModifierName()
    return "modifier_streamsnipers_buff"
end

modifier_streamsnipers_buff_talent = class({})
function modifier_streamsnipers_buff_talent:IsPurgable() return false end
function modifier_streamsnipers_buff_talent:RemoveOnDeath() return false end

modifier_streamsnipers_debuff = class({})

function modifier_streamsnipers_debuff:IsHidden() return true end
function modifier_streamsnipers_debuff:IsPurgable() return false end

function modifier_streamsnipers_debuff:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(FrameTime())
end

function modifier_streamsnipers_debuff:OnIntervalThink()
    if not IsServer() then return end
    if self:GetParent():IsInvisible() and not self:GetCaster():CanEntityBeSeenByMyTeam(self:GetParent()) then return end
    AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), self:GetParent():GetCurrentVisionRange(), FrameTime(), true)
end

modifier_streamsnipers_buff = class({})

function modifier_streamsnipers_buff:IsPurgable() return false end
function modifier_streamsnipers_buff:IsHidden() return self:GetStackCount() == 0 end

function modifier_streamsnipers_buff:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

function modifier_streamsnipers_buff:OnRefresh()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

function modifier_streamsnipers_buff:OnIntervalThink()
    if not IsServer() then return end
    local radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
    local enemies = FindUnitsInRadius( self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, 0, false )
    if self:GetParent():HasModifier("modifier_streamsnipers_buff_talent") then return end
    self:SetStackCount( #enemies )
end

function modifier_streamsnipers_buff:DeclareFunctions()
    local decFuncs = 
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
    return decFuncs
end

function modifier_streamsnipers_buff:GetEffectName()
    return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end

function modifier_streamsnipers_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_streamsnipers_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor( "move_speed_pct" )
end

function modifier_streamsnipers_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetStackCount() * (self:GetAbility():GetSpecialValueFor( "attack_speed" ) + self:GetCaster():FindTalentValue("special_bonus_birzha_papich_1"))
end

function modifier_streamsnipers_buff:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor( "armor" )
end

LinkLuaModifier("modifier_Papich_in_solo",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_Papich_in_solo_oneshot",  "abilities/heroes/papich.lua", LUA_MODIFIER_MOTION_NONE)

Papich_in_solo = class({})

function Papich_in_solo:GetCooldown(level)
    return (self.BaseClass.GetCooldown( self, level ) + self:GetCaster():FindTalentValue("special_bonus_birzha_papich_8")) / ( self:GetCaster():GetCooldownReduction())
end

function Papich_in_solo:GetIntrinsicModifierName()
    return "modifier_Papich_in_solo"
end

modifier_Papich_in_solo = class({})

function modifier_Papich_in_solo:IsPurgable() return false end
function modifier_Papich_in_solo:IsHidden() return true end

function modifier_Papich_in_solo:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }

    return funcs
end

function modifier_Papich_in_solo:OnCreated()
    if not IsServer() then return end
    self.attach_sound = 0
    self.attack_record = nil
end

function modifier_Papich_in_solo:OnAttack( params )
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if params.target == self:GetParent() then return end
    if params.target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
    if params.attacker:IsIllusion() then return end
    if params.attacker:PassivesDisabled() then return end
    if params.target:IsWard() then return end

    if self.attach_sound < 15 then
        self.attach_sound = self.attach_sound + 1
    else
        self:GetParent():EmitSound("papichwherecrit") 
        self.attach_sound = 0
    end
end

function modifier_Papich_in_solo:GetModifierPreAttack_CriticalStrike( params )
    local crit_mult = self:GetAbility():GetSpecialValueFor("crit_mult")
    if not IsServer() then return end
    if params.target:IsWard() then return end
    if params.attacker:PassivesDisabled() then return end
    if not self:GetAbility():IsFullyCastable() then return end
    if self:GetCaster():HasModifier("modifier_Papich_in_solo_oneshot") and not self:GetParent():IsIllusion() and not params.target:IsBoss() then
        if self:GetParent():HasTalent("special_bonus_birzha_papich_7") then
            self:GetParent():RemoveGesture(ACT_DOTA_ATTACK_EVENT)
            self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, self:GetParent():GetAttackSpeed(true))
            self.attack_record = params.record
            self.one_shot = true
            return 1000000
        else
            self:GetParent():RemoveGesture(ACT_DOTA_ATTACK_EVENT)
            self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, self:GetParent():GetAttackSpeed(true))
            self.attack_record = params.record
            self.one_shot = true
            return
        end
    end
    self:GetParent():RemoveGesture(ACT_DOTA_ATTACK_EVENT)
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, self:GetParent():GetAttackSpeed(true))
    self.attack_record = params.record
    self.one_shot = nil
    return crit_mult
end

function modifier_Papich_in_solo:GetModifierProcAttack_Feedback( params )
    if not IsServer() then return end
    local pass = false
    if self.attack_record and params.record == self.attack_record then
        pass = true
        self.attack_record = nil
    end
    if pass and self.one_shot == true then
        self:GetParent():EmitSound("papichcreet")
        if DonateShopIsItemActive(self:GetCaster():GetPlayerID(), 29) then
            local niia = ParticleManager:CreateParticle("particles/birzhapass/papich_critical_effect.vpcf", PATTACH_OVERHEAD_FOLLOW, params.target)
            ParticleManager:SetParticleControl(niia, 0, params.target:GetAbsOrigin())
            ParticleManager:SetParticleControl(niia, 7, params.target:GetAbsOrigin())
        end
        if self:GetParent():HasTalent("special_bonus_birzha_papich_7") then
            self.attach_sound = 0
            self:GetAbility():UseResources(false, false, false, true)
            self:GetParent():StopSound("papichwherecrit")
            self.one_shot = nil
        else
            self.one_shot = nil
            self.attach_sound = 0
            ApplyDamage({victim = params.target, attacker = self:GetParent(), damage = params.target:GetMaxHealth() / 100 * self:GetAbility():GetSpecialValueFor("damage_chance"), damage_type = DAMAGE_TYPE_PURE, ability = nil}) 
        end
        self:GetParent():RemoveModifierByName("modifier_Papich_in_solo_oneshot")
    elseif pass and self.one_shot == nil then
        self:GetParent():EmitSound("papichsolo_new")
        self:GetAbility():UseResources(false, false, false, true)
        self:GetParent():StopSound("papichwherecrit")
        self.one_shot = nil
        self:GetParent():RemoveModifierByName("modifier_Papich_in_solo_oneshot")
    end
    if pass then
        if self:GetCaster():HasTalent("special_bonus_birzha_papich_5") then
            local heal = params.damage / 100 * self:GetCaster():FindTalentValue("special_bonus_birzha_papich_5")
            self:GetCaster():Heal(heal, nil)
            local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
            ParticleManager:ReleaseParticleIndex( effect_cast )
        end
    else
        local chance = self:GetAbility():GetSpecialValueFor("chance") + self:GetCaster():FindTalentValue("special_bonus_birzha_papich_7")
        if RollPseudoRandomPercentage(chance, 921, self:GetCaster()) then
            self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_Papich_in_solo_oneshot", {})
        end
    end
end

modifier_Papich_in_solo_oneshot = class({})
function modifier_Papich_in_solo_oneshot:IsHidden() return true end
function modifier_Papich_in_solo_oneshot:IsPurgeException() return false end
function modifier_Papich_in_solo_oneshot:IsPurgable() return false end
function modifier_Papich_in_solo_oneshot:RemoveOnDeath() return false end
function modifier_Papich_in_solo_oneshot:GetEffectName()
    return "particles/papich_crit_overhead_buff.vpcf"
end
function modifier_Papich_in_solo_oneshot:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end