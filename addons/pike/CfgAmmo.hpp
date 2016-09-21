class CfgAmmo {
    class FlareBase;
    class GVAR(ammo_gl): FlareBase {
        model = "\A3\weapons_f\ammo\UGL_slug";
        lightColor[] = {0, 0, 0, 0};
        smokeColor[] = {0, 0, 0, 0};
        timeToLive = 2;
    };

    class M_Titan_AT;
    class GVAR(ammo_rocket): M_Titan_AT {
        irLock = 0;
        laserLock = 0;
        airLock = 0;
        manualControl = 0;

        // model = "\A3\weapons_f\ammo\UGL_slug";
        maxSpeed = 120;
        thrust = 45;
        
        hit = 80;
        indirectHit = 8;
        indirectHitRange = 6;

        initTime = 0;

        // Begin ACE guidance Configs
        class ace_missileguidance {
            enabled = 1;

            minDeflection = 0.0005;      // Minium flap deflection for guidance
            maxDeflection = 0.0025;       // Maximum flap deflection for guidance
            incDeflection = 0.0005;      // The incrmeent in which deflection adjusts.

            canVanillaLock = 0;          // Can this default vanilla lock? Only applicable to non-cadet mode

            // Guidance type for munitions
            defaultSeekerType = "SALH";
            seekerTypes[] = {"SALH"};

            defaultSeekerLockMode = "LOAL";
            seekerLockModes[] = {"LOAL"};

            seekerAngle = 90;           // Angle in front of the missile which can be searched
            seekerAccuracy = 1;         // seeker accuracy multiplier

            seekerMinRange = 1;
            seekerMaxRange = 1000;      // Range from the missile which the seeker can visually search

            // Attack profile type selection
            defaultAttackProfile = "LIN";
            attackProfiles[] = { "LIN", "DIR", "MID", "HI" };
        };
    };
};
