Shader "ConverterSamples/LoopSource"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "gray" {}
        _Tint ("Tint", Color) = (1, 0.5, 0.25, 0.8)
        _Strength ("Strength", Range(0, 2)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _Tint;
            float _Strength;
            struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            float4 frag(v2f i) : SV_Target
            {
                float4 sampled = tex2D(_MainTex, i.uv);
                float4 result = (sampled * _Tint); int count = (int)clamp(_Strength,0.0,8.0); for (int k=0;k<count;k++) { result=sin(result+0.1); } return result;
            }
            ENDCG
        }
    }
}
