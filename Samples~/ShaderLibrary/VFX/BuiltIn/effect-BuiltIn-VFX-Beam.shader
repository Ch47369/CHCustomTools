// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASELibrary/BuiltIn/VFX/溶解叠加光束"
{
	Properties
	{
		_BaseColor( "基色 / Base Color", Color ) = ( 0.2, 0.45, 0.6, 1 )
		[NoScaleOffset] _BaseMap( "基色纹理", 2D ) = "white" {}
		_Smoothness( "光滑度", Range( 0, 1 ) ) = 0.45
		_Metallic( "金属度", Range( 0, 1 ) ) = 0
		[NoScaleOffset] _DissolveMap( "溶解纹理（线性）", 2D ) = "white" {}
		_Dissolve( "溶解进度", Range( 0, 1 ) ) = 0.4
		_EdgeWidth( "溶解边缘宽度", Range( 0.001, 0.2 ) ) = 0.04
		_EdgeColor( "边缘颜色", Color ) = ( 1, 0.15, 0.02, 1 )

	}
	
	SubShader
	{
		

		

		Tags { "RenderType"="Transparent" "Queue"="Transparent" }

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

			Cull Back
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			BlendOp Add, Add

			

			CGPROGRAM
				#define ASE_SURFACE_TRANSPARENT
				#define ASE_VERSION 19913
				#define ASE_USING_SAMPLING_MACROS 1

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#include "UnityCG.cginc"

				#define ASE_NEEDS_TEXTURE_COORDINATES0
				#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
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

				uniform float _Smoothness;
				uniform float _Metallic;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_BaseMap);
				SamplerState sampler_BaseMap;
				uniform float4 _BaseColor;
				uniform float4 _EdgeColor;
				uniform float _Dissolve;
				uniform float _EdgeWidth;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_DissolveMap);
				SamplerState sampler_DissolveMap;


				
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

					float2 texCoord3 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float4 tex2DNode6 = SAMPLE_TEXTURE2D( _BaseMap, sampler_BaseMap, texCoord3 );
					float4 ase______Base_Color_4646 = _BaseColor;
					float3 ase_SimpleMultiplyOpNode_5050 = ( (tex2DNode6).rgb * (ase______Base_Color_4646).rgb );
					float2 ase_TextureCoordinatesNode_4848 = texCoord3;
					float4 tex2DNode15 = SAMPLE_TEXTURE2D( _DissolveMap, sampler_DissolveMap, ase_TextureCoordinatesNode_4848 );
					float smoothstepResult19 = smoothstep( _Dissolve , ( _Dissolve + _EdgeWidth ) , tex2DNode15.r);
					float smoothstepResult24 = smoothstep( ( _Dissolve + _EdgeWidth ) , ( _Dissolve + ( _EdgeWidth * 2.0 ) ) , tex2DNode15.r);
					float3 ase_SimpleAddOpNode_5656 = ( ase_SimpleMultiplyOpNode_5050 + ( (_EdgeColor).rgb * saturate( ( smoothstepResult19 - smoothstepResult24 ) ) ) );
					
					float ase_SimpleMultiplyOpNode_5252 = ( tex2DNode6.a * (_BaseColor).a );
					float ase_SimpleMultiplyOpNode_5454 = ( ase_SimpleMultiplyOpNode_5252 * smoothstepResult19 );
					float2 texCoord32 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float smoothstepResult42 = smoothstep( 0.05 , 0.25 , abs( ( (texCoord32).x - 0.5 ) ));
					

					float3 Color = ase_SimpleAddOpNode_5656;
					float Alpha = ( ase_SimpleMultiplyOpNode_5454 * saturate( ( 1.0 - smoothstepResult42 ) ) );
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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":58,"pos":[0,15],"params":["Inherit","False","680","575","原创材质基础，不是樱花兔或网络素材的等价转换。基色按 sRGB 导入，遮罩按 Linear，法线按 NormalMap；需要按实际模型补齐贴图。","4","3","4","46","48","01 输入与资源","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":3,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":60,"pos":[2820,15],"params":["Inherit","False","3060","1310","按独立参数计算材质响应；所有连线由 ASE 原生节点创建。下方注释说明本示例与完整专用材质的差距。","23","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","49","51","53","54","56","03 材质计算","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":4,"pos":[50,360],"params":["Inherit","False","Property","_BaseColor","基色 / Base Color","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.2,0.45,0.6,1","0.2,0.45,0.6,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":21,"pos":[2870,850],"params":["Inherit","False","Constant","_Float0","Float 0","9","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":48,"pos":[390,115],"params":["Inherit","False","ase_TextureCoordinatesNode_48","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":59,"pos":[900,15],"params":["Inherit","False","1700","820","纹理对象靠近采样器；UV 动画在片元使用。细节频率和幅度需要按模型真实尺寸调节。","12","5","6","7","8","9","10","11","12","13","47","50","52","02 坐标与纹理","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":5,"pos":[950,115],"params":["Inherit","True","Property","_BaseMap","基色纹理","1","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":14,"pos":[2870,115],"params":["Inherit","True","Property","_DissolveMap","溶解纹理（线性）","4","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":17,"pos":[2870,605],"params":["Inherit","False","Property","_EdgeWidth","溶解边缘宽度","6","0","Create","False","0","0","0","True","0","False","Object","-1","","0.04","0","0.001","0.2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":22,"pos":[3210,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":46,"pos":[390,360],"params":["Inherit","False","ase______Base_Color_46","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":49,"pos":[2870,1095],"params":["Inherit","False","48","ase_TextureCoordinatesNode_48","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":61,"pos":[6100,15],"params":["Inherit","False","2720","820","原创可编辑扩展：溶解叠加光束。程序图案使用 UV0；贴图型扩展需绑定实际资源。设备建议来自静态复杂度，未做 GPU 实机测速。","15","32","33","34","35","36","37","38","39","40","41","42","43","44","45","55","06 溶解叠加光束","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":6,"pos":[1290,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","2","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":10,"pos":[1290,360],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":15,"pos":[3210,115],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","6","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":16,"pos":[2870,360],"params":["Inherit","False","Property","_Dissolve","溶解进度","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":18,"pos":[3210,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":20,"pos":[3550,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":23,"pos":[3550,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":32,"pos":[6150,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":47,"pos":[1290,605],"params":["Inherit","False","46","ase______Base_Color_46","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":7,"pos":[1630,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":8,"pos":[1630,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":11,"pos":[1630,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":19,"pos":[3550,115],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":24,"pos":[3890,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":33,"pos":[6490,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":37,"pos":[6490,115],"params":["Inherit","False","Constant","_Float3","Float 3","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":9,"pos":[1970,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":25,"pos":[4230,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":27,"pos":[4230,115],"params":["Inherit","False","Property","_EdgeColor","边缘颜色","7","0","Create","False","0","0","0","True","0","False","Object","-1","","1,0.15,0.02,1","1,0.15,0.02,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":38,"pos":[6830,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":52,"pos":[1970,360],"params":["Inherit","False","ase_SimpleMultiplyOpNode_52","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":26,"pos":[4570,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[4570,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":39,"pos":[7170,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":40,"pos":[7170,115],"params":["Inherit","False","Constant","_Float4","Float 4","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.05","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":41,"pos":[7170,360],"params":["Inherit","False","Constant","_Float5","Float 5","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0.25","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":50,"pos":[2310,115],"params":["Inherit","False","ase_SimpleMultiplyOpNode_50","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":53,"pos":[3550,360],"params":["Inherit","False","52","ase_SimpleMultiplyOpNode_52","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[4910,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[3890,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":35,"pos":[7510,115],"params":["Inherit","False","Constant","_Float1","Float 1","10","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":42,"pos":[7510,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":51,"pos":[4910,115],"params":["Inherit","False","50","ase_SimpleMultiplyOpNode_50","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":30,"pos":[5250,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":43,"pos":[7850,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":54,"pos":[4230,360],"params":["Inherit","False","ase_SimpleMultiplyOpNode_54","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":44,"pos":[8190,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":55,"pos":[8190,360],"params":["Inherit","False","54","ase_SimpleMultiplyOpNode_54","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":56,"pos":[5590,115],"params":["Inherit","False","ase_SimpleAddOpNode_56","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":62,"pos":[6100,995],"params":["Inherit","False","640","330","从命名 Register 读取远处的法线、顶点位移等结果，在主节点旁连接到对应端口，避免长线横穿整个图。","1","57","09 主节点输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":12,"pos":[950,360],"params":["Inherit","False","Property","_Smoothness","光滑度","2","0","Create","False","0","0","0","True","0","False","Object","-1","","0.45","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[950,605],"params":["Inherit","False","Property","_Metallic","金属度","3","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":34,"pos":[6490,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":36,"pos":[6150,360],"params":["Inherit","False","Constant","_Float2","Float 2","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":45,"pos":[8530,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":57,"pos":[6150,1095],"params":["Inherit","False","56","ase_SimpleAddOpNode_56","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[9170,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[9170,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","10","ASELibrary/BuiltIn/VFX/溶解叠加光束","0770190933193b94aaa3065e307002fa","True","Unlit","0","1","Unlit","8","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","2","RenderType=Transparent=RenderType","Queue=Transparent=Queue=0","True","3","True","12","all","0","False","True","1","5","False","","10","False","","1","1","False","","10","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","10","Surface","1","0","  Keep Alpha","1","0","  Blend","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Cast Shadows","0","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Vertex Position","1","0","0","3","False","True","False","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[9170,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ShadowCaster","0","2","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[48,0,3,0]}
{"wire":[22,0,17,0]}
{"wire":[22,1,21,0]}
{"wire":[46,0,4,0]}
{"wire":[6,0,5,0]}
{"wire":[6,1,3,0]}
{"wire":[10,0,4,0]}
{"wire":[15,0,14,0]}
{"wire":[15,1,49,0]}
{"wire":[18,0,16,0]}
{"wire":[18,1,17,0]}
{"wire":[20,0,16,0]}
{"wire":[20,1,17,0]}
{"wire":[23,0,16,0]}
{"wire":[23,1,22,0]}
{"wire":[7,0,6,0]}
{"wire":[8,0,47,0]}
{"wire":[11,0,6,4]}
{"wire":[11,1,10,0]}
{"wire":[19,0,15,1]}
{"wire":[19,1,16,0]}
{"wire":[19,2,18,0]}
{"wire":[24,0,15,1]}
{"wire":[24,1,20,0]}
{"wire":[24,2,23,0]}
{"wire":[33,0,32,0]}
{"wire":[9,0,7,0]}
{"wire":[9,1,8,0]}
{"wire":[25,0,19,0]}
{"wire":[25,1,24,0]}
{"wire":[38,0,33,0]}
{"wire":[38,1,37,0]}
{"wire":[52,0,11,0]}
{"wire":[26,0,25,0]}
{"wire":[28,0,27,0]}
{"wire":[39,0,38,0]}
{"wire":[50,0,9,0]}
{"wire":[29,0,28,0]}
{"wire":[29,1,26,0]}
{"wire":[31,0,53,0]}
{"wire":[31,1,19,0]}
{"wire":[42,0,39,0]}
{"wire":[42,1,40,0]}
{"wire":[42,2,41,0]}
{"wire":[30,0,51,0]}
{"wire":[30,1,29,0]}
{"wire":[43,0,35,0]}
{"wire":[43,1,42,0]}
{"wire":[54,0,31,0]}
{"wire":[44,0,43,0]}
{"wire":[56,0,30,0]}
{"wire":[34,0,32,0]}
{"wire":[45,0,55,0]}
{"wire":[45,1,44,0]}
{"wire":[1,0,57,0]}
{"wire":[1,7,45,0]}
ASEEND*/
//CHKSM=CECB4B6FA30F6A7B313933F9E06CB4F647DB2BB6