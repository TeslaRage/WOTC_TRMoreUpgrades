class X2Item_TRMoreUpgrades extends X2Item_DefaultUpgrades config(ArmorUpgrades);

var config array<VestConversionData> arrVestsToConvert;
var config array<AbilityConversionData> arrAbilitiesToConvert;
var config bool bAllowSparkToUseAllUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local VestConversionData VestToConvert;
	local AbilityConversionData AbilityToConvert;

	// Convert vests to armor upgrades
	foreach default.arrVestsToConvert(VestToConvert)
    {
		if (VestToConvert.DLC != '' && 
			!class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.IsModLoaded(VestToConvert.DLC))
		{
			continue;
		}

		Items.AddItem(CreateVestAsArmorUpgrade(VestToConvert));
	}

	// New armor upgrades based on abilities
	foreach default.arrAbilitiesToConvert(AbilityToConvert)
	{
		if (AbilityToConvert.DLC != '' && 
			!class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.IsModLoaded(AbilityToConvert.DLC))
		{
			continue;
		}
		
		Items.AddItem(CreateArmorUpgradeFromAbility(AbilityToConvert));
	}

	return Items;
}

static function X2DataTemplate CreateVestAsArmorUpgrade(VestConversionData VestToConvert)
{
	local X2ArmorUpgradeTemplate Template;
	local string TemplateName;

	TemplateName = "TRArmorUpgrade_" $VestToConvert.VestTemplateName;
	`CREATE_X2TEMPLATE(class'X2ArmorUpgradeTemplate', Template, name(TemplateName));	   
	
	SetUpArmorUpgrade(Template, 'vest', VestToConvert.bAllowOnSpark);

	Template.Tier = 1;
	Template.VestTemplateName = VestToConvert.VestTemplateName;
	Template.DisallowedArmors = VestToConvert.DisallowedArmors;
	Template.bDisablesMutualExclusiveRule = VestToConvert.bDisablesMutualExclusiveRule;
	Template.NumOfAdditionalSlots = VestToConvert.NumOfAdditionalSlots;
	Template.RequiredUpgrade = VestToConvert.RequiredUpgrade;	

	class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.default.VestTypes.AddItem(Template.DataName); // Yeay hacky
	
	return Template;
}

static function SetUpArmorUpgrade(out X2ArmorUpgradeTemplate Template, name Type, bool bAllowOnSpark)
{	
	local array<name> BlankNames;

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToArmor;
	
	Template.ItemCat = 'armorupgrade';	
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;

	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Type = Type;

	if (bAllowOnSpark || default.bAllowSparkToUseAllUpgrades)
	{
		BlankNames.Length = 0; // Remove warning during compile
		Template.DisallowedArmorCats = BlankNames;
	}	
}

// Copied from X2Item_DefaultUpgrades::CanApplyUpgradeToWeapon
static function bool CanApplyUpgradeToArmor(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex)
{
	local array<X2WeaponUpgradeTemplate> AttachedUpgradeTemplates;
	local X2WeaponUpgradeTemplate AttachedUpgrade;
	local X2ArmorUpgradeTemplate AUTemplate; 
	local X2ArmorTemplate ArmorTemplate;
	local bool bMutualExclusive, bHasRequiredUpgrade;
	local int iSlot;
		
	AttachedUpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();
	AUTemplate = X2ArmorUpgradeTemplate(UpgradeTemplate);
	ArmorTemplate = X2ArmorTemplate(Weapon.GetMyTemplate());

	foreach AttachedUpgradeTemplates(AttachedUpgrade, iSlot)
	{
		// Slot Index indicates the upgrade slot the player intends to replace with this new upgrade
		if (iSlot == SlotIndex)
		{
			// The exact upgrade already equipped in a slot cannot be equipped again
			// This allows different versions of the same upgrade type to be swapped into the slot
			if (AttachedUpgrade == UpgradeTemplate)
			{
				return false;
			}
		}
		else if (UpgradeTemplate.MutuallyExclusiveUpgrades.Find(AttachedUpgrade.DataName) != INDEX_NONE)		
		{			
			// If the new upgrade is mutually exclusive with any of the other currently equipped upgrades, it is not allowed
			// We tag the upgrade			
			bMutualExclusive = true;
			break;
		}

		if (AttachedUpgrade.DataName == AUTemplate.RequiredUpgrade && AUTemplate.RequiredUpgrade != '') bHasRequiredUpgrade = true;
	}

	// If upgrade is mutually exclusive with an attached upgrade and the armor has no upgrade that 
	// disables mutual exclusions
	if ((bMutualExclusive && !HasUpgradeToDisableME(Weapon))) return false;
	
	if (ArmorTemplate != none && AUTemplate != none)
	{
		// Now we check if the armor cat is disallowed
		if (AUTemplate.DisallowedArmorCats.Find(ArmorTemplate.ArmorCat) != INDEX_NONE) return false;

		// Check if this armor template is allowed
		if (AUTemplate.DisallowedArmors.Find(ArmorTemplate.DataName) != INDEX_NONE) return false;
	}

	// If the upgrade needs a required upgrade, and the upgrade is currently not attached
	if (!bHasRequiredUpgrade && AUTemplate.RequiredUpgrade != '') return false;

	return true;
}

static function X2DataTemplate CreateArmorUpgradeFromAbility(AbilityConversionData AbilityToConvert)
{
	local X2ArmorUpgradeTemplate Template;
	local string TemplateName;

	TemplateName = "TRArmorUpgrade_" $AbilityToConvert.AbilityName;
	`CREATE_X2TEMPLATE(class'X2ArmorUpgradeTemplate', Template, name(TemplateName));

	SetUpArmorUpgrade(Template, 'utility', AbilityToConvert.bAllowOnSpark);	

	Template.AbilityName = AbilityToConvert.AbilityName;
	Template.DisallowedArmors = AbilityToConvert.DisallowedArmors;
	Template.AddToSoldierEarnedAbilities = AbilityToConvert.AddToSoldierEarnedAbilities;
	Template.strImage = AbilityToConvert.strImg;
	Template.BonusAbilities.AddItem(AbilityToConvert.AbilityName);

	if (AbilityToConvert.RequiredUpgrade == '')	Template.RewardDecks.AddItem('ExperimentalArmorRewards');
	if (AbilityToConvert.RequiredUpgrade != '') Template.CanBeBuilt = true;

	Template.TradingPostValue = 20;
    Template.Tier = 1;
	Template.bDisablesMutualExclusiveRule = AbilityToConvert.bDisablesMutualExclusiveRule;
	Template.NumOfAdditionalSlots = AbilityToConvert.NumOfAdditionalSlots;
	Template.RequiredUpgrade = AbilityToConvert.RequiredUpgrade;

	class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.default.UtilityTypes.AddItem(Template.DataName); // Yeay hacky
	
	return Template;
}

static function bool HasUpgradeToDisableME(XComGameState_Item Armor)
{
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2ArmorUpgradeTemplate AUTemplate;

	WUTemplates = Armor.GetMyWeaponUpgradeTemplates();
	foreach WUTemplates(WUTemplate)
	{
		AUTemplate = X2ArmorUpgradeTemplate(WUTemplate);
		if (AUTemplate == none) continue;

		if (AUTemplate.bDisablesMutualExclusiveRule) return true;
	}

	return false;
}