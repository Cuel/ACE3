/*
 * Author: Glowbal
 * Check if vehicle is a engineering vehicle.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Is engineering vehicle <BOOL>
 *
 * Example:
 * [vehicle] call ace_repair_fnc_isRepairVehicle
 *
 * Public: Yes
 */
#include "script_component.hpp"

params ["_vehicle"];
TRACE_1("params",_vehicle);

if (_vehicle isKindOf "CAManBase") exitWith {false};

// Backwards compability due to wiki saying isRepairVehicle was a boolean, this function only checked for an integer value.
private _value = _vehicle getVariable ["ACE_isRepairVehicle", -1];
if (_value in [0, false]) exitWith {false};
if (_value isEqualTo true || {value > 0}) exitWith {true};
getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> QGVAR(canRepair)) > 0 // return
