// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned template: straight alpha, hard rectangular clipping, global UI variants.
Shader "ASELibrary/HDRP/UI/界面纵向渐变"
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
        _GradientStart( "渐变起点", Range( 0, 1 ) ) = 0.15
        _GradientEnd( "渐变终点", Range( 0, 1 ) ) = 0.85
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
            uniform float4 _EffectTint;
            uniform float _GradientStart;
            uniform float _GradientEnd;
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
                float4 ase_SimpleMultiplyOpNode_2020 = ( SAMPLE_TEXTURE2D( _LibraryTex, sampler_LibraryTex, texCoord1 ) * _BaseColor );
                float2 texCoord6 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float smoothstepResult13 = smoothstep( _GradientStart , _GradientEnd , (texCoord6).y);
                float4 lerpResult19 = lerp( ase_SimpleMultiplyOpNode_2020 , ( ase_SimpleMultiplyOpNode_2020 * _EffectTint ) , saturate( ( smoothstepResult13 * _EffectAmount ) ));
                
                fixed4 color = lerpResult19;
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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":23,"pos":[0,15],"params":["Inherit","False","1360","575","原创材质基础，不是樱花兔或网络素材的等价转换。基色按 sRGB 导入，遮罩按 Linear，法线按 NormalMap；需要按实际模型补齐贴图。","6","1","2","3","4","5","20","01 输入与资源","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":24,"pos":[1580,15],"params":["Inherit","False","2040","1065","原创可编辑扩展：界面纵向渐变。程序图案使用 UV0；贴图型扩展需绑定实际资源。设备建议来自静态复杂度，未做 GPU 实机测速。","16","6","7","8","9","10","11","12","13","14","15","16","17","18","19","21","22","06 界面纵向渐变","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":3,"pos":[50,360],"params":["Inherit","True","Property","_LibraryTex","图像纹理","1","1","[NoScaleOffset]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":6,"pos":[1630,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":2,"pos":[390,115],"params":["Inherit","False","Property","_BaseColor","基色 / Base Color","0","0","Create","False","0","0","0","True","0","False","Object","-1","","0.2,0.45,0.6,1","0.2,0.45,0.6,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":4,"pos":[390,360],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","2","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":8,"pos":[1970,850],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":11,"pos":[1970,115],"params":["Inherit","False","Property","_GradientStart","渐变起点","2","0","Create","False","0","0","0","True","0","False","Object","-1","","0.15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":12,"pos":[1970,360],"params":["Inherit","False","Property","_GradientEnd","渐变终点","3","0","Create","False","0","0","0","True","0","False","Object","-1","","0.85","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":5,"pos":[730,115],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor","id":13,"pos":[2310,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":15,"pos":[2310,115],"params":["Inherit","False","Property","_EffectAmount","扩展影响强度","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.55","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":14,"pos":[2650,115],"params":["Inherit","False","Property","_EffectTint","扩展叠色","4","0","Create","False","0","0","0","True","0","False","Object","-1","","0.4,0.65,0.3,1","0.4,0.65,0.3,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":17,"pos":[2650,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":20,"pos":[1070,115],"params":["Inherit","False","ase_SimpleMultiplyOpNode_20","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":21,"pos":[2650,360],"params":["Inherit","False","20","ase_SimpleMultiplyOpNode_20","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":16,"pos":[2990,360],"params":["Inherit","False","2","2","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":18,"pos":[2990,605],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":22,"pos":[2990,115],"params":["Inherit","False","20","ase_SimpleMultiplyOpNode_20","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":7,"pos":[1970,605],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":9,"pos":[1630,360],"params":["Inherit","False","Constant","_Float0","Float 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":10,"pos":[1630,605],"params":["Inherit","False","Constant","_Float1","Float 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.LerpOp, AmplifyShaderEditor","id":19,"pos":[3330,115],"params":["Inherit","False","3","0","COLOR","0,0,0,0","False","1","COLOR","0,0,0,0","False","2","FLOAT","0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[3970,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","3","ASELibrary/HDRP/UI/界面纵向渐变","eab467e6cd0b4d27ab8e9e434d8c30e3","True","UI","0","0","UI","2","False","True","2","5","False","","10","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","True","True","True","True","True","0","True","_ColorMask","False","False","False","False","False","False","False","True","True","0","True","_Stencil","255","True","_StencilReadMask","255","True","_StencilWriteMask","0","True","_StencilComp","0","True","_StencilOp","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","0","True","unity_GUIZTestMode","False","False","True","5","Queue=Transparent=Queue=0","IgnoreProjector=True","RenderType=Transparent=RenderType","PreviewType=Plane","CanUseSpriteAtlas=True","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","3","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[4,0,3,0]}
{"wire":[4,1,1,0]}
{"wire":[8,0,6,0]}
{"wire":[5,0,4,0]}
{"wire":[5,1,2,0]}
{"wire":[13,0,8,0]}
{"wire":[13,1,11,0]}
{"wire":[13,2,12,0]}
{"wire":[17,0,13,0]}
{"wire":[17,1,15,0]}
{"wire":[20,0,5,0]}
{"wire":[16,0,21,0]}
{"wire":[16,1,14,0]}
{"wire":[18,0,17,0]}
{"wire":[7,0,6,0]}
{"wire":[19,0,22,0]}
{"wire":[19,1,16,0]}
{"wire":[19,2,18,0]}
{"wire":[0,0,19,0]}
ASEEND*/
//CHKSM=24075FE656A0F4824566D853A08FC82CF10F556E