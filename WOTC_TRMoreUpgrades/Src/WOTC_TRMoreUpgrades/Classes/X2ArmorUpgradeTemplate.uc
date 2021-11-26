class X2ArmorUpgradeTemplate extends X2WeaponUpgradeTemplate;

var name Type;                          // Type of armor upgrade
var name VestTemplateName;				// Name of the vest this upgrade was converted from
var name AbilityName;					// Name of the ability this upgrade was converted from
var bool AddToSoldierEarnedAbilities;	// Some abilities need to be added to earned ability list for it to work e.g. abilities with delegate AbilityTemplate.GetBonusWeaponAmmoFn
var array<UIStatMarkup> UIStatMarkups;  // Values to display in the UI (so we don't have to dig through abilities and effects)
var array<name> DisallowedArmorCats;	// Armor cats that are not allowed to use this upgrade
var array<name> DisallowedArmors;		// Armor templates that are not allowed to use this upgrade
var bool bDisablesMutualExclusiveRule;  // Disables mutual exclusions - please use with caution
var int NumOfAdditionalSlots;			// Gives more slots
var name RequiredUpgrade;				// Requires another upgrade to be slotted first. Set up delegate (refer to DLCInfo.static.SetUpDelegateForRequiredUpgrade)

function SetUIStatMarkup(String InLabel,
	optional ECharStatType InStatType = eStat_Invalid, 
	optional int Amount = 0, 
	optional bool ForceShow = false, 
	optional delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShowUIStatFn,
	optional String InUnit)
{
	local UIStatMarkup StatMarkup;

	StatMarkup.StatLabel = InLabel;
	StatMarkup.StatUnit = InUnit;
	StatMarkup.StatModifier = Amount;
	StatMarkup.StatType = InStatType;
	StatMarkup.bForceShow = ForceShow;
	StatMarkup.ShouldStatDisplayFn = ShowUIStatFn;
			
	UIStatMarkups.AddItem(StatMarkup);
}

function int GetUIStatMarkup(ECharStatType Stat, optional XComGameState_Item Item)
{
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;
	local int Index, Modifier;

	for( Index = 0; Index < UIStatMarkups.Length; ++Index )
	{
		ShouldStatDisplayFn = UIStatMarkups[Index].ShouldStatDisplayFn;
		if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
		{
			continue;
		}

		if( UIStatMarkups[Index].StatType == Stat)
		{
			Modifier += UIStatMarkups[Index].StatModifier;
		}
	}

	if ((Stat == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
	{
		Modifier *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
	}

	return Modifier;
}

defaultproperties
{
	DisallowedArmorCats[0] = "spark";
}