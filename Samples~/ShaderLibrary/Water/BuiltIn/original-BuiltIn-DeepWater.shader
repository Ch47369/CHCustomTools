// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Water/DeepWater_ASE"
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

		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0

		//_InstancedTerrainNormals("Specular Highlights", Float) = 1.0
	}

	SubShader
	{
		

		

		Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="False" }

	LOD 0

		Cull Back
		AlphaToMask Off
		ZWrite Off
		ZClip True
		ZTest LEqual
		ColorMask RGBA
		Blend One Zero, One Zero
		BlendOp Add, Add
		Offset 0 , 0

		

		Blend One Zero, One Zero
		BlendOp Add, Add
		

		CGINCLUDE
			#pragma target 3.5
			// ensure rendering platforms toggle list is visible

			#ifndef GLOBAL_HEADER_INCLUDED
			#define GLOBAL_HEADER_INCLUDED
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

			float4 ComputeClipSpacePosition( float2 screenPosNorm, float deviceDepth )
			{
				float4 positionCS = float4( screenPosNorm * 2.0 - 1.0, deviceDepth, 1.0 );
			#if UNITY_UV_STARTS_AT_TOP
				positionCS.y = -positionCS.y;
			#endif
				return positionCS;
			}
			#endif
		ENDCG

		GrabPass{ }

		Pass
		{
			
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }

			Blend One Zero, One Zero
			BlendOp Add, Add

			CGPROGRAM
				#define ASE_GEOMETRY
				#define ASE_RECEIVE_SHADOWS
				#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
				#pragma shader_feature_local_fragment _GLOSSYREFLECTIONS_OFF
				#pragma multi_compile_instancing
				#pragma multi_compile_fog
				#define ASE_FOG
				#define _SPECULAR_SETUP 1
				#define UNITY_STANDARD_USE_DITHER_MASK 1
				#define ASE_FRAGMENT_NORMAL 2
				#define ASE_VERSION 19913
				#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
				#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
				#else
				#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
				#endif
				#define ASE_USING_SAMPLING_MACROS 1

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fwdbase
				#ifndef UNITY_PASS_FORWARDBASE
					#define UNITY_PASS_FORWARDBASE
				#endif
				#include "HLSLSupport.cginc"
				#if defined( ASE_GEOMETRY ) || defined( ASE_IMPOSTOR )
					#ifndef UNITY_INSTANCED_LOD_FADE
						#define UNITY_INSTANCED_LOD_FADE
					#endif
					#ifndef UNITY_INSTANCED_SH
						#define UNITY_INSTANCED_SH
					#endif
					#ifndef UNITY_INSTANCED_LIGHTMAPSTS
						#define UNITY_INSTANCED_LIGHTMAPSTS
					#endif
				#endif
				#include "UnityShaderVariables.cginc"
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "UnityPBSLighting.cginc"
				#include "AutoLight.cginc"

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
				#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
				#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
				#else//ASE Sampling Macros
				#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
				#endif//ASE Sampling Macros
				


				#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
					#define ASE_SV_DEPTH SV_DepthLessEqual
					#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
				#else
					#define ASE_SV_DEPTH SV_Depth
					#define ASE_SV_POSITION_QUALIFIERS
				#endif

				struct appdata
				{
					float4 vertex : POSITION;
					half3 normal : NORMAL;
					half4 tangent : TANGENT;
					float4 texcoord : TEXCOORD0;
					float4 texcoord1 : TEXCOORD1;
					float4 texcoord2 : TEXCOORD2;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS float4 pos : SV_POSITION;
					float4 worldPos : TEXCOORD0; // xyz = positionWS, w = fogCoord
					half3 normalWS : TEXCOORD1;
					float4 tangentWS : TEXCOORD2; // holds terrainUV ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					half4 ambientOrLightmapUV : TEXCOORD3;
					UNITY_LIGHTING_COORDS( 4, 5 )
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

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

				uniform float _WaveScale;
				uniform float _WaveSpeed;
				uniform float _WaveHeight;
				uniform float4 _ShallowColor;
				uniform float4 _DeepColor;
				UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
				uniform float4 _CameraDepthTexture_TexelSize;
				uniform float _Density;
				uniform float4 _Absorption;
				uniform float _DeepDistance;
				uniform float _ScatteringStrength;
				uniform float4 _FoamColor;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_RippleSlope);
				uniform float _FoamWidth;
				SamplerState sampler_RippleSlope;
				uniform float _FoamStrength;
				uniform float _RippleScale;
				uniform float _RippleStrength;
				uniform float _ReflectionStrength;
				uniform float _Smoothness;
				ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
				uniform float _RefractionStrength;
				uniform float4 _CausticTint;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_CausticTex);
				uniform float _CausticSpeed;
				uniform float _CausticScale;
				SamplerState sampler_CausticTex;
				uniform float _CausticStrength;
				uniform float _CausticFalloff;


				float ASELinearEyeDepth( float rawDepth )
				{
					#if UNITY_REVERSED_Z
					float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#else
					float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#endif
					return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth ) : orthoDepth;
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
				

				v2f VertexFunction( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID(v);
					v2f o;
					UNITY_INITIALIZE_OUTPUT(v2f,o);
					UNITY_TRANSFER_INSTANCE_ID(v,o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					float ase_wave_zero_318318 = 0.0;
					float3 ase_positionWS = mul( unity_ObjectToWorld, float4( ( v.vertex ).xyz, 1 ) ).xyz;
					float2 ase_world_xz_299299 = (ase_positionWS).xz;
					float2 temp_output_19_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult20 = dot( ase_world_xz_299299 , temp_output_19_0 );
					float ase_water_clock_301301 = ( _Time.y * _WaveSpeed );
					float temp_output_25_0 = ( ( dotResult20 + ( ase_water_clock_301301 * 0.9 ) ) + 0.1 );
					float temp_output_27_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_38_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult39 = dot( ase_world_xz_299299 , temp_output_38_0 );
					float temp_output_44_0 = ( ( dotResult39 + ( ase_water_clock_301301 * 1.23 ) ) + 1.6 );
					float temp_output_46_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_308308 = temp_output_46_0;
					float2 temp_output_57_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult58 = dot( ase_world_xz_299299 , temp_output_57_0 );
					float temp_output_63_0 = ( ( dotResult58 + ( ase_water_clock_301301 * 1.58 ) ) + 3.0 );
					float temp_output_65_0 = ( _WaveHeight * 0.15 );
					float temp_output_31_0 = ( cos( temp_output_25_0 ) * temp_output_27_0 );
					float2 ase_swell_1_wavevector_303303 = temp_output_19_0;
					float temp_output_50_0 = ( cos( temp_output_44_0 ) * temp_output_46_0 );
					float2 ase_swell_2_wavevector_310310 = temp_output_38_0;
					float temp_output_69_0 = ( cos( temp_output_63_0 ) * temp_output_65_0 );
					float2 ase_swell_3_wavevector_315315 = temp_output_57_0;
					float4 appendResult80 = (float4(( ( ( sin( temp_output_25_0 ) * temp_output_27_0 ) + ( sin( temp_output_44_0 ) * ase_swell_2_amplitude_308308 ) ) + ( sin( temp_output_63_0 ) * temp_output_65_0 ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).x ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).x ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).x ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).y ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).y ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).y ) ) , 0.0));
					#ifdef _WATER_WAVES_ON
					float4 staticSwitch82 = appendResult80;
					#else
					float4 staticSwitch82 = float4( 0, 0, 0, 0 );
					#endif
					float4 appendResult86 = (float4(ase_wave_zero_318318 , (staticSwitch82).x , ase_wave_zero_318318 , ase_wave_zero_318318));
					float3 ase_object_wave_offset_391391 = (mul( unity_WorldToObject, appendResult86 )).xyz;
					

					#ifdef ASE_ABSOLUTE_VERTEX_POS
						float3 defaultVertexValue = v.vertex.xyz;
					#else
						float3 defaultVertexValue = float3(0, 0, 0);
					#endif
					float3 vertexValue = ase_object_wave_offset_391391;
					#ifdef ASE_ABSOLUTE_VERTEX_POS
						v.vertex.xyz = vertexValue;
					#else
						v.vertex.xyz += vertexValue;
					#endif
					v.vertex.w = 1;
					v.normal = v.normal;
					v.tangent = v.tangent;

					float3 positionWS = mul( unity_ObjectToWorld, v.vertex ).xyz;
					half3 normalWS = UnityObjectToWorldNormal( v.normal );
					half3 tangentWS = UnityObjectToWorldDir( v.tangent.xyz );

					o.pos = UnityObjectToClipPos( v.vertex );
					o.worldPos.xyz = positionWS;
					o.normalWS = normalWS;
					o.tangentWS = half4( tangentWS, v.tangent.w );

					o.ambientOrLightmapUV = 0;
					#ifdef LIGHTMAP_ON
						o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#elif UNITY_SHOULD_SAMPLE_SH
						#ifdef VERTEXLIGHT_ON
							o.ambientOrLightmapUV.rgb += Shade4PointLights(
								unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
								unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
								unity_4LightAtten0, positionWS, normalWS );
						#endif
						o.ambientOrLightmapUV.rgb = ShadeSHPerVertex( normalWS, o.ambientOrLightmapUV.rgb );
					#endif
					#ifdef DYNAMICLIGHTMAP_ON
						o.ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
					#endif

					#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
						o.tangentWS.zw = v.texcoord.xy;
						o.tangentWS.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#endif

					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
					#if defined( ASE_FOG )
						UNITY_TRANSFER_FOG_COMBINED_WITH_WORLD_POS( o, o.pos );
					#endif
					return o;
				}

				#if defined(ASE_TESSELLATION)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					half4 tangent : TANGENT;
					half3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
					float4 texcoord1 : TEXCOORD1;
					float4 texcoord2 : TEXCOORD2;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( appdata v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.tangent = v.tangent;
					o.normal = v.normal;
					o.texcoord = v.texcoord;
					o.texcoord1 = v.texcoord1;
					o.texcoord2 = v.texcoord2;
					
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
					tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
					tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
					tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
					tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
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
				v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					appdata o = (appdata) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
					o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
					o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
					o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
					o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
					
					#if defined(ASE_PHONG_TESSELLATION)
					float3 pp[3];
					for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
					float phongStrength = _TessPhongStrength;
					o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
				#else
				v2f vert ( appdata v )
				{
					return VertexFunction( v );
				}
				#endif

				half4 frag( v2f IN 
							#if defined( ASE_WRITE_DEPTH )
								, out float outputDepth : ASE_SV_DEPTH
							#endif
							) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(IN);

					#ifdef LOD_FADE_CROSSFADE
						UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
					#endif

					#if defined(ASE_LIGHTING_SIMPLE)
						SurfaceOutput o = (SurfaceOutput)0;
					#else
						#if defined(_SPECULAR_SETUP)
							SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
						#else
							SurfaceOutputStandard o = (SurfaceOutputStandard)0;
						#endif
					#endif

					half atten;
					{
						#if defined( ASE_RECEIVE_SHADOWS )
							UNITY_LIGHT_ATTENUATION( temp, IN, IN.worldPos.xyz )
							atten = temp;
						#else
							atten = 1;
						#endif
					}

					float3 PositionWS = IN.worldPos.xyz;
					half3 ViewDirWS = normalize( UnityWorldSpaceViewDir( PositionWS ) );
					float4 ScreenPosNorm = float4( IN.pos.xy * ( _ScreenParams.zw - 1.0 ), IN.pos.zw );
					float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, IN.pos.z ) * IN.pos.w;
					float4 ScreenPos = ComputeScreenPos( ClipPos );
					half3 NormalWS = IN.normalWS;
					half3 TangentWS = IN.tangentWS.xyz;
					half3 BitangentWS = cross( IN.normalWS, IN.tangentWS.xyz ) * IN.tangentWS.w * unity_WorldTransformParams.w;
					half3 LightAtten = atten;

					#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
						float2 sampleCoords = (IN.tangentWS.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
						NormalWS = UnityObjectToWorldNormal(normalize(tex2D(_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
						TangentWS = -cross(unity_ObjectToWorld._13_23_33, NormalWS);
						BitangentWS = cross(NormalWS, -TangentWS);
					#endif

					float screenDepth131 = ASELinearEyeDepth( SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ScreenPosNorm.xy ) );
					float distanceDepth131 = ( screenDepth131 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( 1.0 );
					float temp_output_135_0 = min( max( distanceDepth131, 0.0 ), 80.0 );
					float ase_view_to_camera_ws_331331 = ViewDirWS.x;
					float ase_view_to_camera_ws_333333 = ViewDirWS.y;
					float ase_view_to_camera_ws_335335 = ViewDirWS.z;
					float4 appendResult137 = (float4(ase_view_to_camera_ws_331331 , ase_view_to_camera_ws_333333 , ase_view_to_camera_ws_335335 , 0.0));
					float temp_output_144_0 = ( temp_output_135_0 / max( abs( (mul( unity_WorldToCamera, appendResult137 )).z ), 0.12 ) );
					float ase_optical_path_m_337337 = temp_output_144_0;
					float4 staticSwitch160 = ( float4 )0;
					#ifdef _WATER_DEPTH_ON
					{
						float3 temp_output_151_0 = exp( -( ( temp_output_144_0 * _Density ) * (_Absorption).xyz ) );
						float4 appendResult158 = (float4((temp_output_151_0).x , (temp_output_151_0).y , (temp_output_151_0).z , saturate( ( ase_optical_path_m_337337 / _DeepDistance ) )));
						staticSwitch160 = appendResult158;
					}
					#else
					{
						staticSwitch160 = float4( 1, 1, 1, 0 );
					}
					#endif
					float3 lerpResult167 = lerp( (_ShallowColor).rgb , (_DeepColor).rgb , (staticSwitch160).w);
					float3 ase_depth_scattering_color_365365 = lerpResult167;
					float3 ase_enabled_transmittance_363363 = (staticSwitch160).xyz;
					float3 staticSwitch278 = ( float3 )0;
					#ifdef _WATER_SCATTER_ON
					{
						staticSwitch278 = ( ( ase_depth_scattering_color_365365 * ( 1.0 - ase_enabled_transmittance_363363 ) ) * _ScatteringStrength );
					}
					#else
					{
						staticSwitch278 = (float4( 0, 0, 0, 0 )).xyz;
					}
					#endif
					float3 ase_scattering_enabled_368368 = staticSwitch278;
					float3 ase_foam_rgb_381381 = (_FoamColor).rgb;
					float smoothstepResult170 = smoothstep( 0.0 , 0.1 , temp_output_135_0);
					float ase_shore_contact_fade_350350 = smoothstepResult170;
					float ase_water_clock_301301 = ( _Time.y * _WaveSpeed );
					float ase_depth_eye_353353 = temp_output_135_0;
					float2 ase_world_xz_299299 = (PositionWS).xz;
					float staticSwitch245 = ( float )0;
					#ifdef _WATER_FOAM_ON
					{
						float temp_output_220_0 = ( 1.0 - saturate( ( ase_depth_eye_353353 / _FoamWidth ) ) );
						float2 panner214 = ( ase_water_clock_301301 * (float4( 0.029, 0.014, 0, 0 )).xy + ( ase_world_xz_299299 * 0.48 ));
						float smoothstepResult224 = smoothstep( 0.34 , 0.66 , SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner214 ).b);
						float lerpResult237 = lerp( 0.35 , 1.0 , ( ( sin( ( ( ase_depth_eye_353353 * 14.0 ) - ( ase_water_clock_301301 * 1.8 ) ) ) * 0.5 ) + 0.5 ));
						staticSwitch245 = saturate( ( ( ( ( temp_output_220_0 * temp_output_220_0 ) * smoothstepResult224 ) * lerpResult237 ) * ( _FoamStrength * ase_shore_contact_fade_350350 ) ) );
					}
					#else
					{
						staticSwitch245 = 0.0;
					}
					#endif
					float ase_foam_enabled_377377 = staticSwitch245;
					float3 lerpResult297 = lerp( ( ase_scattering_enabled_368368 * 0.08 ) , ase_foam_rgb_381381 , ase_foam_enabled_377377);
					
					float2 temp_output_19_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
					float dotResult20 = dot( ase_world_xz_299299 , temp_output_19_0 );
					float temp_output_25_0 = ( ( dotResult20 + ( ase_water_clock_301301 * 0.9 ) ) + 0.1 );
					float temp_output_27_0 = ( _WaveHeight * 0.57 );
					float2 temp_output_38_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
					float dotResult39 = dot( ase_world_xz_299299 , temp_output_38_0 );
					float temp_output_44_0 = ( ( dotResult39 + ( ase_water_clock_301301 * 1.23 ) ) + 1.6 );
					float temp_output_46_0 = ( _WaveHeight * 0.28 );
					float ase_swell_2_amplitude_308308 = temp_output_46_0;
					float2 temp_output_57_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
					float dotResult58 = dot( ase_world_xz_299299 , temp_output_57_0 );
					float temp_output_63_0 = ( ( dotResult58 + ( ase_water_clock_301301 * 1.58 ) ) + 3.0 );
					float temp_output_65_0 = ( _WaveHeight * 0.15 );
					float temp_output_31_0 = ( cos( temp_output_25_0 ) * temp_output_27_0 );
					float2 ase_swell_1_wavevector_303303 = temp_output_19_0;
					float temp_output_50_0 = ( cos( temp_output_44_0 ) * temp_output_46_0 );
					float2 ase_swell_2_wavevector_310310 = temp_output_38_0;
					float temp_output_69_0 = ( cos( temp_output_63_0 ) * temp_output_65_0 );
					float2 ase_swell_3_wavevector_315315 = temp_output_57_0;
					float4 appendResult80 = (float4(( ( ( sin( temp_output_25_0 ) * temp_output_27_0 ) + ( sin( temp_output_44_0 ) * ase_swell_2_amplitude_308308 ) ) + ( sin( temp_output_63_0 ) * temp_output_65_0 ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).x ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).x ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).x ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).y ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).y ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).y ) ) , 0.0));
					#ifdef _WATER_WAVES_ON
					float4 staticSwitch82 = appendResult80;
					#else
					float4 staticSwitch82 = float4( 0, 0, 0, 0 );
					#endif
					float ase_enabled_wave_slope_x_326326 = (staticSwitch82).y;
					float2 staticSwitch114 = ( float2 )0;
					#ifdef _WATER_RIPPLES_ON
					{
						float2 panner96 = ( ase_water_clock_301301 * (float4( 0.036, 0.021, 0, 0 )).xy + ( ase_world_xz_299299 * _RippleScale ));
						float2 panner103 = ( ase_water_clock_301301 * (float4( -0.019, 0.029, 0, 0 )).xy + ( (ase_world_xz_299299).yx * ( _RippleScale * 1.63 ) ));
						staticSwitch114 = ( ( ( (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner96 )).rg + (SAMPLE_TEXTURE2D( _RippleSlope, sampler_RippleSlope, panner103 )).gr ) - 1.0 ) * _RippleStrength );
					}
					#else
					{
						staticSwitch114 = (float4( 0, 0, 0, 0 )).xy;
					}
					#endif
					float2 ase_ripples_enabled_324324 = staticSwitch114;
					float ase_enabled_wave_slope_z_329329 = (staticSwitch82).z;
					float3 appendResult122 = (float3(-( ase_enabled_wave_slope_x_326326 + (ase_ripples_enabled_324324).x ) , 1.0 , -( ase_enabled_wave_slope_z_329329 + (ase_ripples_enabled_324324).y )));
					float3 normalizeResult123 = normalize( appendResult122 );
					float3 ase_water_normal_ws_358358 = normalizeResult123;
					
					float lerpResult290 = lerp( ( 0.02037 * ( _ReflectionStrength * ase_shore_contact_fade_350350 ) ) , 0.028 , ase_foam_enabled_377377);
					float3 appendResult291 = (float3(lerpResult290 , lerpResult290 , lerpResult290));
					
					float lerpResult294 = lerp( _Smoothness , 0.28 , ase_foam_enabled_377377);
					float ase_surface_smoothness_385385 = lerpResult294;
					
					float3 staticSwitch280 = ( float3 )0;
					#ifdef _WATER_REFRACTION_ON
					{
						float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ScreenPos );
						float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
						float4 appendResult252 = (float4((ase_water_normal_ws_358358).x , (ase_water_normal_ws_358358).y , (ase_water_normal_ws_358358).z , 0.0));
						float4 screenColor266 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,saturate( ( (ase_grabScreenPosNorm).xy + ( (mul( unity_WorldToCamera, appendResult252 )).xy * ( _RefractionStrength * saturate( ( ase_depth_eye_353353 / 0.65 ) ) ) ) ) ));
						float3 staticSwitch210 = ( float3 )0;
						#ifdef _WATER_CAUSTICS_ON
						{
							float ase_time_seconds_348348 = _Time.y;
							float temp_output_181_0 = ( ase_time_seconds_348348 * _CausticSpeed );
							float3 ase_world_position_342342 = PositionWS;
							float3 ase_view_to_camera_ws_339339 = ViewDirWS;
							float3 temp_output_172_0 = ( ase_world_position_342342 - ( ase_view_to_camera_ws_339339 * ase_optical_path_m_337337 ) );
							float3 ase_underwater_position_ws_344344 = temp_output_172_0;
							float2 temp_output_173_0 = (ase_underwater_position_ws_344344).xz;
							float2 panner185 = ( temp_output_181_0 * (float4( 0.025, 0.017, 0, 0 )).xy + ( temp_output_173_0 * ( _CausticScale * 1.0 ) ));
							float2 panner192 = ( temp_output_181_0 * (float4( -0.018, 0.023, 0, 0 )).xy + ( temp_output_173_0 * ( _CausticScale * 1.17 ) ));
							float ase_world_position_346346 = PositionWS.y;
							staticSwitch210 = ( (_CausticTint).rgb * ( min( SAMPLE_TEXTURE2D( _CausticTex, sampler_CausticTex, panner185 ).r, SAMPLE_TEXTURE2D( _CausticTex, sampler_CausticTex, panner192 ).r ) * ( _CausticStrength * ( exp( -( max( ( ase_world_position_346346 - (temp_output_172_0).y ), 0.0 ) * _CausticFalloff ) ) * ase_shore_contact_fade_350350 ) ) ) );
						}
						#else
						{
							staticSwitch210 = (float4( 0, 0, 0, 0 )).xyz;
						}
						#endif
						float3 ase_caustics_enabled_371371 = staticSwitch210;
						staticSwitch280 = ( ( ( (screenColor266).rgb * ( 1.0 + ase_caustics_enabled_371371 ) ) * ase_enabled_transmittance_363363 ) + staticSwitch278 );
					}
					#else
					{
						staticSwitch280 = ase_depth_scattering_color_365365;
					}
					#endif
					float staticSwitch130 = ( float )0;
					#ifdef _WATER_FRESNEL_ON
					{
						float fresnelNdotV125 = dot( normalizeResult123, ViewDirWS );
						float fresnelNode125 = ( 0.02037 + 0.97963 * pow( 1.0 - fresnelNdotV125, 5.0 ) );
						staticSwitch130 = fresnelNode125;
					}
					#else
					{
						staticSwitch130 = 0.0;
					}
					#endif
					float ase_fresnel_enabled_375375 = staticSwitch130;
					float3 ase_water_transmission_emission_387387 = ( ( staticSwitch280 * ( 1.0 - ase_fresnel_enabled_375375 ) ) * ( 1.0 - ase_foam_enabled_377377 ) );
					
					float ase_composite_alpha_389389 = 1.0;
					

					o.Albedo = lerpResult297;
					o.Normal = ase_water_normal_ws_358358;

					half3 Specular = appendResult291;
					half Metallic = 0;
					half Smoothness = ase_surface_smoothness_385385;
					half Occlusion = 1;

					#if defined(ASE_LIGHTING_SIMPLE)
						o.Specular = Specular.x;
						o.Gloss = Smoothness;
					#else
						#if defined(_SPECULAR_SETUP)
							o.Specular = Specular;
						#else
							o.Metallic = Metallic;
						#endif
						o.Occlusion = Occlusion;
						o.Smoothness = Smoothness;
					#endif

					o.Emission = ase_water_transmission_emission_387387;
					o.Alpha = ase_composite_alpha_389389;
					half AlphaClipThreshold = 0.5;
					half AlphaClipThresholdShadow = 0.5;
					half3 BakedGI = 0;
					half3 Transmission = 1;
					half3 Translucency = 1;

					#if defined( ASE_WRITE_DEPTH )
						IN.pos.z = IN.pos.z;
					#endif

					#ifdef _ALPHATEST_ON
						clip( o.Alpha - AlphaClipThreshold );
					#endif

					#if defined( ASE_CHANGES_WORLD_POS )
					{
						#if defined( ASE_RECEIVE_SHADOWS )
							UNITY_LIGHT_ATTENUATION( temp, IN, PositionWS )
							LightAtten = temp;
						#else
							LightAtten = 1;
						#endif
					}
					#endif

					#if ( ASE_FRAGMENT_NORMAL == 0 )
						o.Normal = normalize( o.Normal.x * TangentWS + o.Normal.y * BitangentWS + o.Normal.z * NormalWS );
					#elif ( ASE_FRAGMENT_NORMAL == 1 )
						o.Normal = UnityObjectToWorldNormal( o.Normal );
					#elif ( ASE_FRAGMENT_NORMAL == 2 )
						// @diogo: already in world-space; do nothing
					#endif

					#if defined( ASE_WRITE_DEPTH )
						outputDepth = IN.pos.z;
					#endif

					#ifndef USING_DIRECTIONAL_LIGHT
						half3 lightDir = normalize( UnityWorldSpaceLightDir( PositionWS ) );
					#else
						half3 lightDir = _WorldSpaceLightPos0.xyz;
					#endif

					UnityGI gi;
					UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
					gi.indirect.diffuse = 0;
					gi.indirect.specular = 0;
					gi.light.color = _LightColor0.rgb;
					gi.light.dir = lightDir;

					UnityGIInput giInput;
					UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
					giInput.light = gi.light;
					giInput.worldPos = PositionWS;
					giInput.worldViewDir = ViewDirWS;
					giInput.atten = atten;
					#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
						giInput.lightmapUV = IN.ambientOrLightmapUV;
					#else
						giInput.lightmapUV = 0.0;
					#endif
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						giInput.ambient = IN.ambientOrLightmapUV.rgb;
					#else
						giInput.ambient.rgb = 0.0;
					#endif
					giInput.probeHDR[0] = unity_SpecCube0_HDR;
					giInput.probeHDR[1] = unity_SpecCube1_HDR;
					#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
						giInput.boxMin[0] = unity_SpecCube0_BoxMin;
					#endif
					#ifdef UNITY_SPECCUBE_BOX_PROJECTION
						giInput.boxMax[0] = unity_SpecCube0_BoxMax;
						giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
						giInput.boxMax[1] = unity_SpecCube1_BoxMax;
						giInput.boxMin[1] = unity_SpecCube1_BoxMin;
						giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
					#endif

					#if defined(ASE_LIGHTING_SIMPLE)
						#if defined(_SPECULAR_SETUP)
							LightingBlinnPhong_GI(o, giInput, gi);
						#else
							LightingLambert_GI(o, giInput, gi);
						#endif
					#else
						#if defined(_SPECULAR_SETUP)
							LightingStandardSpecular_GI(o, giInput, gi);
						#else
							LightingStandard_GI(o, giInput, gi);
						#endif
					#endif

					#ifdef ASE_BAKEDGI
						gi.indirect.diffuse = BakedGI;
					#endif

					#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
						gi.indirect.diffuse = 0;
					#endif

					half4 c = 0;
					#if defined(ASE_LIGHTING_SIMPLE)
						#if defined(_SPECULAR_SETUP)
							c += LightingBlinnPhong (o, ViewDirWS, gi);
						#else
							c += LightingLambert( o, gi );
						#endif
					#else
						#if defined(_SPECULAR_SETUP)
							c += LightingStandardSpecular (o, ViewDirWS, gi);
						#else
							c += LightingStandard(o, ViewDirWS, gi);
						#endif
					#endif

					#ifdef ASE_TRANSMISSION
					{
						half shadow = _TransmissionShadow;
						#ifdef DIRECTIONAL
							half3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
						#else
							half3 lightAtten = gi.light.color;
						#endif
						half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
						c.rgb += o.Albedo * transmission;
					}
					#endif

					#ifdef ASE_TRANSLUCENCY
					{
						half shadow = _TransShadow;
						half normal = _TransNormal;
						half scattering = _TransScattering;
						half direct = _TransDirect;
						half ambient = _TransAmbient;
						half strength = _TransStrength;

						#ifdef DIRECTIONAL
							half3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
						#else
							half3 lightAtten = gi.light.color;
						#endif
						half3 lightDir = gi.light.dir + o.Normal * normal;
						half transVdotL = pow( saturate( dot( ViewDirWS, -lightDir ) ), scattering );
						half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
						c.rgb += o.Albedo * translucency * strength;
					}
					#endif

					c.rgb += o.Emission;

					#if defined( ASE_FOG )
						UNITY_EXTRACT_FOG_FROM_WORLD_POS( IN );
						UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
					#endif
					return c;
				}
			ENDCG
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			ZWrite On

			CGPROGRAM
				#define ASE_GEOMETRY
				#define ASE_RECEIVE_SHADOWS
				#pragma multi_compile_instancing
				#define ASE_FOG
				#define _SPECULAR_SETUP 1
				#define UNITY_STANDARD_USE_DITHER_MASK 1
				#define ASE_FRAGMENT_NORMAL 2
				#define ASE_VERSION 19913
				#define ASE_USING_SAMPLING_MACROS 1

				#pragma vertex vert
				#pragma fragment frag
				#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
				#pragma multi_compile_fwdbase
				#define SCENESELECTIONPASS
				#ifndef UNITY_PASS_FORWARDBASE
					#define UNITY_PASS_FORWARDBASE
				#endif
				#include "HLSLSupport.cginc"
				#if defined( ASE_GEOMETRY ) || defined( ASE_IMPOSTOR )
					#ifndef UNITY_INSTANCED_LOD_FADE
						#define UNITY_INSTANCED_LOD_FADE
					#endif
					#ifndef UNITY_INSTANCED_SH
						#define UNITY_INSTANCED_SH
					#endif
					#ifndef UNITY_INSTANCED_LIGHTMAPSTS
						#define UNITY_INSTANCED_LIGHTMAPSTS
					#endif
				#endif
				#include "UnityShaderVariables.cginc"
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "UnityPBSLighting.cginc"
				#include "AutoLight.cginc"

				#pragma shader_feature_local _WATER_WAVES_ON


				#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
					#define ASE_SV_DEPTH SV_DepthLessEqual
					#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
				#else
					#define ASE_SV_DEPTH SV_Depth
					#define ASE_SV_POSITION_QUALIFIERS
				#endif

				int _ObjectId;
				int _PassValue;

				struct appdata
				{
					float4 vertex : POSITION;
					half3 normal : NORMAL;
					half4 tangent : TANGENT;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS float4 pos : SV_POSITION;
					float4 worldPos : TEXCOORD0; // xyz = positionWS
					half3 normalWS : TEXCOORD1;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				#ifdef ASE_TESSELLATION
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif

				uniform float _WaveSpeed;
				uniform float _WaveScale;
				uniform float _WaveHeight;


				
				v2f VertexFunction( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID(v);
					v2f o;
					UNITY_INITIALIZE_OUTPUT(v2f,o);
					UNITY_TRANSFER_INSTANCE_ID(v,o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					float ase_wave_zero_318318 = 0.0;
					float3 ase_positionWS = mul( unity_ObjectToWorld, float4( ( v.vertex ).xyz, 1 ) ).xyz;
					float2 ase_world_xz_299299 = (ase_positionWS).xz;
					float ase_water_clock_301301 = ( _Time.y * _WaveSpeed );
					float4 staticSwitch82 = ( float4 )0;
					#ifdef _WATER_WAVES_ON
					{
						float2 temp_output_19_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
						float dotResult20 = dot( ase_world_xz_299299 , temp_output_19_0 );
						float temp_output_25_0 = ( ( dotResult20 + ( ase_water_clock_301301 * 0.9 ) ) + 0.1 );
						float temp_output_27_0 = ( _WaveHeight * 0.57 );
						float2 temp_output_38_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
						float dotResult39 = dot( ase_world_xz_299299 , temp_output_38_0 );
						float temp_output_44_0 = ( ( dotResult39 + ( ase_water_clock_301301 * 1.23 ) ) + 1.6 );
						float temp_output_46_0 = ( _WaveHeight * 0.28 );
						float ase_swell_2_amplitude_308308 = temp_output_46_0;
						float2 temp_output_57_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
						float dotResult58 = dot( ase_world_xz_299299 , temp_output_57_0 );
						float temp_output_63_0 = ( ( dotResult58 + ( ase_water_clock_301301 * 1.58 ) ) + 3.0 );
						float temp_output_65_0 = ( _WaveHeight * 0.15 );
						float temp_output_31_0 = ( cos( temp_output_25_0 ) * temp_output_27_0 );
						float2 ase_swell_1_wavevector_303303 = temp_output_19_0;
						float temp_output_50_0 = ( cos( temp_output_44_0 ) * temp_output_46_0 );
						float2 ase_swell_2_wavevector_310310 = temp_output_38_0;
						float temp_output_69_0 = ( cos( temp_output_63_0 ) * temp_output_65_0 );
						float2 ase_swell_3_wavevector_315315 = temp_output_57_0;
						float4 appendResult80 = (float4(( ( ( sin( temp_output_25_0 ) * temp_output_27_0 ) + ( sin( temp_output_44_0 ) * ase_swell_2_amplitude_308308 ) ) + ( sin( temp_output_63_0 ) * temp_output_65_0 ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).x ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).x ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).x ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).y ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).y ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).y ) ) , 0.0));
						staticSwitch82 = appendResult80;
					}
					#else
					{
						staticSwitch82 = float4( 0, 0, 0, 0 );
					}
					#endif
					float4 appendResult86 = (float4(ase_wave_zero_318318 , (staticSwitch82).x , ase_wave_zero_318318 , ase_wave_zero_318318));
					float3 ase_object_wave_offset_391391 = (mul( unity_WorldToObject, appendResult86 )).xyz;
					

					#ifdef ASE_ABSOLUTE_VERTEX_POS
						float3 defaultVertexValue = v.vertex.xyz;
					#else
						float3 defaultVertexValue = float3(0, 0, 0);
					#endif
					float3 vertexValue = ase_object_wave_offset_391391;
					#ifdef ASE_ABSOLUTE_VERTEX_POS
						v.vertex.xyz = vertexValue;
					#else
						v.vertex.xyz += vertexValue;
					#endif
					v.vertex.w = 1;
					v.normal = v.normal;
					v.tangent = v.tangent;

					float3 positionWS = mul( unity_ObjectToWorld, v.vertex ).xyz;
					half3 normalWS = UnityObjectToWorldNormal( v.normal );

					o.pos = UnityObjectToClipPos( v.vertex );
					o.worldPos.xyz = positionWS;
					o.normalWS = normalWS;
					return o;
				}

				#if defined(ASE_TESSELLATION)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					half3 normal : NORMAL;
					half4 tangent : TANGENT;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( appdata v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.normal = v.normal;
					o.tangent = v.tangent;
					
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
					tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
					tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
					tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
					tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
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
				v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					appdata o = (appdata) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
					o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
					
					#if defined(ASE_PHONG_TESSELLATION)
					float3 pp[3];
					for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
					float phongStrength = _TessPhongStrength;
					o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
				#else
				v2f vert ( appdata v )
				{
					return VertexFunction( v );
				}
				#endif

				half4 frag( v2f IN 
							#if defined( ASE_WRITE_DEPTH )
								, out float outputDepth : ASE_SV_DEPTH
							#endif
							) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(IN);

					#ifdef LOD_FADE_CROSSFADE
						UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
					#endif

					float ase_composite_alpha_389389 = 1.0;
					

					half Alpha = ase_composite_alpha_389389;
					half AlphaClipThreshold = 0.5;

					#if defined( ASE_WRITE_DEPTH )
						IN.pos.z = IN.pos.z;
					#endif

					#ifdef _ALPHATEST_ON
						clip( Alpha - AlphaClipThreshold );
					#endif

					#if defined( ASE_WRITE_DEPTH )
						outputDepth = IN.pos.z;
					#endif

					return float4( _ObjectId, _PassValue, 1.0, 1.0 );
				}
			ENDCG
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			ZWrite On

			CGPROGRAM
				#define ASE_GEOMETRY
				#define ASE_RECEIVE_SHADOWS
				#pragma multi_compile_instancing
				#define ASE_FOG
				#define _SPECULAR_SETUP 1
				#define UNITY_STANDARD_USE_DITHER_MASK 1
				#define ASE_FRAGMENT_NORMAL 2
				#define ASE_VERSION 19913
				#define ASE_USING_SAMPLING_MACROS 1

				#pragma vertex vert
				#pragma fragment frag
				#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

				#pragma multi_compile_fwdbase
				#ifndef UNITY_PASS_FORWARDBASE
					#define UNITY_PASS_FORWARDBASE
				#endif
				#define SCENEPICKINGPASS
				#include "HLSLSupport.cginc"
				#if defined( ASE_GEOMETRY ) || defined( ASE_IMPOSTOR )
					#ifndef UNITY_INSTANCED_LOD_FADE
						#define UNITY_INSTANCED_LOD_FADE
					#endif
					#ifndef UNITY_INSTANCED_SH
						#define UNITY_INSTANCED_SH
					#endif
					#ifndef UNITY_INSTANCED_LIGHTMAPSTS
						#define UNITY_INSTANCED_LIGHTMAPSTS
					#endif
				#endif
				#include "UnityShaderVariables.cginc"
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "UnityPBSLighting.cginc"
				#include "AutoLight.cginc"

				#pragma shader_feature_local _WATER_WAVES_ON


				#if defined(ASE_WRITE_DEPTH_CONSERVATIVE) && (SHADER_TARGET >= 45)
					#define ASE_SV_DEPTH SV_DepthLessEqual
					#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
				#else
					#define ASE_SV_DEPTH SV_Depth
					#define ASE_SV_POSITION_QUALIFIERS
				#endif

				float4 _SelectionID;

				struct appdata
				{
					float4 vertex : POSITION;
					half3 normal : NORMAL;
					half4 tangent : TANGENT;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS float4 pos : SV_POSITION;
					float4 worldPos : TEXCOORD0; // xyz = positionWS
					half3 normalWS : TEXCOORD1;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				#ifdef ASE_TESSELLATION
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif

				uniform float _WaveSpeed;
				uniform float _WaveScale;
				uniform float _WaveHeight;


				
				v2f VertexFunction( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID(v);
					v2f o;
					UNITY_INITIALIZE_OUTPUT(v2f,o);
					UNITY_TRANSFER_INSTANCE_ID(v,o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					float ase_wave_zero_318318 = 0.0;
					float3 ase_positionWS = mul( unity_ObjectToWorld, float4( ( v.vertex ).xyz, 1 ) ).xyz;
					float2 ase_world_xz_299299 = (ase_positionWS).xz;
					float ase_water_clock_301301 = ( _Time.y * _WaveSpeed );
					float4 staticSwitch82 = ( float4 )0;
					#ifdef _WATER_WAVES_ON
					{
						float2 temp_output_19_0 = ( (float4( 0.52, 0.17, 0, 0 )).xy * _WaveScale );
						float dotResult20 = dot( ase_world_xz_299299 , temp_output_19_0 );
						float temp_output_25_0 = ( ( dotResult20 + ( ase_water_clock_301301 * 0.9 ) ) + 0.1 );
						float temp_output_27_0 = ( _WaveHeight * 0.57 );
						float2 temp_output_38_0 = ( (float4( -0.23, 0.86, 0, 0 )).xy * _WaveScale );
						float dotResult39 = dot( ase_world_xz_299299 , temp_output_38_0 );
						float temp_output_44_0 = ( ( dotResult39 + ( ase_water_clock_301301 * 1.23 ) ) + 1.6 );
						float temp_output_46_0 = ( _WaveHeight * 0.28 );
						float ase_swell_2_amplitude_308308 = temp_output_46_0;
						float2 temp_output_57_0 = ( (float4( 1.13, 0.65, 0, 0 )).xy * _WaveScale );
						float dotResult58 = dot( ase_world_xz_299299 , temp_output_57_0 );
						float temp_output_63_0 = ( ( dotResult58 + ( ase_water_clock_301301 * 1.58 ) ) + 3.0 );
						float temp_output_65_0 = ( _WaveHeight * 0.15 );
						float temp_output_31_0 = ( cos( temp_output_25_0 ) * temp_output_27_0 );
						float2 ase_swell_1_wavevector_303303 = temp_output_19_0;
						float temp_output_50_0 = ( cos( temp_output_44_0 ) * temp_output_46_0 );
						float2 ase_swell_2_wavevector_310310 = temp_output_38_0;
						float temp_output_69_0 = ( cos( temp_output_63_0 ) * temp_output_65_0 );
						float2 ase_swell_3_wavevector_315315 = temp_output_57_0;
						float4 appendResult80 = (float4(( ( ( sin( temp_output_25_0 ) * temp_output_27_0 ) + ( sin( temp_output_44_0 ) * ase_swell_2_amplitude_308308 ) ) + ( sin( temp_output_63_0 ) * temp_output_65_0 ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).x ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).x ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).x ) ) , ( ( ( temp_output_31_0 * (ase_swell_1_wavevector_303303).y ) + ( temp_output_50_0 * (ase_swell_2_wavevector_310310).y ) ) + ( temp_output_69_0 * (ase_swell_3_wavevector_315315).y ) ) , 0.0));
						staticSwitch82 = appendResult80;
					}
					#else
					{
						staticSwitch82 = float4( 0, 0, 0, 0 );
					}
					#endif
					float4 appendResult86 = (float4(ase_wave_zero_318318 , (staticSwitch82).x , ase_wave_zero_318318 , ase_wave_zero_318318));
					float3 ase_object_wave_offset_391391 = (mul( unity_WorldToObject, appendResult86 )).xyz;
					

					#ifdef ASE_ABSOLUTE_VERTEX_POS
						float3 defaultVertexValue = v.vertex.xyz;
					#else
						float3 defaultVertexValue = float3(0, 0, 0);
					#endif
					float3 vertexValue = ase_object_wave_offset_391391;
					#ifdef ASE_ABSOLUTE_VERTEX_POS
						v.vertex.xyz = vertexValue;
					#else
						v.vertex.xyz += vertexValue;
					#endif
					v.vertex.w = 1;
					v.normal = v.normal;
					v.tangent = v.tangent;

					float3 positionWS = mul( unity_ObjectToWorld, v.vertex ).xyz;
					half3 normalWS = UnityObjectToWorldNormal( v.normal );

					o.pos = UnityObjectToClipPos( v.vertex );
					o.worldPos.xyz = positionWS;
					o.normalWS = normalWS;
					return o;
				}

				#if defined(ASE_TESSELLATION)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					half3 normal : NORMAL;
					half4 tangent : TANGENT;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( appdata v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.normal = v.normal;
					o.tangent = v.tangent;
					
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
					tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
					tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
					tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
					tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
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
				v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					appdata o = (appdata) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
					o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
					
					#if defined(ASE_PHONG_TESSELLATION)
					float3 pp[3];
					for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
					float phongStrength = _TessPhongStrength;
					o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
				#else
				v2f vert ( appdata v )
				{
					return VertexFunction( v );
				}
				#endif

				half4 frag( v2f IN 
							#if defined( ASE_WRITE_DEPTH )
								, out float outputDepth : ASE_SV_DEPTH
							#endif
							) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(IN);

					#ifdef LOD_FADE_CROSSFADE
						UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
					#endif

					float ase_composite_alpha_389389 = 1.0;
					

					half Alpha = ase_composite_alpha_389389;
					half AlphaClipThreshold = 0.5;

					#if defined( ASE_WRITE_DEPTH )
						IN.pos.z = IN.pos.z;
					#endif

					#ifdef _ALPHATEST_ON
						clip( Alpha - AlphaClipThreshold );
					#endif

					#if defined( ASE_WRITE_DEPTH )
						outputDepth = IN.pos.z;
					#endif

					return _SelectionID;
				}
			ENDCG
		}
		
	}
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":393,"pos":[0,15],"params":["Inherit","False","1020","1310","以世界 XZ 米制坐标驱动波浪与细波纹；对象缩放不改变波长。所有动画共享时间和速度。适用于水平水面。","10","8","9","10","11","12","299","301","342","346","348","01 世界坐标与时间","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor","id":8,"pos":[50,115],"params":["Inherit","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":10,"pos":[50,360],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":11,"pos":[50,605],"params":["Inherit","False","Property","_WaveSpeed","01 Waves / speed","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.75","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":394,"pos":[1240,15],"params":["Inherit","False","6120","3270","三组不同方向、频率和速度的正弦波叠加成米制位移，同时用 cos 求导得到匹配的水面斜率。w=0 的矩阵变换将世界位移转回对象空间，不受平移影响。细分网格才有真实起伏。","99","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","300","302","303","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","326","329","391","02 三向缓慢涌浪与解析斜率","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":9,"pos":[390,115],"params":["Inherit","False","FLOAT2","0","2","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":12,"pos":[390,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":17,"pos":[1290,360],"params":["Inherit","False","Constant","_Vector0","Vector 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.52,0.17,0,0","0.52,0.17,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":36,"pos":[1290,605],"params":["Inherit","False","Constant","_Vector1","Vector 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.23,0.86,0,0","-0.23,0.86,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":16,"pos":[1630,115],"params":["Inherit","False","Property","_WaveScale","01 Waves / frequency","2","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0.1","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":18,"pos":[1630,605],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":37,"pos":[1630,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":55,"pos":[1630,360],"params":["Inherit","False","Constant","_Vector2","Vector 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.13,0.65,0,0","1.13,0.65,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":299,"pos":[730,115],"params":["Inherit","False","ase_world_xz_299","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":301,"pos":[730,360],"params":["Inherit","False","ase_water_clock_301","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":19,"pos":[1970,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":21,"pos":[1970,115],"params":["Inherit","False","Constant","_Float2","Float 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.9","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":38,"pos":[1970,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":40,"pos":[1970,360],"params":["Inherit","False","Constant","_Float5","Float 5","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.23","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":56,"pos":[1970,1340],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":300,"pos":[1970,605],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":302,"pos":[1970,1585],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":306,"pos":[1970,850],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":307,"pos":[1970,1830],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":20,"pos":[2310,850],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":22,"pos":[2310,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":39,"pos":[2310,1585],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":41,"pos":[2310,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":45,"pos":[2650,850],"params":["Inherit","False","Constant","_Float7","Float 7","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.28","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":57,"pos":[2310,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":59,"pos":[2310,115],"params":["Inherit","False","Constant","_Float8","Float 8","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.58","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":313,"pos":[2310,360],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":314,"pos":[2310,605],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":23,"pos":[2650,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":24,"pos":[2650,360],"params":["Inherit","False","Constant","_Float3","Float 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":42,"pos":[2650,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":43,"pos":[2650,605],"params":["Inherit","False","Constant","_Float6","Float 6","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.6","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":46,"pos":[2990,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":58,"pos":[2650,1095],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":60,"pos":[2650,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":303,"pos":[2990,1095],"params":["Inherit","False","ase_swell_1_wavevector_303","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":310,"pos":[2990,1830],"params":["Inherit","False","ase_swell_2_wavevector_310","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":15,"pos":[2650,115],"params":["Inherit","False","Property","_WaveHeight","01 Waves / height (m)","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0.13","0","0","0.6","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":25,"pos":[2990,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":26,"pos":[2990,115],"params":["Inherit","False","Constant","_Float4","Float 4","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.57","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":30,"pos":[3330,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":44,"pos":[2990,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":49,"pos":[3330,2075],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":61,"pos":[2990,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":62,"pos":[2990,360],"params":["Inherit","False","Constant","_Float9","Float 9","3","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":304,"pos":[3330,1340],"params":["Inherit","False","303","ase_swell_1_wavevector_303","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":305,"pos":[3330,1585],"params":["Inherit","False","303","ase_swell_1_wavevector_303","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":308,"pos":[3330,605],"params":["Inherit","False","ase_swell_2_amplitude_308","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":311,"pos":[3330,2320],"params":["Inherit","False","310","ase_swell_2_wavevector_310","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":312,"pos":[3330,2565],"params":["Inherit","False","310","ase_swell_2_wavevector_310","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":315,"pos":[3330,1830],"params":["Inherit","False","ase_swell_3_wavevector_315","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":27,"pos":[3330,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":28,"pos":[3670,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[3670,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":32,"pos":[3670,1340],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":34,"pos":[3670,1585],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":47,"pos":[3670,1830],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":50,"pos":[3670,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":51,"pos":[3670,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":53,"pos":[3670,3055],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":63,"pos":[3330,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":64,"pos":[3330,115],"params":["Inherit","False","Constant","_Float10","Float 10","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.15","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":68,"pos":[3670,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":309,"pos":[3670,605],"params":["Inherit","False","308","ase_swell_2_amplitude_308","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":316,"pos":[3670,2320],"params":["Inherit","False","315","ase_swell_3_wavevector_315","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":317,"pos":[3670,2565],"params":["Inherit","False","315","ase_swell_3_wavevector_315","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[4010,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":33,"pos":[4010,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":35,"pos":[4010,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":48,"pos":[4010,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":52,"pos":[4010,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":54,"pos":[4010,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":65,"pos":[3670,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":66,"pos":[4010,1340],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":69,"pos":[4010,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":70,"pos":[4010,1585],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":72,"pos":[4010,1830],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":67,"pos":[4350,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":71,"pos":[4350,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":73,"pos":[4350,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":74,"pos":[4350,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":76,"pos":[4350,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":78,"pos":[4350,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":75,"pos":[4690,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":77,"pos":[4690,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":79,"pos":[4690,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[4690,115],"params":["Inherit","False","Constant","_Float0","Float 0","1","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":80,"pos":[5030,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":81,"pos":[5030,115],"params":["Inherit","False","Constant","_Vector3","Vector 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":82,"pos":[5370,360],"params":["Inherit","False","Property","_WATER_WAVES","Enable / 01 Geometry waves","3","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT4","0,0,0,0","False","0","FLOAT4","0,0,0,0","False","2","FLOAT4","0,0,0,0","False","3","FLOAT4","0,0,0,0","False","4","FLOAT4","0,0,0,0","False","5","FLOAT4","0,0,0,0","False","6","FLOAT4","0,0,0,0","False","7","FLOAT4","0,0,0,0","False","8","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":318,"pos":[5370,115],"params":["Inherit","False","ase_wave_zero_318","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":83,"pos":[5710,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":319,"pos":[5710,115],"params":["Inherit","False","318","ase_wave_zero_318","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":86,"pos":[6050,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToObjectMatrix, AmplifyShaderEditor","id":87,"pos":[6050,115],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":88,"pos":[6390,115],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":401,"pos":[28180,15],"params":["Inherit","False","1700","2045","Specular 工作流由方向光及 Reflection Probe 产生高光与反射；模板 Material Toggle 分别控制两者，使用 Unity 的 OFF 关键词。Transparent、ZWrite Off、One/Zero 已合成背景。各效果使用本地 shader_feature，构建时仅保留实际使用的材质组合。","22","285","286","287","288","289","290","291","292","293","294","295","296","297","298","367","369","379","380","382","383","385","389","09 PBR 高光、探针反射与合成","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":89,"pos":[6730,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":298,"pos":[28230,1095],"params":["Inherit","False","Constant","_Float44","Float 44","37","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":389,"pos":[28570,1340],"params":["Inherit","False","ase_composite_alpha_389","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":391,"pos":[7070,115],"params":["Inherit","False","ase_object_wave_offset_391","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":395,"pos":[1240,3445],"params":["Inherit","False","3740","1555","两次采样同一张原创线性斜率纹理，以不同方向和尺度流动。RG 解码为有正负的斜率；第二层交换通道。B 作为岸沫破碎噪声。纹理必须关闭 sRGB，保持 Repeat 与 mipmap。","30","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","320","321","322","323","324","03 双层无缝细波纹","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":396,"pos":[7580,15],"params":["Inherit","False","3060","2045","将涌浪解析斜率和细波纹斜率相加，构造并归一化世界空间法线。Schlick Fresnel 使用水的正视反射率约 2.04%，斜视时增强反射并减少透射。主节点 Normal Space 必须为 World。","26","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","325","327","328","330","331","333","335","339","358","375","04 真实方向法线与 Fresnel","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":397,"pos":[10860,15],"params":["Inherit","False","5780","1555","Depth Fade 减去已位移水面的线性眼空间深度，除以视线余弦得到水中路程。T=exp(-吸收系数×密度×路程)。开关关闭时透过率为 1，颜色使用浅水色；泡沫、焦散和折射仍可能需要共享深度。","49","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","332","334","336","337","338","350","353","363","365","05 真实深度与可选光吸收","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":398,"pos":[16860,15],"params":["Inherit","False","5100","2045","从水面沿相机视线和深度间隙重建水底位置，按水底世界 XZ 投影两层原创焦散纹理，缓慢错向流动。随垂直水深衰减并经水体吸收合成。关闭会裁掉焦散贡献；依赖屏幕水下透视，不是场景投影灯或水下相机效果。","49","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","340","341","343","344","345","347","349","351","371","06 水底焦散：重建位置与流动光网","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":399,"pos":[16860,2220],"params":["Inherit","False","4080","2045","按深度间隙生成岸沫，独立采样斜率纹理 B 通道作为流动噪声，再乘推进条带与接触软化。与细波纹开关独立；关闭泡沫会裁掉这个额外采样及粗糙度/颜色贡献。","45","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","246","247","352","354","355","356","357","370","377","381","07 可选浅岸泡沫","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":400,"pos":[22180,15],"params":["Inherit","False","5780","2045","相机空间法线扰动屏幕坐标，浅岸缩小偏移。水底颜色乘焦散光网，再经 RGB 吸收和可选散射，最后让出 Fresnel 与泡沫能量。关闭屏幕折射时改用水体颜色，裁掉屏幕采样和焦散；ShaderLab 的 GrabPass 拷贝仍存在。","50","248","249","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","359","360","361","362","364","366","368","372","373","374","376","378","387","08 可选屏幕折射与水下合成","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":402,"pos":[30100,15],"params":["Inherit","False","640","1310","从命名 Register 读取远处的法线、顶点位移等结果，在主节点旁连接到对应端口，避免长线横穿整个图。","5","384","386","388","390","392","09 主节点输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":14,"pos":[1290,115],"params":["Inherit","False","Constant","_Float1","Float 1","1","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":84,"pos":[5710,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":85,"pos":[5710,850],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":90,"pos":[2310,3545],"params":["Inherit","True","Property","_RippleSlope","02 Ripples / seamless slope field","4","0","Create","False","0","0","0","True","0","False","","None","None","False","gray","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":91,"pos":[1290,3545],"params":["Inherit","False","Property","_RippleScale","02 Ripples / tiling per meter","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":92,"pos":[3670,3545],"params":["Inherit","False","Property","_RippleStrength","02 Ripples / strength","6","0","Create","False","0","0","0","True","0","False","Object","-1","","0.48","0","0","1.5","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":93,"pos":[1970,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":94,"pos":[1630,3545],"params":["Inherit","False","Constant","_Vector4","Vector 4","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.036,0.021,0,0","0.036,0.021,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":95,"pos":[1970,3545],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":96,"pos":[2310,3790],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":97,"pos":[1630,4525],"params":["Inherit","False","FLOAT2","1","0","2","3","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":98,"pos":[1290,3790],"params":["Inherit","False","Constant","_Float11","Float 11","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1.63","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":99,"pos":[1630,4280],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":100,"pos":[1970,4770],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":101,"pos":[1630,3790],"params":["Inherit","False","Constant","_Vector5","Vector 5","7","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.019,0.029,0,0","-0.019,0.029,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":102,"pos":[1970,4035],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":103,"pos":[2310,4035],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":104,"pos":[2650,3545],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","7","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":105,"pos":[2650,3790],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":106,"pos":[2990,3545],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":107,"pos":[2990,3790],"params":["Inherit","False","FLOAT2","1","0","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":108,"pos":[3330,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":109,"pos":[3330,3545],"params":["Inherit","False","Constant","_Float12","Float 12","9","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":110,"pos":[3670,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":111,"pos":[4010,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":112,"pos":[3670,3790],"params":["Inherit","False","Constant","_Vector6","Vector 6","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":113,"pos":[4010,3790],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":114,"pos":[4350,3545],"params":["Inherit","False","Property","_WATER_RIPPLES","Enable / 02 Fine ripples (2 samples)","7","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT2","0,0","False","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT2","0,0","False","6","FLOAT2","0,0","False","7","FLOAT2","0,0","False","8","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":115,"pos":[7970,1095],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":116,"pos":[8310,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":117,"pos":[8650,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":118,"pos":[7970,1340],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":119,"pos":[8310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":120,"pos":[8650,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":121,"pos":[8650,115],"params":["Inherit","False","Constant","_Float13","Float 13","10","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":122,"pos":[8990,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.NormalizeNode, AmplifyShaderEditor","id":123,"pos":[9330,850],"params":["Inherit","False","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ViewDirInputsCoordNode, AmplifyShaderEditor","id":124,"pos":[7630,115],"params":["Inherit","False","World","False","0","4","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3"]}
{"type":"AmplifyShaderEditor.FresnelNode, AmplifyShaderEditor","id":125,"pos":[9670,360],"params":["Inherit","False","Standard","WorldNormal","ViewDir","False","False","5","0","FLOAT3","0,0,1","False","4","FLOAT3","0,0,0","False","1","FLOAT","0","False","2","FLOAT","1","False","3","FLOAT","5","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":126,"pos":[9330,115],"params":["Inherit","False","Constant","_Float14","Float 14","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.02037","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":127,"pos":[9330,360],"params":["Inherit","False","Constant","_Float15","Float 15","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.97963","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":128,"pos":[9330,605],"params":["Inherit","False","Constant","_Float16","Float 16","10","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":129,"pos":[9670,115],"params":["Inherit","False","Constant","_Float17","Float 17","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":130,"pos":[10010,115],"params":["Inherit","False","Property","_WATER_FRESNEL","Enable / 03 Transmission Fresnel","8","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT","0","False","0","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","5","FLOAT","0","False","6","FLOAT","0","False","7","FLOAT","0","False","8","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DepthFade, AmplifyShaderEditor","id":131,"pos":[10910,115],"params":["Inherit","False","True","False","False","2","1","FLOAT3","0,0,0","False","0","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":132,"pos":[10910,360],"params":["Inherit","False","Constant","_Float18","Float 18","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":133,"pos":[11250,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":134,"pos":[11250,115],"params":["Inherit","False","Constant","_Float19","Float 19","11","0","Create","True","0","0","0","False","0","False","Object","-1","","80","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":135,"pos":[11590,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":136,"pos":[10910,605],"params":["Inherit","False","Constant","_Float20","Float 20","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":137,"pos":[11250,850],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToCameraMatrix, AmplifyShaderEditor","id":138,"pos":[11250,360],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":139,"pos":[11590,850],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":140,"pos":[11930,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":141,"pos":[12270,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":142,"pos":[12270,115],"params":["Inherit","False","Constant","_Float21","Float 21","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0.12","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":143,"pos":[12610,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":144,"pos":[12950,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":145,"pos":[12950,115],"params":["Inherit","False","Property","_Density","03 Depth / absorption density","9","0","Create","False","0","0","0","True","0","False","Object","-1","","0.7","0","0.01","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":146,"pos":[12950,360],"params":["Inherit","False","Property","_Absorption","03 Depth / absorption RGB (1/m)","10","0","Create","False","0","0","0","True","0","False","Object","-1","","0.85,0.32,0.17,0","0.85,0.32,0.17,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":147,"pos":[13290,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":148,"pos":[13290,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":149,"pos":[13630,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":150,"pos":[13970,360],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ExpOpNode, AmplifyShaderEditor","id":151,"pos":[14310,115],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":152,"pos":[13970,115],"params":["Inherit","False","Property","_DeepDistance","03 Depth / deep color distance (m)","11","0","Create","False","0","0","0","True","0","False","Object","-1","","5","0","0.1","25","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":153,"pos":[14310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":154,"pos":[14650,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":155,"pos":[14650,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":156,"pos":[14650,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":157,"pos":[14650,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":158,"pos":[14990,360],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":159,"pos":[14990,115],"params":["Inherit","False","Constant","_Vector7","Vector 7","14","0","Create","True","0","0","0","False","0","False","Object","-1","","1,1,1,0","1,1,1,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":160,"pos":[15330,605],"params":["Inherit","False","Property","_WATER_DEPTH","Enable / 04 Depth absorption and tint","12","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT4","0,0,0,0","False","0","FLOAT4","0,0,0,0","False","2","FLOAT4","0,0,0,0","False","3","FLOAT4","0,0,0,0","False","4","FLOAT4","0,0,0,0","False","5","FLOAT4","0,0,0,0","False","6","FLOAT4","0,0,0,0","False","7","FLOAT4","0,0,0,0","False","8","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":161,"pos":[15670,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":162,"pos":[15670,850],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":163,"pos":[15330,115],"params":["Inherit","False","Property","_ShallowColor","03 Depth / shallow scattering","13","0","Create","False","0","0","0","True","0","False","Object","-1","","0.12,0.48,0.4,1","0.12,0.48,0.4,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":164,"pos":[15670,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":165,"pos":[15330,360],"params":["Inherit","False","Property","_DeepColor","03 Depth / deep scattering","14","0","Create","False","0","0","0","True","0","False","Object","-1","","0.012,0.13,0.19,1","0.012,0.13,0.19,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":166,"pos":[15670,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":167,"pos":[16010,115],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":168,"pos":[11590,115],"params":["Inherit","False","Constant","_Float22","Float 22","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":169,"pos":[11590,360],"params":["Inherit","False","Constant","_Float23","Float 23","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":170,"pos":[11930,115],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":171,"pos":[17250,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":172,"pos":[17590,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":173,"pos":[18950,1340],"params":["Inherit","False","FLOAT2","0","2","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":174,"pos":[17930,115],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":175,"pos":[18270,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":176,"pos":[18270,115],"params":["Inherit","False","Constant","_Float24","Float 24","17","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":177,"pos":[18610,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":178,"pos":[19630,115],"params":["Inherit","True","Property","_CausticTex","06 Caustics / seamless light pattern","15","0","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":179,"pos":[18610,115],"params":["Inherit","False","Property","_CausticScale","06 Caustics / tiling per meter","16","0","Create","False","0","0","0","True","0","False","Object","-1","","0.28","0","0.05","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":180,"pos":[18950,115],"params":["Inherit","False","Property","_CausticSpeed","06 Caustics / animation speed","17","0","Create","False","0","0","0","True","0","False","Object","-1","","0.65","0","0","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":181,"pos":[19290,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":182,"pos":[18610,360],"params":["Inherit","False","Constant","_Float25","Float 25","20","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":183,"pos":[18950,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":184,"pos":[19290,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":185,"pos":[19630,605],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":186,"pos":[18950,360],"params":["Inherit","False","Constant","_Vector8","Vector 8","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0.025,0.017,0,0","0.025,0.017,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":187,"pos":[19290,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":188,"pos":[19970,360],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","20","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":189,"pos":[18610,605],"params":["Inherit","False","Constant","_Float26","Float 26","21","0","Create","True","0","0","0","False","0","False","Object","-1","","1.17","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":190,"pos":[18950,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":191,"pos":[19290,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":192,"pos":[19630,850],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":193,"pos":[18950,605],"params":["Inherit","False","Constant","_Vector9","Vector 9","21","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.018,0.023,0,0","-0.018,0.023,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":194,"pos":[19290,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":195,"pos":[19970,605],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","21","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":196,"pos":[20310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":197,"pos":[19970,115],"params":["Inherit","False","Property","_CausticStrength","06 Caustics / brightness","18","0","Create","False","0","0","0","True","0","False","Object","-1","","3","0","0","6","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":198,"pos":[18610,850],"params":["Inherit","False","Property","_CausticFalloff","06 Caustics / depth extinction","19","0","Create","False","0","0","0","True","0","False","Object","-1","","0.45","0","0","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":199,"pos":[18950,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":200,"pos":[19290,1340],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ExpOpNode, AmplifyShaderEditor","id":201,"pos":[19630,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":202,"pos":[19970,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":203,"pos":[20310,115],"params":["Inherit","False","Property","_CausticTint","06 Caustics / light tint","20","0","Create","False","0","0","0","True","0","False","Object","-1","","1,0.94,0.72,1","1,0.94,0.72,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":204,"pos":[20650,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":205,"pos":[20310,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":206,"pos":[20650,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":207,"pos":[20990,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":208,"pos":[20650,115],"params":["Inherit","False","Constant","_Vector10","Vector 10","25","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":209,"pos":[20990,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":210,"pos":[21330,115],"params":["Inherit","False","Property","_WATER_CAUSTICS","Enable / 06 Underwater caustics (2 samples)","21","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":211,"pos":[18270,3055],"params":["Inherit","True","Property","_TextureSample4","Texture Sample 4","26","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":212,"pos":[17250,2320],"params":["Inherit","False","Constant","_Float27","Float 27","27","0","Create","True","0","0","0","False","0","False","Object","-1","","0.48","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":213,"pos":[17590,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PannerNode, AmplifyShaderEditor","id":214,"pos":[17930,2565],"params":["Inherit","False","3","0","FLOAT2","0,0","False","2","FLOAT2","0,0","False","1","FLOAT","1","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":215,"pos":[17250,2565],"params":["Inherit","False","Constant","_Vector11","Vector 11","27","0","Create","True","0","0","0","False","0","False","Object","-1","","0.029,0.014,0,0","0.029,0.014,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":216,"pos":[17590,2565],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":217,"pos":[17250,2810],"params":["Inherit","False","Property","_FoamWidth","04 Foam / shoreline width (m)","22","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5","0","0.02","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":218,"pos":[17590,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":219,"pos":[17930,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":220,"pos":[18270,3545],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":221,"pos":[18610,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":222,"pos":[18270,2320],"params":["Inherit","False","Constant","_Float28","Float 28","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.34","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":223,"pos":[18270,2565],"params":["Inherit","False","Constant","_Float29","Float 29","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.66","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":224,"pos":[18610,2810],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":225,"pos":[16910,2320],"params":["Inherit","False","Constant","_Float30","Float 30","28","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":226,"pos":[17250,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":227,"pos":[16910,2565],"params":["Inherit","False","Constant","_Float31","Float 31","28","0","Create","True","0","0","0","False","0","False","Object","-1","","1.8","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":228,"pos":[17250,4035],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":229,"pos":[17590,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":230,"pos":[17930,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":231,"pos":[17930,2320],"params":["Inherit","False","Constant","_Float32","Float 32","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":232,"pos":[18270,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":233,"pos":[18270,2810],"params":["Inherit","False","Constant","_Float33","Float 33","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":234,"pos":[18610,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":235,"pos":[18610,2320],"params":["Inherit","False","Constant","_Float34","Float 34","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.35","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":236,"pos":[18610,2565],"params":["Inherit","False","Constant","_Float35","Float 35","28","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":237,"pos":[18950,2810],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":238,"pos":[18950,2320],"params":["Inherit","False","Property","_FoamStrength","04 Foam / amount","23","0","Create","False","0","0","0","True","0","False","Object","-1","","0.7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":239,"pos":[18950,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":240,"pos":[19290,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":241,"pos":[19290,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":242,"pos":[19630,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":243,"pos":[19970,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":244,"pos":[19970,2320],"params":["Inherit","False","Constant","_Float36","Float 36","29","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":245,"pos":[20310,2320],"params":["Inherit","False","Property","_WATER_FOAM","Enable / 05 Shore foam (1 noise sample)","24","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT","0","False","0","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","5","FLOAT","0","False","6","FLOAT","0","False","7","FLOAT","0","False","8","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":246,"pos":[16910,2810],"params":["Inherit","False","Property","_FoamColor","04 Foam / color","25","0","Create","False","0","0","0","True","0","False","Object","-1","","0.82,0.91,0.88,1","0.82,0.91,0.88,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":247,"pos":[17250,3790],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":248,"pos":[22570,1340],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":249,"pos":[22570,1585],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":250,"pos":[22570,1830],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":251,"pos":[22570,115],"params":["Inherit","False","Constant","_Float37","Float 37","31","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":252,"pos":[22910,1340],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.WorldToCameraMatrix, AmplifyShaderEditor","id":253,"pos":[22910,115],"params":["Inherit","False","0","1","FLOAT4x4","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":254,"pos":[23250,850],"params":["Inherit","False","2","2","0","FLOAT4x4","1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1","False","1","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":255,"pos":[23590,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":256,"pos":[23250,115],"params":["Inherit","False","Property","_RefractionStrength","05 Optics / refraction","26","0","Create","False","0","0","0","True","0","False","Object","-1","","0.014","0","0","0.05","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":257,"pos":[22570,360],"params":["Inherit","False","Constant","_Float38","Float 38","32","0","Create","True","0","0","0","False","0","False","Object","-1","","0.65","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":258,"pos":[22910,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":259,"pos":[23250,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":260,"pos":[23590,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":261,"pos":[23930,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GrabScreenPosition, AmplifyShaderEditor","id":262,"pos":[23590,115],"params":["Inherit","False","0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":263,"pos":[23930,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":264,"pos":[24270,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":265,"pos":[24610,115],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ScreenColorNode, AmplifyShaderEditor","id":266,"pos":[24950,360],"params":["Inherit","False","Global","_GrabScreen0","Grab Screen 0","32","0","Create","True","0","0","0","False","0","False","","Object","-1","False","False","False","False","True","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","5","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":267,"pos":[25290,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":268,"pos":[24950,115],"params":["Inherit","False","Constant","_Float39","Float 39","32","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":269,"pos":[25290,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":270,"pos":[25630,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":271,"pos":[25970,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":272,"pos":[22570,850],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":273,"pos":[22910,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":274,"pos":[22910,360],"params":["Inherit","False","Property","_ScatteringStrength","05 Optics / scattering","27","0","Create","False","0","0","0","True","0","False","Object","-1","","0.75","0","0","1.5","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":275,"pos":[23250,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":276,"pos":[22910,605],"params":["Inherit","False","Constant","_Vector12","Vector 12","33","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":277,"pos":[23250,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":278,"pos":[23590,360],"params":["Inherit","False","Property","_WATER_SCATTER","Enable / 07 Water scattering","28","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":279,"pos":[26310,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":280,"pos":[26650,605],"params":["Inherit","False","Property","_WATER_REFRACTION","Enable / 08 Screen refraction and bottom","29","0","Create","False","0","0","0","True","0","False","","0","1","1","True","","Toggle","2","Key0","Key1","Create","True","True","All","False","False","True","9","1","FLOAT3","0,0,0","False","0","FLOAT3","0,0,0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","5","FLOAT3","0,0,0","False","6","FLOAT3","0,0,0","False","7","FLOAT3","0,0,0","False","8","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":281,"pos":[26650,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":282,"pos":[26990,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor","id":283,"pos":[26990,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":284,"pos":[27330,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":285,"pos":[28230,115],"params":["Inherit","False","Property","_ReflectionStrength","05 Optics / reflection","30","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":286,"pos":[28570,115],"params":["Inherit","False","Constant","_Float40","Float 40","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.02037","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":287,"pos":[28570,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":288,"pos":[28910,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":289,"pos":[28910,115],"params":["Inherit","False","Constant","_Float41","Float 41","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.028","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":290,"pos":[29250,115],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":291,"pos":[29590,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":292,"pos":[28230,360],"params":["Inherit","False","Property","_Smoothness","05 Optics / smoothness","31","0","Create","False","0","0","0","True","0","False","Object","-1","","0.94","0","0.5","0.99","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":293,"pos":[28230,605],"params":["Inherit","False","Constant","_Float42","Float 42","37","0","Create","True","0","0","0","False","0","False","Object","-1","","0.28","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":294,"pos":[28570,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":295,"pos":[28230,850],"params":["Inherit","False","Constant","_Float43","Float 43","37","0","Create","True","0","0","0","False","0","False","Object","-1","","0.08","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":296,"pos":[28570,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":297,"pos":[28910,1095],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":320,"pos":[1630,4035],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":321,"pos":[1970,4280],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":322,"pos":[1290,4035],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":323,"pos":[1970,4525],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":324,"pos":[4690,3545],"params":["Inherit","False","ase_ripples_enabled_324","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":325,"pos":[7630,360],"params":["Inherit","False","324","ase_ripples_enabled_324","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":326,"pos":[6050,605],"params":["Inherit","False","ase_enabled_wave_slope_x_326","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":327,"pos":[7970,1585],"params":["Inherit","False","326","ase_enabled_wave_slope_x_326","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":328,"pos":[7630,605],"params":["Inherit","False","324","ase_ripples_enabled_324","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":329,"pos":[6050,850],"params":["Inherit","False","ase_enabled_wave_slope_z_329","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":330,"pos":[7970,1830],"params":["Inherit","False","329","ase_enabled_wave_slope_z_329","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":331,"pos":[7970,115],"params":["Inherit","False","ase_view_to_camera_ws_331","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":332,"pos":[10910,850],"params":["Inherit","False","331","ase_view_to_camera_ws_331","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":333,"pos":[7970,360],"params":["Inherit","False","ase_view_to_camera_ws_333","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":334,"pos":[10910,1095],"params":["Inherit","False","333","ase_view_to_camera_ws_333","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":335,"pos":[7970,605],"params":["Inherit","False","ase_view_to_camera_ws_335","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":336,"pos":[10910,1340],"params":["Inherit","False","335","ase_view_to_camera_ws_335","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":337,"pos":[13630,360],"params":["Inherit","False","ase_optical_path_m_337","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":338,"pos":[13970,605],"params":["Inherit","False","337","ase_optical_path_m_337","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":339,"pos":[7970,850],"params":["Inherit","False","ase_view_to_camera_ws_339","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":340,"pos":[16910,360],"params":["Inherit","False","339","ase_view_to_camera_ws_339","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":341,"pos":[16910,115],"params":["Inherit","False","337","ase_optical_path_m_337","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":342,"pos":[390,360],"params":["Inherit","False","ase_world_position_342","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":343,"pos":[17250,360],"params":["Inherit","False","342","ase_world_position_342","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":344,"pos":[18270,360],"params":["Inherit","False","ase_underwater_position_ws_344","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":345,"pos":[18610,1340],"params":["Inherit","False","344","ase_underwater_position_ws_344","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":346,"pos":[390,605],"params":["Inherit","False","ase_world_position_346","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":347,"pos":[17930,360],"params":["Inherit","False","346","ase_world_position_346","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":348,"pos":[390,850],"params":["Inherit","False","ase_time_seconds_348","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":349,"pos":[18950,1585],"params":["Inherit","False","348","ase_time_seconds_348","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":350,"pos":[12270,360],"params":["Inherit","False","ase_shore_contact_fade_350","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":351,"pos":[19630,360],"params":["Inherit","False","350","ase_shore_contact_fade_350","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":352,"pos":[17250,3055],"params":["Inherit","False","299","ase_world_xz_299","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":353,"pos":[11930,360],"params":["Inherit","False","ase_depth_eye_353","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":354,"pos":[17250,3300],"params":["Inherit","False","353","ase_depth_eye_353","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":355,"pos":[16910,3055],"params":["Inherit","False","353","ase_depth_eye_353","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":356,"pos":[16910,3300],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":357,"pos":[18950,2565],"params":["Inherit","False","350","ase_shore_contact_fade_350","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":358,"pos":[9670,605],"params":["Inherit","False","ase_water_normal_ws_358","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":359,"pos":[22230,360],"params":["Inherit","False","358","ase_water_normal_ws_358","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":360,"pos":[22230,605],"params":["Inherit","False","358","ase_water_normal_ws_358","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":361,"pos":[22230,850],"params":["Inherit","False","358","ase_water_normal_ws_358","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":362,"pos":[22570,1095],"params":["Inherit","False","353","ase_depth_eye_353","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":363,"pos":[16010,360],"params":["Inherit","False","ase_enabled_transmittance_363","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":364,"pos":[22230,115],"params":["Inherit","False","363","ase_enabled_transmittance_363","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":365,"pos":[16350,115],"params":["Inherit","False","ase_depth_scattering_color_365","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":366,"pos":[22570,605],"params":["Inherit","False","365","ase_depth_scattering_color_365","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":367,"pos":[28230,1585],"params":["Inherit","False","350","ase_shore_contact_fade_350","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":368,"pos":[23930,360],"params":["Inherit","False","ase_scattering_enabled_368","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":369,"pos":[28230,1830],"params":["Inherit","False","368","ase_scattering_enabled_368","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":370,"pos":[17590,2810],"params":["Inherit","False","301","ase_water_clock_301","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":371,"pos":[21670,115],"params":["Inherit","False","ase_caustics_enabled_371","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":372,"pos":[24950,605],"params":["Inherit","False","371","ase_caustics_enabled_371","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":373,"pos":[25630,360],"params":["Inherit","False","363","ase_enabled_transmittance_363","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":374,"pos":[26310,115],"params":["Inherit","False","365","ase_depth_scattering_color_365","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":375,"pos":[10350,115],"params":["Inherit","False","ase_fresnel_enabled_375","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":376,"pos":[26310,360],"params":["Inherit","False","375","ase_fresnel_enabled_375","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":377,"pos":[20650,2320],"params":["Inherit","False","ase_foam_enabled_377","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":378,"pos":[26650,115],"params":["Inherit","False","377","ase_foam_enabled_377","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":379,"pos":[28910,360],"params":["Inherit","False","377","ase_foam_enabled_377","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":380,"pos":[28230,1340],"params":["Inherit","False","377","ase_foam_enabled_377","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":381,"pos":[17590,3545],"params":["Inherit","False","ase_foam_rgb_381","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":382,"pos":[28570,1585],"params":["Inherit","False","381","ase_foam_rgb_381","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":383,"pos":[28570,360],"params":["Inherit","False","377","ase_foam_enabled_377","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":384,"pos":[30150,605],"params":["Inherit","False","358","ase_water_normal_ws_358","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":385,"pos":[28910,850],"params":["Inherit","False","ase_surface_smoothness_385","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":386,"pos":[30150,850],"params":["Inherit","False","385","ase_surface_smoothness_385","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":387,"pos":[27670,115],"params":["Inherit","False","ase_water_transmission_emission_387","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":388,"pos":[30150,115],"params":["Inherit","False","387","ase_water_transmission_emission_387","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":390,"pos":[30150,1095],"params":["Inherit","False","389","ase_composite_alpha_389","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":392,"pos":[30150,360],"params":["Inherit","False","391","ase_object_wave_offset_391","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","True","1","LightMode=ForwardBase","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[30790,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","6","Water/DeepWater_ASE","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","ForwardBase","0","1","ForwardBase","17","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Transparent=RenderType","Queue=Transparent=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=ForwardBase","False","False","0","","0","0","Standard","45","Category","0","0","  Instanced Terrain Normals","1","0","Workflow","0","0","Surface","1","0","  Blend","4","0","  Dither Shadows","1","0","Two Sided","1","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Deferred Pass","0","0","Normal Space","2","0","Transmission","0","0","  Transmission Shadow","0.5,False,","0","Translucency","0","0","  Translucency Strength","1,False,","0","  Normal Distortion","0.5,False,","0","  Scattering","2,False,","0","  Direct","0.9,False,","0","  Ambient","0.1,False,","0","  Shadow","0.5,False,","0","Cast Shadows","0","0","Receive Shadows","1","0","Receive Specular","2","0","Receive Reflections","2","0","GPU Instancing","1","0","LOD CrossFade","0","0","Built-in Fog","1","0","Ambient Light","1","0","Meta Pass","0","0","Add Pass","0","0","Override Baked GI","0","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Tessellation","0","0","  Phong","0","0","  Strength","0.5,False,","0","  Type","0","0","  Tess","16,False,","0","  Min","10,False,","0","  Max","25,False,","0","  Edge Length","16,False,","0","  Max Displacement","25,False,","0","Disable Batching","0","0","Vertex Position","1","0","0","8","False","True","False","False","False","False","True","True","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","ForwardAdd","0","2","ForwardAdd","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","True","1","1","False","","1","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","True","1","LightMode=ForwardAdd","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":3,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","Deferred","0","3","Deferred","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Deferred","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":4,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","Meta","0","4","Meta","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=Meta","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":5,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","ShadowCaster","0","5","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":6,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","SceneSelectionPass","0","6","SceneSelectionPass","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","False","False","False","True","1","LightMode=SceneSelectionPass","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":7,"pos":[30790,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","ed95fe726fd7b4644bb42f4d1ddd2bcd","True","ScenePickingPass","0","7","ScenePickingPass","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","True","1","False","","True","3","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","DisableBatching=False=DisableBatching","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","False","False","False","True","1","LightMode=Picking","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[9,0,8,0]}
{"wire":[12,0,10,0]}
{"wire":[12,1,11,0]}
{"wire":[18,0,17,0]}
{"wire":[37,0,36,0]}
{"wire":[299,0,9,0]}
{"wire":[301,0,12,0]}
{"wire":[19,0,18,0]}
{"wire":[19,1,16,0]}
{"wire":[38,0,37,0]}
{"wire":[38,1,16,0]}
{"wire":[56,0,55,0]}
{"wire":[20,0,300,0]}
{"wire":[20,1,19,0]}
{"wire":[22,0,302,0]}
{"wire":[22,1,21,0]}
{"wire":[39,0,306,0]}
{"wire":[39,1,38,0]}
{"wire":[41,0,307,0]}
{"wire":[41,1,40,0]}
{"wire":[57,0,56,0]}
{"wire":[57,1,16,0]}
{"wire":[23,0,20,0]}
{"wire":[23,1,22,0]}
{"wire":[42,0,39,0]}
{"wire":[42,1,41,0]}
{"wire":[46,0,15,0]}
{"wire":[46,1,45,0]}
{"wire":[58,0,313,0]}
{"wire":[58,1,57,0]}
{"wire":[60,0,314,0]}
{"wire":[60,1,59,0]}
{"wire":[303,0,19,0]}
{"wire":[310,0,38,0]}
{"wire":[25,0,23,0]}
{"wire":[25,1,24,0]}
{"wire":[30,0,25,0]}
{"wire":[44,0,42,0]}
{"wire":[44,1,43,0]}
{"wire":[49,0,44,0]}
{"wire":[61,0,58,0]}
{"wire":[61,1,60,0]}
{"wire":[308,0,46,0]}
{"wire":[315,0,57,0]}
{"wire":[27,0,15,0]}
{"wire":[27,1,26,0]}
{"wire":[28,0,25,0]}
{"wire":[31,0,30,0]}
{"wire":[31,1,27,0]}
{"wire":[32,0,304,0]}
{"wire":[34,0,305,0]}
{"wire":[47,0,44,0]}
{"wire":[50,0,49,0]}
{"wire":[50,1,46,0]}
{"wire":[51,0,311,0]}
{"wire":[53,0,312,0]}
{"wire":[63,0,61,0]}
{"wire":[63,1,62,0]}
{"wire":[68,0,63,0]}
{"wire":[29,0,28,0]}
{"wire":[29,1,27,0]}
{"wire":[33,0,31,0]}
{"wire":[33,1,32,0]}
{"wire":[35,0,31,0]}
{"wire":[35,1,34,0]}
{"wire":[48,0,47,0]}
{"wire":[48,1,309,0]}
{"wire":[52,0,50,0]}
{"wire":[52,1,51,0]}
{"wire":[54,0,50,0]}
{"wire":[54,1,53,0]}
{"wire":[65,0,15,0]}
{"wire":[65,1,64,0]}
{"wire":[66,0,63,0]}
{"wire":[69,0,68,0]}
{"wire":[69,1,65,0]}
{"wire":[70,0,316,0]}
{"wire":[72,0,317,0]}
{"wire":[67,0,66,0]}
{"wire":[67,1,65,0]}
{"wire":[71,0,69,0]}
{"wire":[71,1,70,0]}
{"wire":[73,0,69,0]}
{"wire":[73,1,72,0]}
{"wire":[74,0,29,0]}
{"wire":[74,1,48,0]}
{"wire":[76,0,33,0]}
{"wire":[76,1,52,0]}
{"wire":[78,0,35,0]}
{"wire":[78,1,54,0]}
{"wire":[75,0,74,0]}
{"wire":[75,1,67,0]}
{"wire":[77,0,76,0]}
{"wire":[77,1,71,0]}
{"wire":[79,0,78,0]}
{"wire":[79,1,73,0]}
{"wire":[80,0,75,0]}
{"wire":[80,1,77,0]}
{"wire":[80,2,79,0]}
{"wire":[80,3,13,0]}
{"wire":[82,1,81,0]}
{"wire":[82,0,80,0]}
{"wire":[318,0,13,0]}
{"wire":[83,0,82,0]}
{"wire":[86,0,319,0]}
{"wire":[86,1,83,0]}
{"wire":[86,2,319,0]}
{"wire":[86,3,319,0]}
{"wire":[88,0,87,0]}
{"wire":[88,1,86,0]}
{"wire":[89,0,88,0]}
{"wire":[389,0,298,0]}
{"wire":[391,0,89,0]}
{"wire":[84,0,82,0]}
{"wire":[85,0,82,0]}
{"wire":[93,0,320,0]}
{"wire":[93,1,91,0]}
{"wire":[95,0,94,0]}
{"wire":[96,0,93,0]}
{"wire":[96,2,95,0]}
{"wire":[96,1,321,0]}
{"wire":[97,0,322,0]}
{"wire":[99,0,91,0]}
{"wire":[99,1,98,0]}
{"wire":[100,0,97,0]}
{"wire":[100,1,99,0]}
{"wire":[102,0,101,0]}
{"wire":[103,0,100,0]}
{"wire":[103,2,102,0]}
{"wire":[103,1,323,0]}
{"wire":[104,0,90,0]}
{"wire":[104,1,96,0]}
{"wire":[105,0,90,0]}
{"wire":[105,1,103,0]}
{"wire":[106,0,104,0]}
{"wire":[107,0,105,0]}
{"wire":[108,0,106,0]}
{"wire":[108,1,107,0]}
{"wire":[110,0,108,0]}
{"wire":[110,1,109,0]}
{"wire":[111,0,110,0]}
{"wire":[111,1,92,0]}
{"wire":[113,0,112,0]}
{"wire":[114,1,113,0]}
{"wire":[114,0,111,0]}
{"wire":[115,0,325,0]}
{"wire":[116,0,327,0]}
{"wire":[116,1,115,0]}
{"wire":[117,0,116,0]}
{"wire":[118,0,328,0]}
{"wire":[119,0,330,0]}
{"wire":[119,1,118,0]}
{"wire":[120,0,119,0]}
{"wire":[122,0,117,0]}
{"wire":[122,1,121,0]}
{"wire":[122,2,120,0]}
{"wire":[123,0,122,0]}
{"wire":[125,0,123,0]}
{"wire":[125,4,124,0]}
{"wire":[125,1,126,0]}
{"wire":[125,2,127,0]}
{"wire":[125,3,128,0]}
{"wire":[130,1,129,0]}
{"wire":[130,0,125,0]}
{"wire":[133,0,131,0]}
{"wire":[133,1,132,0]}
{"wire":[135,0,133,0]}
{"wire":[135,1,134,0]}
{"wire":[137,0,332,0]}
{"wire":[137,1,334,0]}
{"wire":[137,2,336,0]}
{"wire":[137,3,136,0]}
{"wire":[139,0,138,0]}
{"wire":[139,1,137,0]}
{"wire":[140,0,139,0]}
{"wire":[141,0,140,0]}
{"wire":[143,0,141,0]}
{"wire":[143,1,142,0]}
{"wire":[144,0,135,0]}
{"wire":[144,1,143,0]}
{"wire":[147,0,146,0]}
{"wire":[148,0,144,0]}
{"wire":[148,1,145,0]}
{"wire":[149,0,148,0]}
{"wire":[149,1,147,0]}
{"wire":[150,0,149,0]}
{"wire":[151,0,150,0]}
{"wire":[153,0,338,0]}
{"wire":[153,1,152,0]}
{"wire":[154,0,153,0]}
{"wire":[155,0,151,0]}
{"wire":[156,0,151,0]}
{"wire":[157,0,151,0]}
{"wire":[158,0,155,0]}
{"wire":[158,1,156,0]}
{"wire":[158,2,157,0]}
{"wire":[158,3,154,0]}
{"wire":[160,1,159,0]}
{"wire":[160,0,158,0]}
{"wire":[161,0,160,0]}
{"wire":[162,0,160,0]}
{"wire":[164,0,163,0]}
{"wire":[166,0,165,0]}
{"wire":[167,0,164,0]}
{"wire":[167,1,166,0]}
{"wire":[167,2,162,0]}
{"wire":[170,0,135,0]}
{"wire":[170,1,168,0]}
{"wire":[170,2,169,0]}
{"wire":[171,0,340,0]}
{"wire":[171,1,341,0]}
{"wire":[172,0,343,0]}
{"wire":[172,1,171,0]}
{"wire":[173,0,345,0]}
{"wire":[174,0,172,0]}
{"wire":[175,0,347,0]}
{"wire":[175,1,174,0]}
{"wire":[177,0,175,0]}
{"wire":[177,1,176,0]}
{"wire":[181,0,349,0]}
{"wire":[181,1,180,0]}
{"wire":[183,0,179,0]}
{"wire":[183,1,182,0]}
{"wire":[184,0,173,0]}
{"wire":[184,1,183,0]}
{"wire":[185,0,184,0]}
{"wire":[185,2,187,0]}
{"wire":[185,1,181,0]}
{"wire":[187,0,186,0]}
{"wire":[188,0,178,0]}
{"wire":[188,1,185,0]}
{"wire":[190,0,179,0]}
{"wire":[190,1,189,0]}
{"wire":[191,0,173,0]}
{"wire":[191,1,190,0]}
{"wire":[192,0,191,0]}
{"wire":[192,2,194,0]}
{"wire":[192,1,181,0]}
{"wire":[194,0,193,0]}
{"wire":[195,0,178,0]}
{"wire":[195,1,192,0]}
{"wire":[196,0,188,1]}
{"wire":[196,1,195,1]}
{"wire":[199,0,177,0]}
{"wire":[199,1,198,0]}
{"wire":[200,0,199,0]}
{"wire":[201,0,200,0]}
{"wire":[202,0,201,0]}
{"wire":[202,1,351,0]}
{"wire":[204,0,203,0]}
{"wire":[205,0,197,0]}
{"wire":[205,1,202,0]}
{"wire":[206,0,196,0]}
{"wire":[206,1,205,0]}
{"wire":[207,0,204,0]}
{"wire":[207,1,206,0]}
{"wire":[209,0,208,0]}
{"wire":[210,1,209,0]}
{"wire":[210,0,207,0]}
{"wire":[211,0,90,0]}
{"wire":[211,1,214,0]}
{"wire":[213,0,352,0]}
{"wire":[213,1,212,0]}
{"wire":[214,0,213,0]}
{"wire":[214,2,216,0]}
{"wire":[214,1,370,0]}
{"wire":[216,0,215,0]}
{"wire":[218,0,354,0]}
{"wire":[218,1,217,0]}
{"wire":[219,0,218,0]}
{"wire":[220,0,219,0]}
{"wire":[221,0,220,0]}
{"wire":[221,1,220,0]}
{"wire":[224,0,211,3]}
{"wire":[224,1,222,0]}
{"wire":[224,2,223,0]}
{"wire":[226,0,355,0]}
{"wire":[226,1,225,0]}
{"wire":[228,0,356,0]}
{"wire":[228,1,227,0]}
{"wire":[229,0,226,0]}
{"wire":[229,1,228,0]}
{"wire":[230,0,229,0]}
{"wire":[232,0,230,0]}
{"wire":[232,1,231,0]}
{"wire":[234,0,232,0]}
{"wire":[234,1,233,0]}
{"wire":[237,0,235,0]}
{"wire":[237,1,236,0]}
{"wire":[237,2,234,0]}
{"wire":[239,0,221,0]}
{"wire":[239,1,224,0]}
{"wire":[240,0,239,0]}
{"wire":[240,1,237,0]}
{"wire":[241,0,238,0]}
{"wire":[241,1,357,0]}
{"wire":[242,0,240,0]}
{"wire":[242,1,241,0]}
{"wire":[243,0,242,0]}
{"wire":[245,1,244,0]}
{"wire":[245,0,243,0]}
{"wire":[247,0,246,0]}
{"wire":[248,0,359,0]}
{"wire":[249,0,360,0]}
{"wire":[250,0,361,0]}
{"wire":[252,0,248,0]}
{"wire":[252,1,249,0]}
{"wire":[252,2,250,0]}
{"wire":[252,3,251,0]}
{"wire":[254,0,253,0]}
{"wire":[254,1,252,0]}
{"wire":[255,0,254,0]}
{"wire":[258,0,362,0]}
{"wire":[258,1,257,0]}
{"wire":[259,0,258,0]}
{"wire":[260,0,256,0]}
{"wire":[260,1,259,0]}
{"wire":[261,0,255,0]}
{"wire":[261,1,260,0]}
{"wire":[263,0,262,0]}
{"wire":[264,0,263,0]}
{"wire":[264,1,261,0]}
{"wire":[265,0,264,0]}
{"wire":[266,0,265,0]}
{"wire":[267,0,266,0]}
{"wire":[269,0,268,0]}
{"wire":[269,1,372,0]}
{"wire":[270,0,267,0]}
{"wire":[270,1,269,0]}
{"wire":[271,0,270,0]}
{"wire":[271,1,373,0]}
{"wire":[272,0,364,0]}
{"wire":[273,0,366,0]}
{"wire":[273,1,272,0]}
{"wire":[275,0,273,0]}
{"wire":[275,1,274,0]}
{"wire":[277,0,276,0]}
{"wire":[278,1,277,0]}
{"wire":[278,0,275,0]}
{"wire":[279,0,271,0]}
{"wire":[279,1,278,0]}
{"wire":[280,1,374,0]}
{"wire":[280,0,279,0]}
{"wire":[281,0,376,0]}
{"wire":[282,0,280,0]}
{"wire":[282,1,281,0]}
{"wire":[283,0,378,0]}
{"wire":[284,0,282,0]}
{"wire":[284,1,283,0]}
{"wire":[287,0,285,0]}
{"wire":[287,1,367,0]}
{"wire":[288,0,286,0]}
{"wire":[288,1,287,0]}
{"wire":[290,0,288,0]}
{"wire":[290,1,289,0]}
{"wire":[290,2,379,0]}
{"wire":[291,0,290,0]}
{"wire":[291,1,290,0]}
{"wire":[291,2,290,0]}
{"wire":[294,0,292,0]}
{"wire":[294,1,293,0]}
{"wire":[294,2,380,0]}
{"wire":[296,0,369,0]}
{"wire":[296,1,295,0]}
{"wire":[297,0,296,0]}
{"wire":[297,1,382,0]}
{"wire":[297,2,383,0]}
{"wire":[324,0,114,0]}
{"wire":[326,0,84,0]}
{"wire":[329,0,85,0]}
{"wire":[331,0,124,1]}
{"wire":[333,0,124,2]}
{"wire":[335,0,124,3]}
{"wire":[337,0,144,0]}
{"wire":[339,0,124,0]}
{"wire":[342,0,8,0]}
{"wire":[344,0,172,0]}
{"wire":[346,0,8,2]}
{"wire":[348,0,10,0]}
{"wire":[350,0,170,0]}
{"wire":[353,0,135,0]}
{"wire":[358,0,123,0]}
{"wire":[363,0,161,0]}
{"wire":[365,0,167,0]}
{"wire":[368,0,278,0]}
{"wire":[371,0,210,0]}
{"wire":[375,0,130,0]}
{"wire":[377,0,245,0]}
{"wire":[381,0,247,0]}
{"wire":[385,0,294,0]}
{"wire":[387,0,284,0]}
{"wire":[1,0,297,0]}
{"wire":[1,1,384,0]}
{"wire":[1,3,291,0]}
{"wire":[1,5,386,0]}
{"wire":[1,2,388,0]}
{"wire":[1,7,390,0]}
{"wire":[1,15,392,0]}
ASEEND*/
//CHKSM=B0A2DE7B2C14B3EAE2C0FEA5EC50B3CBD616B02D