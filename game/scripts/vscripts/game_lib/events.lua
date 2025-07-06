function BirzhaGameMode:CreateFountainThinkers()
    for team = 0, 13 do
        local trigger = Entities:FindByName(nil, "base_team_"..team)
        if trigger then
            local find_fountain = nil
            for _, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
                if fountain and fountain:GetTeamNumber() == team then
                    find_fountain = fountain
                    break
                end
            end
            if find_fountain then
                local ability_fountain = find_fountain:FindAbilityByName("ability_fountain")
                if ability_fountain then
                    CreateModifierThinker(find_fountain, ability_fountain, "modifier_birzha_fountain_passive", {}, trigger:GetAbsOrigin(), team, false)
                end
            end
        end
    end
end

-- Единый игровой таймер
function BirzhaGameMode:GameInProgressThink()
    ---- Предметы и монеты
    BirzhaGameMode:ThinkGoldDrop()
	BirzhaGameMode:ThinkItemCheck()

    ---- Игровое время
    BIRZHA_GAME_ALL_TIMER = BIRZHA_GAME_ALL_TIMER + 1
    GameTimerUpdater(BIRZHA_GAME_ALL_TIMER, "GameTimer")
 
    ---- Фонтан
    if BIRZHA_FOUNTAIN_GAME_TIMER > 0 then
        BIRZHA_FOUNTAIN_GAME_TIMER = BIRZHA_FOUNTAIN_GAME_TIMER - 1
        GameTimerUpdater(BIRZHA_FOUNTAIN_GAME_TIMER, "fountain", 900)
        if BIRZHA_FOUNTAIN_GAME_TIMER <= 0 then
            CustomGameEventManager:Send_ServerToAllClients("birzha_toast_manager_create", {text = "fountainoff", icon = "fountain"} )
        end
    end

    ---- Контракты
    -- if BIRZHA_CONTRACT_TIME > 0 then
    --     BIRZHA_CONTRACT_TIME = BIRZHA_CONTRACT_TIME - 1
    --     GameTimerUpdater(BIRZHA_CONTRACT_TIME, "contarct_time")
    --     if BIRZHA_CONTRACT_TIME <= 0 then
    --         self:SpawnContracts()
    --         BIRZHA_CONTRACT_TIME = 180
    --     end
    -- end

    -- if BIRZHA_GAME_ALL_TIMER > 0 and BIRZHA_GAME_ALL_TIMER % 300 == 0 then
    --     CustomGameEventManager:Send_ServerToAllClients("birzha_toast_manager_create", {text = "spawn_anton", icon = "creep"} )
    --     BirzhaGameMode:SpawnAntosha()
    -- end

    -- if BIRZHA_GAME_ALL_TIMER > 0 and BIRZHA_GAME_ALL_TIMER % 180 == 0 then
    --     CustomGameEventManager:Send_ServerToAllClients("birzha_toast_manager_create", {text = "spawn_kobold", icon = "kobold"} )
    --     BirzhaGameMode:SpawnKobold()
    -- end

    -- Окончание игры
    if BIRZHA_FOUNTAIN_GAME_TIMER <= 0 and BIRZHA_TIMER_TO_END_GAME > 0 then
        BIRZHA_TIMER_TO_END_GAME = BIRZHA_TIMER_TO_END_GAME - 1
        GameTimerUpdater(BIRZHA_TIMER_TO_END_GAME, "endgametimer", 300)
        if BIRZHA_TIMER_TO_END_GAME <= 0 and not GameRules:IsCheatMode() then
            local leaderbirzha = BirzhaGameMode:GetTeamLeader()
            BirzhaGameMode:EndGame( leaderbirzha )
            GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[leaderbirzha] )
        end
    end
end

-- Смена стадий игры
function BirzhaGameMode:OnGameRulesStateChange(params)
	local nNewState = GameRules:State_Get()

	HeroDemo:OnGameRulesStateChange(params)

	if nNewState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		birzha_hero_selection:Init()
	end

    if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        birzha_hero_selection:StartCheckingToStart()
        BirzhaGameMode:CreateFountainThinkers()
    end

	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		CustomNetTables:SetTableValue( "game_state", "scores_to_win", { kills = MAPS_MAX_SCORES[GetMapName()] } )
	end

	if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        birzha_hero_selection:EndSelectionAndStartGameFromDota()
		Timers:CreateTimer(1, function()
            SpawnDonaters()
        end)
	end
end

-- Ивент произошедшего убийства
function BirzhaGameMode:OnTeamKillCredit( event )
	if BIRZHA_FOUNTAIN_GAME_TIMER <= 0 then
		BIRZHA_TIMER_TO_END_GAME = 300
	end
    if BirzhaGameMode.PucciFastTime ~= nil and BirzhaGameMode.PucciFastTime then return end
	BirzhaGameMode:AddScoreToTeam( event.teamnumber, 1 )
end

function BirzhaGameMode:AddScoreToTeam( Team, AddScore )
	local table_team_score = CustomNetTables:GetTableValue("game_state", tostring(Team))
	local table_game_score = CustomNetTables:GetTableValue("game_state", "scores_to_win")
	local team_kills = 0
	if table_team_score then
		team_kills = table_team_score.kills + AddScore
		CustomNetTables:SetTableValue( "game_state", tostring(Team), { kills = team_kills } )
	end
	table_team_score = CustomNetTables:GetTableValue("game_state", tostring(Team))
	if table_team_score and table_game_score then
		if table_team_score.kills >= table_game_score.kills then	
			BirzhaGameMode:EndGame( Team )
			GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[Team] )
		end
	end
end

-- Подбор предмета
function BirzhaGameMode:OnItemPickUp(event)
    -- Передаем событие в VectorTarget
    VectorTarget:OnItemPickup(event)
    
    -- Получаем предмет и владельца
    local item = EntIndexToHScript(event.ItemEntityIndex)
    local owner
    
    -- Определяем владельца (героя или юнита)
    if event.HeroEntityIndex then
        owner = EntIndexToHScript(event.HeroEntityIndex)
    elseif event.UnitEntityIndex then
        owner = EntIndexToHScript(event.UnitEntityIndex)
    end
    
    -- Если владельца нет (на всякий случай), выходим
    if not owner then return end
    
    local itemName = event.itemname
    
    -- Обработка мешков с золотом
    if itemName == "item_bag_of_gold" then
        self:GiveGoldAndRemoveItem(owner, 150, item)
    elseif itemName == "item_bag_of_gold_event" then
        self:GiveGoldAndRemoveItem(owner, 25, item)
    -- Обработка особого мешка с золотом Van
    elseif itemName == "item_bag_of_gold_van" then
        local gold = item.g_gold
        self:GiveGoldAndRemoveItem(owner, gold, item)
    -- Обработка фейкового мешка
    elseif itemName == "item_bag_of_gold_bp_fake" then
        UTIL_Remove(item)
    -- Обработка сундуков
    elseif itemName == "item_treasure_chest" or itemName == "item_treasure_chest_winter" then
        BirzhaGameMode:SpecialItemAdd(event)
        UTIL_Remove(item)
    -- Удаление предмета, если у него есть origin
    elseif item.origin then
        item.origin.is_spawned = nil
        UTIL_Remove(item)
    end
