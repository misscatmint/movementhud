
MHudEnumPreference UpdateSpeed;
MHudBoolPreference DisableInFreeCamera;

static const char Speeds[UpdateSpeed_COUNT][] =
{
    "Fastest",
    "Fast",
    "Normal",
	"Slow",
	"Slowest"
};

static const char SpeedsPhraseKeys[UpdateSpeed_COUNT][] =
{
    "enum.update_speed.fastest",
    "enum.update_speed.fast",
    "enum.update_speed.normal",
    "enum.update_speed.slow",
    "enum.update_speed.slowest"
};


void OnPluginStart_Elements_Mode()
{
    OnPluginStart_Elements_Mode_Speed();
    OnPluginStart_Elements_Mode_Keys();
    OnPluginStart_Elements_Mode_Indicators();
}

void OnPluginStart_Elements_Other()
{
    OnPluginStart_Elements_Other_Speed();
    OnPluginStart_Elements_Other_Keys();
    OnPluginStart_Elements_Other_Indicators();
    
    UpdateSpeed = new MHudEnumPreference("update_speed", "Update Speed", Speeds, sizeof(Speeds) - 1, UpdateSpeed_Fastest);
    SetPreferenceNamePhraseKey(UpdateSpeed, "pref.update_speed");
    SetEnumValuePhraseKeys(UpdateSpeed, SpeedsPhraseKeys, sizeof(SpeedsPhraseKeys));

    DisableInFreeCamera = new MHudBoolPreference("disable_in_freecam", "Disable HUD in Free Camera", false);
    SetPreferenceNamePhraseKey(DisableInFreeCamera, "pref.disable_in_freecam");
}

bool ShouldUpdateHUD(int client)
{
    if (DisableInFreeCamera.GetBool(client) && IsClientInFreeCamera(client))
    {
        return false;
    }

    return (client + GetGameTickCount()) % (UpdateSpeed.GetInt(client) + 1) == 0;
}

float GetTextHoldTimeMHUD(int client)
{
    return GetTextHoldTime(UpdateSpeed.GetInt(client) + 1);
}
