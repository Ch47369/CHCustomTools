// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned UI template: target 2.0, straight alpha, hard clipping and global UI variants.
// _MainTex is supplied by the native texture property node, including PerRendererData.
Shader "UI/NormalImagePanZoom_ASE"
{
    Properties
    {
        _Color("Tint", Color) = (1,1,1,1)
        [HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
        [PerRendererData] _MainTex( "Sprite Texture", 2D ) = "white" {}
        [HideInInspector] _ViewRect( "View Rect", Vector ) = ( 0, 0, 1, 1 )
        [HideInInspector] _FlipHorizontally( "Flip Horizontally", Float ) = 0

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

            #pragma target 2.0
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
            UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
            uniform float4 _ViewRect;
            uniform float _FlipHorizontally;
            SamplerState sampler_MainTex;

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
                float4 ase__ViewRect_3636 = _ViewRect;
                float ase__FlipHorizontally_3232 = _FlipHorizontally;
                float2 texCoord4 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                float temp_output_9_0 = (texCoord4).x;
                float ifLocalVar10 = 0;
                if( ase__FlipHorizontally_3232 <= 0.5 )
                {
                	ifLocalVar10 = temp_output_9_0;
                }
                else
                {
                	ifLocalVar10 = ( 1.0 - (texCoord4).x );
                }
                float ase_n10_3434 = (texCoord4).y;
                float2 appendResult12 = (float2(ifLocalVar10 , ase_n10_3434));
                float2 temp_output_16_0 = ( (ase__ViewRect_3636).xy + ( appendResult12 * (ase__ViewRect_3636).zw ) );
                float4 tex2DNode17 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, temp_output_16_0 );
                float ase_n28_4040 = (tex2DNode17).g;
                float4 ase_color_3838 = tex2DNode17;
                float ase_n29_4242 = (ase_color_3838).b;
                float2 temp_cast_0 = (0.0).xx;
                float2 temp_cast_1 = (1.0).xx;
                float2 temp_output_22_0 = ( step( temp_cast_0 , temp_output_16_0 ) * step( temp_output_16_0 , temp_cast_1 ) );
                float4 appendResult31 = (float4((tex2DNode17).r , ase_n28_4040 , ase_n29_4242 , ( ( (tex2DNode17).a * (temp_output_22_0).x ) * (temp_output_22_0).y )));
                
                fixed4 color = appendResult31;
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
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":45,"pos":[0,15],"params":["Inherit","False","800","815","这些属性提供纹理、颜色和参数；属性名与原 Shader 一致。","4","2","3","32","36","材质输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":46,"pos":[0,990],"params":["Inherit","False","640","450","按连线计算并传递结果。表达式：input.uv","1","4","计算 viewUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":3,"pos":[50,480],"params":["Inherit","False","Property","_FlipHorizontally","Flip Horizontally","2","1","[HideInInspector]","Create","False","0","0","0","True","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":4,"pos":[50,1090],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":47,"pos":[1020,15],"params":["Inherit","False","1600","2275","比较输入并选择分支，更新局部变量；保留相等时的分支结果。","11","5","6","7","8","9","10","11","12","33","34","35","条件选择","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":6,"pos":[1070,480],"params":["Inherit","False","Constant","_Float1","Float 1","3","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":7,"pos":[1070,845],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":11,"pos":[1070,1575],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":32,"pos":[450,115],"params":["Inherit","False","ase__FlipHorizontally_32","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":2,"pos":[50,115],"params":["Inherit","False","Property","_ViewRect","View Rect","1","1","[HideInInspector]","Create","False","0","0","0","True","0","False","Object","-1","","0,0,1,1","0,0,1,1","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":5,"pos":[1070,115],"params":["Inherit","False","Constant","_Float0","Float 0","3","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":8,"pos":[1470,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":9,"pos":[1070,1210],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":33,"pos":[1070,1940],"params":["Inherit","False","32","ase__FlipHorizontally_32","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":34,"pos":[1470,480],"params":["Inherit","False","ase_n10_34","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":49,"pos":[4660,625],"params":["Inherit","False","1200","815","用阈值产生 0/1 选择信号。表达式：step(0.0, sampleUV) * step(sampleUV, 1.0)","5","18","19","20","21","22","计算 inside","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":10,"pos":[1870,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","4","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":18,"pos":[4710,725],"params":["Inherit","False","Constant","_Float2","Float 2","4","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":20,"pos":[4710,1090],"params":["Inherit","False","Constant","_Float3","Float 3","4","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":35,"pos":[1870,480],"params":["Inherit","False","34","ase_n10_34","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":36,"pos":[450,480],"params":["Inherit","False","ase__ViewRect_36","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":44,"pos":[4660,15],"params":["Inherit","False","1200","450","按 UV 采样纹理。表达式：tex2D(_MainTex, sampleUV)","3","1","17","38","计算 color","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":48,"pos":[2840,15],"params":["Inherit","False","1600","815","按连线计算并传递结果。表达式：_ViewRect.xy + viewUV * _ViewRect.zw","5","13","14","15","16","37","计算 sampleUV","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":12,"pos":[2270,115],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":14,"pos":[3290,480],"params":["Inherit","False","FLOAT2","2","3","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":19,"pos":[5110,725],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":21,"pos":[5110,1090],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":37,"pos":[2890,115],"params":["Inherit","False","36","ase__ViewRect_36","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":38,"pos":[5510,115],"params":["Inherit","False","ase_color_38","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":50,"pos":[6080,15],"params":["Inherit","False","2000","2275","采样 _ViewRect 缩放/平移后的纹理；UV 越界时 Alpha 为零。模板继续乘顶点色与 Tint，应用矩形硬裁剪、Alpha Clip、Stencil 和透明混合。","14","23","24","25","26","27","28","29","30","31","39","40","41","42","43","计算 color.a","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":13,"pos":[3290,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":15,"pos":[3690,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":22,"pos":[5510,725],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":39,"pos":[6130,1940],"params":["Inherit","False","38","ase_color_38","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":1,"pos":[4710,115],"params":["Inherit","True","Property","_MainTex","Sprite Texture","0","1","[PerRendererData]","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":16,"pos":[4090,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":23,"pos":[6130,115],"params":["Inherit","False","FLOAT","3","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":24,"pos":[6130,480],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":29,"pos":[6130,1575],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":30,"pos":[6530,480],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":17,"pos":[5110,115],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","3","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":25,"pos":[6530,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":26,"pos":[6130,845],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":40,"pos":[6530,845],"params":["Inherit","False","ase_n28_40","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":42,"pos":[6930,845],"params":["Inherit","False","ase_n29_42","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":27,"pos":[6930,115],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":28,"pos":[6130,1210],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":41,"pos":[6930,480],"params":["Inherit","False","40","ase_n28_40","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":43,"pos":[7330,115],"params":["Inherit","False","42","ase_n29_42","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":31,"pos":[7730,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[8430,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","2","UI/NormalImagePanZoom_ASE","c08fd7d51a79449e86b199a5bb4a5724","True","UI","0","0","UI","2","False","True","2","5","False","","10","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","2","False","","False","True","True","True","True","True","0","True","_ColorMask","False","False","False","False","False","False","False","True","True","0","True","_Stencil","255","True","_StencilReadMask","255","True","_StencilWriteMask","0","True","_StencilComp","0","True","_StencilOp","0","False","","0","False","","0","False","","0","False","","0","False","","0","False","","False","True","2","False","","True","0","True","unity_GUIZTestMode","False","False","True","5","Queue=Transparent=Queue=0","IgnoreProjector=True","RenderType=Transparent=RenderType","PreviewType=Plane","CanUseSpriteAtlas=True","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","0","","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[7,0,4,0]}
{"wire":[11,0,4,0]}
{"wire":[32,0,3,0]}
{"wire":[8,0,6,0]}
{"wire":[8,1,7,0]}
{"wire":[9,0,4,0]}
{"wire":[34,0,11,0]}
{"wire":[10,0,33,0]}
{"wire":[10,1,5,0]}
{"wire":[10,2,8,0]}
{"wire":[10,3,9,0]}
{"wire":[10,4,9,0]}
{"wire":[36,0,2,0]}
{"wire":[12,0,10,0]}
{"wire":[12,1,35,0]}
{"wire":[14,0,37,0]}
{"wire":[19,0,18,0]}
{"wire":[19,1,16,0]}
{"wire":[21,0,16,0]}
{"wire":[21,1,20,0]}
{"wire":[38,0,17,0]}
{"wire":[13,0,37,0]}
{"wire":[15,0,12,0]}
{"wire":[15,1,14,0]}
{"wire":[22,0,19,0]}
{"wire":[22,1,21,0]}
{"wire":[16,0,13,0]}
{"wire":[16,1,15,0]}
{"wire":[23,0,17,0]}
{"wire":[24,0,22,0]}
{"wire":[29,0,17,0]}
{"wire":[30,0,39,0]}
{"wire":[17,0,1,0]}
{"wire":[17,1,16,0]}
{"wire":[25,0,23,0]}
{"wire":[25,1,24,0]}
{"wire":[26,0,22,0]}
{"wire":[40,0,29,0]}
{"wire":[42,0,30,0]}
{"wire":[27,0,25,0]}
{"wire":[27,1,26,0]}
{"wire":[28,0,17,0]}
{"wire":[31,0,28,0]}
{"wire":[31,1,41,0]}
{"wire":[31,2,43,0]}
{"wire":[31,3,27,0]}
{"wire":[0,0,31,0]}
ASEEND*/
//CHKSM=CB8FBB28A3329E8D324197CC27C532FBF4465A4C