end

-- Вспомогательная функция для выдачи золота и удаления предмета
function BirzhaGameMode:GiveGoldAndRemoveItem(owner, gold, item)
    local playerID = owner:GetPlayerOwnerID()
    PlayerResource:ModifyGold(playerID, gold, true, 0)
    SendOverheadEventMessage(owner, OVERHEAD_ALERT_GOLD, owner, gold, nil)
    UTIL_Remove(item)
end

-- Установка времени для PUCCI
function BirzhaGameMode:PucciSetTime(time)
    BirzhaGameMode.PucciFastTime = time
end

-- Получение лидера
function BirzhaGameMode:GetTeamLeader()
    local team = {}
    local teams_table = table.deepcopy(_G.GET_TEAM_LIST[GetMapName()])
    for _, i in ipairs(teams_table) do
        local table_team_score = CustomNetTables:GetTableValue("game_state", tostring(i))
        if table_team_score then
            table.insert(team, {id = i, kills = table_team_score.kills} )
        end
    end
    table.sort( team, function(x,y) return y.kills < x.kills end )
    return team[1].id
end

function BirzhaGameMode:GetMaxKillLeader()
	local team = {}
    local teams_table = table.deepcopy(_G.GET_TEAM_LIST[GetMapName()])
    for _, i in ipairs(teams_table) do
        local table_team_score = CustomNetTables:GetTableValue("game_state", tostring(i))
        if table_team_score then
            table.insert(team, {id = i, kills = table_team_score.kills} )
        end
    end 
    table.sort( team, function(x,y) return y.kills < x.kills end )
    return team[1].kills
end

function BirzhaGameMode:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)
    if not killedUnit then return end
    
    local killedTeam = killedUnit:GetTeam()
    local hero = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker)
    local mapName = GetMapName()

    -- Очистка WorldPanels для не-героев
    if not killedUnit:IsRealHero() then
        self:CleanUpWorldPanels(killedUnit)
    end

    -- Установка времени респавна для героев
    if killedUnit:IsRealHero() then
        self:HandleHeroRespawn(killedTeam, killedUnit)
    end

    if not hero then return end

    local heroTeam = hero:GetTeam()
    local game_time = BIRZHA_GAME_ALL_TIMER / 60

    -- Бонус за убийство вардов
    if killedUnit:IsBaseNPC() and killedUnit:IsWard() then
        self:HandleWardKillBonus(hero, killedUnit)
    end

    -- Обработка убийства героя вражеской команды
    if killedUnit:IsRealHero() and heroTeam ~= killedTeam then
        -- Специальные звуки для героев
        self:PlayHeroSpecificSounds(hero, killedUnit)

        -- Эффект за убийство для донатеров
        self:CreateKillEffect(hero)

        -- Бонус за убийство лидера
        local bonusData = self:CalculateLeaderBonus(hero, killedUnit, game_time)
        
        -- Обработка бонуса лидера
        if mapName ~= "birzhamemov_zxc" then
            self:ApplyLeaderBonus(hero, killedUnit, bonusData, game_time)
        end

        -- Увеличение стаков для Overlord
        self:IncrementOverlordStacks(hero, 5)

        -- Обработка ассистов
        self:ProcessAssists(hero, killedUnit)
    end
end

-- Вспомогательные функции
function BirzhaGameMode:CleanUpWorldPanels(unit)
    local panels = WorldPanels.entToPanels[unit]
    if not panels then return end
    for _, panel in ipairs(panels) do
        for _, pid in ipairs(panel.pids) do
            PlayerTables:DeleteTableKey("worldpanels_" .. pid, panel.idString)
        end
    end
end

function BirzhaGameMode:HandleHeroRespawn(team, hero)
    if hero:IsReincarnating() then return end
    if hero:GetRespawnTime() <= 10 then return end
    self:SetRespawnTime(team, hero)
end

function BirzhaGameMode:HandleWardKillBonus(hero, ward)
    local mod = hero:FindModifierByName("modifier_item_birzha_ward")
    if not mod then return end
    local gold = ward:GetUnitName() == "npc_dota_observer_wards" and 50 or 25
    hero:ModifyGold(gold, true, 0)
end

function BirzhaGameMode:PlayHeroSpecificSounds(killer, victim)
    local heroSounds = {
        npc_dota_hero_treant = {
            death = {sound = "OverlordDeath", chance = 25},
            kill = {func = killer.OverlordKillSound}
        },
        npc_dota_hero_sasake = {
            death = {sound = "sasake_death", chance = 25},
            kill = {sound = "sasake_kill", chance = 25}
        },
        npc_dota_hero_travoman = {
            death = {sound = "travoman_death", chance = 25},
            kill = {sound = "travoman_kill", chance = 25}
        },
        npc_dota_hero_old_god = {
            death = {sound = "stariy_death", chance = 100}
        }
    }

    local victimData = heroSounds[victim:GetUnitName()]
    if victimData and victimData.death and RollPercentage(victimData.death.chance) then
        victim:EmitSound(victimData.death.sound)
    end

    local killerData = heroSounds[killer:GetUnitName()]
    if killerData then
        if killerData.kill and killerData.kill.func then
            killerData.kill.func(killer, victim)
        elseif killerData.kill and killerData.kill.sound and RollPercentage(killerData.kill.chance) then
            killer:EmitSound(killerData.kill.sound)
        end
    end
end

function BirzhaGameMode:CreateKillEffect(hero)
    if DonateShopIsItemBought(hero:GetPlayerOwnerID(), 194) then
        local particle = ParticleManager:CreateParticle("particles/econ/items/drow/drow_arcana/drow_v2_arcana_revenge_kill_effect_caster.vpcf",  PATTACH_ABSORIGIN_FOLLOW, hero)
        ParticleManager:SetParticleControlEnt(particle, 1, hero, PATTACH_POINT_FOLLOW, nil, hero:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)
    end
end

