// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader "ASELibrary/HDRP/PublicFilters/Vignette"
{
    Properties
    {
        _Aspect( "纵横比向量", Vector ) = ( 1, 1, 0, 0 )
        _Falloff( "暗角衰减", Range( 0, 3 ) ) = 0.5
        [NoScaleOffset] _MainTex( "输入图像", 2D ) = "white" {}

    }
    SubShader
    {
		LOD 0

        Tags { "RenderType"="Opaque" "RenderPipeline"="HDRenderPipeline" }
        Cull Off
        ZWrite Off
        ZTest Always
        Blend Off
        
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_SRP_VERSION 140008
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 3.0
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #include "UnityCG.cginc"
            #if defined(SHADER_API_GLES)
                #define TEXTURE2D(name) sampler2D name
                #define SAMPLER(name)
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)
            #else
                #define TEXTURE2D(name) Texture2D name
                #define SAMPLER(name) SamplerState name
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)
            #endif
            // ASE SRP Time nodes use seconds from _TimeParameters.x. Preserve
            // the source's engine time even for explicit Blit without a camera.
            #define _TimeParameters float4(_Time.y, sin(_Time.y), cos(_Time.y), 0.0)
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0

            struct FilterInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                
            };
            struct FilterVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            CBUFFER_START( UnityPerMaterial )
            float4 _Aspect;
            float _Falloff;
            CBUFFER_END

            FilterVaryings FilterVertex(FilterInput v )
            {
                FilterVaryings o;
                
                v.position.xyz += float3(0,0,0);
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                return o;
            }
            float4 FilterFragment(FilterVaryings i ) : SV_Target
            {
                float2 texCoord1 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float2 ase_TextureCoordinatesNode_2929 = texCoord1;
                float4 tex2DNode20 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, ase_TextureCoordinatesNode_2929 );
                float temp_output_12_0 = ( length( ( ( ( ase_TextureCoordinatesNode_2929 - (float4( 0.5, 0.5, 0, 0 )).xy ) * (_Aspect).xy ) * 2.0 ) ) * _Falloff );
                float temp_output_15_0 = ( ( temp_output_12_0 * temp_output_12_0 ) + 1.0 );
                float3 temp_output_22_0 = ( (tex2DNode20).rgb * ( 1.0 / ( temp_output_15_0 * temp_output_15_0 ) ) );
                float4 appendResult27 = (float4((temp_output_22_0).x , (temp_output_22_0).y , (temp_output_22_0).z , (tex2DNode20).a));
                
                return (appendResult27).xyzw;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":33,"pos":[900,15],"params":["Inherit","False","1700","820","保留原始 UV0 和原 shader uniform 名称；原 C# 宿主提供的参数现可在材质中显式设置。纹理无 ST 变换，与原片元一致。","9","2","3","4","5","6","7","8","9","30","02 坐标与参数","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":2,"pos":[950,115],"params":["Inherit","False","Constant","_Vector0","Vector 0","0","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5,0.5,0,0","0.5,0.5,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":3,"pos":[1290,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":5,"pos":[1290,115],"params":["Inherit","False","Property","_Aspect","纵横比向量","0","0","Create","False","0","0","0","True","0","False","Object","-1","","1,1,0,0","1,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":30,"pos":[1290,605],"params":["Inherit","False","29","ase_TextureCoordinatesNode_29","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":4,"pos":[1630,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":6,"pos":[1630,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":7,"pos":[1970,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":8,"pos":[1970,115],"params":["Inherit","False","Constant","_Float0","Float 0","1","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":9,"pos":[2310,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":34,"pos":[2820,15],"params":["Inherit","False","3060","1065","径向距离乘 Falloff，衰减为 1 / (1 + r²)²；只衰减 RGB，保留输入 Alpha。","19","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","31","03 镜头暗角","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.LengthOpNode, AmplifyShaderEditor","id":10,"pos":[2870,360],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":11,"pos":[2870,115],"params":["Inherit","False","Property","_Falloff","暗角衰减","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5","0","0","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":32,"pos":[0,15],"params":["Inherit","False","680","330","MIT 来源 keijiro/KinoVignette / Vignette.shader。此图为显式输入纹理的全屏滤镜；不会自动注入相机。输入输出采用调用者相同色彩编码，不额外曝光或色调映射。","2","1","29","01 输入与宿主","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":12,"pos":[3210,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":13,"pos":[3550,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":14,"pos":[3550,115],"params":["Inherit","False","Constant","_Float1","Float 1","2","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":29,"pos":[390,115],"params":["Inherit","False","ase_TextureCoordinatesNode_29","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":15,"pos":[3890,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":19,"pos":[3890,115],"params":["Inherit","True","Property","_MainTex","输入图像","2","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":31,"pos":[3890,360],"params":["Inherit","False","29","ase_TextureCoordinatesNode_29","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":16,"pos":[4230,115],"params":["Inherit","False","Constant","_Float2","Float 2","2","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":17,"pos":[4230,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":20,"pos":[4230,360],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","3","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":18,"pos":[4570,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":21,"pos":[4570,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":22,"pos":[4910,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":23,"pos":[5250,850],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":24,"pos":[5250,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":25,"pos":[5250,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":26,"pos":[5250,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":27,"pos":[5590,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":35,"pos":[6100,15],"params":["Inherit","False","640","330","原 Pass 的 Cull Off、ZTest Always、ZWrite Off、Blend Off、RGBA 写入由插件自有模板保留。通过 ASE 保存重载和 Unity 编译后入库；采样夹具不代表真实相机集成或所有平台等价。","1","28","04 原始图像输出","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[6150,115],"params":["Inherit","False","FLOAT4","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[6790,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","2","ASELibrary/HDRP/PublicFilters/Vignette","b9e3bd2247b04c12ac193aa10cb6ed03","True","Unlit","0","0","Unlit","2","False","True","0","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","True","7","False","","False","False","True","2","RenderType=Opaque=RenderType","RenderPipeline=HDRenderPipeline","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[3,0,2,0]}
{"wire":[4,0,30,0]}
{"wire":[4,1,3,0]}
{"wire":[6,0,5,0]}
{"wire":[7,0,4,0]}
{"wire":[7,1,6,0]}
{"wire":[9,0,7,0]}
{"wire":[9,1,8,0]}
{"wire":[10,0,9,0]}
{"wire":[12,0,10,0]}
{"wire":[12,1,11,0]}
{"wire":[13,0,12,0]}
{"wire":[13,1,12,0]}
{"wire":[29,0,1,0]}
{"wire":[15,0,13,0]}
{"wire":[15,1,14,0]}
{"wire":[17,0,15,0]}
{"wire":[17,1,15,0]}
{"wire":[20,0,19,0]}
{"wire":[20,1,31,0]}
{"wire":[18,0,16,0]}
{"wire":[18,1,17,0]}
{"wire":[21,0,20,0]}
{"wire":[22,0,21,0]}
{"wire":[22,1,18,0]}
{"wire":[23,0,20,0]}
{"wire":[24,0,22,0]}
{"wire":[25,0,22,0]}
{"wire":[26,0,22,0]}
{"wire":[27,0,24,0]}
{"wire":[27,1,25,0]}
{"wire":[27,2,26,0]}
{"wire":[27,3,23,0]}
{"wire":[28,0,27,0]}
{"wire":[0,0,28,0]}
ASEEND*/
//CHKSM=7176EC7765996288FE2B4126977599B47047C552