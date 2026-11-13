// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader "ASELibrary/HDRP/PublicFilters/Mirror"
{
    Properties
    {
        _Divisor( "角度重复周期（弧度）", Range( 0.001, 6.283185 ) ) = 1.570796
        _Offset( "重复角偏移", Range( -6.283185, 6.283185 ) ) = 0
        _Roll( "旋转角", Range( -6.283185, 6.283185 ) ) = 0
        [Toggle( SYMMETRY_ON )] SYMMETRY( "全局镜面对称", Float ) = 0
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
            #pragma multi_compile _ SYMMETRY_ON

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
            float _Offset;
            float _Divisor;
            float _Roll;
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
                float2 temp_output_7_0 = ( texCoord1 - (float4( 0.5, 0.5, 0, 0 )).xy );
                float ase_______4343 = _Offset;
                float temp_output_12_0 = ( atan2( (temp_output_7_0).y , (temp_output_7_0).x ) + ase_______4343 );
                float ase____________4545 = _Divisor;
                float temp_output_16_0 = ( temp_output_12_0 - ( ase____________4545 * floor( ( temp_output_12_0 / ase____________4545 ) ) ) );
                float staticSwitch19 = ( float )0;
                #ifdef SYMMETRY_ON
                {
                	staticSwitch19 = min( temp_output_16_0, ( ase____________4545 - temp_output_16_0 ) );
                }
                #else
                {
                	staticSwitch19 = temp_output_16_0;
                }
                #endif
                float ase_____4949 = _Roll;
                float temp_output_21_0 = ( staticSwitch19 + ( ase_____4949 - ase_______4343 ) );
                float ase_LengthOpNode_5252 = length( temp_output_7_0 );
                float2 temp_output_34_0 = ( ( ( ( cos( temp_output_21_0 ) * (float4( 1, 0, 0, 0 )).xy ) + ( sin( temp_output_21_0 ) * (float4( 0, 1, 0, 0 )).xy ) ) * ase_LengthOpNode_5252 ) + (float4( 0.5, 0.5, 0, 0 )).xy );
                
                return (SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, max( min( temp_output_34_0, ( 2.0 - temp_output_34_0 ) ), -temp_output_34_0 ) )).rgba;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":55,"pos":[860,15],"params":["Inherit","False","1700","1065","保留原始 UV0 和原 shader uniform 名称；原 C# 宿主提供的参数现可在材质中显式设置。纹理无 ST 变换，与原片元一致。","14","2","3","4","5","6","7","8","9","10","11","43","45","49","52","02 坐标与参数","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":5,"pos":[910,850],"params":["Inherit","False","Constant","_Vector0","Vector 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5,0.5,0,0","0.5,0.5,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":54,"pos":[0,15],"params":["Inherit","False","640","330","MIT 来源 keijiro/KinoMirror / Mirror.shader。此图为显式输入纹理的全屏滤镜；不会自动注入相机。输入输出采用调用者相同色彩编码，不额外曝光或色调映射。","1","1","01 输入与宿主","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":6,"pos":[1250,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":56,"pos":[2780,15],"params":["Inherit","False","6460","1065","保留 atan2、角度取模、边界反射与原全局 SYMMETRY_ON multi_compile；不是普通 UV 旋转。Divisor 必须大于 0。","37","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","44","46","47","48","50","51","53","03 极坐标镜像","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":2,"pos":[910,115],"params":["Inherit","False","Property","_Divisor","角度重复周期（弧度）","0","0","Create","False","0","0","0","True","0","False","Object","-1","","1.570796","0","0.001","6.283185","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":3,"pos":[910,360],"params":["Inherit","False","Property","_Offset","重复角偏移","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","-6.283185","6.283185","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":7,"pos":[1590,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":46,"pos":[3170,115],"params":["Inherit","False","45","ase____________45","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":8,"pos":[1930,115],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":9,"pos":[1930,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":13,"pos":[3510,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":43,"pos":[1250,360],"params":["Inherit","False","ase_______43","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":45,"pos":[1250,115],"params":["Inherit","False","ase____________45","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":4,"pos":[910,605],"params":["Inherit","False","Property","_Roll","旋转角","2","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","-6.283185","6.283185","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ATan2OpNode, AmplifyShaderEditor","id":10,"pos":[2270,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FloorOpNode, AmplifyShaderEditor","id":14,"pos":[3850,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":44,"pos":[2830,115],"params":["Inherit","False","43","ase_______43","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":47,"pos":[3850,360],"params":["Inherit","False","45","ase____________45","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":48,"pos":[4530,115],"params":["Inherit","False","45","ase____________45","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":12,"pos":[3170,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":15,"pos":[4190,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":17,"pos":[4870,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":49,"pos":[1250,605],"params":["Inherit","False","ase_____49","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":16,"pos":[4530,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":18,"pos":[5210,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":50,"pos":[5210,605],"params":["Inherit","False","49","ase_____49","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":51,"pos":[5210,360],"params":["Inherit","False","43","ase_______43","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StaticSwitch, AmplifyShaderEditor","id":19,"pos":[5550,115],"params":["Inherit","False","Property","SYMMETRY","全局镜面对称","3","0","Create","False","0","0","0","True","0","False","","1","0","0","True","","Toggle","2","Key0","Key1","Create","False","True","All","False","False","True","9","1","FLOAT","0","False","0","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","5","FLOAT","0","False","6","FLOAT","0","False","7","FLOAT","0","False","8","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":20,"pos":[5550,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":21,"pos":[5890,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":24,"pos":[5890,115],"params":["Inherit","False","Constant","_Vector1","Vector 1","4","0","Create","True","0","0","0","False","0","False","Object","-1","","1,0,0,0","1,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":27,"pos":[5890,360],"params":["Inherit","False","Constant","_Vector2","Vector 2","4","0","Create","True","0","0","0","False","0","False","Object","-1","","0,1,0,0","0,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.LengthOpNode, AmplifyShaderEditor","id":11,"pos":[1930,605],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor","id":22,"pos":[6230,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":23,"pos":[6230,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":25,"pos":[6230,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[6230,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":26,"pos":[6570,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":29,"pos":[6570,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":52,"pos":[2270,360],"params":["Inherit","False","ase_LengthOpNode_52","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":30,"pos":[6910,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":32,"pos":[6910,115],"params":["Inherit","False","Constant","_Vector3","Vector 3","4","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5,0.5,0,0","0.5,0.5,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":53,"pos":[6910,605],"params":["Inherit","False","52","ase_LengthOpNode_52","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[7250,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":33,"pos":[7250,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":35,"pos":[7590,115],"params":["Inherit","False","Constant","_Float0","Float 0","4","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":34,"pos":[7590,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":36,"pos":[7930,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMinOpNode, AmplifyShaderEditor","id":37,"pos":[8270,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":38,"pos":[8270,360],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":39,"pos":[8610,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":40,"pos":[8610,115],"params":["Inherit","True","Property","_MainTex","输入图像","4","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":41,"pos":[8950,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","5","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":57,"pos":[9460,15],"params":["Inherit","False","640","330","原 Pass 的 Cull Off、ZTest Always、ZWrite Off、Blend Off、RGBA 写入由插件自有模板保留。通过 ASE 保存重载和 Unity 编译后入库；采样夹具不代表真实相机集成或所有平台等价。","1","42","04 原始图像输出","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":42,"pos":[9510,115],"params":["Inherit","False","FLOAT4","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[10150,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","2","ASELibrary/HDRP/PublicFilters/Mirror","b9e3bd2247b04c12ac193aa10cb6ed03","True","Unlit","0","0","Unlit","2","False","True","0","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","True","7","False","","False","False","True","2","RenderType=Opaque=RenderType","RenderPipeline=HDRenderPipeline","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[6,0,5,0]}
{"wire":[7,0,1,0]}
{"wire":[7,1,6,0]}
{"wire":[8,0,7,0]}
{"wire":[9,0,7,0]}
{"wire":[13,0,12,0]}
{"wire":[13,1,46,0]}
{"wire":[43,0,3,0]}
{"wire":[45,0,2,0]}
{"wire":[10,0,8,0]}
{"wire":[10,1,9,0]}
{"wire":[14,0,13,0]}
{"wire":[12,0,10,0]}
{"wire":[12,1,44,0]}
{"wire":[15,0,47,0]}
{"wire":[15,1,14,0]}
{"wire":[17,0,48,0]}
{"wire":[17,1,16,0]}
{"wire":[49,0,4,0]}
{"wire":[16,0,12,0]}
{"wire":[16,1,15,0]}
{"wire":[18,0,16,0]}
{"wire":[18,1,17,0]}
{"wire":[19,1,16,0]}
{"wire":[19,0,18,0]}
{"wire":[20,0,50,0]}
{"wire":[20,1,51,0]}
{"wire":[21,0,19,0]}
{"wire":[21,1,20,0]}
{"wire":[11,0,7,0]}
{"wire":[22,0,21,0]}
{"wire":[23,0,21,0]}
{"wire":[25,0,24,0]}
{"wire":[28,0,27,0]}
{"wire":[26,0,22,0]}
{"wire":[26,1,25,0]}
{"wire":[29,0,23,0]}
{"wire":[29,1,28,0]}
{"wire":[52,0,11,0]}
{"wire":[30,0,26,0]}
{"wire":[30,1,29,0]}
{"wire":[31,0,30,0]}
{"wire":[31,1,53,0]}
{"wire":[33,0,32,0]}
{"wire":[34,0,31,0]}
{"wire":[34,1,33,0]}
{"wire":[36,0,35,0]}
{"wire":[36,1,34,0]}
{"wire":[37,0,34,0]}
{"wire":[37,1,36,0]}
{"wire":[38,0,34,0]}
{"wire":[39,0,37,0]}
{"wire":[39,1,38,0]}
{"wire":[41,0,40,0]}
{"wire":[41,1,39,0]}
{"wire":[42,0,41,0]}
{"wire":[0,0,42,0]}
ASEEND*/
//CHKSM=5B56ED752A64B7028B94B931829C4B4780A5C2AB