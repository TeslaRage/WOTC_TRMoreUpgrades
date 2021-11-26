class X2Effect_ShieldRegeneration extends X2Effect_Persistent;

var int HealAmount;
var int MaxHealAmount;
var name ShieldRegeneratedName;
var name EventToTriggerOnShieldRegen;

var localized string HealedMessage;

function bool RegenerationTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit OldTargetState, NewTargetState;
	local UnitValue HealthRegenerated;
	local int AmountToHeal, Healed;
	
	OldTargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (ShieldRegeneratedName != '' && MaxHealAmount > 0)
	{
		OldTargetState.GetUnitValue(ShieldRegeneratedName, HealthRegenerated);

		// If the unit has already been healed the maximum number of times, do not regen
		if (HealthRegenerated.fValue >= MaxHealAmount)
		{
			return false;
		}
		else
		{
			// Ensure the unit is not healed for more than the maximum allowed amount
			AmountToHeal = min(HealAmount, (MaxHealAmount - HealthRegenerated.fValue));
		}
	}
	else
	{
		// If no value tracking for health regenerated is set, heal for the default amount
		AmountToHeal = HealAmount;
	}	

	// Perform the heal
	NewTargetState = XComGameState_Unit(NewGameState.ModifyStateObject(OldTargetState.Class, OldTargetState.ObjectID));
	NewTargetState.ModifyCurrentStat(estat_ShieldHP, AmountToHeal);

	if (EventToTriggerOnShieldRegen != '')
	{
		`XEVENTMGR.TriggerEvent(EventToTriggerOnShieldRegen, NewTargetState, NewTargetState, NewGameState);
	}

	// If this health regen is being tracked, save how much the unit was healed
	if (ShieldRegeneratedName != '')
	{
		Healed = NewTargetState.GetCurrentStat(estat_ShieldHP) - OldTargetState.GetCurrentStat(estat_ShieldHP);
		if (Healed > 0)
		{
			NewTargetState.SetUnitFloatValue(ShieldRegeneratedName, HealthRegenerated.fValue + Healed, eCleanup_BeginTactical);
		}
	}

	return false;
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int Healed;
	local string Msg;

	OldUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	NewUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	Healed = NewUnit.GetCurrentStat(estat_ShieldHP) - OldUnit.GetCurrentStat(estat_ShieldHP);
	
	if( Healed > 0 )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		Msg = Repl(default.HealedMessage, "<Heal/>", Healed);
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Msg, '', eColor_Good);
	}
}

defaultproperties
{
	EffectName="Regeneration"
	EffectTickedFn=RegenerationTicked
}