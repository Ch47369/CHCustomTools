// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "CH/Paths/Custom2TexV2/URP"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.BlendMode)] _Src( "Src", Float ) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _Dst( "Dst", Float ) = 10
		[Enum(Off,0,On,1)] _ZWriteMode( "ZWriteMode", Float ) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode( "CullMode", Float ) = 2
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


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1.0

		//[HideInInspector] _AlphaClip("__clip", Float) = 0.0
	}

	SubShader
	{
		PackageRequirements
		{
			"com.unity.render-pipelines.universal": "[14.0,15.0]"
		}

		

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

	LOD 0

		ZWrite On
		ZClip True
		Cull [_CullMode]
		AlphaToMask Off
		ColorMask RGBA
		Blend One Zero, One Zero
		BlendOp Add, Add

		

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
			
			Name "Unlit"
			

			ZWrite [_ZWriteMode]
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Blend [_Src] [_Dst], One OneMinusSrcAlpha
			BlendOp Add, Add

			

			HLSLPROGRAM

			

			#define _NORMAL_DROPOFF_TS 1
			#pragma shader_feature_local_fragment _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_WORLD_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION


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
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				half4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 positionWSAndFogFactor : TEXCOORD0;
				half3 normalWS : TEXCOORD1;
				half4 tangentWS : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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

				output.ase_texcoord3.xy = input.ase_texcoord.xy;
				output.ase_texcoord4 = input.ase_texcoord1;
				output.ase_color = input.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS, input.tangentOS );

				float fogFactor = 0;
				#if defined(ASE_FOG) && !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
				#endif

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				output.positionWSAndFogFactor = float4( vertexInput.positionWS, fogFactor );
				output.normalWS = normalInput.normalWS;
				output.tangentWS = half4( normalInput.tangentWS, ( input.tangentOS.w > 0.0 ? 1.0 : -1.0 ) * GetOddNegativeScale() );;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				output.ase_color = input.ase_color;
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
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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
					float4 shadowCoord = TransformWorldToShadowCoord( input.positionWSAndFogFactor.xyz );
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				// @diogo: mikktspace compliant
				float renormFactor = 1.0 / max( FLT_MIN, length( input.normalWS ) );

				float3 PositionWS = input.positionWSAndFogFactor.xyz;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				half3 ViewDirWS = GetWorldSpaceNormalizeViewDir( PositionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );
				float3 TangentWS = input.tangentWS.xyz * renormFactor;
				float3 BitangentWS = cross( input.normalWS, input.tangentWS.xyz ) * input.tangentWS.w * renormFactor;
				float3 NormalWS = input.normalWS * renormFactor;

				half2 uv_DissolveMap = input.ase_texcoord3.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord4;
				texCoord228.xy = input.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half4 Dissolve_RGB137 = ( smoothstepResult93 * _EdgeColor );
				half3 appendResult155 = (half3(Dissolve_RGB137.rgb));
				half2 uv_MainTex = input.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord3.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord4;
				texCoord73.xy = input.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord3.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half3 appendResult156 = (half3(BlendColor111.rgb));
				half Dissolve_A126 = smoothstepResult93;
				half3 lerpResult102 = lerp( appendResult155 , appendResult156 , Dissolve_A126);
				half3 lerpResult89 = lerp( float3( 1,1,1 ) , (input.ase_color).rgb , _VertexColor);
				half3 Vertex_RGB130 = lerpResult89;
				half3 RGB123 = ( lerpResult102 * Vertex_RGB130 );
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				half lerpResult264 = lerp( 1.0 , lerpResult259 , saturate( ( _SoftParticleOnARGBA - 1.0 ) ));
				
				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord3.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				half clampResult233 = clamp( distance( PositionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( RGB123 * lerpResult264 );
				float3 Normal = float3(0, 0, 1);
				float Alpha = ( A135 * lerpResult259 );
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
					float AlphaClipThresholdShadow = 0.5;
				#endif


				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
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
				inputData.normalWS = NormalWS;
				inputData.viewDirectionWS = ViewDirWS;

				#ifdef ASE_FOG
					inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.positionWSAndFogFactor.w);
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(input.positionCS, Color);
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						Color.rgb = MixFogColor(Color.rgb, half3(0,0,0), inputData.fogCoord);
					#else
						Color.rgb = MixFog(Color.rgb, inputData.fogCoord);
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
					return half4( Color, Alpha );
				#else
					return half4( Color, OutputAlpha( Alpha, isTransparent ) );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW // @diogo: removed _vertex for POM node

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


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
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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


			float3 _LightDirection;
			float3 _LightPosition;

			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			PackedVaryings VertexFunction( Attributes input )
			{
				PackedVaryings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( output );

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				output.ase_texcoord2.xyz = ase_positionWS;
				
				output.ase_color = input.ase_color;
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord1 = input.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord.zw = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				float3 positionWS = TransformObjectToWorld( input.positionOS.xyz );
				half3 normalWS = TransformObjectToWorldDir(input.normalOS);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				output.positionCS = ASE_ADJUST_CLIP_POSITION( positionCS );
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_color = input.ase_color;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
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
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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

			half4 frag(PackedVaryings input
						#if defined( ASE_WRITE_DEPTH )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = input.ase_texcoord.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord1;
				texCoord228.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = input.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord1;
				texCoord73.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				float Alpha = ( A135 * lerpResult259 );
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
					float AlphaClipThresholdShadow = 0.5;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					#if defined( _ALPHATEST_SHADOW_ON )
						AlphaDiscard( Alpha, AlphaClipThresholdShadow );
					#else
						AlphaDiscard( Alpha, AlphaClipThreshold );
					#endif
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
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


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
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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


			float3 _LightDirection;
			float3 _LightPosition;

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

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				output.ase_texcoord2.xyz = ase_positionWS;
				
				output.ase_color = input.ase_color;
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord1 = input.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord.zw = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_color = input.ase_color;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
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
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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

			half4 frag(PackedVaryings input
						#if defined( ASE_WRITE_DEPTH )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = input.ase_texcoord.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord1;
				texCoord228.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = input.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord1;
				texCoord73.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				float Alpha = ( A135 * lerpResult259 );
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
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			
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
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			int _ObjectId;
			int _PassValue;

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

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				output.ase_texcoord2.xyz = ase_positionWS;
				float4 ase_positionCS = TransformObjectToHClip( ( input.positionOS ).xyz );
				float4 screenPos = ComputeScreenPos( ase_positionCS );
				output.ase_texcoord3 = screenPos;
				
				output.ase_color = input.ase_color;
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord1 = input.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord.zw = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_color = input.ase_color;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
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
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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

			half4 frag(PackedVaryings input ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = input.ase_texcoord.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord1;
				texCoord228.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = input.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord1;
				texCoord73.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float4 screenPos = input.ase_texcoord3;
				half4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_positionSSNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ase_positionSSNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				surfaceDescription.Alpha = ( A135 * lerpResult259 );
				#if defined( _ALPHATEST_ON )
					surfaceDescription.AlphaClipThreshold = _Cutoff;
				#endif

				#ifdef _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19913
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
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
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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


			float ASELinearEyeDepth( float rawDepth )
			{
				#if UNITY_REVERSED_Z
				float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#else
				float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
				#endif
				return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth, _ZBufferParams ) : orthoDepth;
			}
			

			float4 _SelectionID;

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

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				output.ase_texcoord2.xyz = ase_positionWS;
				float4 ase_positionCS = TransformObjectToHClip( ( input.positionOS ).xyz );
				float4 screenPos = ComputeScreenPos( ase_positionCS );
				output.ase_texcoord3 = screenPos;
				
				output.ase_color = input.ase_color;
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord1 = input.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord.zw = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = ASE_ADJUST_CLIP_POSITION( vertexInput.positionCS );
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_color = input.ase_color;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
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
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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

			half4 frag(PackedVaryings input ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = input.ase_texcoord.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord1;
				texCoord228.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = input.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord1;
				texCoord73.xy = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float4 screenPos = input.ase_texcoord3;
				half4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_positionSSNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ase_positionSSNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				surfaceDescription.Alpha = ( A135 * lerpResult259 );
				#if defined( _ALPHATEST_ON )
					surfaceDescription.AlphaClipThreshold = _Cutoff;
				#endif

				#ifdef _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = unity_SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			

        	#define _NORMAL_DROPOFF_TS 1
        	#pragma multi_compile_instancing
        	#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
        	#define _SURFACE_TYPE_TRANSPARENT 1
        	#define ASE_VERSION 19913
        	#define ASE_SRP_VERSION 140008
        	#define REQUIRE_DEPTH_TEXTURE 1


			

        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS
			#define VARYINGS_NEED_TANGENT_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			
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
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED


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
				half4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				half3 normalWS : TEXCOORD0;
				float4 tangentWS : TEXCOORD1;
				float4 ase_color : COLOR;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
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
			float _CullMode;
			float _ZWriteMode;
			float _MainTexIntensity;
			float _DistanceOnOff;
			float _AlphaClip;
			float _Cutoff;
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

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				output.ase_texcoord4.xyz = ase_positionWS;
				
				output.ase_color = input.ase_color;
				output.ase_texcoord2.xy = input.ase_texcoord.xy;
				output.ase_texcoord3 = input.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord2.zw = 0;
				output.ase_texcoord4.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

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
				output.normalWS = normalInput.normalWS;
				output.tangentWS = float4( normalInput.tangentWS, ( input.tangentOS.w > 0.0 ? 1.0 : -1.0 ) * GetOddNegativeScale() );
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				half4 tangentOS : TANGENT;
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

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.ase_color = input.ase_color;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
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
				output.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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

			void frag(PackedVaryings input
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

				// @diogo: mikktspace compliant
				float renormFactor = 1.0 / max( FLT_MIN, length( input.normalWS ) );

				float3 NormalWS = input.normalWS * renormFactor;
				float3 TangentWS = input.tangentWS.xyz * renormFactor;
				float3 BitangentWS = cross( input.normalWS, input.tangentWS.xyz ) * input.tangentWS.w * renormFactor;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				half lerpResult92 = lerp( 1.0 , (input.ase_color).a , _VertexColor);
				half Vertex_A131 = lerpResult92;
				half2 uv_DissolveMap = input.ase_texcoord2.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
				half4 texCoord228 = input.ase_texcoord3;
				texCoord228.xy = input.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomDate206 = _CustomDate1;
				half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
				half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
				half Dissolve_A126 = smoothstepResult93;
				half2 uv_MainTex = input.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 uv_DisturbanceTex = input.ase_texcoord2.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
				half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
				half4 texCoord73 = input.ase_texcoord3;
				texCoord73.xy = input.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
				half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
				half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
				half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
				half2 uv_AddTex = input.ase_texcoord2.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
				half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
				half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
				half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
				half4 BlendColor111 = lerpResult78;
				half4 break116 = BlendColor111;
				half lerpResult76 = lerp( break116.r , break116.a , _RA);
				half2 uv_MaskTex = input.ase_texcoord2.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
				half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
				float3 ase_positionWS = input.ase_texcoord4.xyz;
				half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
				half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
				half DistanceFade244 = lerpResult241;
				half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
				half A135 = lerpResult248;
				float screenDepth258 = ASELinearEyeDepth( SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ) );
				half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
				half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
				

				float3 Normal = float3(0, 0, 1);
				float Alpha = ( A135 * lerpResult259 );
				#if defined( _ALPHATEST_ON )
					float AlphaClipThreshold = _Cutoff;
				#endif

				#if defined( ASE_WRITE_DEPTH )
					input.positionCS.z = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
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

	
	}
	

	

	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
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
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":48,"pos":[2584,-184],"params":["Float","False","Property","_CullMode","CullMode","3","1","[Enum]","Create","True","0","0","1","UnityEngine.Rendering.CullMode","True","0","False","Object","-1","","2","2","0","0","0","1","FLOAT","0"]}
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
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":270,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","0","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":271,"pos":[2568,-8],"params":["Float","False","True","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","19","CH/Paths/Custom2TexV2/URP","2992e84f91cbeb14eab234972e07ea9d","True","Unlit","0","1","Unlit","11","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","True","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Transparent=RenderType","Queue=Transparent=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","True","1","5","True","","10","True","","1","1","False","","10","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","True","","True","3","False","","True","True","0","False","","0","False","","False","True","0","False","False","0","","0","0","Standard","28","Surface","1","0","  Keep Alpha","0","0","  Blend","0","0","Two Sided","1","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Fragment Normal Space","0","0","Forward Only","0","0","Cast Shadows","1","0","Receive Shadows","2","0","Receive SSAO","1","0","GPU Instancing","1","0","LOD CrossFade","1","0","Built-in Fog","0","0","Meta Pass","0","0","Extra Pre Pass","0","0","Tessellation","0","0","  Phong","0","0","  Strength","0.5,False,","0","  Type","0","0","  Tess","16,False,","0","  Min","10,False,","0","  Max","25,False,","0","  Edge Length","16,False,","0","  Max Displacement","25,False,","0","Write Depth","0","0","  Conservative","0","0","Vertex Position","1","0","0","10","False","True","True","True","False","False","True","True","True","False","False","","False","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":272,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","ShadowCaster","0","2","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","True","False","False","False","False","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":273,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","DepthOnly","0","3","DepthOnly","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","True","True","False","False","False","0","False","","False","False","False","False","False","False","False","False","False","True","1","False","","False","False","False","True","1","LightMode=DepthOnly","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":274,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","Meta","0","4","Meta","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Meta","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":275,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","Universal2D","0","5","Universal2D","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","1","LightMode=Universal2D","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":276,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","SceneSelectionPass","0","6","SceneSelectionPass","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=SceneSelectionPass","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":277,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","ScenePickingPass","0","7","ScenePickingPass","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Picking","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":278,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","DepthNormals","0","8","DepthNormals","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=DepthNormals","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":279,"pos":[2568,-8],"params":["Float","False","False","-1","3","UnityEditor.ShaderGraphUnlitGUI","0","1","New Amplify Shader","2992e84f91cbeb14eab234972e07ea9d","True","DepthNormalsOnly","0","9","DepthNormalsOnly","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","False","True","1","False","","True","4","RenderPipeline=UniversalPipeline","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","UniversalMaterialType=Unlit","True","5","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=DepthNormalsOnly","False","True","9","d3d11","metal","vulkan","xboxone","xboxseries","playstation","ps4","ps5","switch","0","","0","0","Standard","0","True","0"]}
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
{"wire":[271,2,260,0]}
{"wire":[271,3,265,0]}
ASEEND*/
//CHKSM=3643C2BE1488089DFE7BE7D1A1606EABC3D792CA