class UISoldierHeader_TR extends UISoldierHeader config(UIModificationWOTC);

var string m_strDefenseLabel;

var string StoredLastUpdatedPsi;
var string StoredLastUpdatedArmor;
var string StoredLastUpdatedDodge;
var string StoredLastUpdatedDefense;
var string StoredAddWillToCaption;

var string StoredShortArmorString;

var bool StoredNeedArmor;
var bool StoredNeedDodge;
var bool StoredNeedDefense;
var bool StoredNeedPsi;

var bool DisplayXP;
var bool DisplayXP_Check;

var config bool HideAimBonusesFromSwords;
var config bool AddXPDisplay;

public function PopulateData(optional XComGameState_Unit Unit, optional StateObjectReference NewItem, optional StateObjectReference ReplacedItem, optional XComGameState NewCheckGameState)
{
	local int iRank, WillBonus, AimBonus, HealthBonus, MobilityBonus, TechBonus, PsiBonus, PsiBonusChange, ArmorBonus, DodgeBonus, DefenseBonus;
	local int PsiStat;
	local string classIcon, rankIcon, flagIcon, Will, Aim, Health, Mobility, Tech, Psi, Armor, Dodge, Defense;
	local string AddWillToCaption;
	local int RawArmor, RawTotalArmor, RawDodge, RawDefense;
	local bool needPsi, needArmor, needDodge, needDefense;
	local X2SoldierClassTemplate SoldierClass;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Item TmpItem;
	local XComGameStateHistory History;
	local string StatusValue, StatusLabel, StatusDesc, StatusTimeLabel, StatusTimeValue, DaysValue;
	local bool shouldShowPsi;
	local bool unitUsesWill;
	local bool psionicItemEquipped;
	local array<XComGameState_Item> UnitInventory;
	local XComGameState_Item UnitInventoryItem;

	local string KillsLabel;
	local string KillsString;
	local int SoldierRank;
	local string NeededKillsString;

	psionicItemEquipped = false;
	shouldShowPsi = false;

	History = `XCOMHISTORY;
	CheckGameState = NewCheckGameState;

	if (DisplayXP_Check != true) {
		DisplayXP_Check = true;
		if (AddXPDisplay) {
			DisplayXP = true;
		} else {
			if (class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.IsModLoaded('XPDisplay'))
				DisplayXP = true;
		}
	}

	if(Unit == none)
	{
		if(CheckGameState != none)
			Unit = XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitRef.ObjectID));
		else
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	}
	
	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	flagIcon  = (Unit.IsSoldier() && !bHideFlag) ? Unit.GetCountryTemplate().FlagImage : "";
	rankIcon  = Unit.IsSoldier() ? class'UIUtilities_Image'.static.GetRankIcon(iRank, Unit.GetSoldierClassTemplateName()) : "";
	classIcon = Unit.IsSoldier() ? Unit.GetSoldierClassIcon() : Unit.GetMPCharacterTemplate().IconImage;

	if (Unit.IsAlive())
	{
		StatusLabel = m_strStatusLabel;
		class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, StatusDesc, StatusTimeLabel, StatusTimeValue); 
		StatusValue = StatusDesc;
		DaysValue = StatusTimeValue @ StatusTimeLabel;
	}
	else
	{
		StatusLabel = m_strDateKilledLabel;
		StatusValue = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Unit.GetKIADate());
	}

	if(Unit.IsMPCharacter())
	{
		SetSoldierInfo( Caps(strMPForceName == "" ? Unit.GetName( eNameType_FullNick ) : strMPForceName),
							  StatusLabel, StatusValue,
							  class'XGBuildUI'.default.m_strLabelCost, 
							  string(Unit.GetUnitPointValue()),
							  "", "",
							  classIcon, Caps(SoldierClass != None ? Unit.GetSoldierClassDisplayName() : ""),
							  rankIcon, Caps(Unit.IsSoldier() ? `GET_RANK_STR(Unit.GetRank(), Unit.GetSoldierClassTemplateName()) : ""),
							  flagIcon, (Unit.ShowPromoteIcon()), DaysValue);
	}
	else
	{
		if (DisplayXP) {
			KillsLabel = class'XLocalizedData'.default.XpLabel;
			KillsString = string(Unit.GetTotalNumKills());

			SoldierRank = Unit.GetSoldierRank();
			if ((SoldierRank + 1) >= class'X2ExperienceConfig'.static.GetMaxRank()) {
				NeededKillsString = "/-";
			} else {
				NeededKillsString = "/" $ class'X2ExperienceConfig'.static.GetRequiredKills(SoldierRank + 1);
			}

			KillsString $= class'UIUtilities_Text'.static.GetColoredText(NeededKillsString, eUIState_Warning, 18);

		} else {
			KillsLabel = m_strKillsLabel;
			KillsString = string(Unit.GetNumKills());
		}

		SetSoldierInfo( Caps(Unit.GetName( eNameType_FullNick )),
							  StatusLabel, StatusValue,
							  m_strMissionsLabel, string(Unit.GetNumMissions()),
							  KillsLabel, KillsString,
							  classIcon, Caps(SoldierClass != None ? Unit.GetSoldierClassDisplayName() : ""),
							  rankIcon, Caps(`GET_RANK_STR(Unit.GetRank(), Unit.GetSoldierClassTemplateName())),
							  flagIcon, (Unit.ShowPromoteIcon()), DaysValue);
	}

	// Get Unit base stats and any stat modifications from abilities
	
	/* wotc version */
	Will = string(int(Unit.GetCurrentStat(eStat_Will)) + Unit.GetUIStatFromAbilities(eStat_Will)) $ "/" $ string(int(Unit.GetMaxStat(eStat_Will)));
	Will = class'UIUtilities_Text'.static.GetColoredText(Will, Unit.GetMentalStateUIState());

	// just like basic
	Aim = string(int(Unit.GetCurrentStat(eStat_Offense)) + Unit.GetUIStatFromAbilities(eStat_Offense));
	Health = string(int(Unit.GetCurrentStat(eStat_HP)) + Unit.GetUIStatFromAbilities(eStat_HP));
	Mobility = string(int(Unit.GetCurrentStat(eStat_Mobility)) + Unit.GetUIStatFromAbilities(eStat_Mobility));
	Tech = string(int(Unit.GetCurrentStat(eStat_Hacking)) + Unit.GetUIStatFromAbilities(eStat_Hacking));

	RawArmor = int(Unit.GetCurrentStat(eStat_ArmorMitigation)) + Unit.GetUIStatFromAbilities(eStat_ArmorMitigation);
	RawTotalArmor = RawArmor;
	Armor = string(RawArmor);

	RawDodge = int(Unit.GetCurrentStat(eStat_Dodge)) + Unit.GetUIStatFromAbilities(eStat_Dodge);
	Dodge = string(RawDodge);

	RawDefense = int(Unit.GetCurrentStat(eStat_Defense)) + Unit.GetUIStatFromAbilities(eStat_Defense);
	Defense = string(RawDefense);

	if (RawDodge != 0)
		needDodge = true;

	if (RawArmor != 0)
		needArmor = true;

	if (RawDefense != 0)
		needDefense = true;

	/*
	if (Unit.bIsShaken)
	{
		Will = class'UIUtilities_Text'.static.GetColoredText(Will, eUIState_Bad);
	}
	*/

	// Get bonus stats for the Unit from items
	// I could just call my UnitGetUIStatFromInventory for all of these, but eh.	
	WillBonus = UnitGetUIStatFromInventory(Unit, eStat_Will, '', false);
	
	// my version, when needed
	if (default.HideAimBonusesFromSwords)
		AimBonus = UnitGetUIStatFromInventory(Unit, eStat_Offense, 'sword', false);
	else
		AimBonus = UnitGetUIStatFromInventory(Unit, eStat_Offense, '', false);
	
	HealthBonus = UnitGetUIStatFromInventory(Unit, eStat_HP, '', false);

	// my version
	MobilityBonus = UnitGetUIStatFromInventory(Unit, eStat_Mobility, '', true);

	TechBonus = UnitGetUIStatFromInventory(Unit, eStat_Hacking, '', false);
	ArmorBonus = UnitGetUIStatFromInventory(Unit, eStat_ArmorMitigation, '', false);
	DodgeBonus = UnitGetUIStatFromInventory(Unit, eStat_Dodge, '', false);
	DefenseBonus = UnitGetUIStatFromInventory(Unit, eStat_Defense, '', false);

	if (DodgeBonus != 0)
		needDodge = true;
	if (ArmorBonus != 0)
		needArmor = true;
	if (DefenseBonus != 0)
		needDefense = true;

	PsiStat = int(Unit.GetCurrentStat(eStat_PsiOffense)) + Unit.GetUIStatFromAbilities(eStat_PsiOffense);
	Psi = string(PsiStat);
	PsiBonus = UnitGetUIStatFromInventory(Unit, eStat_PsiOffense, '', true);

	if(Unit.IsPsionic() || Unit.bHasPsiGift || PsiStat > 0) {
		shouldShowPsi = true;
	}

	if (!shouldShowPsi)
	{
		UnitInventory = Unit.GetAllInventoryItems(CheckGameState);
		foreach UnitInventory(UnitInventoryItem)
		{
			WeaponTemplate = X2WeaponTemplate(UnitInventoryItem.GetMyTemplate());
			if (WeaponTemplate != none)
			{
				if (WeaponTemplate.WeaponCat == 'psiamp') {
					psionicItemEquipped = true;
					break;
				}
			}
		}

		if (psionicItemEquipped) {
			shouldShowPsi = true;
		}
	}

	// Add bonus stats from an item that is about to be equipped
	if(NewItem.ObjectID > 0)
	{
		if(CheckGameState != None)
			TmpItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(NewItem.ObjectID));
		else
			TmpItem = XComGameState_Item(History.GetGameStateForObjectID(NewItem.ObjectID));
		EquipmentTemplate = X2EquipmentTemplate(TmpItem.GetMyTemplate());
		
		// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
		if (EquipmentTemplate != none) 
		{
            // Grab additional stats from Armor Upgrades
            if (EquipmentTemplate.IsA('X2ArmorTemplate'))
            {
                MobilityBonus += GetStatsFromArmorUpgrades(eStat_Mobility, TmpItem);
                DefenseBonus += GetStatsFromArmorUpgrades(eStat_Defense, TmpItem);
                PsiBonusChange += GetStatsFromArmorUpgrades(eStat_PsiOffense, TmpItem);
                WillBonus += GetStatsFromArmorUpgrades(eStat_Will, TmpItem);
                AimBonus += GetStatsFromArmorUpgrades(eStat_Offense, TmpItem);
                HealthBonus += GetStatsFromArmorUpgrades(eStat_HP, TmpItem);
                TechBonus += GetStatsFromArmorUpgrades(eStat_Hacking, TmpItem);
                ArmorBonus += GetStatsFromArmorUpgrades(eStat_ArmorMitigation, TmpItem);
                DodgeBonus += GetStatsFromArmorUpgrades(eStat_Dodge, TmpItem);
            }

			MobilityBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
			DefenseBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Defense, TmpItem);

			PsiBonusChange = EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);
			if (PsiBonusChange != 0) {
				PsiBonus += PsiBonusChange;
			}

			WeaponTemplate = X2WeaponTemplate(EquipmentTemplate);
			if (WeaponTemplate != none)
			{
				if (WeaponTemplate.WeaponCat == 'psiamp') {
					shouldShowPsi = true;
				}
			}
			
			if (EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
			{
				WillBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Will, TmpItem);

				if (!default.HideAimBonusesFromSwords || !IgnoreThisCategory(TmpItem, 'sword', WeaponTemplate))
					AimBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Offense, TmpItem);

				HealthBonus += EquipmentTemplate.GetUIStatMarkup(eStat_HP, TmpItem);
				//MobilityBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
				TechBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Hacking, TmpItem);
				ArmorBonus += EquipmentTemplate.GetUIStatMarkup(eStat_ArmorMitigation, TmpItem);
				DodgeBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Dodge, TmpItem);
		
				//PsiBonusChange = EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);

			}
		}
	}

	// Subtract stats from an item that is about to be replaced
	if(ReplacedItem.ObjectID > 0)
	{
		if(CheckGameState != None)
			TmpItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(ReplacedItem.ObjectID));
		else
			TmpItem = XComGameState_Item(History.GetGameStateForObjectID(ReplacedItem.ObjectID));
		EquipmentTemplate = X2EquipmentTemplate(TmpItem.GetMyTemplate());
		
		// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
		if (EquipmentTemplate != none)
		{
            // Grab additional stats from Armor Upgrades
            if (EquipmentTemplate.IsA('X2ArmorTemplate'))
            {
                MobilityBonus -= GetStatsFromArmorUpgrades(eStat_Mobility, TmpItem);
                DefenseBonus -= GetStatsFromArmorUpgrades(eStat_Defense, TmpItem);
                PsiBonusChange -= GetStatsFromArmorUpgrades(eStat_PsiOffense, TmpItem);
                WillBonus -= GetStatsFromArmorUpgrades(eStat_Will, TmpItem);
                AimBonus -= GetStatsFromArmorUpgrades(eStat_Offense, TmpItem);
                HealthBonus -= GetStatsFromArmorUpgrades(eStat_HP, TmpItem);
                TechBonus -= GetStatsFromArmorUpgrades(eStat_Hacking, TmpItem);
                ArmorBonus -= GetStatsFromArmorUpgrades(eStat_ArmorMitigation, TmpItem);
                DodgeBonus -= GetStatsFromArmorUpgrades(eStat_Dodge, TmpItem);
            }

			MobilityBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
			DefenseBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Defense, TmpItem);
			
			PsiBonusChange = EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);
			if (PsiBonusChange != 0) {
				PsiBonus -= PsiBonusChange;
			}

			WeaponTemplate = X2WeaponTemplate(EquipmentTemplate);
			if (WeaponTemplate != none)
			{
				if (WeaponTemplate.WeaponCat == 'psiamp') {
					shouldShowPsi = true;
				}
			}
			
			if (EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
			{
				WillBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Will, TmpItem);
				if (!default.HideAimBonusesFromSwords || !IgnoreThisCategory(TmpItem, 'sword', WeaponTemplate))
					AimBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Offense, TmpItem);

				HealthBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_HP, TmpItem);
				//MobilityBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
				TechBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Hacking, TmpItem);
				ArmorBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_ArmorMitigation, TmpItem);
				DodgeBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Dodge, TmpItem);

				//PsiBonusChange = EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);

			}
		}
	}

	// both before and after in case the modification made them 0
	// that might still be good to show
	if (DodgeBonus != 0)
		needDodge = true;
	if (ArmorBonus != 0)
		needArmor = true;
	if (DefenseBonus != 0)
		needDefense = true;

	RawTotalArmor += ArmorBonus;

	// redraw will in a shorter form if there's a bonus/penalty
	if (WillBonus != 0) {
		Will = string(int(Unit.GetCurrentStat(eStat_Will)) + Unit.GetUIStatFromAbilities(eStat_Will));
		Will = class'UIUtilities_Text'.static.GetColoredText(Will, Unit.GetMentalStateUIState());
		AddWillToCaption = string(int(Unit.GetMaxStat(eStat_Will)));
	} else {
		AddWillToCaption = "";
	}

	if( WillBonus > 0 )
		 Will $= class'UIUtilities_Text'.static.GetColoredText("+"$WillBonus,	eUIState_Good);
	else if (WillBonus < 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText(""$WillBonus,	eUIState_Bad);

	if( AimBonus > 0 )
		Aim $= class'UIUtilities_Text'.static.GetColoredText("+"$AimBonus, eUIState_Good);
	else if (AimBonus < 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText(""$AimBonus, eUIState_Bad);

	if( HealthBonus > 0 )
		Health $= class'UIUtilities_Text'.static.GetColoredText("+"$HealthBonus, eUIState_Good);
	else if (HealthBonus < 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText(""$HealthBonus, eUIState_Bad);

	if( MobilityBonus > 0 )
		Mobility $= class'UIUtilities_Text'.static.GetColoredText("+"$MobilityBonus, eUIState_Good);
	else if (MobilityBonus < 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText(""$MobilityBonus, eUIState_Bad);

	if( TechBonus > 0 )
		Tech $= class'UIUtilities_Text'.static.GetColoredText("+"$TechBonus, eUIState_Good);
	else if (TechBonus < 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText(""$TechBonus, eUIState_Bad);
	
	if( ArmorBonus > 0 )
		Armor $= class'UIUtilities_Text'.static.GetColoredText("+"$ArmorBonus, eUIState_Good);
	else if (ArmorBonus < 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText(""$ArmorBonus, eUIState_Bad);

	if( DodgeBonus > 0 )
		Dodge $= class'UIUtilities_Text'.static.GetColoredText("+"$DodgeBonus, eUIState_Good);
	else if (DodgeBonus < 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText(""$DodgeBonus, eUIState_Bad);

	if( DefenseBonus > 0 )
		Defense $= class'UIUtilities_Text'.static.GetColoredText("+"$DefenseBonus, eUIState_Good);
	else if (DefenseBonus < 0)
		Defense $= class'UIUtilities_Text'.static.GetColoredText(""$DefenseBonus, eUIState_Bad);

	if( PsiBonus > 0 )
		Psi $= class'UIUtilities_Text'.static.GetColoredText("+"$PsiBonus, eUIState_Good);
	else if (PsiBonus < 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText(""$PsiBonus, eUIState_Bad);

	if (shouldShowPsi) {
		PsiMarkup.Show();
		needPsi = true;
	} else {
		PsiMarkup.Hide();
		Psi = "";
	}

	StoredShortArmorString = class'UIUtilities_Text'.static.GetColoredText("+"$ string(RawTotalArmor), eUIState_Warning);

	// shove some variables away in case SetSoldierStats gets called
	StoredLastUpdatedArmor = Armor;
	StoredLastUpdatedDodge = Dodge;
	StoredLastUpdatedDefense = Defense;
	StoredLastUpdatedPsi = Psi;

	StoredAddWillToCaption = AddWillToCaption;

	StoredNeedArmor = needArmor;
	StoredNeedDodge = needDodge;
	StoredNeedDefense = needDefense;
	StoredNeedPsi = needPsi;

	if(!bSoldierStatsHidden)
	{
		unitUsesWill = Unit.UsesWillSystem();
		SetSoldierStatsExpand(Health, Mobility, Aim, Will, Armor, Dodge, Defense, Tech, Psi, AddWillToCaption, needArmor, needDodge, needDefense, needPsi, unitUsesWill);
		RefreshCombatSim(Unit);
	}

	Show();
}
/* */

// only called from elsewhere, now!
public function SetSoldierStats(optional string Health	 = "", 
								optional string Mobility = "", 
								optional string Aim	     = "", 
								optional string Will     = "", 
								optional string Armor	 = "", 
								optional string Dodge	 = "", 
								optional string Tech	 = "", 
								optional string Psi		 = "",
								optional bool unitUsesWill = true )
{
	local bool needArmor, needDodge, needDefense, needPsi;
	local string CurrentPsi;
	local string CurrentAddWillToCaption;

	needArmor = StoredNeedArmor;
	needDodge = StoredNeedDodge;
	needDefense = StoredNeedDefense;
	needPsi = StoredNeedPsi;

	if (Armor != "" && Armor != StoredLastUpdatedArmor)
		needArmor = true;
	else if (Armor == "")
		needArmor = false;

	if (Dodge != "" && Dodge != StoredLastUpdatedDodge)
		needDodge = true;

	if (Psi != StoredLastUpdatedPsi)
		needPsi = true;

	CurrentPsi = Psi;
	if (Psi == "" && StoredLastUpdatedPsi != "")
	{
		CurrentPsi = StoredLastUpdatedPsi;
		needPsi = true;
	} 

	CurrentAddWillToCaption = StoredAddWillToCaption;

	SetSoldierStatsExpand(Health, Mobility, Aim, Will, Armor, Dodge, StoredLastUpdatedDefense, Tech, CurrentPsi, CurrentAddWillToCaption, needArmor, needDodge, needDefense, needPsi, unitUsesWill);
}



public function SetSoldierStatsExpand(string Health, string Mobility, string Aim, string Will, string Armor,
	string Dodge, string Defense, string Tech, string Psi, string AddWillToCaption, bool needArmor, bool needDodge, bool needDefense, bool needPsi, bool unitUsesWill)
{
	local bool armorDrawn;
	
	mc.BeginFunctionOp("SetSoldierStats");

	if (m_strDefenseLabel == "")
		m_strDefenseLabel = class'XLocalizedData'.default.DefenseLabel;
	
	if( Health != "" )
	{
		if (needArmor && needDodge && needDefense && needPsi && unitUsesWill) {
			mc.QueueString(m_strHealthLabel $ " / " $ m_strArmorLabel);
			mc.QueueString(Health $ StoredShortArmorString);
			armorDrawn = true;
		} else {
			mc.QueueString(m_strHealthLabel);
			mc.QueueString(Health);
		}
	}
	if( Mobility != "" )
	{
		mc.QueueString(m_strMobilityLabel);
		mc.QueueString(Mobility);
	}
	if( Aim != "" )
	{
		mc.QueueString(m_strAimLabel);
		mc.QueueString(Aim);
	}

	if (!unitUsesWill) {
		if (!needArmor || !needPsi || !needDodge || !needDefense) {
			mc.QueueString("");
			mc.QueueString("");
		}
	} else {
		if( Will != "" )
		{
			if (AddWillToCaption != "" ) {
				mc.QueueString(m_strWillLabel $ "(" $ AddWillToCaption $ ")");
				mc.QueueString(Will);
			} else {
				mc.QueueString(m_strWillLabel);
				mc.QueueString(Will);
			}
		}
	}

	if (!armorDrawn && (needArmor || !needPsi || !needDodge || !needDefense)) {
		if( Armor != "" )
		{
			mc.QueueString(m_strArmorLabel);
			mc.QueueString(Armor);
		}
	}


	if (needDodge || !needPsi || !needDefense) {
		if( Dodge != "" ) {
				mc.QueueString(m_strDodgeLabel);
				mc.QueueString(Dodge);
		}
	}

	if (needDefense) {
		if (Defense != "" )
		{
			mc.QueueString(m_strDefenseLabel);
			mc.QueueString(Defense);
		}
	}

	if( Tech != "" )
	{
		mc.QueueString(m_strTechLabel);
		mc.QueueString(Tech);
	}

	if(needPsi && Psi != "" )
	{
		mc.QueueString( class'UIUtilities_Text'.static.GetColoredText(m_strPsiLabel, eUIState_Psyonic) );
		mc.QueueString( class'UIUtilities_Text'.static.GetColoredText(Psi, eUIState_Psyonic) );
	}

	mc.EndOp();
}

simulated function int UnitGetUIStatFromInventory(XComGameState_Unit Unit, ECharStatType Stat, name IgnoreCat, bool ignoreExcludedList)
{
	local int Result;
	local XComGameState_Item InventoryItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local array<XComGameState_Item> CurrentInventory;

	//  Gather abilities from the unit's inventory
	CurrentInventory = Unit.GetAllInventoryItems(CheckGameState);
	foreach CurrentInventory(InventoryItem)
	{
		EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
		if (EquipmentTemplate != none)
		{
			WeaponTemplate = X2WeaponTemplate(EquipmentTemplate);

			// you probably want to see the bonuses from your primary weapon whatever it is
			if (!IgnoreThisCategory(InventoryItem, IgnoreCat, WeaponTemplate))
			{
				if(ignoreExcludedList || (class'UISoldierHeader'.default.EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE))
				{
					Result += EquipmentTemplate.GetUIStatMarkup(Stat, InventoryItem);
				}
			}
            Result += GetStatsFromArmorUpgrades(Stat, InventoryItem);
		}
	}	

	return Result;
}

simulated function bool IgnoreThisCategory(XComGameState_Item InventoryItem, name IgnoreCat, X2WeaponTemplate WeaponTemplate)
{
	if (IgnoreCat == '' || WeaponTemplate == none || WeaponTemplate.WeaponCat != IgnoreCat)
		return false;

	if (InventoryItem.InventorySlot == eInvSlot_PrimaryWeapon)
		return false;

	return true;
}

simulated function int GetStatsFromArmorUpgrades(ECharStatType Stat, XComGameState_Item Item)
{
    local int Result;		
	local X2ArmorTemplate ArmorTemplate;
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;
    
    ArmorTemplate = X2ArmorTemplate(Item.GetMyTemplate());
    if (ArmorTemplate != none)
    {
        WeaponUpgradeTemplates = Item.GetMyWeaponUpgradeTemplates();
        foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
        {
            ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(WeaponUpgradeTemplate); 
            if (ArmorUpgradeTemplate == none) continue;

            Result += ArmorUpgradeTemplate.GetUIStatMarkup(Stat);
        }
    }
    return Result;
}