function BirzhaGameMode:CalculateLeaderBonus(hero, victim, gameTime)
    local teams_table = table.deepcopy(_G.GET_TEAM_LIST[GetMapName()])
    local teamData = {}
    
    -- Получаем данные команд
    for _, teamID in ipairs(teams_table) do
        local score = CustomNetTables:GetTableValue("game_state", tostring(teamID))
        if score then
            table.insert(teamData, {id = teamID, kills = score.kills})
        end
    end
    
    -- Сортируем по убийствам
    table.sort(teamData, function(a, b) return a.kills > b.kills end)
    
    -- Находим статистику команд
    local targetKills, attackerKills = 0, 0
    for _, team in ipairs(teamData) do
        if team.id == victim:GetTeamNumber() then
            targetKills = team.kills
        elseif team.id == hero:GetTeamNumber() then
            attackerKills = team.kills
        end
    end
    
    -- Получаем нетворс
    local networthAttacker = PlayerResource:GetNetWorth(hero:GetPlayerOwnerID()) or 0
    local networthTarget = PlayerResource:GetNetWorth(victim:GetPlayerOwnerID()) or 0
    
    return {
        isBonus = targetKills > attackerKills and networthTarget > networthAttacker,
        targetKills = targetKills,
        attackerKills = attackerKills,
        networthAttacker = networthAttacker,
        networthTarget = networthTarget
    }
end

function BirzhaGameMode:ApplyLeaderBonus(hero, victim, bonusData, gameTime)
    local bonusGold, bonusExp = 0, 0
    if bonusData.isBonus and (gameTime >= 5 or IsInToolsMode()) then
        local memberID = hero:GetPlayerOwnerID()
        bonusGold = (250 + (250 * gameTime / 10)) + ((bonusData.targetKills - bonusData.attackerKills) * 50)
        bonusExp = (500 * (gameTime / 5)) + ((bonusData.targetKills - bonusData.attackerKills) * 100)
        PlayerResource:ModifyGold(memberID, bonusGold, true, 0)
        if hero:IsHero() then
            hero:AddExperience(bonusExp, 0, false, false)
        end
    elseif hero:IsHero() then
        hero:AddExperience(100, 0, false, false)
    end
    -- Отправка уведомления о бонусе
    if victim:GetTeam() == self.leadingTeam and not self.isGameTied and gameTime >= 5 and (bonusExp > 0 or bonusGold > 0) then
        CustomGameEventManager:Send_ServerToAllClients("birzha_toast_manager_create", {
            text = "__",
            icon = "leader",
            kill = 1,
            hero_id = hero:GetUnitName(),
            exp = math.floor(bonusExp),
            gold = math.floor(bonusGold)
        })
    end
end

function BirzhaGameMode:IncrementOverlordStacks(hero, amount)
    local modifier = hero:FindModifierByName("modifier_Overlord_passive")
    if modifier then
        modifier:SetStackCount(modifier:GetStackCount() + amount)
    end
end

function BirzhaGameMode:ProcessAssists(killer, victim)
    local allHeroes = HeroList:GetAllHeroes()
    for _, attacker in ipairs(allHeroes) do
        for i = 0, victim:GetNumAttackers() - 1 do
            if attacker:GetPlayerOwnerID() == victim:GetAttacker(i) then
                attacker:AddExperience(50, 0, false, false)
                if attacker ~= killer then
                    self:IncrementOverlordStacks(attacker, 2)
                    self:ProcessWardModifierAssist(attacker, killer)
                end
            end
        end
    end
end

function BirzhaGameMode:ProcessWardModifierAssist(attacker, killer)
    local mod = attacker:FindModifierByName("modifier_item_birzha_ward")
    if not (mod and attacker:IsRealHero() and killer:GetTeamNumber() == attacker:GetTeamNumber()) then return end

    local ability = mod:GetAbility()
    ability.assists = (ability.assists or 0) + 1
    
    local goldRewards = 
    {
        [15] = {gold = 100, stack = 2, level = 2},
        [30] = {gold = 125, stack = 3, level = 3}
    }
    
    if ability.assists >= 30 then
        attacker:ModifyGold(125, true, 0)
        mod:SetStackCount(3)
        ability.level = 3
    elseif ability.assists >= 15 then
        attacker:ModifyGold(100, true, 0)
        mod:SetStackCount(2)
        ability.level = 2
    else
        attacker:ModifyGold(75, true, 0)
    end
end


function BirzhaGameMode:SetRespawnTime(killedTeam, killedUnit)
    -- Обработка специального модификатора Jull
    if killedUnit:HasModifier("modifier_jull_steal_time") then
        self:HandleJullRespawnTime(killedTeam, killedUnit)
        return
    end

    -- Базовое время респавна
    local respawn_time_base = 5
    local bonus_respawn_time = math.floor(math.min(BIRZHA_GAME_ALL_TIMER / 240, 8))
    
    -- Дополнительный бонус для лидирующей команды
    if killedTeam == self.leadingTeam then
        bonus_respawn_time = bonus_respawn_time + self:GetLeadingTeamBonusTime()
    end

    -- Установка финального времени респавна
    killedUnit:SetTimeUntilRespawn(respawn_time_base + bonus_respawn_time)
end

-- Вспомогательные функции
function BirzhaGameMode:HandleJullRespawnTime(killedTeam, killedUnit)
    local respawn_time_base = 5
    local bonus_respawn_time = math.floor(math.min(BIRZHA_GAME_ALL_TIMER / 240, 8))
    
    -- Бонус для лидирующей команды
    if killedTeam == self.leadingTeam then
        bonus_respawn_time = bonus_respawn_time + self:GetLeadingTeamBonusTime()
    end

    local respawn_time = respawn_time_base + bonus_respawn_time
    
    -- Учет стаков модификатора
    local modifier = killedUnit:FindModifierByName("modifier_jull_steal_time_stack")
    if modifier then
        local stackcount = modifier:GetStackCount()
        if stackcount > 0 then
            respawn_time = math.max(1, respawn_time - stackcount)
            modifier:SetStackCount(0)  -- Сбрасываем все стаки сразу
        end
    end

    -- Гарантируем минимальное время респавна
    killedUnit:SetTimeUntilRespawn(math.max(1, respawn_time))
end

function BirzhaGameMode:GetLeadingTeamBonusTime()
    if BIRZHA_GAME_ALL_TIMER >= 600 then
        return 8
    elseif BIRZHA_GAME_ALL_TIMER >= 300 then
        return 6
    elseif BIRZHA_GAME_ALL_TIMER >= 120 then
        return 4
    end
    return 0
end

-- Изменение убийств если ливнул парень
function BirzhaGameMode:PlayerLeaveUpdateMaxScore()
	local current_max_kills = CustomNetTables:GetTableValue("game_state", "scores_to_win").kills
	local leader_max_kills = BirzhaGameMode:GetMaxKillLeader()
	local maps_scores_change = _G.maps_scores_change
	local new_kills = current_max_kills - maps_scores_change[GetMapName()]
	if leader_max_kills >= new_kills then
		new_kills = leader_max_kills + math.floor(( maps_scores_change[GetMapName()] / 2 ))
	end
	if new_kills > MAPS_MAX_SCORES[GetMapName()] then
		new_kills = MAPS_MAX_SCORES[GetMapName()]
	end
	CustomNetTables:SetTableValue( "game_state", "scores_to_win", { kills = new_kills } )
end

