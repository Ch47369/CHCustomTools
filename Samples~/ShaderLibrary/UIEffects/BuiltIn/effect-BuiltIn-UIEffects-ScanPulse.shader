// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned template: straight alpha, hard rectangular clipping, global UI variants.
Shader "ASELibrary/BuiltIn/UIEffects/扫描线脉冲"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
        _BaseColor( "基色 / Base Color", Color ) = ( 0.2, 0.45, 0.6, 1 )
        [NoScaleOffset] _LibraryTex( "图像纹理", 2D ) = "white" {}
        _Speed( "流光速度", Range( -2, 2 ) ) = 0.2
        _Width( "流光带宽", Range( 0.001, 0.4 ) ) = 0.08
        _Shine( "流光颜色", Color ) = ( 0.7, 0.9, 1, 0 )
        _EffectSpeed( "扩展动画速度", Range( -4, 4 ) ) = 0.4
        _PatternFrequency( "图案频率", Range( 1, 400 ) ) = 60
        _EffectTint( "扩展叠色", Color ) = ( 0.4, 0.65, 0.3, 1 )
        _EffectAmount( "扩展影响强度", Range( 0, 1 ) ) = 0.55

    }
    SubShader
    {
		LOD 0

        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        Stencil
        {
        	Ref [_Stencil]
        	ReadMask [_StencilReadMask]
        	WriteMask [_StencilWriteMask]
        	Comp [_StencilComp]
        	Pass [_StencilOp]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
        
        Pass
        {
            Name "UI"
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 3.5
            #pragma vertex UiVertex
            #pragma fragment UiFragment
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "UnityShaderVariables.cginc"
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0
            #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
            #else//ASE Sampling Macros
            #define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
            #endif//ASE Sampling Macros
            

            struct UiInput
            {
                float4 position : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                
            };
            struct UiVaryings
            {
                float4 position : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float4 localPosition : TEXCOORD1;
                
            };
            fixed4 _Color;
            float4 _ClipRect;
            UNITY_DECLARE_TEX2D_NOSAMPLER(_LibraryTex);
            SamplerState sampler_LibraryTex;
            uniform float4 _BaseColor;
            uniform float4 _Shine;
            uniform float _Speed;
            uniform float _Width;
            uniform float4 _EffectTint;
            uniform float _EffectSpeed;
            uniform float _PatternFrequency;
            uniform float _EffectAmount;

            UiVaryings UiVertex(UiInput v )
            {
                UiVaryings o;
                
                v.position.xyz += float3(0,0,0);
                o.position = UnityObjectToClipPos(v.position);
                o.localPosition = v.position;
                o.uv = v.uv;
                o.color = v.color * _Color;
                return o;
            }
            fixed4 UiFragment(UiVaryings i ) : SV_Target
            {
                float2 texCoord1 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float4 ase_SimpleMultiplyOpNode_5050 = ( SAMPLE_TEXTURE2D( _LibraryTex, sampler_LibraryTex, texCoord1 ) * _BaseColor );
                float2 ase_TextureCoordinatesNode_4848 = texCoord1;
                float4 ase_SimpleAddOpNode_5252 = ( ase_SimpleMultiplyOpNode_5050 + ( _Shine * saturate( ( 1.0 - ( abs( ( (ase_TextureCoordinatesNode_4848).x - frac( ( _Time.y * _Speed ) ) ) ) / _Width ) ) ) ) );
                float2 texCoord21 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float4 lerpResult47 = lerp( ase_SimpleAddOpNode_5252 , ( ase_SimpleAddOpNode_5252 * _EffectTint ) , saturate( ( ( ( ( sin( ( _Time.y * _EffectSpeed ) ) * 0.4 ) + 0.6 ) * ( ( sin( ( (texCoord21).y * _PatternFrequency ) ) * 0.5 ) + 0.5 ) ) * _EffectAmount ) ));
                
                fixed4 color = lerpResult47;
                color *= i.color;
                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(i.localPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif
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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":55,"pos":[0,15],"params":["Inherit","False","1360","820","原创材质基础，不是樱花兔或网络素材的等价转换。基色按 sRGB 导入，遮罩按 Linear，法线按 NormalMap；需要按实际模型补齐贴图。","7","1","2","3","4","5","48","50","01 输入与资源","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":56,"pos":[1580,15],"params":["Inherit","False","3740","575","UV.x 与时间控制流光位置，带宽控制平滑边缘；模板保留顶点色、Tint、Stencil、矩形裁剪和 GUI 深度。","18","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","49","51","52","02 流光带","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":6,"pos":[1630,115],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":7,"pos":[1630,360],"params":["Inherit","False","Property","_Speed","流光速度","2","0","Create","False","0","0","0","True","0","False","Object","-1","","0.2","0","-2","2","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":48,"pos":[390,360],"params":["Inherit","False","ase_TextureCoordinatesNode_48","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":8,"pos":[1970,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":49,"pos":[1970,360],"params":["Inherit","False","48","ase_TextureCoordinatesNode_48","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.FractNode, AmplifyShaderEditor","id":9,"pos":[2310,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":10,"pos":[2310,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":57,"pos":[5540,15],"params":["Inherit","False","3400","1310","原创可编辑扩展：扫描线脉冲。程序图案使用 UV0；贴图型扩展需绑定实际资源。设备建议来自静态复杂度，未做 GPU 实机测速。","29","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","53","54","06 扫描线脉冲","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":11,"pos":[2650,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":21,"pos":[5590,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":3,"pos":[50,360],"params":["Inherit","True","Property","_LibraryTex","图像纹理","1","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":12,"pos":[2990,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[2990,115],"params":["Inherit","False","Property","_Width","流光带宽","3","0","Create","False","0","0","0","True","0","False","Object","-1","","0.08","0","0.001","0.4","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":23,"pos":[5930,1095],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":26,"pos":[5930,115],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":27,"pos":[5930,360],"params":["Inherit","False","Property","_EffectSpeed","扩展动画速度","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4","0","-4","4","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":34,"pos":[5930,605],"params":["Inherit","False","Property","_PatternFrequency","图案频率","6","0","Create","False","0","0","0","True","0","False","Object","-1","","60","0","1","400","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":2,"pos":[390,115],"params":["Inherit","False","Property","_BaseColor","基色 / Base Color","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.2,0.45,0.6,1","0.2,0.45,0.6,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":4,"pos":[390,605],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","2","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":14,"pos":[3330,115],"params":["Inherit","False","Constant","_Float0","Float 0","5","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":15,"pos":[3330,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":28,"pos":[6270,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":35,"pos":[6270,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":5,"pos":[730,115],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":16,"pos":[3670,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":29,"pos":[6610,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":30,"pos":[6610,115],"params":["Inherit","False","Constant","_Float3","Float 3","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor","id":36,"pos":[6610,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":37,"pos":[6610,360],"params":["Inherit","False","Constant","_Float5","Float 5","8","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":17,"pos":[4010,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":18,"pos":[4010,115],"params":["Inherit","False","Property","_Shine","流光颜色","4","0","Create","False","0","0","0","True","0","False","Object","-1","","0.7,0.9,1,0","0.7,0.9,1,0","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":31,"pos":[6950,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":32,"pos":[6950,115],"params":["Inherit","False","Constant","_Float4","Float 4","7","0","Create","True","0","0","0","False","0","False","Object","-1","","0.6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":38,"pos":[6950,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":39,"pos":[6950,360],"params":["Inherit","False","Constant","_Float6","Float 6","8","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":50,"pos":[1070,115],"params":["Inherit","False","ase_SimpleMultiplyOpNode_50","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":19,"pos":[4350,360],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":33,"pos":[7290,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":40,"pos":[7290,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":51,"pos":[4350,115],"params":["Inherit","False","50","ase_SimpleMultiplyOpNode_50","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":20,"pos":[4690,115],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":41,"pos":[7630,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":43,"pos":[7630,115],"params":["Inherit","False","Property","_EffectAmount","扩展影响强度","8","0","Create","False","0","0","0","True","0","False","Object","-1","","0.55","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":42,"pos":[7970,115],"params":["Inherit","False","Property","_EffectTint","扩展叠色","7","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4,0.65,0.3,1","0.4,0.65,0.3,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":45,"pos":[7970,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":52,"pos":[5030,115],"params":["Inherit","False","ase_SimpleAddOpNode_52","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":53,"pos":[7970,360],"params":["Inherit","False","52","ase_SimpleAddOpNode_52","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":44,"pos":[8310,360],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":46,"pos":[8310,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":54,"pos":[8310,115],"params":["Inherit","False","52","ase_SimpleAddOpNode_52","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":22,"pos":[5930,850],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":24,"pos":[5590,360],"params":["Inherit","False","Constant","_Float1","Float 1","6","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":25,"pos":[5590,605],"params":["Inherit","False","Constant","_Float2","Float 2","6","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":47,"pos":[8650,115],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[9290,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","3","ASELibrary/BuiltIn/UIEffects/扫描线脉冲","eab467e6cd0b4d27ab8e9e434d8c30e3","True","UI","0","0","UI","2","False","True","2","5","False","","10","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","True","True","True","True","True","0","True","_ColorMask","False","False","False","False","False","False","False","True","True","0","True","_Stencil","255","True","_StencilReadMask","255","True","_StencilWriteMask","0","True","_StencilComp","0","True","_StencilOp","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","0","True","unity_GUIZTestMode","False","False","True","5","Queue=Transparent=Queue=0","IgnoreProjector=True","RenderType=Transparent=RenderType","PreviewType=Plane","CanUseSpriteAtlas=True","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","3","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[48,0,1,0]}
{"wire":[8,0,6,0]}
{"wire":[8,1,7,0]}
{"wire":[9,0,8,0]}
{"wire":[10,0,49,0]}
{"wire":[11,0,10,0]}
{"wire":[11,1,9,0]}
{"wire":[12,0,11,0]}
{"wire":[23,0,21,0]}
{"wire":[4,0,3,0]}
{"wire":[4,1,1,0]}
{"wire":[15,0,12,0]}
{"wire":[15,1,13,0]}
{"wire":[28,0,26,0]}
{"wire":[28,1,27,0]}
{"wire":[35,0,23,0]}
{"wire":[35,1,34,0]}
{"wire":[5,0,4,0]}
{"wire":[5,1,2,0]}
{"wire":[16,0,14,0]}
{"wire":[16,1,15,0]}
{"wire":[29,0,28,0]}
{"wire":[36,0,35,0]}
{"wire":[17,0,16,0]}
{"wire":[31,0,29,0]}
{"wire":[31,1,30,0]}
{"wire":[38,0,36,0]}
{"wire":[38,1,37,0]}
{"wire":[50,0,5,0]}
{"wire":[19,0,18,0]}
{"wire":[19,1,17,0]}
{"wire":[33,0,31,0]}
{"wire":[33,1,32,0]}
{"wire":[40,0,38,0]}
{"wire":[40,1,39,0]}
{"wire":[20,0,51,0]}
{"wire":[20,1,19,0]}
{"wire":[41,0,33,0]}
{"wire":[41,1,40,0]}
{"wire":[45,0,41,0]}
{"wire":[45,1,43,0]}
{"wire":[52,0,20,0]}
{"wire":[44,0,53,0]}
{"wire":[44,1,42,0]}
{"wire":[46,0,45,0]}
{"wire":[22,0,21,0]}
{"wire":[47,0,54,0]}
{"wire":[47,1,44,0]}
{"wire":[47,2,46,0]}
{"wire":[0,0,47,0]}
ASEEND*/
//CHKSM=76363691BDB5A50DE9D3E7C598BF5D550ABFD8FD