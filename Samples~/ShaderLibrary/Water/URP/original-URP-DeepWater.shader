// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Water/DeepWater_URP_ASE"
{
	Properties
	{
		_WaveSpeed( "01 Waves / speed", Range( 0.05, 2 ) ) = 0.75
		_WaveHeight( "01 Waves / height (m)", Range( 0, 0.6 ) ) = 0.13
		_WaveScale( "01 Waves / frequency", Range( 0.1, 3 ) ) = 1
		[Toggle( _WATER_WAVES_ON )] _WATER_WAVES( "Enable / 01 Geometry waves", Float ) = 1
		_RippleSlope( "02 Ripples / seamless slope field", 2D ) = "gray" {}
		_RippleScale( "02 Ripples / tiling per meter", Range( 0.05, 2 ) ) = 0.4
		_RippleStrength( "02 Ripples / strength", Range( 0, 1.5 ) ) = 0.48
		[Toggle( _WATER_RIPPLES_ON )] _WATER_RIPPLES( "Enable / 02 Fine ripples (2 samples)", Float ) = 1
		[Toggle( _WATER_FRESNEL_ON )] _WATER_FRESNEL( "Enable / 03 Transmission Fresnel", Float ) = 1
		_Density( "03 Depth / absorption density", Range( 0.01, 3 ) ) = 0.7
		_Absorption( "03 Depth / absorption RGB (1/m)", Vector ) = ( 0.85, 0.32, 0.17, 0 )
		_DeepDistance( "03 Depth / deep color distance (m)", Range( 0.1, 25 ) ) = 5
		[Toggle( _WATER_DEPTH_ON )] _WATER_DEPTH( "Enable / 04 Depth absorption and tint", Float ) = 1
		_ShallowColor( "03 Depth / shallow scattering", Color ) = ( 0.12, 0.48, 0.4, 1 )
		_DeepColor( "03 Depth / deep scattering", Color ) = ( 0.012, 0.13, 0.19, 1 )
		_CausticTex( "06 Caustics / seamless light pattern", 2D ) = "black" {}
		_CausticScale( "06 Caustics / tiling per meter", Range( 0.05, 2 ) ) = 0.28
		_CausticSpeed( "06 Caustics / animation speed", Range( 0, 2 ) ) = 0.65
		_CausticStrength( "06 Caustics / brightness", Range( 0, 6 ) ) = 3
		_CausticFalloff( "06 Caustics / depth extinction", Range( 0, 3 ) ) = 0.45
		_CausticTint( "06 Caustics / light tint", Color ) = ( 1, 0.94, 0.72, 1 )
		[Toggle( _WATER_CAUSTICS_ON )] _WATER_CAUSTICS( "Enable / 06 Underwater caustics (2 samples)", Float ) = 1
		_FoamWidth( "04 Foam / shoreline width (m)", Range( 0.02, 2 ) ) = 0.5
		_FoamStrength( "04 Foam / amount", Range( 0, 1 ) ) = 0.7
		[Toggle( _WATER_FOAM_ON )] _WATER_FOAM( "Enable / 05 Shore foam (1 noise sample)", Float ) = 1
		_FoamColor( "04 Foam / color", Color ) = ( 0.82, 0.91, 0.88, 1 )
		_RefractionStrength( "05 Optics / refraction", Range( 0, 0.05 ) ) = 0.014
		_ScatteringStrength( "05 Optics / scattering", Range( 0, 1.5 ) ) = 0.75
		[Toggle( _WATER_SCATTER_ON )] _WATER_SCATTER( "Enable / 07 Water scattering", Float ) = 1
		[Toggle( _WATER_REFRACTION_ON )] _WATER_REFRACTION( "Enable / 08 Screen refraction and bottom", Float ) = 1
		_ReflectionStrength( "05 Optics / reflection", Range( 0, 2 ) ) = 1
		_Smoothness( "05 Optics / smoothness", Range( 0.5, 0.99 ) ) = 0.94


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		//_InstancedTerrainNormals("Instanced Terrain Normals", Float) = 1.0

		[ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		//[HideInInspector] _AlphaClip("__clip", Float) = 0.0
	}

	SubShader
	{
		PackageRequirements
		{
			"com.unity.render-pipelines.universal": "[14.0,15.0]"
		}

		

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Lit" }

	LOD 0

		Cull Back
		ZWrite Off
		ZClip True
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

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

			float DistanceFromPlane (float3 pos, float4 plane)
			{
				float d = dot (float4(pos,1.0f), plane);
				return d;
			}

			bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
			{
				float4 planeTest;
				planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
								(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
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
			
			Name "ForwardLit"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			

			#define ASE_GEOMETRY
			#pragma shader_feature_local_fragment _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

			
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
		

			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION

			
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
           

			

			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS

			

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

			#define SHADERPASS SHADERPASS_FORWARD

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined( UNITY_INSTANCING_ENABLED ) && defined( ASE_INSTANCED_TERRAIN ) && ( defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL) || defined(_INSTANCEDTERRAINNORMALS_PIXEL) )
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_WORLD_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#pragma shader_feature_local _WATER_WAVES_ON
			#pragma shader_feature_local _WATER_SCATTER_ON
			#pragma shader_feature_local _WATER_DEPTH_ON
			#pragma shader_feature_local _WATER_FOAM_ON
			#pragma shader_feature_local _WATER_RIPPLES_ON
			#pragma shader_feature_local _WATER_REFRACTION_ON
			#pragma shader_feature_local _WATER_CAUSTICS_ON
			#pragma shader_feature_local _WATER_FRESNEL_ON


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				#if defined(LIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES1)
					float4 texcoord1 : TEXCOORD1;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES2)
					float4 texcoord2 : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				half3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2; // holds terrainUV ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
				float4 lightmapUVOrVertexSH : TEXCOORD3;
				#if defined(ASE_FOG) || defined(_ADDITIONAL_LIGHTS_VERTEX)
					half4 fogFactorAndVertexLight : TEXCOORD4;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD5;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			TEXTURE2D(_RippleSlope);
			SAMPLER(sampler_RippleSlope);
			TEXTURE2D(_CausticTex);
			SAMPLER(sampler_CausticTex);


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
				float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
				float temp_output_29_0 = ( _WaveHeight * 0.57 );
				float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
				float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
				float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
				float temp_output_48_0 = ( _WaveHeight * 0.28 );
				float ase_swell_2_amplitude_310310 = temp_output_48_0;
				float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
				float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
				float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
				float temp_output_67_0 = ( _WaveHeight * 0.15 );
				float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
				float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
				float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
				float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
				float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
				float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
				float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
				#ifdef _WATER_WAVES_ON
				float4 staticSwitch84 = appendResult82;
				#else
				float4 staticSwitch84 = float4( 0, 0, 0, 0 );
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif
				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS, input.tangentOS );

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(input.texcoord1, unity_LightmapST, output.lightmapUVOrVertexSH.xy);
				#else
					OUTPUT_SH(normalInput.normalWS.xyz, output.lightmapUVOrVertexSH.xyz);
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					output.dynamicLightmapUV.xy = input.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ASE_FOG) || defined(_ADDITIONAL_LIGHTS_VERTEX)
					output.fogFactorAndVertexLight = 0;
					#if defined(ASE_FOG) && !defined(_FOG_FRAGMENT)
						output.fogFactorAndVertexLight.x = ComputeFogFactor(vertexInput.positionCS.z);
					#endif
					#ifdef _ADDITIONAL_LIGHTS_VERTEX
						half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );
						output.fogFactorAndVertexLight.yzw = vertexLight;
					#endif
				#endif

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWS = vertexInput.positionWS;
				output.normalWS = normalInput.normalWS;
				output.tangentWS = float4( normalInput.tangentWS, ( input.tangentOS.w > 0.0 ? 1.0 : -1.0 ) * GetOddNegativeScale() );

				#if defined( ENABLE_TERRAIN_PERPIXEL_NORMAL )
					output.tangentWS.zw = input.texcoord.xy;
					output.tangentWS.xy = input.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				#if defined(LIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES1)
					float4 texcoord1 : TEXCOORD1;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES2)
					float4 texcoord2 : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.texcoord = input.texcoord;
				#if defined(LIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES1)
					output.texcoord1 = input.texcoord1;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES2)
					output.texcoord2 = input.texcoord2;
				#endif
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				output.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				#if defined(LIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES1)
					output.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON) || defined(ASE_NEEDS_TEXTURE_COORDINATES2)
					output.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				#endif
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag ( PackedVaryings input
						#if defined( ASE_WRITE_DEPTH )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				#if defined( _SURFACE_TYPE_TRANSPARENT )
					const bool isTransparent = true;
				#else
					const bool isTransparent = false;
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					float4 shadowCoord = TransformWorldToShadowCoord( input.positionWS );
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				// @diogo: mikktspace compliant
				float renormFactor = 1.0 / max( FLT_MIN, length( input.normalWS ) );

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				float3 ViewDirWS = GetWorldSpaceNormalizeViewDir( PositionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );
				float3 TangentWS = input.tangentWS.xyz * renormFactor;
				float3 BitangentWS = cross( input.normalWS, input.tangentWS.xyz ) * input.tangentWS.w * renormFactor;
				float3 NormalWS = input.normalWS * renormFactor;

				#if defined( ENABLE_TERRAIN_PERPIXEL_NORMAL )
					float2 sampleCoords = (input.tangentWS.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					NormalWS = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					TangentWS = -cross(GetObjectToWorldMatrix()._13_23_33, NormalWS);
					BitangentWS = cross(NormalWS, -TangentWS);
				#endif

				float screenDepth133 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ) );
				float distanceDepth133 = ( screenDepth133 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( 1.0 );
				float temp_output_137_0 = min( max( distanceDepth133, 0.0 ), 80.0 );
				float ase_view_to_camera_ws_333333 = ViewDirWS.x;
				float ase_view_to_camera_ws_335335 = ViewDirWS.y;
				float ase_view_to_camera_ws_337337 = ViewDirWS.z;
				float4 appendResult139 = (float4(ase_view_to_camera_ws_333333 , ase_view_to_camera_ws_335335 , ase_view_to_camera_ws_337337 , 0.0));
				float temp_output_146_0 = ( temp_output_137_0 / max( abs( (mul( unity_WorldToCamera, appendResult139 )).z ), 0.12 ) );
				float ase_optical_path_m_339339 = temp_output_146_0;
				float4 staticSwitch162 = ( float4 )0;
				#ifdef _WATER_DEPTH_ON
				{
					float3 temp_output_153_0 = exp( -( ( temp_output_146_0 * _Density ) * (_Absorption).xyz ) );
					float4 appendResult160 = (float4((temp_output_153_0).x , (temp_output_153_0).y , (temp_output_153_0).z , saturate( ( ase_optical_path_m_339339 / _DeepDistance ) )));
					staticSwitch162 = appendResult160;
				}
				#else
				{
					staticSwitch162 = float4( 1, 1, 1, 0 );
				}
				#endif
				float3 lerpResult169 = lerp( (_ShallowColor).rgb , (_DeepColor).rgb , (staticSwitch162).w);
				float3 ase_depth_scattering_color_367367 = lerpResult169;
				float3 ase_enabled_transmittance_365365 = (staticSwitch162).xyz;
				float3 staticSwitch280 = ( float3 )0;
				#ifdef _WATER_SCATTER_ON
				{
					staticSwitch280 = ( ( ase_depth_scattering_color_367367 * ( 1.0 - ase_enabled_transmittance_365365 ) ) * _ScatteringStrength );
				}
				#else
				{
					staticSwitch280 = (float4( 0, 0, 0, 0 )).xyz;
				}
				#endif
				float3 ase_scattering_enabled_370370 = staticSwitch280;
				float3 ase_foam_rgb_383383 = (_FoamColor).rgb;
				float smoothstepResult172 = smoothstep( 0.0 , 0.1 , temp_output_137_0);
				float ase_shore_contact_fade_352352 = smoothstepResult172;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float ase_depth_eye_355355 = temp_output_137_0;
				float2 ase_world_xz_301301 = (PositionWS).xz;
				float staticSwitch247 = ( float )0;
				#ifdef _WATER_FOAM_ON
				{
					float temp_output_222_0 = ( 1.0 - saturate( ( ase_depth_eye_355355 / _FoamWidth ) ) );
					float2 panner216 = ( ase_water_clock_303303 * (float4( 0.029, 0.014, 0, 0 )).xy + ( ase_world_xz_301301 * 0.48 ));
					float smoothstepResult226 = smoothstep( 0.34 , 0.66 , SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner216 ).b);
					float lerpResult239 = lerp( 0.35 , 1.0 , ( ( sin( ( ( ase_depth_eye_355355 * 14.0 ) - ( ase_water_clock_303303 * 1.8 ) ) ) * 0.5 ) + 0.5 ));
					staticSwitch247 = saturate( ( ( ( ( temp_output_222_0 * temp_output_222_0 ) * smoothstepResult226 ) * lerpResult239 ) * ( _FoamStrength * ase_shore_contact_fade_352352 ) ) );
				}
				#else
				{
					staticSwitch247 = 0.0;
				}
				#endif
				float ase_foam_enabled_379379 = staticSwitch247;
				float3 lerpResult299 = lerp( ( ase_scattering_enabled_370370 * 0.08 ) , ase_foam_rgb_383383 , ase_foam_enabled_379379);
				
				float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
				float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
				float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
				float temp_output_29_0 = ( _WaveHeight * 0.57 );
				float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
				float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
				float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
				float temp_output_48_0 = ( _WaveHeight * 0.28 );
				float ase_swell_2_amplitude_310310 = temp_output_48_0;
				float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
				float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
				float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
				float temp_output_67_0 = ( _WaveHeight * 0.15 );
				float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
				float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
				float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
				float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
				float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
				float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
				float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
				#ifdef _WATER_WAVES_ON
				float4 staticSwitch84 = appendResult82;
				#else
				float4 staticSwitch84 = float4( 0, 0, 0, 0 );
				#endif
				float ase_enabled_wave_slope_x_328328 = (staticSwitch84).y;
				float2 staticSwitch116 = ( float2 )0;
				#ifdef _WATER_RIPPLES_ON
				{
					float2 panner98 = ( ase_water_clock_303303 * (float4( 0.036, 0.021, 0, 0 )).xy + ( ase_world_xz_301301 * _RippleScale ));
					float2 panner105 = ( ase_water_clock_303303 * (float4( -0.019, 0.029, 0, 0 )).xy + ( (ase_world_xz_301301).yx * ( _RippleScale * 1.63 ) ));
					staticSwitch116 = ( ( ( (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner98 )).rg + (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner105 )).gr ) - 1.0 ) * _RippleStrength );
				}
				#else
				{
					staticSwitch116 = (float4( 0, 0, 0, 0 )).xy;
				}
				#endif
				float2 ase_ripples_enabled_326326 = staticSwitch116;
				float ase_enabled_wave_slope_z_331331 = (staticSwitch84).z;
				float3 appendResult124 = (float3(-( ase_enabled_wave_slope_x_328328 + (ase_ripples_enabled_326326).x ) , 1.0 , -( ase_enabled_wave_slope_z_331331 + (ase_ripples_enabled_326326).y )));
				float3 normalizeResult125 = normalize( appendResult124 );
				float3 ase_water_normal_ws_360360 = normalizeResult125;
				
				float lerpResult292 = lerp( ( 0.02037 * ( _ReflectionStrength * ase_shore_contact_fade_352352 ) ) , 0.028 , ase_foam_enabled_379379);
				float3 appendResult293 = (float3(lerpResult292 , lerpResult292 , lerpResult292));
				
				float lerpResult296 = lerp( _Smoothness , 0.28 , ase_foam_enabled_379379);
				float ase_surface_smoothness_387387 = lerpResult296;
				
				float3 staticSwitch282 = ( float3 )0;
				#ifdef _WATER_REFRACTION_ON
				{
					float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ScreenPos );
					float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
					float4 appendResult254 = (float4((ase_water_normal_ws_360360).x , (ase_water_normal_ws_360360).y , (ase_water_normal_ws_360360).z , 0.0));
					float4 fetchOpaqueVal268 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( saturate( ( (ase_grabScreenPosNorm).xy + ( (mul( unity_WorldToCamera, appendResult254 )).xy * ( _RefractionStrength * saturate( ( ase_depth_eye_355355 / 0.65 ) ) ) ) ) ).xy ), 1.0 );
					float3 staticSwitch212 = ( float3 )0;
					#ifdef _WATER_CAUSTICS_ON
					{
						float ase_time_seconds_350350 = _TimeParameters.x;
						float temp_output_183_0 = ( ase_time_seconds_350350 * _CausticSpeed );
						float3 ase_world_position_344344 = PositionWS;
						float3 ase_view_to_camera_ws_341341 = ViewDirWS;
						float3 temp_output_174_0 = ( ase_world_position_344344 - ( ase_view_to_camera_ws_341341 * ase_optical_path_m_339339 ) );
						float3 ase_underwater_position_ws_346346 = temp_output_174_0;
						float2 temp_output_175_0 = (ase_underwater_position_ws_346346).xz;
						float2 panner187 = ( temp_output_183_0 * (float4( 0.025, 0.017, 0, 0 )).xy + ( temp_output_175_0 * ( _CausticScale * 1.0 ) ));
						float2 panner194 = ( temp_output_183_0 * (float4( -0.018, 0.023, 0, 0 )).xy + ( temp_output_175_0 * ( _CausticScale * 1.17 ) ));
						float ase_world_position_348348 = PositionWS.y;
						staticSwitch212 = ( (_CausticTint).rgb * ( min( SAMPLE_TEXTURE2D( _CausticTex, sampler_CausticTex, panner187 ).r, SAMPLE_TEXTURE2D( _CausticTex, sampler_CausticTex, panner194 ).r ) * ( _CausticStrength * ( exp( -( max( ( ase_world_position_348348 - (temp_output_174_0).y ), 0.0 ) * _CausticFalloff ) ) * ase_shore_contact_fade_352352 ) ) ) );
					}
					#else
					{
						staticSwitch212 = (float4( 0, 0, 0, 0 )).xyz;
					}
					#endif
					float3 ase_caustics_enabled_373373 = staticSwitch212;
					staticSwitch282 = ( ( ( (fetchOpaqueVal268).rgb * ( 1.0 + ase_caustics_enabled_373373 ) ) * ase_enabled_transmittance_365365 ) + staticSwitch280 );
				}
				#else
				{
					staticSwitch282 = ase_depth_scattering_color_367367;
				}
				#endif
				float staticSwitch132 = ( float )0;
				#ifdef _WATER_FRESNEL_ON
				{
					float fresnelNdotV127 = dot( normalizeResult125, ViewDirWS );
					float fresnelNode127 = ( 0.02037 + 0.97963 * pow( 1.0 - fresnelNdotV127, 5.0 ) );
					staticSwitch132 = fresnelNode127;
				}
				#else
				{
					staticSwitch132 = 0.0;
				}
				#endif
				float ase_fresnel_enabled_377377 = staticSwitch132;
				float3 ase_water_transmission_emission_389389 = ( ( staticSwitch282 * ( 1.0 - ase_fresnel_enabled_377377 ) ) * ( 1.0 - ase_foam_enabled_379379 ) );
				
				float ase_composite_alpha_391391 = 1.0;
				

				float3 BaseColor = lerpResult299;
				float3 Normal = ase_water_normal_ws_360360;
				float3 Specular = appendResult293;
				float Metallic = 0;
				float Smoothness = ase_surface_smoothness_387387;
				float Occlusion = 1;
				float3 Emission = ase_water_transmission_emission_389389;
				float Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
					float AlphaClipThresholdShadow = 0.5;
				#endif
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_CHANGES_WORLD_POS)
					ShadowCoord = TransformWorldToShadowCoord( PositionWS );
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = PositionWS;
				inputData.positionCS = input.positionCS;
				inputData.normalizedScreenSpaceUV = ScreenPosNorm.xy;
				inputData.viewDirectionWS = ViewDirWS;
				inputData.shadowCoord = ShadowCoord;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(TangentWS, BitangentWS, NormalWS));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = NormalWS;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
				#endif
				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
				#endif

				#if defined( ENABLE_TERRAIN_PERPIXEL_NORMAL )
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = input.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, input.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = input.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
				#endif

				#ifdef ASE_LIGHTING_SIMPLE
					half4 color = UniversalFragmentBlinnPhong( inputData, surfaceData);
				#else
					half4 color = UniversalFragmentPBR( inputData, surfaceData);
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					#define SUM_LIGHT_TRANSMISSION(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 transmission = max( 0, -dot( inputData.normalWS, Light.direction ) ) * atten * Transmission;\
						color.rgb += BaseColor * transmission;

					SUM_LIGHT_TRANSMISSION( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSMISSION( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSMISSION( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#define SUM_LIGHT_TRANSLUCENCY(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 lightDir = Light.direction + inputData.normalWS * normal;\
						half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );\
						half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;\
						color.rgb += BaseColor * translucency * strength;

					SUM_LIGHT_TRANSLUCENCY( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSLUCENCY( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSLUCENCY( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( NormalWS,0 ) ).xyz * ( 1.0 - dot( NormalWS, ViewDirWS ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3(0,0,0), inputData.fogCoord);
					#else
						color.rgb = MixFog(color.rgb, inputData.fogCoord);
					#endif
				#endif

				#if defined( ASE_WRITE_DEPTH )
					outputDepth = input.positionCS.z;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				#if defined( ASE_OPAQUE_KEEP_ALPHA )
					return half4( color.rgb, color.a );
				#else
					return half4( color.rgb, OutputAlpha( color.a, isTransparent ) );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			

			#define ASE_GEOMETRY
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#pragma shader_feature_local _WATER_WAVES_ON


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float4 staticSwitch84 = ( float4 )0;
				#ifdef _WATER_WAVES_ON
				{
					float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
					float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
					float temp_output_29_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
					float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
					float temp_output_48_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_310310 = temp_output_48_0;
					float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
					float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
					float temp_output_67_0 = ( _WaveHeight * 0.15 );
					float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
					float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
					float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
					float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
					float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
					float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
					float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
					staticSwitch84 = appendResult82;
				}
				#else
				{
					staticSwitch84 = float4( 0, 0, 0, 0 );
				}
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWS = vertexInput.positionWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(	PackedVaryings input
						#if defined( ASE_WRITE_DEPTH )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( input.positionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				float ase_composite_alpha_391391 = 1.0;
				

				float Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_WRITE_DEPTH )
					outputDepth = input.positionCS.z;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#define ASE_GEOMETRY
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_WORLD_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _WATER_WAVES_ON
			#pragma shader_feature_local _WATER_SCATTER_ON
			#pragma shader_feature_local _WATER_DEPTH_ON
			#pragma shader_feature_local _WATER_FOAM_ON


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			TEXTURE2D(_RippleSlope);
			SAMPLER(sampler_RippleSlope);


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float4 staticSwitch84 = ( float4 )0;
				#ifdef _WATER_WAVES_ON
				{
					float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
					float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
					float temp_output_29_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
					float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
					float temp_output_48_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_310310 = temp_output_48_0;
					float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
					float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
					float temp_output_67_0 = ( _WaveHeight * 0.15 );
					float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
					float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
					float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
					float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
					float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
					float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
					float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
					staticSwitch84 = appendResult82;
				}
				#else
				{
					staticSwitch84 = float4( 0, 0, 0, 0 );
				}
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				
				float4 ase_positionCS = TransformObjectToHClip( ( input.positionOS ).xyz );
				float4 screenPos = ComputeScreenPos( ase_positionCS );
				output.ase_texcoord1 = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = vertexInput.positionCS;
				output.positionWS = vertexInput.positionWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( input.positionWS );
				float4 ShadowCoord = shadowCoord;

				float4 screenPos = input.ase_texcoord1;
				float4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth133 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_positionSSNorm.xy ) );
				float distanceDepth133 = ( screenDepth133 - ASELinearEyeDepth( ase_positionSSNorm.z ) ) / ( 1.0 );
				float temp_output_137_0 = min( max( distanceDepth133, 0.0 ), 80.0 );
				float3 ase_viewVectorWS = ( ( unity_OrthoParams.w == 0 ) ? _WorldSpaceCameraPos - PositionWS : UNITY_MATRIX_V[ 2 ].xyz );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float ase_view_to_camera_ws_333333 = ase_viewDirWS.x;
				float ase_view_to_camera_ws_335335 = ase_viewDirWS.y;
				float ase_view_to_camera_ws_337337 = ase_viewDirWS.z;
				float4 appendResult139 = (float4(ase_view_to_camera_ws_333333 , ase_view_to_camera_ws_335335 , ase_view_to_camera_ws_337337 , 0.0));
				float temp_output_146_0 = ( temp_output_137_0 / max( abs( (mul( unity_WorldToCamera, appendResult139 )).z ), 0.12 ) );
				float ase_optical_path_m_339339 = temp_output_146_0;
				float4 staticSwitch162 = ( float4 )0;
				#ifdef _WATER_DEPTH_ON
				{
					float3 temp_output_153_0 = exp( -( ( temp_output_146_0 * _Density ) * (_Absorption).xyz ) );
					float4 appendResult160 = (float4((temp_output_153_0).x , (temp_output_153_0).y , (temp_output_153_0).z , saturate( ( ase_optical_path_m_339339 / _DeepDistance ) )));
					staticSwitch162 = appendResult160;
				}
				#else
				{
					staticSwitch162 = float4( 1, 1, 1, 0 );
				}
				#endif
				float3 lerpResult169 = lerp( (_ShallowColor).rgb , (_DeepColor).rgb , (staticSwitch162).w);
				float3 ase_depth_scattering_color_367367 = lerpResult169;
				float3 ase_enabled_transmittance_365365 = (staticSwitch162).xyz;
				float3 staticSwitch280 = ( float3 )0;
				#ifdef _WATER_SCATTER_ON
				{
					staticSwitch280 = ( ( ase_depth_scattering_color_367367 * ( 1.0 - ase_enabled_transmittance_365365 ) ) * _ScatteringStrength );
				}
				#else
				{
					staticSwitch280 = (float4( 0, 0, 0, 0 )).xyz;
				}
				#endif
				float3 ase_scattering_enabled_370370 = staticSwitch280;
				float3 ase_foam_rgb_383383 = (_FoamColor).rgb;
				float smoothstepResult172 = smoothstep( 0.0 , 0.1 , temp_output_137_0);
				float ase_shore_contact_fade_352352 = smoothstepResult172;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float ase_depth_eye_355355 = temp_output_137_0;
				float2 ase_world_xz_301301 = (PositionWS).xz;
				float staticSwitch247 = ( float )0;
				#ifdef _WATER_FOAM_ON
				{
					float temp_output_222_0 = ( 1.0 - saturate( ( ase_depth_eye_355355 / _FoamWidth ) ) );
					float2 panner216 = ( ase_water_clock_303303 * (float4( 0.029, 0.014, 0, 0 )).xy + ( ase_world_xz_301301 * 0.48 ));
					float smoothstepResult226 = smoothstep( 0.34 , 0.66 , SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner216 ).b);
					float lerpResult239 = lerp( 0.35 , 1.0 , ( ( sin( ( ( ase_depth_eye_355355 * 14.0 ) - ( ase_water_clock_303303 * 1.8 ) ) ) * 0.5 ) + 0.5 ));
					staticSwitch247 = saturate( ( ( ( ( temp_output_222_0 * temp_output_222_0 ) * smoothstepResult226 ) * lerpResult239 ) * ( _FoamStrength * ase_shore_contact_fade_352352 ) ) );
				}
				#else
				{
					staticSwitch247 = 0.0;
				}
				#endif
				float ase_foam_enabled_379379 = staticSwitch247;
				float3 lerpResult299 = lerp( ( ase_scattering_enabled_370370 * 0.08 ) , ase_foam_rgb_383383 , ase_foam_enabled_379379);
				
				float ase_composite_alpha_391391 = 1.0;
				

				float3 BaseColor = lerpResult299;
				float Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
				#endif

				half4 color = half4(BaseColor, Alpha );

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			

			

			#define ASE_GEOMETRY
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define ASE_USING_SAMPLING_MACROS 1


			

			

			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
			//#define SHADERPASS SHADERPASS_DEPTHNORMALS

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined( UNITY_INSTANCING_ENABLED ) && defined( ASE_INSTANCED_TERRAIN ) && ( defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL) || defined(_INSTANCEDTERRAINNORMALS_PIXEL) )
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_WORLD_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _WATER_WAVES_ON
			#pragma shader_feature_local _WATER_RIPPLES_ON


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				half4 texcoord : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				half3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2; // holds terrainUV ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			TEXTURE2D(_RippleSlope);
			SAMPLER(sampler_RippleSlope);


			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
				float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
				float temp_output_29_0 = ( _WaveHeight * 0.57 );
				float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
				float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
				float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
				float temp_output_48_0 = ( _WaveHeight * 0.28 );
				float ase_swell_2_amplitude_310310 = temp_output_48_0;
				float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
				float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
				float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
				float temp_output_67_0 = ( _WaveHeight * 0.15 );
				float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
				float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
				float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
				float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
				float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
				float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
				float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
				#ifdef _WATER_WAVES_ON
				float4 staticSwitch84 = appendResult82;
				#else
				float4 staticSwitch84 = float4( 0, 0, 0, 0 );
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS, input.tangentOS );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWS = vertexInput.positionWS;
				output.normalWS = normalInput.normalWS;
				output.tangentWS = float4( normalInput.tangentWS, ( input.tangentOS.w > 0.0 ? 1.0 : -1.0 ) * GetOddNegativeScale() );

				#if defined( ENABLE_TERRAIN_PERPIXEL_NORMAL )
					output.tangentWS.zw = input.texcoord.xy;
					output.tangentWS.xy = input.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.texcoord = input.texcoord;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				output.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			void frag(	PackedVaryings input
						, out half4 outNormalWS : SV_Target0
						#if defined( ASE_WRITE_DEPTH )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				// @diogo: mikktspace compliant
				float renormFactor = 1.0 / max( FLT_MIN, length( input.normalWS ) );

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( input.positionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );
				float3 TangentWS = input.tangentWS.xyz * renormFactor;
				float3 BitangentWS = cross( input.normalWS, input.tangentWS.xyz ) * input.tangentWS.w * renormFactor;
				float3 NormalWS = input.normalWS * renormFactor;

				#if defined( ENABLE_TERRAIN_PERPIXEL_NORMAL )
					float2 sampleCoords = (input.tangentWS.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					NormalWS = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					TangentWS = -cross(GetObjectToWorldMatrix()._13_23_33, NormalWS);
					BitangentWS = cross(NormalWS, -TangentWS);
				#endif

				float2 ase_world_xz_301301 = (PositionWS).xz;
				float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
				float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
				float temp_output_29_0 = ( _WaveHeight * 0.57 );
				float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
				float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
				float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
				float temp_output_48_0 = ( _WaveHeight * 0.28 );
				float ase_swell_2_amplitude_310310 = temp_output_48_0;
				float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
				float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
				float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
				float temp_output_67_0 = ( _WaveHeight * 0.15 );
				float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
				float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
				float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
				float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
				float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
				float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
				float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
				#ifdef _WATER_WAVES_ON
				float4 staticSwitch84 = appendResult82;
				#else
				float4 staticSwitch84 = float4( 0, 0, 0, 0 );
				#endif
				float ase_enabled_wave_slope_x_328328 = (staticSwitch84).y;
				float2 staticSwitch116 = ( float2 )0;
				#ifdef _WATER_RIPPLES_ON
				{
					float2 panner98 = ( ase_water_clock_303303 * (float4( 0.036, 0.021, 0, 0 )).xy + ( ase_world_xz_301301 * _RippleScale ));
					float2 panner105 = ( ase_water_clock_303303 * (float4( -0.019, 0.029, 0, 0 )).xy + ( (ase_world_xz_301301).yx * ( _RippleScale * 1.63 ) ));
					staticSwitch116 = ( ( ( (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner98 )).rg + (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner105 )).gr ) - 1.0 ) * _RippleStrength );
				}
				#else
				{
					staticSwitch116 = (float4( 0, 0, 0, 0 )).xy;
				}
				#endif
				float2 ase_ripples_enabled_326326 = staticSwitch116;
				float ase_enabled_wave_slope_z_331331 = (staticSwitch84).z;
				float3 appendResult124 = (float3(-( ase_enabled_wave_slope_x_328328 + (ase_ripples_enabled_326326).x ) , 1.0 , -( ase_enabled_wave_slope_z_331331 + (ase_ripples_enabled_326326).y )));
				float3 normalizeResult125 = normalize( appendResult124 );
				float3 ase_water_normal_ws_360360 = normalizeResult125;
				
				float ase_composite_alpha_391391 = 1.0;
				

				float3 Normal = ase_water_normal_ws_360360;
				float Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_WRITE_DEPTH )
					outputDepth = input.positionCS.z;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(NormalWS);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(TangentWS, BitangentWS, NormalWS));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = NormalWS;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#define ASE_GEOMETRY
			#pragma multi_compile_instancing
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature_local _WATER_WAVES_ON


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction(Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float4 staticSwitch84 = ( float4 )0;
				#ifdef _WATER_WAVES_ON
				{
					float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
					float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
					float temp_output_29_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
					float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
					float temp_output_48_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_310310 = temp_output_48_0;
					float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
					float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
					float temp_output_67_0 = ( _WaveHeight * 0.15 );
					float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
					float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
					float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
					float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
					float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
					float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
					float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
					staticSwitch84 = appendResult82;
				}
				#else
				{
					staticSwitch84 = float4( 0, 0, 0, 0 );
				}
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWS = vertexInput.positionWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag( PackedVaryings input
				#if defined( ASE_WRITE_DEPTH )
				,out float outputDepth : ASE_SV_DEPTH
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;

				float ase_composite_alpha_391391 = 1.0;
				

				surfaceDescription.Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					surfaceDescription.AlphaClipThreshold = _Cutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#if defined( ASE_WRITE_DEPTH )
					outputDepth = input.positionCS.z;
				#endif

				return half4( _ObjectId, _PassValue, 1.0, 1.0 );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#define ASE_GEOMETRY
			#pragma multi_compile_instancing
			#define ASE_FOG 1
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMAL_DROPOFF_WS 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#if defined( _SPECULAR_SETUP ) && defined( ASE_LIGHTING_SIMPLE )
				#if defined( _SPECULARHIGHLIGHTS_OFF )
					#undef _SPECULAR_COLOR
				#else
					#define _SPECULAR_COLOR
				#endif
			#endif

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature_local _WATER_WAVES_ON


			#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float4 _CausticTint;
			float4 _Absorption;
			float4 _FoamColor;
			float _WaveScale;
			float _CausticScale;
			float _CausticSpeed;
			float _RefractionStrength;
			float _Smoothness;
			float _ReflectionStrength;
			float _RippleStrength;
			float _FoamWidth;
			float _FoamStrength;
			float _CausticStrength;
			float _ScatteringStrength;
			float _DeepDistance;
			float _Density;
			float _WaveHeight;
			float _WaveSpeed;
			float _RippleScale;
			float _CausticFalloff;
			float _AlphaClip;
			float _Cutoff;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float ase_wave_zero_320320 = 0.0;
				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float2 ase_world_xz_301301 = (ase_positionWS).xz;
				float ase_water_clock_303303 = ( _TimeParameters.x * _WaveSpeed );
				float4 staticSwitch84 = ( float4 )0;
				#ifdef _WATER_WAVES_ON
				{
					float2 temp_output_21_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult22 = dot( ase_world_xz_301301 , temp_output_21_0 );
					float temp_output_27_0 = ( ( dotResult22 + ( ase_water_clock_303303 * 0.9 ) ) + 0.1 );
					float temp_output_29_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_40_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult41 = dot( ase_world_xz_301301 , temp_output_40_0 );
					float temp_output_46_0 = ( ( dotResult41 + ( ase_water_clock_303303 * 1.23 ) ) + 1.6 );
					float temp_output_48_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_310310 = temp_output_48_0;
					float2 temp_output_59_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult60 = dot( ase_world_xz_301301 , temp_output_59_0 );
					float temp_output_65_0 = ( ( dotResult60 + ( ase_water_clock_303303 * 1.58 ) ) + 3.0 );
					float temp_output_67_0 = ( _WaveHeight * 0.15 );
					float temp_output_33_0 = ( cos( temp_output_27_0 ) * temp_output_29_0 );
					float2 ase_swell_1_wavevector_305305 = temp_output_21_0;
					float temp_output_52_0 = ( cos( temp_output_46_0 ) * temp_output_48_0 );
					float2 ase_swell_2_wavevector_312312 = temp_output_40_0;
					float temp_output_71_0 = ( cos( temp_output_65_0 ) * temp_output_67_0 );
					float2 ase_swell_3_wavevector_317317 = temp_output_59_0;
					float4 appendResult82 = (float4(( ( ( sin( temp_output_27_0 ) * temp_output_29_0 ) + ( sin( temp_output_46_0 ) * ase_swell_2_amplitude_310310 ) ) + ( sin( temp_output_65_0 ) * temp_output_67_0 ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).x ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).x ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).x ) ) , ( ( ( temp_output_33_0 * (ase_swell_1_wavevector_305305).y ) + ( temp_output_52_0 * (ase_swell_2_wavevector_312312).y ) ) + ( temp_output_71_0 * (ase_swell_3_wavevector_317317).y ) ) , 0.0));
					staticSwitch84 = appendResult82;
				}
				#else
				{
					staticSwitch84 = float4( 0, 0, 0, 0 );
				}
				#endif
				float4 appendResult88 = (float4(ase_wave_zero_320320 , (staticSwitch84).x , ase_wave_zero_320320 , ase_wave_zero_320320));
				float3 ase_object_wave_offset_393393 = (mul( GetWorldToObjectMatrix(), appendResult88 )).xyz;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ase_object_wave_offset_393393;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWS = vertexInput.positionWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
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
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag( PackedVaryings input
				#if defined( ASE_WRITE_DEPTH )
				,out float outputDepth : ASE_SV_DEPTH
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 PositionWS = input.positionWS;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;

				float ase_composite_alpha_391391 = 1.0;
				

				surfaceDescription.Alpha = ase_composite_alpha_391391;
				#if defined( _ALPHATEST_ON )
					surfaceDescription.AlphaClipThreshold = _Cutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#if defined( ASE_WRITE_DEPTH )
					outputDepth = input.positionCS.z;
				#endif

				return unity_SelectionID;
			}
			ENDHLSL
		}
		
	}
	

	

	CustomEditor "UnityEditor.ShaderGraphLitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":395,"pos":[0,15],"params":["Inherit","False","1020","1310","以世界 XZ 米制坐标驱动波浪与细波纹；对象缩放不改变波长。所有动画共享时间和速度。适用于水平水面。","10","10","11","12","13","14","301","303","344","348","350","01 世界坐标与时间","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor","id":10,"pos":[50,115],"params":["Inherit","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":12,"pos":[50,360],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[50,605],"params":["Inherit","False","Property","_WaveSpeed","01 Waves / speed","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.75","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":396,"pos":[1240,15],"params":["Inherit","False","6120","3270","三组不同方向、频率和速度的正弦波叠加成米制位移，同时用 cos 求导得到匹配的水面斜率。w=0 的矩阵变换将世界位移转回对象空间，不受平移影响。细分网格才有真实起伏。","99","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","302","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","320","321","328","331","393","02 三向缓慢涌浪与解析斜率","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":11,"pos":[390,115],"params":["Inherit","False","FLOAT2","0","2","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":14,"pos":[390,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":19,"pos":[1290,360],"params":["Inherit","False","Constant","_Vector0","Vector 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.52,0.17,0,0","0.52,0.17,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":38,"pos":[1290,605],"params":["Inherit","False","Constant","_Vector1","Vector 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.23,0.86,0,0","-0.23,0.86,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":18,"pos":[1630,115],"params":["Inherit","False","Property","_WaveScale","01 Waves / frequency","2","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0.1","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":20,"pos":[1630,605],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":39,"pos":[1630,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":57,"pos":[1630,360],"params":["Inherit","False","Constant","_Vector2","Vector 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.13,0.65,0,0","1.13,0.65,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":301,"pos":[730,115],"params":["Inherit","False","ase_world_xz_301","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":303,"pos":[730,360],"params":["Inherit","False","ase_water_clock_303","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":21,"pos":[1970,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":23,"pos":[1970,115],"params":["Inherit","False","Constant","_Float2","Float 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.9","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":40,"pos":[1970,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":42,"pos":[1970,360],"params":["Inherit","False","Constant","_Float5","Float 5","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.23","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":58,"pos":[1970,1340],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":302,"pos":[1970,605],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":304,"pos":[1970,1585],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":308,"pos":[1970,850],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":309,"pos":[1970,1830],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":22,"pos":[2310,850],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":24,"pos":[2310,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":41,"pos":[2310,1585],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":43,"pos":[2310,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":47,"pos":[2650,850],"params":["Inherit","False","Constant","_Float7","Float 7","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.28","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":59,"pos":[2310,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":61,"pos":[2310,115],"params":["Inherit","False","Constant","_Float8","Float 8","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.58","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":315,"pos":[2310,360],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":316,"pos":[2310,605],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":25,"pos":[2650,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":26,"pos":[2650,360],"params":["Inherit","False","Constant","_Float3","Float 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":44,"pos":[2650,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":45,"pos":[2650,605],"params":["Inherit","False","Constant","_Float6","Float 6","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.6","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":48,"pos":[2990,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":60,"pos":[2650,1095],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":62,"pos":[2650,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":305,"pos":[2990,1095],"params":["Inherit","False","ase_swell_1_wavevector_305","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":312,"pos":[2990,1830],"params":["Inherit","False","ase_swell_2_wavevector_312","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":17,"pos":[2650,115],"params":["Inherit","False","Property","_WaveHeight","01 Waves / height (m)","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0.13","0","0","0.6","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":27,"pos":[2990,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":28,"pos":[2990,115],"params":["Inherit","False","Constant","_Float4","Float 4","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.57","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":32,"pos":[3330,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":46,"pos":[2990,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":51,"pos":[3330,2075],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":63,"pos":[2990,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":64,"pos":[2990,360],"params":["Inherit","False","Constant","_Float9","Float 9","3","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":306,"pos":[3330,1340],"params":["Inherit","False","305","ase_swell_1_wavevector_305","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":307,"pos":[3330,1585],"params":["Inherit","False","305","ase_swell_1_wavevector_305","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":310,"pos":[3330,605],"params":["Inherit","False","ase_swell_2_amplitude_310","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":313,"pos":[3330,2320],"params":["Inherit","False","312","ase_swell_2_wavevector_312","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":314,"pos":[3330,2565],"params":["Inherit","False","312","ase_swell_2_wavevector_312","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":317,"pos":[3330,1830],"params":["Inherit","False","ase_swell_3_wavevector_317","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[3330,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":30,"pos":[3670,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":33,"pos":[3670,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":34,"pos":[3670,1340],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":36,"pos":[3670,1585],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":49,"pos":[3670,1830],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":52,"pos":[3670,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":53,"pos":[3670,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":55,"pos":[3670,3055],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":65,"pos":[3330,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":66,"pos":[3330,115],"params":["Inherit","False","Constant","_Float10","Float 10","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.15","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":70,"pos":[3670,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":311,"pos":[3670,605],"params":["Inherit","False","310","ase_swell_2_amplitude_310","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":318,"pos":[3670,2320],"params":["Inherit","False","317","ase_swell_3_wavevector_317","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":319,"pos":[3670,2565],"params":["Inherit","False","317","ase_swell_3_wavevector_317","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[4010,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":35,"pos":[4010,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":37,"pos":[4010,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":50,"pos":[4010,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":54,"pos":[4010,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":56,"pos":[4010,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":67,"pos":[3670,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":68,"pos":[4010,1340],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":71,"pos":[4010,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":72,"pos":[4010,1585],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":74,"pos":[4010,1830],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":69,"pos":[4350,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":73,"pos":[4350,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":75,"pos":[4350,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":76,"pos":[4350,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":78,"pos":[4350,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":80,"pos":[4350,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":77,"pos":[4690,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":79,"pos":[4690,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":81,"pos":[4690,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":15,"pos":[4690,115],"params":["Inherit","False","Constant","_Float0","Float 0","1","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":82,"pos":[5030,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":83,"pos":[5030,115],"params":["Inherit","False","Constant","_Vector3","Vector 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":84,"pos":[5370,360],"params":["Inherit","False","Property","_WATER_WAVES","Enable / 01 Geometry waves","3","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT4","0,0,0,0","False","0","FLOAT4","0,0,0,0","False","2","FLOAT4","0,0,0,0","False","3","FLOAT4","0,0,0,0","False","4","FLOAT4","0,0,0,0","False","5","FLOAT4","0,0,0,0","False","6","FLOAT4","0,0,0,0","False","7","FLOAT4","0,0,0,0","False","8","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":320,"pos":[5370,115],"params":["Inherit","False","ase_wave_zero_320","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":85,"pos":[5710,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":321,"pos":[5710,115],"params":["Inherit","False","320","ase_wave_zero_320","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":88,"pos":[6050,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToObjectMatrix, AmplifyShaderEditor","id":89,"pos":[6050,115],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":90,"pos":[6390,115],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":403,"pos":[28180,15],"params":["Inherit","False","1700","2045","相同的 Specular 工作流、方向光和探针反射；透明 Alpha=1 输出已合成的背景，ZWrite Off。URP 保留高光/环境反射材质开关；HDRP 专用 BSDF 的这两个独立开关未适配，默认均开启。各管线灯光、雾、探针和颜色拷贝宿主有差异，尚未证明像素等价。","22","287","288","289","290","291","292","293","294","295","296","297","298","299","300","369","371","381","382","384","385","387","391","09 PBR 高光、探针反射与合成","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":91,"pos":[6730,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":300,"pos":[28230,1095],"params":["Inherit","False","Constant","_Float44","Float 44","37","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":391,"pos":[28570,1340],"params":["Inherit","False","ase_composite_alpha_391","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":393,"pos":[7070,115],"params":["Inherit","False","ase_object_wave_offset_393","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":397,"pos":[1240,3445],"params":["Inherit","False","3740","1555","两次采样同一张原创线性斜率纹理，以不同方向和尺度流动。RG 解码为有正负的斜率；第二层交换通道。B 作为岸沫破碎噪声。纹理必须关闭 sRGB，保持 Repeat 与 mipmap。","30","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","322","323","324","325","326","03 双层无缝细波纹","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":398,"pos":[7580,15],"params":["Inherit","False","3060","2045","将涌浪解析斜率和细波纹斜率相加，构造并归一化世界空间法线。Schlick Fresnel 使用水的正视反射率约 2.04%，斜视时增强反射并减少透射。主节点 Normal Space 必须为 World。","26","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","327","329","330","332","333","335","337","341","360","377","04 真实方向法线与 Fresnel","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":399,"pos":[10860,15],"params":["Inherit","False","5780","1555","Depth Fade 减去已位移水面的线性眼空间深度，除以视线余弦得到水中路程。T=exp(-吸收系数×密度×路程)。开关关闭时透过率为 1，颜色使用浅水色；泡沫、焦散和折射仍可能需要共享深度。","49","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","334","336","338","339","340","352","355","365","367","05 真实深度与可选光吸收","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":400,"pos":[16860,15],"params":["Inherit","False","5100","2045","从水面沿相机视线和深度间隙重建水底位置，按水底世界 XZ 投影两层原创焦散纹理，缓慢错向流动。随垂直水深衰减并经水体吸收合成。关闭会裁掉焦散贡献；依赖屏幕水下透视，不是场景投影灯或水下相机效果。","49","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","211","212","342","343","345","346","347","349","351","353","373","06 水底焦散：重建位置与流动光网","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":401,"pos":[16860,2220],"params":["Inherit","False","4080","2045","按深度间隙生成岸沫，独立采样斜率纹理 B 通道作为流动噪声，再乘推进条带与接触软化。与细波纹开关独立；关闭泡沫会裁掉这个额外采样及粗糙度/颜色贡献。","45","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","246","247","248","249","354","356","357","358","359","372","379","383","07 可选浅岸泡沫","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":402,"pos":[22180,15],"params":["Inherit","False","5780","2045","相机空间法线扰动屏幕坐标，浅岸缩小偏移。水底颜色乘焦散光网，再经 RGB 吸收和可选散射，最后让出 Fresnel 与泡沫能量。关闭屏幕折射时改用水体颜色，裁掉屏幕采样和焦散；使用 URP Opaque Texture / HDRP Color Pyramid；关闭采样不自动关闭宿主颜色拷贝。HDRP 采样去预曝光后进入 Emission，避免重复曝光。","50","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","285","286","361","362","363","364","366","368","370","374","375","376","378","380","389","08 可选屏幕折射与水下合成","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":404,"pos":[30100,15],"params":["Inherit","False","640","1310","从命名 Register 读取远处的法线、顶点位移等结果，在主节点旁连接到对应端口，避免长线横穿整个图。","5","386","388","390","392","394","09 主节点输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":16,"pos":[1290,115],"params":["Inherit","False","Constant","_Float1","Float 1","1","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":86,"pos":[5710,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":87,"pos":[5710,850],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":92,"pos":[2310,3545],"params":["Inherit","True","Property","_RippleSlope","02 Ripples / seamless slope field","4","0","Create","False","0","0","0","True","0","False","","None","None","False","gray","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":93,"pos":[1290,3545],"params":["Inherit","False","Property","_RippleScale","02 Ripples / tiling per meter","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":94,"pos":[3670,3545],"params":["Inherit","False","Property","_RippleStrength","02 Ripples / strength","6","0","Create","False","0","0","0","True","0","False","Object","-1","","0.48","0","0","1.5","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":95,"pos":[1970,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":96,"pos":[1630,3545],"params":["Inherit","False","Constant","_Vector4","Vector 4","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.036,0.021,0,0","0.036,0.021,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":97,"pos":[1970,3545],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":98,"pos":[2310,3790],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":99,"pos":[1630,4525],"params":["Inherit","False","FLOAT2","1","0","2","3","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":100,"pos":[1290,3790],"params":["Inherit","False","Constant","_Float11","Float 11","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1.63","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":101,"pos":[1630,4280],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":102,"pos":[1970,4770],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":103,"pos":[1630,3790],"params":["Inherit","False","Constant","_Vector5","Vector 5","7","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.019,0.029,0,0","-0.019,0.029,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":104,"pos":[1970,4035],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":105,"pos":[2310,4035],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":106,"pos":[2650,3545],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","7","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":107,"pos":[2650,3790],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":108,"pos":[2990,3545],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":109,"pos":[2990,3790],"params":["Inherit","False","FLOAT2","1","0","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":110,"pos":[3330,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":111,"pos":[3330,3545],"params":["Inherit","False","Constant","_Float12","Float 12","9","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":112,"pos":[3670,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":113,"pos":[4010,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":114,"pos":[3670,3790],"params":["Inherit","False","Constant","_Vector6","Vector 6","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":115,"pos":[4010,3790],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":116,"pos":[4350,3545],"params":["Inherit","False","Property","_WATER_RIPPLES","Enable / 02 Fine ripples (2 samples)","7","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT2","0,0","False","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT2","0,0","False","6","FLOAT2","0,0","False","7","FLOAT2","0,0","False","8","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":117,"pos":[7970,1095],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":118,"pos":[8310,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":119,"pos":[8650,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":120,"pos":[7970,1340],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":121,"pos":[8310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":122,"pos":[8650,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":123,"pos":[8650,115],"params":["Inherit","False","Constant","_Float13","Float 13","10","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":124,"pos":[8990,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.NormalizeNode, AmplifyShaderEditor","id":125,"pos":[9330,850],"params":["Inherit","False","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ViewDirInputsCoordNode, AmplifyShaderEditor","id":126,"pos":[7630,115],"params":["Inherit","False","World","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.FresnelNode, AmplifyShaderEditor","id":127,"pos":[9670,360],"params":["Inherit","False","Standard","WorldNormal","ViewDir","False","False","5","0","FLOAT3","0,0,1","False","4","FLOAT3","0,0,0","False","1","FLOAT","0","False","2","FLOAT","1","False","3","FLOAT","5","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":128,"pos":[9330,115],"params":["Inherit","False","Constant","_Float14","Float 14","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.02037","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":129,"pos":[9330,360],"params":["Inherit","False","Constant","_Float15","Float 15","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.97963","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":130,"pos":[9330,605],"params":["Inherit","False","Constant","_Float16","Float 16","10","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":131,"pos":[9670,115],"params":["Inherit","False","Constant","_Float17","Float 17","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":132,"pos":[10010,115],"params":["Inherit","False","Property","_WATER_FRESNEL","Enable / 03 Transmission Fresnel","8","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT","0","False","0","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","5","FLOAT","0","False","6","FLOAT","0","False","7","FLOAT","0","False","8","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DepthFade, AmplifyShaderEditor","id":133,"pos":[10910,115],"params":["Inherit","False","True","False","False","2","1","FLOAT3","0,0,0","False","0","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":134,"pos":[10910,360],"params":["Inherit","False","Constant","_Float18","Float 18","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":135,"pos":[11250,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":136,"pos":[11250,115],"params":["Inherit","False","Constant","_Float19","Float 19","11","0","Create","True","0","0","0","False","0","False","Object","-1","","80","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":137,"pos":[11590,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":138,"pos":[10910,605],"params":["Inherit","False","Constant","_Float20","Float 20","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":139,"pos":[11250,850],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToCameraMatrix, AmplifyShaderEditor","id":140,"pos":[11250,360],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":141,"pos":[11590,850],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":142,"pos":[11930,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":143,"pos":[12270,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":144,"pos":[12270,115],"params":["Inherit","False","Constant","_Float21","Float 21","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0.12","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":145,"pos":[12610,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":146,"pos":[12950,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":147,"pos":[12950,115],"params":["Inherit","False","Property","_Density","03 Depth / absorption density","9","0","Create","False","0","0","0","True","0","False","Object","-1","","0.7","0","0.01","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":148,"pos":[12950,360],"params":["Inherit","False","Property","_Absorption","03 Depth / absorption RGB (1/m)","10","0","Create","False","0","0","0","True","0","False","Object","-1","","0.85,0.32,0.17,0","0.85,0.32,0.17,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":149,"pos":[13290,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":150,"pos":[13290,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":151,"pos":[13630,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":152,"pos":[13970,360],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ExpOpNode, AmplifyShaderEditor","id":153,"pos":[14310,115],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":154,"pos":[13970,115],"params":["Inherit","False","Property","_DeepDistance","03 Depth / deep color distance (m)","11","0","Create","False","0","0","0","True","0","False","Object","-1","","5","0","0.1","25","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":155,"pos":[14310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":156,"pos":[14650,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":157,"pos":[14650,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":158,"pos":[14650,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":159,"pos":[14650,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":160,"pos":[14990,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":161,"pos":[14990,115],"params":["Inherit","False","Constant","_Vector7","Vector 7","14","0","Create","True","0","0","0","False","0","False","Object","-1","","1,1,1,0","1,1,1,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":162,"pos":[15330,605],"params":["Inherit","False","Property","_WATER_DEPTH","Enable / 04 Depth absorption and tint","12","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT4","0,0,0,0","False","0","FLOAT4","0,0,0,0","False","2","FLOAT4","0,0,0,0","False","3","FLOAT4","0,0,0,0","False","4","FLOAT4","0,0,0,0","False","5","FLOAT4","0,0,0,0","False","6","FLOAT4","0,0,0,0","False","7","FLOAT4","0,0,0,0","False","8","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":163,"pos":[15670,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":164,"pos":[15670,850],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":165,"pos":[15330,115],"params":["Inherit","False","Property","_ShallowColor","03 Depth / shallow scattering","13","0","Create","False","0","0","0","True","0","False","Object","-1","","0.12,0.48,0.4,1","0.12,0.48,0.4,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":166,"pos":[15670,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":167,"pos":[15330,360],"params":["Inherit","False","Property","_DeepColor","03 Depth / deep scattering","14","0","Create","False","0","0","0","True","0","False","Object","-1","","0.012,0.13,0.19,1","0.012,0.13,0.19,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":168,"pos":[15670,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":169,"pos":[16010,115],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":170,"pos":[11590,115],"params":["Inherit","False","Constant","_Float22","Float 22","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":171,"pos":[11590,360],"params":["Inherit","False","Constant","_Float23","Float 23","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":172,"pos":[11930,115],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":173,"pos":[17250,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":174,"pos":[17590,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":175,"pos":[18950,1340],"params":["Inherit","False","FLOAT2","0","2","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":176,"pos":[17930,115],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":177,"pos":[18270,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":178,"pos":[18270,115],"params":["Inherit","False","Constant","_Float24","Float 24","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":179,"pos":[18610,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":180,"pos":[19630,115],"params":["Inherit","True","Property","_CausticTex","06 Caustics / seamless light pattern","15","0","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":181,"pos":[18610,115],"params":["Inherit","False","Property","_CausticScale","06 Caustics / tiling per meter","16","0","Create","False","0","0","0","True","0","False","Object","-1","","0.28","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":182,"pos":[18950,115],"params":["Inherit","False","Property","_CausticSpeed","06 Caustics / animation speed","17","0","Create","False","0","0","0","True","0","False","Object","-1","","0.65","0","0","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":183,"pos":[19290,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":184,"pos":[18610,360],"params":["Inherit","False","Constant","_Float25","Float 25","20","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":185,"pos":[18950,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":186,"pos":[19290,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":187,"pos":[19630,605],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":188,"pos":[18950,360],"params":["Inherit","False","Constant","_Vector8","Vector 8","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0.025,0.017,0,0","0.025,0.017,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":189,"pos":[19290,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":190,"pos":[19970,360],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","20","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":191,"pos":[18610,605],"params":["Inherit","False","Constant","_Float26","Float 26","21","0","Create","True","0","0","0","False","0","False","Object","-1","","1.17","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":192,"pos":[18950,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":193,"pos":[19290,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":194,"pos":[19630,850],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":195,"pos":[18950,605],"params":["Inherit","False","Constant","_Vector9","Vector 9","21","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.018,0.023,0,0","-0.018,0.023,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":196,"pos":[19290,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":197,"pos":[19970,605],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","21","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":198,"pos":[20310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":199,"pos":[19970,115],"params":["Inherit","False","Property","_CausticStrength","06 Caustics / brightness","18","0","Create","False","0","0","0","True","0","False","Object","-1","","3","0","0","6","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":200,"pos":[18610,850],"params":["Inherit","False","Property","_CausticFalloff","06 Caustics / depth extinction","19","0","Create","False","0","0","0","True","0","False","Object","-1","","0.45","0","0","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":201,"pos":[18950,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":202,"pos":[19290,1340],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ExpOpNode, AmplifyShaderEditor","id":203,"pos":[19630,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":204,"pos":[19970,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":205,"pos":[20310,115],"params":["Inherit","False","Property","_CausticTint","06 Caustics / light tint","20","0","Create","False","0","0","0","True","0","False","Object","-1","","1,0.94,0.72,1","1,0.94,0.72,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":206,"pos":[20650,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":207,"pos":[20310,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":208,"pos":[20650,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":209,"pos":[20990,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":210,"pos":[20650,115],"params":["Inherit","False","Constant","_Vector10","Vector 10","25","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":211,"pos":[20990,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":212,"pos":[21330,115],"params":["Inherit","False","Property","_WATER_CAUSTICS","Enable / 06 Underwater caustics (2 samples)","21","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":213,"pos":[18270,3055],"params":["Inherit","True","Property","_TextureSample4","Texture Sample 4","26","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":214,"pos":[17250,2320],"params":["Inherit","False","Constant","_Float27","Float 27","27","0","Create","True","0","0","0","False","0","False","Object","-1","","0.48","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":215,"pos":[17590,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":216,"pos":[17930,2565],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":217,"pos":[17250,2565],"params":["Inherit","False","Constant","_Vector11","Vector 11","27","0","Create","True","0","0","0","False","0","False","Object","-1","","0.029,0.014,0,0","0.029,0.014,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":218,"pos":[17590,2565],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":219,"pos":[17250,2810],"params":["Inherit","False","Property","_FoamWidth","04 Foam / shoreline width (m)","22","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5","0","0.02","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":220,"pos":[17590,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":221,"pos":[17930,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":222,"pos":[18270,3545],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":223,"pos":[18610,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":224,"pos":[18270,2320],"params":["Inherit","False","Constant","_Float28","Float 28","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.34","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":225,"pos":[18270,2565],"params":["Inherit","False","Constant","_Float29","Float 29","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.66","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":226,"pos":[18610,2810],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":227,"pos":[16910,2320],"params":["Inherit","False","Constant","_Float30","Float 30","28","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":228,"pos":[17250,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":229,"pos":[16910,2565],"params":["Inherit","False","Constant","_Float31","Float 31","28","0","Create","True","0","0","0","False","0","False","Object","-1","","1.8","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":230,"pos":[17250,4035],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":231,"pos":[17590,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":232,"pos":[17930,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":233,"pos":[17930,2320],"params":["Inherit","False","Constant","_Float32","Float 32","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":234,"pos":[18270,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":235,"pos":[18270,2810],"params":["Inherit","False","Constant","_Float33","Float 33","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":236,"pos":[18610,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":237,"pos":[18610,2320],"params":["Inherit","False","Constant","_Float34","Float 34","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.35","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":238,"pos":[18610,2565],"params":["Inherit","False","Constant","_Float35","Float 35","28","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":239,"pos":[18950,2810],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":240,"pos":[18950,2320],"params":["Inherit","False","Property","_FoamStrength","04 Foam / amount","23","0","Create","False","0","0","0","True","0","False","Object","-1","","0.7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":241,"pos":[18950,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":242,"pos":[19290,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":243,"pos":[19290,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":244,"pos":[19630,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":245,"pos":[19970,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":246,"pos":[19970,2320],"params":["Inherit","False","Constant","_Float36","Float 36","29","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":247,"pos":[20310,2320],"params":["Inherit","False","Property","_WATER_FOAM","Enable / 05 Shore foam (1 noise sample)","24","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT","0","False","0","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","5","FLOAT","0","False","6","FLOAT","0","False","7","FLOAT","0","False","8","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":248,"pos":[16910,2810],"params":["Inherit","False","Property","_FoamColor","04 Foam / color","25","0","Create","False","0","0","0","True","0","False","Object","-1","","0.82,0.91,0.88,1","0.82,0.91,0.88,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":249,"pos":[17250,3790],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":250,"pos":[22570,1340],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":251,"pos":[22570,1585],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":252,"pos":[22570,1830],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":253,"pos":[22570,115],"params":["Inherit","False","Constant","_Float37","Float 37","31","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":254,"pos":[22910,1340],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToCameraMatrix, AmplifyShaderEditor","id":255,"pos":[22910,115],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":256,"pos":[23250,850],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":257,"pos":[23590,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":258,"pos":[23250,115],"params":["Inherit","False","Property","_RefractionStrength","05 Optics / refraction","26","0","Create","False","0","0","0","True","0","False","Object","-1","","0.014","0","0","0.05","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":259,"pos":[22570,360],"params":["Inherit","False","Constant","_Float38","Float 38","32","0","Create","True","0","0","0","False","0","False","Object","-1","","0.65","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":260,"pos":[22910,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":261,"pos":[23250,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":262,"pos":[23590,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":263,"pos":[23930,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GrabScreenPosition, AmplifyShaderEditor","id":264,"pos":[23590,115],"params":["Inherit","False","0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":265,"pos":[23930,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":266,"pos":[24270,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":267,"pos":[24610,115],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ScreenColorNode, AmplifyShaderEditor","id":268,"pos":[24950,360],"params":["Inherit","False","Global","_GrabScreen0","Grab Screen 0","32","0","Create","True","0","0","0","False","0","False","","Object","-1","False","False","False","False","True","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","5","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":269,"pos":[25290,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":270,"pos":[24950,115],"params":["Inherit","False","Constant","_Float39","Float 39","32","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":271,"pos":[25290,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":272,"pos":[25630,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":273,"pos":[25970,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":274,"pos":[22570,850],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":275,"pos":[22910,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":276,"pos":[22910,360],"params":["Inherit","False","Property","_ScatteringStrength","05 Optics / scattering","27","0","Create","False","0","0","0","True","0","False","Object","-1","","0.75","0","0","1.5","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":277,"pos":[23250,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":278,"pos":[22910,605],"params":["Inherit","False","Constant","_Vector12","Vector 12","33","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":279,"pos":[23250,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":280,"pos":[23590,360],"params":["Inherit","False","Property","_WATER_SCATTER","Enable / 07 Water scattering","28","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":281,"pos":[26310,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":282,"pos":[26650,605],"params":["Inherit","False","Property","_WATER_REFRACTION","Enable / 08 Screen refraction and bottom","29","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":283,"pos":[26650,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":284,"pos":[26990,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":285,"pos":[26990,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":286,"pos":[27330,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":287,"pos":[28230,115],"params":["Inherit","False","Property","_ReflectionStrength","05 Optics / reflection","30","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":288,"pos":[28570,115],"params":["Inherit","False","Constant","_Float40","Float 40","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.02037","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":289,"pos":[28570,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":290,"pos":[28910,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":291,"pos":[28910,115],"params":["Inherit","False","Constant","_Float41","Float 41","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.028","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":292,"pos":[29250,115],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":293,"pos":[29590,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":294,"pos":[28230,360],"params":["Inherit","False","Property","_Smoothness","05 Optics / smoothness","31","0","Create","False","0","0","0","True","0","False","Object","-1","","0.94","0","0.5","0.99","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":295,"pos":[28230,605],"params":["Inherit","False","Constant","_Float42","Float 42","37","0","Create","True","0","0","0","False","0","False","Object","-1","","0.28","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":296,"pos":[28570,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":297,"pos":[28230,850],"params":["Inherit","False","Constant","_Float43","Float 43","37","0","Create","True","0","0","0","False","0","False","Object","-1","","0.08","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":298,"pos":[28570,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":299,"pos":[28910,1095],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":322,"pos":[1630,4035],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":323,"pos":[1970,4280],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":324,"pos":[1290,4035],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":325,"pos":[1970,4525],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":326,"pos":[4690,3545],"params":["Inherit","False","ase_ripples_enabled_326","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":327,"pos":[7630,360],"params":["Inherit","False","326","ase_ripples_enabled_326","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":328,"pos":[6050,605],"params":["Inherit","False","ase_enabled_wave_slope_x_328","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":329,"pos":[7970,1585],"params":["Inherit","False","328","ase_enabled_wave_slope_x_328","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":330,"pos":[7630,605],"params":["Inherit","False","326","ase_ripples_enabled_326","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":331,"pos":[6050,850],"params":["Inherit","False","ase_enabled_wave_slope_z_331","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":332,"pos":[7970,1830],"params":["Inherit","False","331","ase_enabled_wave_slope_z_331","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":333,"pos":[7970,115],"params":["Inherit","False","ase_view_to_camera_ws_333","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":334,"pos":[10910,850],"params":["Inherit","False","333","ase_view_to_camera_ws_333","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":335,"pos":[7970,360],"params":["Inherit","False","ase_view_to_camera_ws_335","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":336,"pos":[10910,1095],"params":["Inherit","False","335","ase_view_to_camera_ws_335","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":337,"pos":[7970,605],"params":["Inherit","False","ase_view_to_camera_ws_337","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":338,"pos":[10910,1340],"params":["Inherit","False","337","ase_view_to_camera_ws_337","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":339,"pos":[13630,360],"params":["Inherit","False","ase_optical_path_m_339","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":340,"pos":[13970,605],"params":["Inherit","False","339","ase_optical_path_m_339","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":341,"pos":[7970,850],"params":["Inherit","False","ase_view_to_camera_ws_341","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":342,"pos":[16910,360],"params":["Inherit","False","341","ase_view_to_camera_ws_341","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":343,"pos":[16910,115],"params":["Inherit","False","339","ase_optical_path_m_339","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":344,"pos":[390,360],"params":["Inherit","False","ase_world_position_344","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":345,"pos":[17250,360],"params":["Inherit","False","344","ase_world_position_344","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":346,"pos":[18270,360],"params":["Inherit","False","ase_underwater_position_ws_346","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":347,"pos":[18610,1340],"params":["Inherit","False","346","ase_underwater_position_ws_346","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":348,"pos":[390,605],"params":["Inherit","False","ase_world_position_348","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":349,"pos":[17930,360],"params":["Inherit","False","348","ase_world_position_348","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":350,"pos":[390,850],"params":["Inherit","False","ase_time_seconds_350","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":351,"pos":[18950,1585],"params":["Inherit","False","350","ase_time_seconds_350","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":352,"pos":[12270,360],"params":["Inherit","False","ase_shore_contact_fade_352","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":353,"pos":[19630,360],"params":["Inherit","False","352","ase_shore_contact_fade_352","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":354,"pos":[17250,3055],"params":["Inherit","False","301","ase_world_xz_301","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":355,"pos":[11930,360],"params":["Inherit","False","ase_depth_eye_355","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":356,"pos":[17250,3300],"params":["Inherit","False","355","ase_depth_eye_355","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":357,"pos":[16910,3055],"params":["Inherit","False","355","ase_depth_eye_355","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":358,"pos":[16910,3300],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":359,"pos":[18950,2565],"params":["Inherit","False","352","ase_shore_contact_fade_352","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":360,"pos":[9670,605],"params":["Inherit","False","ase_water_normal_ws_360","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":361,"pos":[22230,360],"params":["Inherit","False","360","ase_water_normal_ws_360","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":362,"pos":[22230,605],"params":["Inherit","False","360","ase_water_normal_ws_360","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":363,"pos":[22230,850],"params":["Inherit","False","360","ase_water_normal_ws_360","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":364,"pos":[22570,1095],"params":["Inherit","False","355","ase_depth_eye_355","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":365,"pos":[16010,360],"params":["Inherit","False","ase_enabled_transmittance_365","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":366,"pos":[22230,115],"params":["Inherit","False","365","ase_enabled_transmittance_365","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":367,"pos":[16350,115],"params":["Inherit","False","ase_depth_scattering_color_367","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":368,"pos":[22570,605],"params":["Inherit","False","367","ase_depth_scattering_color_367","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":369,"pos":[28230,1585],"params":["Inherit","False","352","ase_shore_contact_fade_352","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":370,"pos":[23930,360],"params":["Inherit","False","ase_scattering_enabled_370","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":371,"pos":[28230,1830],"params":["Inherit","False","370","ase_scattering_enabled_370","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":372,"pos":[17590,2810],"params":["Inherit","False","303","ase_water_clock_303","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":373,"pos":[21670,115],"params":["Inherit","False","ase_caustics_enabled_373","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":374,"pos":[24950,605],"params":["Inherit","False","373","ase_caustics_enabled_373","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":375,"pos":[25630,360],"params":["Inherit","False","365","ase_enabled_transmittance_365","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":376,"pos":[26310,115],"params":["Inherit","False","367","ase_depth_scattering_color_367","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":377,"pos":[10350,115],"params":["Inherit","False","ase_fresnel_enabled_377","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":378,"pos":[26310,360],"params":["Inherit","False","377","ase_fresnel_enabled_377","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":379,"pos":[20650,2320],"params":["Inherit","False","ase_foam_enabled_379","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":380,"pos":[26650,115],"params":["Inherit","False","379","ase_foam_enabled_379","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":381,"pos":[28910,360],"params":["Inherit","False","379","ase_foam_enabled_379","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":382,"pos":[28230,1340],"params":["Inherit","False","379","ase_foam_enabled_379","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":383,"pos":[17590,3545],"params":["Inherit","False","ase_foam_rgb_383","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":384,"pos":[28570,1585],"params":["Inherit","False","383","ase_foam_rgb_383","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":385,"pos":[28570,360],"params":["Inherit","False","379","ase_foam_enabled_379","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":386,"pos":[30150,605],"params":["Inherit","False","360","ase_water_normal_ws_360","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":387,"pos":[28910,850],"params":["Inherit","False","ase_surface_smoothness_387","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":388,"pos":[30150,850],"params":["Inherit","False","387","ase_surface_smoothness_387","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":389,"pos":[27670,115],"params":["Inherit","False","ase_water_transmission_emission_389","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":390,"pos":[30150,115],"params":["Inherit","False","389","ase_water_transmission_emission_389","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":392,"pos":[30150,1095],"params":["Inherit","False","391","ase_composite_alpha_391","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":394,"pos":[30150,360],"params":["Inherit","False","393","ase_object_wave_offset_393","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","ExtraPrePass","0","0","ExtraPrePass","6","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","0","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[30790,200],"params":["Float","False","True","-1","3","UnityEditor.ShaderGraphLitGUI","0","18","Water/DeepWater_URP_ASE","94348b07e5e8bab40bd6c8a1e3df54cd","True","ForwardLit","0","1","ForwardLit","21","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Transparent=RenderType","Queue=Transparent=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","True","1","5","False","","10","False","","1","1","False","","10","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","1","LightMode=UniversalForwardOnly","False","False","0","","0","0","Standard","49","Category","0","0","  Instanced Terrain Normals","1","0","Lighting Model","0","0","Workflow","0","0","Surface","1","0","  Keep Alpha","0","0","  Refraction Model","0","0","  Blend","0","0","Two Sided","1","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Fragment Normal Space","2","0","Forward Only","1","0","  Keep GBuffer","0","0","Transmission","0","0","  Transmission Shadow","0.5,False,","0","Translucency","0","0","  Translucency Strength","1,False,","0","  Normal Distortion","0.5,False,","0","  Scattering","2,False,","0","  Direct","0.9,False,","0","  Ambient","0.1,False,","0","  Shadow","0.5,False,","0","Cast Shadows","0","0","Receive Shadows","2","0","Specular Highlights","2","0","Environment Reflections","2","0","Receive SSAO","1","0","GPU Instancing","1","0","LOD CrossFade","1","0","Built-in Fog","1","0","_FinalColorxAlpha","0","0","Meta Pass","0","0","Override Baked GI","0","0","Extra Pre Pass","0","0","Tessellation","0","0","  Phong","0","0","  Strength","0.5,False,","0","  Type","0","0","  Tess","16,False,","0","  Min","10,False,","0","  Max","25,False,","0","  Edge Length","16,False,","0","  Max Displacement","25,False,","0","Write Depth","0","0","  Conservative","0","0","Vertex Position","1","0","Debug Display","1","0","Clear Coat","0","0","0","10","False","True","False","True","False","True","True","False","True","True","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","ShadowCaster","0","2","ShadowCaster","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","True","False","False","False","False","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":3,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","DepthOnly","0","3","DepthOnly","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","True","True","False","False","False","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","False","False","False","True","1","LightMode=DepthOnly","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":4,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","Meta","0","4","Meta","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Meta","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":5,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","Universal2D","0","5","Universal2D","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","True","1","5","False","","10","False","","1","1","False","","10","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","1","LightMode=Universal2D","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":6,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","DepthNormals","0","6","DepthNormals","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=DepthNormalsOnly","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":7,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","GBuffer","0","7","GBuffer","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","1","LightMode=UniversalGBuffer","False","True","10","d3d11","gles","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":8,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","SceneSelectionPass","0","8","SceneSelectionPass","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=SceneSelectionPass","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":9,"pos":[30790,200],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphLitGUI","0","1","New Amplify Shader","94348b07e5e8bab40bd6c8a1e3df54cd","True","ScenePickingPass","0","9","ScenePickingPass","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","False","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Lit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Picking","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[11,0,10,0]}
{"wire":[14,0,12,0]}
{"wire":[14,1,13,0]}
{"wire":[20,0,19,0]}
{"wire":[39,0,38,0]}
{"wire":[301,0,11,0]}
{"wire":[303,0,14,0]}
{"wire":[21,0,20,0]}
{"wire":[21,1,18,0]}
{"wire":[40,0,39,0]}
{"wire":[40,1,18,0]}
{"wire":[58,0,57,0]}
{"wire":[22,0,302,0]}
{"wire":[22,1,21,0]}
{"wire":[24,0,304,0]}
{"wire":[24,1,23,0]}
{"wire":[41,0,308,0]}
{"wire":[41,1,40,0]}
{"wire":[43,0,309,0]}
{"wire":[43,1,42,0]}
{"wire":[59,0,58,0]}
{"wire":[59,1,18,0]}
{"wire":[25,0,22,0]}
{"wire":[25,1,24,0]}
{"wire":[44,0,41,0]}
{"wire":[44,1,43,0]}
{"wire":[48,0,17,0]}
{"wire":[48,1,47,0]}
{"wire":[60,0,315,0]}
{"wire":[60,1,59,0]}
{"wire":[62,0,316,0]}
{"wire":[62,1,61,0]}
{"wire":[305,0,21,0]}
{"wire":[312,0,40,0]}
{"wire":[27,0,25,0]}
{"wire":[27,1,26,0]}
{"wire":[32,0,27,0]}
{"wire":[46,0,44,0]}
{"wire":[46,1,45,0]}
{"wire":[51,0,46,0]}
{"wire":[63,0,60,0]}
{"wire":[63,1,62,0]}
{"wire":[310,0,48,0]}
{"wire":[317,0,59,0]}
{"wire":[29,0,17,0]}
{"wire":[29,1,28,0]}
{"wire":[30,0,27,0]}
{"wire":[33,0,32,0]}
{"wire":[33,1,29,0]}
{"wire":[34,0,306,0]}
{"wire":[36,0,307,0]}
{"wire":[49,0,46,0]}
{"wire":[52,0,51,0]}
{"wire":[52,1,48,0]}
{"wire":[53,0,313,0]}
{"wire":[55,0,314,0]}
{"wire":[65,0,63,0]}
{"wire":[65,1,64,0]}
{"wire":[70,0,65,0]}
{"wire":[31,0,30,0]}
{"wire":[31,1,29,0]}
{"wire":[35,0,33,0]}
{"wire":[35,1,34,0]}
{"wire":[37,0,33,0]}
{"wire":[37,1,36,0]}
{"wire":[50,0,49,0]}
{"wire":[50,1,311,0]}
{"wire":[54,0,52,0]}
{"wire":[54,1,53,0]}
{"wire":[56,0,52,0]}
{"wire":[56,1,55,0]}
{"wire":[67,0,17,0]}
{"wire":[67,1,66,0]}
{"wire":[68,0,65,0]}
{"wire":[71,0,70,0]}
{"wire":[71,1,67,0]}
{"wire":[72,0,318,0]}
{"wire":[74,0,319,0]}
{"wire":[69,0,68,0]}
{"wire":[69,1,67,0]}
{"wire":[73,0,71,0]}
{"wire":[73,1,72,0]}
{"wire":[75,0,71,0]}
{"wire":[75,1,74,0]}
{"wire":[76,0,31,0]}
{"wire":[76,1,50,0]}
{"wire":[78,0,35,0]}
{"wire":[78,1,54,0]}
{"wire":[80,0,37,0]}
{"wire":[80,1,56,0]}
{"wire":[77,0,76,0]}
{"wire":[77,1,69,0]}
{"wire":[79,0,78,0]}
{"wire":[79,1,73,0]}
{"wire":[81,0,80,0]}
{"wire":[81,1,75,0]}
{"wire":[82,0,77,0]}
{"wire":[82,1,79,0]}
{"wire":[82,2,81,0]}
{"wire":[82,3,15,0]}
{"wire":[84,1,83,0]}
{"wire":[84,0,82,0]}
{"wire":[320,0,15,0]}
{"wire":[85,0,84,0]}
{"wire":[88,0,321,0]}
{"wire":[88,1,85,0]}
{"wire":[88,2,321,0]}
{"wire":[88,3,321,0]}
{"wire":[90,0,89,0]}
{"wire":[90,1,88,0]}
{"wire":[91,0,90,0]}
{"wire":[391,0,300,0]}
{"wire":[393,0,91,0]}
{"wire":[86,0,84,0]}
{"wire":[87,0,84,0]}
{"wire":[95,0,322,0]}
{"wire":[95,1,93,0]}
{"wire":[97,0,96,0]}
{"wire":[98,0,95,0]}
{"wire":[98,2,97,0]}
{"wire":[98,1,323,0]}
{"wire":[99,0,324,0]}
{"wire":[101,0,93,0]}
{"wire":[101,1,100,0]}
{"wire":[102,0,99,0]}
{"wire":[102,1,101,0]}
{"wire":[104,0,103,0]}
{"wire":[105,0,102,0]}
{"wire":[105,2,104,0]}
{"wire":[105,1,325,0]}
{"wire":[106,0,92,0]}
{"wire":[106,1,98,0]}
{"wire":[107,0,92,0]}
{"wire":[107,1,105,0]}
{"wire":[108,0,106,0]}
{"wire":[109,0,107,0]}
{"wire":[110,0,108,0]}
{"wire":[110,1,109,0]}
{"wire":[112,0,110,0]}
{"wire":[112,1,111,0]}
{"wire":[113,0,112,0]}
{"wire":[113,1,94,0]}
{"wire":[115,0,114,0]}
{"wire":[116,1,115,0]}
{"wire":[116,0,113,0]}
{"wire":[117,0,327,0]}
{"wire":[118,0,329,0]}
{"wire":[118,1,117,0]}
{"wire":[119,0,118,0]}
{"wire":[120,0,330,0]}
{"wire":[121,0,332,0]}
{"wire":[121,1,120,0]}
{"wire":[122,0,121,0]}
{"wire":[124,0,119,0]}
{"wire":[124,1,123,0]}
{"wire":[124,2,122,0]}
{"wire":[125,0,124,0]}
{"wire":[127,0,125,0]}
{"wire":[127,4,126,0]}
{"wire":[127,1,128,0]}
{"wire":[127,2,129,0]}
{"wire":[127,3,130,0]}
{"wire":[132,1,131,0]}
{"wire":[132,0,127,0]}
{"wire":[135,0,133,0]}
{"wire":[135,1,134,0]}
{"wire":[137,0,135,0]}
{"wire":[137,1,136,0]}
{"wire":[139,0,334,0]}
{"wire":[139,1,336,0]}
{"wire":[139,2,338,0]}
{"wire":[139,3,138,0]}
{"wire":[141,0,140,0]}
{"wire":[141,1,139,0]}
{"wire":[142,0,141,0]}
{"wire":[143,0,142,0]}
{"wire":[145,0,143,0]}
{"wire":[145,1,144,0]}
{"wire":[146,0,137,0]}
{"wire":[146,1,145,0]}
{"wire":[149,0,148,0]}
{"wire":[150,0,146,0]}
{"wire":[150,1,147,0]}
{"wire":[151,0,150,0]}
{"wire":[151,1,149,0]}
{"wire":[152,0,151,0]}
{"wire":[153,0,152,0]}
{"wire":[155,0,340,0]}
{"wire":[155,1,154,0]}
{"wire":[156,0,155,0]}
{"wire":[157,0,153,0]}
{"wire":[158,0,153,0]}
{"wire":[159,0,153,0]}
{"wire":[160,0,157,0]}
{"wire":[160,1,158,0]}
{"wire":[160,2,159,0]}
{"wire":[160,3,156,0]}
{"wire":[162,1,161,0]}
{"wire":[162,0,160,0]}
{"wire":[163,0,162,0]}
{"wire":[164,0,162,0]}
{"wire":[166,0,165,0]}
{"wire":[168,0,167,0]}
{"wire":[169,0,166,0]}
{"wire":[169,1,168,0]}
{"wire":[169,2,164,0]}
{"wire":[172,0,137,0]}
{"wire":[172,1,170,0]}
{"wire":[172,2,171,0]}
{"wire":[173,0,342,0]}
{"wire":[173,1,343,0]}
{"wire":[174,0,345,0]}
{"wire":[174,1,173,0]}
{"wire":[175,0,347,0]}
{"wire":[176,0,174,0]}
{"wire":[177,0,349,0]}
{"wire":[177,1,176,0]}
{"wire":[179,0,177,0]}
{"wire":[179,1,178,0]}
{"wire":[183,0,351,0]}
{"wire":[183,1,182,0]}
{"wire":[185,0,181,0]}
{"wire":[185,1,184,0]}
{"wire":[186,0,175,0]}
{"wire":[186,1,185,0]}
{"wire":[187,0,186,0]}
{"wire":[187,2,189,0]}
{"wire":[187,1,183,0]}
{"wire":[189,0,188,0]}
{"wire":[190,0,180,0]}
{"wire":[190,1,187,0]}
{"wire":[192,0,181,0]}
{"wire":[192,1,191,0]}
{"wire":[193,0,175,0]}
{"wire":[193,1,192,0]}
{"wire":[194,0,193,0]}
{"wire":[194,2,196,0]}
{"wire":[194,1,183,0]}
{"wire":[196,0,195,0]}
{"wire":[197,0,180,0]}
{"wire":[197,1,194,0]}
{"wire":[198,0,190,1]}
{"wire":[198,1,197,1]}
{"wire":[201,0,179,0]}
{"wire":[201,1,200,0]}
{"wire":[202,0,201,0]}
{"wire":[203,0,202,0]}
{"wire":[204,0,203,0]}
{"wire":[204,1,353,0]}
{"wire":[206,0,205,0]}
{"wire":[207,0,199,0]}
{"wire":[207,1,204,0]}
{"wire":[208,0,198,0]}
{"wire":[208,1,207,0]}
{"wire":[209,0,206,0]}
{"wire":[209,1,208,0]}
{"wire":[211,0,210,0]}
{"wire":[212,1,211,0]}
{"wire":[212,0,209,0]}
{"wire":[213,0,92,0]}
{"wire":[213,1,216,0]}
{"wire":[215,0,354,0]}
{"wire":[215,1,214,0]}
{"wire":[216,0,215,0]}
{"wire":[216,2,218,0]}
{"wire":[216,1,372,0]}
{"wire":[218,0,217,0]}
{"wire":[220,0,356,0]}
{"wire":[220,1,219,0]}
{"wire":[221,0,220,0]}
{"wire":[222,0,221,0]}
{"wire":[223,0,222,0]}
{"wire":[223,1,222,0]}
{"wire":[226,0,213,3]}
{"wire":[226,1,224,0]}
{"wire":[226,2,225,0]}
{"wire":[228,0,357,0]}
{"wire":[228,1,227,0]}
{"wire":[230,0,358,0]}
{"wire":[230,1,229,0]}
{"wire":[231,0,228,0]}
{"wire":[231,1,230,0]}
{"wire":[232,0,231,0]}
{"wire":[234,0,232,0]}
{"wire":[234,1,233,0]}
{"wire":[236,0,234,0]}
{"wire":[236,1,235,0]}
{"wire":[239,0,237,0]}
{"wire":[239,1,238,0]}
{"wire":[239,2,236,0]}
{"wire":[241,0,223,0]}
{"wire":[241,1,226,0]}
{"wire":[242,0,241,0]}
{"wire":[242,1,239,0]}
{"wire":[243,0,240,0]}
{"wire":[243,1,359,0]}
{"wire":[244,0,242,0]}
{"wire":[244,1,243,0]}
{"wire":[245,0,244,0]}
{"wire":[247,1,246,0]}
{"wire":[247,0,245,0]}
{"wire":[249,0,248,0]}
{"wire":[250,0,361,0]}
{"wire":[251,0,362,0]}
{"wire":[252,0,363,0]}
{"wire":[254,0,250,0]}
{"wire":[254,1,251,0]}
{"wire":[254,2,252,0]}
{"wire":[254,3,253,0]}
{"wire":[256,0,255,0]}
{"wire":[256,1,254,0]}
{"wire":[257,0,256,0]}
{"wire":[260,0,364,0]}
{"wire":[260,1,259,0]}
{"wire":[261,0,260,0]}
{"wire":[262,0,258,0]}
{"wire":[262,1,261,0]}
{"wire":[263,0,257,0]}
{"wire":[263,1,262,0]}
{"wire":[265,0,264,0]}
{"wire":[266,0,265,0]}
{"wire":[266,1,263,0]}
{"wire":[267,0,266,0]}
{"wire":[268,0,267,0]}
{"wire":[269,0,268,0]}
{"wire":[271,0,270,0]}
{"wire":[271,1,374,0]}
{"wire":[272,0,269,0]}
{"wire":[272,1,271,0]}
{"wire":[273,0,272,0]}
{"wire":[273,1,375,0]}
{"wire":[274,0,366,0]}
{"wire":[275,0,368,0]}
{"wire":[275,1,274,0]}
{"wire":[277,0,275,0]}
{"wire":[277,1,276,0]}
{"wire":[279,0,278,0]}
{"wire":[280,1,279,0]}
{"wire":[280,0,277,0]}
{"wire":[281,0,273,0]}
{"wire":[281,1,280,0]}
{"wire":[282,1,376,0]}
{"wire":[282,0,281,0]}
{"wire":[283,0,378,0]}
{"wire":[284,0,282,0]}
{"wire":[284,1,283,0]}
{"wire":[285,0,380,0]}
{"wire":[286,0,284,0]}
{"wire":[286,1,285,0]}
{"wire":[289,0,287,0]}
{"wire":[289,1,369,0]}
{"wire":[290,0,288,0]}
{"wire":[290,1,289,0]}
{"wire":[292,0,290,0]}
{"wire":[292,1,291,0]}
{"wire":[292,2,381,0]}
{"wire":[293,0,292,0]}
{"wire":[293,1,292,0]}
{"wire":[293,2,292,0]}
{"wire":[296,0,294,0]}
{"wire":[296,1,295,0]}
{"wire":[296,2,382,0]}
{"wire":[298,0,371,0]}
{"wire":[298,1,297,0]}
{"wire":[299,0,298,0]}
{"wire":[299,1,384,0]}
{"wire":[299,2,385,0]}
{"wire":[326,0,116,0]}
{"wire":[328,0,86,0]}
{"wire":[331,0,87,0]}
{"wire":[333,0,126,1]}
{"wire":[335,0,126,2]}
{"wire":[337,0,126,3]}
{"wire":[339,0,146,0]}
{"wire":[341,0,126,0]}
{"wire":[344,0,10,0]}
{"wire":[346,0,174,0]}
{"wire":[348,0,10,2]}
{"wire":[350,0,12,0]}
{"wire":[352,0,172,0]}
{"wire":[355,0,137,0]}
{"wire":[360,0,125,0]}
{"wire":[365,0,163,0]}
{"wire":[367,0,169,0]}
{"wire":[370,0,280,0]}
{"wire":[373,0,212,0]}
{"wire":[377,0,132,0]}
{"wire":[379,0,247,0]}
{"wire":[383,0,249,0]}
{"wire":[387,0,296,0]}
{"wire":[389,0,286,0]}
{"wire":[1,0,299,0]}
{"wire":[1,1,386,0]}
{"wire":[1,9,293,0]}
{"wire":[1,4,388,0]}
{"wire":[1,2,390,0]}
{"wire":[1,6,392,0]}
{"wire":[1,8,394,0]}
ASEEND*/
//CHKSM=1ECDE6C3BF777B9EACFA85ABEA8E0F1865216354