-- Окончание игры
function BirzhaGameMode:EndGame( victoryTeam )
	if BirzhaGameMode.game_is_end then return end
	BirzhaGameMode.game_is_end = true
	BirzhaData:RegisterEndGameItems()
    BirzhaData:PlayVictoryPlayerSound(victoryTeam)
	if GameRules:IsCheatMode() and not IsInToolsMode() then 
        GameRules:SetGameWinner( victoryTeam ) 
        return 
    end
	if GetMapName() == "birzhamemov_zxc" then
		CustomNetTables:SetTableValue("birzha_mmr", "game_winner", {t = victoryTeam} )
		BirzhaData.PostData()
		GameRules:SetGameWinner( victoryTeam )
		return
	end
	Timers:CreateTimer(1, function()
		GameRules:SetGameWinner( victoryTeam )
	end)
	if BirzhaData:GetPlayerCount() > 3 or IsInToolsMode() then
		CustomNetTables:SetTableValue("birzha_mmr", "game_winner", {t = victoryTeam} )
		BirzhaData.PostData()
		BirzhaData.PostHeroesInfo()
		BirzhaData.PostHeroPlayerHeroInfo()
		BirzhaData:SendDataPlayerReports()
	end
end

function BirzhaGameMode:OnNPCSpawned(event)
    local hero = EntIndexToHScript(event.entindex)
    if not hero then return end

    -- Обработка не-героев
    if not hero:IsHero() then
        self:HandleNonHeroSpawn(hero)
        return
    end

    -- Обработка дисконнекта
    if hero:HasModifier("modifier_birzha_disconnect") then
        hero:AddNewModifier(hero, nil, "modifier_fountain_invulnerability", {})
    end

    -- Обработка чариота и его иллюзий
    self:HandleChariotSpawn(hero)

    -- Добавление магической защиты
    if hero:IsHero() then
        AddValveUselessMagicalResistance(hero)
        hero:AddItemByName("item_tpscroll_custom")
        Timers:CreateTimer(0.1, function()
            local item_tpscroll = hero:FindItemInInventory("item_tpscroll")
            if item_tpscroll then
                UTIL_Remove(item_tpscroll)
            end
        end)
    end

    -- Обработка настоящих героев
    if hero:IsRealHero() then
        local PlayerID = hero:GetPlayerOwnerID()
        
        -- Воспроизведение звуков спавна
        self:PlayHeroSpawnSounds(hero)
        
        -- Обработка квеста Пуччи
        self:HandlePucciQuest(hero)
        
        -- Бессмертие после возрождения
        self:ApplyRespawnInvulnerability(hero)
        
        -- Инициализация при первом спавне
        if not hero.BirzhaFirstSpawned then
            self:InitializeHeroFirstSpawn(hero, PlayerID)
        end
    end

    -- Инициализация кастомных моделей
    if hero:IsHero() and not hero.AddedCustomModels then
        hero.AddedCustomModels = true
        hero.overlord_kill = nil
        BirzhaGameMode:OnHeroInGame(hero)
    end
end

-- Вспомогательные функции

function BirzhaGameMode:HandleNonHeroSpawn(unit)
    local twin_gate_portal_warp = unit:FindAbilityByName("twin_gate_portal_warp")
    if twin_gate_portal_warp then
        twin_gate_portal_warp:Destroy()
    end
end

function BirzhaGameMode:HandleChariotSpawn(hero)
    local chariotTypes = {
        ["npc_palnoref_chariot"] = function()
            if not hero.chariot_sword then
                hero.chariot_sword = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/polnaref/chariot_sword.vmdl"})
                hero.chariot_sword:FollowEntity(hero, true)
            end
        end,
        ["npc_palnoref_chariot_illusion"] = function()
            local sword = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/polnaref/chariot_sword.vmdl"})
            sword:FollowEntity(hero, true)
            sword:SetRenderColor(0, 0, 0)
        end,
        ["npc_palnoref_chariot_illusion_2"] = function()
            local sword = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/polnaref/chariot_sword.vmdl"})
            sword:FollowEntity(hero, true)
            sword:SetRenderColor(0, 0, 0)
        end
    }

    local handler = chariotTypes[hero:GetUnitName()]
    if handler then handler() end
end

function BirzhaGameMode:PlayHeroSpawnSounds(hero)
    local soundData = {
        ["npc_dota_hero_treant"] = {
            firstSpawn = "OverlordSpawn",
            respawn = {sound = "OverlordRein", chance = 25}
        },
        ["npc_dota_hero_venom"] = {
            firstSpawn = "venom_start"
        },
        ["npc_dota_hero_ashab_tamaev"] = {
            always = "ashab_spawn"
        },
        ["npc_dota_hero_travoman"] = {
            firstSpawn = "travoman_spawn",
            respawn = {sound = "travoman_spawn", chance = 25}
        },
        ["npc_dota_hero_sasake"] = {
            respawn = {sound = "sasake_respawn", chance = 20}
        }
    }

    local data = soundData[hero:GetUnitName()]
    if not data then return end

    if data.always then
        hero:EmitSound(data.always)
    elseif not hero.BirzhaFirstSpawned and data.firstSpawn then
        hero:EmitSound(data.firstSpawn)
    elseif hero.BirzhaFirstSpawned and data.respawn and RollPercentage(data.respawn.chance) then
        hero:EmitSound(data.respawn.sound)
    end

    -- Специальная обработка для Sasake
    if hero:GetUnitName() == "npc_dota_hero_sasake" then
        Timers:CreateTimer(0.5, function()
            hero:RemoveModifierByName("modifier_medusa_mana_shield")
        end)
    end
end

function BirzhaGameMode:HandlePucciQuest(hero)
    local ability_pucci = hero:FindAbilityByName("pucci_restart_world")
    if not (ability_pucci and ability_pucci:GetLevel() > 0) then return end

    if ability_pucci.current_quest[4] == false and ability_pucci.current_quest[1] == "pucci_quest_respawn" then
        ability_pucci.current_quest[2] = ability_pucci.current_quest[2] + 1
        
        local player = PlayerResource:GetPlayer(hero:GetPlayerOwnerID())
        CustomGameEventManager:Send_ServerToPlayer(player, "pucci_quest_event_set_progress", {
            min = ability_pucci.current_quest[2],
            max = ability_pucci.current_quest[3]
        })

        if ability_pucci.current_quest[2] >= ability_pucci.current_quest[3] then
            ability_pucci.current_quest[4] = true
            ability_pucci.word_count = ability_pucci.word_count + 1
            ability_pucci.current_quest = ability_pucci.quests[GetMapName()]["pucci_quest_stunned"]
            ability_pucci:SetActivated(true)
            
            CustomGameEventManager:Send_ServerToPlayer(player, "pucci_quest_event_set_quest", {
                quest_name = ability_pucci.current_quest[1],
                min = ability_pucci.current_quest[2],
                max = ability_pucci.current_quest[3]
            })
        end
    end
