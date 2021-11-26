class X2Ability_MoreUpgradesAbilitySet extends X2Ability config(ArmorUpgrades);

var config int ArmorBonus;
var config int MobilityPenalty;
var config int MobilityBonus;
var config int DefensePenalty;
var config int TRPsiShield_ShieldHP;
var config int TRPsiShield_PsiDivisor;
var config int TRAdrenalineSurge_Mobility;
var config int TRShieldRegen_BaseShieldHP;
var config int TRShieldRegen_RegenAmount;
var config int TRShieldRegen_MaxRegen;
var config float TRPlatedComp_DamageReduction;
var config float TRHazmatComp_ExplosiveDamageReduction;
var config float TRStasisComp_WillRestore;
var config float TRStasisComp_HPRestore;

var localized string AblativeHP;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;	

	Templates.AddItem(TRGrenade_Pocket());
	Templates.AddItem(TRAmmo_Pocket());
	Templates.AddItem(TRArmorBonus());
	Templates.AddItem(TRMobilityBonus());
	Templates.AddItem(TRPsiShield());	
	Templates.AddItem(TRAdrenalineSurge());
	Templates.AddItem(TRSmartMod());
	Templates.AddItem(TRShieldRegen());
	Templates.AddItem(TRPlatedComp());
	Templates.AddItem(TRHazmatComp());
	Templates.AddItem(TRStasisComp());

	return Templates;
}

static function X2AbilityTemplate TRGrenade_Pocket()
{
	local X2AbilityTemplate Template;

	Template = CreatePassiveAbility('TRGrenadePocket', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher");
    
	Template.GetBonusWeaponAmmoFn = HeavyOrdnance_BonusWeaponAmmo;

	return Template;
}

function int HeavyOrdnance_BonusWeaponAmmo(XComGameState_Unit UnitState, XComGameState_Item ItemState)
{    
	if (ItemState.InventorySlot == eInvSlot_GrenadePocket)
		return 1;

	return 0;
}

static function X2AbilityTemplate TRAmmo_Pocket()
{
	local X2AbilityTemplate Template;

	Template = CreatePassiveAbility('TRAmmoPocket', "img:///TRMoreUpgrades_Package.perkIcon.UIPerk_ammobelt");

	return Template;
}

static function X2AbilityTemplate TRArmorBonus()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	Template = CreatePassiveAbility('TRArmorBonus', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.ArmorBonus);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, -default.MobilityPenalty);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, default.ArmorBonus);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, -default.MobilityPenalty);

	return Template;
}

static function X2AbilityTemplate TRMobilityBonus()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	Template = CreatePassiveAbility('TRMobilityBonus', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.MobilityBonus);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Defense, -default.DefensePenalty);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, default.MobilityBonus);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.DefenseLabel, eStat_Defense, -default.DefensePenalty);

	return Template;
}

static function X2AbilityTemplate TRPsiShield()
{
	local X2AbilityTemplate Template;
	local X2Effect_TRPsiShield PersistentEffect;

	Template = CreatePassiveAbility('TRPsiShield', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	PersistentEffect = new class'X2Effect_TRPsiShield';
	PersistentEffect.PsiDivisor = default.TRPsiShield_PsiDivisor;
	PersistentEffect.BuildPersistentEffect(1, true, false, false);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentEffect.AddPersistentStatChange(eStat_ShieldHP, default.TRPsiShield_ShieldHP);	
	Template.AddTargetEffect(PersistentEffect);

	Template.SetUIStatMarkup(default.AblativeHP, eStat_ShieldHP, default.TRPsiShield_ShieldHP);	

	return Template;
}

static function X2AbilityTemplate TRAdrenalineSurge()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_PersistentStatChange PersistentStatChangeEffect;	

	Template = CreatePassiveAbility('TRAdrenalineSurge', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");
	Template.bShowActivation = true;	
	Template.bIsPassive = false;
	Template.bSkipFireAction = true;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	

	// Trigger on Damage
	Template.AbilityTriggers.Length = 0; // Reset this from the one granted by CreatePassiveAbility()
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityTargetEffects.Length = 0; // Reset this from the one granted by CreatePassiveAbility()
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(2, false, false, false, eGameRule_PlayerTurnEnd);	
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.TRAdrenalineSurge_Mobility);	
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,, Template.AbilitySourceName);	
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	PersistentStatChangeEffect.EffectName = 'TRAdrenalineSurge';
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, default.TRAdrenalineSurge_Mobility);		

	return Template;
}

static function X2AbilityTemplate TRSmartMod()
{
	local X2AbilityTemplate Template;

	Template = CreatePassiveAbility('TRSmartMod', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	return Template;
}

static function X2AbilityTemplate TRShieldRegen()
{
	local X2AbilityTemplate Template;
	local X2Effect_ShieldRegeneration RegenerationEffect;
	local X2Effect_PersistentStatChange PersistentStatChangeEffect;

	Template = CreatePassiveAbility('TRShieldRegen', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ShieldHP, default.TRShieldRegen_BaseShieldHP);
	Template.AddTargetEffect(PersistentStatChangeEffect);
	
	RegenerationEffect = new class'X2Effect_ShieldRegeneration';
	RegenerationEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.TRShieldRegen_RegenAmount;
	RegenerationEffect.MaxHealAmount = default.TRShieldRegen_MaxRegen;
	RegenerationEffect.ShieldRegeneratedName = 'TRShieldRegen_Regenerated';
	Template.AddTargetEffect(RegenerationEffect);

	return Template;
}

static function X2AbilityTemplate TRPlatedComp()
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange PersistentStatChangeEffect;
	local X2Effect_IncomingDamageMod DamageModifier;

	Template = CreatePassiveAbility('TRPlatedComp', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, -class'X2Ability_ItemGrantedAbilitySet'.default.PLATED_VEST_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	DamageModifier = new class'X2Effect_IncomingDamageMod';	
	DamageModifier.DamageReduction = default.TRPlatedComp_DamageReduction;
	Template.AddTargetEffect(DamageModifier);

	return Template;
}

static function X2AbilityTemplate TRHazmatComp()
{
	local X2AbilityTemplate Template;
	local X2Effect_IncomingDamageMod DamageModifier;

	Template = CreatePassiveAbility('TRHazmatComp', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	DamageModifier = new class'X2Effect_IncomingDamageMod';	
	DamageModifier.ExplosiveDamageReduction = default.TRHazmatComp_ExplosiveDamageReduction;
	DamageModifier.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(DamageModifier);

	return Template;
}

static function X2AbilityTemplate TRStasisComp()
{
	local X2AbilityTemplate Template;	

	Template = CreatePassiveAbility('TRStasisComp', "img:///TRMoreUpgrades_Package.Item_TeleportDisc");

	return Template;
}

static function X2AbilityTemplate CreatePassiveAbility(name AbilityName, optional string IconString, optional name IconEffectName = AbilityName, optional bool bDisplayIcon = true)
{	
	local X2AbilityTemplate Template;
	local X2Effect_Persistent IconEffect;	

	`CREATE_X2ABILITY_TEMPLATE (Template, AbilityName);
	Template.IconImage = IconString;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;
	Template.bUniqueSource = true;
	Template.bIsPassive = true;

	// Dummy effect to show a passive icon in the tactical UI for the SourceUnit
	IconEffect = new class'X2Effect_Persistent';
	IconEffect.BuildPersistentEffect(1, true, false);
	IconEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, bDisplayIcon,, Template.AbilitySourceName);
	IconEffect.EffectName = IconEffectName;
	Template.AddTargetEffect(IconEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}