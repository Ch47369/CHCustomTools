// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DeepZoom/DeepZoomPageTable360_ASE_Organized"
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

					float ase__FlipHorizontally_8282 = _FlipHorizontally;
					float2 texCoord9 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float temp_output_16_0 = frac( (texCoord9).x );
					float ifLocalVar17 = 0;
					if( ase__FlipHorizontally_8282 <= 0.5 )
					{
						ifLocalVar17 = temp_output_16_0;
					}
					else
					{
						ifLocalVar17 = frac( ( 1.0 - (texCoord9).x ) );
					}
					float ase_n15_8484 = (texCoord9).y;
					float2 appendResult19 = (float2(ifLocalVar17 , ase_n15_8484));
					float4 appendResult72 = (float4((appendResult19).x , (appendResult19).y , 0.0 , 0.0));
					float4 ase_fallback_100100 = SAMPLE_TEXTURE2D_LOD( _FallbackTex, sampler_FallbackTex, (appendResult72).xy, (appendResult72).w );
					float2 ase_n16_9393 = appendResult19;
					float2 appendResult27 = (float2((appendResult19).x , ( 1.0 - (appendResult19).y )));
					float4 ase__PageTableGrid_8686 = _PageTableGrid;
					float2 temp_cast_0 = (0.0).xx;
					float2 ase_cellCount_8888 = ( 1.0 / (_PageTableGrid).zw );
					float2 clampResult34 = clamp( floor( ( appendResult27 * (ase__PageTableGrid_8686).xy ) ) , temp_cast_0 , ( ase_cellCount_8888 - 1.0 ) );
					float2 temp_output_38_0 = ( ( clampResult34 + 0.5 ) * (ase__PageTableGrid_8686).zw );
					float4 appendResult43 = (float4((temp_output_38_0).x , (temp_output_38_0).y , 0.0 , 0.0));
					float4 tex2DNode44 = SAMPLE_TEXTURE2D_LOD( _PageTableTransform, sampler_PageTableTransform, (appendResult43).xy, (appendResult43).w );
					float2 temp_output_58_0 = ( ( ase_n16_9393 * (tex2DNode44).rg ) + (tex2DNode44).ba );
					float2 ase_pageUV_9191 = temp_output_38_0;
					float4 appendResult51 = (float4((ase_pageUV_9191).x , (ase_pageUV_9191).y , 0.0 , 0.0));
					float4 ase_info_9595 = SAMPLE_TEXTURE2D_LOD( _PageTableLayer, sampler_PageTableLayer, (appendResult51).xy, (appendResult51).w );
					float3 appendResult63 = (float3((temp_output_58_0).x , (temp_output_58_0).y , round( (ase_info_9595).r )));
					float ase_n64_9898 = 0.0;
					float4 lerpResult79 = lerp( ase_fallback_100100 , SAMPLE_TEXTURE2D_ARRAY_LOD( _TileArray, sampler_TileArray, float3((appendResult63).xy,(appendResult63).z), ase_n64_9898 ) , step( 0.5 , (ase_info_9595).g ));
					

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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":105,"pos":[0,15],"params":["Inherit","False","800","815","这些属性提供纹理、颜色和参数；属性名与原 Shader 一致。","4","6","8","82","86","材质输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":6,"pos":[50,115],"params":["Inherit","False","Property","_PageTableGrid","Page Table Grid","3","0","Create","False","0","0","0","True","0","False","Object","-1","","1,1,1,1","1,1,1,1","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":109,"pos":[1020,15],"params":["Inherit","False","1200","815","按连线计算并传递结果。表达式：1.0 / _PageTableGrid.zw","4","20","21","22","88","计算 cellCount","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":110,"pos":[3640,15],"params":["Inherit","False","2000","1545","向下取整定位网格单元。表达式：floor(float2(uv.x, 1.0 - uv.y) * _PageTableGrid.xy)","9","23","24","25","26","27","28","29","30","87","计算 cell","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":20,"pos":[1070,115],"params":["Inherit","False","Constant","_Float2","Float 2","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":21,"pos":[1070,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":24,"pos":[3690,480],"params":["Inherit","False","Constant","_Float3","Float 3","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":25,"pos":[3690,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":86,"pos":[450,480],"params":["Inherit","False","ase__PageTableGrid_86","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":22,"pos":[1470,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":23,"pos":[3690,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":26,"pos":[4090,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":87,"pos":[3690,1210],"params":["Inherit","False","86","ase__PageTableGrid_86","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":27,"pos":[4490,115],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[4090,480],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":88,"pos":[1870,115],"params":["Inherit","False","ase_cellCount_88","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":111,"pos":[5860,15],"params":["Inherit","False","1200","1180","限制数值范围。表达式：clamp(cell, 0.0, cellCount - 1.0)","5","31","32","33","34","89","计算 cell","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[4890,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":32,"pos":[5910,480],"params":["Inherit","False","Constant","_Float5","Float 5","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":89,"pos":[5910,845],"params":["Inherit","False","88","ase_cellCount_88","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.FloorOpNode, AmplifyShaderEditor","id":30,"pos":[5290,115],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":31,"pos":[5910,115],"params":["Inherit","False","Constant","_Float4","Float 4","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":33,"pos":[6310,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":112,"pos":[7280,15],"params":["Inherit","False","1600","815","按连线计算并传递结果。表达式：(cell + 0.5) * _PageTableGrid.zw","6","35","36","37","38","90","91","计算 pageUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":34,"pos":[6710,115],"params":["Inherit","False","3","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","2","FLOAT2","1,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":35,"pos":[7330,115],"params":["Inherit","False","Constant","_Float6","Float 6","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":90,"pos":[7330,480],"params":["Inherit","False","86","ase__PageTableGrid_86","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":36,"pos":[7730,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":37,"pos":[7730,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":91,"pos":[8530,115],"params":["Inherit","False","ase_pageUV_91","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":104,"pos":[9100,2085],"params":["Inherit","False","2400","1545","以显式 LOD 读取纹理。表达式：tex2Dlod(_PageTableLayer, float4(pageUV, 0, 0))","11","5","47","48","49","50","51","52","53","54","92","95","计算 info","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":107,"pos":[0,990],"params":["Inherit","False","640","450","按连线计算并传递结果。表达式：i.uv","1","9","计算 uv","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":9,"pos":[50,1090],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":38,"pos":[8130,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":92,"pos":[9150,3280],"params":["Inherit","False","91","ase_pageUV_91","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":103,"pos":[9100,15],"params":["Inherit","False","1600","1910","以显式 LOD 读取纹理。表达式：tex2Dlod(_PageTableTransform, float4(pageUV, 0, 0))","9","4","39","40","41","42","43","44","45","46","计算 transform","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":108,"pos":[1020,990],"params":["Inherit","False","2400","2275","比较输入并选择分支，更新局部变量；保留相等时的分支结果。","14","10","11","12","13","14","15","16","17","18","19","83","84","85","93","条件选择","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":8,"pos":[50,480],"params":["Inherit","False","Property","_FlipHorizontally","Flip Horizontally","5","1","[Toggle]","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":11,"pos":[1070,1455],"params":["Inherit","False","Constant","_Float1","Float 1","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":12,"pos":[1070,1820],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":39,"pos":[9150,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":40,"pos":[9150,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":41,"pos":[9150,1210],"params":["Inherit","False","Constant","_Float7","Float 7","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":42,"pos":[9150,1575],"params":["Inherit","False","Constant","_Float8","Float 8","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":47,"pos":[9550,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":48,"pos":[9550,2550],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":49,"pos":[9150,2550],"params":["Inherit","False","Constant","_Float9","Float 9","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":50,"pos":[9150,2915],"params":["Inherit","False","Constant","_Float10","Float 10","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":13,"pos":[1470,1090],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":15,"pos":[1070,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":18,"pos":[1070,2550],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":43,"pos":[9550,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":51,"pos":[9950,2185],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":82,"pos":[450,115],"params":["Inherit","False","ase__FlipHorizontally_82","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":4,"pos":[9150,115],"params":["Inherit","True","Property","_PageTableTransform","Page Table Transform","1","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":5,"pos":[9150,2185],"params":["Inherit","True","Property","_PageTableLayer","Page Table Layer","2","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":10,"pos":[1070,1090],"params":["Inherit","False","Constant","_Float0","Float 0","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":14,"pos":[1870,1090],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":16,"pos":[1470,1455],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":45,"pos":[9950,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[9950,480],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":53,"pos":[10350,2185],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":54,"pos":[10350,2550],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":83,"pos":[1070,2915],"params":["Inherit","False","82","ase__FlipHorizontally_82","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":84,"pos":[1470,1820],"params":["Inherit","False","ase_n15_84","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":17,"pos":[2270,1090],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":44,"pos":[10350,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","6","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":52,"pos":[10750,2185],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","7","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":85,"pos":[1870,1455],"params":["Inherit","False","84","ase_n15_84","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":93,"pos":[3070,1090],"params":["Inherit","False","ase_n16_93","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":113,"pos":[11720,15],"params":["Inherit","False","1200","1180","按连线计算并传递结果。表达式：uv * transform.xy + transform.zw","5","55","56","57","58","94","计算 tileUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":19,"pos":[2670,1090],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":55,"pos":[11770,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":94,"pos":[11770,845],"params":["Inherit","False","93","ase_n16_93","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":95,"pos":[11150,2185],"params":["Inherit","False","ase_info_95","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":102,"pos":[13140,15],"params":["Inherit","False","2400","1910","以显式 LOD 读取纹理；取最近整数作为索引。表达式：UNITY_SAMPLE_TEX2DARRAY_LOD(_TileArray, float3(tileUV, round(info.x)), 0)","13","3","59","60","61","62","63","64","65","66","67","96","98","99","计算 tileColor","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":106,"pos":[3640,1720],"params":["Inherit","False","2000","1910","以显式 LOD 读取纹理。表达式：tex2Dlod(_FallbackTex, float4(uv, 0, 0))","10","7","68","69","70","71","72","73","74","75","100","计算 fallback","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":56,"pos":[12170,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":57,"pos":[11770,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":68,"pos":[3690,2185],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":69,"pos":[3690,2550],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":70,"pos":[3690,2915],"params":["Inherit","False","Constant","_Float12","Float 12","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":71,"pos":[3690,3280],"params":["Inherit","False","Constant","_Float13","Float 13","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":96,"pos":[13190,1575],"params":["Inherit","False","95","ase_info_95","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":58,"pos":[12570,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":61,"pos":[13590,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":72,"pos":[4090,1820],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":7,"pos":[3690,1820],"params":["Inherit","True","Property","_FallbackTex","Fallback","4","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":59,"pos":[13190,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":60,"pos":[13190,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RoundOpNode, AmplifyShaderEditor","id":62,"pos":[13990,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":67,"pos":[13190,1210],"params":["Inherit","False","Constant","_Float11","Float 11","9","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":74,"pos":[4490,1820],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":75,"pos":[4490,2185],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":114,"pos":[15760,15],"params":["Inherit","False","2000","1180","按权重混合两个结果；用阈值产生 0/1 选择信号。表达式：lerp(fallback, tileColor, step(0.5, info.y)) 输出到主节点的颜色和 Alpha。","8","76","77","78","79","80","81","97","101","计算 最终颜色与透明度","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":63,"pos":[14390,115],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":73,"pos":[4890,1820],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","9","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":97,"pos":[15810,480],"params":["Inherit","False","95","ase_info_95","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":98,"pos":[13590,480],"params":["Inherit","False","ase_n64_98","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":3,"pos":[13190,115],"params":["Inherit","True","Property","_TileArray","Tile Array","0","0","Create","False","0","0","0","True","0","False","","None","None","False","white","LockedToTexture2DArray","Texture2DArray","False","-1","0","2","SAMPLER2DARRAY","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":65,"pos":[14790,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":66,"pos":[14790,480],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":76,"pos":[15810,115],"params":["Inherit","False","Constant","_Float14","Float 14","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":77,"pos":[16210,115],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":99,"pos":[13990,480],"params":["Inherit","False","98","ase_n64_98","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":100,"pos":[5290,1820],"params":["Inherit","False","ase_fallback_100","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":64,"pos":[15190,115],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2DArray","False","8","0","SAMPLER2DARRAY","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":78,"pos":[16610,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":101,"pos":[15810,845],"params":["Inherit","False","100","ase_fallback_100","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":79,"pos":[17010,115],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":80,"pos":[17410,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":81,"pos":[17410,480],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[18110,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[18110,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","8","DeepZoom/DeepZoomPageTable360_ASE_Organized","0770190933193b94aaa3065e307002fa","True","Unlit","0","1","Unlit","8","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","2","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","True","3","True","12","all","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","True","True","1","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","10","Surface","0","0","  Keep Alpha","1","0","  Blend","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Cast Shadows","0","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Vertex Position","1","0","0","3","False","True","False","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[18110,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ShadowCaster","0","2","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[21,0,6,0]}
{"wire":[25,0,19,0]}
{"wire":[86,0,6,0]}
{"wire":[22,0,20,0]}
{"wire":[22,1,21,0]}
{"wire":[23,0,19,0]}
{"wire":[26,0,24,0]}
{"wire":[26,1,25,0]}
{"wire":[27,0,23,0]}
{"wire":[27,1,26,0]}
{"wire":[28,0,87,0]}
{"wire":[88,0,22,0]}
{"wire":[29,0,27,0]}
{"wire":[29,1,28,0]}
{"wire":[30,0,29,0]}
{"wire":[33,0,89,0]}
{"wire":[33,1,32,0]}
{"wire":[34,0,30,0]}
{"wire":[34,1,31,0]}
{"wire":[34,2,33,0]}
{"wire":[36,0,34,0]}
{"wire":[36,1,35,0]}
{"wire":[37,0,90,0]}
{"wire":[91,0,38,0]}
{"wire":[38,0,36,0]}
{"wire":[38,1,37,0]}
{"wire":[12,0,9,0]}
{"wire":[39,0,38,0]}
{"wire":[40,0,38,0]}
{"wire":[47,0,92,0]}
{"wire":[48,0,92,0]}
{"wire":[13,0,11,0]}
{"wire":[13,1,12,0]}
{"wire":[15,0,9,0]}
{"wire":[18,0,9,0]}
{"wire":[43,0,39,0]}
{"wire":[43,1,40,0]}
{"wire":[43,2,41,0]}
{"wire":[43,3,42,0]}
{"wire":[51,0,47,0]}
{"wire":[51,1,48,0]}
{"wire":[51,2,49,0]}
{"wire":[51,3,50,0]}
{"wire":[82,0,8,0]}
{"wire":[14,0,13,0]}
{"wire":[16,0,15,0]}
{"wire":[45,0,43,0]}
{"wire":[46,0,43,0]}
{"wire":[53,0,51,0]}
{"wire":[54,0,51,0]}
{"wire":[84,0,18,0]}
{"wire":[17,0,83,0]}
{"wire":[17,1,10,0]}
{"wire":[17,2,14,0]}
{"wire":[17,3,16,0]}
{"wire":[17,4,16,0]}
{"wire":[44,0,4,0]}
{"wire":[44,1,45,0]}
{"wire":[44,2,46,0]}
{"wire":[52,0,5,0]}
{"wire":[52,1,53,0]}
{"wire":[52,2,54,0]}
{"wire":[93,0,19,0]}
{"wire":[19,0,17,0]}
{"wire":[19,1,85,0]}
{"wire":[55,0,44,0]}
{"wire":[95,0,52,0]}
{"wire":[56,0,94,0]}
{"wire":[56,1,55,0]}
{"wire":[57,0,44,0]}
{"wire":[68,0,19,0]}
{"wire":[69,0,19,0]}
{"wire":[58,0,56,0]}
{"wire":[58,1,57,0]}
{"wire":[61,0,96,0]}
{"wire":[72,0,68,0]}
{"wire":[72,1,69,0]}
{"wire":[72,2,70,0]}
{"wire":[72,3,71,0]}
{"wire":[59,0,58,0]}
{"wire":[60,0,58,0]}
{"wire":[62,0,61,0]}
{"wire":[74,0,72,0]}
{"wire":[75,0,72,0]}
{"wire":[63,0,59,0]}
{"wire":[63,1,60,0]}
{"wire":[63,2,62,0]}
{"wire":[73,0,7,0]}
{"wire":[73,1,74,0]}
{"wire":[73,2,75,0]}
{"wire":[98,0,67,0]}
{"wire":[65,0,63,0]}
{"wire":[66,0,63,0]}
{"wire":[77,0,97,0]}
{"wire":[100,0,73,0]}
{"wire":[64,0,3,0]}
{"wire":[64,1,65,0]}
{"wire":[64,2,99,0]}
{"wire":[64,6,66,0]}
{"wire":[78,0,76,0]}
{"wire":[78,1,77,0]}
{"wire":[79,0,101,0]}
{"wire":[79,1,64,0]}
{"wire":[79,2,78,0]}
{"wire":[80,0,79,0]}
{"wire":[81,0,79,0]}
{"wire":[1,0,80,0]}
{"wire":[1,7,81,0]}
ASEEND*/
//CHKSM=2E5CCD4A5E7862AC37A9BA43CF25303B0E3296AB