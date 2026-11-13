// Converter-owned template: straight alpha, hard rectangular clipping, global UI variants.
Shader /*ase_name*/"Hidden/ASE Converter/UI Straight Alpha"/*end*/
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
        /*ase_props*/
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
        /*ase_pass*/
        Pass
        {
            Name "UI"
            CGPROGRAM
            #pragma target 3.5
            #pragma vertex UiVertex
            #pragma fragment UiFragment
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            /*ase_pragma*/
            struct UiInput
            {
                float4 position : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                /*ase_vdata:p=p;c=c;uv0=tc0.xy*/
            };
            struct UiVaryings
            {
                float4 position : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float4 localPosition : TEXCOORD1;
                /*ase_interp(2,):sp=sp.xyzw;c=c;uv0=tc0.xy*/
            };
            fixed4 _Color;
            float4 _ClipRect;
            /*ase_globals*/
            UiVaryings UiVertex(UiInput v /*ase_vert_input*/)
            {
                UiVaryings o;
                /*ase_vert_code:v=UiInput;o=UiVaryings*/
                v.position.xyz += /*ase_vert_out:Offset;Float3*/float3(0,0,0)/*end*/;
                o.position = UnityObjectToClipPos(v.position);
                o.localPosition = v.position;
                o.uv = v.uv;
                o.color = v.color * _Color;
                return o;
            }
            fixed4 UiFragment(UiVaryings i /*ase_frag_input*/) : SV_Target
            {
                /*ase_frag_code:i=UiVaryings*/
                fixed4 color = /*ase_frag_out:Color;Float4*/float4(1,1,1,1)/*end*/;
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
}
