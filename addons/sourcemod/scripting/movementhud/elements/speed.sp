static Handle HudSync;

MHudEnumPreference SpeedMode;
MHudXYPreference SpeedPosition;
MHudRGBPreference SpeedNormalColor;
MHudRGBPreference SpeedPerfColor;
MHudEnumPreference SpeedTakeoff;
MHudEnumPreference SpeedColorBySpeed;
MHudEnumPreference SpeedRounding;
MHudRGBPreference SpeedGainColor;
MHudRGBPreference SpeedLossColor;
MHudRGBPreference SpeedJBColor;
MHudBoolPreference SpeedCJEnabled;
MHudRGBPreference SpeedCJColor;

static const char Modes[SpeedMode_COUNT][] =
{
    "Disabled",
    "As decimal",
    "As whole number"
};

static const char ModesPhraseKeys[SpeedMode_COUNT][] =
{
    "value.disabled",
    "enum.speed_mode.decimal",
    "enum.speed_mode.integer"
};

static const char Roundings[Round_COUNT][] =
{
    "Round down",
    "Round to nearest",
    "Round up"
};

static const char RoundingsPhraseKeys[Round_COUNT][] =
{
    "enum.rounding.down",
    "enum.rounding.nearest",
    "enum.rounding.up"
};

static const char Takeoff[Takeoff_COUNT][] =
{
    "Disabled",
    "Jumps only",
    "Enabled"
};

static const char TakeoffPhraseKeys[Takeoff_COUNT][] =
{
    "value.disabled",
    "enum.takeoff.jumps_only",
    "enum.takeoff.always"
};

static const char SpeedColors[SpeedKeyColor_COUNT][] =
{
    "Disabled",
    "Color by current speed",
    "Color by gain (Instant)",
    "Color by gain (Average)"
};

static const char SpeedColorsPhraseKeys[SpeedKeyColor_COUNT][] =
{
    "value.disabled",
    "enum.color_by_speed.current_speed",
    "enum.color_by_speed.gain_instant",
    "enum.color_by_speed.gain_average"
};

void OnPluginStart_Elements_Mode_Speed()
{
    SpeedMode = new MHudEnumPreference("speed_mode", "Speed - Mode", Modes, sizeof(Modes) - 1, SpeedMode_None);
    SetPreferenceNamePhraseKey(SpeedMode, "pref.speed_mode");
    SetEnumValuePhraseKeys(SpeedMode, ModesPhraseKeys, sizeof(ModesPhraseKeys));

    SpeedPosition = new MHudXYPreference("speed_position", "Speed - Position", -1, 725);
    SetPreferenceNamePhraseKey(SpeedPosition, "pref.speed_position");
}

