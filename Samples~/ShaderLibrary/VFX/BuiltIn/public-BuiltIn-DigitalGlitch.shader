// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader "ASELibrary/BuiltIn/PublicFilters/DigitalGlitch"
{
    Properties
    {
        [NoScaleOffset] _NoiseTex( "外部故障噪声", 2D ) = "black" {}
        _Intensity( "故障强度", Range( 0, 1 ) ) = 0
        [NoScaleOffset] _MainTex( "输入图像", 2D ) = "white" {}
        [NoScaleOffset] _TrashTex( "外部历史帧", 2D ) = "black" {}

    }
    SubShader
    {
		LOD 0

        Tags { "RenderType"="Opaque" }
        Cull Off
        ZWrite Off
        ZTest Always
        Blend Off
        
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 3.0
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #include "UnityCG.cginc"
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
            #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
            #else//ASE Sampling Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
            #endif//ASE Sampling Macros
            

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
            UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
            UNITY_DECLARE_TEX2D_NOSAMPLER(_NoiseTex);
            SamplerState sampler_NoiseTex;
            uniform float _Intensity;
            SamplerState sampler_MainTex;
            UNITY_DECLARE_TEX2D_NOSAMPLER(_TrashTex);
            SamplerState sampler_TrashTex;

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
                float2 ase_TextureCoordinatesNode_5656 = texCoord1;
                float4 tex2DNode3 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, texCoord1 );
                float temp_output_8_0 = ( 1.001 - ( _Intensity * 1.001 ) );
                float2 temp_output_24_0 = frac( ( ase_TextureCoordinatesNode_5656 + ( (tex2DNode3).rg * step( temp_output_8_0 , pow( (tex2DNode3).b , 2.5 ) ) ) ) );
                float4 tex2DNode26 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, temp_output_24_0 );
                float ase_SimpleSubtractOpNode_5252 = temp_output_8_0;
                float4 ase_SamplerNode_5050 = tex2DNode3;
                float4 lerpResult29 = lerp( tex2DNode26 , SAMPLE_TEXTURE2D( _TrashTex, sampler_TrashTex, temp_output_24_0 ) , step( ase_SimpleSubtractOpNode_5252 , pow( (ase_SamplerNode_5050).a , 2.5 ) ));
                float3 temp_output_30_0 = (lerpResult29).rgb;
                float3 ase_SwizzleNode_5858 = temp_output_30_0;
                float3 lerpResult43 = lerp( ase_SwizzleNode_5858 , saturate( ( (ase_SwizzleNode_5858).yxz + ( ( 1.0 - ( ( (temp_output_30_0).x + (temp_output_30_0).y ) + (temp_output_30_0).z ) ) * 0.5 ) ) ) , step( ase_SimpleSubtractOpNode_5252 , pow( (ase_SamplerNode_5050).b , 3.5 ) ));
                float4 ase_SamplerNode_6161 = tex2DNode26;
                float4 appendResult48 = (float4((lerpResult43).x , (lerpResult43).y , (lerpResult43).z , (ase_SamplerNode_6161).a));
                
                return (appendResult48).xyzw;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":64,"pos":[900,15],"params":["Inherit","False","1360","820","保留原始 UV0 和原 shader uniform 名称；原 C# 宿主提供的参数现可在材质中显式设置。纹理无 ST 变换，与原片元一致。","9","2","3","4","5","6","7","8","50","52","02 坐标与参数","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":4,"pos":[950,360],"params":["Inherit","False","Property","_Intensity","故障强度","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":6,"pos":[950,605],"params":["Inherit","False","Constant","_Float1","Float 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.001","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":63,"pos":[0,15],"params":["Inherit","False","680","330","MIT 来源 keijiro/KinoGlitch / DigitalGlitch.shader。此图为显式输入纹理的全屏滤镜；不会自动注入相机。输入输出采用调用者相同色彩编码，不额外曝光或色调映射。","2","1","56","01 输入与宿主","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":65,"pos":[2480,15],"params":["Inherit","False","6460","1310","三个门限分别控制位移、历史帧替换和颜色置换；保留 2.5/3.5 次方与原 RGB 交换。调用者必须供应噪声和历史帧。","50","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","51","53","54","55","57","58","59","60","61","62","03 数字故障","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":2,"pos":[950,115],"params":["Inherit","True","Property","_NoiseTex","外部故障噪声","0","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":5,"pos":[1290,115],"params":["Inherit","False","Constant","_Float0","Float 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1.001","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":7,"pos":[1290,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":9,"pos":[2530,360],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":10,"pos":[2530,115],"params":["Inherit","False","Constant","_Float2","Float 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","2.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":3,"pos":[1290,360],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","1","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":8,"pos":[1630,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":11,"pos":[2870,115],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":12,"pos":[3210,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":21,"pos":[3210,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":50,"pos":[1630,360],"params":["Inherit","False","ase_SamplerNode_50","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":56,"pos":[390,115],"params":["Inherit","False","ase_TextureCoordinatesNode_56","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":22,"pos":[3550,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":51,"pos":[3550,605],"params":["Inherit","False","50","ase_SamplerNode_50","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":57,"pos":[3550,115],"params":["Inherit","False","56","ase_TextureCoordinatesNode_56","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":13,"pos":[3890,605],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":14,"pos":[3890,115],"params":["Inherit","False","Constant","_Float3","Float 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","2.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":23,"pos":[3890,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":31,"pos":[5590,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":32,"pos":[5590,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":52,"pos":[1970,115],"params":["Inherit","False","ase_SimpleSubtractOpNode_52","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":15,"pos":[4230,850],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":24,"pos":[4230,1095],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":25,"pos":[4230,115],"params":["Inherit","True","Property","_MainTex","输入图像","2","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":27,"pos":[4230,360],"params":["Inherit","True","Property","_TrashTex","外部历史帧","3","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","black","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":33,"pos":[5930,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":34,"pos":[5930,115],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":53,"pos":[4230,605],"params":["Inherit","False","52","ase_SimpleSubtractOpNode_52","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":16,"pos":[4570,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":26,"pos":[4570,360],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","4","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":28,"pos":[4570,605],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","6","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":35,"pos":[6270,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":37,"pos":[6270,115],"params":["Inherit","False","Constant","_Float5","Float 5","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":29,"pos":[4910,115],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":38,"pos":[6610,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":39,"pos":[6610,115],"params":["Inherit","False","Constant","_Float6","Float 6","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":54,"pos":[6610,605],"params":["Inherit","False","50","ase_SamplerNode_50","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":59,"pos":[6610,850],"params":["Inherit","False","58","ase_SwizzleNode_58","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":17,"pos":[6950,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":18,"pos":[6950,115],"params":["Inherit","False","Constant","_Float4","Float 4","3","0","Create","True","0","0","0","False","0","False","Object","-1","","3.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":30,"pos":[5250,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":36,"pos":[6950,850],"params":["Inherit","False","FLOAT3","1","0","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":40,"pos":[6950,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":19,"pos":[7290,360],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":41,"pos":[7290,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":55,"pos":[7290,115],"params":["Inherit","False","52","ase_SimpleSubtractOpNode_52","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":58,"pos":[6270,360],"params":["Inherit","False","ase_SwizzleNode_58","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":20,"pos":[7630,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":42,"pos":[7630,850],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":60,"pos":[7630,360],"params":["Inherit","False","58","ase_SwizzleNode_58","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":61,"pos":[7630,605],"params":["Inherit","False","ase_SamplerNode_61","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":43,"pos":[7970,115],"params":["Inherit","False","3","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","2","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":62,"pos":[7970,360],"params":["Inherit","False","61","ase_SamplerNode_61","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":44,"pos":[8310,850],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":45,"pos":[8310,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[8310,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":47,"pos":[8310,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":48,"pos":[8650,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":66,"pos":[9160,15],"params":["Inherit","False","640","330","原 Pass 的 Cull Off、ZTest Always、ZWrite Off、Blend Off、RGBA 写入由插件自有模板保留。通过 ASE 保存重载和 Unity 编译后入库；采样夹具不代表真实相机集成或所有平台等价。","1","49","04 原始图像输出","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":49,"pos":[9210,115],"params":["Inherit","False","FLOAT4","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[9850,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","ASELibrary/BuiltIn/PublicFilters/DigitalGlitch","b9e3bd2247b04c12ac193aa10cb6ed01","True","Unlit","0","0","Unlit","2","False","True","0","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","True","7","False","","False","False","True","1","RenderType=Opaque=RenderType","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[7,0,4,0]}
{"wire":[7,1,6,0]}
{"wire":[9,0,3,0]}
{"wire":[3,0,2,0]}
{"wire":[3,1,1,0]}
{"wire":[8,0,5,0]}
{"wire":[8,1,7,0]}
{"wire":[11,0,9,0]}
{"wire":[11,1,10,0]}
{"wire":[12,0,8,0]}
{"wire":[12,1,11,0]}
{"wire":[21,0,3,0]}
{"wire":[50,0,3,0]}
{"wire":[56,0,1,0]}
{"wire":[22,0,21,0]}
{"wire":[22,1,12,0]}
{"wire":[13,0,51,0]}
{"wire":[23,0,57,0]}
{"wire":[23,1,22,0]}
{"wire":[31,0,30,0]}
{"wire":[32,0,30,0]}
{"wire":[52,0,8,0]}
{"wire":[15,0,13,0]}
{"wire":[15,1,14,0]}
{"wire":[24,0,23,0]}
{"wire":[33,0,31,0]}
{"wire":[33,1,32,0]}
{"wire":[34,0,30,0]}
{"wire":[16,0,53,0]}
{"wire":[16,1,15,0]}
{"wire":[26,0,25,0]}
{"wire":[26,1,24,0]}
{"wire":[28,0,27,0]}
{"wire":[28,1,24,0]}
{"wire":[35,0,33,0]}
{"wire":[35,1,34,0]}
{"wire":[29,0,26,0]}
{"wire":[29,1,28,0]}
{"wire":[29,2,16,0]}
{"wire":[38,0,37,0]}
{"wire":[38,1,35,0]}
{"wire":[17,0,54,0]}
{"wire":[30,0,29,0]}
{"wire":[36,0,59,0]}
{"wire":[40,0,38,0]}
{"wire":[40,1,39,0]}
{"wire":[19,0,17,0]}
{"wire":[19,1,18,0]}
{"wire":[41,0,36,0]}
{"wire":[41,1,40,0]}
{"wire":[58,0,30,0]}
{"wire":[20,0,55,0]}
{"wire":[20,1,19,0]}
{"wire":[42,0,41,0]}
{"wire":[61,0,26,0]}
{"wire":[43,0,60,0]}
{"wire":[43,1,42,0]}
{"wire":[43,2,20,0]}
{"wire":[44,0,62,0]}
{"wire":[45,0,43,0]}
{"wire":[46,0,43,0]}
{"wire":[47,0,43,0]}
{"wire":[48,0,45,0]}
{"wire":[48,1,46,0]}
{"wire":[48,2,47,0]}
{"wire":[48,3,44,0]}
{"wire":[49,0,48,0]}
{"wire":[0,0,49,0]}
ASEEND*/
//CHKSM=89249D42D76C0EA3AACBA5A9EB2E6349DFF2CD8F