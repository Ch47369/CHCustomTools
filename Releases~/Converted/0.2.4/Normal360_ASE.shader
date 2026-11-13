// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned template for the reviewed two-sided Unlit texture/fog contract.
Shader "Unlit/Normal360_ASE"
{
    Properties
    {
        _MainTex( "Texture", 2D ) = "white" {}
        [Toggle] _FlipHorizontally( "Flip Horizontally", Float ) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
       LOD 100
        Cull Off
        
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 2.5
            #pragma vertex TextureVertex
            #pragma fragment TextureFragment
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
            #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
            #else//ASE Sampling Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
            #endif//ASE Sampling Macros
            

            struct TextureInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                
            };
            struct TextureVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                
            };
            float4 _MainTex_ST;
            UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
            uniform float _FlipHorizontally;
            SamplerState sampler_MainTex;

            TextureVaryings TextureVertex(TextureInput v )
            {
                TextureVaryings o;
                
                v.position.xyz += float3(0,0,0);
                o.position = UnityObjectToClipPos(v.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.position);
                return o;
            }
            fixed4 TextureFragment(TextureVaryings i ) : SV_Target
            {
                float2 texCoord3 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float temp_output_8_0 = (texCoord3).x;
                float ifLocalVar9 = 0;
                if( _FlipHorizontally <= 0.5 )
                {
                	ifLocalVar9 = temp_output_8_0;
                }
                else
                {
                	ifLocalVar9 = ( 1.0 - (texCoord3).x );
                }
                float ase_n9_1313 = (texCoord3).y;
                float2 appendResult11 = (float2(ifLocalVar9 , ase_n9_1313));
                
                fixed4 color = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, appendResult11 );
                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":17,"pos":[0,625],"params":["Inherit","False","640","450","按连线计算并传递结果。表达式：i.uv","1","3","计算 uv","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":3,"pos":[50,725],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":18,"pos":[860,15],"params":["Inherit","False","1600","1910","比较输入并选择分支，更新局部变量；保留相等时的分支结果。","10","4","5","6","7","8","9","10","11","13","14","条件选择","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":5,"pos":[910,480],"params":["Inherit","False","Constant","_Float1","Float 1","2","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":6,"pos":[910,845],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":10,"pos":[910,1575],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":16,"pos":[0,15],"params":["Inherit","False","640","450","这些属性提供纹理、颜色和参数；属性名与原 Shader 一致。","1","2","材质输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":2,"pos":[50,115],"params":["Inherit","False","Property","_FlipHorizontally","Flip Horizontally","1","1","[Toggle]","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":4,"pos":[910,115],"params":["Inherit","False","Constant","_Float0","Float 0","2","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":7,"pos":[1310,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":8,"pos":[910,1210],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":13,"pos":[1310,480],"params":["Inherit","False","ase_n9_13","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":9,"pos":[1710,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":14,"pos":[1710,480],"params":["Inherit","False","13","ase_n9_13","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":15,"pos":[2680,15],"params":["Inherit","False","800","450","按 UV 采样纹理。表达式：tex2D(_MainTex, uv) 模板先在顶点阶段应用 _MainTex 的缩放/偏移，最终保留 Alpha 并应用 Unity 雾效；双面可见。","2","1","12","计算 col","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":1,"pos":[2730,115],"params":["Inherit","True","Property","_MainTex","Texture","0","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":11,"pos":[2110,115],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":12,"pos":[3130,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","2","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[3830,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","100","1","Unlit/Normal360_ASE","a99d644facf4442398d54acf418923b9","True","Unlit","0","0","Unlit","2","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","RenderType=Opaque=RenderType","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[6,0,3,0]}
{"wire":[10,0,3,0]}
{"wire":[7,0,5,0]}
{"wire":[7,1,6,0]}
{"wire":[8,0,3,0]}
{"wire":[13,0,10,0]}
{"wire":[9,0,2,0]}
{"wire":[9,1,4,0]}
{"wire":[9,2,7,0]}
{"wire":[9,3,8,0]}
{"wire":[9,4,8,0]}
{"wire":[11,0,9,0]}
{"wire":[11,1,14,0]}
{"wire":[12,0,1,0]}
{"wire":[12,1,11,0]}
{"wire":[0,0,12,0]}
ASEEND*/
//CHKSM=E76C9F6CBDD8CA3B6EDE22BB130002D23C92C8DB