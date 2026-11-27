// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "CH/Paths/Custom2TexV2/Built-in"
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

	}
	
	SubShader
	{
		

		

		Tags { "RenderType"="Transparent" "Queue"="Transparent" }

	LOD 0

		ZWrite [_ZWriteMode]
		ZClip True
		Cull [_CullMode]
		AlphaToMask Off
		ColorMask RGBA
		Blend One Zero, One Zero
		BlendOp Add, Add
		Offset 0 , 0

		

		Blend [_Src] [_Dst], One OneMinusSrcAlpha
		

		CGINCLUDE
			#pragma target 3.0
			// ensure rendering platforms toggle list is visible

			#ifndef GLOBAL_HEADER_INCLUDED
			#define GLOBAL_HEADER_INCLUDED
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

		
		Pass
		{
			
			Name "Unlit"

			Cull [_CullMode]
			ZWrite [_ZWriteMode]
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Blend [_Src] [_Dst], One OneMinusSrcAlpha
			BlendOp Add, Add

			

			CGPROGRAM
				#define ASE_SURFACE_TRANSPARENT
				#define ASE_VERSION 19913

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#include "UnityCG.cginc"

				#include "UnityShaderVariables.cginc"
				#define ASE_NEEDS_TEXTURE_COORDINATES0
				#define ASE_NEEDS_TEXTURE_COORDINATES1
				#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
				#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1
				#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
				#define ASE_NEEDS_FRAG_COLOR


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
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float4 ase_texcoord : TEXCOORD0;
					float4 ase_texcoord1 : TEXCOORD1;
					half4 ase_color : COLOR;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS float4 pos : SV_POSITION;
					float4 ase_texcoord : TEXCOORD0;
					float4 ase_texcoord1 : TEXCOORD1;
					float4 ase_color : COLOR;
					float4 ase_texcoord2 : TEXCOORD2;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				uniform float _Dst;
				uniform float _ZWriteMode;
				uniform float _CullMode;
				uniform float _Src;
				uniform float _EdgeWidth;
				uniform sampler2D _DissolveMap;
				uniform half4 _DissolveMap_ST;
				uniform float _Dissolve_Int;
				uniform float _CustomDate1;
				uniform half4 _EdgeColor;
				uniform sampler2D _MainTex;
				uniform half2 _MainTexPanner;
				uniform half4 _MainTex_ST;
				uniform sampler2D _DisturbanceTex;
				uniform half2 _DisturbancePanner;
				uniform half4 _DisturbanceTex_ST;
				uniform float _DisturbanceTexIntensity;
				uniform float _DisturbanceONOFF;
				uniform half4 _MainTexColor;
				uniform float _MainTexIntensity;
				uniform sampler2D _AddTex;
				uniform half2 _AddTexPanner;
				uniform half4 _AddTex_ST;
				uniform half4 _AddTexColor;
				uniform float _AddTexIntensity;
				uniform float _TexBlendMode;
				uniform float _VertexColor;
				UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
				uniform float4 _CameraDepthTexture_TexelSize;
				uniform float _SoftParticleDistance;
				uniform float _SoftParticleOnARGBA;
				uniform float _RA;
				uniform sampler2D _MaskTex;
				uniform half4 _MaskTex_ST;
				uniform float _Mask_pow;
				uniform half2 _DistanceA;
				uniform float _DistanceMin;
				uniform float _DistanceMax;
				uniform float _DistanceOnOff;


				float ASELinearEyeDepth( float rawDepth )
				{
					#if UNITY_REVERSED_Z
					float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#else
					float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#endif
					return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth ) : orthoDepth;
				}
				

				v2f vert( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID(v);
					v2f o;
					UNITY_INITIALIZE_OUTPUT(v2f,o);
					UNITY_TRANSFER_INSTANCE_ID(v,o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					float3 ase_positionWS = mul( unity_ObjectToWorld, float4( ( v.vertex ).xyz, 1 ) ).xyz;
					o.ase_texcoord2.xyz = ase_positionWS;
					
					o.ase_texcoord.xy = v.ase_texcoord.xy;
					o.ase_texcoord1 = v.ase_texcoord1;
					o.ase_color = v.ase_color;
					
					//setting value to unused interpolator channels and avoid initialization warnings
					o.ase_texcoord.zw = 0;
					o.ase_texcoord2.w = 0;

					#ifdef ASE_ABSOLUTE_VERTEX_POS
						float3 defaultVertexValue = v.vertex.xyz;
					#else
						float3 defaultVertexValue = float3(0, 0, 0);
					#endif
					float3 vertexValue = defaultVertexValue;
					#ifdef ASE_ABSOLUTE_VERTEX_POS
						v.vertex.xyz = vertexValue;
					#else
						v.vertex.xyz += vertexValue;
					#endif
					v.vertex.w = 1;
					v.normal = v.normal;
					v.tangent = v.tangent;

					o.pos = UnityObjectToClipPos( v.vertex );

					#if defined( ASE_SHADOWS )
						UNITY_TRANSFER_SHADOW( o, v.texcoord );
					#endif
					return o;
				}

				half4 frag( v2f IN 
							#if defined( ASE_WRITE_DEPTH )
								, out float outputDepth : SV_Depth
							#endif
				) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID( IN );
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

					float4 ScreenPosNorm = float4( IN.pos.xy * ( _ScreenParams.zw - 1.0 ), IN.pos.zw );
					float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, IN.pos.z ) * IN.pos.w;
					float4 ScreenPos = ComputeScreenPos( ClipPos );

					half2 uv_DissolveMap = IN.ase_texcoord.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
					half4 texCoord228 = IN.ase_texcoord1;
					texCoord228.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
					half CustomDate206 = _CustomDate1;
					half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
					half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
					half4 Dissolve_RGB137 = ( smoothstepResult93 * _EdgeColor );
					half3 appendResult155 = (half3(Dissolve_RGB137.rgb));
					half2 uv_MainTex = IN.ase_texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					half2 uv_DisturbanceTex = IN.ase_texcoord.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
					half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
					half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
					half4 texCoord73 = IN.ase_texcoord1;
					texCoord73.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
					half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
					half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
					half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
					half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
					half2 uv_AddTex = IN.ase_texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
					half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
					half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
					half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
					half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
					half4 BlendColor111 = lerpResult78;
					half3 appendResult156 = (half3(BlendColor111.rgb));
					half Dissolve_A126 = smoothstepResult93;
					half3 lerpResult102 = lerp( appendResult155 , appendResult156 , Dissolve_A126);
					half3 lerpResult89 = lerp( float3( 1,1,1 ) , (IN.ase_color).rgb , _VertexColor);
					half3 Vertex_RGB130 = lerpResult89;
					half3 RGB123 = ( lerpResult102 * Vertex_RGB130 );
					float screenDepth258 = ASELinearEyeDepth( SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ScreenPosNorm.xy ) );
					half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ScreenPosNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
					half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
					half lerpResult264 = lerp( 1.0 , lerpResult259 , saturate( ( _SoftParticleOnARGBA - 1.0 ) ));
					
					half lerpResult92 = lerp( 1.0 , (IN.ase_color).a , _VertexColor);
					half Vertex_A131 = lerpResult92;
					half4 break116 = BlendColor111;
					half lerpResult76 = lerp( break116.r , break116.a , _RA);
					half2 uv_MaskTex = IN.ase_texcoord.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
					half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
					half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
					float3 ase_positionWS = IN.ase_texcoord2.xyz;
					half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
					half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
					half DistanceFade244 = lerpResult241;
					half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
					half A135 = lerpResult248;
					

					float3 Color = ( RGB123 * lerpResult264 );
					float Alpha = ( A135 * lerpResult259 );
					half AlphaClipThreshold = 0.5;
					half AlphaClipThresholdShadow = 0.5;

					#if defined( ASE_WRITE_DEPTH )
						outputDepth = IN.pos.z;
					#endif

					#ifdef _ALPHATEST_ON
						clip( Alpha - AlphaClipThreshold );
					#endif

				#if defined( ASE_SURFACE_TRANSPARENT ) || defined( ASE_OPAQUE_KEEP_ALPHA )
					return half4( Color, Alpha );
				#else
					return half4( Color, 1.0 );
				#endif
				}
			ENDCG
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			CGPROGRAM
				#define ASE_SURFACE_TRANSPARENT
				#define ASE_VERSION 19913

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_shadowcaster
				#ifndef UNITY_PASS_SHADOWCASTER
					#define UNITY_PASS_SHADOWCASTER
				#endif
				#include "UnityCG.cginc"

				#include "UnityShaderVariables.cginc"
				#define ASE_NEEDS_TEXTURE_COORDINATES0
				#define ASE_NEEDS_TEXTURE_COORDINATES1
				#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
				#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES1


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
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					half4 ase_color : COLOR;
					float4 ase_texcoord : TEXCOORD0;
					float4 ase_texcoord1 : TEXCOORD1;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS UNITY_POSITION( pos );
					V2F_SHADOW_CASTER_NOPOS
					float4 ase_color : COLOR;
					float4 ase_texcoord1 : TEXCOORD1;
					float4 ase_texcoord2 : TEXCOORD2;
					float4 ase_texcoord3 : TEXCOORD3;
					float4 ase_texcoord4 : TEXCOORD4;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				#ifdef UNITY_STANDARD_USE_DITHER_MASK
					sampler3D _DitherMaskLOD;
				#endif

				uniform float _Dst;
				uniform float _ZWriteMode;
				uniform float _CullMode;
				uniform float _Src;
				uniform float _VertexColor;
				uniform float _EdgeWidth;
				uniform sampler2D _DissolveMap;
				uniform half4 _DissolveMap_ST;
				uniform float _Dissolve_Int;
				uniform float _CustomDate1;
				uniform sampler2D _MainTex;
				uniform half2 _MainTexPanner;
				uniform half4 _MainTex_ST;
				uniform sampler2D _DisturbanceTex;
				uniform half2 _DisturbancePanner;
				uniform half4 _DisturbanceTex_ST;
				uniform float _DisturbanceTexIntensity;
				uniform float _DisturbanceONOFF;
				uniform half4 _MainTexColor;
				uniform float _MainTexIntensity;
				uniform sampler2D _AddTex;
				uniform half2 _AddTexPanner;
				uniform half4 _AddTex_ST;
				uniform half4 _AddTexColor;
				uniform float _AddTexIntensity;
				uniform float _TexBlendMode;
				uniform float _RA;
				uniform sampler2D _MaskTex;
				uniform half4 _MaskTex_ST;
				uniform float _Mask_pow;
				uniform half2 _DistanceA;
				uniform float _DistanceMin;
				uniform float _DistanceMax;
				uniform float _DistanceOnOff;
				UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
				uniform float4 _CameraDepthTexture_TexelSize;
				uniform float _SoftParticleDistance;
				uniform float _SoftParticleOnARGBA;


				float ASELinearEyeDepth( float rawDepth )
				{
					#if UNITY_REVERSED_Z
					float orthoDepth = _ProjectionParams.z - ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#else
					float orthoDepth = _ProjectionParams.y + ( _ProjectionParams.z - _ProjectionParams.y ) * rawDepth;
					#endif
					return ( unity_OrthoParams.w == 0 ) ? LinearEyeDepth( rawDepth ) : orthoDepth;
				}
				

				v2f vert( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID( v );
					v2f o;
					UNITY_INITIALIZE_OUTPUT( v2f, o );
					UNITY_TRANSFER_INSTANCE_ID( v, o );
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

					float3 ase_positionWS = mul( unity_ObjectToWorld, float4( ( v.vertex ).xyz, 1 ) ).xyz;
					o.ase_texcoord3.xyz = ase_positionWS;
					float4 ase_positionCS = UnityObjectToClipPos( v.vertex );
					float4 screenPos = ComputeScreenPos( ase_positionCS );
					o.ase_texcoord4 = screenPos;
					
					o.ase_color = v.ase_color;
					o.ase_texcoord1.xy = v.ase_texcoord.xy;
					o.ase_texcoord2 = v.ase_texcoord1;
					
					//setting value to unused interpolator channels and avoid initialization warnings
					o.ase_texcoord1.zw = 0;
					o.ase_texcoord3.w = 0;

					#ifdef ASE_ABSOLUTE_VERTEX_POS
						float3 defaultVertexValue = v.vertex.xyz;
					#else
						float3 defaultVertexValue = float3(0, 0, 0);
					#endif
					float3 vertexValue = defaultVertexValue;
					#ifdef ASE_ABSOLUTE_VERTEX_POS
						v.vertex.xyz = vertexValue;
					#else
						v.vertex.xyz += vertexValue;
					#endif
					v.vertex.w = 1;
					v.normal = v.normal;
					v.tangent = v.tangent;

					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					return o;
				}

				half4 frag( v2f IN 
							#if defined( ASE_WRITE_DEPTH )
								, out float outputDepth : SV_Depth
							#endif
							) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(IN);

					#ifdef LOD_FADE_CROSSFADE
						UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
					#endif

					half lerpResult92 = lerp( 1.0 , (IN.ase_color).a , _VertexColor);
					half Vertex_A131 = lerpResult92;
					half2 uv_DissolveMap = IN.ase_texcoord1.xy * _DissolveMap_ST.xy + _DissolveMap_ST.zw;
					half4 texCoord228 = IN.ase_texcoord2;
					texCoord228.xy = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
					half CustomDate206 = _CustomDate1;
					half lerpResult183 = lerp( _Dissolve_Int , texCoord228.z , CustomDate206);
					half smoothstepResult93 = smoothstep( 0.0 , _EdgeWidth , ( tex2D( _DissolveMap, uv_DissolveMap ).r + 1.0 + ( -2.0 * lerpResult183 ) ));
					half Dissolve_A126 = smoothstepResult93;
					half2 uv_MainTex = IN.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					half2 uv_DisturbanceTex = IN.ase_texcoord1.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
					half2 panner19 = ( 1.0 * _Time.y * _DisturbancePanner + uv_DisturbanceTex);
					half2 lerpResult80 = lerp( uv_MainTex , ( ( tex2D( _DisturbanceTex, panner19 ).r * _DisturbanceTexIntensity ) + uv_MainTex ) , _DisturbanceONOFF);
					half4 texCoord73 = IN.ase_texcoord2;
					texCoord73.xy = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
					half2 appendResult75 = (half2(texCoord73.x , texCoord73.y));
					half2 lerpResult200 = lerp( lerpResult80 , ( appendResult75 + lerpResult80 ) , CustomDate206);
					half2 panner12 = ( 1.0 * _Time.y * _MainTexPanner + lerpResult200);
					half4 MainTexColor103 = ( tex2D( _MainTex, panner12 ) * _MainTexColor * _MainTexIntensity );
					half2 uv_AddTex = IN.ase_texcoord1.xy * _AddTex_ST.xy + _AddTex_ST.zw;
					half2 panner39 = ( 1.0 * _Time.y * _AddTexPanner + uv_AddTex);
					half4 AddTexColor108 = ( tex2D( _AddTex, panner39 ) * _AddTexColor * _AddTexIntensity );
					half4 lerpResult85 = lerp( ( AddTexColor108 * MainTexColor103 ) , ( AddTexColor108 + MainTexColor103 ) , step( 1.9 , _TexBlendMode ));
					half4 lerpResult78 = lerp( MainTexColor103 , lerpResult85 , step( 0.9 , _TexBlendMode ));
					half4 BlendColor111 = lerpResult78;
					half4 break116 = BlendColor111;
					half lerpResult76 = lerp( break116.r , break116.a , _RA);
					half2 uv_MaskTex = IN.ase_texcoord1.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
					half saferPower53 = abs( saturate( tex2D( _MaskTex, uv_MaskTex ).r ) );
					half temp_output_56_0 = ( Vertex_A131 * Dissolve_A126 * lerpResult76 * pow( saferPower53 , max( _Mask_pow, 0.001 ) ) );
					float3 ase_positionWS = IN.ase_texcoord3.xyz;
					half clampResult233 = clamp( distance( ase_positionWS , _WorldSpaceCameraPos ) , _DistanceMin , _DistanceMax );
					half lerpResult241 = lerp( _DistanceA.y , _DistanceA.x , ( ( clampResult233 - _DistanceMin ) / max( ( _DistanceMax - _DistanceMin ), 0.0001 ) ));
					half DistanceFade244 = lerpResult241;
					half lerpResult248 = lerp( ( temp_output_56_0 * DistanceFade244 ) , temp_output_56_0 , _DistanceOnOff);
					half A135 = lerpResult248;
					float4 screenPos = IN.ase_texcoord4;
					half4 ase_positionSSNorm = screenPos / screenPos.w;
					ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
					float screenDepth258 = ASELinearEyeDepth( SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_positionSSNorm.xy ) );
					half distanceDepth258 = saturate( ( screenDepth258 - ASELinearEyeDepth( ase_positionSSNorm.z ) ) / ( max( _SoftParticleDistance, 0.0001 ) ) );
					half lerpResult259 = lerp( 1.0 , distanceDepth258 , saturate( _SoftParticleOnARGBA ));
					

					float Alpha = ( A135 * lerpResult259 );
					half AlphaClipThreshold = 0.5;
					half AlphaClipThresholdShadow = 0.5;

					#if defined( ASE_WRITE_DEPTH )
						outputDepth = IN.pos.z;
					#endif

					#ifdef _ALPHATEST_SHADOW_ON
						if (unity_LightShadowBias.z != 0.0)
							clip(Alpha - AlphaClipThresholdShadow);
						#ifdef _ALPHATEST_ON
						else
							clip(Alpha - AlphaClipThreshold);
						#endif
					#else
						#ifdef _ALPHATEST_ON
							clip(Alpha - AlphaClipThreshold);
						#endif
					#endif

					#ifdef UNITY_STANDARD_USE_DITHER_MASK
						half alphaRef = tex3D(_DitherMaskLOD, float3(IN.pos.xy*0.25,Alpha*0.9375)).a;
						clip(alphaRef - 0.01);
					#endif

					SHADOW_CASTER_FRAGMENT(IN)
				}
			ENDCG
		}
		
	}
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	
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
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":251,"pos":[1291.095,-584.8531],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","16","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ShadowCaster","0","2","ShadowCaster","0","False","True","0","1","False","","0","False","","0","1","False","","0","False","","True","0","False","","0","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","False","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":252,"pos":[1291.095,-594.8531],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","16","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":69,"pos":[2568,-8],"params":["Half","False","True","-1","2","AmplifyShaderEditor.MaterialInspector","0","7","CH/Paths/Custom2TexV2/Built-in","0770190933193b94aaa3065e307002fa","True","Unlit","0","1","Unlit","8","True","True","1","5","True","_Src","10","True","_Dst","1","1","False","","10","False","","True","0","False","","0","False","","False","False","False","False","False","False","False","False","False","True","0","False","","True","True","0","True","_CullMode","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","True","True","0","True","_ZWriteMode","False","True","True","0","False","","0","False","","True","1","False","","True","2","RenderType=Transparent=RenderType","Queue=Transparent=Queue=0","True","2","True","12","all","0","False","True","1","5","True","_Src","10","True","_Dst","1","1","False","","10","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","True","True","0","True","_CullMode","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","True","_ZWriteMode","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","10","Surface","1","0","  Keep Alpha","0","0","  Blend","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Cast Shadows","1","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Vertex Position","1","0","0","3","False","True","True","False","","False","0"]}
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
{"wire":[69,0,260,0]}
{"wire":[69,7,265,0]}
ASEEND*/
//CHKSM=93EDBBCFA61C337A521C8A4B2BDF8ED19CC979E1