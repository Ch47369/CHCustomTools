// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASELibrary/BuiltIn/UVAnimation/流动遮罩叠层"
{
	Properties
	{
		_BaseColor( "基色 / Base Color", Color ) = ( 0.2, 0.45, 0.6, 1 )
		_FlowSpeed( "流动速度", Vector ) = ( 0.03, 0.015, 0, 0 )
		[NoScaleOffset] _BaseMap( "基色纹理", 2D ) = "white" {}
		_Smoothness( "光滑度", Range( 0, 1 ) ) = 0.45
		_Metallic( "金属度", Range( 0, 1 ) ) = 0
		_LayerSpeed( "第二层速度", Vector ) = ( 0.02, -0.025, 0, 0 )
		[NoScaleOffset] _LayerMap( "第二层纹理", 2D ) = "white" {}
		_LayerBlend( "双层混合", Range( 0, 1 ) ) = 0.5
		_EffectSpeed( "扩展动画速度", Range( -4, 4 ) ) = 0.4
		[NoScaleOffset] _EffectMask( "扩展遮罩（线性）", 2D ) = "gray" {}
		_EffectTint( "扩展叠色", Color ) = ( 0.4, 0.65, 0.3, 1 )
		_EffectAmount( "扩展影响强度", Range( 0, 1 ) ) = 0.55

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

			Cull Back
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

				#include "UnityShaderVariables.cginc"
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
				uniform float4 _FlowSpeed;
				SamplerState sampler_BaseMap;
				uniform float4 _BaseColor;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_LayerMap);
				uniform float4 _LayerSpeed;
				SamplerState sampler_LayerMap;
				uniform float _LayerBlend;
				uniform float4 _EffectTint;
				UNITY_DECLARE_TEX2D_NOSAMPLER(_EffectMask);
				uniform float _EffectSpeed;
				SamplerState sampler_EffectMask;
				uniform float _EffectAmount;


				
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
					float2 ase_TextureCoordinatesNode_5252 = texCoord3;
					float4 tex2DNode11 = SAMPLE_TEXTURE2D( _BaseMap, sampler_BaseMap, ( ase_TextureCoordinatesNode_5252 + ( _Time.y * (_FlowSpeed).xy ) ) );
					float4 ase______Base_Color_5454 = _BaseColor;
					float3 ase_SimpleMultiplyOpNode_5757 = ( (tex2DNode11).rgb * (ase______Base_Color_5454).rgb );
					float2 texCoord19 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float3 lerpResult29 = lerp( ase_SimpleMultiplyOpNode_5757 , (SAMPLE_TEXTURE2D( _LayerMap, sampler_LayerMap, ( texCoord19 - ( _Time.y * (_LayerSpeed).xy ) ) )).rgb , _LayerBlend);
					float3 ase_LerpOp_5959 = lerpResult29;
					float2 texCoord30 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
					float3 lerpResult51 = lerp( ase_LerpOp_5959 , ( ase_LerpOp_5959 * (_EffectTint).rgb ) , saturate( ( (SAMPLE_TEXTURE2D( _EffectMask, sampler_EffectMask, ( texCoord30 + ( ( _Time.y * _EffectSpeed ) * (float4( 0.06, 0.025, 0, 0 )).xy ) ) )).r * _EffectAmount ) ));
					
					float ase_SimpleMultiplyOpNode_6262 = ( tex2DNode11.a * (ase______Base_Color_5454).a );
					

					float3 Color = lerpResult51;
					float Alpha = ase_SimpleMultiplyOpNode_6262;
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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":64,"pos":[0,15],"params":["Inherit","False","680","575","原创材质基础，不是樱花兔或网络素材的等价转换。基色按 sRGB 导入，遮罩按 Linear，法线按 NormalMap；需要按实际模型补齐贴图。","4","3","4","52","54","01 输入与资源","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":65,"pos":[900,15],"params":["Inherit","False","2720","820","纹理对象靠近采样器；UV 动画在片元使用。细节频率和幅度需要按模型真实尺寸调节。","19","5","6","7","8","9","10","11","12","13","14","15","16","17","18","53","55","56","57","62","02 坐标与纹理","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":3,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":6,"pos":[950,115],"params":["Inherit","False","Property","_FlowSpeed","流动速度","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0.03,0.015,0,0","0.03,0.015,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":5,"pos":[1290,115],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":7,"pos":[1290,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":52,"pos":[390,115],"params":["Inherit","False","ase_TextureCoordinatesNode_52","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":4,"pos":[50,360],"params":["Inherit","False","Property","_BaseColor","基色 / Base Color","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.2,0.45,0.6,1","0.2,0.45,0.6,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":8,"pos":[1630,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":53,"pos":[1630,115],"params":["Inherit","False","52","ase_TextureCoordinatesNode_52","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":66,"pos":[3840,15],"params":["Inherit","False","2720","820","按独立参数计算材质响应；所有连线由 ASE 原生节点创建。下方注释说明本示例与完整专用材质的差距。","13","19","20","21","22","23","24","25","26","27","28","29","58","59","03 材质计算","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":9,"pos":[1970,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":10,"pos":[1970,115],"params":["Inherit","True","Property","_BaseMap","基色纹理","2","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":21,"pos":[3890,115],"params":["Inherit","False","Property","_LayerSpeed","第二层速度","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.02,-0.025,0,0","0.02,-0.025,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":54,"pos":[390,360],"params":["Inherit","False","ase______Base_Color_54","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":67,"pos":[6780,15],"params":["Inherit","False","3060","1555","原创可编辑扩展：流动遮罩叠层。程序图案使用 UV0；贴图型扩展需绑定实际资源。设备建议来自静态复杂度，未做 GPU 实机测速。","24","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","60","61","06 流动遮罩叠层","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":11,"pos":[2310,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","3","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":20,"pos":[4230,115],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":22,"pos":[4230,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":35,"pos":[6830,850],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":36,"pos":[6830,1095],"params":["Inherit","False","Property","_EffectSpeed","扩展动画速度","8","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4","0","-4","4","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":38,"pos":[6830,1340],"params":["Inherit","False","Constant","_Vector0","Vector 0","11","0","Create","True","0","0","0","False","0","False","Object","-1","","0.06,0.025,0,0","0.06,0.025,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":55,"pos":[2310,360],"params":["Inherit","False","54","ase______Base_Color_54","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":12,"pos":[2650,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":13,"pos":[2650,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":19,"pos":[4570,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":23,"pos":[4570,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":37,"pos":[7170,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":39,"pos":[7170,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":14,"pos":[2990,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":24,"pos":[4910,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":25,"pos":[4910,115],"params":["Inherit","True","Property","_LayerMap","第二层纹理","6","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":30,"pos":[6830,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":40,"pos":[7510,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":26,"pos":[5250,115],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","8","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":41,"pos":[7850,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":42,"pos":[7850,115],"params":["Inherit","True","Property","_EffectMask","扩展遮罩（线性）","9","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","gray","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":57,"pos":[3330,115],"params":["Inherit","False","ase_SimpleMultiplyOpNode_57","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":27,"pos":[5590,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":28,"pos":[5590,115],"params":["Inherit","False","Property","_LayerBlend","双层混合","7","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":43,"pos":[8190,115],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","12","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":56,"pos":[1970,605],"params":["Inherit","False","54","ase______Base_Color_54","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":58,"pos":[5590,605],"params":["Inherit","False","57","ase_SimpleMultiplyOpNode_57","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":15,"pos":[2310,605],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":29,"pos":[5930,115],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":44,"pos":[8530,605],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":45,"pos":[8530,115],"params":["Inherit","False","Property","_EffectTint","扩展叠色","10","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4,0.65,0.3,1","0.4,0.65,0.3,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":47,"pos":[8530,360],"params":["Inherit","False","Property","_EffectAmount","扩展影响强度","11","0","Create","False","0","0","0","True","0","False","Object","-1","","0.55","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":16,"pos":[2650,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[8870,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":49,"pos":[8870,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":59,"pos":[6270,115],"params":["Inherit","False","ase_LerpOp_59","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":60,"pos":[8870,360],"params":["Inherit","False","59","ase_LerpOp_59","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":48,"pos":[9210,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":50,"pos":[9210,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":61,"pos":[9210,115],"params":["Inherit","False","59","ase_LerpOp_59","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":62,"pos":[2990,360],"params":["Inherit","False","ase_SimpleMultiplyOpNode_62","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":68,"pos":[3840,995],"params":["Inherit","False","640","330","从命名 Register 读取远处的法线、顶点位移等结果，在主节点旁连接到对应端口，避免长线横穿整个图。","1","63","09 主节点输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":17,"pos":[950,360],"params":["Inherit","False","Property","_Smoothness","光滑度","3","0","Create","False","0","0","0","True","0","False","Object","-1","","0.45","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":18,"pos":[950,605],"params":["Inherit","False","Property","_Metallic","金属度","4","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":31,"pos":[7170,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":32,"pos":[7170,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":33,"pos":[6830,360],"params":["Inherit","False","Constant","_Float0","Float 0","10","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":34,"pos":[6830,605],"params":["Inherit","False","Constant","_Float1","Float 1","10","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":51,"pos":[9550,115],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":63,"pos":[3890,1095],"params":["Inherit","False","62","ase_SimpleMultiplyOpNode_62","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[10190,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ExtraPrePass","0","0","ExtraPrePass","6","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","True","1","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","0","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":1,"pos":[10190,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","10","ASELibrary/BuiltIn/UVAnimation/流动遮罩叠层","0770190933193b94aaa3065e307002fa","True","Unlit","0","1","Unlit","8","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","2","RenderType=Opaque=RenderType","Queue=Geometry=Queue=0","True","3","True","12","all","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","True","3","False","","True","True","0","False","","0","False","","False","False","False","False","0","","0","0","Standard","10","Surface","0","0","  Keep Alpha","1","0","  Blend","0","0","Alpha Clipping","0","0","  Use Shadow Threshold","0","0","Cast Shadows","0","0","Write Depth","0","0","  Conservative","0","0","Extra Pre Pass","0","0","Vertex Position","1","0","0","3","False","True","False","False","","True","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":2,"pos":[10190,200],"params":["Float","False","False","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","New Amplify Shader","0770190933193b94aaa3065e307002fa","True","ShadowCaster","0","2","ShadowCaster","0","False","True","1","1","False","","0","False","","1","1","False","","0","False","","True","1","False","","1","False","","False","False","False","False","False","False","False","False","False","True","0","False","","False","True","0","False","","False","True","True","True","True","True","0","False","","False","False","False","False","False","False","False","True","False","0","False","","255","False","","255","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","1","False","","False","True","True","0","False","","0","False","","True","1","False","","True","1","RenderType=Opaque=RenderType","True","3","True","12","all","0","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","1","LightMode=ShadowCaster","False","False","0","","0","0","Standard","0","True","0"]}
{"wire":[7,0,6,0]}
{"wire":[52,0,3,0]}
{"wire":[8,0,5,0]}
{"wire":[8,1,7,0]}
{"wire":[9,0,53,0]}
{"wire":[9,1,8,0]}
{"wire":[54,0,4,0]}
{"wire":[11,0,10,0]}
{"wire":[11,1,9,0]}
{"wire":[22,0,21,0]}
{"wire":[12,0,11,0]}
{"wire":[13,0,55,0]}
{"wire":[23,0,20,0]}
{"wire":[23,1,22,0]}
{"wire":[37,0,35,0]}
{"wire":[37,1,36,0]}
{"wire":[39,0,38,0]}
{"wire":[14,0,12,0]}
{"wire":[14,1,13,0]}
{"wire":[24,0,19,0]}
{"wire":[24,1,23,0]}
{"wire":[40,0,37,0]}
{"wire":[40,1,39,0]}
{"wire":[26,0,25,0]}
{"wire":[26,1,24,0]}
{"wire":[41,0,30,0]}
{"wire":[41,1,40,0]}
{"wire":[57,0,14,0]}
{"wire":[27,0,26,0]}
{"wire":[43,0,42,0]}
{"wire":[43,1,41,0]}
{"wire":[15,0,56,0]}
{"wire":[29,0,58,0]}
{"wire":[29,1,27,0]}
{"wire":[29,2,28,0]}
{"wire":[44,0,43,0]}
{"wire":[16,0,11,4]}
{"wire":[16,1,15,0]}
{"wire":[46,0,45,0]}
{"wire":[49,0,44,0]}
{"wire":[49,1,47,0]}
{"wire":[59,0,29,0]}
{"wire":[48,0,60,0]}
{"wire":[48,1,46,0]}
{"wire":[50,0,49,0]}
{"wire":[62,0,16,0]}
{"wire":[31,0,30,0]}
{"wire":[32,0,30,0]}
{"wire":[51,0,61,0]}
{"wire":[51,1,48,0]}
{"wire":[51,2,50,0]}
{"wire":[1,0,51,0]}
{"wire":[1,7,63,0]}
ASEEND*/
//CHKSM=A71BB4ADD4451D0050E1E693D667F9351BD19CA6