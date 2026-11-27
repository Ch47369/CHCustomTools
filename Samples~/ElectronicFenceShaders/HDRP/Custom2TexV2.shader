// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "CH/Paths/Custom2TexV2/HDRP"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.BlendMode)] _Src( "Src", Float ) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _Dst( "Dst", Float ) = 10
		[Enum(Off,0,On,1)] _ZWriteMode( "ZWriteMode", Float ) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode1( "CullMode", Float ) = 2
		[Header(MainTexSetting)] _MainTex( "MainTex", 2D ) = "white" {}
		[HDR] _MainTexColor( "MainTexColor", Color ) = ( 1, 1, 1, 1 )
		_MainTexIntensity( "MainTexIntensity", Float ) = 1
		_MainTexPanner( "MainTexPanner", Vector ) = ( 0, 0, 0, 0 )
		[Enum(R,0,A,1)] _RA( "R/A", Float ) = 1
		[Enum(OFF,0,Multiply,1,Add,2)] _TexBlendMode( "TexBlendMode", Float ) = 0
		_AddTex( "AddTex", 2D ) = "white" {}
		[HDR] _AddTexColor( "AddTexColor", Color ) = ( 1, 1, 1, 1 )
		_AddTexIntensity( "AddTexIntensity", Float ) = 1
		_AddTexPanner( "AddTexPanner", Vector ) = ( 0, 0, 0, 0 )
		[Enum(OFF,0,ON,1)] _DisturbanceONOFF( "DisturbanceON/OFF", Float ) = 0
		_DisturbanceTex( "DisturbanceTex", 2D ) = "white" {}
		_DisturbanceTexIntensity( "DisturbanceTexIntensity", Float ) = 0.1
		_DisturbancePanner( "DisturbancePanner", Vector ) = ( 0.1, 0.1, 0, 0 )
		[Header(DissolveSetting)] _DissolveMap( "DissolveMap", 2D ) = "white" {}
		[HDR] _EdgeColor( "EdgeColor", Color ) = ( 1, 1, 1, 1 )
		_EdgeWidth( "EdgeWidth", Range( 0, 1 ) ) = 0.1
		_Dissolve_Int( "Dissolve_Int", Range( 0, 1 ) ) = 0.4
		[Header(MaskTexSetting)] _MaskTex( "MaskTex", 2D ) = "white" {}
		_Mask_pow( "Mask_pow", Float ) = 1
		[Enum(Off,0,On,1)] _VertexColor( "VertexColor", Float ) = 1
		[Enum(Off,0,On,1)] _CustomDate1( "CustomDate", Float ) = 0
		[Enum(On,0,Off,1)] _DistanceOnOff( "DistanceOn/Off", Float ) = 1
		_DistanceMin( "DistanceMin", Float ) = 1
		_DistanceMax( "DistanceMax", Float ) = 2
		_DistanceA( "DistanceA", Vector ) = ( 0, 1, 0, 0 )
		[Enum(Off,0,Alpha,1,AlphaRGB,2)] _SoftParticleOnARGBA( "SoftParticleOn/A/RGBA", Float ) = 0
		_SoftParticleDistance( "SoftParticleDistance", Float ) = 0.2

		[HideInInspector] _RenderQueueType("Render Queue Type", Float) = 4
		[HideInInspector][ToggleUI] _AddPrecomputedVelocity("Add Precomputed Velocity", Float) = 1
		//[HideInInspector] _ShadowMatteFilter("Shadow Matte Filter", Float) = 2.006836
		[HideInInspector] _StencilRef("Stencil Ref", Int) = 0 // StencilUsage.Clear
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Int) = 3 // StencilUsage.RequiresDeferredLighting | StencilUsage.SubsurfaceScattering
		[HideInInspector] _StencilRefDepth("Stencil Ref Depth", Int) = 0 // Nothing
		[HideInInspector] _StencilWriteMaskDepth("Stencil Write Mask Depth", Int) = 8 // StencilUsage.TraceReflectionRay
		[HideInInspector] _StencilRefMV("Stencil Ref MV", Int) = 32 // StencilUsage.ObjectMotionVector
		[HideInInspector] _StencilWriteMaskMV("Stencil Write Mask MV", Int) = 32 // StencilUsage.ObjectMotionVector
		[HideInInspector] _StencilRefDistortionVec("Stencil Ref Distortion Vec", Int) = 2 // StencilUsage.DistortionVectors
		[HideInInspector] _StencilWriteMaskDistortionVec("Stencil Write Mask Distortion Vec", Int) = 2 // StencilUsage.DistortionVectors
		[HideInInspector] _StencilWriteMaskGBuffer("Stencil Write Mask GBuffer", Int) = 3 // StencilUsage.RequiresDeferredLighting | StencilUsage.SubsurfaceScattering
		[HideInInspector] _StencilRefGBuffer("Stencil Ref GBuffer", Int) = 2 // StencilUsage.RequiresDeferredLighting
		[HideInInspector] _ZTestGBuffer("ZTest GBuffer", Int) = 4
		[HideInInspector][ToggleUI] _RequireSplitLighting("Require Split Lighting", Float) = 0
		[HideInInspector][ToggleUI] _ReceivesSSR("Receives SSR", Float) = 1
		[HideInInspector] _SurfaceType("Surface Type", Float) = 1
		[HideInInspector] _BlendMode("Blend Mode", Float) = 0
		[HideInInspector] _SrcBlend("Src Blend", Float) = 1
		[HideInInspector] _DstBlend("Dst Blend", Float) = 0
		[HideInInspector] _AlphaSrcBlend("Alpha Src Blend", Float) = 1
		[HideInInspector] _AlphaDstBlend("Alpha Dst Blend", Float) = 0
		[HideInInspector][ToggleUI] _ZWrite("ZWrite", Float) = 0
		[HideInInspector][ToggleUI] _TransparentZWrite("Transparent ZWrite", Float) = 0
		[HideInInspector] _CullMode("Cull Mode", Float) = 2
		[HideInInspector] _TransparentSortPriority("Transparent Sort Priority", Float) = 0
		[HideInInspector][ToggleUI] _EnableFogOnTransparent("Enable Fog", Float) = 0
		[HideInInspector] _CullModeForward("Cull Mode Forward", Float) = 2 // This mode is dedicated to Forward to correctly handle backface then front face rendering thin transparent
		[HideInInspector][Enum(Back, 2, Front, 1)] _TransparentCullMode("_TransparentCullMode", Int) = 2// Back culling by default
		[HideInInspector] _ZTestDepthEqualForOpaque("ZTest Depth Equal For Opaque", Int) = 4 // Less equal
		[HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _ZTestTransparent("ZTest Transparent", Int) = 4// Less equal
		[HideInInspector][ToggleUI] _TransparentBackfaceEnable("Transparent Backface Enable", Float) = 0
		//[HideInInspector][ToggleUI] _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 1
		[HideInInspector][ToggleUI] _UseShadowThreshold("Use Shadow Threshold", Float) = 1
		[HideInInspector][ToggleUI] _DoubleSidedEnable("Double Sided Enable", Float) = 0
		[HideInInspector][Enum(Flip, 0, Mirror, 1, None, 2)] _DoubleSidedNormalMode("Double Sided Normal Mode", Float) = 1
		[HideInInspector] _DoubleSidedConstants("DoubleSidedConstants", Vector) = (1,1,-1,0)
		[HideInInspector] _DistortionEnable("_DistortionEnable",Float) = 0
		[HideInInspector] _DistortionOnly("_DistortionOnly",Float) = 0

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleUI] _TransparentWritingMotionVec("Transparent Writing MotionVec", Float) = 0
		[HideInInspector][Enum(Back, 2, Front, 1)] _OpaqueCullMode("_OpaqueCullMode", Int) = 2 // Back culling by default
		[HideInInspector][ToggleUI] _SupportDecals("Support Decals", Float) = 1
		[HideInInspector][ToggleUI] _ReceivesSSRTransparent("Receives SSR Transparent", Float) = 0
		[HideInInspector] _EmissionColor("Color", Color) = (1, 1, 1)
		[HideInInspector] _UnlitColorMap_MipInfo("_UnlitColorMap_MipInfo", Vector) = (0, 0, 0, 0)

		[HideInInspector][Enum(Auto, 0, On, 1, Off, 2)] _DoubleSidedGIMode("Double sided GI mode", Float) = 0
	}

	SubShader
	{
		PackageRequirements
		{
			"com.unity.render-pipelines.high-definition": "[14.0,15.0]"
		}

		

		

		Tags { "RenderPipeline"="HDRenderPipeline" "RenderType"="Opaque" "Queue"="Transparent" "ShaderGraphShader"="true" }

	LOD 0

		ZClip True

		HLSLINCLUDE
		#pragma target 4.5
		#pragma exclude_renderers glcore gles gles3 
		
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef GLOBAL_HEADER_INCLUDED
		#define GLOBAL_HEADER_INCLUDED

			#define ASE_ADJUST_CLIP_POSITION( x ) x

			#ifndef ASE_TESS_FUNCS
			#define ASE_TESS_FUNCS
			float4 FixedTess( float tessValue )
			{
				return tessValue;
			}

			float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
			{
				float3 wpos = mul(o2w,vertex).xyz;
				float dist = distance (wpos, cameraPos);
				float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
				return f;
			}

			float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
			{
				float4 tess;
				tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
				tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
				tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
				tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
				return tess;
			}

			float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
			{
				float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
				float len = distance(wpos0, wpos1);
				float f = max(len * scParams.y / (edgeLen * dist), 1.0);
				return f;
			}

			float DistanceFromPlaneASE (float3 pos, float4 plane)
			{
				return dot (float4(pos,1.0f), plane);
			}

			bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
			{
				float4 planeTest;
				planeTest.x = (( DistanceFromPlaneASE(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.y = (( DistanceFromPlaneASE(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.z = (( DistanceFromPlaneASE(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.w = (( DistanceFromPlaneASE(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							  (( DistanceFromPlaneASE(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
				return !all (planeTest);
			}

			float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
			{
				float3 f;
				f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
				f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
				f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

				return CalcTriEdgeTessFactors (f);
			}

			float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
			{
				float3 pos0 = mul(o2w,v0).xyz;
				float3 pos1 = mul(o2w,v1).xyz;
				float3 pos2 = mul(o2w,v2).xyz;
				float4 tess;
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
				return tess;
			}

			float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
			{
				float3 pos0 = mul(o2w,v0).xyz;
				float3 pos1 = mul(o2w,v1).xyz;
				float3 pos2 = mul(o2w,v2).xyz;
				float4 tess;

				if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
				{
					tess = 0.0f;
				}
				else
				{
					tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
					tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
					tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
					tess.w = (tess.x + tess.y + tess.z) / 3.0f;
				}
				return tess;
			}
			#endif //ASE_TESS_FUNCS

		#endif //GLOBAL_HEADER_INCLUDED
		ENDHLSL

		
		Pass
		{
			
			Name "Forward Unlit"
			Tags { "LightMode"="ForwardOnly" }

			Blend [_SrcBlend] [_DstBlend], [_AlphaSrcBlend] [_AlphaDstBlend]

			Cull [_CullModeForward]
			ZTest [_ZTestDepthEqualForOpaque]
			ZWrite [_ZWrite]

			ColorMask [_ColorMaskTransparentVel] 1

			Stencil
			{
				Ref [_StencilRef]
				WriteMask [_StencilWriteMask]
				Comp Always
				Pass Replace
			}


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma multi_compile _ DEBUG_DISPLAY
			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

	        #if defined(_TRANSPARENT_WRITES_MOTION_VEC) && defined(_SURFACE_TYPE_TRANSPARENT)
	        #define _WRITE_TRANSPARENT_MOTION_VECTOR
	        #endif

			#define SHADERPASS SHADERPASS_FORWARD_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#if defined(_ENABLE_SHADOW_MATTE) && SHADERPASS == SHADERPASS_FORWARD_UNLIT
				#define LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
				#define HAS_LIGHTLOOP
				#define SHADOW_OPTIMIZE_REGISTER_USAGE 1

				#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl"
				#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowContext.hlsl"
				#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/HDShadow.hlsl"
				#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
				#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/PunctualLightCommon.hlsl"
				#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/HDShadowLoop.hlsl"
			#endif

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				half4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_Position;
				float3 positionRWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float3 Color;
				float3 Emission;
				float4 ShadowTint;
				float Alpha;
				float AlphaClipThreshold;
				float AlphaClipThresholdShadow;
				float4 VTPackedFeedback;
			};

			void BuildSurfaceData(FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData)
			{
				ZERO_INITIALIZE(SurfaceData, surfaceData);
				surfaceData.color = surfaceDescription.Color;
			}

			void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription , FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#ifdef _ALPHATEST_ON
				DoAlphaTest ( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif

				BuildSurfaceData(fragInputs, surfaceDescription, V, surfaceData);

				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif

				#if defined(_ENABLE_SHADOW_MATTE) && SHADERPASS == SHADERPASS_FORWARD_UNLIT
					HDShadowContext shadowContext = InitShadowContext();
					float shadow;
					float3 shadow3;
					posInput = GetPositionInput(fragInputs.positionSS.xy, _ScreenSize.zw, fragInputs.positionSS.z, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
					float3 normalWS = normalize(fragInputs.tangentToWorld[1]);
					uint renderingLayers = _EnableLightLayers ? asuint(unity_RenderingLayer.x) : DEFAULT_LIGHT_LAYERS;
					ShadowLoopMin(shadowContext, posInput, normalWS, asuint(_ShadowMatteFilter), renderingLayers, shadow3);
					shadow = dot(shadow3, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));

					float4 shadowColor = (1 - shadow)*surfaceDescription.ShadowTint.rgba;
					float  localAlpha  = saturate(shadowColor.a + surfaceDescription.Alpha);

					#ifdef _SURFACE_TYPE_TRANSPARENT
						surfaceData.color = lerp(shadowColor.rgb*surfaceData.color, lerp(lerp(shadowColor.rgb, surfaceData.color, 1 - surfaceDescription.ShadowTint.a), surfaceData.color, shadow), surfaceDescription.Alpha);
					#else
						surfaceData.color = lerp(lerp(shadowColor.rgb, surfaceData.color, 1 - surfaceDescription.ShadowTint.a), surfaceData.color, shadow);
					#endif
					localAlpha = ApplyBlendMode(surfaceData.color, localAlpha).a;
					surfaceDescription.Alpha = localAlpha;
				#endif

				ZERO_INITIALIZE(BuiltinData, builtinData);
				builtinData.opacity = surfaceDescription.Alpha;

				#if defined(DEBUG_DISPLAY)
					builtinData.renderingLayers = GetMeshRenderingLightLayer();
				#endif

                #ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif

				builtinData.emissiveColor = surfaceDescription.Emission;

				#ifdef UNITY_VIRTUAL_TEXTURING
                builtinData.vtPackedFeedback = surfaceDescription.VTPackedFeedback;
                #endif

				#ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif

                ApplyDebugToBuiltinData(builtinData);
			}

			float GetDeExposureMultiplier()
			{
			#if defined(DISABLE_UNLIT_DEEXPOSURE)
				return 1.0;
			#else
				return _DeExposureMultiplier;
			#endif
			}

			PackedVaryingsMeshToPS VertexFunction( AttributesMesh inputMesh  )
			{
				PackedVaryingsMeshToPS o;
				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.ase_texcoord1.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord2 = inputMesh.ase_texcoord1;
				o.ase_color = inputMesh.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

				#ifdef ASE_CUSTOM_MOTION_VECTOR
				// Declared so the Velocity output port surfaces on the master node; only consumed by the motion vector pass.
				float3 aseCustomVelocity = float3( 0, 0, 0 );
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				o.positionCS = ASE_ADJUST_CLIP_POSITION( TransformWorldToHClip(positionRWS) );
				o.positionRWS = positionRWS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				half4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			#ifdef UNITY_VIRTUAL_TEXTURING
			#define VT_BUFFER_TARGET SV_Target1
			#define EXTRA_BUFFER_TARGET SV_Target2
			#else
			#define EXTRA_BUFFER_TARGET SV_Target1
			#endif

			void Frag( PackedVaryingsMeshToPS packedInput,
						out float4 outColor : SV_Target0
						#ifdef UNITY_VIRTUAL_TEXTURING
						,out float4 outVTFeedback : VT_BUFFER_TARGET
						#endif
						#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
						, out float outputDepth : DEPTH_OFFSET_SEMANTIC
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID( packedInput );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( packedInput );

				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;
				input.positionRWS = packedInput.positionRWS;

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.positionRWS;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.positionRWS );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.positionCS.z ) * packedInput.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half2 uv_DissolveMap = packedInput.ase_texcoord1.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord2;
				texCoord228.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half4 Dissolve_RGB137 = ( smoothstepResult93 * _EdgeColor );
				half3 appendResult155 = (half3(Dissolve_RGB137.rgb));
				half2 uv_MainTex = packedInput.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord1.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord2;
				texCoord73.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord1.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half3 appendResult156 = (half3(BlendColor111.rgb));
				half Dissolve_A126 = smoothstepResult93;
				half3 lerpResult102 = lerp( appendResult155 , appendResult156 , Dissolve_A126);
				half3 lerpResult89 = lerp( float3( 1,1,1 ) , (packedInput.ase_color).rgb , _VertexColor);
				half3 Vertex_RGB130 = lerpResult89;
				half3 RGB123 = ( lerpResult102 * Vertex_RGB130 );
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				half lerpResult264 = lerp( 1.0 , lerpResult259 , saturate( ( _SoftParticleOnARGBA - 1.0 ) ));
				
				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord1.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Color = ( RGB123 * lerpResult264 );
				surfaceDescription.Emission = 0;
				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				#ifdef _ALPHATEST_SHADOW_ON
				surfaceDescription.AlphaClipThresholdShadow = _AlphaCutoffShadow;
				surfaceDescription.AlphaClipThresholdShadow = _UseShadowThreshold ? surfaceDescription.AlphaClipThresholdShadow : surfaceDescription.AlphaClipThreshold;
				#endif

				surfaceDescription.ShadowTint = float4( 0, 0, 0, 1 );
				float2 Distortion = float2( 0, 0 );
				float DistortionBlur = 0;

				#if defined( ASE_WRITE_DEPTH )
				posInput.deviceDepth = posInput.deviceDepth;
				#endif

				#ifdef _DEPTHOFFSET_ON
				surfaceDescription.DepthOffset = 0;
				#endif

				surfaceDescription.VTPackedFeedback = float4(1.0f,1.0f,1.0f,1.0f);
				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription, input, V, posInput, surfaceData, builtinData);

				BSDFData bsdfData = ConvertSurfaceDataToBSDFData( input.positionSS.xy, surfaceData );

				#if defined(_ENABLE_SHADOW_MATTE)
				bsdfData.color *= GetScreenSpaceAmbientOcclusion(input.positionSS.xy);
				#endif


			#ifdef DEBUG_DISPLAY
				if (_DebugLightingMode >= DEBUGLIGHTINGMODE_DIFFUSE_LIGHTING && _DebugLightingMode <= DEBUGLIGHTINGMODE_EMISSIVE_LIGHTING)
				{
					if (_DebugLightingMode != DEBUGLIGHTINGMODE_EMISSIVE_LIGHTING)
					{
						builtinData.emissiveColor = 0.0;
					}
					else
					{
						bsdfData.color = 0.0;
					}
				}
			#endif

				float4 outResult = ApplyBlendMode(bsdfData.color * GetDeExposureMultiplier() + builtinData.emissiveColor * GetCurrentExposureMultiplier(), builtinData.opacity);
				outResult = EvaluateAtmosphericScattering(posInput, V, outResult);

				#ifdef DEBUG_DISPLAY
					int bufferSize = int(_DebugViewMaterialArray[0].x);
					for (int index = 1; index <= bufferSize; index++)
					{
						int indexMaterialProperty = int(_DebugViewMaterialArray[index].x);
						if (indexMaterialProperty != 0)
						{
							float3 result = float3(1.0, 0.0, 1.0);
							bool needLinearToSRGB = false;

							GetPropertiesDataDebug(indexMaterialProperty, result, needLinearToSRGB);
							GetVaryingsDataDebug(indexMaterialProperty, input, result, needLinearToSRGB);
							GetBuiltinDataDebug(indexMaterialProperty, builtinData, posInput, result, needLinearToSRGB);
							GetSurfaceDataDebug(indexMaterialProperty, surfaceData, result, needLinearToSRGB);
							GetBSDFDataDebug(indexMaterialProperty, bsdfData, result, needLinearToSRGB);

							if (!needLinearToSRGB)
								result = SRGBToLinear(max(0, result));

							outResult = float4(result, 1.0);
						}
					}

					if (_DebugFullScreenMode == FULLSCREENDEBUGMODE_TRANSPARENCY_OVERDRAW)
					{
						float4 result = _DebugTransparencyOverdrawWeight * float4(TRANSPARENCY_OVERDRAW_COST, TRANSPARENCY_OVERDRAW_COST, TRANSPARENCY_OVERDRAW_COST, TRANSPARENCY_OVERDRAW_A);
						outResult = result;
					}
				#endif

				outColor = outResult;

				#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
				outputDepth = posInput.deviceDepth;
				#endif

				#ifdef UNITY_VIRTUAL_TEXTURING
				outVTFeedback = builtinData.vtPackedFeedback;
				#endif
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			Cull [_CullMode]
			ZWrite On
			ZClip [_ZClip]
			ColorMask 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#if defined(_TRANSPARENT_WRITES_MOTION_VEC) && defined(_SURFACE_TYPE_TRANSPARENT)
			#define _WRITE_TRANSPARENT_MOTION_VECTOR
			#endif

			#define SHADERPASS SHADERPASS_SHADOWS
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_Position;
				float3 positionRWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
				float AlphaClipThresholdShadow;
			};

			void BuildSurfaceData(FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData)
			{
				ZERO_INITIALIZE(SurfaceData, surfaceData);
				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif
			}

			void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#if defined( _ALPHATEST_SHADOW_ON )
					DoAlphaTest( surfaceDescription.Alpha, surfaceDescription.AlphaClipThresholdShadow );
				#elif defined( _ALPHATEST_ON )
					DoAlphaTest( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif

				BuildSurfaceData(fragInputs, surfaceDescription, V, surfaceData);

				ZERO_INITIALIZE (BuiltinData, builtinData);
				builtinData.opacity = surfaceDescription.Alpha;

				#if defined(DEBUG_DISPLAY)
					builtinData.renderingLayers = GetMeshRenderingLightLayer();
				#endif

				#ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif

                #ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif

                ApplyDebugToBuiltinData(builtinData);
			}

			PackedVaryingsMeshToPS VertexFunction( AttributesMesh inputMesh  )
			{
				PackedVaryingsMeshToPS o;
				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.ase_color = inputMesh.ase_color;
				o.ase_texcoord1.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord2 = inputMesh.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

				#ifdef ASE_CUSTOM_MOTION_VECTOR
				// Declared so the Velocity output port surfaces on the master node; only consumed by the motion vector pass.
				float3 aseCustomVelocity = float3( 0, 0, 0 );
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				o.positionCS = ASE_ADJUST_CLIP_POSITION( TransformWorldToHClip(positionRWS) );
				o.positionRWS = positionRWS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			void Frag( PackedVaryingsMeshToPS packedInput
						#ifdef WRITE_MSAA_DEPTH
						, out float4 depthColor : SV_Target0
							#ifdef WRITE_NORMAL_BUFFER
							, out float4 outNormalBuffer : SV_Target1
							#endif
						#else
							#ifdef WRITE_NORMAL_BUFFER
							, out float4 outNormalBuffer : SV_Target0
							#endif
						#endif
						#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
						, out float outputDepth : DEPTH_OFFSET_SEMANTIC
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID( packedInput );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( packedInput );

				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;
				input.positionRWS = packedInput.positionRWS;

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.positionRWS;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.positionRWS );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.positionCS.z ) * packedInput.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = packedInput.ase_texcoord1.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord2;
				texCoord228.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = packedInput.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord1.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord2;
				texCoord73.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord1.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord1.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				#ifdef _ALPHATEST_SHADOW_ON
				surfaceDescription.AlphaClipThresholdShadow = _AlphaCutoffShadow;
				surfaceDescription.AlphaClipThresholdShadow = _UseShadowThreshold ? surfaceDescription.AlphaClipThresholdShadow : surfaceDescription.AlphaClipThreshold;
				#endif

				#if defined( ASE_WRITE_DEPTH )
				posInput.deviceDepth = posInput.deviceDepth;
				#endif

				#ifdef _DEPTHOFFSET_ON
				surfaceDescription.DepthOffset = 0;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription,input, V, posInput, surfaceData, builtinData);

				#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
				outputDepth = posInput.deviceDepth;
				float bias = max(abs(ddx(posInput.deviceDepth)), abs(ddy(posInput.deviceDepth))) * _SlopeScaleDepthBias;
				outputDepth += bias;
				#endif

				#ifdef WRITE_MSAA_DEPTH
					depthColor = packedInput.vmesh.positionCS.z;
					#ifdef _ALPHATOMASK_ON
					depthColor.a = SharpenAlpha(builtinData.opacity, builtinData.alphaClipTreshold);
					#endif
				#endif

				#if defined(WRITE_NORMAL_BUFFER)
				EncodeIntoNormalBuffer(ConvertSurfaceDataToNormalData(surfaceData), outNormalBuffer);
				#endif

				#if defined(WRITE_DECAL_BUFFER) && !defined(_DISABLE_DECALS)
					DecalPrepassData decalPrepassData;
					decalPrepassData.geomNormalWS = surfaceData.geomNormalWS;
					decalPrepassData.decalLayerMask = GetMeshRenderingDecalLayer();
					EncodeIntoDecalPrepassBuffer(decalPrepassData, outDecalBuffer);
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "META"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma shader_feature EDITOR_VISUALIZATION

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#if defined(_TRANSPARENT_WRITES_MOTION_VEC) && defined(_SURFACE_TYPE_TRANSPARENT)
			#define _WRITE_TRANSPARENT_MOTION_VECTOR
			#endif

			#define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_COLOR


			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 uv3 : TEXCOORD3;
				half4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				float4 positionCS : SV_Position;
				#ifdef EDITOR_VISUALIZATION
				float2 VizUV : TEXCOORD0;
				float4 LightCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float3 Color;
				float3 Emission;
				float Alpha;
				float AlphaClipThreshold;
			};

			void BuildSurfaceData( FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData )
			{
				ZERO_INITIALIZE( SurfaceData, surfaceData );
				surfaceData.color = surfaceDescription.Color;

				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif
			}

			void GetSurfaceAndBuiltinData( SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData )
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#ifdef _ALPHATEST_ON
				DoAlphaTest( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif

				BuildSurfaceData( fragInputs, surfaceDescription, V, surfaceData );
				ZERO_INITIALIZE( BuiltinData, builtinData );
				builtinData.opacity = surfaceDescription.Alpha;
				#if defined(DEBUG_DISPLAY)
					builtinData.renderingLayers = GetMeshRenderingLightLayer();
				#endif

				#ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif

				builtinData.emissiveColor = surfaceDescription.Emission;

				#ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif


                ApplyDebugToBuiltinData(builtinData);
			}

			#define SCENEPICKINGPASS
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/PickingSpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/MetaPass.hlsl"

			PackedVaryingsMeshToPS VertexFunction( AttributesMesh inputMesh  )
			{
				PackedVaryingsMeshToPS o;
				UNITY_SETUP_INSTANCE_ID( inputMesh );
				UNITY_TRANSFER_INSTANCE_ID( inputMesh, o );

				float4 ase_positionCS = TransformWorldToHClip( TransformObjectToWorld( ( inputMesh.positionOS ).xyz ) );
				float4 screenPos = ComputeScreenPos( ase_positionCS, _ProjectionParams.x );
				o.ase_texcoord4 = screenPos;
				
				float3 ase_positionWS = GetAbsolutePositionWS( TransformObjectToWorld( ( inputMesh.positionOS ).xyz ) );
				o.ase_texcoord5.xyz = ase_positionWS;
				
				o.ase_texcoord2.xy = inputMesh.uv0.xy;
				o.ase_texcoord3 = inputMesh.uv1;
				o.ase_color = inputMesh.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord5.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

			#ifdef EDITOR_VISUALIZATION
				float2 vizUV = 0;
				float4 lightCoord = 0;
				UnityEditorVizData(inputMesh.positionOS.xyz, inputMesh.uv0.xy, inputMesh.uv1.xy, inputMesh.uv2.xy, vizUV, lightCoord);
			#endif

				float2 uv = float2( 0.0, 0.0 );
				if( unity_MetaVertexControl.x )
				{
					uv = inputMesh.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				}
				else if( unity_MetaVertexControl.y )
				{
					uv = inputMesh.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				}

				#ifdef EDITOR_VISUALIZATION
					o.VizUV.xy = vizUV;
					o.LightCoord = lightCoord;
				#endif

				o.positionCS = float4( uv * 2.0 - 1.0, inputMesh.positionOS.z > 0 ? 1.0e-4 : 0.0, 1.0 );
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 uv3 : TEXCOORD3;
				half4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.uv0 = v.uv0;
				o.uv1 = v.uv1;
				o.uv2 = v.uv2;
				o.uv3 = v.uv3;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.uv0 = patch[0].uv0 * bary.x + patch[1].uv0 * bary.y + patch[2].uv0 * bary.z;
				o.uv1 = patch[0].uv1 * bary.x + patch[1].uv1 * bary.y + patch[2].uv1 * bary.z;
				o.uv2 = patch[0].uv2 * bary.x + patch[1].uv2 * bary.y + patch[2].uv2 * bary.z;
				o.uv3 = patch[0].uv3 * bary.x + patch[1].uv3 * bary.y + patch[2].uv3 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			float4 Frag( PackedVaryingsMeshToPS packedInput  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( packedInput );
				FragInputs input;
				ZERO_INITIALIZE( FragInputs, input );
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;

				PositionInputs posInput = GetPositionInput( input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS );

				float3 V = float3( 1.0, 1.0, 1.0 );

				half2 uv_DissolveMap = packedInput.ase_texcoord2.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord3;
				texCoord228.xy = packedInput.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half4 Dissolve_RGB137 = ( smoothstepResult93 * _EdgeColor );
				half3 appendResult155 = (half3(Dissolve_RGB137.rgb));
				half2 uv_MainTex = packedInput.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord2.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord3;
				texCoord73.xy = packedInput.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord2.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half3 appendResult156 = (half3(BlendColor111.rgb));
				half Dissolve_A126 = smoothstepResult93;
				half3 lerpResult102 = lerp( appendResult155 , appendResult156 , Dissolve_A126);
				half3 lerpResult89 = lerp( float3( 1,1,1 ) , (packedInput.ase_color).rgb , _VertexColor);
				half3 Vertex_RGB130 = lerpResult89;
				half3 RGB123 = ( lerpResult102 * Vertex_RGB130 );
				float4 screenPos = packedInput.ase_texcoord4;
				half4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ase_positionSSNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ase_positionSSNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				half lerpResult264 = lerp( 1.0 , lerpResult259 , saturate( ( _SoftParticleOnARGBA - 1.0 ) ));
				
				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord2.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = packedInput.ase_texcoord5.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Color = ( RGB123 * lerpResult264 );
				surfaceDescription.Emission = 0;
				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData( surfaceDescription,input, V, posInput, surfaceData, builtinData );

				BSDFData bsdfData = ConvertSurfaceDataToBSDFData( input.positionSS.xy, surfaceData );
				LightTransportData lightTransportData = GetLightTransportData( surfaceData, builtinData, bsdfData );

				float4 res = float4( 0.0, 0.0, 0.0, 1.0 );
				UnityMetaInput metaInput;
				metaInput.Albedo = lightTransportData.diffuseColor.rgb;
				metaInput.Emission = lightTransportData.emissiveColor;
			#ifdef EDITOR_VISUALIZATION
				metaInput.VizUV = packedInput.VizUV;
				metaInput.LightCoord = packedInput.LightCoord;
			#endif
				res = UnityMetaFragment(metaInput);

				return res;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma editor_sync_compilation

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#define SHADERPASS SHADERPASS_DEPTH_ONLY
			#define SCENESELECTIONPASS 1

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			int _ObjectId;
			int _PassValue;

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/PickingSpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_Position;
				float3 positionRWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			void BuildSurfaceData(FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData)
			{
				ZERO_INITIALIZE(SurfaceData, surfaceData);

				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif
			}

			void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#ifdef _ALPHATEST_ON
				DoAlphaTest ( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				BuildSurfaceData(fragInputs, surfaceDescription, V, surfaceData);
				ZERO_INITIALIZE(BuiltinData, builtinData);
				builtinData.opacity =  surfaceDescription.Alpha;

				#ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif

				#ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif


                ApplyDebugToBuiltinData(builtinData);
			}

			PackedVaryingsMeshToPS VertexFunction( AttributesMesh inputMesh  )
			{
				PackedVaryingsMeshToPS o;
				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.ase_color = inputMesh.ase_color;
				o.ase_texcoord1.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord2 = inputMesh.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue =  defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

				#ifdef ASE_CUSTOM_MOTION_VECTOR
				// Declared so the Velocity output port surfaces on the master node; only consumed by the motion vector pass.
				float3 aseCustomVelocity = float3( 0, 0, 0 );
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				o.positionCS = ASE_ADJUST_CLIP_POSITION( TransformWorldToHClip(positionRWS) );
				o.positionRWS = positionRWS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			void Frag( PackedVaryingsMeshToPS packedInput
						, out float4 outColor : SV_Target0
						#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
						, out float outputDepth : DEPTH_OFFSET_SEMANTIC
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID( packedInput );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( packedInput );
				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.positionRWS;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.positionRWS );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.positionCS.z ) * packedInput.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = packedInput.ase_texcoord1.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord2;
				texCoord228.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = packedInput.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord1.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord2;
				texCoord73.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord1.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord1.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
				posInput.deviceDepth = posInput.deviceDepth;
				#endif

				#ifdef _DEPTHOFFSET_ON
				surfaceDescription.DepthOffset = 0;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription, input, V, posInput, surfaceData, builtinData);

				#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
				outputDepth = posInput.deviceDepth;
				#endif

				outColor = float4( _ObjectId, _PassValue, 1.0, 1.0 );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthForwardOnly"
			Tags { "LightMode"="DepthForwardOnly" }

			Cull [_CullMode]
			ZWrite On
			Stencil
			{
				Ref [_StencilRefDepth]
				WriteMask [_StencilWriteMaskDepth]
				Comp Always
				Pass Replace
			}


			ColorMask 0 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma multi_compile _ WRITE_MSAA_DEPTH

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#define SHADERPASS SHADERPASS_DEPTH_ONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_Position;
				float3 positionRWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			void BuildSurfaceData(FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData)
			{
				ZERO_INITIALIZE(SurfaceData, surfaceData);
				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif
			}

			void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#ifdef _ALPHATEST_ON
				DoAlphaTest ( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif

				BuildSurfaceData(fragInputs, surfaceDescription, V, surfaceData);
				ZERO_INITIALIZE(BuiltinData, builtinData);
				builtinData.opacity =  surfaceDescription.Alpha;

				#if defined(DEBUG_DISPLAY)
					builtinData.renderingLayers = GetMeshRenderingLightLayer();
				#endif

                #ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif

				#ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif

                ApplyDebugToBuiltinData(builtinData);
			}

			PackedVaryingsMeshToPS VertexFunction( AttributesMesh inputMesh  )
			{
				PackedVaryingsMeshToPS o;
				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.ase_color = inputMesh.ase_color;
				o.ase_texcoord1.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord2 = inputMesh.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue =  defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

				#ifdef ASE_CUSTOM_MOTION_VECTOR
				// Declared so the Velocity output port surfaces on the master node; only consumed by the motion vector pass.
				float3 aseCustomVelocity = float3( 0, 0, 0 );
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				o.positionCS = ASE_ADJUST_CLIP_POSITION( TransformWorldToHClip(positionRWS) );
				o.positionRWS = positionRWS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			void Frag( PackedVaryingsMeshToPS packedInput
						#ifdef WRITE_MSAA_DEPTH
						, out float4 depthColor : SV_Target0
							#ifdef WRITE_NORMAL_BUFFER
							, out float4 outNormalBuffer : SV_Target1
							#endif
						#else
							#ifdef WRITE_NORMAL_BUFFER
							, out float4 outNormalBuffer : SV_Target0
							#endif
						#endif
						#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
						, out float outputDepth : DEPTH_OFFSET_SEMANTIC
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID( packedInput );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( packedInput );

				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;
				input.positionRWS = packedInput.positionRWS;

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.positionRWS;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.positionRWS );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.positionCS.z ) * packedInput.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = packedInput.ase_texcoord1.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord2;
				texCoord228.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = packedInput.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord1.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord2;
				texCoord73.xy = packedInput.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord1.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord1.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
				posInput.deviceDepth = posInput.deviceDepth;
				#endif

				#ifdef _DEPTHOFFSET_ON
				surfaceDescription.DepthOffset = 0;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription, input, V, posInput, surfaceData, builtinData);

				#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
				outputDepth = posInput.deviceDepth;
				#endif

				#ifdef WRITE_MSAA_DEPTH
					depthColor = packedInput.positionCS.z;
					#ifdef _ALPHATOMASK_ON
					depthColor.a = SharpenAlpha(builtinData.opacity, builtinData.alphaClipTreshold);
					#endif
				#endif

				#if defined(WRITE_NORMAL_BUFFER)
					EncodeIntoNormalBuffer(ConvertSurfaceDataToNormalData(surfaceData), outNormalBuffer);
				#endif
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "MotionVectors"
			Tags { "LightMode"="MotionVectors" }

			Cull [_CullMode]

			ZWrite On

			Stencil
			{
				Ref [_StencilRefMV]
				WriteMask [_StencilWriteMaskMV]
				Comp Always
				Pass Replace
			}


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT

			#pragma multi_compile _ WRITE_MSAA_DEPTH

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#if defined(_TRANSPARENT_WRITES_MOTION_VEC) && defined(_SURFACE_TYPE_TRANSPARENT)
			#define _WRITE_TRANSPARENT_MOTION_VECTOR
			#endif

			#define SHADERPASS SHADERPASS_MOTION_VECTORS

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
			float _TessPhongStrength;
			float _TessValue;
			float _TessMin;
			float _TessMax;
			float _TessEdgeLength;
			float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float3 previousPositionOS : TEXCOORD4;
				float3 precomputedVelocity : TEXCOORD5;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 vmeshPositionCS : SV_Position;
				float3 vmeshPositionRWS : TEXCOORD0;
				float4 vpassPositionCS : TEXCOORD1;
				float4 vpassPreviousPositionCS : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			void BuildSurfaceData(FragInputs fragInputs, SurfaceDescription surfaceDescription, float3 V, out SurfaceData surfaceData)
			{
				ZERO_INITIALIZE(SurfaceData, surfaceData);
				#ifdef WRITE_NORMAL_BUFFER
				surfaceData.normalWS = fragInputs.tangentToWorld[2];
				#endif
			}

			void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
			{
				#ifdef LOD_FADE_CROSSFADE
                LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

				#ifdef _ALPHATEST_ON
				DoAlphaTest ( surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif

				BuildSurfaceData(fragInputs, surfaceDescription, V, surfaceData);
				ZERO_INITIALIZE(BuiltinData, builtinData);
				builtinData.opacity =  surfaceDescription.Alpha;

				#if defined(DEBUG_DISPLAY)
                    builtinData.renderingLayers = GetMeshRenderingLightLayer();
                #endif


                #ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = surfaceDescription.AlphaClipThreshold;
                #endif


                #ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif

                ApplyDebugToBuiltinData(builtinData);
			}

			AttributesMesh ApplyMeshModification(AttributesMesh inputMesh, float3 timeParameters, inout PackedVaryingsMeshToPS o, out float3 customVelocity )
			{
				// @diogo: local copy shadows the global; DXC rejects writes to globals
				float4 _TimeParameters = float4( timeParameters, 0 );

				o.ase_color = inputMesh.ase_color;
				o.ase_texcoord3.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord4 = inputMesh.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif
				inputMesh.normalOS = inputMesh.normalOS;

				customVelocity = float3( 0, 0, 0 );

				return inputMesh;
			}

			PackedVaryingsMeshToPS VertexFunction(AttributesMesh inputMesh)
			{
				PackedVaryingsMeshToPS o = (PackedVaryingsMeshToPS)0;
				AttributesMesh defaultMesh = inputMesh;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 currentVelocity;
				inputMesh = ApplyMeshModification(inputMesh, _TimeParameters.xyz, o, currentVelocity);

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);

				float3 VMESHpositionRWS = positionRWS;
				float4 VMESHpositionCS = TransformWorldToHClip(positionRWS);

				float4 VPASSpreviousPositionCS;
				float4 VPASSpositionCS = mul(UNITY_MATRIX_UNJITTERED_VP, float4(VMESHpositionRWS, 1.0));

				bool forceNoMotion = unity_MotionVectorsParams.y == 0.0;
				if (forceNoMotion)
				{
					VPASSpreviousPositionCS = float4(0.0, 0.0, 0.0, 1.0);
				}
				else
				{
					bool hasDeformation = unity_MotionVectorsParams.x > 0.0;
					float3 effectivePositionOS = (hasDeformation ? inputMesh.previousPositionOS : defaultMesh.positionOS);

					#if defined(HAVE_MESH_MODIFICATION)
						AttributesMesh previousMesh = defaultMesh;
						previousMesh.positionOS = effectivePositionOS;
						PackedVaryingsMeshToPS test = (PackedVaryingsMeshToPS)0;
						float3 previousVelocity;
						previousMesh = ApplyMeshModification(previousMesh, _LastTimeParameters.xyz, test, previousVelocity);
						effectivePositionOS = previousMesh.positionOS;
					#endif

					#if defined(_ADD_PRECOMPUTED_VELOCITY)
						effectivePositionOS -= inputMesh.precomputedVelocity;
					#endif

					#if defined(ASE_CUSTOM_MOTION_VECTOR)
						effectivePositionOS -= currentVelocity;
					#endif

					float3 previousPositionRWS = TransformPreviousObjectToWorld( effectivePositionOS );

					#ifdef ATTRIBUTES_NEED_NORMAL
						float3 normalWS = TransformPreviousObjectToWorldNormal(defaultMesh.normalOS);
					#else
						float3 normalWS = float3(0.0, 0.0, 0.0);
					#endif

					#if defined(HAVE_VERTEX_MODIFICATION)
						ApplyVertexModification(inputMesh, normalWS, previousPositionRWS, _LastTimeParameters.xyz);
					#endif

					#ifdef _WRITE_TRANSPARENT_MOTION_VECTOR
						if (_TransparentCameraOnlyMotionVectors > 0)
						{
							previousPositionRWS = VMESHpositionRWS.xyz;
						}
					#endif

					VPASSpreviousPositionCS = mul(UNITY_MATRIX_PREV_VP, float4(previousPositionRWS, 1.0));
				}

				o.vmeshPositionCS = ASE_ADJUST_CLIP_POSITION( VMESHpositionCS );
				o.vmeshPositionRWS = VMESHpositionRWS;

				o.vpassPositionCS = ASE_ADJUST_CLIP_POSITION( VPASSpositionCS );
				o.vpassPreviousPositionCS = ASE_ADJUST_CLIP_POSITION( VPASSpreviousPositionCS );
				return o;
			}

			#if ( 0 ) // TEMPORARY: defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float3 previousPositionOS : TEXCOORD4;
				float3 precomputedVelocity : TEXCOORD5;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.previousPositionOS = v.previousPositionOS;
				#if defined (_ADD_PRECOMPUTED_VELOCITY)
					o.precomputedVelocity = v.precomputedVelocity;
				#endif
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.previousPositionOS = patch[0].previousPositionOS * bary.x + patch[1].previousPositionOS * bary.y + patch[2].previousPositionOS * bary.z;
				#if defined (_ADD_PRECOMPUTED_VELOCITY)
					o.precomputedVelocity = patch[0].precomputedVelocity * bary.x + patch[1].precomputedVelocity * bary.y + patch[2].precomputedVelocity * bary.z;
				#endif
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(WRITE_DECAL_BUFFER) && defined(WRITE_MSAA_DEPTH)
			#define SV_TARGET_NORMAL SV_Target3
			#elif defined(WRITE_DECAL_BUFFER) || defined(WRITE_MSAA_DEPTH)
			#define SV_TARGET_NORMAL SV_Target2
			#else
			#define SV_TARGET_NORMAL SV_Target1
			#endif

			void Frag( PackedVaryingsMeshToPS packedInput
						#ifdef WRITE_MSAA_DEPTH
						, out float4 depthColor : SV_Target0
						, out float4 outMotionVector : SV_Target1
							#ifdef WRITE_DECAL_BUFFER
							, out float4 outDecalBuffer : SV_Target2
							#endif
						#else
						, out float4 outMotionVector : SV_Target0
							#ifdef WRITE_DECAL_BUFFER
							, out float4 outDecalBuffer : SV_Target1
							#endif
						#endif

						#ifdef WRITE_NORMAL_BUFFER
						, out float4 outNormalBuffer : SV_TARGET_NORMAL
						#endif

						#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
						, out float outputDepth : DEPTH_OFFSET_SEMANTIC
						#endif
						 )
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( packedInput );
				UNITY_SETUP_INSTANCE_ID( packedInput );
				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.vmeshPositionCS;
				input.positionRWS = packedInput.vmeshPositionRWS.xyz;

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.vmeshPositionRWS.xyz;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.vmeshPositionRWS.xyz );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.vmeshPositionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.vmeshPositionCS.z ) * packedInput.vmeshPositionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = packedInput.ase_texcoord3.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord4;
				texCoord228.xy = packedInput.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = packedInput.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord3.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord4;
				texCoord73.xy = packedInput.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord3.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord3.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
				posInput.deviceDepth = posInput.deviceDepth;
				#endif

				#ifdef _DEPTHOFFSET_ON
				surfaceDescription.DepthOffset = 0;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription, input, V, posInput, surfaceData, builtinData);

				float4 VPASSpositionCS = float4(packedInput.vpassPositionCS.xy, 0.0, packedInput.vpassPositionCS.z);
				float4 VPASSpreviousPositionCS = float4(packedInput.vpassPreviousPositionCS.xy, 0.0, packedInput.vpassPreviousPositionCS.z);

				#ifdef _DEPTHOFFSET_ON
				VPASSpositionCS.w += builtinData.depthOffset;
				VPASSpreviousPositionCS.w += builtinData.depthOffset;
				#endif

				float2 motionVector = CalculateMotionVector( VPASSpositionCS, VPASSpreviousPositionCS );
				EncodeMotionVector( motionVector * 0.5, outMotionVector );

				bool forceNoMotion = unity_MotionVectorsParams.y == 0.0;
				if( forceNoMotion )
					outMotionVector = float4( 2.0, 0.0, 0.0, 0.0 );

				#ifdef WRITE_MSAA_DEPTH
					depthColor = packedInput.vmeshPositionCS.z;
					depthColor.a = SharpenAlpha(builtinData.opacity, builtinData.alphaClipTreshold);
				#endif

				#ifdef WRITE_NORMAL_BUFFER
					EncodeIntoNormalBuffer(ConvertSurfaceDataToNormalData(surfaceData), outNormalBuffer);
				#endif

				#if defined(WRITE_DECAL_BUFFER)
					DecalPrepassData decalPrepassData;
					#ifdef _DISABLE_DECALS
					ZERO_INITIALIZE(DecalPrepassData, decalPrepassData);
					#else
					decalPrepassData.geomNormalWS = surfaceData.geomNormalWS;
					decalPrepassData.decalLayerMask = GetMeshRenderingDecalLayer();
					#endif
					EncodeIntoDecalPrepassBuffer(decalPrepassData, outDecalBuffer);
					outDecalBuffer.w = (GetMeshRenderingLightLayer() & 0x000000FF) / 255.0;
				#endif

				#if defined(_DEPTHOFFSET_ON) || defined(ASE_WRITE_DEPTH)
				outputDepth = posInput.deviceDepth;
				#endif
			}

			ENDHLSL
		}

		
        Pass
		{
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

            Cull [_CullMode]

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008


			#pragma shader_feature _SURFACE_TYPE_TRANSPARENT
			#pragma shader_feature_local _TRANSPARENT_WRITES_MOTION_VEC

			#pragma editor_sync_compilation

			#pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex Vert
			#pragma fragment Frag

			#if defined(_TRANSPARENT_WRITES_MOTION_VEC) && defined(_SURFACE_TYPE_TRANSPARENT)
			#define _WRITE_TRANSPARENT_MOTION_VECTOR
			#endif

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_TANGENT_TO_WORLD

			#define SHADERPASS SHADERPASS_DEPTH_ONLY
			#define SCENEPICKINGPASS 1

			#define SHADER_UNLIT

			float4 _SelectionID;

            CBUFFER_START( UnityPerMaterial )
			half4 _MainTexColor;
			half4 _DisturbanceTex_ST;
			half4 _MainTex_ST;
			half4 _AddTex_ST;
			half4 _EdgeColor;
			half4 _AddTexColor;
			half4 _MaskTex_ST;
			half4 _DissolveMap_ST;
			half2 _DistanceA;
			half2 _DisturbancePanner;
			half2 _AddTexPanner;
			half2 _MainTexPanner;
			float _RA;
			float _SoftParticleOnARGBA;
			float _Mask_pow;
			float _DistanceMin;
			float _SoftParticleDistance;
			float _VertexColor;
			float _TexBlendMode;
			float _AddTexIntensity;
			float _Dst;
			float _DistanceMax;
			float _DisturbanceONOFF;
			float _DisturbanceTexIntensity;
			float _CustomDate1;
			float _Dissolve_Int;
			float _EdgeWidth;
			float _Src;
			float _CullMode1;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float4 _EmissionColor;
			float _RenderQueueType;
			#ifdef _ADD_PRECOMPUTED_VELOCITY
			float _AddPrecomputedVelocity;
			#endif
			#ifdef _ENABLE_SHADOW_MATTE
			float _ShadowMatteFilter;
			#endif
			float _StencilRef;
			float _StencilWriteMask;
			float _StencilRefDepth;
			float _StencilWriteMaskDepth;
			float _StencilRefMV;
			float _StencilWriteMaskMV;
			float _StencilRefDistortionVec;
			float _StencilWriteMaskDistortionVec;
			float _StencilWriteMaskGBuffer;
			float _StencilRefGBuffer;
			float _ZTestGBuffer;
			float _RequireSplitLighting;
			float _ReceivesSSR;
			float _SurfaceType;
			float _BlendMode;
			float _SrcBlend;
			float _DstBlend;
			float _AlphaSrcBlend;
			float _AlphaDstBlend;
			float _ZWrite;
			float _TransparentZWrite;
			float _CullMode;
			float _TransparentSortPriority;
			float _EnableFogOnTransparent;
			float _CullModeForward;
			float _TransparentCullMode;
			float _ZTestDepthEqualForOpaque;
			float _ZTestTransparent;
			float _TransparentBackfaceEnable;
			float _AlphaCutoffEnable;
			float _AlphaCutoff;
			float _AlphaCutoffShadow;
			float _UseShadowThreshold;
			float _DoubleSidedEnable;
			float _DoubleSidedNormalMode;
			float4 _DoubleSidedConstants;
			float _EnableBlendModePreserveSpecularLighting;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _DissolveMap;
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			sampler2D _AddTex;
			sampler2D _MaskTex;


            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/PickingSpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Unlit/Unlit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_RELATIVE_WORLD_POS
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsMeshToPS
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionRWS : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

            struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};


            void GetSurfaceAndBuiltinData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData RAY_TRACING_OPTIONAL_PARAMETERS)
            {
                #ifdef LOD_FADE_CROSSFADE
			        LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                #endif

                #ifdef _ALPHATEST_ON
                    float alphaCutoff = surfaceDescription.AlphaClipThreshold;
                    GENERIC_ALPHA_TEST(surfaceDescription.Alpha, alphaCutoff);
                #endif

                #if !defined(SHADER_STAGE_RAY_TRACING) && _DEPTHOFFSET_ON
                ApplyDepthOffsetPositionInput(V, surfaceDescription.DepthOffset, GetViewForwardDir(), GetWorldToHClipMatrix(), posInput);
                #endif


				ZERO_INITIALIZE(SurfaceData, surfaceData);

				ZERO_BUILTIN_INITIALIZE(builtinData);
				builtinData.opacity = surfaceDescription.Alpha;

				#if defined(DEBUG_DISPLAY)
					builtinData.renderingLayers = GetMeshRenderingLightLayer();
				#endif

                #ifdef _ALPHATEST_ON
                    builtinData.alphaClipTreshold = alphaCutoff;
                #endif

                #ifdef _DEPTHOFFSET_ON
                builtinData.depthOffset = surfaceDescription.DepthOffset;
                #endif


                ApplyDebugToBuiltinData(builtinData);

            }


			PackedVaryingsMeshToPS VertexFunction(AttributesMesh inputMesh  )
			{

				PackedVaryingsMeshToPS o;
				ZERO_INITIALIZE(PackedVaryingsMeshToPS, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, o );

				o.ase_color = inputMesh.ase_color;
				o.ase_texcoord3.xy = inputMesh.ase_texcoord.xy;
				o.ase_texcoord4 = inputMesh.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue =  defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				inputMesh.normalOS = inputMesh.normalOS;

				#ifdef ASE_CUSTOM_MOTION_VECTOR
				// Declared so the Velocity output port surfaces on the master node; only consumed by the motion vector pass.
				float3 aseCustomVelocity = float3( 0, 0, 0 );
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				o.positionCS = ASE_ADJUST_CLIP_POSITION( TransformWorldToHClip(positionRWS) );
				o.positionRWS = positionRWS;
				o.normalWS.xyz =  normalWS;
				o.tangentWS.xyzw =  tangentWS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float3 positionOS : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl Vert ( AttributesMesh v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.positionOS = v.positionOS;
				o.normalOS = v.normalOS;
				o.tangentOS = v.tangentOS;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
				float3 cameraPos = 0;
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), cameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, GetObjectToWorldMatrix(), cameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(float4(v[0].positionOS,1), float4(v[1].positionOS,1), float4(v[2].positionOS,1), edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), cameraPos, _ScreenParams, _FrustumPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			PackedVaryingsMeshToPS DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				AttributesMesh o = (AttributesMesh) 0;
				o.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			PackedVaryingsMeshToPS Vert ( AttributesMesh v )
			{
				return VertexFunction( v );
			}
			#endif

			void Frag(	PackedVaryingsMeshToPS packedInput
						, out float4 outColor : SV_Target0
						
					)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

				FragInputs input;
				ZERO_INITIALIZE(FragInputs, input);
				input.tangentToWorld = k_identity3x3;
				input.positionSS = packedInput.positionCS;

				input.tangentToWorld = BuildTangentToWorld(packedInput.tangentWS.xyzw, packedInput.normalWS.xyz);

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

				float3 PositionRWS = packedInput.positionRWS;
				float3 V = GetWorldSpaceNormalizeViewDir( packedInput.positionRWS );
				float4 ScreenPosNorm = float4( posInput.positionNDC, packedInput.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, packedInput.positionCS.z ) * packedInput.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos, _ProjectionParams.x );

				half lerpResult92 = lerp( 1.0 , (packedInput.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = packedInput.ase_texcoord3.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = packedInput.ase_texcoord4;
				texCoord228.xy = packedInput.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = packedInput.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = packedInput.ase_texcoord3.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = packedInput.ase_texcoord4;
				texCoord73.xy = packedInput.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = packedInput.ase_texcoord3.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = packedInput.ase_texcoord3.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = GetAbsolutePositionWS( PositionRWS );
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SampleCameraDepth( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.Alpha = ( A135 * lerpResult259 );

				#ifdef _ALPHATEST_ON
				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
				#endif

				SurfaceData surfaceData;
				BuiltinData builtinData;
				GetSurfaceAndBuiltinData(surfaceDescription, input, V, posInput, surfaceData, builtinData);
				outColor = unity_SelectionID;
			}

            ENDHLSL
        }

		Pass
		{
			Name "FullScreenDebug"
			Tags
			{
				"LightMode" = "FullScreenDebug"
			}

			Cull [_CullMode]
			ZTest LEqual
			ZWrite Off

			HLSLPROGRAM

			/*ase_pragma_before*/

			#pragma vertex Vert
			#pragma fragment Frag

			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"

			#define SHADERPASS SHADERPASS_FULL_SCREEN_DEBUG

			struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				#if UNITY_ANY_INSTANCING_ENABLED
					uint instanceID : INSTANCEID_SEMANTIC;
				#endif
			};

			struct VaryingsMeshToPS
			{
				SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				#if UNITY_ANY_INSTANCING_ENABLED
					uint instanceID : CUSTOM_INSTANCE_ID;
				#endif
			};

			struct PackedVaryingsMeshToPS
			{
				SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				#if UNITY_ANY_INSTANCING_ENABLED
					uint instanceID : CUSTOM_INSTANCE_ID;
				#endif
			};

			VaryingsMeshToPS UnpackVaryingsMeshToPS (PackedVaryingsMeshToPS input)
			{
				VaryingsMeshToPS output;
				output.positionCS = input.positionCS;
				#if UNITY_ANY_INSTANCING_ENABLED
				output.instanceID = input.instanceID;
				#endif
				return output;
			}

			PackedVaryingsMeshToPS PackVaryingsMeshToPS (VaryingsMeshToPS input)
			{
				PackedVaryingsMeshToPS output;
				ZERO_INITIALIZE(PackedVaryingsMeshToPS, output);
				output.positionCS = input.positionCS;
				#if UNITY_ANY_INSTANCING_ENABLED
				output.instanceID = input.instanceID;
				#endif
				return output;
			}

			FragInputs BuildFragInputs(VaryingsMeshToPS input)
			{
				FragInputs output;
				ZERO_INITIALIZE(FragInputs, output);

				output.tangentToWorld = k_identity3x3;
				output.positionSS = input.positionCS;

				return output;
			}

			FragInputs UnpackVaryingsMeshToFragInputs(PackedVaryingsMeshToPS input)
			{
				UNITY_SETUP_INSTANCE_ID(input);
				VaryingsMeshToPS unpacked = UnpackVaryingsMeshToPS(input);
				return BuildFragInputs(unpacked);
			}

			#define DEBUG_DISPLAY
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/FullScreenDebug.hlsl"

			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/VertMesh.hlsl"

			PackedVaryingsType Vert(AttributesMesh inputMesh)
			{
				VaryingsType varyingsType;
				varyingsType.vmesh = VertMesh(inputMesh);
				return PackVaryingsType(varyingsType);
			}

			#if !defined(_DEPTHOFFSET_ON)
			[earlydepthstencil] // quad overshading debug mode writes to UAV
			#endif
			void Frag(PackedVaryingsToPS packedInput)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				FragInputs input = UnpackVaryingsToFragInputs(packedInput);

				PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz);

			#ifdef PLATFORM_SUPPORTS_PRIMITIVE_ID_IN_PIXEL_SHADER
				if (_DebugFullScreenMode == FULLSCREENDEBUGMODE_QUAD_OVERDRAW)
				{
					IncrementQuadOverdrawCounter(posInput.positionSS.xy, input.primitiveID);
				}
			#endif
			}

			ENDHLSL
		}
		
	}
	

	

	CustomEditor "Rendering.HighDefinition.HDUnlitGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":21,"pos":[-2234.045,-611.3629],"params":["Inherit","False","0","16","2","_DisturbanceTex","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector2Node, AmplifyShaderEditor","id":20,"pos":[-2201.744,-488.7779],"params":["Inherit","False","Property","_DisturbancePanner","DisturbancePanner","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1,0.1","0.1,0.1","0","3","FLOAT2","0","FLOAT","1","FLOAT","2"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":19,"pos":[-2018.776,-607.902],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":16,"pos":[-1848.706,-638.1874],"params":["Inherit","True","Property","_DisturbanceTex","DisturbanceTex","15","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":26,"pos":[-1801.797,-447.8372],"params":["Float","False","Property","_DisturbanceTexIntensity","DisturbanceTexIntensity","16","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0.1","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":25,"pos":[-1567.323,-608.0613],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":73,"pos":[-1487.729,-409.8255],"params":["Inherit","False","1","-1","4","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":11,"pos":[-1779.941,-373.1227],"params":["Inherit","False","0","14","2","_MainTex","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":24,"pos":[-1439.231,-607.8708],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":75,"pos":[-1283.769,-389.6625],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":38,"pos":[-2243.972,-21.12315],"params":["Inherit","False","0","30","2","_AddTex","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector2Node, AmplifyShaderEditor","id":40,"pos":[-2231.241,106.72],"params":["Inherit","False","Property","_AddTexPanner","AddTexPanner","13","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0","0,0","0","3","FLOAT2","0","FLOAT","1","FLOAT","2"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":81,"pos":[-1487.539,-487.977],"params":["Float","False","Property","_DisturbanceONOFF","DisturbanceON/OFF","14","1","[Enum]","Create","True","1","DisturbanceSetting","2","OFF","0","ON","1","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":72,"pos":[-1129.465,-570.6064],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":208,"pos":[-1191.003,-478.057],"params":["Inherit","False","206","CustomDate","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":80,"pos":[-1322.967,-628.9768],"params":["Inherit","False","3","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":39,"pos":[-2028.045,-16.77575],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,-0.8","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":200,"pos":[-997.6666,-629.8391],"params":["Inherit","False","3","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector2Node, AmplifyShaderEditor","id":10,"pos":[-1014.581,-507.1123],"params":["Inherit","False","Property","_MainTexPanner","MainTexPanner","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0","0,-0.1","0","3","FLOAT2","0","FLOAT","1","FLOAT","2"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":30,"pos":[-1862.05,-45.25405],"params":["Inherit","True","Property","_AddTex","AddTex","10","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":33,"pos":[-1746.432,150.0709],"params":["Float","False","Property","_AddTexIntensity","AddTexIntensity","12","0","Create","True","0","0","0","False","0","False","Object","-1","","1","1","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":32,"pos":[-1954.169,140.2867],"params":["Inherit","False","Property","_AddTexColor","AddTexColor","11","1","[HDR]","Create","True","0","0","0","False","0","False","Object","-1","","1,1,1,1","1,1,1,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":12,"pos":[-844.4874,-631.2227],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,-0.8","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[-1526.974,-39.09985],"params":["Inherit","False","3","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":4,"pos":[-830.1807,-436.4082],"params":["Inherit","False","Property","_MainTexColor","MainTexColor","5","1","[HDR]","Create","True","0","0","0","False","0","False","Object","-1","","1,1,1,1","27.4717,13.74359,3.498754,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":3,"pos":[-824.7806,-266.4077],"params":["Float","False","Property","_MainTexIntensity","MainTexIntensity","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","2","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":108,"pos":[-1541.505,121.3483],"params":["Inherit","False","AddTexColor","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":14,"pos":[-681.5253,-630.2943],"params":["Inherit","True","Property","_MainTex","MainTex","4","1","[Header]","Create","True","1","MainTexSetting","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":205,"pos":[-2273.757,679.4006],"params":["Float","False","Property","_CustomDate1","CustomDate","25","1","[Enum]","Create","True","0","2","Off","0","On","1","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":2,"pos":[-403.4976,-625.9534],"params":["Inherit","True","3","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":107,"pos":[-1148.297,114.9026],"params":["Inherit","False","103","MainTexColor","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":109,"pos":[-1148.389,10.33196],"params":["Inherit","False","108","AddTexColor","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":206,"pos":[-2116.471,679.1877],"params":["Inherit","False","CustomDate","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":84,"pos":[-1100.432,215.7783],"params":["Float","False","Property","_TexBlendMode","TexBlendMode","9","1","[Enum]","Create","True","1","AddTexSetting","3","OFF","0","Multiply","1","Add","2","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":41,"pos":[-939.6138,-23.52114],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":82,"pos":[-929.8242,65.49641],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":166,"pos":[-929.287,154.7844],"params":["Inherit","False","2","0","FLOAT","1.9","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":99,"pos":[-1573.772,590.2064],"params":["Float","False","Property","_Dissolve_Int","Dissolve_Int","21","0","Create","False","0","0","0","False","0","False","Object","-1","","0.4","0.481","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":228,"pos":[-1560.357,660.9965],"params":["Inherit","False","1","-1","4","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":207,"pos":[-1530.224,819.2168],"params":["Inherit","False","206","CustomDate","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor","id":229,"pos":[-1455.3,1131.985],"params":["Inherit","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.WorldSpaceCameraPos, AmplifyShaderEditor","id":231,"pos":[-1525.842,1289.022],"params":["Inherit","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":103,"pos":[-394.2125,-415.2394],"params":["Inherit","False","MainTexColor","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":105,"pos":[-766.9335,-55.85355],"params":["Inherit","False","103","MainTexColor","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":172,"pos":[-745.4984,167.6618],"params":["Inherit","False","2","0","FLOAT","0.9","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":85,"pos":[-782.1671,19.12577],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":183,"pos":[-1351.464,657.5402],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DistanceOpNode, AmplifyShaderEditor","id":230,"pos":[-1165.842,1130.022],"params":["Inherit","False","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":234,"pos":[-1182.842,1264.022],"params":["Float","False","Property","_DistanceMin","DistanceMin","27","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":235,"pos":[-1186.842,1342.022],"params":["Float","False","Property","_DistanceMax","DistanceMax","28","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":78,"pos":[-577.9488,-53.38575],"params":["Inherit","True","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":94,"pos":[-1284.277,484.3553],"params":["Inherit","False","Constant","_Float0","Float 0","1","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":98,"pos":[-1568.625,402.152],"params":["Inherit","True","Property","_DissolveMap","DissolveMap","18","1","[Header]","Create","True","1","DissolveSetting","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":97,"pos":[-1257.397,561.1992],"params":["Inherit","False","2","2","0","FLOAT","-2","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.VertexColorNode, AmplifyShaderEditor","id":87,"pos":[-2269.634,438.0841],"params":["Inherit","False","0","5","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":233,"pos":[-904.8414,1130.022],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":237,"pos":[-651.8411,1262.022],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":95,"pos":[-1106.781,429.4819],"params":["Inherit","True","3","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":91,"pos":[-2092.322,574.8478],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":96,"pos":[-1121.615,644.0757],"params":["Float","False","Property","_EdgeWidth","EdgeWidth","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0.163","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":236,"pos":[-652.8411,1130.022],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":111,"pos":[-405.4064,197.3127],"params":["Inherit","False","BlendColor","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":86,"pos":[-2114.714,504.3217],"params":["Float","False","Property","_VertexColor","VertexColor","24","1","[Enum]","Create","True","1","OtherSetting","2","Off","0","On","1","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":269,"pos":[-490,1420],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0.0001","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":113,"pos":[-40,-64],"params":["Inherit","False","111","BlendColor","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":52,"pos":[-24,192],"params":["Inherit","True","Property","_MaskTex","MaskTex","22","1","[Header]","Create","True","1","MaskTexSetting","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":93,"pos":[-880.4689,427.9764],"params":["Inherit","True","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":92,"pos":[-1963.322,539.8478],"params":["Inherit","False","3","0","FLOAT","1","False","1","FLOAT","1","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector2Node, AmplifyShaderEditor","id":240,"pos":[-653.8411,1001.022],"params":["Inherit","False","Property","_DistanceA","DistanceA","29","0","Create","True","0","0","0","False","0","False","Object","-1","","0,1","0,1","0","3","FLOAT2","0","FLOAT","1","FLOAT","2"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":242,"pos":[-492.8413,1180.022],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":54,"pos":[120,376],"params":["Float","False","Property","_Mask_pow","Mask_pow","23","0","Create","True","0","0","0","False","0","False","Object","-1","","1","1","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":126,"pos":[-591.1672,647.6727],"params":["Inherit","False","Dissolve_A","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.BreakToComponentsNode, AmplifyShaderEditor","id":116,"pos":[128,-64],"params":["Inherit","False","COLOR","1","0","COLOR","0,0,0,0","False","16","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT","5","FLOAT","6","FLOAT","7","FLOAT","8","FLOAT","9","FLOAT","10","FLOAT","11","FLOAT","12","FLOAT","13","FLOAT","14","FLOAT","15"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":77,"pos":[128,80],"params":["Float","False","Property","_RA","R/A","8","1","[Enum]","Create","True","0","2","R","0","A","1","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":241,"pos":[-399.8413,1004.022],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":131,"pos":[-1823.895,538.49],"params":["Inherit","False","Vertex_A","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":254,"pos":[185,325],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0.001","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":253,"pos":[200,192],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":76,"pos":[256,-64],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":128,"pos":[240,-184],"params":["Inherit","False","126","Dissolve_A","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":132,"pos":[248,-256],"params":["Inherit","False","131","Vertex_A","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":244,"pos":[-413.0393,1291.238],"params":["Inherit","False","DistanceFade","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":53,"pos":[256,224],"params":["Inherit","False","True","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":56,"pos":[480,-136],"params":["Inherit","False","4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":246,"pos":[440,96],"params":["Inherit","False","244","DistanceFade","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":250,"pos":[488,8],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":249,"pos":[440,176],"params":["Float","False","Property","_DistanceOnOff","DistanceOn/Off","26","1","[Enum]","Create","True","0","2","On","0","Off","1","0","False","0","False","Object","-1","","1","1","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":256,"pos":[1016,240],"params":["Float","False","Property","_SoftParticleDistance","SoftParticleDistance","31","0","Create","True","0","0","0","False","0","False","Object","-1","","0.2","0.2","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":248,"pos":[680,-136],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":257,"pos":[1320,240],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0.0001","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":255,"pos":[1016,32],"params":["Float","False","Property","_SoftParticleOnARGBA","SoftParticleOn/A/RGBA","30","1","[Enum]","Create","True","0","3","Off","0","Alpha","1","AlphaRGB","2","0","False","0","False","Object","-1","","0","1","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":135,"pos":[648,-8],"params":["Inherit","False","A","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DepthFade, AmplifyShaderEditor","id":258,"pos":[1520,216],"params":["Inherit","False","True","True","False","2","1","FLOAT3","0,0,0","False","0","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":268,"pos":[1288,32],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":259,"pos":[1808,176],"params":["Inherit","False","3","0","FLOAT","1","False","1","FLOAT","1","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":140,"pos":[1984,256],"params":["Inherit","False","135","A","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":47,"pos":[2584,-256],"params":["Float","False","Property","_Dst","Dst","1","1","[Enum]","Create","True","0","0","1","UnityEngine.Rendering.BlendMode","True","0","False","Object","-1","","10","10","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":51,"pos":[2584,-112],"params":["Float","False","Property","_ZWriteMode","ZWriteMode","2","1","[Enum]","Create","True","0","2","Off","0","On","1","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":102,"pos":[221.8935,-629.9199],"params":["Inherit","True","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":139,"pos":[469.8126,-550.9344],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":155,"pos":[64.62321,-634.464],"params":["Inherit","False","FLOAT3","4","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":156,"pos":[60.24849,-564.9916],"params":["Inherit","False","FLOAT3","4","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":136,"pos":[16.54236,-457.8521],"params":["Inherit","False","126","Dissolve_A","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":138,"pos":[-126.2164,-634.992],"params":["Inherit","False","137","Dissolve_RGB","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":124,"pos":[-121.9374,-559.236],"params":["Inherit","False","111","BlendColor","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":101,"pos":[-598.7792,429.3979],"params":["Inherit","True","2","2","0","FLOAT","0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":137,"pos":[-402.153,425.1673],"params":["Inherit","False","Dissolve_RGB","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":100,"pos":[-838.0477,637.8046],"params":["Inherit","False","Property","_EdgeColor","EdgeColor","19","1","[HDR]","Create","True","0","0","0","False","0","False","Object","-1","","1,1,1,1","23.96863,8.156863,4.015687,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":90,"pos":[-2105.946,433.7449],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":89,"pos":[-1964.946,414.7449],"params":["Inherit","False","3","0","FLOAT3","1,1,1","False","1","FLOAT3","1,1,1","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":48,"pos":[2584,-184],"params":["Float","False","Property","_CullMode1","CullMode","3","1","[Enum]","Create","True","0","0","1","UnityEngine.Rendering.CullMode","True","0","False","Object","-1","","2","2","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":133,"pos":[278.8804,-419.6709],"params":["Inherit","False","130","Vertex_RGB","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":130,"pos":[-1822.994,410.2901],"params":["Inherit","False","Vertex_RGB","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":265,"pos":[2296,320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":123,"pos":[560,-600],"params":["Inherit","False","RGB","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":46,"pos":[2584,-328],"params":["Float","False","Property","_Src","Src","0","1","[Enum]","Create","True","1","BaseSetting","0","1","UnityEngine.Rendering.BlendMode","True","0","False","Object","-1","","5","5","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":261,"pos":[1288,488],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":260,"pos":[2296,32],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":263,"pos":[1808,488],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":264,"pos":[2008,352],"params":["Inherit","False","3","0","FLOAT","1","False","1","FLOAT","1","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":125,"pos":[1776,32],"params":["Inherit","False","123","RGB","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":270,"pos":[2568,-8],"params":["Float","False","True","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","16","CH/Paths/Custom2TexV2/HDRP","7f5cb9c3ea6481f469fdd856555439ef","True","Forward Unlit","0","0","Forward Unlit","13","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Transparent=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","True","1","0","True","_SrcBlend","0","True","_DstBlend","1","0","True","_AlphaSrcBlend","0","True","_AlphaDstBlend","False","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullModeForward","False","False","False","True","True","True","True","True","0","True","_ColorMaskTransparentVel","False","False","False","False","False","True","True","0","True","_StencilRef","255","False","","255","True","_StencilWriteMask","7","False","","3","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","0","True","_ZWrite","True","0","True","_ZTestDepthEqualForOpaque","False","False","True","1","LightMode=ForwardOnly","False","False","0","Hidden/InternalErrorShader","0","0","Standard","36","Surface Type","1","0","  Rendering Pass ","0","0","  Rendering Pass","1","0","  Blending Mode","0","0","  Receive Fog","0","0","  Distortion","0","0","    Distortion Mode","0","0","    Distortion Depth Test","1","0","    Distortion Only","0","0","  Depth Write","0","0","  Cull Mode","0","0","  Depth Test","4","0","Double-Sided","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Receive Decals","1","0","Motion Vectors","1","0","  Add Precomputed Velocity","0","0","  Add Custom Velocity","0","0","Shadow Matte","0","0","Cast Shadows","1","0","Write Depth","0","0","  Depth Offset","0","0","  Conservative","0","0","GPU Instancing","1","0","Tessellation","0","0","  Phong","0","0","  Strength","0.5,False,","0","  Type","0","0","  Tess","16,False,","0","  Min","10,False,","0","  Max","25,False,","0","  Edge Length","16,False,","0","  Max Displacement","25,False,","0","Vertex Position","1","0","LOD CrossFade","0","0","0","8","True","True","True","True","True","True","False","True","False","","False","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":271,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","ShadowCaster","0","1","ShadowCaster","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullMode","False","True","False","False","False","False","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","False","False","True","0","True","_ZClip","True","1","LightMode=ShadowCaster","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":272,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","META","0","2","META","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Meta","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":273,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","SceneSelectionPass","0","3","SceneSelectionPass","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=SceneSelectionPass","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":274,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","DepthForwardOnly","0","4","DepthForwardOnly","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullMode","False","True","False","False","False","False","0","False","","False","False","False","False","False","False","False","True","True","0","True","_StencilRefDepth","255","False","","255","True","_StencilWriteMaskDepth","7","False","","3","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","False","True","1","LightMode=DepthForwardOnly","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":275,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","MotionVectors","0","5","MotionVectors","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullMode","False","False","False","False","False","False","False","False","False","True","True","0","True","_StencilRefMV","255","False","","255","True","_StencilWriteMaskMV","7","False","","3","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","False","True","1","LightMode=MotionVectors","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":276,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","DistortionVectors","0","6","DistortionVectors","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","True","4","1","False","","1","False","","4","1","False","","1","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullMode","False","False","False","False","False","False","False","False","False","True","True","0","True","_StencilRefDistortionVec","255","False","","255","True","_StencilWriteMaskDistortionVec","7","False","","3","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","3","False","","False","False","True","1","LightMode=DistortionVectors","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":277,"pos":[2568,-8],"params":["Float","False","False","-1","3","Rendering.HighDefinition.HDUnlitGUI","0","1","New Amplify Shader","7f5cb9c3ea6481f469fdd856555439ef","True","ScenePickingPass","0","7","ScenePickingPass","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","4","RenderPipeline=HDRenderPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","ShaderGraphShader=true","True","5","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","True","_CullMode","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","True","3","False","","False","False","True","1","LightMode=Picking","False","False","0","Hidden/InternalErrorShader","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":106,"pos":[-2284.045,-675.863],"params":["Inherit","False","2074.093","500.0021","Comment","22","103","2","14","3","4","10","11","80","12","208","200","72","75","73","81","24","26","25","16","20","21","19","MainTexColor","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":110,"pos":[-2293.973,-95.25394],"params":["Inherit","False","930.3301","411.6418","Comment","8","108","33","32","30","40","38","31","39","AddTexColor","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":134,"pos":[-1152.963,-96.30942],"params":["Inherit","False","937.5887","385.3676","Comment","11","84","78","82","85","107","109","105","41","166","172","111","MainAddBlend","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":243,"pos":[-1575.842,951.0217],"params":["Inherit","False","1360","620","DistanceFade","13","229","231","230","233","234","235","236","237","240","242","241","244","269","DistanceFade","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":127,"pos":[-1581.321,362.7028],"params":["Inherit","False","1366.397","528.9531","Comment","14","207","228","183","99","97","98","96","126","93","100","94","101","95","137","Dissolve","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":122,"pos":[-2279.634,377.7454],"params":["Inherit","False","648.1094","277.6029","Comment","8","131","130","86","91","89","92","90","87","VertexColor","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":142,"pos":[-104,-304],"params":["Inherit","False","934.0322","801.3425","Comment","10","121","120","132","128","56","135","246","248","249","250","A","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":121,"pos":[-32,152],"params":["Inherit","False","424.2069","297.9635","Comment","5","54","53","52","254","253","Mask","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":120,"pos":[-56,-112],"params":["Inherit","False","446.5341","260.8385","Comment","4","76","77","113","116","R/A","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":266,"pos":[904,-40],"params":["Inherit","False","1600","720","Float modes: Off=0 (unchanged), Alpha=1 (fade Alpha), AlphaRGB=2 (fade Alpha and RGB). Camera depth texture required. Choose Alpha for SrcAlpha blending; AlphaRGB for Src=One blending.","13","255","256","257","258","259","260","261","263","264","265","140","125","268","Soft Particles / Off - Alpha - AlphaRGB","0.25,0.75,0.72,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":141,"pos":[-145.8604,-676.6329],"params":["Inherit","False","920.446","341.1266","Comment","9","124","133","139","123","136","138","102","155","156","RGB","1,1,1,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":129,"pos":[2576,-368],"params":["Inherit","False","172.3054","330.9568","Comment","4","51","48","46","47","BaseSetting","1,1,1,1","0","0"]}
{"wire":[19,0,21,0]}
{"wire":[19,2,20,0]}
{"wire":[16,1,19,0]}
{"wire":[25,0,16,1]}
{"wire":[25,1,26,0]}
{"wire":[24,0,25,0]}
{"wire":[24,1,11,0]}
{"wire":[75,0,73,1]}
{"wire":[75,1,73,2]}
{"wire":[72,0,75,0]}
{"wire":[72,1,80,0]}
{"wire":[80,0,11,0]}
{"wire":[80,1,24,0]}
{"wire":[80,2,81,0]}
{"wire":[39,0,38,0]}
{"wire":[39,2,40,0]}
{"wire":[200,0,80,0]}
{"wire":[200,1,72,0]}
{"wire":[200,2,208,0]}
{"wire":[30,1,39,0]}
{"wire":[12,0,200,0]}
{"wire":[12,2,10,0]}
{"wire":[31,0,30,0]}
{"wire":[31,1,32,0]}
{"wire":[31,2,33,0]}
{"wire":[108,0,31,0]}
{"wire":[14,1,12,0]}
{"wire":[2,0,14,0]}
{"wire":[2,1,4,0]}
{"wire":[2,2,3,0]}
{"wire":[206,0,205,0]}
{"wire":[41,0,109,0]}
{"wire":[41,1,107,0]}
{"wire":[82,0,109,0]}
{"wire":[82,1,107,0]}
{"wire":[166,1,84,0]}
{"wire":[103,0,2,0]}
{"wire":[172,1,84,0]}
{"wire":[85,0,41,0]}
{"wire":[85,1,82,0]}
{"wire":[85,2,166,0]}
{"wire":[183,0,99,0]}
{"wire":[183,1,228,3]}
{"wire":[183,2,207,0]}
{"wire":[230,0,229,0]}
{"wire":[230,1,231,0]}
{"wire":[78,0,105,0]}
{"wire":[78,1,85,0]}
{"wire":[78,2,172,0]}
{"wire":[97,1,183,0]}
{"wire":[233,0,230,0]}
{"wire":[233,1,234,0]}
{"wire":[233,2,235,0]}
{"wire":[237,0,235,0]}
{"wire":[237,1,234,0]}
{"wire":[95,0,98,1]}
{"wire":[95,1,94,0]}
{"wire":[95,2,97,0]}
{"wire":[91,0,87,0]}
{"wire":[236,0,233,0]}
{"wire":[236,1,234,0]}
{"wire":[111,0,78,0]}
{"wire":[269,0,237,0]}
{"wire":[93,0,95,0]}
{"wire":[93,2,96,0]}
{"wire":[92,1,91,0]}
{"wire":[92,2,86,0]}
{"wire":[242,0,236,0]}
{"wire":[242,1,269,0]}
{"wire":[126,0,93,0]}
{"wire":[116,0,113,0]}
{"wire":[241,0,240,2]}
{"wire":[241,1,240,1]}
{"wire":[241,2,242,0]}
{"wire":[131,0,92,0]}
{"wire":[254,0,54,0]}
{"wire":[253,0,52,1]}
{"wire":[76,0,116,0]}
{"wire":[76,1,116,3]}
{"wire":[76,2,77,0]}
{"wire":[244,0,241,0]}
{"wire":[53,0,253,0]}
{"wire":[53,1,254,0]}
{"wire":[56,0,132,0]}
{"wire":[56,1,128,0]}
{"wire":[56,2,76,0]}
{"wire":[56,3,53,0]}
{"wire":[250,0,56,0]}
{"wire":[250,1,246,0]}
{"wire":[248,0,250,0]}
{"wire":[248,1,56,0]}
{"wire":[248,2,249,0]}
{"wire":[257,0,256,0]}
{"wire":[135,0,248,0]}
{"wire":[258,0,257,0]}
{"wire":[268,0,255,0]}
{"wire":[259,1,258,0]}
{"wire":[259,2,268,0]}
{"wire":[102,0,155,0]}
{"wire":[102,1,156,0]}
{"wire":[102,2,136,0]}
{"wire":[139,0,102,0]}
{"wire":[139,1,133,0]}
{"wire":[155,0,138,0]}
{"wire":[156,0,124,0]}
{"wire":[101,0,93,0]}
{"wire":[101,1,100,0]}
{"wire":[137,0,101,0]}
{"wire":[90,0,87,0]}
{"wire":[89,1,90,0]}
{"wire":[89,2,86,0]}
{"wire":[130,0,89,0]}
{"wire":[265,0,140,0]}
{"wire":[265,1,259,0]}
{"wire":[123,0,139,0]}
{"wire":[261,0,255,0]}
{"wire":[260,0,125,0]}
{"wire":[260,1,264,0]}
{"wire":[263,0,261,0]}
{"wire":[264,1,259,0]}
{"wire":[264,2,263,0]}
{"wire":[270,0,260,0]}
{"wire":[270,2,265,0]}
ASEEND*/
//CHKSM=370022CE4D9B9C0D1DA0E0B7F57C1FA4CF89BACC