end

function BirzhaGameMode:ApplyRespawnInvulnerability(hero)
    if BIRZHA_FOUNTAIN_GAME_TIMER <= 0 and not hero:IsReincarnating() and not hero:IsIllusion() then
        hero:AddInvul(3)
    end
end

function BirzhaGameMode:InitializeHeroFirstSpawn(hero, PlayerID)
    hero.BirzhaFirstSpawned = true
    
    if not hero:IsRealHero() then return end

    local playerData = BirzhaData.PLAYERS_GLOBAL_INFORMATION[PlayerID]
    if not playerData then return end

    -- Обновление информации о команде
    playerData.team = hero:GetTeamNumber()

    -- Инициализация героя при первом выборе
    if not playerData.selected_hero then
        playerData.selected_hero = hero
        hero:AddNewModifier(hero, nil, "modifier_birzha_start_movespeed", {duration = 10})
        birzha_hero_selection:AddDonateFromStart(PlayerID)
        donate_shop:AddedDonateStart(hero, PlayerID)
    end

    -- Обработка репортов
    if playerData.has_report > 0 then
        local modifier = hero:AddNewModifier(hero, nil, "modifier_birzha_loser", {})
        if modifier then
            modifier:SetStackCount(playerData.has_report)
        end
    end

    -- Инициализация способностей
    if hero:IsHero() then
        BirzhaGameMode:AbilitiesStart(hero)
    end

    -- Регистрация ботов в режиме инструментов
    if IsInToolsMode() and PlayerResource:IsFakeClient(PlayerID) then
        BirzhaData:RegisterPlayer(PlayerID)
        BirzhaData.PLAYERS_GLOBAL_INFORMATION[PlayerID].selected_hero = hero
    end
end

function BirzhaGameMode:AbilitiesStart(hero)
	local FastAbilities = _G.FastAbilities
	for _, name in pairs(FastAbilities) do
	   	local FastAbility = hero:FindAbilityByName(name)
		if FastAbility then
			FastAbility:SetLevel(1)
		end
	end
end

