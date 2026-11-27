Shader "CH/Paths/Electronic Fence"
{
    Properties
    {
        [HDR] _FenceColor ("Fence color", Color) = (0.06, 1.25, 1.7, 1)
        _Opacity ("Wall opacity", Range(0, 1)) = 0.23
        _EdgeWidth ("Edge width", Range(0.002, 0.15)) = 0.032
        _GridDensity ("Grid density", Vector) = (4, 8, 0, 0)
        _ScanSpeed ("Scan speed", Range(-4, 4)) = 0.7
        _ScanIntensity ("Scan intensity", Range(0, 2)) = 0.75
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    struct Attributes
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float2 progress : TEXCOORD1;
    };
    struct Varyings
    {
        float4 position : SV_POSITION;
        float2 uv : TEXCOORD0;
        float2 progress : TEXCOORD1;
    };
    half4 _FenceColor;
    half _Opacity, _EdgeWidth, _ScanSpeed, _ScanIntensity;
    float4 _GridDensity;

    Varyings Vert(Attributes input)
    {
        Varyings output;
        output.position = UnityObjectToClipPos(input.vertex);
        output.uv = input.uv;
        output.progress = input.progress;
        return output;
    }

    half4 Frag(Varyings input) : SV_Target
    {
        float height = saturate(input.progress.y);
        float edge = 1 - smoothstep(_EdgeWidth, _EdgeWidth * 2, min(height, 1 - height));
        float2 gridUV = input.uv * _GridDensity.xy;
        float2 cell = abs(frac(gridUV + 0.5) - 0.5);
        float2 gridAA = clamp(fwidth(gridUV), 0.006, 0.25);
        float2 gridLines = 1 - smoothstep(float2(0.015, 0.015), 0.015 + gridAA, cell);
        float grid = max(gridLines.x, gridLines.y);
        float sweep = abs(frac(height * 0.7 - _Time.y * _ScanSpeed + 0.5) - 0.5);
        float band = (1 - smoothstep(0.018, 0.12, sweep)) * _ScanIntensity;
        float opacity = saturate(_Opacity * (0.85 - 0.45 * height) + grid * 0.18 + edge * 0.68 + band * 0.2);
        half3 color = _FenceColor.rgb * (0.68 + band * 0.7 + grid * 0.28 + edge * 0.85);
        return half4(color, opacity * _FenceColor.a);
    }
    ENDCG

    SubShader
    {
        Tags { "RenderPipeline"="HDRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Tags { "LightMode"="ForwardOnly" }
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            ENDCG
        }
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            ENDCG
        }
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            ENDCG
        }
    }
}
