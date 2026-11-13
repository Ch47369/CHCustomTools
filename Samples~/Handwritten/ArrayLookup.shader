Shader "Handwritten/ArrayLookup"
{
    Properties
    {
        _Layers ("Layers", 2DArray) = "" {}
        [NoScaleOffset] _Lookup ("Lookup", 2D) = "black" {}
        [Toggle] _Flip ("Flip", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Cull Front
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "UnityCG.cginc"
            UNITY_DECLARE_TEX2DARRAY(_Layers);
            sampler2D _Lookup;
            float _Flip;
            struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { float4 position : SV_POSITION; float2 uv : TEXCOORD0; };
            v2f vert(appdata v) { v2f o; o.position = UnityObjectToClipPos(v.vertex); o.uv = v.uv; return o; }
            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                if (_Flip > 0.5) { uv.x = frac(1.0 - uv.x); } else { uv.x = frac(uv.x); }
                float4 lookup = tex2Dlod(_Lookup, float4(uv, 0, 0));
                return UNITY_SAMPLE_TEX2DARRAY_LOD(_Layers, float3(uv, round(lookup.x)), 0);
            }
            ENDCG
        }
    }
}
