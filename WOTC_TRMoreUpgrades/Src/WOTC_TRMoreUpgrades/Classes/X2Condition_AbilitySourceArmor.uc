class X2Condition_AbilitySourceArmor extends X2Condition;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{	
	local XComGameState_Item SourceWeapon;	

	SourceWeapon = kAbility.GetSourceWeapon();
	if (SourceWeapon != none)
	{
		if (SourceWeapon.GetMyWeaponUpgradeCount() > 0)
            return 'AA_WeaponIncompatible';
	}
	return 'AA_Success';
}