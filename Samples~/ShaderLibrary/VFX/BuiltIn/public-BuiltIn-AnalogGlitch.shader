// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader "ASELibrary/BuiltIn/PublicFilters/AnalogGlitch"
{
    Properties
    {
        _ScanLineJitter( "扫描线位移与阈值", Vector ) = ( 0, 1, 0, 0 )
        _VerticalJump( "垂直跳动强度与相位", Vector ) = ( 0, 0, 0, 0 )
        _ColorDrift( "颜色漂移强度与相位", Vector ) = ( 0, 0, 0, 0 )
        _HorizontalShake( "横向抖动", Range( 0, 1 ) ) = 0
        [NoScaleOffset] _MainTex( "输入图像", 2D ) = "white" {}

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
            #include "UnityShaderVariables.cginc"
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
            uniform float4 _ScanLineJitter;
            uniform float _HorizontalShake;
            uniform float4 _VerticalJump;
            SamplerState sampler_MainTex;
            uniform float4 _ColorDrift;

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
                float ase_SwizzleNode_113113 = (texCoord1).x;
                float ase_SwizzleNode_9898 = (texCoord1).y;
                float temp_output_6_0 = ( _Time.y / 20.0 );
                float temp_output_25_0 = ( ( frac( ( sin( ( ( ase_SwizzleNode_9898 * 12.9898 ) + ( temp_output_6_0 * 78.233 ) ) ) * 43758.55 ) ) * 2.0 ) - 1.0 );
                float2 ase_SwizzleNode_100100 = (_ScanLineJitter).xy;
                float ase_SimpleDivideOpNode_108108 = temp_output_6_0;
                float temp_output_57_0 = ( ( ase_SwizzleNode_113113 + ( temp_output_25_0 * ( step( (ase_SwizzleNode_100100).y , abs( temp_output_25_0 ) ) * (ase_SwizzleNode_100100).x ) ) ) + ( ( frac( ( sin( ( ( ase_SimpleDivideOpNode_108108 * 12.9898 ) + ( 2.0 * 78.233 ) ) ) * 43758.55 ) ) - 0.5 ) * _HorizontalShake ) );
                float2 ase_SwizzleNode_103103 = (_VerticalJump).xy;
                float lerpResult36 = lerp( ase_SwizzleNode_9898 , frac( ( ase_SwizzleNode_9898 + (ase_SwizzleNode_103103).y ) ) , (ase_SwizzleNode_103103).x);
                float ase_LerpOp_115115 = lerpResult36;
                float4 tex2DNode67 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, frac( ( ( temp_output_57_0 * (float4( 1, 0, 0, 0 )).xy ) + ( ase_LerpOp_115115 * (float4( 0, 1, 0, 0 )).xy ) ) ) );
                float2 ase_SwizzleNode_110110 = (_ColorDrift).xy;
                float3 temp_output_91_0 = ( ( ( (tex2DNode67).r * (float4( 1, 0, 0, 0 )).xyz ) + ( (SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, frac( ( ( ( temp_output_57_0 + ( sin( ( lerpResult36 + (ase_SwizzleNode_110110).y ) ) * (ase_SwizzleNode_110110).x ) ) * (float4( 1, 0, 0, 0 )).xy ) + ( ase_LerpOp_115115 * (float4( 0, 1, 0, 0 )).xy ) ) ) )).g * (float4( 0, 1, 0, 0 )).xyz ) ) + ( (tex2DNode67).b * (float4( 0, 0, 1, 0 )).xyz ) );
                float4 appendResult96 = (float4((temp_output_91_0).x , (temp_output_91_0).y , (temp_output_91_0).z , 1.0));
                
                return (appendResult96).xyzw;
            }
            ENDCG
        }
    }
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":118,"pos":[0,15],"params":["Inherit","False","640","330","MIT 来源 keijiro/KinoGlitch / AnalogGlitch.shader。此图为显式输入纹理的全屏滤镜；不会自动注入相机。输入输出采用调用者相同色彩编码，不额外曝光或色调映射。","1","1","01 输入与宿主","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":119,"pos":[860,15],"params":["Inherit","False","1020","1800","保留原始 UV0 和原 shader uniform 名称；原 C# 宿主提供的参数现可在材质中显式设置。纹理无 ST 变换，与原片元一致。","17","2","3","4","5","6","7","8","9","10","11","12","98","100","103","108","110","113","02 坐标与参数","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":3,"pos":[910,1585],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":4,"pos":[910,115],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":5,"pos":[910,360],"params":["Inherit","False","Constant","_Float0","Float 0","0","0","Create","True","0","0","0","False","0","False","Object","-1","","20","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":98,"pos":[1250,1340],"params":["Inherit","False","ase_SwizzleNode_98","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":120,"pos":[2100,15],"params":["Inherit","False","8500","1800","保留 nrand 常数、_Time.x=秒/20、扫描线阈值、垂直跳动、横抖及独立绿色通道漂移。外部宿主负责动画参数积分。","98","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","99","101","102","104","105","106","107","109","111","112","114","115","116","117","03 信号扰动","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":6,"pos":[1250,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[2150,115],"params":["Inherit","False","Constant","_Float1","Float 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","12.9898","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":15,"pos":[2150,360],"params":["Inherit","False","Constant","_Float2","Float 2","3","0","Create","True","0","0","0","False","0","False","Object","-1","","78.233","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":99,"pos":[2150,605],"params":["Inherit","False","98","ase_SwizzleNode_98","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":7,"pos":[910,605],"params":["Inherit","False","Property","_ScanLineJitter","扫描线位移与阈值","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0,1,0,0","0,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":9,"pos":[910,850],"params":["Inherit","False","Property","_VerticalJump","垂直跳动强度与相位","1","0","Create","False","0","0","0","True","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":14,"pos":[2490,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":16,"pos":[2490,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":108,"pos":[1590,115],"params":["Inherit","False","ase_SimpleDivideOpNode_108","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":8,"pos":[1250,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":10,"pos":[1250,605],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":11,"pos":[910,1095],"params":["Inherit","False","Property","_ColorDrift","颜色漂移强度与相位","2","0","Create","False","0","0","0","True","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":17,"pos":[2830,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":37,"pos":[3850,360],"params":["Inherit","False","Constant","_Float6","Float 6","3","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":38,"pos":[3850,605],"params":["Inherit","False","Constant","_Float7","Float 7","3","0","Create","True","0","0","0","False","0","False","Object","-1","","12.9898","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":40,"pos":[3850,850],"params":["Inherit","False","Constant","_Float8","Float 8","3","0","Create","True","0","0","0","False","0","False","Object","-1","","78.233","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":109,"pos":[3850,1340],"params":["Inherit","False","108","ase_SimpleDivideOpNode_108","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":12,"pos":[1250,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":18,"pos":[3170,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":19,"pos":[3170,115],"params":["Inherit","False","Constant","_Float3","Float 3","3","0","Create","True","0","0","0","False","0","False","Object","-1","","43758.55","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":39,"pos":[4190,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":41,"pos":[4190,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":100,"pos":[1590,360],"params":["Inherit","False","ase_SwizzleNode_100","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":103,"pos":[1590,605],"params":["Inherit","False","ase_SwizzleNode_103","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":20,"pos":[3510,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":42,"pos":[4530,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":101,"pos":[4530,360],"params":["Inherit","False","100","ase_SwizzleNode_100","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":104,"pos":[4190,850],"params":["Inherit","False","103","ase_SwizzleNode_103","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":110,"pos":[1590,850],"params":["Inherit","False","ase_SwizzleNode_110","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":21,"pos":[3850,1095],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":22,"pos":[3850,115],"params":["Inherit","False","Constant","_Float4","Float 4","3","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":26,"pos":[4870,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":27,"pos":[4870,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":32,"pos":[4530,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":43,"pos":[4870,1340],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":44,"pos":[4870,115],"params":["Inherit","False","Constant","_Float9","Float 9","3","0","Create","True","0","0","0","False","0","False","Object","-1","","43758.55","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":102,"pos":[4870,850],"params":["Inherit","False","100","ase_SwizzleNode_100","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":105,"pos":[4530,1095],"params":["Inherit","False","98","ase_SwizzleNode_98","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":111,"pos":[5210,1095],"params":["Inherit","False","110","ase_SwizzleNode_110","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":2,"pos":[910,1340],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":23,"pos":[4190,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":24,"pos":[4190,115],"params":["Inherit","False","Constant","_Float5","Float 5","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":28,"pos":[5210,115],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":29,"pos":[5210,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":33,"pos":[4870,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":45,"pos":[5210,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":51,"pos":[5550,850],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":106,"pos":[4870,1095],"params":["Inherit","False","103","ase_SwizzleNode_103","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":25,"pos":[4530,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":30,"pos":[5550,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":34,"pos":[5210,1585],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":35,"pos":[5210,850],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":46,"pos":[5550,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":47,"pos":[5550,115],"params":["Inherit","False","Constant","_Float10","Float 10","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":52,"pos":[5890,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":107,"pos":[5210,1340],"params":["Inherit","False","98","ase_SwizzleNode_98","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":112,"pos":[5890,850],"params":["Inherit","False","110","ase_SwizzleNode_110","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":113,"pos":[1250,1095],"params":["Inherit","False","ase_SwizzleNode_113","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[5890,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":36,"pos":[5550,1095],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":48,"pos":[5890,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":49,"pos":[5890,115],"params":["Inherit","False","Property","_HorizontalShake","横向抖动","3","0","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":53,"pos":[6230,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":54,"pos":[6230,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":114,"pos":[5890,1340],"params":["Inherit","False","113","ase_SwizzleNode_113","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":50,"pos":[6230,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":55,"pos":[6570,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":56,"pos":[6230,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":58,"pos":[6570,115],"params":["Inherit","False","Constant","_Vector0","Vector 0","4","0","Create","True","0","0","0","False","0","False","Object","-1","","1,0,0,0","1,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":61,"pos":[6570,360],"params":["Inherit","False","Constant","_Vector1","Vector 1","4","0","Create","True","0","0","0","False","0","False","Object","-1","","0,1,0,0","0,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":69,"pos":[6570,605],"params":["Inherit","False","Constant","_Vector2","Vector 2","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1,0,0,0","1,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":72,"pos":[6570,850],"params":["Inherit","False","Constant","_Vector3","Vector 3","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0,1,0,0","0,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":115,"pos":[6570,1585],"params":["Inherit","False","ase_LerpOp_115","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":57,"pos":[6570,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":59,"pos":[6910,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":62,"pos":[6910,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":68,"pos":[6910,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":70,"pos":[6910,605],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":73,"pos":[6910,850],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":116,"pos":[6910,1340],"params":["Inherit","False","115","ase_LerpOp_115","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":117,"pos":[6910,1585],"params":["Inherit","False","115","ase_LerpOp_115","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":60,"pos":[7250,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":63,"pos":[7250,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":71,"pos":[7250,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":74,"pos":[7250,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":64,"pos":[7590,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":75,"pos":[7590,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":65,"pos":[7930,360],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":66,"pos":[7930,115],"params":["Inherit","True","Property","_MainTex","输入图像","4","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":76,"pos":[7930,605],"params":["Inherit","False","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":67,"pos":[8270,605],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","5","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":77,"pos":[8270,850],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","6","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":81,"pos":[8270,115],"params":["Inherit","False","Constant","_Vector4","Vector 4","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1,0,0,0","1,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":84,"pos":[8270,360],"params":["Inherit","False","Constant","_Vector5","Vector 5","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0,1,0,0","0,1,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":78,"pos":[8610,850],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":79,"pos":[8610,1095],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":82,"pos":[8610,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":85,"pos":[8610,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":88,"pos":[8610,115],"params":["Inherit","False","Constant","_Vector6","Vector 6","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,1,0","0,0,1,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":80,"pos":[8950,360],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":83,"pos":[8950,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":86,"pos":[8950,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":89,"pos":[8950,115],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":87,"pos":[9290,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":90,"pos":[9290,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":91,"pos":[9630,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":92,"pos":[9970,115],"params":["Inherit","False","Constant","_Float11","Float 11","7","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":93,"pos":[9970,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":94,"pos":[9970,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":95,"pos":[9970,850],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":96,"pos":[10310,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":121,"pos":[10820,15],"params":["Inherit","False","640","330","原 Pass 的 Cull Off、ZTest Always、ZWrite Off、Blend Off、RGBA 写入由插件自有模板保留。通过 ASE 保存重载和 Unity 编译后入库；采样夹具不代表真实相机集成或所有平台等价。","1","97","04 原始图像输出","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":97,"pos":[10870,115],"params":["Inherit","False","FLOAT4","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[11510,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","1","ASELibrary/BuiltIn/PublicFilters/AnalogGlitch","b9e3bd2247b04c12ac193aa10cb6ed01","True","Unlit","0","0","Unlit","2","False","True","0","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","True","7","False","","False","False","True","1","RenderType=Opaque=RenderType","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[3,0,1,0]}
{"wire":[98,0,3,0]}
{"wire":[6,0,4,0]}
{"wire":[6,1,5,0]}
{"wire":[14,0,99,0]}
{"wire":[14,1,13,0]}
{"wire":[16,0,6,0]}
{"wire":[16,1,15,0]}
{"wire":[108,0,6,0]}
{"wire":[8,0,7,0]}
{"wire":[10,0,9,0]}
{"wire":[17,0,14,0]}
{"wire":[17,1,16,0]}
{"wire":[12,0,11,0]}
{"wire":[18,0,17,0]}
{"wire":[39,0,109,0]}
{"wire":[39,1,38,0]}
{"wire":[41,0,37,0]}
{"wire":[41,1,40,0]}
{"wire":[100,0,8,0]}
{"wire":[103,0,10,0]}
{"wire":[20,0,18,0]}
{"wire":[20,1,19,0]}
{"wire":[42,0,39,0]}
{"wire":[42,1,41,0]}
{"wire":[110,0,12,0]}
{"wire":[21,0,20,0]}
{"wire":[26,0,101,0]}
{"wire":[27,0,25,0]}
{"wire":[32,0,104,0]}
{"wire":[43,0,42,0]}
{"wire":[2,0,1,0]}
{"wire":[23,0,21,0]}
{"wire":[23,1,22,0]}
{"wire":[28,0,26,0]}
{"wire":[28,1,27,0]}
{"wire":[29,0,102,0]}
{"wire":[33,0,105,0]}
{"wire":[33,1,32,0]}
{"wire":[45,0,43,0]}
{"wire":[45,1,44,0]}
{"wire":[51,0,111,0]}
{"wire":[25,0,23,0]}
{"wire":[25,1,24,0]}
{"wire":[30,0,28,0]}
{"wire":[30,1,29,0]}
{"wire":[34,0,33,0]}
{"wire":[35,0,106,0]}
{"wire":[46,0,45,0]}
{"wire":[52,0,36,0]}
{"wire":[52,1,51,0]}
{"wire":[113,0,2,0]}
{"wire":[31,0,25,0]}
{"wire":[31,1,30,0]}
{"wire":[36,0,107,0]}
{"wire":[36,1,34,0]}
{"wire":[36,2,35,0]}
{"wire":[48,0,46,0]}
{"wire":[48,1,47,0]}
{"wire":[53,0,52,0]}
{"wire":[54,0,112,0]}
{"wire":[50,0,48,0]}
{"wire":[50,1,49,0]}
{"wire":[55,0,53,0]}
{"wire":[55,1,54,0]}
{"wire":[56,0,114,0]}
{"wire":[56,1,31,0]}
{"wire":[115,0,36,0]}
{"wire":[57,0,56,0]}
{"wire":[57,1,50,0]}
{"wire":[59,0,58,0]}
{"wire":[62,0,61,0]}
{"wire":[68,0,57,0]}
{"wire":[68,1,55,0]}
{"wire":[70,0,69,0]}
{"wire":[73,0,72,0]}
{"wire":[60,0,57,0]}
{"wire":[60,1,59,0]}
{"wire":[63,0,116,0]}
{"wire":[63,1,62,0]}
{"wire":[71,0,68,0]}
{"wire":[71,1,70,0]}
{"wire":[74,0,117,0]}
{"wire":[74,1,73,0]}
{"wire":[64,0,60,0]}
{"wire":[64,1,63,0]}
{"wire":[75,0,71,0]}
{"wire":[75,1,74,0]}
{"wire":[65,0,64,0]}
{"wire":[76,0,75,0]}
{"wire":[67,0,66,0]}
{"wire":[67,1,65,0]}
{"wire":[77,0,66,0]}
{"wire":[77,1,76,0]}
{"wire":[78,0,67,0]}
{"wire":[79,0,77,0]}
{"wire":[82,0,81,0]}
{"wire":[85,0,84,0]}
{"wire":[80,0,67,0]}
{"wire":[83,0,78,0]}
{"wire":[83,1,82,0]}
{"wire":[86,0,79,0]}
{"wire":[86,1,85,0]}
{"wire":[89,0,88,0]}
{"wire":[87,0,83,0]}
{"wire":[87,1,86,0]}
{"wire":[90,0,80,0]}
{"wire":[90,1,89,0]}
{"wire":[91,0,87,0]}
{"wire":[91,1,90,0]}
{"wire":[93,0,91,0]}
{"wire":[94,0,91,0]}
{"wire":[95,0,91,0]}
{"wire":[96,0,93,0]}
{"wire":[96,1,94,0]}
{"wire":[96,2,95,0]}
{"wire":[96,3,92,0]}
{"wire":[97,0,96,0]}
{"wire":[0,0,97,0]}
ASEEND*/
//CHKSM=4E8FC0467D204C0BA39950A377F27D03FD92B401