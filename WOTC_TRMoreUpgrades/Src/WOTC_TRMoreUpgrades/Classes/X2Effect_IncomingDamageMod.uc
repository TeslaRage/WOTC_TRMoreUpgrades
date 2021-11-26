class X2Effect_IncomingDamageMod extends X2Effect_Persistent;

var float DamageReduction;
var float ExplosiveDamageReduction;

function float GetPostDefaultDefendingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState)
{
    local float DamageMod;

    // if (class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.HasArmorUpgradeName(TargetUnit,'TRArmorUpgrade_PlatedVest'))
    // {        
    DamageMod = -(CurrentDamage * DamageReduction);
    // }

    if (WeaponDamageEffect.bExplosiveDamage)
	{
		DamageMod = -(CurrentDamage * ExplosiveDamageReduction);
	}

    return DamageMod; 
}

defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
}