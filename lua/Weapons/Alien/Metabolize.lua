//
// lua\Weapons\Alien\Metabolize.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'Metabolize' (Blink)

Metabolize.kMapName = "metabolize"

local networkVars =
{
    lastPrimaryAttackTime = "time"
}

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function Metabolize:OnCreate()

    Blink.OnCreate(self)
    
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
    self.attackedfromshift = nil
end

function Metabolize:GetAnimationGraphName()
    return kAnimationGraph
end

function Metabolize:GetEnergyCost(player)
    return kMetabolizeEnergyCost
end

function Metabolize:GetHUDSlot()
    return 2
end

function Metabolize:GetDeathIconIndex()
    return kDeathMessageIcon.Vortex
end

function Metabolize:GetBlinkAllowed()
    return true
end

function Metabolize:GetAttackDelay()
    return kMetabolizeDelay
end

function Metabolize:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Metabolize:GetSecondaryTechId()
    return kTechId.Blink
end

function Metabolize:GetHasAttackDelay()
    return self.lastPrimaryAttackTime + kMetabolizeDelay > Shared.GetTime()
end

function Metabolize:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay() then
        self.primaryAttacking = true
    else
        self:OnPrimaryAttackEnd()
    end
    
end

function Metabolize:OnPrimaryAttackEnd()
    
    Blink.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

function Metabolize:SetAttackedFromShift(weaponMapName)
    self.attackedfromshift = weaponMapName
end

function Metabolize:OnHolster(player)

    Blink.OnHolster(self, player)
    self.primaryAttacking = false
    
end

function Metabolize:OnTag(tagName)

    PROFILE("Metabolize:OnTag")

    if tagName == "metabolize" and not self:GetHasAttackDelay() then
		local player = self:GetParent()
        if player then
			player:DeductAbilityEnergy(kMetabolizeEnergyCost)
			player:TriggerEffects("metabolize")
			if player:GetCanMetabolizeHealth() then
				player:AddHealth(kMetabolizeHealthRegain, false, false)
			end	
			player:AddEnergy(kMetabolizeEnergyRegain)
			if self.attackedfromshift ~= nil then
				player:SetActiveWeapon(self.attackedfromshift)
			end
			self.attackedfromshift = nil
			self.lastPrimaryAttackTime = Shared.GetTime()
			self.primaryAttacking = false
		end
	elseif tagName == "metabolize_end" then
		local player = self:GetParent()
        if player then
			//Shared.Message(string.format("Time - %s", Shared.GetTime() - player.timeMetabolize))
			self.primaryAttacking = false
		end
	end
    
end

function Metabolize:OnUpdateAnimationInput(modelMixin)

    PROFILE("Metabolize:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "vortex")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Metabolize", Metabolize.kMapName, networkVars)