function BirzhaGameMode:OnHeroInGame(hero)
	local playerID = hero:GetPlayerID()
	local npcName = hero:GetUnitName()

    -- Heroes with visual particles
    if npcName == "npc_dota_hero_travoman" then
		local particle_cart = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_ambient_arcana.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
		ParticleManager:SetParticleControlEnt( particle_cart, 0, hero, PATTACH_POINT_FOLLOW, "attach_attack1", Vector(0,0,0), true )
	end
    if npcName == "npc_dota_hero_kelthuzad" then
        local particle_list =
        {
            {"particles/econ/items/lich/forbidden_knowledge/lich_forbidden_knowledge_ambient_book.vpcf", "attach_hitloc"},
            {"particles/units/heroes/hero_lich/lich_ambient_frost.vpcf", "attach_attack1"},
            {"particles/units/heroes/hero_lich/lich_ambient_frost_legs.vpcf", "attach_hitloc"},
            {"particles/units/heroes/hero_lich/lich_ambient_frost_ground_effect.vpcf", "attach_hitloc"},
        }
        for _, info in pairs(particle_list) do
		    local particle = ParticleManager:CreateParticle(info[1], PATTACH_ABSORIGIN_FOLLOW, hero)
		    ParticleManager:SetParticleControlEnt( particle, 0, hero, PATTACH_POINT_FOLLOW, info[2], Vector(0,0,0), true )
            if _ == 1 then
                ParticleManager:SetParticleControlEnt( particle, 1, hero, PATTACH_POINT_FOLLOW, info[2], Vector(0,0,0), true )
            end
        end
	end
    if npcName == "npc_dota_hero_old_god" then
        --local particle = ParticleManager:CreateParticle("particles/old_god/wisp_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
        --ParticleManager:SetParticleControlEnt(particle, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
    end
    -- Heroes with Free Items
    if npcName == "npc_dota_hero_serega_pirat" then
        local set_items = 
        {
            "models/items/antimage/god_eater_weapon/god_eater_weapon.vmdl",
            "models/items/antimage/god_eater_off_hand/god_eater_off_hand.vmdl",
            "models/items/antimage/god_eater_shoulder/god_eater_shoulder.vmdl",
            "models/items/antimage/god_eater_head/god_eater_head.vmdl",
            "models/items/antimage/god_eater_belt/god_eater_belt.vmdl",
            "models/items/antimage/god_eater_arms/god_eater_arms.vmdl",
            "models/items/antimage/god_eater_armor/god_eater_armor.vmdl",
        }
        for _, item in pairs(set_items) do
            local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
            model_item:FollowEntity(hero, true)
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, model_item)
        end
	end

    if npcName == "npc_dota_hero_sasake" then
        local set_items = 
        {
            "models/items/juggernaut/arcana/juggernaut_arcana_mask.vmdl",
            "models/items/juggernaut/armor_for_the_favorite_legs/armor_for_the_favorite_legs.vmdl",
            "models/items/juggernaut/jugg_ti8/jugg_ti8_sword.vmdl",
        }
        for _, item in pairs(set_items) do
            local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
            model_item:FollowEntity(hero, true)
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, model_item)
            if _ == 3 then
                ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_ti8_sword/jugg_ti8_crimson_sword_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            end
        end
	end

    if hero:GetUnitName() == "npc_dota_hero_void_spirit" then
        local set_items = 
        {
            "models/items/queenofpain/queenofpain_arcana/queenofpain_arcana_head.vmdl",
            "models/items/queenofpain/queenofpain_arcana/queenofpain_arcana_armor.vmdl",
        }
        for _, item in pairs(set_items) do
            local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
            model_item:FollowEntity(hero, true)
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, model_item)
            if _ == 1 then
                ParticleManager:CreateParticle("particles/econ/items/queen_of_pain/qop_arcana/qop_arcana_head_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            end
        end
	end

    if hero:GetUnitName() == "npc_dota_hero_grimstroke" then
        local grimstroke_list = 
        {
            ["models/heroes/grimstroke/grimstroke_head_item.vmdl"] = true,
        }
        BirzhaGameMode:DeleteAllItemFromHero(hero, grimstroke_list, nil)
	end

    if npcName == "npc_dota_hero_abaddon" then
		local WeaponMeepo = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/meepo/ti8_meepo_pitmouse_fraternity_weapon/ti8_meepo_pitmouse_fraternity_weapon.vmdl"})
		WeaponMeepo:FollowEntity(hero, true)
        if hero and hero.cosmetic_items == nil then
            hero.cosmetic_items = {}
        end
        table.insert(hero.cosmetic_items, WeaponMeepo)
	end

	if npcName == "npc_dota_hero_enigma" then
		local Ricardo = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/axe/ricardaxe.vmdl"})
		Ricardo:FollowEntity(hero, true)
        if hero and hero.cosmetic_items == nil then
            hero.cosmetic_items = {}
        end
        table.insert(hero.cosmetic_items, Ricardo)
	end

    if npcName == "npc_dota_hero_nyx_assassin" then
        local set_items = 
        {
            "models/items/rikimaru/ti6_blink_strike/riki_ti6_blink_strike.vmdl",
            "models/items/rikimaru/umbrage/umbrage.vmdl",
            "models/items/rikimaru/umbrage__offhand/umbrage__offhand.vmdl",
            "models/items/rikimaru/riki_ti8_immortal_head/riki_ti8_immortal_head.vmdl",
            "models/items/rikimaru/riki_cunning_corsair_ti_2017_tail/riki_cunning_corsair_ti_2017_tail.vmdl",
        }
        for _, item in pairs(set_items) do
            local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
            model_item:FollowEntity(hero, true)
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, model_item)
            if _ == 1 then
                ParticleManager:CreateParticle("particles/econ/items/riki/riki_immortal_ti6/riki_immortal_ti6_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            elseif _ == 4 then
                ParticleManager:CreateParticle("particles/econ/items/riki/riki_head_ti8/riki_head_ambient_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            end
        end
	end

	if hero:GetUnitName() == "npc_dota_hero_nevermore" then
		if DonateShopIsItemActive(playerID, 27) then
            local ignore_list = 
            {
                ["models/heroes/shadow_fiend/shadow_fiend_head.vmdl"] = true,
            }
            BirzhaGameMode:DeleteAllItemFromHero(hero, nil, ignore_list)
			hero:SetOriginalModel("models/heroes/shadow_fiend/shadow_fiend_arcana.vmdl")
            local set_items = 
            {
                "models/heroes/shadow_fiend/arcana_wings.vmdl",
                "models/items/nevermore/ferrum_chiroptera_shoulder/ferrum_chiroptera_shoulder.vmdl",
                "models/heroes/shadow_fiend/head_arcana.vmdl",
                "models/items/shadow_fiend/arms_deso/arms_deso.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
			Timers:CreateTimer(0.25, function()
				local desolator = ParticleManager:CreateParticle("particles/never_arcana/desolationhadow_fiend_desolation_ambient.vpcf", PATTACH_CUSTOMORIGIN, hero)
				ParticleManager:SetParticleControlEnt( desolator, 0, hero, PATTACH_POINT_FOLLOW, "attach_arm_L", Vector(0,0,0), true )
				ParticleManager:SetParticleControlEnt( desolator, 1, hero, PATTACH_POINT_FOLLOW, "attach_arm_R", Vector(0,0,0), true )
			end)
			hero:AddNewModifier( hero, nil, "modifier_bp_never_reward", {})
		end
	end

	if npcName == "npc_dota_hero_earthshaker" then
		if DonateShopIsItemActive(playerID, 28) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:SetOriginalModel("models/items/earthshaker/earthshaker_arcana/earthshaker_arcana.vmdl")
            local set_items = 
            {
                "models/items/earthshaker/earthshaker_arcana/earthshaker_arcana_head.vmdl",
                "models/items/earthshaker/ti9_immortal/ti9_immortal.vmdl",
                "models/items/earthshaker/frostivus2018_es_frozen_wastes_arms/frostivus2018_es_frozen_wastes_arms.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 1 then
                    ParticleManager:CreateParticle("particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_head_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 2 then
                    ParticleManager:CreateParticle("particles/econ/items/earthshaker/earthshaker_ti9/earthshaker_ti9_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                end
            end
            hero:AddNewModifier( hero, nil, "modifier_bp_valakas_reward", {})
		end
	end

	if npcName == "npc_dota_hero_legion_commander" then
		if DonateShopIsItemActive(playerID, 126) or IsInToolsMode() then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:AddActivityModifier("dualwield")
			hero:AddActivityModifier("arcana")
			hero:SetMaterialGroup("1")
            local set_items = 
            {
                "models/items/legion_commander/radiant_conqueror_head/radiant_conqueror_head.vmdl",
                "models/items/legion_commander/radiant_conqueror_arms/radiant_conqueror_arms.vmdl",
                "models/items/legion_commander/radiant_conqueror_back/radiant_conqueror_back.vmdl",
                "models/items/legion_commander/radiant_conqueror_shoulder/radiant_conqueror_shoulder.vmdl",
                "models/items/legion_commander/radiant_conqueror_legs/radiant_conqueror_legs.vmdl",
                "models/items/legion_commander/demon_sword.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 1 then
                    ParticleManager:CreateParticle("particles/econ/items/legion/legion_radiant_conqueror/legion_radiant_conqueror_head_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 3 then
                    ParticleManager:CreateParticle("particles/econ/items/legion/legion_radiant_conqueror/legion_radiant_conqueror_back_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 4 then
                    ParticleManager:CreateParticle("particles/econ/items/legion/legion_radiant_conqueror/legion_radiant_conqueror_shoulder_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 5 then
                    local particle_ayano_1 = ParticleManager:CreateParticle("particles/econ/items/legion/legion_weapon_voth_domosh/legion_arcana_weapon.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                    ParticleManager:SetParticleControlEnt( particle_ayano_1, 0, hero, PATTACH_POINT_FOLLOW, "attach_attack1", Vector(0,0,0), true )
                    local particle_ayano_2 = ParticleManager:CreateParticle("particles/econ/items/legion/legion_weapon_voth_domosh/legion_arcana_weapon_offhand.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                    ParticleManager:SetParticleControlEnt( particle_ayano_2, 0, hero, PATTACH_POINT_FOLLOW, "attach_attack2", Vector(0,0,0), true )
                end
            end
			hero:AddNewModifier( hero, nil, "modifier_bp_ayano", {})
		end
	end

	if npcName == "npc_dota_hero_monkey_king" then
		if DonateShopIsItemActive(playerID, 130) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:AddActivityModifier("arcana")
            hero:SetMaterialGroup("1")
            local set_items = 
            {
                "models/items/monkey_king/monkey_king_arcana_head/mesh/monkey_king_arcana.vmdl",
                "models/items/monkey_king/monkey_king_immortal_weapon/monkey_king_immortal_weapon.vmdl",
                "models/items/monkey_king/mk_ti9_immortal_armor/mk_ti9_immortal_armor.vmdl",
                "models/items/monkey_king/mk_ti9_immortal_shoulder/mk_ti9_immortal_shoulder.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 1 then
                    ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/monkey_king_arcana_crown_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 2 then
                    ParticleManager:CreateParticle("particles/econ/items/monkey_king/ti7_weapon/mk_ti7_golden_immortal_weapon_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                    hero.BoyWeapon:SetMaterialGroup("2")
                elseif _ == 3 then
                    ParticleManager:CreateParticle("particles/econ/items/monkey_king/mk_ti9_immortal/mk_ti9_immortal_armor_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                end
            end
			local particle_boy_1 = ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/monkey_king_arcana_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			ParticleManager:SetParticleControl(particle_boy_1, 0, hero:GetAbsOrigin())
			hero:AddNewModifier( hero, nil, "modifier_bp_dangerous_boy", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_lycan" then
		if DonateShopIsItemActive(playerID, 37) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:SetOriginalModel("models/creeps/knoll_1/werewolf_boss.vmdl")
			hero:SetModelScale(1.4)
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_queenofpain" then
		if DonateShopIsItemActive(playerID, 26) then
			hero:SetOriginalModel("models/update_heroes/kurumi/kurumi_arcana.vmdl")
			hero:SetModelScale(0.92)
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_faceless_void" then
		if DonateShopIsItemActive(playerID, 180) then
			hero:SetOriginalModel("models/dio_arcana/dio_arcana.vmdl")
			hero:SetModelScale(1.03)
			hero:AddNewModifier(hero, nil, "modifier_bp_dio", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_oracle" then
		if DonateShopIsItemActive(playerID, 182) then
			hero:SetOriginalModel("models/korra/korra_model.vmdl")
			hero:AddNewModifier(hero, nil, "modifier_avatar_persona", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_sonic" then
		if DonateShopIsItemActive(playerID, 183) then
			hero:SetOriginalModel("models/sonic_arcana/sonic_arcana.vmdl")
			hero:AddNewModifier(hero, nil, "modifier_sonic_arcana", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_alchemist" then
		if DonateShopIsItemActive(playerID, 36) then
			hero.brb_crown = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/birzhapass/crown_bigrussianboss.vmdl"})
			hero.brb_crown:FollowEntity(hero, true)
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_bounty_hunter" then
		if DonateShopIsItemActive(playerID, 31) then
            local set_items = 
            {
                "models/items/bounty_hunter/bh_ti9_immortal_weapon/bh_ti9_immortal_weapon.vmdl"
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                ParticleManager:CreateParticle("particles/econ/items/bounty_hunter/bounty_hunter_ti9_immortal/bh_ti9_immortal_weapon.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            end
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_tiny" then
		if DonateShopIsItemActive(playerID, 30) then
			hero:SetOriginalModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_01.vmdl")
			hero:AddNewModifier( hero, nil, "modifier_bp_johncena", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_ogre_magi" then
		if DonateShopIsItemActive(playerID, 23) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:SetOriginalModel("models/creeps/ogre_1/boss_ogre.vmdl")
		end
	end

    if hero:GetUnitName() == "npc_dota_hero_sand_king" then
		if DonateShopIsItemActive(playerID, 22) then
			hero:SetMaterialGroup("event")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_pyramide" then
		if DonateShopIsItemActive(playerID, 181) then
			hero:SetMaterialGroup("battlepass")
			hero:AddNewModifier(hero, nil, "modifier_pyramide_persona", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_winter_wyvern" then
		if DonateShopIsItemActive(playerID, 35) then
			hero:SetMaterialGroup("event")
		end
	end

	if npcName == "npc_dota_hero_omniknight" then
		if DonateShopIsItemActive(playerID, 32) then
            local set_items = 
            {
                "models/omniknight_zelensky_head.vmdl"
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_dragon_knight" then
        local weapon_dk_model = "models/items/dragon_knight/aurora_warrior_set_weapon/aurora_warrior_set_weapon.vmdl"
		if DonateShopIsItemActive(playerID, 38) then
			hero:SetOriginalModel("models/heroes/dragon_knight_persona/dk_persona_base.vmdl")
            weapon_dk_model = "models/heroes/dragon_knight_persona/dk_persona_weapon_alt.vmdl"
        end
        local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = weapon_dk_model})
        model_item:FollowEntity(hero, true)
        if hero and hero.cosmetic_items == nil then
            hero.cosmetic_items = {}
        end
        table.insert(hero.cosmetic_items, model_item)
	end

	if npcName == "npc_dota_hero_troll_warlord" then
		if DonateShopIsItemActive(playerID, 24) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
            local set_items = 
            {
                "models/troll_warlord_gorin_stool.vmdl",
                "models/heroes/troll_warlord/troll_warlord_head.vmdl",
                "models/heroes/troll_warlord/troll_warlord_shoulders.vmdl",
                "models/heroes/troll_warlord/mesh/troll_warlord_armor_model_lod0.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
			hero:SetRangedProjectileName("particles/gorin_attack_item.vpcf")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_sniper" then
		if DonateShopIsItemActive(playerID, 200) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
            local set_items = 
            {
                "models/items/sniper/scifi_sniper_test_shoulder/scifi_sniper_test_shoulder.vmdl",
                "models/items/sniper/scifi_sniper_test_head/scifi_sniper_test_head.vmdl",
                "models/items/sniper/scifi_sniper_test_gun/scifi_sniper_test_gun.vmdl",
                "models/items/sniper/scifi_sniper_test_back/scifi_sniper_test_back.vmdl",
                "models/items/sniper/scifi_sniper_test_arms/scifi_sniper_test_arms.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 2 then
                    ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_fall20_immortal/sniper_fall20_immortal_head.vpcf", PATTACH_POINT_FOLLOW, model_item)
                elseif _ == 3 then
                    ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_fall20_immortal/sniper_fall20_immortal_weapon_ambient.vpcf", PATTACH_POINT_FOLLOW, model_item)
                elseif _ == 4 then
                    ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_fall20_immortal/sniper_fall20_immortal_jetpack.vpcf", PATTACH_POINT_FOLLOW, model_item)
                end
            end
			hero:AddActivityModifier("scifi")
			hero:AddActivityModifier("SCIFI")
			hero:AddActivityModifier("MGC")
			hero:SetRangedProjectileName("particles/econ/items/sniper/sniper_fall20_immortal/sniper_fall20_immortal_base_attack.vpcf")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_terrorblade" then
		hero:AddActivityModifier("arcana")
		hero:AddActivityModifier("abysm")
		if DonateShopIsItemActive(playerID, 34) then
			local TerrorbladeWeapons = 
            {
				["models/heroes/terrorblade/weapon.vmdl"] = true,
				["models/items/terrorblade/corrupted_weapons/corrupted_weapons.vmdl"] = true,
				["models/items/terrorblade/endless_purgatory_weapon/endless_purgatory_weapon.vmdl"] = true,
				["models/items/terrorblade/knight_of_foulfell_terrorblade_weapon/knight_of_foulfell_terrorblade_weapon.vmdl"] = true,
				["models/items/terrorblade/marauders_weapon/marauders_weapon.vmdl"] = true,
				["models/items/terrorblade/tb_ti9_immortal_weapon/tb_ti9_immortal_weapon.vmdl"] = true,
				["models/items/terrorblade/tb_samurai_weapon/tb_samurai_weapon.vmdl"] = true,
				["models/heroes/terrorblade/terrorblade_weapon_planes.vmdl"] = true,
			}
            BirzhaGameMode:DeleteAllItemFromHero(hero, TerrorbladeWeapons, nil)
            local set_items = 
            {
                "models/birzhapass/terrorblade_sobolev_book_left.vmdl",
                "models/birzhapass/terrorblade_sobolev_book_right.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
			hero:AddNewModifier( hero, nil, "modifier_bp_sobolev", {})
		end
	end

	if npcName == "npc_dota_hero_invoker" then
		BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
		if DonateShopIsItemActive(playerID, 33) then
            hero:AddNewModifier( hero, nil, "modifier_bp_druzhko_reward", {})
            local set_items = 
            {
                "models/items/invoker_kid/dark_artistry_kid/invoker_kid_dark_artistry_armor.vmdl",
                "models/items/invoker_kid/dark_artistry_kid/invoker_kid_dark_artistry_shoulder.vmdl",
                "models/items/invoker_kid/dark_artistry_kid/invoker_kid_dark_artistry_arms.vmdl",
                "models/items/invoker_kid/dark_artistry_kid/invoker_kid_dark_artistry_back.vmdl",
                "models/items/invoker_kid/dark_artistry_kid/magus_apex_kid.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 4 then
                    ParticleManager:CreateParticle("particles/econ/items/invoker_kid/invoker_dark_artistry/invoker_kid_dark_artistry_cape_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 5 then
                    ParticleManager:CreateParticle("particles/econ/items/invoker_kid/invoker_dark_artistry/invoker_kid_magus_apex_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                end
            end
		else
            local set_items = 
            {
                "models/heroes/invoker_kid/invoker_kid_cape.vmdl",
                "models/heroes/invoker_kid/invoker_kid_sleeves.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_skeleton_king" then
		if DonateShopIsItemActive(playerID, 29) then
			BirzhaGameMode:DeleteAllItemFromHero(hero, nil, nil)
			hero:SetOriginalModel("models/items/wraith_king/arcana/wraith_king_arcana.vmdl")
            local set_items = 
            {
                "models/items/wraith_king/arcana/wraith_king_arcana_weapon.vmdl",
                "models/items/wraith_king/arcana/wraith_king_arcana_head.vmdl",
                "models/items/wraith_king/arcana/wraith_king_arcana_shoulder.vmdl",
                "models/items/wraith_king/arcana/wraith_king_arcana_arms.vmdl",
                "models/items/wraith_king/arcana/wraith_king_arcana_back.vmdl",
                "models/items/wraith_king/arcana/wraith_king_arcana_armor.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
                if _ == 1 then
                    ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_weapon.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                elseif _ == 2 then
                    ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_ambient_head.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
                end
            end
			local AmbientEffect = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_ambient.vpcf", PATTACH_POINT_FOLLOW, hero)
			ParticleManager:SetParticleControl(AmbientEffect, 0, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 1, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 2, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 3, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 4, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 5, hero:GetAbsOrigin())
			ParticleManager:SetParticleControl(AmbientEffect, 6, hero:GetAbsOrigin())
		end
		if DonateShopIsItemActive(playerID, 198) then
            local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/blistering_shade/mesh/blistering_shade_alt.vmdl"})
            model_item:FollowEntity(hero, true)
            model_item:SetMaterialGroup("witness")
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_ti6_bracer/wraith_king_ti6_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, model_item)
            table.insert(hero.cosmetic_items, model_item)
			hero:AddNewModifier(hero, nil, "modifier_papich_hand_effect", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_pudge" then
		if DonateShopIsItemActive(playerID, 25) then
			hero:SetOriginalModel("models/items/pudge/arcana/pudge_arcana_base.vmdl")
			local PudgeBack = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/pudge/arcana/pudge_arcana_back.vmdl"})
			PudgeBack:FollowEntity(hero, true)
			ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_arcana/pudge_arcana_red_back_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, PudgeBack)
			hero:AddNewModifier( hero, nil, "modifier_bp_mum_arcana", {})
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, PudgeBack)
		end
		if DonateShopIsItemActive(playerID, 39) then
			local pudge_mask = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/pudge_mask_v2.vmdl"})
			pudge_mask:FollowEntity(hero, true)
            if hero and hero.cosmetic_items == nil then
                hero.cosmetic_items = {}
            end
            table.insert(hero.cosmetic_items, pudge_mask)
			hero:AddNewModifier( hero, nil, "modifier_bp_mum_mask", {})
		end
		if DonateShopIsItemActive(playerID, 179) then
			if hero ~= nil and hero:IsHero() then
				local children = hero:GetChildren();
				for k,child in pairs(children) do
					if child:GetClassname() == "dota_item_wearable" and (string.find(child:GetModelName(), "weapon") == nil and string.find(child:GetModelName(), "hook") == nil) then
						child:RemoveSelf();
					elseif child:GetClassname() == "dota_item_wearable" and child:GetModelName() == "models/heroes/pudge/leftweapon.vmdl" then
						child:RemoveSelf();
					elseif child:GetClassname() == "dota_item_wearable" and (string.find(child:GetModelName(), "offhand") ~= nil) then
						child:RemoveSelf();
					end
				end
			end
            local set_items = 
            {
                "models/pudge_gopo_set/gopo_back.vmdl",
                "models/heroes/pudge/leftarm.vmdl",
                "models/pudge_gopo_set/gopo_arm.vmdl",
                "models/pudge_gopo_set/gopo_head.vmdl",
                "models/pudge_gopo_set/gopo_belt.vmdl",
                "models/pudge_gopo_set/gopo_wepon.vmdl",
            }
            for _, item in pairs(set_items) do
                local model_item = SpawnEntityFromTableSynchronous("prop_dynamic", {model = item})
                model_item:FollowEntity(hero, true)
                if hero and hero.cosmetic_items == nil then
                    hero.cosmetic_items = {}
                end
                table.insert(hero.cosmetic_items, model_item)
            end
		end
	end
    if hero:IsIllusion() then
		hero:AddNewModifier( hero, nil, "modifier_birzha_illusion_cosmetics", {} )
	end
end

function BirzhaGameMode:DeleteAllItemFromHero(hero, list, ignore_list)
    if hero ~= nil and hero:IsHero() then
        local children = hero:GetChildren();
        for k,child in pairs(children) do
            if list ~= nil then
                if child:GetClassname() == "dota_item_wearable" and list[child:GetModelName()] ~= nil then
                    child:RemoveSelf();
                end
            elseif ignore_list ~= nil then
                if child:GetClassname() == "dota_item_wearable" and ignore_list[child:GetModelName()] == nil then
                    child:RemoveSelf();
                end
            else
                if child:GetClassname() == "dota_item_wearable" then
                    child:RemoveSelf();
                end
            end
        end
    end
end