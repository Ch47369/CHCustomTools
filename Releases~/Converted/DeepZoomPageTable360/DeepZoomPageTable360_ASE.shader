// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DeepZoom/DeepZoomPageTable360_ASE"
{
	Properties
	{
		_TileArray( "Tile Array", 2DArray ) = "white" {}
		[NoScaleOffset] _PageTableTransform( "Page Table Transform", 2D ) = "black" {}
		[NoScaleOffset] _PageTableLayer( "Page Table Layer", 2D ) = "black" {}
		_PageTableGrid( "Page Table Grid", Vector ) = ( 1, 1, 1, 1 )
		[NoScaleOffset] _FallbackTex( "Fallback", 2D ) = "black" {}
		[Toggle] _FlipHorizontally( "Flip Horizontally", Float ) = 0

	}
	
	SubShader
	{
		

		

		Tags { "RenderType"="Opaque" "Queue"="Geometry" }

	LOD 0

		ZWrite On
		ZClip True
		Cull Back
		AlphaToMask Off
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

			Cull Front
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Blend One Zero, One Zero
			BlendOp Add, Add

			

			CGPROGRAM
				#define ASE_OPAQUE_KEEP_ALPHA
				#define ASE_VERSION 19913
				#define ASE_USING_SAMPLING_MACROS 1

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#include "UnityCG.cginc"

				#define ASE_NEEDS_TEXTURE_COORDINATES0
				#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
				#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
				#define SAMPLE_TEXTURE2D_ARRAY_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
				#else//ASE Sampling Macros
				#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
				#define SAMPLE_TEXTURE2D_ARRAY_LOD(tex,samplertex,coord,lod) tex2DArraylod(tex, float4(coord,lod))
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
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float4 ase_texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					ASE_SV_POSITION_QUALIFIERS float4 pos : SV_POSITION;
					float4 ase_texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
				};

				UNITY_DECLARE_TEX2D_NOSAMPLER(_FallbackTex);
				uniform float _FlipHorizontally;
				SamplerState sampler_FallbackTex;
				UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_TileArray);
				UNITY_DECLARE_TEX2D_NOSAMPLER(_PageTableTransform);
				uniform float4 _PageTableGrid;
				SamplerState sampler_PageTableTransform;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_PageTableLayer);
				SamplerState sampler_PageTableLayer;
				SamplerState sampler_TileArray;


				
				v2f vert( appdata v  )
				{
					UNITY_SETUP_INSTANCE_ID(v);
					v2f o;
					UNITY_INITIALIZE_OUTPUT(v2f,o);
					UNITY_TRANSFER_INSTANCE_ID(v,o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					o.ase_texcoord.xy = v.ase_texcoord.xy;
					
					//setting value to unused interpolator channels and avoid initialization warnings
					o.ase_texcoord.zw = 0;

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

					float2 texCoord9 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float temp_output_16_0 = frac( (texCoord9).x );
					float ifLocalVar17 = 0;
					if( _FlipHorizontally <= 0.5 )
					{
						ifLocalVar17 = temp_output_16_0;
					}
					else
					{
						ifLocalVar17 = frac( ( 1.0 - (texCoord9).x ) );
					}
					float2 appendResult19 = (float2(ifLocalVar17 , (texCoord9).y));
					float4 appendResult72 = (float4((appendResult19).x , (appendResult19).y , 0.0 , 0.0));
					float2 appendResult27 = (float2((appendResult19).x , ( 1.0 - (appendResult19).y )));
					float2 temp_cast_0 = (0.0).xx;
					float2 clampResult34 = clamp( floor( ( appendResult27 * (_PageTableGrid).xy ) ) , temp_cast_0 , ( ( 1.0 / (_PageTableGrid).zw ) - 1.0 ) );
					float2 temp_output_38_0 = ( ( clampResult34 + 0.5 ) * (_PageTableGrid).zw );
					float4 appendResult43 = (float4((temp_output_38_0).x , (temp_output_38_0).y , 0.0 , 0.0));
					float4 tex2DNode44 = SAMPLE_TEXTURE2D_LOD( _PageTableTransform, sampler_PageTableTransform, (appendResult43).xy, (appendResult43).w );
					float2 temp_output_58_0 = ( ( appendResult19 * (tex2DNode44).rg ) + (tex2DNode44).ba );
					float4 appendResult51 = (float4((temp_output_38_0).x , (temp_output_38_0).y , 0.0 , 0.0));
					float4 tex2DNode52 = SAMPLE_TEXTURE2D_LOD( _PageTableLayer, sampler_PageTableLayer, (appendResult51).xy, (appendResult51).w );
					float3 appendResult63 = (float3((temp_output_58_0).x , (temp_output_58_0).y , round( (tex2DNode52).r )));
					float4 lerpResult79 = lerp( SAMPLE_TEXTURE2D_LOD( _FallbackTex, sampler_FallbackTex, (appendResult72).xy, (appendResult72).w ) , SAMPLE_TEXTURE2D_ARRAY_LOD( _TileArray, sampler_TileArray, float3((appendResult63).xy,(appendResult63).z), 0.0 ) , step( 0.5 , (tex2DNode52).g ));
					

					float3 Color = (lerpResult79).rgb;
					float Alpha = (lerpResult79).a;
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

	
	}
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":24,"pos":[-600,540],"params":["Inherit","False","Constant","_Float3","Float 3","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":25,"pos":[-600,720],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":6,"pos":[-1500,540],"params":["Inherit","False","Property","_PageTableGrid","Page Table Grid","3","0","Create","False","0","0","0","True","0","False","Object","-1","","1,1,1,1","1,1,1,1","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":23,"pos":[-600,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":26,"pos":[-600,900],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":20,"pos":[-900,900],"params":["Inherit","False","Constant","_Float2","Float 2","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":21,"pos":[-600,0],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":27,"pos":[-300,0],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[-300,180],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":22,"pos":[-600,180],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[-300,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":32,"pos":[-300,900],"params":["Inherit","False","Constant","_Float5","Float 5","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FloorOpNode, AmplifyShaderEditor","id":30,"pos":[-300,540],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":31,"pos":[-300,720],"params":["Inherit","False","Constant","_Float4","Float 4","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":33,"pos":[0,0],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":34,"pos":[0,180],"params":["Inherit","False","3","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","2","FLOAT2","1,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":35,"pos":[0,360],"params":["Inherit","False","Constant","_Float6","Float 6","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":36,"pos":[0,540],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":37,"pos":[0,720],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":38,"pos":[0,900],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":39,"pos":[300,0],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":40,"pos":[300,180],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":41,"pos":[300,360],"params":["Inherit","False","Constant","_Float7","Float 7","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":42,"pos":[300,540],"params":["Inherit","False","Constant","_Float8","Float 8","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":9,"pos":[-1200,0],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":43,"pos":[300,720],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":4,"pos":[-1500,180],"params":["Inherit","True","Property","_PageTableTransform","Page Table Transform","1","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":11,"pos":[-1200,360],"params":["Inherit","False","Constant","_Float1","Float 1","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":12,"pos":[-1200,540],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":45,"pos":[600,0],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[600,180],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":47,"pos":[600,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":48,"pos":[600,540],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":49,"pos":[600,720],"params":["Inherit","False","Constant","_Float9","Float 9","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":50,"pos":[600,900],"params":["Inherit","False","Constant","_Float10","Float 10","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":13,"pos":[-1200,720],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":15,"pos":[-900,0],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":44,"pos":[300,900],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","6","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":51,"pos":[900,0],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":5,"pos":[-1500,360],"params":["Inherit","True","Property","_PageTableLayer","Page Table Layer","2","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":8,"pos":[-1500,900],"params":["Inherit","False","Property","_FlipHorizontally","Flip Horizontally","5","1","[Toggle]","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":10,"pos":[-1200,180],"params":["Inherit","False","Constant","_Float0","Float 0","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":14,"pos":[-1200,900],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":16,"pos":[-900,180],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":53,"pos":[900,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":54,"pos":[900,540],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":55,"pos":[900,720],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":17,"pos":[-900,360],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":18,"pos":[-900,540],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":52,"pos":[900,180],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","7","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":56,"pos":[900,900],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":57,"pos":[1200,0],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":19,"pos":[-900,720],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":58,"pos":[1200,180],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":61,"pos":[1200,720],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":59,"pos":[1200,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":60,"pos":[1200,540],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RoundOpNode, AmplifyShaderEditor","id":62,"pos":[1200,900],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":68,"pos":[1500,900],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":69,"pos":[1800,0],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":70,"pos":[1800,180],"params":["Inherit","False","Constant","_Float12","Float 12","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":71,"pos":[1800,360],"params":["Inherit","False","Constant","_Float13","Float 13","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":63,"pos":[1500,0],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":72,"pos":[1800,540],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":3,"pos":[-1500,0],"params":["Inherit","True","Property","_TileArray","Tile Array","0","0","Create","False","0","0","0","True","0","False","","None","None","False","white","LockedToTexture2DArray","Texture2DArray","False","-1","0","2","SAMPLER2DARRAY","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":7,"pos":[-1500,720],"params":["Inherit","True","Property","_FallbackTex","Fallback","4","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":65,"pos":[1500,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":66,"pos":[1500,540],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":67,"pos":[1500,720],"params":["Inherit","False","Constant","_Float11","Float 11","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":74,"pos":[1800,900],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":75,"pos":[2100,0],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":76,"pos":[2100,180],"params":["Inherit","False","Constant","_Float14","Float 14","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":77,"pos":[2100,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":64,"pos":[1500,180],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2DArray","False","8","0","SAMPLER2DARRAY","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":73,"pos":[1800,720],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","9","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":78,"pos":[2100,540],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":79,"pos":[2100,720],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":80,"pos":[2100,900],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":81,"pos":[2400,0],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[0,0],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[0,0],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","7","DeepZoom/DeepZoomPageTable360_ASE","0770190933193b94aaa3065e307002fa","True","Unlit","0","1","Unlit","8","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","2","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","True","3","True","12","all","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","True","True","1","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","10","Surface","0","0","  Keep Alpha","1","0","  Blend","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Cast Shadows","0","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Vertex Position","1","0","0","3","False","True","False","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[0,0],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ShadowCaster","0","2","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[25,0,19,0]}
{"wire":[23,0,19,0]}
{"wire":[26,0,24,0]}
{"wire":[26,1,25,0]}
{"wire":[21,0,6,0]}
{"wire":[27,0,23,0]}
{"wire":[27,1,26,0]}
{"wire":[28,0,6,0]}
{"wire":[22,0,20,0]}
{"wire":[22,1,21,0]}
{"wire":[29,0,27,0]}
{"wire":[29,1,28,0]}
{"wire":[30,0,29,0]}
{"wire":[33,0,22,0]}
{"wire":[33,1,32,0]}
{"wire":[34,0,30,0]}
{"wire":[34,1,31,0]}
{"wire":[34,2,33,0]}
{"wire":[36,0,34,0]}
{"wire":[36,1,35,0]}
{"wire":[37,0,6,0]}
{"wire":[38,0,36,0]}
{"wire":[38,1,37,0]}
{"wire":[39,0,38,0]}
{"wire":[40,0,38,0]}
{"wire":[43,0,39,0]}
{"wire":[43,1,40,0]}
{"wire":[43,2,41,0]}
{"wire":[43,3,42,0]}
{"wire":[12,0,9,0]}
{"wire":[45,0,43,0]}
{"wire":[46,0,43,0]}
{"wire":[47,0,38,0]}
{"wire":[48,0,38,0]}
{"wire":[13,0,11,0]}
{"wire":[13,1,12,0]}
{"wire":[15,0,9,0]}
{"wire":[44,0,4,0]}
{"wire":[44,1,45,0]}
{"wire":[44,2,46,0]}
{"wire":[51,0,47,0]}
{"wire":[51,1,48,0]}
{"wire":[51,2,49,0]}
{"wire":[51,3,50,0]}
{"wire":[14,0,13,0]}
{"wire":[16,0,15,0]}
{"wire":[53,0,51,0]}
{"wire":[54,0,51,0]}
{"wire":[55,0,44,0]}
{"wire":[17,0,8,0]}
{"wire":[17,1,10,0]}
{"wire":[17,2,14,0]}
{"wire":[17,3,16,0]}
{"wire":[17,4,16,0]}
{"wire":[18,0,9,0]}
{"wire":[52,0,5,0]}
{"wire":[52,1,53,0]}
{"wire":[52,2,54,0]}
{"wire":[56,0,19,0]}
{"wire":[56,1,55,0]}
{"wire":[57,0,44,0]}
{"wire":[19,0,17,0]}
{"wire":[19,1,18,0]}
{"wire":[58,0,56,0]}
{"wire":[58,1,57,0]}
{"wire":[61,0,52,0]}
{"wire":[59,0,58,0]}
{"wire":[60,0,58,0]}
{"wire":[62,0,61,0]}
{"wire":[68,0,19,0]}
{"wire":[69,0,19,0]}
{"wire":[63,0,59,0]}
{"wire":[63,1,60,0]}
{"wire":[63,2,62,0]}
{"wire":[72,0,68,0]}
{"wire":[72,1,69,0]}
{"wire":[72,2,70,0]}
{"wire":[72,3,71,0]}
{"wire":[65,0,63,0]}
{"wire":[66,0,63,0]}
{"wire":[74,0,72,0]}
{"wire":[75,0,72,0]}
{"wire":[77,0,52,0]}
{"wire":[64,0,3,0]}
{"wire":[64,1,65,0]}
{"wire":[64,2,67,0]}
{"wire":[64,6,66,0]}
{"wire":[73,0,7,0]}
{"wire":[73,1,74,0]}
{"wire":[73,2,75,0]}
{"wire":[78,0,76,0]}
{"wire":[78,1,77,0]}
{"wire":[79,0,73,0]}
{"wire":[79,1,64,0]}
{"wire":[79,2,78,0]}
{"wire":[80,0,79,0]}
{"wire":[81,0,79,0]}
{"wire":[1,0,80,0]}
{"wire":[1,7,81,0]}
ASEEND*/
//CHKSM=3572D48B0C652682C6FDE26657522D5EAD46238F