// This is an extension of a Unity built-in shader source.
//
// Everywhere except the regions noted by "Standard Plus Code" is under
// Copyright (c) 2016 Unity Technologies. MIT license (see license.txt).
//
// Standard Plus code by Paulo Cunha.

#ifndef STANDARD_PLUS_STANDARD_CORE_FORWARD_INCLUDED //Standard Plus Code
#define STANDARD_PLUS_STANDARD_CORE_FORWARD_INCLUDED //Standard Plus Code


#include "UnityStandardConfig.cginc"

#include "StandardPlusStandardCore.cginc" //Standard Plus Code

VertexOutputForwardBase vertBase (VertexInput v) { return vertForwardBase(v); }
VertexOutputForwardAdd vertAdd (VertexInput v) { return vertForwardAdd(v); }
half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseInternal(i); }
half4 fragAdd (VertexOutputForwardAdd i) : SV_Target { return fragForwardAddInternal(i); }


#endif 