void OnPluginStart_Elements_Other_Speed()
{
    HudSync = CreateHudSynchronizer();

    SpeedNormalColor = new MHudRGBPreference("speed_color_normal", "Speed - Normal Color", 255, 255, 255);
    SetPreferenceNamePhraseKey(SpeedNormalColor, "pref.speed_color_normal");

    SpeedPerfColor = new MHudRGBPreference("speed_color_perf", "Speed - Perfect Bhop Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(SpeedPerfColor, "pref.speed_color_perf");

    SpeedTakeoff = new MHudEnumPreference("speed_takeoff", "Speed - Show Takeoff", Takeoff, sizeof(Takeoff) - 1, Takeoff_Jump);
    SetPreferenceNamePhraseKey(SpeedTakeoff, "pref.speed_takeoff");
    SetEnumValuePhraseKeys(SpeedTakeoff, TakeoffPhraseKeys, sizeof(TakeoffPhraseKeys));

    SpeedRounding = new MHudEnumPreference("speed_rounding", "Speed - Rounding", Roundings, sizeof(Roundings) - 1, Round_Down);
    SetPreferenceNamePhraseKey(SpeedRounding, "pref.speed_rounding");
    SetEnumValuePhraseKeys(SpeedRounding, RoundingsPhraseKeys, sizeof(RoundingsPhraseKeys));

    SpeedColorBySpeed = new MHudEnumPreference("speed_color_by_speed", "Speed - Color by Speed", SpeedColors, sizeof(SpeedColors) - 1, SpeedKeyColor_None);
    SetPreferenceNamePhraseKey(SpeedColorBySpeed, "pref.speed_color_by_speed");
    SetEnumValuePhraseKeys(SpeedColorBySpeed, SpeedColorsPhraseKeys, sizeof(SpeedColorsPhraseKeys));

    SpeedGainColor = new MHudRGBPreference("speed_color_gain", "Speed - Gain Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(SpeedGainColor, "pref.speed_color_gain");

    SpeedLossColor = new MHudRGBPreference("speed_color_loss", "Speed - Loss Color", 255, 0, 0);
    SetPreferenceNamePhraseKey(SpeedLossColor, "pref.speed_color_loss");

    SpeedJBColor = new MHudRGBPreference("speed_color_jb", "Speed - Jump Bug Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(SpeedJBColor, "pref.speed_color_jb");

    SpeedCJEnabled = new MHudBoolPreference("speed_color_cj_enabled", "Speed - Crouch Jump Color Enabled", false);
    SetPreferenceNamePhraseKey(SpeedCJEnabled, "pref.speed_color_cj_enabled");

    SpeedCJColor = new MHudRGBPreference("speed_color_cj", "Speed - Crouch Jump Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(SpeedCJColor, "pref.speed_color_cj");
}

void OnGameFrame_Element_Speed(int client, int target)
{
    int mode = SpeedMode.GetInt(client);
    if (mode == SpeedMode_None)
    {
        return;
    }
    int rounding = SpeedRounding.GetInt(client);
    float speed = gF_CurrentSpeed[target];
    
    int showTakeoff = SpeedTakeoff.GetInt(client);
    int colorBySpeed = SpeedColorBySpeed.GetInt(client);

    float xy[2];
    SpeedPosition.GetXY(client, xy);

    int rgb[3];
    switch (colorBySpeed)
    {
        case SpeedKeyColor_None:
        {
            MHudRGBPreference colorPreference;
            if (gB_GotBotInfo[target])
            {
                colorPreference = gH_BotInfo[target].HitPerf && !gH_BotInfo[target].OnGround
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }
            else
            {
                colorPreference = gB_DidPerf[target]
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }

            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_Speed:
        {
            GetColorBySpeed(speed, rgb);
        }
        case SpeedKeyColor_GainInstant:
        {
            MHudRGBPreference colorPreference;
            if (gF_CurrentSpeed[client] - gF_OldSpeed[client] > 0.1)
            {
                colorPreference = SpeedGainColor;
            }
            else if (gF_CurrentSpeed[client] - gF_OldSpeed[client] < -0.1)
            {
                colorPreference = SpeedLossColor;
            }
            else 
            {
                colorPreference = gB_DidPerf[target]
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }
            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_GainAverage:
        {
            MHudRGBPreference colorPreference = gB_DidPerf[target]
                ? SpeedPerfColor
                : SpeedNormalColor;
            colorPreference.GetRGB(client, rgb);
            float gainTicks;
            int gainRGB[3];
            
            for (int i = 0; i < MAX_TRACKED_TICKS; i++)
            {
                if (gF_SpeedChange[client][i] > 0.1)
                {
                    gainTicks += 1.0;
                }
                else if (gF_SpeedChange[client][i] < -0.1)
                {
                    gainTicks -= 1.0;
                }
            }
            
            if (gainTicks >= 0)
            {
                SpeedGainColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, gainTicks/MAX_TRACKED_TICKS, rgb);
            }
            else
            {
                SpeedLossColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, -gainTicks/MAX_TRACKED_TICKS, rgb);
            }
        }
    }

    if (gB_DidJumpBug[target])
    {
        SpeedJBColor.GetRGB(client, rgb);
    }
    if (SpeedCJEnabled.GetBool(client) && gB_DidCrouchJump[target])
    {
        SpeedCJColor.GetRGB(client, rgb);
    }

    Call_OnDrawSpeed(client, xy, rgb);
    
    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    if (mode == SpeedMode_Float)
    {
        if (showTakeoff == Takeoff_None || !gB_DidTakeoff[target] || (showTakeoff == Takeoff_Jump && !gB_DidJump[target]))
        {
            ShowSyncHudText(client, HudSync, "%.2f", speed);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%.2f\n(%.2f)", speed, gF_TakeoffSpeed[target]);
        }
    }
    else
    {
        int speedInt;
        int takeoffSpeedInt;
        switch (rounding)
        {
            case Round_Down:
            {
                // Prevent speed flickering
                speedInt = RoundToFloor(speed);
                if (speed - speedInt >= 0.999)
                {
                    speedInt++;
                }
                takeoffSpeedInt = RoundToFloor(gF_TakeoffSpeed[target]);
                if (gF_TakeoffSpeed[target] - takeoffSpeedInt >= 0.999)
                {
                    takeoffSpeedInt++;
                }
            }
            case Round_Nearest:
            {
                speedInt = RoundToNearest(speed);
                takeoffSpeedInt = RoundToNearest(gF_TakeoffSpeed[target]);
            }
            case Round_Up:
            {
                speedInt = RoundToCeil(speed);
                takeoffSpeedInt = RoundToCeil(gF_TakeoffSpeed[target]);
            }
        }
        if (showTakeoff == Takeoff_None || !gB_DidTakeoff[target] || (showTakeoff == Takeoff_Jump && !gB_DidJump[target]))
        {
            ShowSyncHudText(client, HudSync, "%d", speedInt);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%d\n(%d)", speedInt, takeoffSpeedInt);
        }
    }
}
