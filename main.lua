local mod = RegisterMod("samson_hair", 1)
local sfx = SFXManager()

function mod:shear_hair(collectibleType, RNG, EntityPlayer, UseFlags, ActiveSlot, varData)
    if EntityPlayer:GetName() == "Samson" then
        local samsonHairID = Isaac.GetCostumeIdByPath("gfx/characters/Character_007_SamsonHead.anm2")
        local itemConfig = Isaac.GetItemConfig()
        local bloodyLustCollectible = itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_BLOODY_LUST)

        local layerMap = EntityPlayer:GetCostumeLayerMap()
        local descs = EntityPlayer:GetCostumeSpriteDescs()

        for _, mapData in ipairs(layerMap) do
            if mapData.costumeIndex == -1 then goto continue end
            local desc = descs[mapData.costumeIndex + 1]
            if desc == nil then goto continue end

            local itemConfig = desc:GetItemConfig()
            if itemConfig.ID == samsonHairID then
                -- spawn particle, sfx, change sprite
                sfx:Play(SoundEffect.SOUND_BLOODBANK_SPAWN)

                -- reevaluate stats for hair cut
                EntityPlayer:AddCacheFlags(CacheFlag.CACHE_ALL)
                EntityPlayer:EvaluateItems()

                -- dork ass costume removal and replace
                EntityPlayer:RemoveCostume(bloodyLustCollectible)

                local sprite = desc:GetSprite()
                sprite:ReplaceSpritesheet(mapData.layerID, "gfx/characters/samsons_hair_cut.png")
                sprite:LoadGraphics()

                EntityPlayer:GetData().PendingShearsAction = true
            end
            ::continue::
        end

        EntityPlayer:AnimateCollectible(collectibleType)
        return true
    end
end

function mod:on_player_update(EntityPlayer)
    local data = EntityPlayer:GetData()

    if not data.PendingShearsAction then
        return
    end

    if not EntityPlayer:IsExtraAnimationFinished() then
        return
    end

    EntityPlayer:AddCacheFlags(CacheFlag.CACHE_ALL)
    EntityPlayer:EvaluateItems()
    data.PendingShearsAction = nil
    data.UsedShears = true

    sfx:Play(SoundEffect.SOUND_KNIFE_PULL)
    sfx:Play(SoundEffect.SOUND_MUSHROOM_POOF_2)
    local haircutParticleVariant = Isaac.GetEntityVariantByName("Haircut Particles")
    local haircutParticleEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, haircutParticleVariant, 0, EntityPlayer.Position, Vector(0, 0), EntityPlayer):ToEffect()
    haircutParticleEffect:FollowParent(EntityPlayer)
    haircutParticleEffect.DepthOffset = 100

    EntityPlayer:AddHearts(-EntityPlayer:GetHearts())
    local maxHearts = EntityPlayer:GetMaxHearts()

    if maxHearts > 2 then
        EntityPlayer:AddMaxHearts(2 - maxHearts)
    elseif maxHearts < 2 then
        EntityPlayer:AddMaxHearts(2 - maxHearts)
    end
    
    EntityPlayer:AddHearts(1)
    EntityPlayer:AddBrokenHearts(11)
end

function mod:shear_set_stats(player, cacheFlag)
    local data = player:GetData()
    if data.UsedShears then return end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_PINKING_SHEARS) then
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = 0.1
        elseif cacheFlag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = 80
        elseif cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = 0.1
        elseif cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearRange = 100.0
        elseif cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = 0
        end
    end
end

mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.shear_hair, CollectibleType.COLLECTIBLE_PINKING_SHEARS)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.on_player_update)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.shear_set_stats)
