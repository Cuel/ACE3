/*
 * Author: Nou
 * Turn a laser designator on.
 *
 * Arguments:
 * 0: Position of seeker (ASL) <position>
 * 1: Direction vector (will be normalized) <vector>
 * 2: Seeker FOV in degrees <number>
 * 3: Seeker wavelength sensitivity range, [1550,1550] is common eye safe. <array>
 * 4: Seeker laser code. <number>
 *
 * Return Value:
 * Array, [Strongest compatible laser spot ASL pos, owner object] Nil array values if nothing found.
 */

#include "script_component.hpp"

params ["_posASL", "_dir", "_seekerFov", "_seekerWavelengths", "_seekerCode", ["_ignoreObj1", objNull]];

_dir = vectorNormalized _dir;
_seekerWavelengths params ["_seekerWavelengthMin", "_seekerWavelengthMax"];
private _seekerCos = cos _seekerFov;

private _spots = [];
private _finalPos = nil;
private _finalOwner = objNull;

{
    _x params ["_obj", "_owner", "_laserMethod", "_emitterWavelength", "_laserCode", "_divergence"];
    TRACE_6("laser",_obj,_owner,_laserMethod,_emitterWavelength,_laserCode,_divergence);

    if (alive _obj && {_emitterWavelength >= _seekerWavelengthMin} && {_emitterWavelength <= _seekerWavelengthMax} && {_laserCode == _seekerCode}) then {

        private _laser = [];
        // Find laser pos and dir of the laser depending on type
        if (IS_STRING(_laserMethod)) then {
            _laser = _x call (missionNamespace getVariable [_laserMethod, []]);
        } else {
            if (IS_CODE(_laserMethod)) then {
                _laser = _x call _laserMethod;
            } else {

                if (IS_ARRAY(_laserMethod)) then {
                    if (count _laserMethod == 2) then {
                        _laser = [AGLtoASL (_obj modelToWorldVisual (_laserMethod select 0)), _obj weaponDirection (_laserMethod select 1)];
                    } else {
                        if (count _laserMethod == 3) then {
                            _laser = [AGLtoASL (_obj modelToWorldVisual (_laserMethod select 0)), (AGLtoASL (_obj modelToWorldVisual (_laserMethod select 1))) vectorFromTo (AGLtoASL (_obj modelToWorldVisual (_laserMethod select 2)))];
                        };
                    };
                };
            };
        };

        TRACE_1("",_laser);
        //Handle Weird Data Return - skips over this laser in the for loop
        if ((_laser isEqualTo []) || {_laser isEqualTo [-1, -1]}) exitWith {WARNING_1("Bad Laser Return",_laser);};
        _laser params [["_laserPos", [], [[]], 3], ["_laserDir", [], [[]], 3]];

        if (GVAR(enableDispersion)) then {
            // Shoot a cone with dispersion
            private _res = [_laserPos, _laserDir, _divergence, 3, _ignoreObj1] call FUNC(shootCone);
            {
                _testPoint = _x select 0;
                _testPointVector = vectorNormalized (_testPoint vectorDiff _posASL);
                private _testDotProduct = _dir vectorDotProduct _testPointVector;
                if (_testDotProduct > _seekerCos) then {
                    _spots pushBack [_testPoint, _owner];
                };
            } forEach (_res select 2);
        } else {
            // Shoot a perfect ray from source to target
            ([_laserPos, _laserDir, _ignoreObj1] call FUNC(shootRay)) params ["_resultPos", "_distance"];
            TRACE_2("spot",_resultPos,_distance);
            if (_distance > 0) then {
                private _testPointVector = _posASL vectorFromTo _resultPos;
                private _testDotProduct = _dir vectorDotProduct _testPointVector;
                if (_testDotProduct > _seekerCos) then {
                    _spots pushBack [_resultPos, _owner];
                };
            };
        };
    };
} forEach (GVAR(laserEmitters) select 2); // Go through all values in hash

TRACE_2("",count _spots, _spots);

if ((count _spots) > 0) then {
    private _bucketList = nil;
    private _bucketPos = nil;
    private _c = 0;
    private _buckets = [];
    private _excludes = [];
    private _bucketIndex = 0;

    // Put close points together into buckets
    while { count(_spots) != count(_excludes) && _c < (count _spots) } do {
        scopeName "mainSearch";
        {
            if (!(_forEachIndex in _excludes)) then {
                private _index = _buckets pushBack [_x, [_x]];
                _excludes pushBack _forEachIndex;
                _bucketPos = _x select 0;
                _bucketList = (_buckets select _index) select 1;
                breakTo "mainSearch";
            };
        } forEach _spots;
        {
            if (!(_forEachIndex in _excludes)) then {
                private _testPos = (_x select 0);
                if ((_testPos vectorDistanceSqr _bucketPos) <= 100) then {
                    _bucketList pushBack _x;
                    _excludes pushBack _forEachIndex;
                };
            };
        } forEach _spots;
        _c = _c + 1;
    };

    TRACE_1("",_buckets);

    private _finalBuckets = [];
    private _largest = -1;
    private _largestIndex = 0;
    {
        // find bucket with largest number of points we can see
        private _index = _finalBuckets pushBack [];
        _bucketList = _finalBuckets select _index;
        {
            private _testPos = (_x select 0) vectorAdd [0,0,0.05];
            private _testIntersections = lineIntersectsSurfaces [_posASL, _testPos, _ignoreObj1];
            if ([] isEqualTo _testIntersections) then {
                _bucketList pushBack _x;
            };
        } forEach (_x select 1);
        if ((count _bucketList) > _largest) then {
            _largest = (count _bucketList);
            _largestIndex = _index;
        };
    } forEach _buckets;

    private _finalBucket = _finalBuckets select _largestIndex;
    private _ownersHash = [] call CBA_fnc_hashCreate;

    TRACE_2("",_finalBucket,_finalBuckets);

    if (count _finalBucket > 0) then {
        // merge all points in the best bucket into an average point and find effective owner
        _finalPos = [0,0,0];
        {
            _x params ["_xPos", "_owner"];
            _finalPos = _finalPos vectorAdd _xPos;
            if ([_ownersHash, _owner] call CBA_fnc_hashHasKey) then {
                private _count = [_ownersHash, _owner] call CBA_fnc_hashGet;
                [_ownersHash, _owner, _count + 1] call CBA_fnc_hashSet;
            } else {
                [_ownersHash, _owner, 1] call CBA_fnc_hashSet;
            };
        } forEach _finalBucket;

        _finalPos = _finalPos vectorMultiply (1 / (count _finalBucket));

        private _maxOwnerCount = -1;

        [_ownersHash, {
            if (_value > _maxOwnerCount) then {
                _finalOwner = _key;
            };
        }] call CBA_fnc_hashEachPair;
    };
};

TRACE_2("return",_finalPos,_finalOwner);
if (isNil "_finalPos") exitWith {[nil, _finalOwner]};
[_finalPos, _finalOwner];
