LinkLuaModifier( "modifier_item_armor_damned", "items/armor_damned", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_armor_damned_debuff", "items/armor_damned", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_armor_damned_aura", "items/armor_damned", LUA_MODIFIER_MOTION_NONE )

item_armor_damned = class({})

function item_armor_damned:OnSpellStart()
	local blast_radius = self:GetSpecialValueFor("radius")
	local blast_speed = 500
	local damage = self:GetSpecialValueFor("damage") + self:GetCaster():GetIntellect(false)
	local blast_duration = blast_radius / blast_speed
	local current_loc = self:GetCaster():GetAbsOrigin()
	local caster	= self:GetCaster()
	local ability	= self

    local particle = "particles/damned_active.vpcf"

    if DonateShopIsItemBought(self:GetCaster():GetPlayerOwnerID(), 201) or IsInToolsMode() then
        particle = "particles/econ/events/fall_2022/shivas/shivas_guard_fall2022_active.vpcf"
    end

	local blast_pfx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(blast_pfx, 0, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(blast_pfx, 1, Vector(blast_radius, blast_duration * 1.33, blast_speed))
	ParticleManager:ReleaseParticleIndex(blast_pfx)

	local targets_hit = {}
	local current_radius = 0
	local tick_interval = 0.1

	self:GetCaster():EmitSound("item_aotd")

	Timers:CreateTimer(tick_interval, function()
		if self:IsNull() then return end
		AddFOWViewer(self:GetCaster():GetTeamNumber(), current_loc, current_radius, 0.1, false)
		current_radius = current_radius + blast_speed * tick_interval
		current_loc = self:GetCaster():GetAbsOrigin()
		local nearby_enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), current_loc, nil, current_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			local enemy_has_been_hit = false
			for _,enemy_hit in pairs(targets_hit) do
				if enemy == enemy_hit then enemy_has_been_hit = true end
			end
			if not enemy_has_been_hit then
				ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
				enemy:AddNewModifier(self:GetCaster(), self, "modifier_item_armor_damned_debuff", {duration = self:GetSpecialValueFor("duration_debuff") * (1 - enemy:GetStatusResistance())})
				targets_hit[#targets_hit + 1] = enemy
			end
		end
		if current_radius < blast_radius then
			return tick_interval
		end
	end)
end

function item_armor_damned:GetIntrinsicModifierName() 
    return "modifier_item_armor_damned"
end

modifier_item_armor_damned = class({})

function modifier_item_armor_damned:IsHidden() return true end
function modifier_item_armor_damned:IsPurgable() return false end
function modifier_item_armor_damned:IsPurgeException() return false end
function modifier_item_armor_damned:GetAttributes()  return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_armor_damned:DeclareFunctions()
	return  
	{
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_item_armor_damned:GetModifierPreAttack_BonusDamage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_armor_damned:GetModifierConstantHealthRegen()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor('bonus_hp_regen')
end

function modifier_item_armor_damned:GetModifierBonusStats_Intellect()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_armor_damned:GetModifierPhysicalArmorBonus()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_armor_damned:GetAuraRadius()
	if not self:GetAbility() then return end
	return self:GetAbility():GetSpecialValueFor("radius_passive")
end

function modifier_item_armor_damned:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_item_armor_damned:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_armor_damned:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_armor_damned:GetModifierAura()
	return "modifier_item_armor_damned_aura"
end

function modifier_item_armor_damned:GetAuraDuration()
	return 0.01
end

function modifier_item_armor_damned:IsAura()
	return true
end

function modifier_item_armor_damned:GetAuraEntityReject(target)
    if target:HasModifier("modifier_item_armor_damned_debuff") then
        return true
    else
        return false
    end
end

modifier_item_armor_damned_aura = class({})

function modifier_item_armor_damned_aura:IsPurgable()
    return false
end

function modifier_item_armor_damned_aura:DeclareFunctions()
	return  
	{
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }
end

function modifier_item_armor_damned_aura:GetModifierAttackSpeedBonus_Constant()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("attack_speed_passive") * -1
end

function modifier_item_armor_damned_aura:GetModifierMoveSpeedBonus_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor('movespeed_passive') * -1
end

function modifier_item_armor_damned_aura:GetModifierBaseDamageOutgoing_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("damage_passive") * -1
end

function modifier_item_armor_damned_aura:Custom_HealAmplifyReduce()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("hp_regen_passive") * -1
end

function modifier_item_armor_damned_aura:GetModifierHPRegenAmplify_Percentage()
	if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("hp_regen_passive") * -1
end

modifier_item_armor_damned_debuff = class({})

function modifier_item_armor_damned_debuff:IsPurgable()
    return false
end

function modifier_item_armor_damned_debuff:DeclareFunctions()
	return  
	{
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }
end

function modifier_item_armor_damned_debuff:GetEffectName()
	return "particles/aotd_debuff.vpcf"
end

function modifier_item_armor_damned_debuff:GetModifierAttackSpeedBonus_Constant()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("attack_speed_debuff")
end

function modifier_item_armor_damned_debuff:GetModifierMoveSpeedBonus_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("movespeed_debuff")
end

function modifier_item_armor_damned_debuff:GetModifierBaseDamageOutgoing_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("damage_debuff")
end

function modifier_item_armor_damned_debuff:Custom_HealAmplifyReduce()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("hp_regen_debuff")
end

function modifier_item_armor_damned_debuff:GetModifierHPRegenAmplify_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("hp_regen_debuff")
end

function modifier_item_armor_damned_debuff:GetModifierMiss_Percentage()
    if not self:GetAbility() then return end
    return self:GetAbility():GetSpecialValueFor("miss_debuff")
end
