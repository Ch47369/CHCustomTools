// Made with Amplify Shader Editor v1.9.9.13
// Available at the Unity Asset Store - http://u3d.as/y3X 
// Converter-owned mesh host for the reviewed unlit glitter source.
// Vertex tangent-view normalization/interpolation matches the source.
// The node graph contains all material calculations; no lighting/fog/exposure is added.
Shader "ASELibrary/HDRP/Showcase/LayeredParallaxGlitter"
{
    Properties
    {
        _MainTex( "基色贴图", 2D ) = "white" {}
        _NoiseTex( "闪片噪声（线性）", 2D ) = "white" {}
        _MipMap( "闪片色带", 2D ) = "white" {}
        _NormalMap( "原始 RG 法线（线性）", 2D ) = "white" {}
        _MaskAlpha( "轮廓裁剪（线性）", 2D ) = "white" {}
        _BaseColor( "基色叠色", Color ) = ( 0.5, 0.5, 0.5, 1 )
        [HDR] _SparkleColor( "闪片颜色（HDR）", Color ) = ( 1, 1, 1, 1 )
        _ShiningSpeed( "第一层流速", Float ) = 0.1
        _ShiningSpeed_02( "第二层流速", Float ) = 0.1
        _ShiningSpeed_03( "第三层流速", Float ) = 0.1
        _DepthStep( "第一层视差深度", Range( 0, 300 ) ) = 20
        _DepthStep_02( "第二层视差深度", Range( 0, 300 ) ) = 20
        _DepthStep_03( "第三层视差深度", Range( 0, 300 ) ) = 20
        _Iteration( "每层迭代（向上取整）", Range( 1, 15 ) ) = 3
        _DieValue01( "速度衰减", Range( 0.01, 1 ) ) = 0.5
        _DieValue02( "亮度衰减", Range( 0, 5 ) ) = 3
        _OffsetSecond( "第二层偏移", Vector ) = ( 0.5, 0.5, 0, 0 )
        _OffsetThird( "第三层偏移", Vector ) = ( 0.5, 0.5, 0, 0 )
        _NormalScale( "原始 RG 法线强度", Range( 0, 3 ) ) = 1
        _ParallaxMap( "源未使用：视差贴图", 2D ) = "white" {}
        _ColorGradient( "源未使用：颜色梯度", 2D ) = "white" {}
        _Color_pow( "源未使用：颜色指数", Range( 0, 10 ) ) = 1
        _SparklePower( "源未使用：闪片指数", Float ) = 10
        _SpecularColor( "源未使用：高光色", Color ) = ( 1, 1, 1, 1 )
        _SpecularPow( "源未使用：高光指数", Range( 1, 150 ) ) = 1
        _RimColor( "源未使用：边缘色", Color ) = ( 0.17, 0.36, 0.81, 0 )
        _RimPower( "源未使用：边缘指数", Range( 0.6, 36 ) ) = 8
        _RimIntensity( "源未使用：边缘强度", Range( 0, 100 ) ) = 1

    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderPipeline"="HDRenderPipeline" }
        Cull Back
        ZWrite On
        ZTest LEqual
        Blend Off
        
        LOD 100
        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="SRPDefaultUnlit" }
            CGPROGRAM
            #define ASE_VERSION 19913
            #define ASE_SRP_VERSION 140008
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma target 4.5
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #include "UnityCG.cginc"
            #if defined(SHADER_API_GLES)
                #define TEXTURE2D(name) sampler2D name
                #define SAMPLER(name)
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)
                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex2Dlod(tex, float4(uv, 0, lod))
            #else
                #define TEXTURE2D(name) Texture2D name
                #define SAMPLER(name) SamplerState name
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)
                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex.SampleLevel(state, uv, lod)
            #endif
            // ASE SRP Time nodes use seconds from _TimeParameters.x. Preserve
            // the source's engine time even for explicit Blit without a camera.
            #define _TimeParameters float4(_Time.y, sin(_Time.y), cos(_Time.y), 0.0)
            #define ASE_NEEDS_TEXTURE_COORDINATES0
            #define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0

            struct FilterInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                
            };
            struct FilterVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangentView : TEXCOORD1;
                
            };
            TEXTURE2D(_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);
            TEXTURE2D(_ColorGradient);
            SAMPLER(sampler_ColorGradient);
            TEXTURE2D(_MaskAlpha);
            SAMPLER(sampler_MaskAlpha);
            TEXTURE2D(_MipMap);
            TEXTURE2D(_NoiseTex);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            SAMPLER(sampler_NoiseTex);
            SAMPLER(sampler_MipMap);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            CBUFFER_START( UnityPerMaterial )
            float4 _NoiseTex_ST;
            float4 _OffsetThird;
            float4 _OffsetSecond;
            float4 _NormalMap_ST;
            float4 _MainTex_ST;
            float4 _MipMap_ST;
            float4 _SparkleColor;
            float4 _BaseColor;
            float4 _RimColor;
            float4 _SpecularColor;
            float _RimIntensity;
            float _DepthStep_03;
            float _ShiningSpeed_03;
            float _SparklePower;
            float _DepthStep_02;
            float _ShiningSpeed_02;
            float _DepthStep;
            float _DieValue01;
            float _NormalScale;
            float _SpecularPow;
            float _ShiningSpeed;
            float _DieValue02;
            float _RimPower;
            float _Iteration;
            float _Color_pow;
            CBUFFER_END

            FilterVaryings FilterVertex(FilterInput v )
            {
                FilterVaryings o;
                
                v.position.xyz += float3(0,0,0);
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                float3 binormal = cross(v.normal,v.tangent.xyz)*v.tangent.w;
                float3 objectView = ObjSpaceViewDir(v.position);
                o.tangentView = normalize(mul(float3x3(v.tangent.xyz,binormal,v.normal),objectView));
                return o;
            }
            float4 FilterFragment(FilterVaryings i ) : SV_Target
            {
                float3 ase_tangentView = i.tangentView;
                float2 texCoord3 = i.uv.xy * float2( 1,1 ) + float2( 0,0 );
                
                float ase____________17201720 = _Iteration;
                float ase_n2_16811681 = 1.0;
                float3 ase_SwizzleNode_17181718 = (float4( 0, 0, 0, 0 )).xyz;
                float ase_n1_16861686 = 0.0;
                float3 ase_SwizzleNode_17161716 = (_SparkleColor).rgb;
                float2 uv_MipMap = i.uv.xy * _MipMap_ST.xy + _MipMap_ST.zw;
                float2 ase_TextureCoordinatesNode_16991699 = uv_MipMap;
                float temp_output_54_0 = ( _TimeParameters.x / 20.0 );
                float ase_SimpleDivideOpNode_16941694 = temp_output_54_0;
                float ase_n71_16961696 = 1.0;
                float2 appendResult75 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n71_16961696 )));
                float2 temp_output_76_0 = ( ase_TextureCoordinatesNode_16991699 + appendResult75 );
                float ase______17131713 = _DieValue02;
                float4 ase_n21_16751675 = float4( 0, 0, 0, 0 );
                float2 ase_SwizzleNode_17061706 = (ase_n21_16751675).xy;
                float ase_______16841684 = _ShiningSpeed;
                float2 appendResult56 = (float2(ase_n1_16861686 , ( temp_output_54_0 * ase_______16841684 )));
                float2 ase_DynamicAppendNode_17101710 = appendResult56;
                float2 uv_NoiseTex = i.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                float2 ase_TextureCoordinatesNode_17041704 = uv_NoiseTex;
                float3 normalizeResult28 = normalize( ase_tangentView );
                float2 uv_NormalMap = i.uv.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
                float4 tex2DNode30 = SAMPLE_TEXTURE2D( _NormalMap, sampler_NormalMap, uv_NormalMap );
                float2 temp_output_36_0 = ( ( ( (tex2DNode30).rg * 2.0 ) - ase_n2_16811681 ) * _NormalScale );
                float dotResult37 = dot( temp_output_36_0 , temp_output_36_0 );
                float3 appendResult43 = (float3((temp_output_36_0).x , (temp_output_36_0).y , sqrt( ( ase_n2_16811681 - saturate( dotResult37 ) ) )));
                float3 temp_output_45_0 = reflect( -normalizeResult28 , appendResult43 );
                float2 temp_output_51_0 = ( (temp_output_45_0).xy / ( abs( (temp_output_45_0).z ) * 612.0 ) );
                float ase______17081708 = _DieValue01;
                float ase_________17021702 = _DepthStep;
                float3 ifLocalVar103 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 1.0 )
                {
                	ifLocalVar103 = ase_SwizzleNode_17181718;
                }
                else
                {
                	float4 tex2DNode87 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( temp_output_51_0 * ( ase_________17021702 * 1.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 1.0 , ase______17081708 ) ) ) );
                	float clampResult98 = clamp( ( pow( ase_n71_16961696 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar103 = max( ase_SwizzleNode_17181718, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode87).r , 6.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_76_0, ase_n1_16861686 )).rgb ) * clampResult98 ) );
                }
                float ase_n106_17241724 = 0.5;
                float2 appendResult110 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n106_17241724 )));
                float2 temp_output_111_0 = ( temp_output_76_0 + appendResult110 );
                float2 ase_SimpleDivideOpNode_17291729 = temp_output_51_0;
                float3 ifLocalVar138 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 2.0 )
                {
                	ifLocalVar138 = ifLocalVar103;
                }
                else
                {
                	float4 tex2DNode122 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 2.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.5 , ase______17081708 ) ) ) );
                	float clampResult133 = clamp( ( pow( ase_n106_17241724 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar138 = max( ifLocalVar103, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode122).r , 5.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_111_0, ase_n1_16861686 )).rgb ) * clampResult133 ) );
                }
                float ase_n141_17421742 = 0.3333333;
                float2 appendResult145 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n141_17421742 )));
                float2 temp_output_146_0 = ( temp_output_111_0 + appendResult145 );
                float3 ifLocalVar173 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 3.0 )
                {
                	ifLocalVar173 = ifLocalVar138;
                }
                else
                {
                	float4 tex2DNode157 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 3.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.3333333 , ase______17081708 ) ) ) );
                	float clampResult168 = clamp( ( pow( ase_n141_17421742 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar173 = max( ifLocalVar138, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode157).r , 4.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_146_0, ase_n1_16861686 )).rgb ) * clampResult168 ) );
                }
                float ase_n176_17591759 = 0.25;
                float2 appendResult180 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n176_17591759 )));
                float2 temp_output_181_0 = ( temp_output_146_0 + appendResult180 );
                float3 ifLocalVar208 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 4.0 )
                {
                	ifLocalVar208 = ifLocalVar173;
                }
                else
                {
                	float4 tex2DNode192 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 4.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.25 , ase______17081708 ) ) ) );
                	float clampResult203 = clamp( ( pow( ase_n176_17591759 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar208 = max( ifLocalVar173, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode192).r , 3.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_181_0, ase_n1_16861686 )).rgb ) * clampResult203 ) );
                }
                float ase_n211_17761776 = 0.2;
                float2 appendResult215 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n211_17761776 )));
                float2 temp_output_216_0 = ( temp_output_181_0 + appendResult215 );
                float3 ifLocalVar243 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 5.0 )
                {
                	ifLocalVar243 = ifLocalVar208;
                }
                else
                {
                	float4 tex2DNode227 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 5.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.2 , ase______17081708 ) ) ) );
                	float clampResult238 = clamp( ( pow( ase_n211_17761776 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar243 = max( ifLocalVar208, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode227).r , 2.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_216_0, ase_n1_16861686 )).rgb ) * clampResult238 ) );
                }
                float2 ase_SimpleAddOpNode_17961796 = temp_output_216_0;
                float ase_n246_17931793 = 0.1666667;
                float2 appendResult250 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n246_17931793 )));
                float2 temp_output_251_0 = ( ase_SimpleAddOpNode_17961796 + appendResult250 );
                float3 ifLocalVar278 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 6.0 )
                {
                	ifLocalVar278 = ifLocalVar243;
                }
                else
                {
                	float4 tex2DNode262 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 6.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.1666667 , ase______17081708 ) ) ) );
                	float clampResult273 = clamp( ( pow( ase_n246_17931793 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar278 = max( ifLocalVar243, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode262).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_251_0, ase_n1_16861686 )).rgb ) * clampResult273 ) );
                }
                float ase_n281_18121812 = 0.1428571;
                float2 appendResult285 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n281_18121812 )));
                float2 temp_output_286_0 = ( temp_output_251_0 + appendResult285 );
                float3 ifLocalVar313 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 7.0 )
                {
                	ifLocalVar313 = ifLocalVar278;
                }
                else
                {
                	float4 tex2DNode297 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 7.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.1428571 , ase______17081708 ) ) ) );
                	float clampResult308 = clamp( ( pow( ase_n281_18121812 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar313 = max( ifLocalVar278, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode297).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_286_0, ase_n1_16861686 )).rgb ) * clampResult308 ) );
                }
                float ase_n316_18291829 = 0.125;
                float2 appendResult320 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n316_18291829 )));
                float2 temp_output_321_0 = ( temp_output_286_0 + appendResult320 );
                float3 ifLocalVar348 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 8.0 )
                {
                	ifLocalVar348 = ifLocalVar313;
                }
                else
                {
                	float4 tex2DNode332 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 8.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.125 , ase______17081708 ) ) ) );
                	float clampResult343 = clamp( ( pow( ase_n316_18291829 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar348 = max( ifLocalVar313, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode332).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_321_0, ase_n1_16861686 )).rgb ) * clampResult343 ) );
                }
                float ase_n351_18461846 = 0.1111111;
                float2 appendResult355 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n351_18461846 )));
                float2 temp_output_356_0 = ( temp_output_321_0 + appendResult355 );
                float3 ifLocalVar383 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 9.0 )
                {
                	ifLocalVar383 = ifLocalVar348;
                }
                else
                {
                	float4 tex2DNode367 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 9.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.1111111 , ase______17081708 ) ) ) );
                	float clampResult378 = clamp( ( pow( ase_n351_18461846 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar383 = max( ifLocalVar348, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode367).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_356_0, ase_n1_16861686 )).rgb ) * clampResult378 ) );
                }
                float ase_n386_18631863 = 0.1;
                float2 appendResult390 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n386_18631863 )));
                float2 temp_output_391_0 = ( temp_output_356_0 + appendResult390 );
                float3 ifLocalVar418 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 10.0 )
                {
                	ifLocalVar418 = ifLocalVar383;
                }
                else
                {
                	float4 tex2DNode402 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 10.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.1 , ase______17081708 ) ) ) );
                	float clampResult413 = clamp( ( pow( ase_n386_18631863 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar418 = max( ifLocalVar383, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode402).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_391_0, ase_n1_16861686 )).rgb ) * clampResult413 ) );
                }
                float2 ase_SimpleAddOpNode_18831883 = temp_output_391_0;
                float ase_n421_18801880 = 0.09090909;
                float2 appendResult425 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n421_18801880 )));
                float2 temp_output_426_0 = ( ase_SimpleAddOpNode_18831883 + appendResult425 );
                float3 ifLocalVar453 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 11.0 )
                {
                	ifLocalVar453 = ifLocalVar418;
                }
                else
                {
                	float4 tex2DNode437 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 11.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.09090909 , ase______17081708 ) ) ) );
                	float clampResult448 = clamp( ( pow( ase_n421_18801880 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar453 = max( ifLocalVar418, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode437).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_426_0, ase_n1_16861686 )).rgb ) * clampResult448 ) );
                }
                float ase_n456_18991899 = 0.08333334;
                float2 appendResult460 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n456_18991899 )));
                float2 temp_output_461_0 = ( temp_output_426_0 + appendResult460 );
                float3 ifLocalVar488 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 12.0 )
                {
                	ifLocalVar488 = ifLocalVar453;
                }
                else
                {
                	float4 tex2DNode472 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 12.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.08333334 , ase______17081708 ) ) ) );
                	float clampResult483 = clamp( ( pow( ase_n456_18991899 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar488 = max( ifLocalVar453, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode472).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_461_0, ase_n1_16861686 )).rgb ) * clampResult483 ) );
                }
                float ase_n491_19161916 = 0.07692308;
                float2 appendResult495 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n491_19161916 )));
                float2 temp_output_496_0 = ( temp_output_461_0 + appendResult495 );
                float3 ifLocalVar523 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 13.0 )
                {
                	ifLocalVar523 = ifLocalVar488;
                }
                else
                {
                	float4 tex2DNode507 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 13.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.07692308 , ase______17081708 ) ) ) );
                	float clampResult518 = clamp( ( pow( ase_n491_19161916 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar523 = max( ifLocalVar488, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode507).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_496_0, ase_n1_16861686 )).rgb ) * clampResult518 ) );
                }
                float ase_n526_19331933 = 0.07142857;
                float2 appendResult530 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n526_19331933 )));
                float2 temp_output_531_0 = ( temp_output_496_0 + appendResult530 );
                float3 ifLocalVar558 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 14.0 )
                {
                	ifLocalVar558 = ifLocalVar523;
                }
                else
                {
                	float4 tex2DNode542 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 14.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.07142857 , ase______17081708 ) ) ) );
                	float clampResult553 = clamp( ( pow( ase_n526_19331933 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar558 = max( ifLocalVar523, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode542).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_531_0, ase_n1_16861686 )).rgb ) * clampResult553 ) );
                }
                float3 ifLocalVar593 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 15.0 )
                {
                	ifLocalVar593 = ifLocalVar558;
                }
                else
                {
                	float ase_n561_19501950 = 0.06666667;
                	float2 appendResult565 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n561_19501950 )));
                	float clampResult588 = clamp( ( pow( ase_n561_19501950 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar593 = max( ifLocalVar558, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________17021702 * 15.0 ) ) ) + ase_SwizzleNode_17061706 ) + ( ase_DynamicAppendNode_17101710 * pow( 0.06666667 , ase______17081708 ) ) ) )).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, ( temp_output_531_0 + appendResult565 ), ase_n1_16861686 )).rgb ) * clampResult588 ) );
                }
                float3 ase_SwizzleNode_19851985 = (float4( 0, 0, 0, 0 )).xyz;
                float ase_n598_19671967 = 1.0;
                float2 appendResult602 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n598_19671967 )));
                float2 temp_output_603_0 = ( ase_TextureCoordinatesNode_16991699 + appendResult602 );
                float4 ase_______16771677 = _OffsetSecond;
                float2 ase_SwizzleNode_19761976 = (ase_______16771677).xy;
                float ase_______16891689 = _ShiningSpeed_02;
                float2 appendResult61 = (float2(( ( temp_output_54_0 * ase_______16841684 ) * 0.1 ) , ( temp_output_54_0 * ase_______16891689 )));
                float2 ase_DynamicAppendNode_19791979 = appendResult61;
                float ase_________19721972 = _DepthStep_02;
                float3 ifLocalVar630 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 1.0 )
                {
                	ifLocalVar630 = ase_SwizzleNode_19851985;
                }
                else
                {
                	float4 tex2DNode614 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 1.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 1.0 , ase______17081708 ) ) ) );
                	float clampResult625 = clamp( ( pow( ase_n598_19671967 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar630 = max( ase_SwizzleNode_19851985, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode614).r , 6.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_603_0, ase_n1_16861686 )).rgb ) * clampResult625 ) );
                }
                float ase_n633_19901990 = 0.5;
                float2 appendResult637 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n633_19901990 )));
                float2 temp_output_638_0 = ( temp_output_603_0 + appendResult637 );
                float3 ifLocalVar665 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 2.0 )
                {
                	ifLocalVar665 = ifLocalVar630;
                }
                else
                {
                	float4 tex2DNode649 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 2.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.5 , ase______17081708 ) ) ) );
                	float clampResult660 = clamp( ( pow( ase_n633_19901990 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar665 = max( ifLocalVar630, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode649).r , 5.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_638_0, ase_n1_16861686 )).rgb ) * clampResult660 ) );
                }
                float ase_n668_20072007 = 0.3333333;
                float2 appendResult672 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n668_20072007 )));
                float2 temp_output_673_0 = ( temp_output_638_0 + appendResult672 );
                float3 ifLocalVar700 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 3.0 )
                {
                	ifLocalVar700 = ifLocalVar665;
                }
                else
                {
                	float4 tex2DNode684 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 3.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.3333333 , ase______17081708 ) ) ) );
                	float clampResult695 = clamp( ( pow( ase_n668_20072007 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar700 = max( ifLocalVar665, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode684).r , 4.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_673_0, ase_n1_16861686 )).rgb ) * clampResult695 ) );
                }
                float ase_n703_20242024 = 0.25;
                float2 appendResult707 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n703_20242024 )));
                float2 temp_output_708_0 = ( temp_output_673_0 + appendResult707 );
                float3 ifLocalVar735 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 4.0 )
                {
                	ifLocalVar735 = ifLocalVar700;
                }
                else
                {
                	float4 tex2DNode719 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 4.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.25 , ase______17081708 ) ) ) );
                	float clampResult730 = clamp( ( pow( ase_n703_20242024 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar735 = max( ifLocalVar700, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode719).r , 3.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_708_0, ase_n1_16861686 )).rgb ) * clampResult730 ) );
                }
                float ase_n738_20412041 = 0.2;
                float2 appendResult742 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n738_20412041 )));
                float2 temp_output_743_0 = ( temp_output_708_0 + appendResult742 );
                float3 ifLocalVar770 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 5.0 )
                {
                	ifLocalVar770 = ifLocalVar735;
                }
                else
                {
                	float4 tex2DNode754 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 5.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.2 , ase______17081708 ) ) ) );
                	float clampResult765 = clamp( ( pow( ase_n738_20412041 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar770 = max( ifLocalVar735, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode754).r , 2.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_743_0, ase_n1_16861686 )).rgb ) * clampResult765 ) );
                }
                float2 ase_SimpleAddOpNode_20612061 = temp_output_743_0;
                float ase_n773_20582058 = 0.1666667;
                float2 appendResult777 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n773_20582058 )));
                float2 temp_output_778_0 = ( ase_SimpleAddOpNode_20612061 + appendResult777 );
                float3 ifLocalVar805 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 6.0 )
                {
                	ifLocalVar805 = ifLocalVar770;
                }
                else
                {
                	float4 tex2DNode789 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 6.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.1666667 , ase______17081708 ) ) ) );
                	float clampResult800 = clamp( ( pow( ase_n773_20582058 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar805 = max( ifLocalVar770, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode789).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_778_0, ase_n1_16861686 )).rgb ) * clampResult800 ) );
                }
                float ase_n808_20772077 = 0.1428571;
                float2 appendResult812 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n808_20772077 )));
                float2 temp_output_813_0 = ( temp_output_778_0 + appendResult812 );
                float3 ifLocalVar840 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 7.0 )
                {
                	ifLocalVar840 = ifLocalVar805;
                }
                else
                {
                	float4 tex2DNode824 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 7.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.1428571 , ase______17081708 ) ) ) );
                	float clampResult835 = clamp( ( pow( ase_n808_20772077 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar840 = max( ifLocalVar805, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode824).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_813_0, ase_n1_16861686 )).rgb ) * clampResult835 ) );
                }
                float ase_n843_20942094 = 0.125;
                float2 appendResult847 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n843_20942094 )));
                float2 temp_output_848_0 = ( temp_output_813_0 + appendResult847 );
                float3 ifLocalVar875 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 8.0 )
                {
                	ifLocalVar875 = ifLocalVar840;
                }
                else
                {
                	float4 tex2DNode859 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 8.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.125 , ase______17081708 ) ) ) );
                	float clampResult870 = clamp( ( pow( ase_n843_20942094 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar875 = max( ifLocalVar840, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode859).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_848_0, ase_n1_16861686 )).rgb ) * clampResult870 ) );
                }
                float ase_n878_21112111 = 0.1111111;
                float2 appendResult882 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n878_21112111 )));
                float2 temp_output_883_0 = ( temp_output_848_0 + appendResult882 );
                float3 ifLocalVar910 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 9.0 )
                {
                	ifLocalVar910 = ifLocalVar875;
                }
                else
                {
                	float4 tex2DNode894 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 9.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.1111111 , ase______17081708 ) ) ) );
                	float clampResult905 = clamp( ( pow( ase_n878_21112111 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar910 = max( ifLocalVar875, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode894).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_883_0, ase_n1_16861686 )).rgb ) * clampResult905 ) );
                }
                float ase_n913_21282128 = 0.1;
                float2 appendResult917 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n913_21282128 )));
                float2 temp_output_918_0 = ( temp_output_883_0 + appendResult917 );
                float3 ifLocalVar945 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 10.0 )
                {
                	ifLocalVar945 = ifLocalVar910;
                }
                else
                {
                	float4 tex2DNode929 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 10.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.1 , ase______17081708 ) ) ) );
                	float clampResult940 = clamp( ( pow( ase_n913_21282128 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar945 = max( ifLocalVar910, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode929).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_918_0, ase_n1_16861686 )).rgb ) * clampResult940 ) );
                }
                float2 ase_SimpleAddOpNode_21482148 = temp_output_918_0;
                float ase_n948_21452145 = 0.09090909;
                float2 appendResult952 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n948_21452145 )));
                float2 temp_output_953_0 = ( ase_SimpleAddOpNode_21482148 + appendResult952 );
                float3 ifLocalVar980 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 11.0 )
                {
                	ifLocalVar980 = ifLocalVar945;
                }
                else
                {
                	float4 tex2DNode964 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 11.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.09090909 , ase______17081708 ) ) ) );
                	float clampResult975 = clamp( ( pow( ase_n948_21452145 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar980 = max( ifLocalVar945, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode964).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_953_0, ase_n1_16861686 )).rgb ) * clampResult975 ) );
                }
                float ase_n983_21642164 = 0.08333334;
                float2 appendResult987 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n983_21642164 )));
                float2 temp_output_988_0 = ( temp_output_953_0 + appendResult987 );
                float3 ifLocalVar1015 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 12.0 )
                {
                	ifLocalVar1015 = ifLocalVar980;
                }
                else
                {
                	float4 tex2DNode999 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 12.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.08333334 , ase______17081708 ) ) ) );
                	float clampResult1010 = clamp( ( pow( ase_n983_21642164 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1015 = max( ifLocalVar980, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode999).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_988_0, ase_n1_16861686 )).rgb ) * clampResult1010 ) );
                }
                float ase_n1018_21812181 = 0.07692308;
                float2 appendResult1022 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1018_21812181 )));
                float2 temp_output_1023_0 = ( temp_output_988_0 + appendResult1022 );
                float3 ifLocalVar1050 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 13.0 )
                {
                	ifLocalVar1050 = ifLocalVar1015;
                }
                else
                {
                	float4 tex2DNode1034 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 13.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.07692308 , ase______17081708 ) ) ) );
                	float clampResult1045 = clamp( ( pow( ase_n1018_21812181 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1050 = max( ifLocalVar1015, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1034).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1023_0, ase_n1_16861686 )).rgb ) * clampResult1045 ) );
                }
                float ase_n1053_21982198 = 0.07142857;
                float2 appendResult1057 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1053_21982198 )));
                float2 temp_output_1058_0 = ( temp_output_1023_0 + appendResult1057 );
                float3 ifLocalVar1085 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 14.0 )
                {
                	ifLocalVar1085 = ifLocalVar1050;
                }
                else
                {
                	float4 tex2DNode1069 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 14.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.07142857 , ase______17081708 ) ) ) );
                	float clampResult1080 = clamp( ( pow( ase_n1053_21982198 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1085 = max( ifLocalVar1050, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1069).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1058_0, ase_n1_16861686 )).rgb ) * clampResult1080 ) );
                }
                float3 ifLocalVar1120 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 15.0 )
                {
                	ifLocalVar1120 = ifLocalVar1085;
                }
                else
                {
                	float ase_n1088_22152215 = 0.06666667;
                	float2 appendResult1092 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1088_22152215 )));
                	float clampResult1115 = clamp( ( pow( ase_n1088_22152215 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1120 = max( ifLocalVar1085, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________19721972 * 15.0 ) ) ) + ase_SwizzleNode_19761976 ) + ( ase_DynamicAppendNode_19791979 * pow( 0.06666667 , ase______17081708 ) ) ) )).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, ( temp_output_1058_0 + appendResult1092 ), ase_n1_16861686 )).rgb ) * clampResult1115 ) );
                }
                float3 temp_output_1651_0 = ( ifLocalVar593 + max( ifLocalVar593, ifLocalVar1120 ) );
                float3 ase_SwizzleNode_22502250 = (float4( 0, 0, 0, 0 )).xyz;
                float ase_n1125_22322232 = 1.0;
                float2 appendResult1129 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1125_22322232 )));
                float2 temp_output_1130_0 = ( ase_TextureCoordinatesNode_16991699 + appendResult1129 );
                float4 ase_______16791679 = _OffsetThird;
                float2 ase_SwizzleNode_22412241 = (ase_______16791679).xy;
                float ase_______16921692 = _ShiningSpeed_03;
                float2 appendResult66 = (float2(( ( temp_output_54_0 * ase_______16841684 ) * -0.1 ) , ( temp_output_54_0 * ase_______16921692 )));
                float2 ase_DynamicAppendNode_22442244 = appendResult66;
                float ase_________22372237 = _DepthStep_03;
                float3 ifLocalVar1157 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 1.0 )
                {
                	ifLocalVar1157 = ase_SwizzleNode_22502250;
                }
                else
                {
                	float4 tex2DNode1141 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 1.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 1.0 , ase______17081708 ) ) ) );
                	float clampResult1152 = clamp( ( pow( ase_n1125_22322232 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1157 = max( ase_SwizzleNode_22502250, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1141).r , 6.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1130_0, ase_n1_16861686 )).rgb ) * clampResult1152 ) );
                }
                float ase_n1160_22552255 = 0.5;
                float2 appendResult1164 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1160_22552255 )));
                float2 temp_output_1165_0 = ( temp_output_1130_0 + appendResult1164 );
                float3 ifLocalVar1192 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 2.0 )
                {
                	ifLocalVar1192 = ifLocalVar1157;
                }
                else
                {
                	float4 tex2DNode1176 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 2.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.5 , ase______17081708 ) ) ) );
                	float clampResult1187 = clamp( ( pow( ase_n1160_22552255 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1192 = max( ifLocalVar1157, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1176).r , 5.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1165_0, ase_n1_16861686 )).rgb ) * clampResult1187 ) );
                }
                float ase_n1195_22722272 = 0.3333333;
                float2 appendResult1199 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1195_22722272 )));
                float2 temp_output_1200_0 = ( temp_output_1165_0 + appendResult1199 );
                float3 ifLocalVar1227 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 3.0 )
                {
                	ifLocalVar1227 = ifLocalVar1192;
                }
                else
                {
                	float4 tex2DNode1211 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 3.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.3333333 , ase______17081708 ) ) ) );
                	float clampResult1222 = clamp( ( pow( ase_n1195_22722272 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1227 = max( ifLocalVar1192, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1211).r , 4.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1200_0, ase_n1_16861686 )).rgb ) * clampResult1222 ) );
                }
                float ase_n1230_22892289 = 0.25;
                float2 appendResult1234 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1230_22892289 )));
                float2 temp_output_1235_0 = ( temp_output_1200_0 + appendResult1234 );
                float3 ifLocalVar1262 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 4.0 )
                {
                	ifLocalVar1262 = ifLocalVar1227;
                }
                else
                {
                	float4 tex2DNode1246 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 4.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.25 , ase______17081708 ) ) ) );
                	float clampResult1257 = clamp( ( pow( ase_n1230_22892289 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1262 = max( ifLocalVar1227, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1246).r , 3.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1235_0, ase_n1_16861686 )).rgb ) * clampResult1257 ) );
                }
                float ase_n1265_23062306 = 0.2;
                float2 appendResult1269 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1265_23062306 )));
                float2 temp_output_1270_0 = ( temp_output_1235_0 + appendResult1269 );
                float3 ifLocalVar1297 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 5.0 )
                {
                	ifLocalVar1297 = ifLocalVar1262;
                }
                else
                {
                	float4 tex2DNode1281 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 5.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.2 , ase______17081708 ) ) ) );
                	float clampResult1292 = clamp( ( pow( ase_n1265_23062306 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1297 = max( ifLocalVar1262, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1281).r , 2.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1270_0, ase_n1_16861686 )).rgb ) * clampResult1292 ) );
                }
                float2 ase_SimpleAddOpNode_23262326 = temp_output_1270_0;
                float ase_n1300_23232323 = 0.1666667;
                float2 appendResult1304 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1300_23232323 )));
                float2 temp_output_1305_0 = ( ase_SimpleAddOpNode_23262326 + appendResult1304 );
                float3 ifLocalVar1332 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 6.0 )
                {
                	ifLocalVar1332 = ifLocalVar1297;
                }
                else
                {
                	float4 tex2DNode1316 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 6.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.1666667 , ase______17081708 ) ) ) );
                	float clampResult1327 = clamp( ( pow( ase_n1300_23232323 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1332 = max( ifLocalVar1297, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1316).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1305_0, ase_n1_16861686 )).rgb ) * clampResult1327 ) );
                }
                float ase_n1335_23422342 = 0.1428571;
                float2 appendResult1339 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1335_23422342 )));
                float2 temp_output_1340_0 = ( temp_output_1305_0 + appendResult1339 );
                float3 ifLocalVar1367 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 7.0 )
                {
                	ifLocalVar1367 = ifLocalVar1332;
                }
                else
                {
                	float4 tex2DNode1351 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 7.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.1428571 , ase______17081708 ) ) ) );
                	float clampResult1362 = clamp( ( pow( ase_n1335_23422342 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1367 = max( ifLocalVar1332, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1351).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1340_0, ase_n1_16861686 )).rgb ) * clampResult1362 ) );
                }
                float ase_n1370_23592359 = 0.125;
                float2 appendResult1374 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1370_23592359 )));
                float2 temp_output_1375_0 = ( temp_output_1340_0 + appendResult1374 );
                float3 ifLocalVar1402 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 8.0 )
                {
                	ifLocalVar1402 = ifLocalVar1367;
                }
                else
                {
                	float4 tex2DNode1386 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 8.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.125 , ase______17081708 ) ) ) );
                	float clampResult1397 = clamp( ( pow( ase_n1370_23592359 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1402 = max( ifLocalVar1367, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1386).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1375_0, ase_n1_16861686 )).rgb ) * clampResult1397 ) );
                }
                float ase_n1405_23762376 = 0.1111111;
                float2 appendResult1409 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1405_23762376 )));
                float2 temp_output_1410_0 = ( temp_output_1375_0 + appendResult1409 );
                float3 ifLocalVar1437 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 9.0 )
                {
                	ifLocalVar1437 = ifLocalVar1402;
                }
                else
                {
                	float4 tex2DNode1421 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 9.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.1111111 , ase______17081708 ) ) ) );
                	float clampResult1432 = clamp( ( pow( ase_n1405_23762376 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1437 = max( ifLocalVar1402, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1421).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1410_0, ase_n1_16861686 )).rgb ) * clampResult1432 ) );
                }
                float ase_n1440_23932393 = 0.1;
                float2 appendResult1444 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1440_23932393 )));
                float2 temp_output_1445_0 = ( temp_output_1410_0 + appendResult1444 );
                float3 ifLocalVar1472 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 10.0 )
                {
                	ifLocalVar1472 = ifLocalVar1437;
                }
                else
                {
                	float4 tex2DNode1456 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 10.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.1 , ase______17081708 ) ) ) );
                	float clampResult1467 = clamp( ( pow( ase_n1440_23932393 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1472 = max( ifLocalVar1437, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1456).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1445_0, ase_n1_16861686 )).rgb ) * clampResult1467 ) );
                }
                float2 ase_SimpleAddOpNode_24132413 = temp_output_1445_0;
                float ase_n1475_24102410 = 0.09090909;
                float2 appendResult1479 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1475_24102410 )));
                float2 temp_output_1480_0 = ( ase_SimpleAddOpNode_24132413 + appendResult1479 );
                float3 ifLocalVar1507 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 11.0 )
                {
                	ifLocalVar1507 = ifLocalVar1472;
                }
                else
                {
                	float4 tex2DNode1491 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 11.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.09090909 , ase______17081708 ) ) ) );
                	float clampResult1502 = clamp( ( pow( ase_n1475_24102410 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1507 = max( ifLocalVar1472, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1491).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1480_0, ase_n1_16861686 )).rgb ) * clampResult1502 ) );
                }
                float ase_n1510_24292429 = 0.08333334;
                float2 appendResult1514 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1510_24292429 )));
                float2 temp_output_1515_0 = ( temp_output_1480_0 + appendResult1514 );
                float3 ifLocalVar1542 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 12.0 )
                {
                	ifLocalVar1542 = ifLocalVar1507;
                }
                else
                {
                	float4 tex2DNode1526 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 12.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.08333334 , ase______17081708 ) ) ) );
                	float clampResult1537 = clamp( ( pow( ase_n1510_24292429 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1542 = max( ifLocalVar1507, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1526).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1515_0, ase_n1_16861686 )).rgb ) * clampResult1537 ) );
                }
                float ase_n1545_24462446 = 0.07692308;
                float2 appendResult1549 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1545_24462446 )));
                float2 temp_output_1550_0 = ( temp_output_1515_0 + appendResult1549 );
                float3 ifLocalVar1577 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 13.0 )
                {
                	ifLocalVar1577 = ifLocalVar1542;
                }
                else
                {
                	float4 tex2DNode1561 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 13.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.07692308 , ase______17081708 ) ) ) );
                	float clampResult1572 = clamp( ( pow( ase_n1545_24462446 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1577 = max( ifLocalVar1542, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1561).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1550_0, ase_n1_16861686 )).rgb ) * clampResult1572 ) );
                }
                float ase_n1580_24632463 = 0.07142857;
                float2 appendResult1584 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1580_24632463 )));
                float2 temp_output_1585_0 = ( temp_output_1550_0 + appendResult1584 );
                float3 ifLocalVar1612 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 14.0 )
                {
                	ifLocalVar1612 = ifLocalVar1577;
                }
                else
                {
                	float4 tex2DNode1596 = SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 14.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.07142857 , ase______17081708 ) ) ) );
                	float clampResult1607 = clamp( ( pow( ase_n1580_24632463 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1612 = max( ifLocalVar1577, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (tex2DNode1596).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, temp_output_1585_0, ase_n1_16861686 )).rgb ) * clampResult1607 ) );
                }
                float3 ifLocalVar1647 = 0;
                if( ( ase____________17201720 + ase_n2_16811681 ) <= 15.0 )
                {
                	ifLocalVar1647 = ifLocalVar1612;
                }
                else
                {
                	float ase_n1615_24802480 = 0.06666667;
                	float2 appendResult1619 = (float2(ase_n1_16861686 , ( ( ase_SimpleDivideOpNode_16941694 * 0.3 ) * ase_n1615_24802480 )));
                	float clampResult1642 = clamp( ( pow( ase_n1615_24802480 , ase______17131713 ) * 5.0 ) , ase_n1_16861686 , 5.0 );
                	ifLocalVar1647 = max( ifLocalVar1612, ( ( ( ase_SwizzleNode_17161716 * step( 0.3 , saturate( pow( (SAMPLE_TEXTURE2D( _NoiseTex, sampler_NoiseTex, ( ( ( ase_TextureCoordinatesNode_17041704 + ( ase_SimpleDivideOpNode_17291729 * ( ase_________22372237 * 15.0 ) ) ) + ase_SwizzleNode_22412241 ) + ( ase_DynamicAppendNode_22442244 * pow( 0.06666667 , ase______17081708 ) ) ) )).r , 1.0 ) ) ) ) * (SAMPLE_TEXTURE2D_LOD( _MipMap, sampler_MipMap, ( temp_output_1585_0 + appendResult1619 ), ase_n1_16861686 )).rgb ) * clampResult1642 ) );
                }
                float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 ase______24962496 = _BaseColor;
                float3 temp_output_1659_0 = ( ( temp_output_1651_0 + max( temp_output_1651_0, ifLocalVar1647 ) ) + ( (SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex )).rgb * (ase______24962496).rgb ) );
                float4 appendResult1663 = (float4((temp_output_1659_0).x , (temp_output_1659_0).y , (temp_output_1659_0).z , ase_n2_16811681));
                
                clip((SAMPLE_TEXTURE2D( _MaskAlpha, sampler_MaskAlpha, texCoord3 )).r - 0.5);
                return appendResult1663;
            }
            ENDCG
        }
    }
    Fallback "Transparent/Cutout/VertexLit"
	
	CustomEditor "AmplifyShaderEditor.MaterialInspector"
}
/*ASEBEGIN
Version=19913
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2504,"pos":[1920,15],"params":["Inherit","False","6120","2780","模板按原顶点阶段计算 object->tangent 视线并归一化，再插值。此原生模板变量节点读取该插值；片元再归一化，保留源视差阶段。RG 法线不使用 Unity NormalMap 解包，避免改变源码通道约定。","61","7","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","1682","1683","1685","1687","1688","1690","1691","1693","1694","1699","1704","1710","1718","1729","1979","2244","02 顶点视线与原始法线","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":7,"pos":[1970,115],"params":["Inherit","True","Property","_NormalMap","原始 RG 法线（线性）","3","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":29,"pos":[2310,115],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":30,"pos":[2650,605],"params":["Inherit","True","Property","_TextureSample0","Texture Sample 0","18","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":31,"pos":[2990,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":32,"pos":[2990,115],"params":["Inherit","False","Constant","_Float2","Float 2","19","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":33,"pos":[3330,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor","id":37,"pos":[4350,115],"params":["Inherit","False","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1682,"pos":[3330,360],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":34,"pos":[3670,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":35,"pos":[3670,115],"params":["Inherit","False","Property","_NormalScale","原始 RG 法线强度","18","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0","3","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":38,"pos":[4690,115],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1683,"pos":[4690,360],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2502,"pos":[0,15],"params":["Inherit","False","1700","4740","MIT: aspect-ux/AspectURP。完整三层流麻/视差闪片计算，非皮肤或体积散射。保留原属性；基色/色带 sRGB，噪声/裁剪/原始 RG 法线 Linear。","45","1","2","3","5","6","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","1675","1676","1677","1678","1679","1680","1681","1684","1686","1689","1692","1702","1706","1708","1713","1716","1720","1972","1976","2237","2241","2496","01 原源码与输入","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":13,"pos":[50,2075],"params":["Inherit","False","Property","_ShiningSpeed_02","第二层流速","8","0","Create","False","0","0","0","True","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TemplateLocalVarsNode, AmplifyShaderEditor","id":27,"pos":[5030,115],"params":["Inherit","False","0","0","ase_tangentView","0","5","FLOAT3","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":36,"pos":[4010,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor","id":39,"pos":[5030,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":12,"pos":[50,1830],"params":["Inherit","False","Property","_ShiningSpeed","第一层流速","7","0","Create","False","0","0","0","True","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":14,"pos":[50,2320],"params":["Inherit","False","Property","_ShiningSpeed_03","第三层流速","9","0","Create","False","0","0","0","True","0","False","Object","-1","","0.1","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":16,"pos":[50,2810],"params":["Inherit","False","Property","_DepthStep_02","第二层视差深度","11","0","Create","False","0","0","0","True","0","False","Object","-1","","20","0","0","300","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":23,"pos":[50,4280],"params":["Inherit","False","Property","_OffsetSecond","第二层偏移","16","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5,0.5,0,0","0.5,0.5,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.NormalizeNode, AmplifyShaderEditor","id":28,"pos":[5370,115],"params":["Inherit","False","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SqrtOpNode, AmplifyShaderEditor","id":40,"pos":[5370,850],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":41,"pos":[5370,360],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":42,"pos":[5370,605],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT2","0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1688,"pos":[2310,1095],"params":["Inherit","False","1684","ase_______1684","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1689,"pos":[390,1340],"params":["Inherit","False","ase_______1689","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1,"pos":[50,115],"params":["Inherit","False","Constant","_Float0","Float 0","0","0","Create","True","0","0","0","False","0","False","Object","-1","","0","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":15,"pos":[50,2565],"params":["Inherit","False","Property","_DepthStep","第一层视差深度","10","0","Create","False","0","0","0","True","0","False","Object","-1","","20","0","0","300","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":17,"pos":[50,3055],"params":["Inherit","False","Property","_DepthStep_03","第三层视差深度","12","0","Create","False","0","0","0","True","0","False","Object","-1","","20","0","0","300","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":21,"pos":[50,4035],"params":["Inherit","False","Constant","_Vector0","Vector 0","16","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":25,"pos":[50,4525],"params":["Inherit","False","Property","_OffsetThird","第三层偏移","17","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5,0.5,0,0","0.5,0.5,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":43,"pos":[5710,360],"params":["Inherit","False","FLOAT3","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.NegateNode, AmplifyShaderEditor","id":44,"pos":[5710,115],"params":["Inherit","False","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":47,"pos":[6390,115],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor","id":52,"pos":[1970,360],"params":["Inherit","False","1","0","FLOAT","1","False","5","FLOAT","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":53,"pos":[1970,605],"params":["Inherit","False","Constant","_Float4","Float 4","20","0","Create","True","0","0","0","False","0","False","Object","-1","","20","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":57,"pos":[2650,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":58,"pos":[2650,115],"params":["Inherit","False","Constant","_Float5","Float 5","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1677,"pos":[390,3545],"params":["Inherit","False","ase_______1677","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1684,"pos":[390,1095],"params":["Inherit","False","ase_______1684","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1690,"pos":[2650,2320],"params":["Inherit","False","1689","ase_______1689","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1691,"pos":[2310,1340],"params":["Inherit","False","1684","ase_______1684","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1692,"pos":[390,1585],"params":["Inherit","False","ase_______1692","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1972,"pos":[390,2075],"params":["Inherit","False","ase_________1972","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2508,"pos":[33400,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","264","598","599","600","601","602","603","604","605","606","607","608","609","610","611","612","613","614","615","616","617","618","619","620","621","622","623","624","625","626","627","628","629","630","631","632","633","634","635","636","637","638","639","640","641","642","643","644","645","646","647","648","649","650","651","652","653","654","655","656","657","658","659","660","661","662","663","664","665","666","667","668","669","670","671","672","673","674","675","676","677","678","679","680","681","682","683","684","685","686","687","688","689","690","691","692","693","694","695","696","697","698","699","700","701","702","703","704","705","706","707","708","709","710","711","712","713","714","715","716","717","718","719","720","721","722","723","724","725","726","727","728","729","730","731","732","733","734","735","736","737","738","739","740","741","742","743","744","745","746","747","748","749","750","751","752","753","754","755","756","757","758","759","760","761","762","763","764","765","766","767","768","769","770","771","772","1966","1967","1968","1969","1970","1971","1973","1974","1975","1977","1978","1980","1981","1982","1983","1984","1986","1987","1988","1989","1990","1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025","2026","2027","2028","2029","2030","2031","2032","2033","2034","2035","2036","2037","2038","2039","2040","2041","2042","2043","2044","2045","2046","2047","2048","2049","2050","2051","2052","2053","2054","2055","2056","2061","2499","04 第2层 · 迭代 1–5","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":5,"pos":[50,850],"params":["Inherit","True","Property","_NoiseTex","闪片噪声（线性）","1","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.ReflectOpNode, AmplifyShaderEditor","id":45,"pos":[6050,115],"params":["Inherit","False","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.AbsOpNode, AmplifyShaderEditor","id":48,"pos":[6730,360],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":49,"pos":[6730,115],"params":["Inherit","False","Constant","_Float3","Float 3","20","0","Create","True","0","0","0","False","0","False","Object","-1","","612","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":54,"pos":[2310,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":59,"pos":[2990,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":60,"pos":[2990,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":62,"pos":[2650,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":63,"pos":[2650,360],"params":["Inherit","False","Constant","_Float6","Float 6","20","0","Create","True","0","0","0","False","0","False","Object","-1","","-0.1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":606,"pos":[33450,360],"params":["Inherit","False","Constant","_Float129","Float 129","51","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1675,"pos":[390,3300],"params":["Inherit","False","ase_n21_1675","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1678,"pos":[730,605],"params":["Inherit","False","1677","ase_______1677","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1679,"pos":[390,3790],"params":["Inherit","False","ase_______1679","-1","True","1","0","FLOAT4","0,0,0,0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1685,"pos":[2310,850],"params":["Inherit","False","1684","ase_______1684","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1686,"pos":[390,115],"params":["Inherit","False","ase_n1_1686","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1693,"pos":[2650,2565],"params":["Inherit","False","1692","ase_______1692","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1702,"pos":[390,1830],"params":["Inherit","False","ase_________1702","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1973,"pos":[33450,605],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2237,"pos":[390,2320],"params":["Inherit","False","ase_________2237","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2505,"pos":[8260,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","263","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202","203","204","205","206","207","208","209","210","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234","235","236","237","238","239","240","241","242","243","244","245","1695","1696","1697","1698","1700","1701","1703","1705","1707","1709","1711","1712","1714","1715","1717","1719","1721","1722","1723","1724","1725","1726","1727","1728","1730","1731","1732","1733","1734","1735","1736","1737","1738","1739","1740","1741","1742","1743","1744","1745","1746","1747","1748","1749","1750","1751","1752","1753","1754","1755","1756","1757","1758","1759","1760","1761","1762","1763","1764","1765","1766","1767","1768","1769","1770","1771","1772","1773","1774","1775","1776","1777","1778","1779","1780","1781","1782","1783","1784","1785","1786","1787","1788","1789","1790","1791","1796","2498","03 第1层 · 迭代 1–5","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2511,"pos":[58540,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","264","1125","1126","1127","1128","1129","1130","1131","1132","1133","1134","1135","1136","1137","1138","1139","1140","1141","1142","1143","1144","1145","1146","1147","1148","1149","1150","1151","1152","1153","1154","1155","1156","1157","1158","1159","1160","1161","1162","1163","1164","1165","1166","1167","1168","1169","1170","1171","1172","1173","1174","1175","1176","1177","1178","1179","1180","1181","1182","1183","1184","1185","1186","1187","1188","1189","1190","1191","1192","1193","1194","1195","1196","1197","1198","1199","1200","1201","1202","1203","1204","1205","1206","1207","1208","1209","1210","1211","1212","1213","1214","1215","1216","1217","1218","1219","1220","1221","1222","1223","1224","1225","1226","1227","1228","1229","1230","1231","1232","1233","1234","1235","1236","1237","1238","1239","1240","1241","1242","1243","1244","1245","1246","1247","1248","1249","1250","1251","1252","1253","1254","1255","1256","1257","1258","1259","1260","1261","1262","1263","1264","1265","1266","1267","1268","1269","1270","1271","1272","1273","1274","1275","1276","1277","1278","1279","1280","1281","1282","1283","1284","1285","1286","1287","1288","1289","1290","1291","1292","1293","1294","1295","1296","1297","1298","1299","2231","2232","2233","2234","2235","2236","2238","2239","2240","2242","2243","2245","2246","2247","2248","2249","2251","2252","2253","2254","2255","2256","2257","2258","2259","2260","2261","2262","2263","2264","2265","2266","2267","2268","2269","2270","2271","2272","2273","2274","2275","2276","2277","2278","2279","2280","2281","2282","2283","2284","2285","2286","2287","2288","2289","2290","2291","2292","2293","2294","2295","2296","2297","2298","2299","2300","2301","2302","2303","2304","2305","2306","2307","2308","2309","2310","2311","2312","2313","2314","2315","2316","2317","2318","2319","2320","2321","2326","2500","05 第3层 · 迭代 1–5","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":19,"pos":[50,3545],"params":["Inherit","False","Property","_DieValue01","速度衰减","14","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5","0","0.01","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":24,"pos":[1070,360],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":46,"pos":[7070,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":50,"pos":[7070,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":55,"pos":[2650,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":61,"pos":[3330,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":64,"pos":[2990,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":65,"pos":[2990,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":67,"pos":[1970,1095],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":79,"pos":[8310,360],"params":["Inherit","False","Constant","_Float9","Float 9","21","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":607,"pos":[33790,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1133,"pos":[58590,360],"params":["Inherit","False","Constant","_Float249","Float 249","81","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1676,"pos":[730,360],"params":["Inherit","False","1675","ase_n21_1675","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1680,"pos":[730,850],"params":["Inherit","False","1679","ase_______1679","1","0","OBJECT","","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1687,"pos":[2650,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1703,"pos":[8310,605],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1974,"pos":[33790,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2238,"pos":[58590,605],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":22,"pos":[1070,115],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":26,"pos":[1070,605],"params":["Inherit","False","FLOAT2","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor","id":51,"pos":[7410,115],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":56,"pos":[2990,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":66,"pos":[3330,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":80,"pos":[8650,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":598,"pos":[33450,115],"params":["Inherit","False","Constant","_Float127","Float 127","50","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":608,"pos":[34130,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":641,"pos":[34130,360],"params":["Inherit","False","Constant","_Float137","Float 137","53","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1134,"pos":[58930,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1704,"pos":[2310,1585],"params":["Inherit","False","ase_TextureCoordinatesNode_1704","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1708,"pos":[390,2810],"params":["Inherit","False","ase______1708","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1975,"pos":[34130,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1976,"pos":[1410,360],"params":["Inherit","False","ase_SwizzleNode_1976","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1978,"pos":[34130,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1979,"pos":[3670,605],"params":["Inherit","False","ase_DynamicAppendNode_1979","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1994,"pos":[34130,2320],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2239,"pos":[58930,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":71,"pos":[8310,115],"params":["Inherit","False","Constant","_Float7","Float 7","20","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":81,"pos":[8990,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":114,"pos":[8990,360],"params":["Inherit","False","Constant","_Float17","Float 17","23","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":609,"pos":[34470,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":611,"pos":[34470,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":642,"pos":[34470,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1125,"pos":[58590,115],"params":["Inherit","False","Constant","_Float247","Float 247","80","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1135,"pos":[59270,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1168,"pos":[59270,360],"params":["Inherit","False","Constant","_Float257","Float 257","83","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1705,"pos":[8990,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1706,"pos":[1410,115],"params":["Inherit","False","ase_SwizzleNode_1706","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1709,"pos":[8990,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1710,"pos":[3330,605],"params":["Inherit","False","ase_DynamicAppendNode_1710","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1728,"pos":[8990,2320],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1729,"pos":[7750,115],"params":["Inherit","False","ase_SimpleDivideOpNode_1729","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1977,"pos":[34470,1095],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1980,"pos":[34470,1340],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1995,"pos":[34470,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2240,"pos":[59270,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2241,"pos":[1410,605],"params":["Inherit","False","ase_SwizzleNode_2241","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2243,"pos":[59270,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2244,"pos":[3670,850],"params":["Inherit","False","ase_DynamicAppendNode_2244","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2259,"pos":[59270,2320],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":82,"pos":[9330,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":84,"pos":[9330,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":115,"pos":[9330,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":610,"pos":[34810,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":612,"pos":[34810,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":633,"pos":[33790,360],"params":["Inherit","False","Constant","_Float135","Float 135","52","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":643,"pos":[34810,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":676,"pos":[34810,115],"params":["Inherit","False","Constant","_Float145","Float 145","55","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1136,"pos":[59610,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1138,"pos":[59610,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1169,"pos":[59610,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1707,"pos":[9330,850],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1711,"pos":[9330,1340],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1730,"pos":[9330,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1996,"pos":[34810,2810],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1998,"pos":[34810,4035],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2011,"pos":[34810,3790],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2242,"pos":[59610,1095],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2245,"pos":[59610,2075],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2260,"pos":[59610,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":83,"pos":[9670,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":85,"pos":[9670,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":106,"pos":[8650,360],"params":["Inherit","False","Constant","_Float15","Float 15","22","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":116,"pos":[9670,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":149,"pos":[9670,115],"params":["Inherit","False","Constant","_Float25","Float 25","25","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":599,"pos":[33790,115],"params":["Inherit","False","Constant","_Float128","Float 128","50","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":613,"pos":[35150,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":644,"pos":[35150,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":646,"pos":[35150,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":677,"pos":[35150,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1137,"pos":[59950,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1139,"pos":[59950,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1160,"pos":[58930,360],"params":["Inherit","False","Constant","_Float255","Float 255","82","0","Create","True","0","0","0","False","0","False","Object","-1","","0.5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1170,"pos":[59950,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1203,"pos":[59950,115],"params":["Inherit","False","Constant","_Float265","Float 265","85","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1694,"pos":[2650,1095],"params":["Inherit","False","ase_SimpleDivideOpNode_1694","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1731,"pos":[9670,2810],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1733,"pos":[9670,4035],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1746,"pos":[9670,3790],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1966,"pos":[33790,1095],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1967,"pos":[33790,605],"params":["Inherit","False","ase_n598_1967","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1997,"pos":[35150,850],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1999,"pos":[35150,1095],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2012,"pos":[35150,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2261,"pos":[59950,3055],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2263,"pos":[59950,4035],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2276,"pos":[59950,3790],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":6,"pos":[50,1095],"params":["Inherit","True","Property","_MipMap","闪片色带","2","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":72,"pos":[8650,115],"params":["Inherit","False","Constant","_Float8","Float 8","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":86,"pos":[10010,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":117,"pos":[10010,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":119,"pos":[10010,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":150,"pos":[10010,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":600,"pos":[34130,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":614,"pos":[35490,2810],"params":["Inherit","True","Property","_TextureSample32","Texture Sample 32","51","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":645,"pos":[35490,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":647,"pos":[35490,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":668,"pos":[34130,605],"params":["Inherit","False","Constant","_Float143","Float 143","54","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3333333","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":678,"pos":[35490,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":711,"pos":[35490,115],"params":["Inherit","False","Constant","_Float153","Float 153","57","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1126,"pos":[58930,115],"params":["Inherit","False","Constant","_Float248","Float 248","80","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1140,"pos":[60290,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1171,"pos":[60290,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1173,"pos":[60290,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1204,"pos":[60290,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1695,"pos":[8650,850],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1696,"pos":[8650,605],"params":["Inherit","False","ase_n71_1696","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1732,"pos":[10010,360],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1734,"pos":[10010,1095],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1747,"pos":[10010,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1968,"pos":[34130,1340],"params":["Inherit","False","1967","ase_n598_1967","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2013,"pos":[35490,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2015,"pos":[35490,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2028,"pos":[35490,2565],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2231,"pos":[58930,1095],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2232,"pos":[58930,605],"params":["Inherit","False","ase_n1125_2232","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2262,"pos":[60290,850],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2264,"pos":[60290,1585],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2277,"pos":[60290,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":68,"pos":[1970,1340],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":73,"pos":[8990,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":87,"pos":[10350,2810],"params":["Inherit","True","Property","_TextureSample2","Texture Sample 2","21","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":118,"pos":[10350,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":120,"pos":[10350,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":141,"pos":[8990,605],"params":["Inherit","False","Constant","_Float23","Float 23","24","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3333333","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":151,"pos":[10350,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":184,"pos":[10350,115],"params":["Inherit","False","Constant","_Float33","Float 33","27","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":601,"pos":[34470,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":615,"pos":[35830,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":617,"pos":[35830,115],"params":["Inherit","False","Constant","_Float131","Float 131","52","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":634,"pos":[34130,115],"params":["Inherit","False","Constant","_Float136","Float 136","52","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":648,"pos":[35830,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":679,"pos":[35830,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":681,"pos":[35830,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":712,"pos":[35830,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1127,"pos":[59270,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1141,"pos":[60630,2565],"params":["Inherit","True","Property","_TextureSample62","Texture Sample 62","81","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1172,"pos":[60630,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1174,"pos":[60630,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1195,"pos":[59270,605],"params":["Inherit","False","Constant","_Float263","Float 263","84","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3333333","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1205,"pos":[60630,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1238,"pos":[60630,115],"params":["Inherit","False","Constant","_Float273","Float 273","87","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1697,"pos":[8990,1585],"params":["Inherit","False","1696","ase_n71_1696","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1748,"pos":[10350,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1750,"pos":[10350,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1763,"pos":[10350,2565],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1969,"pos":[34470,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1989,"pos":[34130,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1990,"pos":[34130,850],"params":["Inherit","False","ase_n633_1990","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2014,"pos":[35830,850],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2016,"pos":[35830,1340],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2029,"pos":[35830,360],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2233,"pos":[59270,1340],"params":["Inherit","False","2232","ase_n1125_2232","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2278,"pos":[60630,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2280,"pos":[60630,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2293,"pos":[60630,2810],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":10,"pos":[50,1585],"params":["Inherit","False","Property","_SparkleColor","闪片颜色（HDR）","6","1","[HDR]","Create","False","0","0","0","True","0","False","Object","-1","","1,1,1,1","1,1,1,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":20,"pos":[50,3790],"params":["Inherit","False","Property","_DieValue02","亮度衰减","15","0","Create","False","0","0","0","True","0","False","Object","-1","","3","0","0","5","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":74,"pos":[9330,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":88,"pos":[10690,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":90,"pos":[10690,115],"params":["Inherit","False","Constant","_Float11","Float 11","22","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":107,"pos":[8990,115],"params":["Inherit","False","Constant","_Float16","Float 16","22","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":121,"pos":[10690,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":152,"pos":[10690,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":154,"pos":[10690,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":185,"pos":[10690,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":602,"pos":[34810,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":618,"pos":[36170,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":635,"pos":[34470,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":649,"pos":[36170,1095],"params":["Inherit","True","Property","_TextureSample34","Texture Sample 34","53","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":680,"pos":[36170,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":682,"pos":[36170,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":703,"pos":[34470,360],"params":["Inherit","False","Constant","_Float151","Float 151","56","0","Create","True","0","0","0","False","0","False","Object","-1","","0.25","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":713,"pos":[36170,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":746,"pos":[36170,115],"params":["Inherit","False","Constant","_Float161","Float 161","59","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1128,"pos":[59610,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1142,"pos":[60970,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1144,"pos":[60970,115],"params":["Inherit","False","Constant","_Float251","Float 251","82","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1161,"pos":[59270,115],"params":["Inherit","False","Constant","_Float256","Float 256","82","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1175,"pos":[60970,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1206,"pos":[60970,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1208,"pos":[60970,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1239,"pos":[60970,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1698,"pos":[9330,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1699,"pos":[2310,1830],"params":["Inherit","False","ase_TextureCoordinatesNode_1699","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1723,"pos":[8990,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1724,"pos":[8990,850],"params":["Inherit","False","ase_n106_1724","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1749,"pos":[10690,360],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1751,"pos":[10690,1340],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1764,"pos":[10690,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1970,"pos":[34810,3545],"params":["Inherit","False","1699","ase_TextureCoordinatesNode_1699","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1991,"pos":[34470,2320],"params":["Inherit","False","1990","ase_n633_1990","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2030,"pos":[36170,1585],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2032,"pos":[36170,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2045,"pos":[36170,2320],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2234,"pos":[59610,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2254,"pos":[59270,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2255,"pos":[59270,850],"params":["Inherit","False","ase_n1160_2255","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2279,"pos":[60970,1095],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2281,"pos":[60970,1585],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2294,"pos":[60970,360],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":11,"pos":[390,850],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":75,"pos":[9670,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":91,"pos":[11030,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":108,"pos":[9330,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":122,"pos":[11030,1095],"params":["Inherit","True","Property","_TextureSample4","Texture Sample 4","23","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":153,"pos":[11030,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":155,"pos":[11030,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":176,"pos":[9330,360],"params":["Inherit","False","Constant","_Float31","Float 31","26","0","Create","True","0","0","0","False","0","False","Object","-1","","0.25","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":186,"pos":[11030,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":219,"pos":[11030,115],"params":["Inherit","False","Constant","_Float41","Float 41","29","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":603,"pos":[35150,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":616,"pos":[36510,115],"params":["Inherit","False","Constant","_Float130","Float 130","52","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":619,"pos":[36510,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":636,"pos":[34810,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":650,"pos":[36510,1830],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":652,"pos":[36510,360],"params":["Inherit","False","Constant","_Float139","Float 139","54","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":669,"pos":[34470,115],"params":["Inherit","False","Constant","_Float144","Float 144","54","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":683,"pos":[36510,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":714,"pos":[36510,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":716,"pos":[36510,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":747,"pos":[36510,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1129,"pos":[59950,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1145,"pos":[61310,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1162,"pos":[59610,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1176,"pos":[61310,1830],"params":["Inherit","True","Property","_TextureSample64","Texture Sample 64","83","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1207,"pos":[61310,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1209,"pos":[61310,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1230,"pos":[59610,360],"params":["Inherit","False","Constant","_Float271","Float 271","86","0","Create","True","0","0","0","False","0","False","Object","-1","","0.25","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1240,"pos":[61310,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1273,"pos":[61310,115],"params":["Inherit","False","Constant","_Float281","Float 281","89","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1700,"pos":[9670,3545],"params":["Inherit","False","1699","ase_TextureCoordinatesNode_1699","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1713,"pos":[390,3055],"params":["Inherit","False","ase______1713","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1725,"pos":[9330,2075],"params":["Inherit","False","1724","ase_n106_1724","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1765,"pos":[11030,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1767,"pos":[11030,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1780,"pos":[11030,2320],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1971,"pos":[36510,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1981,"pos":[36510,1340],"params":["Inherit","False","1967","ase_n598_1967","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1982,"pos":[36510,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1992,"pos":[34810,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2006,"pos":[34470,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2007,"pos":[34470,1585],"params":["Inherit","False","ase_n668_2007","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2031,"pos":[36510,1095],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2033,"pos":[36510,1585],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2046,"pos":[36510,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2235,"pos":[59950,3300],"params":["Inherit","False","1699","ase_TextureCoordinatesNode_1699","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2256,"pos":[59610,2320],"params":["Inherit","False","2255","ase_n1160_2255","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2295,"pos":[61310,1585],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2297,"pos":[61310,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2310,"pos":[61310,2320],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2507,"pos":[25020,15],"params":["Inherit","False","8160","5720","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","264","421","422","423","424","425","426","427","428","429","430","431","432","433","434","435","436","437","438","439","440","441","442","443","444","445","446","447","448","449","450","451","452","453","454","455","456","457","458","459","460","461","462","463","464","465","466","467","468","469","470","471","472","473","474","475","476","477","478","479","480","481","482","483","484","485","486","487","488","489","490","491","492","493","494","495","496","497","498","499","500","501","502","503","504","505","506","507","508","509","510","511","512","513","514","515","516","517","518","519","520","521","522","523","524","525","526","527","528","529","530","531","532","533","534","535","536","537","538","539","540","541","542","543","544","545","546","547","548","549","550","551","552","553","554","555","556","557","558","559","560","561","562","563","564","565","566","567","568","569","570","571","572","573","574","575","576","577","578","579","580","581","582","583","584","585","586","587","588","589","590","591","592","593","594","595","596","597","1879","1880","1881","1882","1884","1885","1886","1887","1888","1889","1890","1891","1892","1893","1894","1895","1896","1897","1898","1899","1900","1901","1902","1903","1904","1905","1906","1907","1908","1909","1910","1911","1912","1913","1914","1915","1916","1917","1918","1919","1920","1921","1922","1923","1924","1925","1926","1927","1928","1929","1930","1931","1932","1933","1934","1935","1936","1937","1938","1939","1940","1941","1942","1943","1944","1945","1946","1947","1948","1949","1950","1951","1952","1953","1954","1955","1956","1957","1958","1959","1960","1961","1962","1963","1964","1965","1985","03 第1层 · 迭代 11–15","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2509,"pos":[41780,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","262","773","774","775","776","777","778","779","780","781","782","783","784","785","786","787","788","789","790","791","792","793","794","795","796","797","798","799","800","801","802","803","804","805","806","807","808","809","810","811","812","813","814","815","816","817","818","819","820","821","822","823","824","825","826","827","828","829","830","831","832","833","834","835","836","837","838","839","840","841","842","843","844","845","846","847","848","849","850","851","852","853","854","855","856","857","858","859","860","861","862","863","864","865","866","867","868","869","870","871","872","873","874","875","876","877","878","879","880","881","882","883","884","885","886","887","888","889","890","891","892","893","894","895","896","897","898","899","900","901","902","903","904","905","906","907","908","909","910","911","912","913","914","915","916","917","918","919","920","921","922","923","924","925","926","927","928","929","930","931","932","933","934","935","936","937","938","939","940","941","942","943","944","945","946","947","2057","2058","2059","2060","2062","2063","2064","2065","2066","2067","2068","2069","2070","2071","2072","2073","2074","2075","2076","2077","2078","2079","2080","2081","2082","2083","2084","2085","2086","2087","2088","2089","2090","2091","2092","2093","2094","2095","2096","2097","2098","2099","2100","2101","2102","2103","2104","2105","2106","2107","2108","2109","2110","2111","2112","2113","2114","2115","2116","2117","2118","2119","2120","2121","2122","2123","2124","2125","2126","2127","2128","2129","2130","2131","2132","2133","2134","2135","2136","2137","2138","2139","2140","2141","2142","2143","2148","04 第2层 · 迭代 6–10","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":76,"pos":[10010,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":89,"pos":[11370,115],"params":["Inherit","False","Constant","_Float10","Float 10","22","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":92,"pos":[11370,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":109,"pos":[9670,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":123,"pos":[11370,2075],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":125,"pos":[11370,360],"params":["Inherit","False","Constant","_Float19","Float 19","24","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":142,"pos":[9330,115],"params":["Inherit","False","Constant","_Float24","Float 24","24","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":156,"pos":[11370,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":187,"pos":[11370,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":189,"pos":[11370,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":220,"pos":[11370,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":596,"pos":[25070,360],"params":["Inherit","False","Constant","_Vector2","Vector 2","50","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":604,"pos":[36850,1095],"params":["Inherit","True","Property","_TextureSample31","Texture Sample 31","50","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":620,"pos":[36850,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":621,"pos":[36850,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":622,"pos":[36850,115],"params":["Inherit","False","Constant","_Float132","Float 132","52","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":637,"pos":[35150,2320],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":653,"pos":[36850,605],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":670,"pos":[34810,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":684,"pos":[36850,2075],"params":["Inherit","True","Property","_TextureSample36","Texture Sample 36","55","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":715,"pos":[36850,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":717,"pos":[36850,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":738,"pos":[34810,605],"params":["Inherit","False","Constant","_Float159","Float 159","58","0","Create","True","0","0","0","False","0","False","Object","-1","","0.2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":748,"pos":[36850,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":781,"pos":[41830,360],"params":["Inherit","False","Constant","_Float169","Float 169","61","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1130,"pos":[60290,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1143,"pos":[61650,115],"params":["Inherit","False","Constant","_Float250","Float 250","82","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1146,"pos":[61650,2320],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1163,"pos":[59950,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1177,"pos":[61650,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1179,"pos":[61650,360],"params":["Inherit","False","Constant","_Float259","Float 259","84","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1196,"pos":[59610,115],"params":["Inherit","False","Constant","_Float264","Float 264","84","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1210,"pos":[61650,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1241,"pos":[61650,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1243,"pos":[61650,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1274,"pos":[61650,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1701,"pos":[11370,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1712,"pos":[11370,1340],"params":["Inherit","False","1696","ase_n71_1696","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1714,"pos":[11370,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1716,"pos":[730,115],"params":["Inherit","False","ase_SwizzleNode_1716","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1726,"pos":[9670,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1741,"pos":[9330,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1742,"pos":[9330,1585],"params":["Inherit","False","ase_n141_1742","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1766,"pos":[11370,850],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1768,"pos":[11370,1585],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1781,"pos":[11370,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1984,"pos":[36850,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2008,"pos":[34810,3055],"params":["Inherit","False","2007","ase_n668_2007","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2047,"pos":[36850,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2049,"pos":[36850,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2064,"pos":[41830,605],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2236,"pos":[61650,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2246,"pos":[61650,1095],"params":["Inherit","False","2232","ase_n1125_2232","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2247,"pos":[61650,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2257,"pos":[59950,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2271,"pos":[59610,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2272,"pos":[59610,1340],"params":["Inherit","False","ase_n1195_2272","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2296,"pos":[61650,1340],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2298,"pos":[61650,1830],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2311,"pos":[61650,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2506,"pos":[16640,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","262","246","247","248","249","250","251","252","253","254","255","256","257","258","259","260","261","262","263","264","265","266","267","268","269","270","271","272","273","274","275","276","277","278","279","280","281","282","283","284","285","286","287","288","289","290","291","292","293","294","295","296","297","298","299","300","301","302","303","304","305","306","307","308","309","310","311","312","313","314","315","316","317","318","319","320","321","322","323","324","325","326","327","328","329","330","331","332","333","334","335","336","337","338","339","340","341","342","343","344","345","346","347","348","349","350","351","352","353","354","355","356","357","358","359","360","361","362","363","364","365","366","367","368","369","370","371","372","373","374","375","376","377","378","379","380","381","382","383","384","385","386","387","388","389","390","391","392","393","394","395","396","397","398","399","400","401","402","403","404","405","406","407","408","409","410","411","412","413","414","415","416","417","418","419","420","1792","1793","1794","1795","1797","1798","1799","1800","1801","1802","1803","1804","1805","1806","1807","1808","1809","1810","1811","1812","1813","1814","1815","1816","1817","1818","1819","1820","1821","1822","1823","1824","1825","1826","1827","1828","1829","1830","1831","1832","1833","1834","1835","1836","1837","1838","1839","1840","1841","1842","1843","1844","1845","1846","1847","1848","1849","1850","1851","1852","1853","1854","1855","1856","1857","1858","1859","1860","1861","1862","1863","1864","1865","1866","1867","1868","1869","1870","1871","1872","1873","1874","1875","1876","1877","1878","1883","03 第1层 · 迭代 6–10","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2510,"pos":[50160,15],"params":["Inherit","False","8160","5720","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","264","948","949","950","951","952","953","954","955","956","957","958","959","960","961","962","963","964","965","966","967","968","969","970","971","972","973","974","975","976","977","978","979","980","981","982","983","984","985","986","987","988","989","990","991","992","993","994","995","996","997","998","999","1000","1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","1011","1012","1013","1014","1015","1016","1017","1018","1019","1020","1021","1022","1023","1024","1025","1026","1027","1028","1029","1030","1031","1032","1033","1034","1035","1036","1037","1038","1039","1040","1041","1042","1043","1044","1045","1046","1047","1048","1049","1050","1051","1052","1053","1054","1055","1056","1057","1058","1059","1060","1061","1062","1063","1064","1065","1066","1067","1068","1069","1070","1071","1072","1073","1074","1075","1076","1077","1078","1079","1080","1081","1082","1083","1084","1085","1086","1087","1088","1089","1090","1091","1092","1093","1094","1095","1096","1097","1098","1099","1100","1101","1102","1103","1104","1105","1106","1107","1108","1109","1110","1111","1112","1113","1114","1115","1116","1117","1118","1119","1120","1121","1122","1123","1124","2144","2145","2146","2147","2149","2150","2151","2152","2153","2154","2155","2156","2157","2158","2159","2160","2161","2162","2163","2164","2165","2166","2167","2168","2169","2170","2171","2172","2173","2174","2175","2176","2177","2178","2179","2180","2181","2182","2183","2184","2185","2186","2187","2188","2189","2190","2191","2192","2193","2194","2195","2196","2197","2198","2199","2200","2201","2202","2203","2204","2205","2206","2207","2208","2209","2210","2211","2212","2213","2214","2215","2216","2217","2218","2219","2220","2221","2222","2223","2224","2225","2226","2227","2228","2229","2230","2250","04 第2层 · 迭代 11–15","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2512,"pos":[66920,15],"params":["Inherit","False","8160","4250","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","262","1300","1301","1302","1303","1304","1305","1306","1307","1308","1309","1310","1311","1312","1313","1314","1315","1316","1317","1318","1319","1320","1321","1322","1323","1324","1325","1326","1327","1328","1329","1330","1331","1332","1333","1334","1335","1336","1337","1338","1339","1340","1341","1342","1343","1344","1345","1346","1347","1348","1349","1350","1351","1352","1353","1354","1355","1356","1357","1358","1359","1360","1361","1362","1363","1364","1365","1366","1367","1368","1369","1370","1371","1372","1373","1374","1375","1376","1377","1378","1379","1380","1381","1382","1383","1384","1385","1386","1387","1388","1389","1390","1391","1392","1393","1394","1395","1396","1397","1398","1399","1400","1401","1402","1403","1404","1405","1406","1407","1408","1409","1410","1411","1412","1413","1414","1415","1416","1417","1418","1419","1420","1421","1422","1423","1424","1425","1426","1427","1428","1429","1430","1431","1432","1433","1434","1435","1436","1437","1438","1439","1440","1441","1442","1443","1444","1445","1446","1447","1448","1449","1450","1451","1452","1453","1454","1455","1456","1457","1458","1459","1460","1461","1462","1463","1464","1465","1466","1467","1468","1469","1470","1471","1472","1473","1474","2322","2323","2324","2325","2327","2328","2329","2330","2331","2332","2333","2334","2335","2336","2337","2338","2339","2340","2341","2342","2343","2344","2345","2346","2347","2348","2349","2350","2351","2352","2353","2354","2355","2356","2357","2358","2359","2360","2361","2362","2363","2364","2365","2366","2367","2368","2369","2370","2371","2372","2373","2374","2375","2376","2377","2378","2379","2380","2381","2382","2383","2384","2385","2386","2387","2388","2389","2390","2391","2392","2393","2394","2395","2396","2397","2398","2399","2400","2401","2402","2403","2404","2405","2406","2407","2408","2413","05 第3层 · 迭代 6–10","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":69,"pos":[1970,850],"params":["Inherit","False","Constant","_Vector1","Vector 1","20","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":77,"pos":[11710,850],"params":["Inherit","True","Property","_TextureSample1","Texture Sample 1","20","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":93,"pos":[11710,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":94,"pos":[11710,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":95,"pos":[11710,115],"params":["Inherit","False","Constant","_Float12","Float 12","22","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":110,"pos":[10010,1830],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":126,"pos":[11710,1095],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":143,"pos":[9670,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":157,"pos":[11710,1585],"params":["Inherit","True","Property","_TextureSample6","Texture Sample 6","25","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":188,"pos":[11710,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":190,"pos":[11710,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":211,"pos":[9670,605],"params":["Inherit","False","Constant","_Float39","Float 39","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":221,"pos":[11710,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":254,"pos":[16690,360],"params":["Inherit","False","Constant","_Float49","Float 49","31","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":597,"pos":[25410,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":605,"pos":[37190,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":623,"pos":[37190,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":624,"pos":[37190,115],"params":["Inherit","False","Constant","_Float133","Float 133","52","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":626,"pos":[37190,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":638,"pos":[35490,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":651,"pos":[37190,360],"params":["Inherit","False","Constant","_Float138","Float 138","54","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":654,"pos":[37190,1585],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":671,"pos":[35150,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":685,"pos":[37190,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":687,"pos":[37190,605],"params":["Inherit","False","Constant","_Float147","Float 147","56","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":704,"pos":[34810,360],"params":["Inherit","False","Constant","_Float152","Float 152","56","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":718,"pos":[37190,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":749,"pos":[37190,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":751,"pos":[37190,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":782,"pos":[42170,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.Vector4Node, AmplifyShaderEditor","id":1123,"pos":[50210,360],"params":["Inherit","False","Constant","_Vector3","Vector 3","80","0","Create","True","0","0","0","False","0","False","Object","-1","","0,0,0,0","0,0,0,0","0","5","FLOAT4","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1131,"pos":[61990,605],"params":["Inherit","True","Property","_TextureSample61","Texture Sample 61","80","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1147,"pos":[61990,850],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1148,"pos":[61990,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1149,"pos":[61990,115],"params":["Inherit","False","Constant","_Float252","Float 252","82","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1164,"pos":[60290,2320],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1180,"pos":[61990,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1197,"pos":[59950,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1211,"pos":[61990,2320],"params":["Inherit","True","Property","_TextureSample66","Texture Sample 66","85","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1242,"pos":[61990,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1244,"pos":[61990,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1265,"pos":[59950,605],"params":["Inherit","False","Constant","_Float279","Float 279","88","0","Create","True","0","0","0","False","0","False","Object","-1","","0.2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1275,"pos":[61990,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1308,"pos":[66970,360],"params":["Inherit","False","Constant","_Float289","Float 289","91","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1717,"pos":[11710,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1743,"pos":[9670,3055],"params":["Inherit","False","1742","ase_n141_1742","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1782,"pos":[11710,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1784,"pos":[11710,2810],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1799,"pos":[16690,605],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1983,"pos":[37190,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1993,"pos":[37190,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2000,"pos":[37190,2320],"params":["Inherit","False","1990","ase_n633_1990","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2001,"pos":[37190,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2009,"pos":[35150,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2023,"pos":[34810,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2024,"pos":[34810,1095],"params":["Inherit","False","ase_n703_2024","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2048,"pos":[37190,1340],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2050,"pos":[37190,1830],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2065,"pos":[42170,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2249,"pos":[61990,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2273,"pos":[59950,2320],"params":["Inherit","False","2272","ase_n1195_2272","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2312,"pos":[61990,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2314,"pos":[61990,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2329,"pos":[66970,605],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":70,"pos":[2310,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":78,"pos":[12050,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":96,"pos":[12050,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":97,"pos":[12050,115],"params":["Inherit","False","Constant","_Float13","Float 13","22","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":99,"pos":[12050,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":111,"pos":[10350,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":124,"pos":[12050,360],"params":["Inherit","False","Constant","_Float18","Float 18","24","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":127,"pos":[12050,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":144,"pos":[10010,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":158,"pos":[12050,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":160,"pos":[12050,605],"params":["Inherit","False","Constant","_Float27","Float 27","26","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":177,"pos":[9670,360],"params":["Inherit","False","Constant","_Float32","Float 32","26","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":191,"pos":[12050,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":222,"pos":[12050,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":224,"pos":[12050,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":255,"pos":[17030,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":625,"pos":[37530,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":627,"pos":[37530,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":639,"pos":[37530,1095],"params":["Inherit","True","Property","_TextureSample33","Texture Sample 33","52","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":655,"pos":[37530,850],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":656,"pos":[37530,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":657,"pos":[37530,115],"params":["Inherit","False","Constant","_Float140","Float 140","54","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":672,"pos":[35490,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":688,"pos":[37530,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":705,"pos":[35150,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":719,"pos":[37530,1830],"params":["Inherit","True","Property","_TextureSample38","Texture Sample 38","57","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":750,"pos":[37530,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":752,"pos":[37530,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":773,"pos":[41830,115],"params":["Inherit","False","Constant","_Float167","Float 167","60","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":783,"pos":[42510,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":816,"pos":[42510,360],"params":["Inherit","False","Constant","_Float177","Float 177","63","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1124,"pos":[50550,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","FLOAT4","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1132,"pos":[62330,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1150,"pos":[62330,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1151,"pos":[62330,115],"params":["Inherit","False","Constant","_Float253","Float 253","82","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1153,"pos":[62330,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1165,"pos":[60630,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1178,"pos":[62330,360],"params":["Inherit","False","Constant","_Float258","Float 258","84","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1181,"pos":[62330,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1198,"pos":[60290,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1212,"pos":[62330,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1214,"pos":[62330,605],"params":["Inherit","False","Constant","_Float267","Float 267","86","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1231,"pos":[59950,360],"params":["Inherit","False","Constant","_Float272","Float 272","86","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1245,"pos":[62330,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1276,"pos":[62330,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1278,"pos":[62330,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1309,"pos":[67310,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1715,"pos":[12050,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1727,"pos":[12050,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1735,"pos":[12050,2320],"params":["Inherit","False","1724","ase_n106_1724","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1736,"pos":[12050,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1744,"pos":[10010,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1758,"pos":[9670,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1759,"pos":[9670,1095],"params":["Inherit","False","ase_n176_1759","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1783,"pos":[12050,1340],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1785,"pos":[12050,1585],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1800,"pos":[17030,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1985,"pos":[25750,850],"params":["Inherit","False","ase_SwizzleNode_1985","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2003,"pos":[37530,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2025,"pos":[35150,1830],"params":["Inherit","False","2024","ase_n703_2024","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2066,"pos":[42510,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2068,"pos":[42510,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2081,"pos":[42510,2320],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2248,"pos":[62330,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2258,"pos":[62330,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2265,"pos":[62330,2075],"params":["Inherit","False","2255","ase_n1160_2255","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2266,"pos":[62330,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2274,"pos":[60290,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2288,"pos":[59950,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2289,"pos":[59950,1095],"params":["Inherit","False","ase_n1230_2289","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2313,"pos":[62330,1585],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2315,"pos":[62330,2320],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2330,"pos":[67310,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":98,"pos":[12390,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":100,"pos":[12390,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":112,"pos":[12390,850],"params":["Inherit","True","Property","_TextureSample3","Texture Sample 3","22","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":128,"pos":[12390,1095],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":129,"pos":[12390,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":130,"pos":[12390,115],"params":["Inherit","False","Constant","_Float20","Float 20","24","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":145,"pos":[10350,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":161,"pos":[12390,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":178,"pos":[10010,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":192,"pos":[12390,2075],"params":["Inherit","True","Property","_TextureSample8","Texture Sample 8","27","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":223,"pos":[12390,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":225,"pos":[12390,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":246,"pos":[16690,115],"params":["Inherit","False","Constant","_Float47","Float 47","30","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":256,"pos":[17370,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":289,"pos":[17370,360],"params":["Inherit","False","Constant","_Float57","Float 57","33","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":628,"pos":[37870,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":640,"pos":[37870,2075],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":658,"pos":[37870,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":659,"pos":[37870,115],"params":["Inherit","False","Constant","_Float141","Float 141","54","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":661,"pos":[37870,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":673,"pos":[35830,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":686,"pos":[37870,360],"params":["Inherit","False","Constant","_Float146","Float 146","56","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":689,"pos":[37870,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":706,"pos":[35490,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":720,"pos":[37870,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":722,"pos":[37870,605],"params":["Inherit","False","Constant","_Float155","Float 155","58","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":739,"pos":[35150,115],"params":["Inherit","False","Constant","_Float160","Float 160","58","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":753,"pos":[37870,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":784,"pos":[42850,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":786,"pos":[42850,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":817,"pos":[42850,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1152,"pos":[62670,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1154,"pos":[62670,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1166,"pos":[62670,850],"params":["Inherit","True","Property","_TextureSample63","Texture Sample 63","82","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1182,"pos":[62670,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1183,"pos":[62670,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1184,"pos":[62670,115],"params":["Inherit","False","Constant","_Float260","Float 260","84","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1199,"pos":[60630,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1215,"pos":[62670,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1232,"pos":[60290,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1246,"pos":[62670,2075],"params":["Inherit","True","Property","_TextureSample68","Texture Sample 68","87","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1277,"pos":[62670,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1279,"pos":[62670,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1300,"pos":[66970,115],"params":["Inherit","False","Constant","_Float287","Float 287","90","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1310,"pos":[67650,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1343,"pos":[67650,360],"params":["Inherit","False","Constant","_Float297","Float 297","93","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1718,"pos":[2650,1340],"params":["Inherit","False","ase_SwizzleNode_1718","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1738,"pos":[12390,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1760,"pos":[10010,2075],"params":["Inherit","False","1759","ase_n176_1759","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1801,"pos":[17370,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1803,"pos":[17370,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1816,"pos":[17370,2320],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1986,"pos":[37870,1830],"params":["Inherit","False","1985","ase_SwizzleNode_1985","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1987,"pos":[37870,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1988,"pos":[37870,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2002,"pos":[37870,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2010,"pos":[37870,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2017,"pos":[37870,3055],"params":["Inherit","False","2007","ase_n668_2007","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2018,"pos":[37870,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2026,"pos":[35490,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2040,"pos":[35150,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2041,"pos":[35150,1340],"params":["Inherit","False","ase_n738_2041","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2067,"pos":[42850,1095],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2069,"pos":[42850,1340],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2082,"pos":[42850,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2250,"pos":[50890,850],"params":["Inherit","False","ase_SwizzleNode_2250","-1","True","1","0","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2268,"pos":[62670,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2290,"pos":[60290,1830],"params":["Inherit","False","2289","ase_n1230_2289","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2331,"pos":[67650,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2333,"pos":[67650,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2346,"pos":[67650,2320],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":101,"pos":[12730,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":113,"pos":[12730,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":131,"pos":[12730,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":132,"pos":[12730,115],"params":["Inherit","False","Constant","_Float21","Float 21","24","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":134,"pos":[12730,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":146,"pos":[10690,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":159,"pos":[12730,360],"params":["Inherit","False","Constant","_Float26","Float 26","26","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":162,"pos":[12730,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":179,"pos":[10350,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":193,"pos":[12730,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":195,"pos":[12730,605],"params":["Inherit","False","Constant","_Float35","Float 35","28","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":212,"pos":[10010,115],"params":["Inherit","False","Constant","_Float40","Float 40","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":226,"pos":[12730,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":257,"pos":[17710,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":259,"pos":[17710,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":290,"pos":[17710,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":629,"pos":[38210,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":631,"pos":[38210,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":632,"pos":[38210,115],"params":["Inherit","False","Constant","_Float134","Float 134","52","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":660,"pos":[38210,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":662,"pos":[38210,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":674,"pos":[38210,1340],"params":["Inherit","True","Property","_TextureSample35","Texture Sample 35","54","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":690,"pos":[38210,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":691,"pos":[38210,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":692,"pos":[38210,360],"params":["Inherit","False","Constant","_Float148","Float 148","56","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":707,"pos":[35830,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":723,"pos":[38210,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":740,"pos":[35490,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":754,"pos":[38210,2565],"params":["Inherit","True","Property","_TextureSample40","Texture Sample 40","59","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":785,"pos":[43190,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":787,"pos":[43190,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":808,"pos":[42170,360],"params":["Inherit","False","Constant","_Float175","Float 175","62","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1428571","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":818,"pos":[43190,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":851,"pos":[43190,115],"params":["Inherit","False","Constant","_Float185","Float 185","65","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1155,"pos":[63010,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1167,"pos":[63010,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1185,"pos":[63010,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1186,"pos":[63010,115],"params":["Inherit","False","Constant","_Float261","Float 261","84","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1188,"pos":[63010,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1200,"pos":[60970,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1213,"pos":[63010,360],"params":["Inherit","False","Constant","_Float266","Float 266","86","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1216,"pos":[63010,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1233,"pos":[60630,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1247,"pos":[63010,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1249,"pos":[63010,605],"params":["Inherit","False","Constant","_Float275","Float 275","88","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1266,"pos":[60290,115],"params":["Inherit","False","Constant","_Float280","Float 280","88","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1280,"pos":[63010,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1311,"pos":[67990,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1313,"pos":[67990,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1344,"pos":[67990,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1719,"pos":[12730,2565],"params":["Inherit","False","1718","ase_SwizzleNode_1718","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1721,"pos":[12730,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1722,"pos":[12730,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1737,"pos":[12730,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1745,"pos":[12730,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1752,"pos":[12730,2810],"params":["Inherit","False","1742","ase_n141_1742","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1753,"pos":[12730,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1761,"pos":[10350,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1775,"pos":[10010,2320],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1776,"pos":[10010,1340],"params":["Inherit","False","ase_n211_1776","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1802,"pos":[17710,850],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1804,"pos":[17710,1340],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1817,"pos":[17710,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2020,"pos":[38210,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2042,"pos":[35490,1830],"params":["Inherit","False","2041","ase_n738_2041","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2083,"pos":[43190,2810],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2085,"pos":[43190,4035],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2098,"pos":[43190,3545],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2251,"pos":[63010,2075],"params":["Inherit","False","2250","ase_SwizzleNode_2250","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2252,"pos":[63010,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2253,"pos":[63010,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2267,"pos":[63010,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2275,"pos":[63010,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2282,"pos":[63010,2810],"params":["Inherit","False","2272","ase_n1195_2272","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2283,"pos":[63010,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2291,"pos":[60630,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2305,"pos":[60290,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2306,"pos":[60290,1095],"params":["Inherit","False","ase_n1265_2306","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2332,"pos":[67990,1095],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2334,"pos":[67990,2075],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2347,"pos":[67990,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2499,"pos":[38210,1095],"params":["Inherit","False","1985","ase_SwizzleNode_1985","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":102,"pos":[13070,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":104,"pos":[13070,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":105,"pos":[13070,115],"params":["Inherit","False","Constant","_Float14","Float 14","22","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":133,"pos":[13070,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":135,"pos":[13070,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":147,"pos":[13070,1095],"params":["Inherit","True","Property","_TextureSample5","Texture Sample 5","24","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":163,"pos":[13070,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":164,"pos":[13070,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":165,"pos":[13070,360],"params":["Inherit","False","Constant","_Float28","Float 28","26","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":180,"pos":[10690,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":196,"pos":[13070,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":213,"pos":[10350,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":227,"pos":[13070,2565],"params":["Inherit","True","Property","_TextureSample10","Texture Sample 10","29","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":258,"pos":[18050,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":260,"pos":[18050,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":281,"pos":[17030,360],"params":["Inherit","False","Constant","_Float55","Float 55","32","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1428571","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":291,"pos":[18050,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":324,"pos":[18050,115],"params":["Inherit","False","Constant","_Float65","Float 65","35","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":630,"pos":[38550,1585],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":663,"pos":[38550,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":675,"pos":[38550,2320],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":693,"pos":[38550,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":694,"pos":[38550,115],"params":["Inherit","False","Constant","_Float149","Float 149","56","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":696,"pos":[38550,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":708,"pos":[36170,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":721,"pos":[38550,360],"params":["Inherit","False","Constant","_Float154","Float 154","58","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":724,"pos":[38550,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":741,"pos":[35830,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":755,"pos":[38550,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":757,"pos":[38550,605],"params":["Inherit","False","Constant","_Float163","Float 163","60","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":774,"pos":[42170,115],"params":["Inherit","False","Constant","_Float168","Float 168","60","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":788,"pos":[43530,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":819,"pos":[43530,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":821,"pos":[43530,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":852,"pos":[43530,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1156,"pos":[63350,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1158,"pos":[63350,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1159,"pos":[63350,115],"params":["Inherit","False","Constant","_Float254","Float 254","82","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1187,"pos":[63350,1095],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1189,"pos":[63350,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1201,"pos":[63350,1340],"params":["Inherit","True","Property","_TextureSample65","Texture Sample 65","84","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1217,"pos":[63350,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1218,"pos":[63350,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1219,"pos":[63350,360],"params":["Inherit","False","Constant","_Float268","Float 268","86","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1234,"pos":[60970,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1250,"pos":[63350,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1267,"pos":[60630,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1281,"pos":[63350,2565],"params":["Inherit","True","Property","_TextureSample70","Texture Sample 70","89","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1312,"pos":[68330,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1314,"pos":[68330,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1335,"pos":[67310,360],"params":["Inherit","False","Constant","_Float295","Float 295","92","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1428571","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1345,"pos":[68330,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1378,"pos":[68330,115],"params":["Inherit","False","Constant","_Float305","Float 305","95","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1755,"pos":[13070,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1777,"pos":[10350,1585],"params":["Inherit","False","1776","ase_n211_1776","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1818,"pos":[18050,2810],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1820,"pos":[18050,3790],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1833,"pos":[18050,3545],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2004,"pos":[38550,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2005,"pos":[38550,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2019,"pos":[38550,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2027,"pos":[38550,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2034,"pos":[38550,2075],"params":["Inherit","False","2024","ase_n703_2024","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2035,"pos":[38550,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2043,"pos":[35830,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2057,"pos":[42170,1095],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2058,"pos":[42170,605],"params":["Inherit","False","ase_n773_2058","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2084,"pos":[43530,850],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2086,"pos":[43530,1095],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2099,"pos":[43530,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2285,"pos":[63350,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2307,"pos":[60630,1095],"params":["Inherit","False","2306","ase_n1265_2306","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2348,"pos":[68330,3055],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2350,"pos":[68330,4035],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2363,"pos":[68330,3790],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2498,"pos":[13070,1340],"params":["Inherit","False","1718","ase_SwizzleNode_1718","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2500,"pos":[63350,850],"params":["Inherit","False","2250","ase_SwizzleNode_2250","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":103,"pos":[13410,2565],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":136,"pos":[13410,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":148,"pos":[13410,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":166,"pos":[13410,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":167,"pos":[13410,115],"params":["Inherit","False","Constant","_Float29","Float 29","26","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":169,"pos":[13410,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":181,"pos":[11030,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":194,"pos":[13410,360],"params":["Inherit","False","Constant","_Float34","Float 34","28","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":197,"pos":[13410,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":214,"pos":[10690,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":228,"pos":[13410,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":230,"pos":[13410,605],"params":["Inherit","False","Constant","_Float43","Float 43","30","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":247,"pos":[17030,115],"params":["Inherit","False","Constant","_Float48","Float 48","30","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":261,"pos":[18390,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":292,"pos":[18390,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":294,"pos":[18390,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":325,"pos":[18390,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":664,"pos":[38890,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":666,"pos":[38890,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":667,"pos":[38890,115],"params":["Inherit","False","Constant","_Float142","Float 142","54","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":695,"pos":[38890,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":697,"pos":[38890,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":709,"pos":[38890,1095],"params":["Inherit","True","Property","_TextureSample37","Texture Sample 37","56","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":725,"pos":[38890,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":726,"pos":[38890,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":727,"pos":[38890,360],"params":["Inherit","False","Constant","_Float156","Float 156","58","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":742,"pos":[36170,360],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":758,"pos":[38890,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":775,"pos":[42510,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":789,"pos":[43870,2810],"params":["Inherit","True","Property","_TextureSample42","Texture Sample 42","61","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":820,"pos":[43870,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":822,"pos":[43870,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":843,"pos":[42510,605],"params":["Inherit","False","Constant","_Float183","Float 183","64","0","Create","True","0","0","0","False","0","False","Object","-1","","0.125","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":853,"pos":[43870,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":886,"pos":[43870,115],"params":["Inherit","False","Constant","_Float193","Float 193","67","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1157,"pos":[63690,1585],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1190,"pos":[63690,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1202,"pos":[63690,2320],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1220,"pos":[63690,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1221,"pos":[63690,115],"params":["Inherit","False","Constant","_Float269","Float 269","86","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1223,"pos":[63690,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1235,"pos":[61310,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1248,"pos":[63690,360],"params":["Inherit","False","Constant","_Float274","Float 274","88","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1251,"pos":[63690,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1268,"pos":[60970,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1282,"pos":[63690,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1284,"pos":[63690,605],"params":["Inherit","False","Constant","_Float283","Float 283","90","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1301,"pos":[67310,115],"params":["Inherit","False","Constant","_Float288","Float 288","90","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1315,"pos":[68670,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1346,"pos":[68670,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1348,"pos":[68670,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1379,"pos":[68670,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1739,"pos":[13410,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1740,"pos":[13410,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1754,"pos":[13410,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1762,"pos":[13410,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1769,"pos":[13410,2075],"params":["Inherit","False","1759","ase_n176_1759","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1770,"pos":[13410,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1778,"pos":[10690,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1792,"pos":[17030,1095],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1793,"pos":[17030,605],"params":["Inherit","False","ase_n246_1793","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1819,"pos":[18390,360],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1821,"pos":[18390,1095],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1834,"pos":[18390,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2037,"pos":[38890,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2059,"pos":[42510,1340],"params":["Inherit","False","2058","ase_n773_2058","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2100,"pos":[43870,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2102,"pos":[43870,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2115,"pos":[43870,2565],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2269,"pos":[63690,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2270,"pos":[63690,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2284,"pos":[63690,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2292,"pos":[63690,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2299,"pos":[63690,2075],"params":["Inherit","False","2289","ase_n1230_2289","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2300,"pos":[63690,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2308,"pos":[60970,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2322,"pos":[67310,1095],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2323,"pos":[67310,605],"params":["Inherit","False","ase_n1300_2323","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2349,"pos":[68670,850],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2351,"pos":[68670,1585],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2364,"pos":[68670,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":137,"pos":[13750,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":139,"pos":[13750,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":140,"pos":[13750,115],"params":["Inherit","False","Constant","_Float22","Float 22","24","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":168,"pos":[13750,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":170,"pos":[13750,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":182,"pos":[13750,1095],"params":["Inherit","True","Property","_TextureSample7","Texture Sample 7","26","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":198,"pos":[13750,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":199,"pos":[13750,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":200,"pos":[13750,360],"params":["Inherit","False","Constant","_Float36","Float 36","28","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":215,"pos":[11030,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":231,"pos":[13750,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":248,"pos":[17370,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":262,"pos":[18730,2810],"params":["Inherit","True","Property","_TextureSample12","Texture Sample 12","31","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":293,"pos":[18730,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":295,"pos":[18730,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":316,"pos":[17370,605],"params":["Inherit","False","Constant","_Float63","Float 63","34","0","Create","True","0","0","0","False","0","False","Object","-1","","0.125","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":326,"pos":[18730,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":359,"pos":[18730,115],"params":["Inherit","False","Constant","_Float73","Float 73","37","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":665,"pos":[39230,2565],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":698,"pos":[39230,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":710,"pos":[39230,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":728,"pos":[39230,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":729,"pos":[39230,115],"params":["Inherit","False","Constant","_Float157","Float 157","58","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":731,"pos":[39230,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":743,"pos":[36510,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":756,"pos":[39230,360],"params":["Inherit","False","Constant","_Float162","Float 162","60","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":759,"pos":[39230,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":776,"pos":[42850,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":790,"pos":[44210,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":792,"pos":[44210,115],"params":["Inherit","False","Constant","_Float171","Float 171","62","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":809,"pos":[42510,115],"params":["Inherit","False","Constant","_Float176","Float 176","62","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":823,"pos":[44210,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":854,"pos":[44210,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":856,"pos":[44210,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":887,"pos":[44210,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1191,"pos":[64030,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1193,"pos":[64030,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1194,"pos":[64030,115],"params":["Inherit","False","Constant","_Float262","Float 262","84","0","Create","True","0","0","0","False","0","False","Object","-1","","2","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1222,"pos":[64030,1095],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1224,"pos":[64030,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1236,"pos":[64030,850],"params":["Inherit","True","Property","_TextureSample67","Texture Sample 67","86","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1252,"pos":[64030,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1253,"pos":[64030,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1254,"pos":[64030,360],"params":["Inherit","False","Constant","_Float276","Float 276","88","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1269,"pos":[61310,360],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1285,"pos":[64030,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1302,"pos":[67650,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1316,"pos":[69010,2565],"params":["Inherit","True","Property","_TextureSample72","Texture Sample 72","91","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1347,"pos":[69010,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1349,"pos":[69010,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1370,"pos":[67650,605],"params":["Inherit","False","Constant","_Float303","Float 303","94","0","Create","True","0","0","0","False","0","False","Object","-1","","0.125","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1380,"pos":[69010,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1413,"pos":[69010,115],"params":["Inherit","False","Constant","_Float313","Float 313","97","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1772,"pos":[13750,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1794,"pos":[17370,1340],"params":["Inherit","False","1793","ase_n246_1793","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1835,"pos":[18730,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1837,"pos":[18730,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1850,"pos":[18730,2565],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2021,"pos":[39230,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2022,"pos":[39230,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2036,"pos":[39230,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2044,"pos":[39230,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2051,"pos":[39230,1830],"params":["Inherit","False","2041","ase_n738_2041","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2052,"pos":[39230,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2060,"pos":[42850,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2061,"pos":[36850,2810],"params":["Inherit","False","ase_SimpleAddOpNode_2061","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2076,"pos":[42510,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2077,"pos":[42510,850],"params":["Inherit","False","ase_n808_2077","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2101,"pos":[44210,850],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2103,"pos":[44210,1340],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2116,"pos":[44210,360],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2302,"pos":[64030,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2324,"pos":[67650,1340],"params":["Inherit","False","2323","ase_n1300_2323","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2365,"pos":[69010,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2367,"pos":[69010,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2380,"pos":[69010,2810],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":138,"pos":[14090,2810],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":171,"pos":[14090,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":183,"pos":[14090,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":201,"pos":[14090,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":202,"pos":[14090,115],"params":["Inherit","False","Constant","_Float37","Float 37","28","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":204,"pos":[14090,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":216,"pos":[11370,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":229,"pos":[14090,360],"params":["Inherit","False","Constant","_Float42","Float 42","30","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":232,"pos":[14090,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":249,"pos":[17710,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":263,"pos":[19070,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":265,"pos":[19070,115],"params":["Inherit","False","Constant","_Float51","Float 51","32","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":282,"pos":[17370,115],"params":["Inherit","False","Constant","_Float56","Float 56","32","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":296,"pos":[19070,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":327,"pos":[19070,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":329,"pos":[19070,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":360,"pos":[19070,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":699,"pos":[39570,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":701,"pos":[39570,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":702,"pos":[39570,115],"params":["Inherit","False","Constant","_Float150","Float 150","56","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":730,"pos":[39570,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":732,"pos":[39570,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":744,"pos":[39570,1095],"params":["Inherit","True","Property","_TextureSample39","Texture Sample 39","58","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":760,"pos":[39570,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":761,"pos":[39570,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":762,"pos":[39570,360],"params":["Inherit","False","Constant","_Float164","Float 164","60","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":777,"pos":[43190,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":793,"pos":[44550,1095],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":810,"pos":[42850,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":824,"pos":[44550,1340],"params":["Inherit","True","Property","_TextureSample44","Texture Sample 44","63","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":855,"pos":[44550,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":857,"pos":[44550,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":878,"pos":[42850,360],"params":["Inherit","False","Constant","_Float191","Float 191","66","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1111111","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":888,"pos":[44550,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":921,"pos":[44550,115],"params":["Inherit","False","Constant","_Float201","Float 201","69","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1192,"pos":[64370,2320],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1225,"pos":[64370,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1237,"pos":[64370,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1255,"pos":[64370,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1256,"pos":[64370,115],"params":["Inherit","False","Constant","_Float277","Float 277","88","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1258,"pos":[64370,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1270,"pos":[61650,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1283,"pos":[64370,360],"params":["Inherit","False","Constant","_Float282","Float 282","90","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1286,"pos":[64370,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1303,"pos":[67990,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1317,"pos":[69350,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1319,"pos":[69350,115],"params":["Inherit","False","Constant","_Float291","Float 291","92","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1336,"pos":[67650,115],"params":["Inherit","False","Constant","_Float296","Float 296","92","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1350,"pos":[69350,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1381,"pos":[69350,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1383,"pos":[69350,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1414,"pos":[69350,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1756,"pos":[14090,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1757,"pos":[14090,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1771,"pos":[14090,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1779,"pos":[14090,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1786,"pos":[14090,2075],"params":["Inherit","False","1776","ase_n211_1776","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1787,"pos":[14090,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1795,"pos":[17710,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1796,"pos":[11710,3055],"params":["Inherit","False","ase_SimpleAddOpNode_1796","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1811,"pos":[17370,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1812,"pos":[17370,850],"params":["Inherit","False","ase_n281_1812","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1836,"pos":[19070,360],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1838,"pos":[19070,1340],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1851,"pos":[19070,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2054,"pos":[39570,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2062,"pos":[43190,3790],"params":["Inherit","False","2061","ase_SimpleAddOpNode_2061","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2078,"pos":[42850,2320],"params":["Inherit","False","2077","ase_n808_2077","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2117,"pos":[44550,1585],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2119,"pos":[44550,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2132,"pos":[44550,2320],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2286,"pos":[64370,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2287,"pos":[64370,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2301,"pos":[64370,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2309,"pos":[64370,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2316,"pos":[64370,1830],"params":["Inherit","False","2306","ase_n1265_2306","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2317,"pos":[64370,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2325,"pos":[67990,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2326,"pos":[61990,2075],"params":["Inherit","False","ase_SimpleAddOpNode_2326","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2341,"pos":[67650,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2342,"pos":[67650,850],"params":["Inherit","False","ase_n1335_2342","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2366,"pos":[69350,1095],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2368,"pos":[69350,1585],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2381,"pos":[69350,360],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":172,"pos":[14430,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":174,"pos":[14430,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":175,"pos":[14430,115],"params":["Inherit","False","Constant","_Float30","Float 30","26","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":203,"pos":[14430,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":205,"pos":[14430,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":217,"pos":[14430,1095],"params":["Inherit","True","Property","_TextureSample9","Texture Sample 9","28","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":233,"pos":[14430,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":234,"pos":[14430,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":235,"pos":[14430,360],"params":["Inherit","False","Constant","_Float44","Float 44","30","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":250,"pos":[18050,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":266,"pos":[19410,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":283,"pos":[17710,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":297,"pos":[19410,1095],"params":["Inherit","True","Property","_TextureSample14","Texture Sample 14","33","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":328,"pos":[19410,360],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":330,"pos":[19410,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":351,"pos":[17710,360],"params":["Inherit","False","Constant","_Float71","Float 71","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1111111","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":361,"pos":[19410,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":394,"pos":[19410,115],"params":["Inherit","False","Constant","_Float81","Float 81","39","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":700,"pos":[39910,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":733,"pos":[39910,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":745,"pos":[39910,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":763,"pos":[39910,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":764,"pos":[39910,115],"params":["Inherit","False","Constant","_Float165","Float 165","60","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":766,"pos":[39910,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":778,"pos":[43530,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":791,"pos":[44890,115],"params":["Inherit","False","Constant","_Float170","Float 170","62","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":794,"pos":[44890,1830],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":811,"pos":[43190,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":825,"pos":[44890,2565],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":827,"pos":[44890,360],"params":["Inherit","False","Constant","_Float179","Float 179","64","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":844,"pos":[42850,115],"params":["Inherit","False","Constant","_Float184","Float 184","64","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":858,"pos":[44890,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":889,"pos":[44890,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":891,"pos":[44890,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":922,"pos":[44890,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1226,"pos":[64710,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1228,"pos":[64710,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1229,"pos":[64710,115],"params":["Inherit","False","Constant","_Float270","Float 270","86","0","Create","True","0","0","0","False","0","False","Object","-1","","3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1257,"pos":[64710,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1259,"pos":[64710,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1271,"pos":[64710,1095],"params":["Inherit","True","Property","_TextureSample69","Texture Sample 69","88","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1287,"pos":[64710,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1288,"pos":[64710,2075],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1289,"pos":[64710,360],"params":["Inherit","False","Constant","_Float284","Float 284","90","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1304,"pos":[68330,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1320,"pos":[69690,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1337,"pos":[67990,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1351,"pos":[69690,1830],"params":["Inherit","True","Property","_TextureSample74","Texture Sample 74","93","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1382,"pos":[69690,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1384,"pos":[69690,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1405,"pos":[67990,360],"params":["Inherit","False","Constant","_Float311","Float 311","96","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1111111","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1415,"pos":[69690,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1448,"pos":[69690,115],"params":["Inherit","False","Constant","_Float321","Float 321","99","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1789,"pos":[14430,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1797,"pos":[18050,4035],"params":["Inherit","False","1796","ase_SimpleAddOpNode_1796","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1813,"pos":[17710,2320],"params":["Inherit","False","1812","ase_n281_1812","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1852,"pos":[19410,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1854,"pos":[19410,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1867,"pos":[19410,2320],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2038,"pos":[39910,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2039,"pos":[39910,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2053,"pos":[39910,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2063,"pos":[44890,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2070,"pos":[44890,1340],"params":["Inherit","False","2058","ase_n773_2058","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2071,"pos":[44890,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2079,"pos":[43190,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2093,"pos":[42850,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2094,"pos":[42850,1585],"params":["Inherit","False","ase_n843_2094","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2118,"pos":[44890,1095],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2120,"pos":[44890,1585],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2133,"pos":[44890,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2319,"pos":[64710,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2327,"pos":[68330,3300],"params":["Inherit","False","2326","ase_SimpleAddOpNode_2326","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2343,"pos":[67990,2320],"params":["Inherit","False","2342","ase_n1335_2342","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2382,"pos":[69690,1585],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2384,"pos":[69690,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2397,"pos":[69690,2320],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":173,"pos":[14770,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":206,"pos":[14770,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":218,"pos":[14770,1095],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":236,"pos":[14770,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":237,"pos":[14770,115],"params":["Inherit","False","Constant","_Float45","Float 45","30","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":239,"pos":[14770,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":251,"pos":[18390,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":264,"pos":[19750,115],"params":["Inherit","False","Constant","_Float50","Float 50","32","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":267,"pos":[19750,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":284,"pos":[18050,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":298,"pos":[19750,2075],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":300,"pos":[19750,360],"params":["Inherit","False","Constant","_Float59","Float 59","34","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":317,"pos":[17710,115],"params":["Inherit","False","Constant","_Float64","Float 64","34","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":331,"pos":[19750,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":362,"pos":[19750,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":364,"pos":[19750,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":395,"pos":[19750,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":734,"pos":[40250,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":736,"pos":[40250,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":737,"pos":[40250,115],"params":["Inherit","False","Constant","_Float158","Float 158","58","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":765,"pos":[40250,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":767,"pos":[40250,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":779,"pos":[45230,1095],"params":["Inherit","True","Property","_TextureSample41","Texture Sample 41","60","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":795,"pos":[45230,605],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":796,"pos":[45230,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":797,"pos":[45230,115],"params":["Inherit","False","Constant","_Float172","Float 172","62","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":812,"pos":[43530,2320],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":828,"pos":[45230,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":845,"pos":[43190,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":859,"pos":[45230,2075],"params":["Inherit","True","Property","_TextureSample46","Texture Sample 46","65","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":890,"pos":[45230,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":892,"pos":[45230,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":913,"pos":[43190,605],"params":["Inherit","False","Constant","_Float199","Float 199","68","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":923,"pos":[45230,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":956,"pos":[50210,115],"params":["Inherit","False","Constant","_Float209","Float 209","71","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1227,"pos":[65050,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1260,"pos":[65050,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1272,"pos":[65050,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1290,"pos":[65050,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1291,"pos":[65050,115],"params":["Inherit","False","Constant","_Float285","Float 285","90","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1293,"pos":[65050,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1305,"pos":[68670,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1318,"pos":[70030,115],"params":["Inherit","False","Constant","_Float290","Float 290","92","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1321,"pos":[70030,2320],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1338,"pos":[68330,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1352,"pos":[70030,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1354,"pos":[70030,360],"params":["Inherit","False","Constant","_Float299","Float 299","94","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1371,"pos":[67990,115],"params":["Inherit","False","Constant","_Float304","Float 304","94","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1385,"pos":[70030,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1416,"pos":[70030,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1418,"pos":[70030,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1449,"pos":[70030,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1773,"pos":[14770,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1774,"pos":[14770,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1788,"pos":[14770,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1798,"pos":[19750,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1805,"pos":[19750,1340],"params":["Inherit","False","1793","ase_n246_1793","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1806,"pos":[19750,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1814,"pos":[18050,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1828,"pos":[17710,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1829,"pos":[17710,1585],"params":["Inherit","False","ase_n316_1829","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1853,"pos":[19750,850],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1855,"pos":[19750,1585],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1868,"pos":[19750,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2073,"pos":[45230,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2095,"pos":[43190,3055],"params":["Inherit","False","2094","ase_n843_2094","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2134,"pos":[45230,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2136,"pos":[45230,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2151,"pos":[50210,605],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2303,"pos":[65050,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2304,"pos":[65050,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2318,"pos":[65050,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2328,"pos":[70030,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2335,"pos":[70030,1095],"params":["Inherit","False","2323","ase_n1300_2323","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2336,"pos":[70030,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2344,"pos":[68330,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2358,"pos":[67990,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2359,"pos":[67990,1340],"params":["Inherit","False","ase_n1370_2359","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2383,"pos":[70030,1340],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2385,"pos":[70030,1830],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2398,"pos":[70030,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2513,"pos":[75300,15],"params":["Inherit","False","8160","5720","保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。","261","1475","1476","1477","1478","1479","1480","1481","1482","1483","1484","1485","1486","1487","1488","1489","1490","1491","1492","1493","1494","1495","1496","1497","1498","1499","1500","1501","1502","1503","1504","1505","1506","1507","1508","1509","1510","1511","1512","1513","1514","1515","1516","1517","1518","1519","1520","1521","1522","1523","1524","1525","1526","1527","1528","1529","1530","1531","1532","1533","1534","1535","1536","1537","1538","1539","1540","1541","1542","1543","1544","1545","1546","1547","1548","1549","1550","1551","1552","1553","1554","1555","1556","1557","1558","1559","1560","1561","1562","1563","1564","1565","1566","1567","1568","1569","1570","1571","1572","1573","1574","1575","1576","1577","1578","1579","1580","1581","1582","1583","1584","1585","1586","1587","1588","1589","1590","1591","1592","1593","1594","1595","1596","1597","1598","1599","1600","1601","1602","1603","1604","1605","1606","1607","1608","1609","1610","1611","1612","1613","1614","1615","1616","1617","1618","1619","1620","1621","1622","1623","1624","1625","1626","1627","1628","1629","1630","1631","1632","1633","1634","1635","1636","1637","1638","1639","1640","1641","1642","1643","1644","1645","1646","1647","1648","1649","2409","2410","2411","2412","2414","2415","2416","2417","2418","2419","2420","2421","2422","2423","2424","2425","2426","2427","2428","2429","2430","2431","2432","2433","2434","2435","2436","2437","2438","2439","2440","2441","2442","2443","2444","2445","2446","2447","2448","2449","2450","2451","2452","2453","2454","2455","2456","2457","2458","2459","2460","2461","2462","2463","2464","2465","2466","2467","2468","2469","2470","2471","2472","2473","2474","2475","2476","2477","2478","2479","2480","2481","2482","2483","2484","2485","2486","2487","2488","2489","2490","2491","2492","2493","2494","2495","05 第3层 · 迭代 11–15","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":207,"pos":[15110,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":209,"pos":[15110,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":210,"pos":[15110,115],"params":["Inherit","False","Constant","_Float38","Float 38","28","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":238,"pos":[15110,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":240,"pos":[15110,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":252,"pos":[20090,1585],"params":["Inherit","True","Property","_TextureSample11","Texture Sample 11","30","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":268,"pos":[20090,1095],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":269,"pos":[20090,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":270,"pos":[20090,115],"params":["Inherit","False","Constant","_Float52","Float 52","32","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":285,"pos":[18390,2320],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":301,"pos":[20090,850],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":318,"pos":[18050,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":332,"pos":[20090,1340],"params":["Inherit","True","Property","_TextureSample16","Texture Sample 16","35","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":363,"pos":[20090,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":365,"pos":[20090,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":386,"pos":[18050,605],"params":["Inherit","False","Constant","_Float79","Float 79","38","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":396,"pos":[20090,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":429,"pos":[25070,115],"params":["Inherit","False","Constant","_Float89","Float 89","41","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":735,"pos":[40590,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":768,"pos":[40590,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":780,"pos":[45570,2320],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":798,"pos":[45570,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":799,"pos":[45570,115],"params":["Inherit","False","Constant","_Float173","Float 173","62","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":801,"pos":[45570,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":813,"pos":[43870,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":826,"pos":[45570,360],"params":["Inherit","False","Constant","_Float178","Float 178","64","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":829,"pos":[45570,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":846,"pos":[43530,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":860,"pos":[45570,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":862,"pos":[45570,605],"params":["Inherit","False","Constant","_Float187","Float 187","66","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":879,"pos":[43190,360],"params":["Inherit","False","Constant","_Float192","Float 192","66","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":893,"pos":[45570,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":924,"pos":[45570,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":926,"pos":[45570,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":957,"pos":[50550,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1261,"pos":[65390,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1263,"pos":[65390,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1264,"pos":[65390,115],"params":["Inherit","False","Constant","_Float278","Float 278","88","0","Create","True","0","0","0","False","0","False","Object","-1","","4","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1292,"pos":[65390,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1294,"pos":[65390,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1306,"pos":[70370,605],"params":["Inherit","True","Property","_TextureSample71","Texture Sample 71","90","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1322,"pos":[70370,850],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1323,"pos":[70370,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1324,"pos":[70370,115],"params":["Inherit","False","Constant","_Float292","Float 292","92","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1339,"pos":[68670,2320],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1355,"pos":[70370,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1372,"pos":[68330,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1386,"pos":[70370,2320],"params":["Inherit","True","Property","_TextureSample76","Texture Sample 76","95","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1417,"pos":[70370,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1419,"pos":[70370,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1440,"pos":[68330,605],"params":["Inherit","False","Constant","_Float319","Float 319","98","0","Create","True","0","0","0","False","0","False","Object","-1","","0.1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1450,"pos":[70370,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1483,"pos":[75350,115],"params":["Inherit","False","Constant","_Float329","Float 329","101","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1808,"pos":[20090,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1830,"pos":[18050,3055],"params":["Inherit","False","1829","ase_n316_1829","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1869,"pos":[20090,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1871,"pos":[20090,2810],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1886,"pos":[25070,605],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2055,"pos":[40590,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2056,"pos":[40590,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2072,"pos":[45570,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2080,"pos":[45570,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2087,"pos":[45570,2075],"params":["Inherit","False","2077","ase_n808_2077","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2088,"pos":[45570,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2096,"pos":[43530,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2110,"pos":[43190,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2111,"pos":[43190,1095],"params":["Inherit","False","ase_n878_2111","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2135,"pos":[45570,1340],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2137,"pos":[45570,1830],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2152,"pos":[50550,115],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2338,"pos":[70370,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2360,"pos":[68330,2320],"params":["Inherit","False","2359","ase_n1370_2359","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2399,"pos":[70370,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2401,"pos":[70370,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2416,"pos":[75350,360],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":208,"pos":[15450,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":241,"pos":[15450,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":253,"pos":[20430,3300],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":271,"pos":[20430,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":272,"pos":[20430,115],"params":["Inherit","False","Constant","_Float53","Float 53","32","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":274,"pos":[20430,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":286,"pos":[18730,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":299,"pos":[20430,360],"params":["Inherit","False","Constant","_Float58","Float 58","34","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":302,"pos":[20430,2075],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":319,"pos":[18390,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":333,"pos":[20430,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":335,"pos":[20430,605],"params":["Inherit","False","Constant","_Float67","Float 67","36","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":352,"pos":[18050,360],"params":["Inherit","False","Constant","_Float72","Float 72","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":366,"pos":[20430,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":397,"pos":[20430,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":399,"pos":[20430,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":430,"pos":[25410,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":769,"pos":[40930,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":771,"pos":[40930,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":772,"pos":[40930,115],"params":["Inherit","False","Constant","_Float166","Float 166","60","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":800,"pos":[45910,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":802,"pos":[45910,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":814,"pos":[45910,850],"params":["Inherit","True","Property","_TextureSample43","Texture Sample 43","62","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":830,"pos":[45910,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":831,"pos":[45910,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":832,"pos":[45910,115],"params":["Inherit","False","Constant","_Float180","Float 180","64","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":847,"pos":[43870,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":863,"pos":[45910,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":880,"pos":[43530,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":894,"pos":[45910,2075],"params":["Inherit","True","Property","_TextureSample48","Texture Sample 48","67","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":925,"pos":[45910,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":927,"pos":[45910,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":948,"pos":[50890,115],"params":["Inherit","False","Constant","_Float207","Float 207","70","0","Create","True","0","0","0","False","0","False","Object","-1","","0.09090909","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":958,"pos":[50890,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":991,"pos":[50890,360],"params":["Inherit","False","Constant","_Float217","Float 217","73","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1262,"pos":[65730,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1295,"pos":[65730,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1307,"pos":[70710,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1325,"pos":[70710,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1326,"pos":[70710,115],"params":["Inherit","False","Constant","_Float293","Float 293","92","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1328,"pos":[70710,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1340,"pos":[69010,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1353,"pos":[70710,360],"params":["Inherit","False","Constant","_Float298","Float 298","94","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1356,"pos":[70710,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1373,"pos":[68670,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1387,"pos":[70710,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1389,"pos":[70710,605],"params":["Inherit","False","Constant","_Float307","Float 307","96","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1406,"pos":[68330,360],"params":["Inherit","False","Constant","_Float312","Float 312","96","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1420,"pos":[70710,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1451,"pos":[70710,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1453,"pos":[70710,3790],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1484,"pos":[75690,360],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1790,"pos":[15450,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1791,"pos":[15450,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1807,"pos":[20430,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1815,"pos":[20430,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1822,"pos":[20430,2320],"params":["Inherit","False","1812","ase_n281_1812","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1823,"pos":[20430,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1831,"pos":[18390,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1845,"pos":[18050,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1846,"pos":[18050,1095],"params":["Inherit","False","ase_n351_1846","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1870,"pos":[20430,1340],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1872,"pos":[20430,1585],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1887,"pos":[25410,115],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2090,"pos":[45910,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2112,"pos":[43530,1830],"params":["Inherit","False","2111","ase_n878_2111","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2153,"pos":[50890,1095],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2155,"pos":[50890,1585],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2168,"pos":[50890,1340],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2320,"pos":[65730,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2321,"pos":[65730,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2337,"pos":[70710,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2345,"pos":[70710,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2352,"pos":[70710,2075],"params":["Inherit","False","2342","ase_n1335_2342","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2353,"pos":[70710,4035],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2361,"pos":[68670,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2375,"pos":[68330,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2376,"pos":[68330,1095],"params":["Inherit","False","ase_n1405_2376","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2400,"pos":[70710,1585],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2402,"pos":[70710,2320],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2417,"pos":[75690,115],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":242,"pos":[15790,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":244,"pos":[15790,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":245,"pos":[15790,115],"params":["Inherit","False","Constant","_Float46","Float 46","30","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":273,"pos":[20770,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":275,"pos":[20770,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":287,"pos":[20770,1095],"params":["Inherit","True","Property","_TextureSample13","Texture Sample 13","32","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":303,"pos":[20770,850],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":304,"pos":[20770,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":305,"pos":[20770,115],"params":["Inherit","False","Constant","_Float60","Float 60","34","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":320,"pos":[18730,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":336,"pos":[20770,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":353,"pos":[18390,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":367,"pos":[20770,1830],"params":["Inherit","True","Property","_TextureSample18","Texture Sample 18","37","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":398,"pos":[20770,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":400,"pos":[20770,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":421,"pos":[25750,115],"params":["Inherit","False","Constant","_Float87","Float 87","40","0","Create","True","0","0","0","False","0","False","Object","-1","","0.09090909","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":431,"pos":[25750,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":464,"pos":[25750,360],"params":["Inherit","False","Constant","_Float97","Float 97","43","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":770,"pos":[41270,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":803,"pos":[46250,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":815,"pos":[46250,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":833,"pos":[46250,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":834,"pos":[46250,115],"params":["Inherit","False","Constant","_Float181","Float 181","64","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":836,"pos":[46250,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":848,"pos":[44210,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":861,"pos":[46250,360],"params":["Inherit","False","Constant","_Float186","Float 186","66","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":864,"pos":[46250,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":881,"pos":[43870,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":895,"pos":[46250,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":897,"pos":[46250,605],"params":["Inherit","False","Constant","_Float195","Float 195","68","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":914,"pos":[43530,115],"params":["Inherit","False","Constant","_Float200","Float 200","68","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":928,"pos":[46250,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":959,"pos":[51230,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":961,"pos":[51230,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":992,"pos":[51230,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1296,"pos":[66070,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1298,"pos":[66070,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1299,"pos":[66070,115],"params":["Inherit","False","Constant","_Float286","Float 286","90","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1327,"pos":[71050,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1329,"pos":[71050,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1341,"pos":[71050,850],"params":["Inherit","True","Property","_TextureSample73","Texture Sample 73","92","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1357,"pos":[71050,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1358,"pos":[71050,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1359,"pos":[71050,115],"params":["Inherit","False","Constant","_Float300","Float 300","94","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1374,"pos":[69010,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1390,"pos":[71050,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1407,"pos":[68670,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1421,"pos":[71050,2075],"params":["Inherit","True","Property","_TextureSample78","Texture Sample 78","97","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1452,"pos":[71050,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1454,"pos":[71050,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1475,"pos":[76030,115],"params":["Inherit","False","Constant","_Float327","Float 327","100","0","Create","True","0","0","0","False","0","False","Object","-1","","0.09090909","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1485,"pos":[76030,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1518,"pos":[76030,360],"params":["Inherit","False","Constant","_Float337","Float 337","103","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1825,"pos":[20770,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1847,"pos":[18390,1830],"params":["Inherit","False","1846","ase_n351_1846","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1888,"pos":[25750,1095],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1890,"pos":[25750,1585],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1903,"pos":[25750,1340],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2074,"pos":[46250,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2075,"pos":[46250,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2089,"pos":[46250,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2097,"pos":[46250,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2104,"pos":[46250,2565],"params":["Inherit","False","2094","ase_n843_2094","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2105,"pos":[46250,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2113,"pos":[43870,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2127,"pos":[43530,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2128,"pos":[43530,1340],"params":["Inherit","False","ase_n913_2128","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2154,"pos":[51230,360],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2156,"pos":[51230,605],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2169,"pos":[51230,115],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2355,"pos":[71050,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2377,"pos":[68670,1830],"params":["Inherit","False","2376","ase_n1405_2376","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2418,"pos":[76030,850],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2420,"pos":[76030,1340],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2433,"pos":[76030,1095],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":243,"pos":[16130,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":276,"pos":[21110,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":288,"pos":[21110,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":306,"pos":[21110,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":307,"pos":[21110,115],"params":["Inherit","False","Constant","_Float61","Float 61","34","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":309,"pos":[21110,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":321,"pos":[19070,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":334,"pos":[21110,360],"params":["Inherit","False","Constant","_Float66","Float 66","36","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":337,"pos":[21110,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":354,"pos":[18730,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":368,"pos":[21110,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":370,"pos":[21110,605],"params":["Inherit","False","Constant","_Float75","Float 75","38","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":387,"pos":[18390,115],"params":["Inherit","False","Constant","_Float80","Float 80","38","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":401,"pos":[21110,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":432,"pos":[26090,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":434,"pos":[26090,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":465,"pos":[26090,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":804,"pos":[46590,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":806,"pos":[46590,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":807,"pos":[46590,115],"params":["Inherit","False","Constant","_Float174","Float 174","62","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":835,"pos":[46590,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":837,"pos":[46590,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":849,"pos":[46590,1340],"params":["Inherit","True","Property","_TextureSample45","Texture Sample 45","64","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":865,"pos":[46590,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":866,"pos":[46590,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":867,"pos":[46590,360],"params":["Inherit","False","Constant","_Float188","Float 188","66","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":882,"pos":[44210,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":898,"pos":[46590,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":915,"pos":[43870,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":929,"pos":[46590,2075],"params":["Inherit","True","Property","_TextureSample50","Texture Sample 50","69","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":960,"pos":[51570,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":962,"pos":[51570,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":983,"pos":[51570,115],"params":["Inherit","False","Constant","_Float215","Float 215","72","0","Create","True","0","0","0","False","0","False","Object","-1","","0.08333334","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":993,"pos":[51570,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1026,"pos":[51570,360],"params":["Inherit","False","Constant","_Float225","Float 225","75","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1297,"pos":[66410,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1330,"pos":[71390,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1342,"pos":[71390,1830],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1360,"pos":[71390,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1361,"pos":[71390,115],"params":["Inherit","False","Constant","_Float301","Float 301","94","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1363,"pos":[71390,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1375,"pos":[69350,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1388,"pos":[71390,360],"params":["Inherit","False","Constant","_Float306","Float 306","96","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1391,"pos":[71390,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1408,"pos":[69010,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1422,"pos":[71390,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1424,"pos":[71390,605],"params":["Inherit","False","Constant","_Float315","Float 315","98","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1441,"pos":[68670,115],"params":["Inherit","False","Constant","_Float320","Float 320","98","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1455,"pos":[71390,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1486,"pos":[76370,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1488,"pos":[76370,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1519,"pos":[76370,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1809,"pos":[21110,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1810,"pos":[21110,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1824,"pos":[21110,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1832,"pos":[21110,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1839,"pos":[21110,2810],"params":["Inherit","False","1829","ase_n316_1829","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1840,"pos":[21110,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1848,"pos":[18730,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1862,"pos":[18390,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1863,"pos":[18390,1340],"params":["Inherit","False","ase_n386_1863","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1889,"pos":[26090,115],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1891,"pos":[26090,605],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1904,"pos":[26090,360],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2107,"pos":[46590,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2129,"pos":[43870,1830],"params":["Inherit","False","2128","ase_n913_2128","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2170,"pos":[51570,1340],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2172,"pos":[51570,1830],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2185,"pos":[51570,1585],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2339,"pos":[71390,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2340,"pos":[71390,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2354,"pos":[71390,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2362,"pos":[71390,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2369,"pos":[71390,2565],"params":["Inherit","False","2359","ase_n1370_2359","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2370,"pos":[71390,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2378,"pos":[69010,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2392,"pos":[68670,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2393,"pos":[68670,1095],"params":["Inherit","False","ase_n1440_2393","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2419,"pos":[76370,360],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2421,"pos":[76370,850],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2434,"pos":[76370,115],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":277,"pos":[21450,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":279,"pos":[21450,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":280,"pos":[21450,115],"params":["Inherit","False","Constant","_Float54","Float 54","32","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":308,"pos":[21450,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":310,"pos":[21450,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":322,"pos":[21450,1340],"params":["Inherit","True","Property","_TextureSample15","Texture Sample 15","34","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":338,"pos":[21450,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":339,"pos":[21450,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":340,"pos":[21450,360],"params":["Inherit","False","Constant","_Float68","Float 68","36","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":355,"pos":[19070,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":371,"pos":[21450,2075],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":388,"pos":[18730,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":402,"pos":[21450,2320],"params":["Inherit","True","Property","_TextureSample20","Texture Sample 20","39","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":433,"pos":[26430,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":435,"pos":[26430,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":456,"pos":[26430,115],"params":["Inherit","False","Constant","_Float95","Float 95","42","0","Create","True","0","0","0","False","0","False","Object","-1","","0.08333334","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":466,"pos":[26430,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":499,"pos":[26430,360],"params":["Inherit","False","Constant","_Float105","Float 105","45","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":805,"pos":[46930,1585],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":838,"pos":[46930,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":850,"pos":[46930,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":868,"pos":[46930,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":869,"pos":[46930,115],"params":["Inherit","False","Constant","_Float189","Float 189","66","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":871,"pos":[46930,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":883,"pos":[44550,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":896,"pos":[46930,360],"params":["Inherit","False","Constant","_Float194","Float 194","68","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":899,"pos":[46930,3300],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":916,"pos":[44210,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":930,"pos":[46930,3055],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":932,"pos":[46930,605],"params":["Inherit","False","Constant","_Float203","Float 203","70","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":949,"pos":[51910,115],"params":["Inherit","False","Constant","_Float208","Float 208","70","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":963,"pos":[51910,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":994,"pos":[51910,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":996,"pos":[51910,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1027,"pos":[51910,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1331,"pos":[71730,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1333,"pos":[71730,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1334,"pos":[71730,115],"params":["Inherit","False","Constant","_Float294","Float 294","92","0","Create","True","0","0","0","False","0","False","Object","-1","","6","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1362,"pos":[71730,1095],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1364,"pos":[71730,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1376,"pos":[71730,1340],"params":["Inherit","True","Property","_TextureSample75","Texture Sample 75","94","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1392,"pos":[71730,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1393,"pos":[71730,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1394,"pos":[71730,360],"params":["Inherit","False","Constant","_Float308","Float 308","96","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1409,"pos":[69350,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1425,"pos":[71730,2075],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1442,"pos":[69010,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1456,"pos":[71730,2320],"params":["Inherit","True","Property","_TextureSample80","Texture Sample 80","99","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1487,"pos":[76710,850],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1489,"pos":[76710,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1510,"pos":[76710,115],"params":["Inherit","False","Constant","_Float335","Float 335","102","0","Create","True","0","0","0","False","0","False","Object","-1","","0.08333334","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1520,"pos":[76710,605],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1553,"pos":[76710,360],"params":["Inherit","False","Constant","_Float345","Float 345","105","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1842,"pos":[21450,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1864,"pos":[18730,1830],"params":["Inherit","False","1863","ase_n386_1863","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1905,"pos":[26430,1340],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1907,"pos":[26430,1830],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1920,"pos":[26430,1585],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2091,"pos":[46930,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2092,"pos":[46930,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2106,"pos":[46930,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2114,"pos":[46930,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2121,"pos":[46930,2075],"params":["Inherit","False","2111","ase_n878_2111","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2122,"pos":[46930,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2130,"pos":[44210,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2144,"pos":[51910,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2145,"pos":[51910,360],"params":["Inherit","False","ase_n948_2145","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2171,"pos":[51910,850],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2173,"pos":[51910,1095],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2186,"pos":[51910,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2372,"pos":[71730,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2394,"pos":[69010,1095],"params":["Inherit","False","2393","ase_n1440_2393","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2435,"pos":[76710,1340],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2437,"pos":[76710,1830],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2450,"pos":[76710,1585],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":278,"pos":[21790,1585],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":311,"pos":[21790,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":323,"pos":[21790,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":341,"pos":[21790,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":342,"pos":[21790,115],"params":["Inherit","False","Constant","_Float69","Float 69","36","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":344,"pos":[21790,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":356,"pos":[19410,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":369,"pos":[21790,360],"params":["Inherit","False","Constant","_Float74","Float 74","38","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":372,"pos":[21790,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":389,"pos":[19070,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":403,"pos":[21790,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":405,"pos":[21790,605],"params":["Inherit","False","Constant","_Float83","Float 83","40","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":422,"pos":[26770,115],"params":["Inherit","False","Constant","_Float88","Float 88","40","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":436,"pos":[26770,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":467,"pos":[26770,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":469,"pos":[26770,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":500,"pos":[26770,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":839,"pos":[47270,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":841,"pos":[47270,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":842,"pos":[47270,115],"params":["Inherit","False","Constant","_Float182","Float 182","64","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":870,"pos":[47270,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":872,"pos":[47270,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":884,"pos":[47270,1095],"params":["Inherit","True","Property","_TextureSample47","Texture Sample 47","66","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":900,"pos":[47270,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":901,"pos":[47270,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":902,"pos":[47270,360],"params":["Inherit","False","Constant","_Float196","Float 196","68","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":917,"pos":[44550,360],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":933,"pos":[47270,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":950,"pos":[52250,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":964,"pos":[52250,1585],"params":["Inherit","True","Property","_TextureSample52","Texture Sample 52","71","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":995,"pos":[52250,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":997,"pos":[52250,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1018,"pos":[52250,115],"params":["Inherit","False","Constant","_Float223","Float 223","74","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07692308","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1028,"pos":[52250,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1061,"pos":[52250,360],"params":["Inherit","False","Constant","_Float233","Float 233","77","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1332,"pos":[72070,1585],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1365,"pos":[72070,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1377,"pos":[72070,2320],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1395,"pos":[72070,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1396,"pos":[72070,115],"params":["Inherit","False","Constant","_Float309","Float 309","96","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1398,"pos":[72070,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1410,"pos":[69690,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1423,"pos":[72070,360],"params":["Inherit","False","Constant","_Float314","Float 314","98","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1426,"pos":[72070,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1443,"pos":[69350,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1457,"pos":[72070,3300],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1459,"pos":[72070,605],"params":["Inherit","False","Constant","_Float323","Float 323","100","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1476,"pos":[77050,115],"params":["Inherit","False","Constant","_Float328","Float 328","100","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1490,"pos":[77050,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1521,"pos":[77050,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1523,"pos":[77050,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1554,"pos":[77050,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1826,"pos":[21790,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1827,"pos":[21790,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1841,"pos":[21790,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1849,"pos":[21790,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1856,"pos":[21790,2075],"params":["Inherit","False","1846","ase_n351_1846","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1857,"pos":[21790,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1865,"pos":[19070,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1879,"pos":[26770,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1880,"pos":[26770,360],"params":["Inherit","False","ase_n421_1880","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1906,"pos":[26770,605],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1908,"pos":[26770,1095],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1921,"pos":[26770,850],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2124,"pos":[47270,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2146,"pos":[52250,605],"params":["Inherit","False","2145","ase_n948_2145","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2187,"pos":[52250,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2189,"pos":[52250,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2202,"pos":[52250,2320],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2356,"pos":[72070,3545],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2357,"pos":[72070,1340],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2371,"pos":[72070,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2379,"pos":[72070,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2386,"pos":[72070,2075],"params":["Inherit","False","2376","ase_n1405_2376","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2387,"pos":[72070,3790],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2395,"pos":[69350,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2409,"pos":[77050,1830],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2410,"pos":[77050,360],"params":["Inherit","False","ase_n1475_2410","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2436,"pos":[77050,850],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2438,"pos":[77050,1095],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2451,"pos":[77050,605],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":312,"pos":[22130,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":314,"pos":[22130,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":315,"pos":[22130,115],"params":["Inherit","False","Constant","_Float62","Float 62","34","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":343,"pos":[22130,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":345,"pos":[22130,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":357,"pos":[22130,1095],"params":["Inherit","True","Property","_TextureSample17","Texture Sample 17","36","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":373,"pos":[22130,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":374,"pos":[22130,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":375,"pos":[22130,360],"params":["Inherit","False","Constant","_Float76","Float 76","38","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":390,"pos":[19410,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":406,"pos":[22130,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":423,"pos":[27110,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":437,"pos":[27110,1585],"params":["Inherit","True","Property","_TextureSample22","Texture Sample 22","41","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":468,"pos":[27110,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":470,"pos":[27110,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":491,"pos":[27110,115],"params":["Inherit","False","Constant","_Float103","Float 103","44","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07692308","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":501,"pos":[27110,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":534,"pos":[27110,360],"params":["Inherit","False","Constant","_Float113","Float 113","47","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":840,"pos":[47610,2075],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":873,"pos":[47610,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":885,"pos":[47610,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":903,"pos":[47610,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":904,"pos":[47610,115],"params":["Inherit","False","Constant","_Float197","Float 197","68","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":906,"pos":[47610,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":918,"pos":[44890,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":931,"pos":[47610,360],"params":["Inherit","False","Constant","_Float202","Float 202","70","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":934,"pos":[47610,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":951,"pos":[52590,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":965,"pos":[52590,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":967,"pos":[52590,115],"params":["Inherit","False","Constant","_Float211","Float 211","72","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":984,"pos":[52590,360],"params":["Inherit","False","Constant","_Float216","Float 216","72","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":998,"pos":[52590,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1029,"pos":[52590,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1031,"pos":[52590,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1062,"pos":[52590,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1366,"pos":[72410,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1368,"pos":[72410,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1369,"pos":[72410,115],"params":["Inherit","False","Constant","_Float302","Float 302","94","0","Create","True","0","0","0","False","0","False","Object","-1","","7","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1397,"pos":[72410,1095],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1399,"pos":[72410,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1411,"pos":[72410,850],"params":["Inherit","True","Property","_TextureSample77","Texture Sample 77","96","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1427,"pos":[72410,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1428,"pos":[72410,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1429,"pos":[72410,360],"params":["Inherit","False","Constant","_Float316","Float 316","98","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1444,"pos":[69690,360],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1460,"pos":[72410,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1477,"pos":[77390,850],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1491,"pos":[77390,1585],"params":["Inherit","True","Property","_TextureSample82","Texture Sample 82","101","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1522,"pos":[77390,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1524,"pos":[77390,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1545,"pos":[77390,115],"params":["Inherit","False","Constant","_Float343","Float 343","104","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07692308","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1555,"pos":[77390,1095],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1588,"pos":[77390,360],"params":["Inherit","False","Constant","_Float353","Float 353","107","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1859,"pos":[22130,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1881,"pos":[27110,605],"params":["Inherit","False","1880","ase_n421_1880","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1922,"pos":[27110,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1924,"pos":[27110,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1937,"pos":[27110,2320],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2108,"pos":[47610,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2109,"pos":[47610,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2123,"pos":[47610,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2131,"pos":[47610,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2138,"pos":[47610,1830],"params":["Inherit","False","2128","ase_n913_2128","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2139,"pos":[47610,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2147,"pos":[52590,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2148,"pos":[45230,2810],"params":["Inherit","False","ase_SimpleAddOpNode_2148","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2163,"pos":[52590,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2164,"pos":[52590,850],"params":["Inherit","False","ase_n983_2164","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2188,"pos":[52590,1340],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2190,"pos":[52590,1830],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2203,"pos":[52590,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2389,"pos":[72410,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2411,"pos":[77390,605],"params":["Inherit","False","2410","ase_n1475_2410","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2452,"pos":[77390,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2454,"pos":[77390,2565],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2467,"pos":[77390,2320],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":313,"pos":[22470,2075],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":346,"pos":[22470,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":358,"pos":[22470,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":376,"pos":[22470,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":377,"pos":[22470,115],"params":["Inherit","False","Constant","_Float77","Float 77","38","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":379,"pos":[22470,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":391,"pos":[19750,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":404,"pos":[22470,360],"params":["Inherit","False","Constant","_Float82","Float 82","40","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":407,"pos":[22470,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":424,"pos":[27450,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":438,"pos":[27450,2810],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":440,"pos":[27450,115],"params":["Inherit","False","Constant","_Float91","Float 91","42","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":457,"pos":[27450,360],"params":["Inherit","False","Constant","_Float96","Float 96","42","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":471,"pos":[27450,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":502,"pos":[27450,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":504,"pos":[27450,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":535,"pos":[27450,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":874,"pos":[47950,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":876,"pos":[47950,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":877,"pos":[47950,115],"params":["Inherit","False","Constant","_Float190","Float 190","66","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":905,"pos":[47950,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":907,"pos":[47950,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":919,"pos":[47950,1095],"params":["Inherit","True","Property","_TextureSample49","Texture Sample 49","68","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":935,"pos":[47950,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":936,"pos":[47950,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":937,"pos":[47950,360],"params":["Inherit","False","Constant","_Float204","Float 204","70","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":952,"pos":[52930,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":968,"pos":[52930,1830],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":985,"pos":[52930,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":999,"pos":[52930,2075],"params":["Inherit","True","Property","_TextureSample54","Texture Sample 54","73","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1030,"pos":[52930,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1032,"pos":[52930,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1053,"pos":[52930,115],"params":["Inherit","False","Constant","_Float231","Float 231","76","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07142857","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1063,"pos":[52930,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1096,"pos":[52930,360],"params":["Inherit","False","Constant","_Float241","Float 241","79","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1367,"pos":[72750,2320],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1400,"pos":[72750,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1412,"pos":[72750,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1430,"pos":[72750,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1431,"pos":[72750,115],"params":["Inherit","False","Constant","_Float317","Float 317","98","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1433,"pos":[72750,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1445,"pos":[70030,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1458,"pos":[72750,360],"params":["Inherit","False","Constant","_Float322","Float 322","100","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1461,"pos":[72750,2810],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1478,"pos":[77730,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1492,"pos":[77730,2565],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1494,"pos":[77730,115],"params":["Inherit","False","Constant","_Float331","Float 331","102","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1511,"pos":[77730,360],"params":["Inherit","False","Constant","_Float336","Float 336","102","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1525,"pos":[77730,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1556,"pos":[77730,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1558,"pos":[77730,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1589,"pos":[77730,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1843,"pos":[22470,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1844,"pos":[22470,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1858,"pos":[22470,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1866,"pos":[22470,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1873,"pos":[22470,1830],"params":["Inherit","False","1863","ase_n386_1863","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1874,"pos":[22470,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1882,"pos":[27450,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1883,"pos":[20090,3055],"params":["Inherit","False","ase_SimpleAddOpNode_1883","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1898,"pos":[27450,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1899,"pos":[27450,850],"params":["Inherit","False","ase_n456_1899","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1923,"pos":[27450,1095],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1925,"pos":[27450,1830],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1938,"pos":[27450,1340],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2141,"pos":[47950,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2149,"pos":[52930,3055],"params":["Inherit","False","2148","ase_SimpleAddOpNode_2148","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2165,"pos":[52930,850],"params":["Inherit","False","2164","ase_n983_2164","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2204,"pos":[52930,2320],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2206,"pos":[52930,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2219,"pos":[52930,2810],"params":["Inherit","False","1972","ase_________1972","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2373,"pos":[72750,3055],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2374,"pos":[72750,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2388,"pos":[72750,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2396,"pos":[72750,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2403,"pos":[72750,1830],"params":["Inherit","False","2393","ase_n1440_2393","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2404,"pos":[72750,3300],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2412,"pos":[77730,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2413,"pos":[70370,2075],"params":["Inherit","False","ase_SimpleAddOpNode_2413","-1","True","1","0","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2428,"pos":[77730,2075],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2429,"pos":[77730,850],"params":["Inherit","False","ase_n1510_2429","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2453,"pos":[77730,1585],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2455,"pos":[77730,1830],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2468,"pos":[77730,1095],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":347,"pos":[22810,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":349,"pos":[22810,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":350,"pos":[22810,115],"params":["Inherit","False","Constant","_Float70","Float 70","36","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":378,"pos":[22810,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":380,"pos":[22810,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":392,"pos":[22810,1095],"params":["Inherit","True","Property","_TextureSample19","Texture Sample 19","38","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":408,"pos":[22810,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":409,"pos":[22810,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":410,"pos":[22810,360],"params":["Inherit","False","Constant","_Float84","Float 84","40","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":425,"pos":[27790,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":441,"pos":[27790,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":458,"pos":[27790,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":472,"pos":[27790,2075],"params":["Inherit","True","Property","_TextureSample24","Texture Sample 24","43","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":503,"pos":[27790,1340],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":505,"pos":[27790,2810],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":526,"pos":[27790,115],"params":["Inherit","False","Constant","_Float111","Float 111","46","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07142857","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":536,"pos":[27790,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":569,"pos":[27790,360],"params":["Inherit","False","Constant","_Float121","Float 121","49","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":875,"pos":[48290,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":908,"pos":[48290,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":920,"pos":[48290,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":938,"pos":[48290,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":939,"pos":[48290,115],"params":["Inherit","False","Constant","_Float205","Float 205","70","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":941,"pos":[48290,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":953,"pos":[53270,3790],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":966,"pos":[53270,115],"params":["Inherit","False","Constant","_Float210","Float 210","72","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":969,"pos":[53270,3300],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":986,"pos":[53270,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1000,"pos":[53270,4280],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1002,"pos":[53270,360],"params":["Inherit","False","Constant","_Float219","Float 219","74","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1019,"pos":[53270,605],"params":["Inherit","False","Constant","_Float224","Float 224","74","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1033,"pos":[53270,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1064,"pos":[53270,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1066,"pos":[53270,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1097,"pos":[53270,4035],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1401,"pos":[73090,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1403,"pos":[73090,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1404,"pos":[73090,115],"params":["Inherit","False","Constant","_Float310","Float 310","96","0","Create","True","0","0","0","False","0","False","Object","-1","","8","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1432,"pos":[73090,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1434,"pos":[73090,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1446,"pos":[73090,1095],"params":["Inherit","True","Property","_TextureSample79","Texture Sample 79","98","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1462,"pos":[73090,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1463,"pos":[73090,2075],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1464,"pos":[73090,360],"params":["Inherit","False","Constant","_Float324","Float 324","100","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1479,"pos":[78070,605],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1495,"pos":[78070,1340],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1512,"pos":[78070,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1526,"pos":[78070,2320],"params":["Inherit","True","Property","_TextureSample84","Texture Sample 84","103","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1557,"pos":[78070,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1559,"pos":[78070,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1580,"pos":[78070,115],"params":["Inherit","False","Constant","_Float351","Float 351","106","0","Create","True","0","0","0","False","0","False","Object","-1","","0.07142857","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1590,"pos":[78070,1585],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1623,"pos":[78070,360],"params":["Inherit","False","Constant","_Float361","Float 361","109","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1876,"pos":[22810,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1884,"pos":[27790,3300],"params":["Inherit","False","1883","ase_SimpleAddOpNode_1883","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1900,"pos":[27790,850],"params":["Inherit","False","1899","ase_n456_1899","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1939,"pos":[27790,2320],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1941,"pos":[27790,3055],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1954,"pos":[27790,2565],"params":["Inherit","False","1702","ase_________1702","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2125,"pos":[48290,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2126,"pos":[48290,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2140,"pos":[48290,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2150,"pos":[53270,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2157,"pos":[53270,1830],"params":["Inherit","False","2145","ase_n948_2145","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2158,"pos":[53270,4770],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2166,"pos":[53270,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2180,"pos":[53270,2810],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2181,"pos":[53270,1340],"params":["Inherit","False","ase_n1018_2181","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2205,"pos":[53270,2075],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2207,"pos":[53270,2320],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2220,"pos":[53270,1585],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2406,"pos":[73090,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2414,"pos":[78070,2810],"params":["Inherit","False","2413","ase_SimpleAddOpNode_2413","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2430,"pos":[78070,850],"params":["Inherit","False","2429","ase_n1510_2429","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2469,"pos":[78070,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2471,"pos":[78070,3300],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2484,"pos":[78070,3055],"params":["Inherit","False","2237","ase_________2237","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":348,"pos":[23150,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":381,"pos":[23150,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":393,"pos":[23150,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":411,"pos":[23150,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":412,"pos":[23150,115],"params":["Inherit","False","Constant","_Float85","Float 85","40","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":414,"pos":[23150,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":426,"pos":[28130,4280],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":439,"pos":[28130,115],"params":["Inherit","False","Constant","_Float90","Float 90","42","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":442,"pos":[28130,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":459,"pos":[28130,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":473,"pos":[28130,3790],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":475,"pos":[28130,360],"params":["Inherit","False","Constant","_Float99","Float 99","44","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":492,"pos":[28130,605],"params":["Inherit","False","Constant","_Float104","Float 104","44","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":506,"pos":[28130,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":537,"pos":[28130,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":539,"pos":[28130,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":570,"pos":[28130,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":909,"pos":[48630,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":911,"pos":[48630,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":912,"pos":[48630,115],"params":["Inherit","False","Constant","_Float198","Float 198","68","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":940,"pos":[48630,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":942,"pos":[48630,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":954,"pos":[53610,1585],"params":["Inherit","True","Property","_TextureSample51","Texture Sample 51","70","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":970,"pos":[53610,2075],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":971,"pos":[53610,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":972,"pos":[53610,115],"params":["Inherit","False","Constant","_Float212","Float 212","72","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":987,"pos":[53610,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1003,"pos":[53610,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1020,"pos":[53610,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1034,"pos":[53610,2810],"params":["Inherit","True","Property","_TextureSample56","Texture Sample 56","75","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1065,"pos":[53610,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1067,"pos":[53610,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1088,"pos":[53610,360],"params":["Inherit","False","Constant","_Float239","Float 239","78","0","Create","True","0","0","0","False","0","False","Object","-1","","0.06666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1098,"pos":[53610,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1402,"pos":[73430,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1435,"pos":[73430,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1447,"pos":[73430,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1465,"pos":[73430,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1466,"pos":[73430,115],"params":["Inherit","False","Constant","_Float325","Float 325","100","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1468,"pos":[73430,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1480,"pos":[78410,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1493,"pos":[78410,115],"params":["Inherit","False","Constant","_Float330","Float 330","102","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1496,"pos":[78410,3055],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1513,"pos":[78410,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1527,"pos":[78410,4280],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1529,"pos":[78410,360],"params":["Inherit","False","Constant","_Float339","Float 339","104","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1546,"pos":[78410,605],"params":["Inherit","False","Constant","_Float344","Float 344","104","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1560,"pos":[78410,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1591,"pos":[78410,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1593,"pos":[78410,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1624,"pos":[78410,3790],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1860,"pos":[23150,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1861,"pos":[23150,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1875,"pos":[23150,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1885,"pos":[28130,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1892,"pos":[28130,2075],"params":["Inherit","False","1880","ase_n421_1880","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1893,"pos":[28130,4770],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1901,"pos":[28130,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1915,"pos":[28130,2810],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1916,"pos":[28130,1340],"params":["Inherit","False","ase_n491_1916","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1940,"pos":[28130,1585],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1942,"pos":[28130,2320],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1955,"pos":[28130,1830],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2160,"pos":[53610,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2182,"pos":[53610,1340],"params":["Inherit","False","2181","ase_n1018_2181","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2221,"pos":[53610,1830],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2223,"pos":[53610,3790],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2390,"pos":[73430,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2391,"pos":[73430,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2405,"pos":[73430,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2415,"pos":[78410,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2422,"pos":[78410,1830],"params":["Inherit","False","2410","ase_n1475_2410","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2423,"pos":[78410,4770],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2431,"pos":[78410,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2445,"pos":[78410,2810],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2446,"pos":[78410,1340],"params":["Inherit","False","ase_n1545_2446","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2470,"pos":[78410,2075],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2472,"pos":[78410,2565],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2485,"pos":[78410,1585],"params":["Inherit","False","1729","ase_SimpleDivideOpNode_1729","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":382,"pos":[23490,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":384,"pos":[23490,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":385,"pos":[23490,115],"params":["Inherit","False","Constant","_Float78","Float 78","38","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":413,"pos":[23490,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":415,"pos":[23490,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":427,"pos":[28470,1585],"params":["Inherit","True","Property","_TextureSample21","Texture Sample 21","40","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":443,"pos":[28470,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":444,"pos":[28470,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":445,"pos":[28470,115],"params":["Inherit","False","Constant","_Float92","Float 92","42","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":460,"pos":[28470,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":476,"pos":[28470,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":493,"pos":[28470,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":507,"pos":[28470,3055],"params":["Inherit","True","Property","_TextureSample26","Texture Sample 26","45","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":538,"pos":[28470,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":540,"pos":[28470,3300],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":561,"pos":[28470,360],"params":["Inherit","False","Constant","_Float119","Float 119","48","0","Create","True","0","0","0","False","0","False","Object","-1","","0.06666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":571,"pos":[28470,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":910,"pos":[48970,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":943,"pos":[48970,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":955,"pos":[53950,3545],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":973,"pos":[53950,3790],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":974,"pos":[53950,115],"params":["Inherit","False","Constant","_Float213","Float 213","72","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":976,"pos":[53950,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":988,"pos":[53950,4280],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1001,"pos":[53950,360],"params":["Inherit","False","Constant","_Float218","Float 218","74","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1004,"pos":[53950,5260],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1021,"pos":[53950,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1035,"pos":[53950,4770],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1037,"pos":[53950,605],"params":["Inherit","False","Constant","_Float227","Float 227","76","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1054,"pos":[53950,850],"params":["Inherit","False","Constant","_Float232","Float 232","76","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1068,"pos":[53950,5015],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1099,"pos":[53950,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1101,"pos":[53950,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1436,"pos":[73770,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1438,"pos":[73770,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1439,"pos":[73770,115],"params":["Inherit","False","Constant","_Float318","Float 318","98","0","Create","True","0","0","0","False","0","False","Object","-1","","9","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1467,"pos":[73770,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1469,"pos":[73770,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1481,"pos":[78750,1585],"params":["Inherit","True","Property","_TextureSample81","Texture Sample 81","100","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1497,"pos":[78750,1830],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1498,"pos":[78750,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1499,"pos":[78750,115],"params":["Inherit","False","Constant","_Float332","Float 332","102","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1514,"pos":[78750,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1530,"pos":[78750,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1547,"pos":[78750,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1561,"pos":[78750,3055],"params":["Inherit","True","Property","_TextureSample86","Texture Sample 86","105","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1592,"pos":[78750,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1594,"pos":[78750,3545],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1615,"pos":[78750,360],"params":["Inherit","False","Constant","_Float359","Float 359","108","0","Create","True","0","0","0","False","0","False","Object","-1","","0.06666667","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1625,"pos":[78750,2320],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1895,"pos":[28470,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1917,"pos":[28470,1340],"params":["Inherit","False","1916","ase_n491_1916","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1956,"pos":[28470,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1958,"pos":[28470,3790],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2142,"pos":[48970,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2143,"pos":[48970,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2159,"pos":[53950,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2167,"pos":[53950,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2174,"pos":[53950,2810],"params":["Inherit","False","2164","ase_n983_2164","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2175,"pos":[53950,5505],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2183,"pos":[53950,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2197,"pos":[53950,3055],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2198,"pos":[53950,1830],"params":["Inherit","False","ase_n1053_2198","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2222,"pos":[53950,2075],"params":["Inherit","False","1976","ase_SwizzleNode_1976","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2224,"pos":[53950,2320],"params":["Inherit","False","1979","ase_DynamicAppendNode_1979","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2425,"pos":[78750,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2447,"pos":[78750,1340],"params":["Inherit","False","2446","ase_n1545_2446","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2486,"pos":[78750,2075],"params":["Inherit","False","1704","ase_TextureCoordinatesNode_1704","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2488,"pos":[78750,3790],"params":["Inherit","False","1708","ase______1708","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":383,"pos":[23830,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":416,"pos":[23830,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":428,"pos":[28810,3545],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":446,"pos":[28810,3790],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":447,"pos":[28810,115],"params":["Inherit","False","Constant","_Float93","Float 93","42","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":449,"pos":[28810,3055],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":461,"pos":[28810,4280],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":474,"pos":[28810,360],"params":["Inherit","False","Constant","_Float98","Float 98","44","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":477,"pos":[28810,4770],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":494,"pos":[28810,2565],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":508,"pos":[28810,5260],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":510,"pos":[28810,605],"params":["Inherit","False","Constant","_Float107","Float 107","46","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":527,"pos":[28810,850],"params":["Inherit","False","Constant","_Float112","Float 112","46","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":541,"pos":[28810,5015],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":572,"pos":[28810,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":574,"pos":[28810,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":944,"pos":[49310,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":946,"pos":[49310,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":947,"pos":[49310,115],"params":["Inherit","False","Constant","_Float206","Float 206","70","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":975,"pos":[54290,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":977,"pos":[54290,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":989,"pos":[54290,1340],"params":["Inherit","True","Property","_TextureSample53","Texture Sample 53","72","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1005,"pos":[54290,2565],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1006,"pos":[54290,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1007,"pos":[54290,115],"params":["Inherit","False","Constant","_Float220","Float 220","74","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1022,"pos":[54290,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1038,"pos":[54290,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1055,"pos":[54290,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1069,"pos":[54290,2810],"params":["Inherit","True","Property","_TextureSample58","Texture Sample 58","77","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1100,"pos":[54290,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1102,"pos":[54290,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1437,"pos":[74110,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1470,"pos":[74110,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1482,"pos":[79090,3545],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1500,"pos":[79090,3790],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1501,"pos":[79090,115],"params":["Inherit","False","Constant","_Float333","Float 333","102","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1503,"pos":[79090,3055],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1515,"pos":[79090,4280],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1528,"pos":[79090,360],"params":["Inherit","False","Constant","_Float338","Float 338","104","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1531,"pos":[79090,4770],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1548,"pos":[79090,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1562,"pos":[79090,5015],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1564,"pos":[79090,605],"params":["Inherit","False","Constant","_Float347","Float 347","106","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1581,"pos":[79090,850],"params":["Inherit","False","Constant","_Float352","Float 352","106","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1595,"pos":[79090,5260],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1626,"pos":[79090,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1628,"pos":[79090,4525],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1877,"pos":[23830,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1878,"pos":[23830,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1894,"pos":[28810,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1902,"pos":[28810,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1909,"pos":[28810,2810],"params":["Inherit","False","1899","ase_n456_1899","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1910,"pos":[28810,5505],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1918,"pos":[28810,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1932,"pos":[28810,3300],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1933,"pos":[28810,1830],"params":["Inherit","False","ase_n526_1933","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1957,"pos":[28810,2075],"params":["Inherit","False","1706","ase_SwizzleNode_1706","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1959,"pos":[28810,2320],"params":["Inherit","False","1710","ase_DynamicAppendNode_1710","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2177,"pos":[54290,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2199,"pos":[54290,1585],"params":["Inherit","False","2198","ase_n1053_2198","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2407,"pos":[74110,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2408,"pos":[74110,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2424,"pos":[79090,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2432,"pos":[79090,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2439,"pos":[79090,2565],"params":["Inherit","False","2429","ase_n1510_2429","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2440,"pos":[79090,5505],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2448,"pos":[79090,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2462,"pos":[79090,3300],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2463,"pos":[79090,1830],"params":["Inherit","False","ase_n1580_2463","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2487,"pos":[79090,2075],"params":["Inherit","False","2241","ase_SwizzleNode_2241","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2489,"pos":[79090,2810],"params":["Inherit","False","2244","ase_DynamicAppendNode_2244","1","0","OBJECT","","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":417,"pos":[24170,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":419,"pos":[24170,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":420,"pos":[24170,115],"params":["Inherit","False","Constant","_Float86","Float 86","40","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":448,"pos":[29150,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":450,"pos":[29150,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":462,"pos":[29150,1340],"params":["Inherit","True","Property","_TextureSample23","Texture Sample 23","42","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":478,"pos":[29150,2320],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":479,"pos":[29150,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":480,"pos":[29150,115],"params":["Inherit","False","Constant","_Float100","Float 100","44","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":495,"pos":[29150,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":511,"pos":[29150,2565],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":528,"pos":[29150,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":542,"pos":[29150,2810],"params":["Inherit","True","Property","_TextureSample28","Texture Sample 28","47","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":573,"pos":[29150,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":575,"pos":[29150,2075],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":945,"pos":[49650,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":978,"pos":[54630,3790],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":990,"pos":[54630,3055],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1008,"pos":[54630,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1009,"pos":[54630,115],"params":["Inherit","False","Constant","_Float221","Float 221","74","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1011,"pos":[54630,2810],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1023,"pos":[54630,4525],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1036,"pos":[54630,360],"params":["Inherit","False","Constant","_Float226","Float 226","76","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1039,"pos":[54630,4280],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1056,"pos":[54630,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1070,"pos":[54630,5015],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1072,"pos":[54630,605],"params":["Inherit","False","Constant","_Float235","Float 235","78","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1089,"pos":[54630,850],"params":["Inherit","False","Constant","_Float240","Float 240","78","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1103,"pos":[54630,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1471,"pos":[74450,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1473,"pos":[74450,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1474,"pos":[74450,115],"params":["Inherit","False","Constant","_Float326","Float 326","100","0","Create","True","0","0","0","False","0","False","Object","-1","","10","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1502,"pos":[79430,605],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1504,"pos":[79430,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1516,"pos":[79430,1340],"params":["Inherit","True","Property","_TextureSample83","Texture Sample 83","102","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1532,"pos":[79430,2075],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1533,"pos":[79430,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1534,"pos":[79430,115],"params":["Inherit","False","Constant","_Float340","Float 340","104","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1549,"pos":[79430,850],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1565,"pos":[79430,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1582,"pos":[79430,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1596,"pos":[79430,3055],"params":["Inherit","True","Property","_TextureSample88","Texture Sample 88","107","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1627,"pos":[79430,1830],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1629,"pos":[79430,2565],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1912,"pos":[29150,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1934,"pos":[29150,1585],"params":["Inherit","False","1933","ase_n526_1933","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2161,"pos":[54630,4770],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2162,"pos":[54630,1830],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2176,"pos":[54630,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2184,"pos":[54630,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2191,"pos":[54630,3300],"params":["Inherit","False","2181","ase_n1018_2181","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2192,"pos":[54630,5260],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2200,"pos":[54630,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2214,"pos":[54630,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2215,"pos":[54630,2075],"params":["Inherit","False","ase_n1088_2215","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2442,"pos":[79430,360],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2464,"pos":[79430,1585],"params":["Inherit","False","2463","ase_n1580_2463","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":418,"pos":[24510,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":451,"pos":[29490,3790],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":463,"pos":[29490,3055],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":481,"pos":[29490,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":482,"pos":[29490,115],"params":["Inherit","False","Constant","_Float101","Float 101","44","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":484,"pos":[29490,2810],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":496,"pos":[29490,4280],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":509,"pos":[29490,360],"params":["Inherit","False","Constant","_Float106","Float 106","46","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":512,"pos":[29490,4525],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":529,"pos":[29490,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":543,"pos":[29490,5015],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":545,"pos":[29490,605],"params":["Inherit","False","Constant","_Float115","Float 115","48","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":562,"pos":[29490,850],"params":["Inherit","False","Constant","_Float120","Float 120","48","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":576,"pos":[29490,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":979,"pos":[54970,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":981,"pos":[54970,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":982,"pos":[54970,115],"params":["Inherit","False","Constant","_Float214","Float 214","72","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1010,"pos":[54970,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1012,"pos":[54970,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1024,"pos":[54970,1585],"params":["Inherit","True","Property","_TextureSample55","Texture Sample 55","74","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1040,"pos":[54970,2320],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1041,"pos":[54970,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1042,"pos":[54970,360],"params":["Inherit","False","Constant","_Float228","Float 228","76","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1057,"pos":[54970,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1073,"pos":[54970,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1090,"pos":[54970,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1104,"pos":[54970,2565],"params":["Inherit","True","Property","_TextureSample60","Texture Sample 60","79","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1472,"pos":[74790,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1505,"pos":[79770,3790],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1517,"pos":[79770,3055],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1535,"pos":[79770,3545],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1536,"pos":[79770,115],"params":["Inherit","False","Constant","_Float341","Float 341","104","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1538,"pos":[79770,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1550,"pos":[79770,4525],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1563,"pos":[79770,360],"params":["Inherit","False","Constant","_Float346","Float 346","106","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1566,"pos":[79770,4280],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1583,"pos":[79770,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1597,"pos":[79770,5015],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1599,"pos":[79770,605],"params":["Inherit","False","Constant","_Float355","Float 355","108","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1616,"pos":[79770,850],"params":["Inherit","False","Constant","_Float360","Float 360","108","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1630,"pos":[79770,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1896,"pos":[29490,4770],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1897,"pos":[29490,1830],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1911,"pos":[29490,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1919,"pos":[29490,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1926,"pos":[29490,3300],"params":["Inherit","False","1916","ase_n491_1916","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1927,"pos":[29490,5260],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1935,"pos":[29490,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1949,"pos":[29490,2565],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1950,"pos":[29490,2075],"params":["Inherit","False","ase_n561_1950","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2194,"pos":[54970,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2216,"pos":[54970,2075],"params":["Inherit","False","2215","ase_n1088_2215","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2426,"pos":[79770,4770],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2427,"pos":[79770,1830],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2441,"pos":[79770,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2449,"pos":[79770,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2456,"pos":[79770,3300],"params":["Inherit","False","2446","ase_n1545_2446","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2457,"pos":[79770,5260],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2465,"pos":[79770,1585],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2479,"pos":[79770,2810],"params":["Inherit","False","1694","ase_SimpleDivideOpNode_1694","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2480,"pos":[79770,2075],"params":["Inherit","False","ase_n1615_2480","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":452,"pos":[29830,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":454,"pos":[29830,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":455,"pos":[29830,115],"params":["Inherit","False","Constant","_Float94","Float 94","42","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":483,"pos":[29830,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":485,"pos":[29830,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":497,"pos":[29830,1585],"params":["Inherit","True","Property","_TextureSample25","Texture Sample 25","44","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":513,"pos":[29830,2320],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":514,"pos":[29830,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":515,"pos":[29830,360],"params":["Inherit","False","Constant","_Float108","Float 108","46","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":530,"pos":[29830,1340],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":546,"pos":[29830,3055],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":563,"pos":[29830,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":577,"pos":[29830,2565],"params":["Inherit","True","Property","_TextureSample30","Texture Sample 30","49","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":980,"pos":[55310,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1013,"pos":[55310,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1025,"pos":[55310,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1043,"pos":[55310,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1044,"pos":[55310,115],"params":["Inherit","False","Constant","_Float229","Float 229","76","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1046,"pos":[55310,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1058,"pos":[55310,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1071,"pos":[55310,360],"params":["Inherit","False","Constant","_Float234","Float 234","78","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1074,"pos":[55310,4280],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1091,"pos":[55310,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1105,"pos":[55310,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1107,"pos":[55310,605],"params":["Inherit","False","Constant","_Float243","Float 243","80","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1506,"pos":[80110,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1508,"pos":[80110,2810],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1509,"pos":[80110,115],"params":["Inherit","False","Constant","_Float334","Float 334","102","0","Create","True","0","0","0","False","0","False","Object","-1","","11","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1537,"pos":[80110,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1539,"pos":[80110,3055],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1551,"pos":[80110,1585],"params":["Inherit","True","Property","_TextureSample85","Texture Sample 85","104","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1567,"pos":[80110,2320],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1568,"pos":[80110,3545],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1569,"pos":[80110,360],"params":["Inherit","False","Constant","_Float348","Float 348","106","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1584,"pos":[80110,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1600,"pos":[80110,3300],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1617,"pos":[80110,1340],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1631,"pos":[80110,2565],"params":["Inherit","True","Property","_TextureSample90","Texture Sample 90","109","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1929,"pos":[29830,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1951,"pos":[29830,2075],"params":["Inherit","False","1950","ase_n561_1950","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2178,"pos":[55310,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2179,"pos":[55310,1585],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2193,"pos":[55310,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2201,"pos":[55310,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2208,"pos":[55310,2810],"params":["Inherit","False","2198","ase_n1053_2198","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2209,"pos":[55310,4525],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2217,"pos":[55310,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2459,"pos":[80110,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2481,"pos":[80110,2075],"params":["Inherit","False","2480","ase_n1615_2480","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":453,"pos":[30170,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":486,"pos":[30170,3300],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":498,"pos":[30170,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":516,"pos":[30170,3055],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":517,"pos":[30170,115],"params":["Inherit","False","Constant","_Float109","Float 109","46","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":519,"pos":[30170,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":531,"pos":[30170,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":544,"pos":[30170,360],"params":["Inherit","False","Constant","_Float114","Float 114","48","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":547,"pos":[30170,4280],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":564,"pos":[30170,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":578,"pos":[30170,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":580,"pos":[30170,605],"params":["Inherit","False","Constant","_Float123","Float 123","50","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1014,"pos":[55650,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1016,"pos":[55650,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1017,"pos":[55650,115],"params":["Inherit","False","Constant","_Float222","Float 222","74","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1045,"pos":[55650,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1047,"pos":[55650,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1059,"pos":[55650,1340],"params":["Inherit","True","Property","_TextureSample57","Texture Sample 57","76","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1075,"pos":[55650,2075],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1076,"pos":[55650,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1077,"pos":[55650,360],"params":["Inherit","False","Constant","_Float236","Float 236","78","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1092,"pos":[55650,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1108,"pos":[55650,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1507,"pos":[80450,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1540,"pos":[80450,3055],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1552,"pos":[80450,2565],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1570,"pos":[80450,3300],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1571,"pos":[80450,115],"params":["Inherit","False","Constant","_Float349","Float 349","106","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1573,"pos":[80450,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1585,"pos":[80450,4035],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1598,"pos":[80450,360],"params":["Inherit","False","Constant","_Float354","Float 354","108","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1601,"pos":[80450,4525],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1618,"pos":[80450,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1632,"pos":[80450,3545],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1634,"pos":[80450,605],"params":["Inherit","False","Constant","_Float363","Float 363","110","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1913,"pos":[30170,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1914,"pos":[30170,1585],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1928,"pos":[30170,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1936,"pos":[30170,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1943,"pos":[30170,2810],"params":["Inherit","False","1933","ase_n526_1933","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1944,"pos":[30170,4525],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1952,"pos":[30170,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2211,"pos":[55650,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2443,"pos":[80450,3790],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2444,"pos":[80450,1585],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2458,"pos":[80450,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2466,"pos":[80450,1095],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2473,"pos":[80450,2810],"params":["Inherit","False","2463","ase_n1580_2463","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2474,"pos":[80450,4280],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2482,"pos":[80450,1340],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":487,"pos":[30510,2565],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":489,"pos":[30510,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":490,"pos":[30510,115],"params":["Inherit","False","Constant","_Float102","Float 102","44","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":518,"pos":[30510,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":520,"pos":[30510,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":532,"pos":[30510,1340],"params":["Inherit","True","Property","_TextureSample27","Texture Sample 27","46","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":548,"pos":[30510,2075],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":549,"pos":[30510,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":550,"pos":[30510,360],"params":["Inherit","False","Constant","_Float116","Float 116","48","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":565,"pos":[30510,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":581,"pos":[30510,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1015,"pos":[55990,2565],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1048,"pos":[55990,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1060,"pos":[55990,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1078,"pos":[55990,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1079,"pos":[55990,115],"params":["Inherit","False","Constant","_Float237","Float 237","78","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1081,"pos":[55990,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1093,"pos":[55990,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1106,"pos":[55990,360],"params":["Inherit","False","Constant","_Float242","Float 242","80","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1109,"pos":[55990,2320],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1541,"pos":[80790,2320],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1543,"pos":[80790,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1544,"pos":[80790,115],"params":["Inherit","False","Constant","_Float342","Float 342","104","0","Create","True","0","0","0","False","0","False","Object","-1","","12","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1572,"pos":[80790,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1574,"pos":[80790,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1586,"pos":[80790,1340],"params":["Inherit","True","Property","_TextureSample87","Texture Sample 87","106","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1602,"pos":[80790,2565],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1603,"pos":[80790,2810],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1604,"pos":[80790,360],"params":["Inherit","False","Constant","_Float356","Float 356","108","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1619,"pos":[80790,1095],"params":["Inherit","False","FLOAT2","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1635,"pos":[80790,1585],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1946,"pos":[30510,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2195,"pos":[55990,3300],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2196,"pos":[55990,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2210,"pos":[55990,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2218,"pos":[55990,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2225,"pos":[55990,2810],"params":["Inherit","False","2215","ase_n1088_2215","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2226,"pos":[55990,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2476,"pos":[80790,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":488,"pos":[30850,2565],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":521,"pos":[30850,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":533,"pos":[30850,1585],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":551,"pos":[30850,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":552,"pos":[30850,115],"params":["Inherit","False","Constant","_Float117","Float 117","48","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":554,"pos":[30850,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":566,"pos":[30850,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":579,"pos":[30850,360],"params":["Inherit","False","Constant","_Float122","Float 122","50","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":582,"pos":[30850,2320],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1049,"pos":[56330,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1051,"pos":[56330,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1052,"pos":[56330,115],"params":["Inherit","False","Constant","_Float230","Float 230","76","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1080,"pos":[56330,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1082,"pos":[56330,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1094,"pos":[56330,1095],"params":["Inherit","True","Property","_TextureSample59","Texture Sample 59","78","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1110,"pos":[56330,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1111,"pos":[56330,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1112,"pos":[56330,360],"params":["Inherit","False","Constant","_Float244","Float 244","80","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1542,"pos":[81130,2075],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1575,"pos":[81130,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1587,"pos":[81130,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1605,"pos":[81130,2320],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1606,"pos":[81130,115],"params":["Inherit","False","Constant","_Float357","Float 357","108","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1608,"pos":[81130,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1620,"pos":[81130,3055],"params":["Inherit","False","2","2","0","FLOAT2","0,0","False","1","FLOAT2","0,0","False","1","FLOAT2","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1633,"pos":[81130,360],"params":["Inherit","False","Constant","_Float362","Float 362","110","0","Create","True","0","0","0","False","0","False","Object","-1","","0.3","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SaturateNode, AmplifyShaderEditor","id":1636,"pos":[81130,2565],"params":["Inherit","False","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1930,"pos":[30850,3300],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1931,"pos":[30850,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1945,"pos":[30850,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1953,"pos":[30850,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1960,"pos":[30850,2810],"params":["Inherit","False","1950","ase_n561_1950","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1961,"pos":[30850,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2228,"pos":[56330,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2460,"pos":[81130,3300],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2461,"pos":[81130,1095],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2475,"pos":[81130,605],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2483,"pos":[81130,850],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2490,"pos":[81130,2810],"params":["Inherit","False","2480","ase_n1615_2480","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2491,"pos":[81130,3545],"params":["Inherit","False","1713","ase______1713","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":522,"pos":[31190,2075],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":524,"pos":[31190,1830],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":525,"pos":[31190,115],"params":["Inherit","False","Constant","_Float110","Float 110","46","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":553,"pos":[31190,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":555,"pos":[31190,1585],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":567,"pos":[31190,1095],"params":["Inherit","True","Property","_TextureSample29","Texture Sample 29","48","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":583,"pos":[31190,1340],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":584,"pos":[31190,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":585,"pos":[31190,360],"params":["Inherit","False","Constant","_Float124","Float 124","50","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1050,"pos":[56670,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1083,"pos":[56670,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1095,"pos":[56670,1095],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1113,"pos":[56670,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1114,"pos":[56670,115],"params":["Inherit","False","Constant","_Float245","Float 245","80","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1116,"pos":[56670,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1576,"pos":[81470,1830],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1578,"pos":[81470,2075],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1579,"pos":[81470,115],"params":["Inherit","False","Constant","_Float350","Float 350","106","0","Create","True","0","0","0","False","0","False","Object","-1","","13","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1607,"pos":[81470,850],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1609,"pos":[81470,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1621,"pos":[81470,1095],"params":["Inherit","True","Property","_TextureSample89","Texture Sample 89","108","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","MipLevel","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor","id":1637,"pos":[81470,1585],"params":["Inherit","False","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.PowerNode, AmplifyShaderEditor","id":1638,"pos":[81470,2320],"params":["Inherit","False","False","2","0","FLOAT","0","False","1","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1639,"pos":[81470,360],"params":["Inherit","False","Constant","_Float364","Float 364","110","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1963,"pos":[31190,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2212,"pos":[56670,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2213,"pos":[56670,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2227,"pos":[56670,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2493,"pos":[81470,605],"params":["Inherit","False","1716","ase_SwizzleNode_1716","1","0","OBJECT","","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":2,"pos":[50,360],"params":["Inherit","False","Constant","_Float1","Float 1","0","0","Create","True","0","0","0","False","0","False","Object","-1","","1","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":18,"pos":[50,3300],"params":["Inherit","False","Property","_Iteration","每层迭代（向上取整）","13","0","Create","False","0","0","0","True","0","False","Object","-1","","3","0","1","15","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":523,"pos":[31530,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":556,"pos":[31530,1340],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":568,"pos":[31530,1095],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":586,"pos":[31530,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":587,"pos":[31530,115],"params":["Inherit","False","Constant","_Float125","Float 125","50","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":589,"pos":[31530,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1084,"pos":[57010,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1086,"pos":[57010,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1087,"pos":[57010,115],"params":["Inherit","False","Constant","_Float238","Float 238","78","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1115,"pos":[57010,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1117,"pos":[57010,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1577,"pos":[81810,1830],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1610,"pos":[81810,1095],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1622,"pos":[81810,1340],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1640,"pos":[81810,1585],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1641,"pos":[81810,115],"params":["Inherit","False","Constant","_Float365","Float 365","110","0","Create","True","0","0","0","False","0","False","Object","-1","","5","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1643,"pos":[81810,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1947,"pos":[31530,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1948,"pos":[31530,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1962,"pos":[31530,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2477,"pos":[81810,2075],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2478,"pos":[81810,605],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2492,"pos":[81810,360],"params":["Inherit","False","1686","ase_n1_1686","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":557,"pos":[31870,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":559,"pos":[31870,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":560,"pos":[31870,115],"params":["Inherit","False","Constant","_Float118","Float 118","48","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":588,"pos":[31870,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":590,"pos":[31870,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1085,"pos":[57350,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1118,"pos":[57350,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1611,"pos":[82150,850],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1613,"pos":[82150,1095],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1614,"pos":[82150,115],"params":["Inherit","False","Constant","_Float358","Float 358","108","0","Create","True","0","0","0","False","0","False","Object","-1","","14","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor","id":1642,"pos":[82150,360],"params":["Inherit","False","3","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","1","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1644,"pos":[82150,605],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1681,"pos":[390,360],"params":["Inherit","False","ase_n2_1681","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":1720,"pos":[390,2565],"params":["Inherit","False","ase____________1720","-1","True","1","0","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2229,"pos":[57350,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2230,"pos":[57350,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2503,"pos":[83680,15],"params":["Inherit","False","2720","1065","保留源码 Spark += max(Spark, Layer) 的顺序（非简单三层相加），叠加 MainTex*BaseColor。按 MaskAlpha 原始 UV 的 R<0.5 裁剪。输出不添加 PBR/额外灯光、相机抓图、雾或曝光。","20","4","8","1650","1651","1652","1653","1654","1655","1656","1657","1658","1659","1660","1661","1662","1663","1664","1665","2497","2501","06 三层原始聚合与轮廓裁剪","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":4,"pos":[83730,115],"params":["Inherit","True","Property","_MainTex","基色贴图","0","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":9,"pos":[50,1340],"params":["Inherit","False","Property","_BaseColor","基色叠色","5","0","Create","False","0","0","0","True","0","False","Object","-1","","0.5,0.5,0.5,1","0.5,0.5,0.5,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":558,"pos":[32210,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":591,"pos":[32210,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1119,"pos":[57690,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1121,"pos":[57690,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1122,"pos":[57690,115],"params":["Inherit","False","Constant","_Float246","Float 246","80","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1612,"pos":[82490,605],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1645,"pos":[82490,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT","0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1964,"pos":[32210,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":1965,"pos":[32210,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2494,"pos":[82490,850],"params":["Inherit","False","1720","ase____________1720","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2495,"pos":[82490,115],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":592,"pos":[32550,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":594,"pos":[32550,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":595,"pos":[32550,115],"params":["Inherit","False","Constant","_Float126","Float 126","50","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1120,"pos":[58030,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1646,"pos":[82830,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1648,"pos":[82830,605],"params":["Inherit","False","2","2","0","FLOAT","0","False","1","FLOAT","0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1649,"pos":[82830,115],"params":["Inherit","False","Constant","_Float366","Float 366","110","0","Create","True","0","0","0","False","0","False","Object","-1","","15","0","0","1","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":1654,"pos":[84070,360],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor","id":2496,"pos":[390,605],"params":["Inherit","False","ase______2496","-1","True","1","0","COLOR","0,0,0,0","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":593,"pos":[32890,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.ConditionalIfNode, AmplifyShaderEditor","id":1647,"pos":[83170,115],"params":["Inherit","False","False","5","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT3","0,0,0","False","3","FLOAT3","0,0,0","False","4","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1650,"pos":[84070,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1655,"pos":[84410,360],"params":["Inherit","True","Property","_TextureSample91","Texture Sample 91","110","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2497,"pos":[84410,850],"params":["Inherit","False","2496","ase______2496","1","0","OBJECT","","False","1","COLOR","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1651,"pos":[84410,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMaxOpNode, AmplifyShaderEditor","id":1652,"pos":[84750,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1656,"pos":[84750,360],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1657,"pos":[84750,605],"params":["Inherit","False","FLOAT3","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1653,"pos":[85090,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor","id":1658,"pos":[85090,360],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor","id":3,"pos":[50,605],"params":["Inherit","False","0","-1","2","","3","2","SAMPLER2D","","False","0","FLOAT2","1,1","False","1","FLOAT2","0,0","False","5","FLOAT2","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":8,"pos":[83730,360],"params":["Inherit","True","Property","_MaskAlpha","轮廓裁剪（线性）","4","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor","id":1659,"pos":[85430,115],"params":["Inherit","False","2","2","0","FLOAT3","0,0,0","False","1","FLOAT3","0,0,0","False","1","FLOAT3","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1660,"pos":[85770,115],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1661,"pos":[85770,360],"params":["Inherit","False","FLOAT","1","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1662,"pos":[85770,605],"params":["Inherit","False","FLOAT","2","1","2","3","1","0","FLOAT3","0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor","id":1664,"pos":[84070,605],"params":["Inherit","True","Property","_TextureSample92","Texture Sample 92","111","0","Create","True","0","0","0","False","0","False","","-1","None","None","True","0","False","white","Auto","False","Object","-1","Auto","Texture2D","False","8","0","SAMPLER2D","","False","1","FLOAT2","0,0","False","2","FLOAT","0","False","3","FLOAT2","0,0","False","4","FLOAT2","0,0","False","5","FLOAT","1","False","6","FLOAT","0","False","7","SAMPLERSTATE","","False","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor","id":2501,"pos":[85770,850],"params":["Inherit","False","1681","ase_n2_1681","1","0","OBJECT","","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor","id":2514,"pos":[0,4915],"params":["Inherit","False","640","2290","以下参数在原源码仅声明或仅位于注释/无效分支，保留可编辑接口但不接入输出：ParallaxMap、ColorGradient、Color_pow、SparklePower、SpecularColor/Pow、RimColor/Power/Intensity。原图未输出灯光、抓屏或 PBR 响应，不借此声称已有这些功能。","9","1666","1667","1668","1669","1670","1671","1672","1673","1674","07 原图未参与输出的参数","0.25,0.55,0.75,1","0","0"]}
{"type":"AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor","id":1663,"pos":[86110,115],"params":["Inherit","False","FLOAT4","4","0","FLOAT","0","False","1","FLOAT","0","False","2","FLOAT","0","False","3","FLOAT","0","False","1","FLOAT4","0"]}
{"type":"AmplifyShaderEditor.SwizzleNode, AmplifyShaderEditor","id":1665,"pos":[84410,605],"params":["Inherit","False","FLOAT","0","1","2","3","1","0","COLOR","0,0,0,0","False","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":1666,"pos":[50,5015],"params":["Inherit","True","Property","_ParallaxMap","源未使用：视差贴图","19","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor","id":1667,"pos":[50,5260],"params":["Inherit","True","Property","_ColorGradient","源未使用：颜色梯度","20","0","Create","False","0","0","0","True","0","False","","None","None","False","white","Auto","Texture2D","False","-1","0","2","SAMPLER2D","0","SAMPLERSTATE","1"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1668,"pos":[50,5505],"params":["Inherit","False","Property","_Color_pow","源未使用：颜色指数","21","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0","10","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1669,"pos":[50,5750],"params":["Inherit","False","Property","_SparklePower","源未使用：闪片指数","22","0","Create","False","0","0","0","True","0","False","Object","-1","","10","0","0","0","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":1670,"pos":[50,5995],"params":["Inherit","False","Property","_SpecularColor","源未使用：高光色","23","0","Create","False","0","0","0","True","0","False","Object","-1","","1,1,1,1","1,1,1,1","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1671,"pos":[50,6240],"params":["Inherit","False","Property","_SpecularPow","源未使用：高光指数","24","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","1","150","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.ColorNode, AmplifyShaderEditor","id":1672,"pos":[50,6485],"params":["Inherit","False","Property","_RimColor","源未使用：边缘色","25","0","Create","False","0","0","0","True","0","False","Object","-1","","0.17,0.36,0.81,0","0.17,0.36,0.81,0","True","True","0","6","COLOR","0","FLOAT","1","FLOAT","2","FLOAT","3","FLOAT","4","FLOAT3","5"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1673,"pos":[50,6730],"params":["Inherit","False","Property","_RimPower","源未使用：边缘指数","26","0","Create","False","0","0","0","True","0","False","Object","-1","","8","0","0.6","36","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor","id":1674,"pos":[50,6975],"params":["Inherit","False","Property","_RimIntensity","源未使用：边缘强度","27","0","Create","False","0","0","0","True","0","False","Object","-1","","1","0","0","100","0","1","FLOAT","0"]}
{"type":"AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor","id":0,"pos":[86750,200],"params":["Float","False","True","-1","3","AmplifyShaderEditor.MaterialInspector","0","5","ASELibrary/HDRP/Showcase/LayeredParallaxGlitter","57f0b2ef4faf3ad15a58de7ba63288b9","True","Unlit","0","0","Unlit","3","False","True","0","1","False","","0","False","","0","1","False","","0","False","","False","False","False","False","False","False","False","False","False","False","False","False","True","0","False","","False","False","False","False","False","False","False","False","False","False","False","True","1","False","","True","3","False","","False","False","True","4","RenderType=TransparentCutout=RenderType","Queue=AlphaTest=Queue=0","IgnoreProjector=True","RenderPipeline=HDRenderPipeline","False","False","0","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","False","True","1","LightMode=SRPDefaultUnlit","True","5","False","0","Transparent/Cutout/VertexLit","0","0","Standard","0","0","1","True","False","","True","0"]}
{"wire":[29,2,7,0]}
{"wire":[30,0,7,0]}
{"wire":[30,1,29,0]}
{"wire":[31,0,30,0]}
{"wire":[33,0,31,0]}
{"wire":[33,1,32,0]}
{"wire":[37,0,36,0]}
{"wire":[37,1,36,0]}
{"wire":[34,0,33,0]}
{"wire":[34,1,1682,0]}
{"wire":[38,0,37,0]}
{"wire":[36,0,34,0]}
{"wire":[36,1,35,0]}
{"wire":[39,0,1683,0]}
{"wire":[39,1,38,0]}
{"wire":[28,0,27,0]}
{"wire":[40,0,39,0]}
{"wire":[41,0,36,0]}
{"wire":[42,0,36,0]}
{"wire":[1689,0,13,0]}
{"wire":[43,0,41,0]}
{"wire":[43,1,42,0]}
{"wire":[43,2,40,0]}
{"wire":[44,0,28,0]}
{"wire":[47,0,45,0]}
{"wire":[57,0,54,0]}
{"wire":[57,1,1688,0]}
{"wire":[1677,0,23,0]}
{"wire":[1684,0,12,0]}
{"wire":[1692,0,14,0]}
{"wire":[1972,0,16,0]}
{"wire":[45,0,44,0]}
{"wire":[45,1,43,0]}
{"wire":[48,0,47,0]}
{"wire":[54,0,52,0]}
{"wire":[54,1,53,0]}
{"wire":[59,0,57,0]}
{"wire":[59,1,58,0]}
{"wire":[60,0,54,0]}
{"wire":[60,1,1690,0]}
{"wire":[62,0,54,0]}
{"wire":[62,1,1691,0]}
{"wire":[1675,0,21,0]}
{"wire":[1679,0,25,0]}
{"wire":[1686,0,1,0]}
{"wire":[1702,0,15,0]}
{"wire":[2237,0,17,0]}
{"wire":[24,0,1678,0]}
{"wire":[46,0,45,0]}
{"wire":[50,0,48,0]}
{"wire":[50,1,49,0]}
{"wire":[55,0,54,0]}
{"wire":[55,1,1685,0]}
{"wire":[61,0,59,0]}
{"wire":[61,1,60,0]}
{"wire":[64,0,62,0]}
{"wire":[64,1,63,0]}
{"wire":[65,0,54,0]}
{"wire":[65,1,1693,0]}
{"wire":[67,2,5,0]}
{"wire":[607,0,1973,0]}
{"wire":[607,1,606,0]}
{"wire":[22,0,1676,0]}
{"wire":[26,0,1680,0]}
{"wire":[51,0,46,0]}
{"wire":[51,1,50,0]}
{"wire":[56,0,1687,0]}
{"wire":[56,1,55,0]}
{"wire":[66,0,64,0]}
{"wire":[66,1,65,0]}
{"wire":[80,0,1703,0]}
{"wire":[80,1,79,0]}
{"wire":[608,0,1974,0]}
{"wire":[608,1,607,0]}
{"wire":[1134,0,2238,0]}
{"wire":[1134,1,1133,0]}
{"wire":[1704,0,67,0]}
{"wire":[1708,0,19,0]}
{"wire":[1976,0,24,0]}
{"wire":[1979,0,61,0]}
{"wire":[81,0,51,0]}
{"wire":[81,1,80,0]}
{"wire":[609,0,1975,0]}
{"wire":[609,1,608,0]}
{"wire":[611,0,598,0]}
{"wire":[611,1,1978,0]}
{"wire":[642,0,1994,0]}
{"wire":[642,1,641,0]}
{"wire":[1135,0,2239,0]}
{"wire":[1135,1,1134,0]}
{"wire":[1706,0,22,0]}
{"wire":[1710,0,56,0]}
{"wire":[1729,0,51,0]}
{"wire":[2241,0,26,0]}
{"wire":[2244,0,66,0]}
{"wire":[82,0,1705,0]}
{"wire":[82,1,81,0]}
{"wire":[84,0,71,0]}
{"wire":[84,1,1709,0]}
{"wire":[115,0,1728,0]}
{"wire":[115,1,114,0]}
{"wire":[610,0,609,0]}
{"wire":[610,1,1977,0]}
{"wire":[612,0,1980,0]}
{"wire":[612,1,611,0]}
{"wire":[643,0,1995,0]}
{"wire":[643,1,642,0]}
{"wire":[1136,0,2240,0]}
{"wire":[1136,1,1135,0]}
{"wire":[1138,0,1125,0]}
{"wire":[1138,1,2243,0]}
{"wire":[1169,0,2259,0]}
{"wire":[1169,1,1168,0]}
{"wire":[83,0,82,0]}
{"wire":[83,1,1707,0]}
{"wire":[85,0,1711,0]}
{"wire":[85,1,84,0]}
{"wire":[116,0,1730,0]}
{"wire":[116,1,115,0]}
{"wire":[613,0,610,0]}
{"wire":[613,1,612,0]}
{"wire":[644,0,1996,0]}
{"wire":[644,1,643,0]}
{"wire":[646,0,633,0]}
{"wire":[646,1,1998,0]}
{"wire":[677,0,2011,0]}
{"wire":[677,1,676,0]}
{"wire":[1137,0,1136,0]}
{"wire":[1137,1,2242,0]}
{"wire":[1139,0,2245,0]}
{"wire":[1139,1,1138,0]}
{"wire":[1170,0,2260,0]}
{"wire":[1170,1,1169,0]}
{"wire":[1694,0,54,0]}
{"wire":[1967,0,598,0]}
{"wire":[86,0,83,0]}
{"wire":[86,1,85,0]}
{"wire":[117,0,1731,0]}
{"wire":[117,1,116,0]}
{"wire":[119,0,106,0]}
{"wire":[119,1,1733,0]}
{"wire":[150,0,1746,0]}
{"wire":[150,1,149,0]}
{"wire":[600,0,1966,0]}
{"wire":[600,1,599,0]}
{"wire":[614,0,5,0]}
{"wire":[614,1,613,0]}
{"wire":[645,0,644,0]}
{"wire":[645,1,1997,0]}
{"wire":[647,0,1999,0]}
{"wire":[647,1,646,0]}
{"wire":[678,0,2012,0]}
{"wire":[678,1,677,0]}
{"wire":[1140,0,1137,0]}
{"wire":[1140,1,1139,0]}
{"wire":[1171,0,2261,0]}
{"wire":[1171,1,1170,0]}
{"wire":[1173,0,1160,0]}
{"wire":[1173,1,2263,0]}
{"wire":[1204,0,2276,0]}
{"wire":[1204,1,1203,0]}
{"wire":[1696,0,71,0]}
{"wire":[2232,0,1125,0]}
{"wire":[68,2,6,0]}
{"wire":[73,0,1695,0]}
{"wire":[73,1,72,0]}
{"wire":[87,0,5,0]}
{"wire":[87,1,86,0]}
{"wire":[118,0,117,0]}
{"wire":[118,1,1732,0]}
{"wire":[120,0,1734,0]}
{"wire":[120,1,119,0]}
{"wire":[151,0,1747,0]}
{"wire":[151,1,150,0]}
{"wire":[601,0,600,0]}
{"wire":[601,1,1968,0]}
{"wire":[615,0,614,0]}
{"wire":[648,0,645,0]}
{"wire":[648,1,647,0]}
{"wire":[679,0,2013,0]}
{"wire":[679,1,678,0]}
{"wire":[681,0,668,0]}
{"wire":[681,1,2015,0]}
{"wire":[712,0,2028,0]}
{"wire":[712,1,711,0]}
{"wire":[1127,0,2231,0]}
{"wire":[1127,1,1126,0]}
{"wire":[1141,0,5,0]}
{"wire":[1141,1,1140,0]}
{"wire":[1172,0,1171,0]}
{"wire":[1172,1,2262,0]}
{"wire":[1174,0,2264,0]}
{"wire":[1174,1,1173,0]}
{"wire":[1205,0,2277,0]}
{"wire":[1205,1,1204,0]}
{"wire":[1990,0,633,0]}
{"wire":[74,0,73,0]}
{"wire":[74,1,1697,0]}
{"wire":[88,0,87,0]}
{"wire":[121,0,118,0]}
{"wire":[121,1,120,0]}
{"wire":[152,0,1748,0]}
{"wire":[152,1,151,0]}
{"wire":[154,0,141,0]}
{"wire":[154,1,1750,0]}
{"wire":[185,0,1763,0]}
{"wire":[185,1,184,0]}
{"wire":[602,0,1969,0]}
{"wire":[602,1,601,0]}
{"wire":[618,0,615,0]}
{"wire":[618,1,617,0]}
{"wire":[635,0,1989,0]}
{"wire":[635,1,634,0]}
{"wire":[649,0,5,0]}
{"wire":[649,1,648,0]}
{"wire":[680,0,679,0]}
{"wire":[680,1,2014,0]}
{"wire":[682,0,2016,0]}
{"wire":[682,1,681,0]}
{"wire":[713,0,2029,0]}
{"wire":[713,1,712,0]}
{"wire":[1128,0,1127,0]}
{"wire":[1128,1,2233,0]}
{"wire":[1142,0,1141,0]}
{"wire":[1175,0,1172,0]}
{"wire":[1175,1,1174,0]}
{"wire":[1206,0,2278,0]}
{"wire":[1206,1,1205,0]}
{"wire":[1208,0,1195,0]}
{"wire":[1208,1,2280,0]}
{"wire":[1239,0,2293,0]}
{"wire":[1239,1,1238,0]}
{"wire":[1699,0,68,0]}
{"wire":[1724,0,106,0]}
{"wire":[2255,0,1160,0]}
{"wire":[11,0,10,0]}
{"wire":[75,0,1698,0]}
{"wire":[75,1,74,0]}
{"wire":[91,0,88,0]}
{"wire":[91,1,90,0]}
{"wire":[108,0,1723,0]}
{"wire":[108,1,107,0]}
{"wire":[122,0,5,0]}
{"wire":[122,1,121,0]}
{"wire":[153,0,152,0]}
{"wire":[153,1,1749,0]}
{"wire":[155,0,1751,0]}
{"wire":[155,1,154,0]}
{"wire":[186,0,1764,0]}
{"wire":[186,1,185,0]}
{"wire":[603,0,1970,0]}
{"wire":[603,1,602,0]}
{"wire":[619,0,618,0]}
{"wire":[636,0,635,0]}
{"wire":[636,1,1991,0]}
{"wire":[650,0,649,0]}
{"wire":[683,0,680,0]}
{"wire":[683,1,682,0]}
{"wire":[714,0,2030,0]}
{"wire":[714,1,713,0]}
{"wire":[716,0,703,0]}
{"wire":[716,1,2032,0]}
{"wire":[747,0,2045,0]}
{"wire":[747,1,746,0]}
{"wire":[1129,0,2234,0]}
{"wire":[1129,1,1128,0]}
{"wire":[1145,0,1142,0]}
{"wire":[1145,1,1144,0]}
{"wire":[1162,0,2254,0]}
{"wire":[1162,1,1161,0]}
{"wire":[1176,0,5,0]}
{"wire":[1176,1,1175,0]}
{"wire":[1207,0,1206,0]}
{"wire":[1207,1,2279,0]}
{"wire":[1209,0,2281,0]}
{"wire":[1209,1,1208,0]}
{"wire":[1240,0,2294,0]}
{"wire":[1240,1,1239,0]}
{"wire":[1713,0,20,0]}
{"wire":[2007,0,668,0]}
{"wire":[76,0,1700,0]}
{"wire":[76,1,75,0]}
{"wire":[92,0,91,0]}
{"wire":[109,0,108,0]}
{"wire":[109,1,1725,0]}
{"wire":[123,0,122,0]}
{"wire":[156,0,153,0]}
{"wire":[156,1,155,0]}
{"wire":[187,0,1765,0]}
{"wire":[187,1,186,0]}
{"wire":[189,0,176,0]}
{"wire":[189,1,1767,0]}
{"wire":[220,0,1780,0]}
{"wire":[220,1,219,0]}
{"wire":[604,0,6,0]}
{"wire":[604,1,603,0]}
{"wire":[604,2,1971,0]}
{"wire":[620,0,616,0]}
{"wire":[620,1,619,0]}
{"wire":[621,0,1981,0]}
{"wire":[621,1,1982,0]}
{"wire":[637,0,1992,0]}
{"wire":[637,1,636,0]}
{"wire":[653,0,650,0]}
{"wire":[653,1,652,0]}
{"wire":[670,0,2006,0]}
{"wire":[670,1,669,0]}
{"wire":[684,0,5,0]}
{"wire":[684,1,683,0]}
{"wire":[715,0,714,0]}
{"wire":[715,1,2031,0]}
{"wire":[717,0,2033,0]}
{"wire":[717,1,716,0]}
{"wire":[748,0,2046,0]}
{"wire":[748,1,747,0]}
{"wire":[1130,0,2235,0]}
{"wire":[1130,1,1129,0]}
{"wire":[1146,0,1145,0]}
{"wire":[1163,0,1162,0]}
{"wire":[1163,1,2256,0]}
{"wire":[1177,0,1176,0]}
{"wire":[1210,0,1207,0]}
{"wire":[1210,1,1209,0]}
{"wire":[1241,0,2295,0]}
{"wire":[1241,1,1240,0]}
{"wire":[1243,0,1230,0]}
{"wire":[1243,1,2297,0]}
{"wire":[1274,0,2310,0]}
{"wire":[1274,1,1273,0]}
{"wire":[1716,0,11,0]}
{"wire":[1742,0,141,0]}
{"wire":[2272,0,1195,0]}
{"wire":[77,0,6,0]}
{"wire":[77,1,76,0]}
{"wire":[77,2,1701,0]}
{"wire":[93,0,89,0]}
{"wire":[93,1,92,0]}
{"wire":[94,0,1712,0]}
{"wire":[94,1,1714,0]}
{"wire":[110,0,1726,0]}
{"wire":[110,1,109,0]}
{"wire":[126,0,123,0]}
{"wire":[126,1,125,0]}
{"wire":[143,0,1741,0]}
{"wire":[143,1,142,0]}
{"wire":[157,0,5,0]}
{"wire":[157,1,156,0]}
{"wire":[188,0,187,0]}
{"wire":[188,1,1766,0]}
{"wire":[190,0,1768,0]}
{"wire":[190,1,189,0]}
{"wire":[221,0,1781,0]}
{"wire":[221,1,220,0]}
{"wire":[597,0,596,0]}
{"wire":[605,0,604,0]}
{"wire":[623,0,621,0]}
{"wire":[623,1,622,0]}
{"wire":[626,0,1984,0]}
{"wire":[626,1,620,0]}
{"wire":[638,0,603,0]}
{"wire":[638,1,637,0]}
{"wire":[654,0,653,0]}
{"wire":[671,0,670,0]}
{"wire":[671,1,2008,0]}
{"wire":[685,0,684,0]}
{"wire":[718,0,715,0]}
{"wire":[718,1,717,0]}
{"wire":[749,0,2047,0]}
{"wire":[749,1,748,0]}
{"wire":[751,0,738,0]}
{"wire":[751,1,2049,0]}
{"wire":[782,0,2064,0]}
{"wire":[782,1,781,0]}
{"wire":[1131,0,6,0]}
{"wire":[1131,1,1130,0]}
{"wire":[1131,2,2236,0]}
{"wire":[1147,0,1143,0]}
{"wire":[1147,1,1146,0]}
{"wire":[1148,0,2246,0]}
{"wire":[1148,1,2247,0]}
{"wire":[1164,0,2257,0]}
{"wire":[1164,1,1163,0]}
{"wire":[1180,0,1177,0]}
{"wire":[1180,1,1179,0]}
{"wire":[1197,0,2271,0]}
{"wire":[1197,1,1196,0]}
{"wire":[1211,0,5,0]}
{"wire":[1211,1,1210,0]}
{"wire":[1242,0,1241,0]}
{"wire":[1242,1,2296,0]}
{"wire":[1244,0,2298,0]}
{"wire":[1244,1,1243,0]}
{"wire":[1275,0,2311,0]}
{"wire":[1275,1,1274,0]}
{"wire":[2024,0,703,0]}
{"wire":[70,0,69,0]}
{"wire":[78,0,77,0]}
{"wire":[96,0,94,0]}
{"wire":[96,1,95,0]}
{"wire":[99,0,1717,0]}
{"wire":[99,1,93,0]}
{"wire":[111,0,76,0]}
{"wire":[111,1,110,0]}
{"wire":[127,0,126,0]}
{"wire":[144,0,143,0]}
{"wire":[144,1,1743,0]}
{"wire":[158,0,157,0]}
{"wire":[191,0,188,0]}
{"wire":[191,1,190,0]}
{"wire":[222,0,1782,0]}
{"wire":[222,1,221,0]}
{"wire":[224,0,211,0]}
{"wire":[224,1,1784,0]}
{"wire":[255,0,1799,0]}
{"wire":[255,1,254,0]}
{"wire":[625,0,623,0]}
{"wire":[625,1,1983,0]}
{"wire":[625,2,624,0]}
{"wire":[627,0,626,0]}
{"wire":[627,1,605,0]}
{"wire":[639,0,6,0]}
{"wire":[639,1,638,0]}
{"wire":[639,2,1993,0]}
{"wire":[655,0,651,0]}
{"wire":[655,1,654,0]}
{"wire":[656,0,2000,0]}
{"wire":[656,1,2001,0]}
{"wire":[672,0,2009,0]}
{"wire":[672,1,671,0]}
{"wire":[688,0,685,0]}
{"wire":[688,1,687,0]}
{"wire":[705,0,2023,0]}
{"wire":[705,1,704,0]}
{"wire":[719,0,5,0]}
{"wire":[719,1,718,0]}
{"wire":[750,0,749,0]}
{"wire":[750,1,2048,0]}
{"wire":[752,0,2050,0]}
{"wire":[752,1,751,0]}
{"wire":[783,0,2065,0]}
{"wire":[783,1,782,0]}
{"wire":[1124,0,1123,0]}
{"wire":[1132,0,1131,0]}
{"wire":[1150,0,1148,0]}
{"wire":[1150,1,1149,0]}
{"wire":[1153,0,2249,0]}
{"wire":[1153,1,1147,0]}
{"wire":[1165,0,1130,0]}
{"wire":[1165,1,1164,0]}
{"wire":[1181,0,1180,0]}
{"wire":[1198,0,1197,0]}
{"wire":[1198,1,2273,0]}
{"wire":[1212,0,1211,0]}
{"wire":[1245,0,1242,0]}
{"wire":[1245,1,1244,0]}
{"wire":[1276,0,2312,0]}
{"wire":[1276,1,1275,0]}
{"wire":[1278,0,1265,0]}
{"wire":[1278,1,2314,0]}
{"wire":[1309,0,2329,0]}
{"wire":[1309,1,1308,0]}
{"wire":[1759,0,176,0]}
{"wire":[1985,0,597,0]}
{"wire":[2289,0,1230,0]}
{"wire":[98,0,96,0]}
{"wire":[98,1,1715,0]}
{"wire":[98,2,97,0]}
{"wire":[100,0,99,0]}
{"wire":[100,1,78,0]}
{"wire":[112,0,6,0]}
{"wire":[112,1,111,0]}
{"wire":[112,2,1727,0]}
{"wire":[128,0,124,0]}
{"wire":[128,1,127,0]}
{"wire":[129,0,1735,0]}
{"wire":[129,1,1736,0]}
{"wire":[145,0,1744,0]}
{"wire":[145,1,144,0]}
{"wire":[161,0,158,0]}
{"wire":[161,1,160,0]}
{"wire":[178,0,1758,0]}
{"wire":[178,1,177,0]}
{"wire":[192,0,5,0]}
{"wire":[192,1,191,0]}
{"wire":[223,0,222,0]}
{"wire":[223,1,1783,0]}
{"wire":[225,0,1785,0]}
{"wire":[225,1,224,0]}
{"wire":[256,0,1800,0]}
{"wire":[256,1,255,0]}
{"wire":[628,0,627,0]}
{"wire":[628,1,625,0]}
{"wire":[640,0,639,0]}
{"wire":[658,0,656,0]}
{"wire":[658,1,657,0]}
{"wire":[661,0,2003,0]}
{"wire":[661,1,655,0]}
{"wire":[673,0,638,0]}
{"wire":[673,1,672,0]}
{"wire":[689,0,688,0]}
{"wire":[706,0,705,0]}
{"wire":[706,1,2025,0]}
{"wire":[720,0,719,0]}
{"wire":[753,0,750,0]}
{"wire":[753,1,752,0]}
{"wire":[784,0,2066,0]}
{"wire":[784,1,783,0]}
{"wire":[786,0,773,0]}
{"wire":[786,1,2068,0]}
{"wire":[817,0,2081,0]}
{"wire":[817,1,816,0]}
{"wire":[1152,0,1150,0]}
{"wire":[1152,1,2248,0]}
{"wire":[1152,2,1151,0]}
{"wire":[1154,0,1153,0]}
{"wire":[1154,1,1132,0]}
{"wire":[1166,0,6,0]}
{"wire":[1166,1,1165,0]}
{"wire":[1166,2,2258,0]}
{"wire":[1182,0,1178,0]}
{"wire":[1182,1,1181,0]}
{"wire":[1183,0,2265,0]}
{"wire":[1183,1,2266,0]}
{"wire":[1199,0,2274,0]}
{"wire":[1199,1,1198,0]}
{"wire":[1215,0,1212,0]}
{"wire":[1215,1,1214,0]}
{"wire":[1232,0,2288,0]}
{"wire":[1232,1,1231,0]}
{"wire":[1246,0,5,0]}
{"wire":[1246,1,1245,0]}
{"wire":[1277,0,1276,0]}
{"wire":[1277,1,2313,0]}
{"wire":[1279,0,2315,0]}
{"wire":[1279,1,1278,0]}
{"wire":[1310,0,2330,0]}
{"wire":[1310,1,1309,0]}
{"wire":[1718,0,70,0]}
{"wire":[2041,0,738,0]}
{"wire":[2250,0,1124,0]}
{"wire":[101,0,100,0]}
{"wire":[101,1,98,0]}
{"wire":[113,0,112,0]}
{"wire":[131,0,129,0]}
{"wire":[131,1,130,0]}
{"wire":[134,0,1738,0]}
{"wire":[134,1,128,0]}
{"wire":[146,0,111,0]}
{"wire":[146,1,145,0]}
{"wire":[162,0,161,0]}
{"wire":[179,0,178,0]}
{"wire":[179,1,1760,0]}
{"wire":[193,0,192,0]}
{"wire":[226,0,223,0]}
{"wire":[226,1,225,0]}
{"wire":[257,0,1801,0]}
{"wire":[257,1,256,0]}
{"wire":[259,0,246,0]}
{"wire":[259,1,1803,0]}
{"wire":[290,0,1816,0]}
{"wire":[290,1,289,0]}
{"wire":[629,0,1986,0]}
{"wire":[629,1,628,0]}
{"wire":[631,0,1987,0]}
{"wire":[631,1,1988,0]}
{"wire":[660,0,658,0]}
{"wire":[660,1,2002,0]}
{"wire":[660,2,659,0]}
{"wire":[662,0,661,0]}
{"wire":[662,1,640,0]}
{"wire":[674,0,6,0]}
{"wire":[674,1,673,0]}
{"wire":[674,2,2010,0]}
{"wire":[690,0,686,0]}
{"wire":[690,1,689,0]}
{"wire":[691,0,2017,0]}
{"wire":[691,1,2018,0]}
{"wire":[707,0,2026,0]}
{"wire":[707,1,706,0]}
{"wire":[723,0,720,0]}
{"wire":[723,1,722,0]}
{"wire":[740,0,2040,0]}
{"wire":[740,1,739,0]}
{"wire":[754,0,5,0]}
{"wire":[754,1,753,0]}
{"wire":[785,0,784,0]}
{"wire":[785,1,2067,0]}
{"wire":[787,0,2069,0]}
{"wire":[787,1,786,0]}
{"wire":[818,0,2082,0]}
{"wire":[818,1,817,0]}
{"wire":[1155,0,1154,0]}
{"wire":[1155,1,1152,0]}
{"wire":[1167,0,1166,0]}
{"wire":[1185,0,1183,0]}
{"wire":[1185,1,1184,0]}
{"wire":[1188,0,2268,0]}
{"wire":[1188,1,1182,0]}
{"wire":[1200,0,1165,0]}
{"wire":[1200,1,1199,0]}
{"wire":[1216,0,1215,0]}
{"wire":[1233,0,1232,0]}
{"wire":[1233,1,2290,0]}
{"wire":[1247,0,1246,0]}
{"wire":[1280,0,1277,0]}
{"wire":[1280,1,1279,0]}
{"wire":[1311,0,2331,0]}
{"wire":[1311,1,1310,0]}
{"wire":[1313,0,1300,0]}
{"wire":[1313,1,2333,0]}
{"wire":[1344,0,2346,0]}
{"wire":[1344,1,1343,0]}
{"wire":[1776,0,211,0]}
{"wire":[2306,0,1265,0]}
{"wire":[102,0,1719,0]}
{"wire":[102,1,101,0]}
{"wire":[104,0,1721,0]}
{"wire":[104,1,1722,0]}
{"wire":[133,0,131,0]}
{"wire":[133,1,1737,0]}
{"wire":[133,2,132,0]}
{"wire":[135,0,134,0]}
{"wire":[135,1,113,0]}
{"wire":[147,0,6,0]}
{"wire":[147,1,146,0]}
{"wire":[147,2,1745,0]}
{"wire":[163,0,159,0]}
{"wire":[163,1,162,0]}
{"wire":[164,0,1752,0]}
{"wire":[164,1,1753,0]}
{"wire":[180,0,1761,0]}
{"wire":[180,1,179,0]}
{"wire":[196,0,193,0]}
{"wire":[196,1,195,0]}
{"wire":[213,0,1775,0]}
{"wire":[213,1,212,0]}
{"wire":[227,0,5,0]}
{"wire":[227,1,226,0]}
{"wire":[258,0,257,0]}
{"wire":[258,1,1802,0]}
{"wire":[260,0,1804,0]}
{"wire":[260,1,259,0]}
{"wire":[291,0,1817,0]}
{"wire":[291,1,290,0]}
{"wire":[630,0,631,0]}
{"wire":[630,1,632,0]}
{"wire":[630,2,629,0]}
{"wire":[630,3,2499,0]}
{"wire":[630,4,2499,0]}
{"wire":[663,0,662,0]}
{"wire":[663,1,660,0]}
{"wire":[675,0,674,0]}
{"wire":[693,0,691,0]}
{"wire":[693,1,692,0]}
{"wire":[696,0,2020,0]}
{"wire":[696,1,690,0]}
{"wire":[708,0,673,0]}
{"wire":[708,1,707,0]}
{"wire":[724,0,723,0]}
{"wire":[741,0,740,0]}
{"wire":[741,1,2042,0]}
{"wire":[755,0,754,0]}
{"wire":[788,0,785,0]}
{"wire":[788,1,787,0]}
{"wire":[819,0,2083,0]}
{"wire":[819,1,818,0]}
{"wire":[821,0,808,0]}
{"wire":[821,1,2085,0]}
{"wire":[852,0,2098,0]}
{"wire":[852,1,851,0]}
{"wire":[1156,0,2251,0]}
{"wire":[1156,1,1155,0]}
{"wire":[1158,0,2252,0]}
{"wire":[1158,1,2253,0]}
{"wire":[1187,0,1185,0]}
{"wire":[1187,1,2267,0]}
{"wire":[1187,2,1186,0]}
{"wire":[1189,0,1188,0]}
{"wire":[1189,1,1167,0]}
{"wire":[1201,0,6,0]}
{"wire":[1201,1,1200,0]}
{"wire":[1201,2,2275,0]}
{"wire":[1217,0,1213,0]}
{"wire":[1217,1,1216,0]}
{"wire":[1218,0,2282,0]}
{"wire":[1218,1,2283,0]}
{"wire":[1234,0,2291,0]}
{"wire":[1234,1,1233,0]}
{"wire":[1250,0,1247,0]}
{"wire":[1250,1,1249,0]}
{"wire":[1267,0,2305,0]}
{"wire":[1267,1,1266,0]}
{"wire":[1281,0,5,0]}
{"wire":[1281,1,1280,0]}
{"wire":[1312,0,1311,0]}
{"wire":[1312,1,2332,0]}
{"wire":[1314,0,2334,0]}
{"wire":[1314,1,1313,0]}
{"wire":[1345,0,2347,0]}
{"wire":[1345,1,1344,0]}
{"wire":[2058,0,773,0]}
{"wire":[103,0,104,0]}
{"wire":[103,1,105,0]}
{"wire":[103,2,102,0]}
{"wire":[103,3,2498,0]}
{"wire":[103,4,2498,0]}
{"wire":[136,0,135,0]}
{"wire":[136,1,133,0]}
{"wire":[148,0,147,0]}
{"wire":[166,0,164,0]}
{"wire":[166,1,165,0]}
{"wire":[169,0,1755,0]}
{"wire":[169,1,163,0]}
{"wire":[181,0,146,0]}
{"wire":[181,1,180,0]}
{"wire":[197,0,196,0]}
{"wire":[214,0,213,0]}
{"wire":[214,1,1777,0]}
{"wire":[228,0,227,0]}
{"wire":[261,0,258,0]}
{"wire":[261,1,260,0]}
{"wire":[292,0,1818,0]}
{"wire":[292,1,291,0]}
{"wire":[294,0,281,0]}
{"wire":[294,1,1820,0]}
{"wire":[325,0,1833,0]}
{"wire":[325,1,324,0]}
{"wire":[664,0,630,0]}
{"wire":[664,1,663,0]}
{"wire":[666,0,2004,0]}
{"wire":[666,1,2005,0]}
{"wire":[695,0,693,0]}
{"wire":[695,1,2019,0]}
{"wire":[695,2,694,0]}
{"wire":[697,0,696,0]}
{"wire":[697,1,675,0]}
{"wire":[709,0,6,0]}
{"wire":[709,1,708,0]}
{"wire":[709,2,2027,0]}
{"wire":[725,0,721,0]}
{"wire":[725,1,724,0]}
{"wire":[726,0,2034,0]}
{"wire":[726,1,2035,0]}
{"wire":[742,0,2043,0]}
{"wire":[742,1,741,0]}
{"wire":[758,0,755,0]}
{"wire":[758,1,757,0]}
{"wire":[775,0,2057,0]}
{"wire":[775,1,774,0]}
{"wire":[789,0,5,0]}
{"wire":[789,1,788,0]}
{"wire":[820,0,819,0]}
{"wire":[820,1,2084,0]}
{"wire":[822,0,2086,0]}
{"wire":[822,1,821,0]}
{"wire":[853,0,2099,0]}
{"wire":[853,1,852,0]}
{"wire":[1157,0,1158,0]}
{"wire":[1157,1,1159,0]}
{"wire":[1157,2,1156,0]}
{"wire":[1157,3,2500,0]}
{"wire":[1157,4,2500,0]}
{"wire":[1190,0,1189,0]}
{"wire":[1190,1,1187,0]}
{"wire":[1202,0,1201,0]}
{"wire":[1220,0,1218,0]}
{"wire":[1220,1,1219,0]}
{"wire":[1223,0,2285,0]}
{"wire":[1223,1,1217,0]}
{"wire":[1235,0,1200,0]}
{"wire":[1235,1,1234,0]}
{"wire":[1251,0,1250,0]}
{"wire":[1268,0,1267,0]}
{"wire":[1268,1,2307,0]}
{"wire":[1282,0,1281,0]}
{"wire":[1315,0,1312,0]}
{"wire":[1315,1,1314,0]}
{"wire":[1346,0,2348,0]}
{"wire":[1346,1,1345,0]}
{"wire":[1348,0,1335,0]}
{"wire":[1348,1,2350,0]}
{"wire":[1379,0,2363,0]}
{"wire":[1379,1,1378,0]}
{"wire":[1793,0,246,0]}
{"wire":[2323,0,1300,0]}
{"wire":[137,0,103,0]}
{"wire":[137,1,136,0]}
{"wire":[139,0,1739,0]}
{"wire":[139,1,1740,0]}
{"wire":[168,0,166,0]}
{"wire":[168,1,1754,0]}
{"wire":[168,2,167,0]}
{"wire":[170,0,169,0]}
{"wire":[170,1,148,0]}
{"wire":[182,0,6,0]}
{"wire":[182,1,181,0]}
{"wire":[182,2,1762,0]}
{"wire":[198,0,194,0]}
{"wire":[198,1,197,0]}
{"wire":[199,0,1769,0]}
{"wire":[199,1,1770,0]}
{"wire":[215,0,1778,0]}
{"wire":[215,1,214,0]}
{"wire":[231,0,228,0]}
{"wire":[231,1,230,0]}
{"wire":[248,0,1792,0]}
{"wire":[248,1,247,0]}
{"wire":[262,0,5,0]}
{"wire":[262,1,261,0]}
{"wire":[293,0,292,0]}
{"wire":[293,1,1819,0]}
{"wire":[295,0,1821,0]}
{"wire":[295,1,294,0]}
{"wire":[326,0,1834,0]}
{"wire":[326,1,325,0]}
{"wire":[665,0,666,0]}
{"wire":[665,1,667,0]}
{"wire":[665,2,664,0]}
{"wire":[665,3,630,0]}
{"wire":[665,4,630,0]}
{"wire":[698,0,697,0]}
{"wire":[698,1,695,0]}
{"wire":[710,0,709,0]}
{"wire":[728,0,726,0]}
{"wire":[728,1,727,0]}
{"wire":[731,0,2037,0]}
{"wire":[731,1,725,0]}
{"wire":[743,0,708,0]}
{"wire":[743,1,742,0]}
{"wire":[759,0,758,0]}
{"wire":[776,0,775,0]}
{"wire":[776,1,2059,0]}
{"wire":[790,0,789,0]}
{"wire":[823,0,820,0]}
{"wire":[823,1,822,0]}
{"wire":[854,0,2100,0]}
{"wire":[854,1,853,0]}
{"wire":[856,0,843,0]}
{"wire":[856,1,2102,0]}
{"wire":[887,0,2115,0]}
{"wire":[887,1,886,0]}
{"wire":[1191,0,1157,0]}
{"wire":[1191,1,1190,0]}
{"wire":[1193,0,2269,0]}
{"wire":[1193,1,2270,0]}
{"wire":[1222,0,1220,0]}
{"wire":[1222,1,2284,0]}
{"wire":[1222,2,1221,0]}
{"wire":[1224,0,1223,0]}
{"wire":[1224,1,1202,0]}
{"wire":[1236,0,6,0]}
{"wire":[1236,1,1235,0]}
{"wire":[1236,2,2292,0]}
{"wire":[1252,0,1248,0]}
{"wire":[1252,1,1251,0]}
{"wire":[1253,0,2299,0]}
{"wire":[1253,1,2300,0]}
{"wire":[1269,0,2308,0]}
{"wire":[1269,1,1268,0]}
{"wire":[1285,0,1282,0]}
{"wire":[1285,1,1284,0]}
{"wire":[1302,0,2322,0]}
{"wire":[1302,1,1301,0]}
{"wire":[1316,0,5,0]}
{"wire":[1316,1,1315,0]}
{"wire":[1347,0,1346,0]}
{"wire":[1347,1,2349,0]}
{"wire":[1349,0,2351,0]}
{"wire":[1349,1,1348,0]}
{"wire":[1380,0,2364,0]}
{"wire":[1380,1,1379,0]}
{"wire":[2061,0,743,0]}
{"wire":[2077,0,808,0]}
{"wire":[138,0,139,0]}
{"wire":[138,1,140,0]}
{"wire":[138,2,137,0]}
{"wire":[138,3,103,0]}
{"wire":[138,4,103,0]}
{"wire":[171,0,170,0]}
{"wire":[171,1,168,0]}
{"wire":[183,0,182,0]}
{"wire":[201,0,199,0]}
{"wire":[201,1,200,0]}
{"wire":[204,0,1772,0]}
{"wire":[204,1,198,0]}
{"wire":[216,0,181,0]}
{"wire":[216,1,215,0]}
{"wire":[232,0,231,0]}
{"wire":[249,0,248,0]}
{"wire":[249,1,1794,0]}
{"wire":[263,0,262,0]}
{"wire":[296,0,293,0]}
{"wire":[296,1,295,0]}
{"wire":[327,0,1835,0]}
{"wire":[327,1,326,0]}
{"wire":[329,0,316,0]}
{"wire":[329,1,1837,0]}
{"wire":[360,0,1850,0]}
{"wire":[360,1,359,0]}
{"wire":[699,0,665,0]}
{"wire":[699,1,698,0]}
{"wire":[701,0,2021,0]}
{"wire":[701,1,2022,0]}
{"wire":[730,0,728,0]}
{"wire":[730,1,2036,0]}
{"wire":[730,2,729,0]}
{"wire":[732,0,731,0]}
{"wire":[732,1,710,0]}
{"wire":[744,0,6,0]}
{"wire":[744,1,743,0]}
{"wire":[744,2,2044,0]}
{"wire":[760,0,756,0]}
{"wire":[760,1,759,0]}
{"wire":[761,0,2051,0]}
{"wire":[761,1,2052,0]}
{"wire":[777,0,2060,0]}
{"wire":[777,1,776,0]}
{"wire":[793,0,790,0]}
{"wire":[793,1,792,0]}
{"wire":[810,0,2076,0]}
{"wire":[810,1,809,0]}
{"wire":[824,0,5,0]}
{"wire":[824,1,823,0]}
{"wire":[855,0,854,0]}
{"wire":[855,1,2101,0]}
{"wire":[857,0,2103,0]}
{"wire":[857,1,856,0]}
{"wire":[888,0,2116,0]}
{"wire":[888,1,887,0]}
{"wire":[1192,0,1193,0]}
{"wire":[1192,1,1194,0]}
{"wire":[1192,2,1191,0]}
{"wire":[1192,3,1157,0]}
{"wire":[1192,4,1157,0]}
{"wire":[1225,0,1224,0]}
{"wire":[1225,1,1222,0]}
{"wire":[1237,0,1236,0]}
{"wire":[1255,0,1253,0]}
{"wire":[1255,1,1254,0]}
{"wire":[1258,0,2302,0]}
{"wire":[1258,1,1252,0]}
{"wire":[1270,0,1235,0]}
{"wire":[1270,1,1269,0]}
{"wire":[1286,0,1285,0]}
{"wire":[1303,0,1302,0]}
{"wire":[1303,1,2324,0]}
{"wire":[1317,0,1316,0]}
{"wire":[1350,0,1347,0]}
{"wire":[1350,1,1349,0]}
{"wire":[1381,0,2365,0]}
{"wire":[1381,1,1380,0]}
{"wire":[1383,0,1370,0]}
{"wire":[1383,1,2367,0]}
{"wire":[1414,0,2380,0]}
{"wire":[1414,1,1413,0]}
{"wire":[1796,0,216,0]}
{"wire":[1812,0,281,0]}
{"wire":[2326,0,1270,0]}
{"wire":[2342,0,1335,0]}
{"wire":[172,0,138,0]}
{"wire":[172,1,171,0]}
{"wire":[174,0,1756,0]}
{"wire":[174,1,1757,0]}
{"wire":[203,0,201,0]}
{"wire":[203,1,1771,0]}
{"wire":[203,2,202,0]}
{"wire":[205,0,204,0]}
{"wire":[205,1,183,0]}
{"wire":[217,0,6,0]}
{"wire":[217,1,216,0]}
{"wire":[217,2,1779,0]}
{"wire":[233,0,229,0]}
{"wire":[233,1,232,0]}
{"wire":[234,0,1786,0]}
{"wire":[234,1,1787,0]}
{"wire":[250,0,1795,0]}
{"wire":[250,1,249,0]}
{"wire":[266,0,263,0]}
{"wire":[266,1,265,0]}
{"wire":[283,0,1811,0]}
{"wire":[283,1,282,0]}
{"wire":[297,0,5,0]}
{"wire":[297,1,296,0]}
{"wire":[328,0,327,0]}
{"wire":[328,1,1836,0]}
{"wire":[330,0,1838,0]}
{"wire":[330,1,329,0]}
{"wire":[361,0,1851,0]}
{"wire":[361,1,360,0]}
{"wire":[700,0,701,0]}
{"wire":[700,1,702,0]}
{"wire":[700,2,699,0]}
{"wire":[700,3,665,0]}
{"wire":[700,4,665,0]}
{"wire":[733,0,732,0]}
{"wire":[733,1,730,0]}
{"wire":[745,0,744,0]}
{"wire":[763,0,761,0]}
{"wire":[763,1,762,0]}
{"wire":[766,0,2054,0]}
{"wire":[766,1,760,0]}
{"wire":[778,0,2062,0]}
{"wire":[778,1,777,0]}
{"wire":[794,0,793,0]}
{"wire":[811,0,810,0]}
{"wire":[811,1,2078,0]}
{"wire":[825,0,824,0]}
{"wire":[858,0,855,0]}
{"wire":[858,1,857,0]}
{"wire":[889,0,2117,0]}
{"wire":[889,1,888,0]}
{"wire":[891,0,878,0]}
{"wire":[891,1,2119,0]}
{"wire":[922,0,2132,0]}
{"wire":[922,1,921,0]}
{"wire":[1226,0,1192,0]}
{"wire":[1226,1,1225,0]}
{"wire":[1228,0,2286,0]}
{"wire":[1228,1,2287,0]}
{"wire":[1257,0,1255,0]}
{"wire":[1257,1,2301,0]}
{"wire":[1257,2,1256,0]}
{"wire":[1259,0,1258,0]}
{"wire":[1259,1,1237,0]}
{"wire":[1271,0,6,0]}
{"wire":[1271,1,1270,0]}
{"wire":[1271,2,2309,0]}
{"wire":[1287,0,1283,0]}
{"wire":[1287,1,1286,0]}
{"wire":[1288,0,2316,0]}
{"wire":[1288,1,2317,0]}
{"wire":[1304,0,2325,0]}
{"wire":[1304,1,1303,0]}
{"wire":[1320,0,1317,0]}
{"wire":[1320,1,1319,0]}
{"wire":[1337,0,2341,0]}
{"wire":[1337,1,1336,0]}
{"wire":[1351,0,5,0]}
{"wire":[1351,1,1350,0]}
{"wire":[1382,0,1381,0]}
{"wire":[1382,1,2366,0]}
{"wire":[1384,0,2368,0]}
{"wire":[1384,1,1383,0]}
{"wire":[1415,0,2381,0]}
{"wire":[1415,1,1414,0]}
{"wire":[2094,0,843,0]}
{"wire":[173,0,174,0]}
{"wire":[173,1,175,0]}
{"wire":[173,2,172,0]}
{"wire":[173,3,138,0]}
{"wire":[173,4,138,0]}
{"wire":[206,0,205,0]}
{"wire":[206,1,203,0]}
{"wire":[218,0,217,0]}
{"wire":[236,0,234,0]}
{"wire":[236,1,235,0]}
{"wire":[239,0,1789,0]}
{"wire":[239,1,233,0]}
{"wire":[251,0,1797,0]}
{"wire":[251,1,250,0]}
{"wire":[267,0,266,0]}
{"wire":[284,0,283,0]}
{"wire":[284,1,1813,0]}
{"wire":[298,0,297,0]}
{"wire":[331,0,328,0]}
{"wire":[331,1,330,0]}
{"wire":[362,0,1852,0]}
{"wire":[362,1,361,0]}
{"wire":[364,0,351,0]}
{"wire":[364,1,1854,0]}
{"wire":[395,0,1867,0]}
{"wire":[395,1,394,0]}
{"wire":[734,0,700,0]}
{"wire":[734,1,733,0]}
{"wire":[736,0,2038,0]}
{"wire":[736,1,2039,0]}
{"wire":[765,0,763,0]}
{"wire":[765,1,2053,0]}
{"wire":[765,2,764,0]}
{"wire":[767,0,766,0]}
{"wire":[767,1,745,0]}
{"wire":[779,0,6,0]}
{"wire":[779,1,778,0]}
{"wire":[779,2,2063,0]}
{"wire":[795,0,791,0]}
{"wire":[795,1,794,0]}
{"wire":[796,0,2070,0]}
{"wire":[796,1,2071,0]}
{"wire":[812,0,2079,0]}
{"wire":[812,1,811,0]}
{"wire":[828,0,825,0]}
{"wire":[828,1,827,0]}
{"wire":[845,0,2093,0]}
{"wire":[845,1,844,0]}
{"wire":[859,0,5,0]}
{"wire":[859,1,858,0]}
{"wire":[890,0,889,0]}
{"wire":[890,1,2118,0]}
{"wire":[892,0,2120,0]}
{"wire":[892,1,891,0]}
{"wire":[923,0,2133,0]}
{"wire":[923,1,922,0]}
{"wire":[1227,0,1228,0]}
{"wire":[1227,1,1229,0]}
{"wire":[1227,2,1226,0]}
{"wire":[1227,3,1192,0]}
{"wire":[1227,4,1192,0]}
{"wire":[1260,0,1259,0]}
{"wire":[1260,1,1257,0]}
{"wire":[1272,0,1271,0]}
{"wire":[1290,0,1288,0]}
{"wire":[1290,1,1289,0]}
{"wire":[1293,0,2319,0]}
{"wire":[1293,1,1287,0]}
{"wire":[1305,0,2327,0]}
{"wire":[1305,1,1304,0]}
{"wire":[1321,0,1320,0]}
{"wire":[1338,0,1337,0]}
{"wire":[1338,1,2343,0]}
{"wire":[1352,0,1351,0]}
{"wire":[1385,0,1382,0]}
{"wire":[1385,1,1384,0]}
{"wire":[1416,0,2382,0]}
{"wire":[1416,1,1415,0]}
{"wire":[1418,0,1405,0]}
{"wire":[1418,1,2384,0]}
{"wire":[1449,0,2397,0]}
{"wire":[1449,1,1448,0]}
{"wire":[1829,0,316,0]}
{"wire":[2359,0,1370,0]}
{"wire":[207,0,173,0]}
{"wire":[207,1,206,0]}
{"wire":[209,0,1773,0]}
{"wire":[209,1,1774,0]}
{"wire":[238,0,236,0]}
{"wire":[238,1,1788,0]}
{"wire":[238,2,237,0]}
{"wire":[240,0,239,0]}
{"wire":[240,1,218,0]}
{"wire":[252,0,6,0]}
{"wire":[252,1,251,0]}
{"wire":[252,2,1798,0]}
{"wire":[268,0,264,0]}
{"wire":[268,1,267,0]}
{"wire":[269,0,1805,0]}
{"wire":[269,1,1806,0]}
{"wire":[285,0,1814,0]}
{"wire":[285,1,284,0]}
{"wire":[301,0,298,0]}
{"wire":[301,1,300,0]}
{"wire":[318,0,1828,0]}
{"wire":[318,1,317,0]}
{"wire":[332,0,5,0]}
{"wire":[332,1,331,0]}
{"wire":[363,0,362,0]}
{"wire":[363,1,1853,0]}
{"wire":[365,0,1855,0]}
{"wire":[365,1,364,0]}
{"wire":[396,0,1868,0]}
{"wire":[396,1,395,0]}
{"wire":[735,0,736,0]}
{"wire":[735,1,737,0]}
{"wire":[735,2,734,0]}
{"wire":[735,3,700,0]}
{"wire":[735,4,700,0]}
{"wire":[768,0,767,0]}
{"wire":[768,1,765,0]}
{"wire":[780,0,779,0]}
{"wire":[798,0,796,0]}
{"wire":[798,1,797,0]}
{"wire":[801,0,2073,0]}
{"wire":[801,1,795,0]}
{"wire":[813,0,778,0]}
{"wire":[813,1,812,0]}
{"wire":[829,0,828,0]}
{"wire":[846,0,845,0]}
{"wire":[846,1,2095,0]}
{"wire":[860,0,859,0]}
{"wire":[893,0,890,0]}
{"wire":[893,1,892,0]}
{"wire":[924,0,2134,0]}
{"wire":[924,1,923,0]}
{"wire":[926,0,913,0]}
{"wire":[926,1,2136,0]}
{"wire":[957,0,2151,0]}
{"wire":[957,1,956,0]}
{"wire":[1261,0,1227,0]}
{"wire":[1261,1,1260,0]}
{"wire":[1263,0,2303,0]}
{"wire":[1263,1,2304,0]}
{"wire":[1292,0,1290,0]}
{"wire":[1292,1,2318,0]}
{"wire":[1292,2,1291,0]}
{"wire":[1294,0,1293,0]}
{"wire":[1294,1,1272,0]}
{"wire":[1306,0,6,0]}
{"wire":[1306,1,1305,0]}
{"wire":[1306,2,2328,0]}
{"wire":[1322,0,1318,0]}
{"wire":[1322,1,1321,0]}
{"wire":[1323,0,2335,0]}
{"wire":[1323,1,2336,0]}
{"wire":[1339,0,2344,0]}
{"wire":[1339,1,1338,0]}
{"wire":[1355,0,1352,0]}
{"wire":[1355,1,1354,0]}
{"wire":[1372,0,2358,0]}
{"wire":[1372,1,1371,0]}
{"wire":[1386,0,5,0]}
{"wire":[1386,1,1385,0]}
{"wire":[1417,0,1416,0]}
{"wire":[1417,1,2383,0]}
{"wire":[1419,0,2385,0]}
{"wire":[1419,1,1418,0]}
{"wire":[1450,0,2398,0]}
{"wire":[1450,1,1449,0]}
{"wire":[2111,0,878,0]}
{"wire":[208,0,209,0]}
{"wire":[208,1,210,0]}
{"wire":[208,2,207,0]}
{"wire":[208,3,173,0]}
{"wire":[208,4,173,0]}
{"wire":[241,0,240,0]}
{"wire":[241,1,238,0]}
{"wire":[253,0,252,0]}
{"wire":[271,0,269,0]}
{"wire":[271,1,270,0]}
{"wire":[274,0,1808,0]}
{"wire":[274,1,268,0]}
{"wire":[286,0,251,0]}
{"wire":[286,1,285,0]}
{"wire":[302,0,301,0]}
{"wire":[319,0,318,0]}
{"wire":[319,1,1830,0]}
{"wire":[333,0,332,0]}
{"wire":[366,0,363,0]}
{"wire":[366,1,365,0]}
{"wire":[397,0,1869,0]}
{"wire":[397,1,396,0]}
{"wire":[399,0,386,0]}
{"wire":[399,1,1871,0]}
{"wire":[430,0,1886,0]}
{"wire":[430,1,429,0]}
{"wire":[769,0,735,0]}
{"wire":[769,1,768,0]}
{"wire":[771,0,2055,0]}
{"wire":[771,1,2056,0]}
{"wire":[800,0,798,0]}
{"wire":[800,1,2072,0]}
{"wire":[800,2,799,0]}
{"wire":[802,0,801,0]}
{"wire":[802,1,780,0]}
{"wire":[814,0,6,0]}
{"wire":[814,1,813,0]}
{"wire":[814,2,2080,0]}
{"wire":[830,0,826,0]}
{"wire":[830,1,829,0]}
{"wire":[831,0,2087,0]}
{"wire":[831,1,2088,0]}
{"wire":[847,0,2096,0]}
{"wire":[847,1,846,0]}
{"wire":[863,0,860,0]}
{"wire":[863,1,862,0]}
{"wire":[880,0,2110,0]}
{"wire":[880,1,879,0]}
{"wire":[894,0,5,0]}
{"wire":[894,1,893,0]}
{"wire":[925,0,924,0]}
{"wire":[925,1,2135,0]}
{"wire":[927,0,2137,0]}
{"wire":[927,1,926,0]}
{"wire":[958,0,2152,0]}
{"wire":[958,1,957,0]}
{"wire":[1262,0,1263,0]}
{"wire":[1262,1,1264,0]}
{"wire":[1262,2,1261,0]}
{"wire":[1262,3,1227,0]}
{"wire":[1262,4,1227,0]}
{"wire":[1295,0,1294,0]}
{"wire":[1295,1,1292,0]}
{"wire":[1307,0,1306,0]}
{"wire":[1325,0,1323,0]}
{"wire":[1325,1,1324,0]}
{"wire":[1328,0,2338,0]}
{"wire":[1328,1,1322,0]}
{"wire":[1340,0,1305,0]}
{"wire":[1340,1,1339,0]}
{"wire":[1356,0,1355,0]}
{"wire":[1373,0,1372,0]}
{"wire":[1373,1,2360,0]}
{"wire":[1387,0,1386,0]}
{"wire":[1420,0,1417,0]}
{"wire":[1420,1,1419,0]}
{"wire":[1451,0,2399,0]}
{"wire":[1451,1,1450,0]}
{"wire":[1453,0,1440,0]}
{"wire":[1453,1,2401,0]}
{"wire":[1484,0,2416,0]}
{"wire":[1484,1,1483,0]}
{"wire":[1846,0,351,0]}
{"wire":[2376,0,1405,0]}
{"wire":[242,0,208,0]}
{"wire":[242,1,241,0]}
{"wire":[244,0,1790,0]}
{"wire":[244,1,1791,0]}
{"wire":[273,0,271,0]}
{"wire":[273,1,1807,0]}
{"wire":[273,2,272,0]}
{"wire":[275,0,274,0]}
{"wire":[275,1,253,0]}
{"wire":[287,0,6,0]}
{"wire":[287,1,286,0]}
{"wire":[287,2,1815,0]}
{"wire":[303,0,299,0]}
{"wire":[303,1,302,0]}
{"wire":[304,0,1822,0]}
{"wire":[304,1,1823,0]}
{"wire":[320,0,1831,0]}
{"wire":[320,1,319,0]}
{"wire":[336,0,333,0]}
{"wire":[336,1,335,0]}
{"wire":[353,0,1845,0]}
{"wire":[353,1,352,0]}
{"wire":[367,0,5,0]}
{"wire":[367,1,366,0]}
{"wire":[398,0,397,0]}
{"wire":[398,1,1870,0]}
{"wire":[400,0,1872,0]}
{"wire":[400,1,399,0]}
{"wire":[431,0,1887,0]}
{"wire":[431,1,430,0]}
{"wire":[770,0,771,0]}
{"wire":[770,1,772,0]}
{"wire":[770,2,769,0]}
{"wire":[770,3,735,0]}
{"wire":[770,4,735,0]}
{"wire":[803,0,802,0]}
{"wire":[803,1,800,0]}
{"wire":[815,0,814,0]}
{"wire":[833,0,831,0]}
{"wire":[833,1,832,0]}
{"wire":[836,0,2090,0]}
{"wire":[836,1,830,0]}
{"wire":[848,0,813,0]}
{"wire":[848,1,847,0]}
{"wire":[864,0,863,0]}
{"wire":[881,0,880,0]}
{"wire":[881,1,2112,0]}
{"wire":[895,0,894,0]}
{"wire":[928,0,925,0]}
{"wire":[928,1,927,0]}
{"wire":[959,0,2153,0]}
{"wire":[959,1,958,0]}
{"wire":[961,0,948,0]}
{"wire":[961,1,2155,0]}
{"wire":[992,0,2168,0]}
{"wire":[992,1,991,0]}
{"wire":[1296,0,1262,0]}
{"wire":[1296,1,1295,0]}
{"wire":[1298,0,2320,0]}
{"wire":[1298,1,2321,0]}
{"wire":[1327,0,1325,0]}
{"wire":[1327,1,2337,0]}
{"wire":[1327,2,1326,0]}
{"wire":[1329,0,1328,0]}
{"wire":[1329,1,1307,0]}
{"wire":[1341,0,6,0]}
{"wire":[1341,1,1340,0]}
{"wire":[1341,2,2345,0]}
{"wire":[1357,0,1353,0]}
{"wire":[1357,1,1356,0]}
{"wire":[1358,0,2352,0]}
{"wire":[1358,1,2353,0]}
{"wire":[1374,0,2361,0]}
{"wire":[1374,1,1373,0]}
{"wire":[1390,0,1387,0]}
{"wire":[1390,1,1389,0]}
{"wire":[1407,0,2375,0]}
{"wire":[1407,1,1406,0]}
{"wire":[1421,0,5,0]}
{"wire":[1421,1,1420,0]}
{"wire":[1452,0,1451,0]}
{"wire":[1452,1,2400,0]}
{"wire":[1454,0,2402,0]}
{"wire":[1454,1,1453,0]}
{"wire":[1485,0,2417,0]}
{"wire":[1485,1,1484,0]}
{"wire":[2128,0,913,0]}
{"wire":[243,0,244,0]}
{"wire":[243,1,245,0]}
{"wire":[243,2,242,0]}
{"wire":[243,3,208,0]}
{"wire":[243,4,208,0]}
{"wire":[276,0,275,0]}
{"wire":[276,1,273,0]}
{"wire":[288,0,287,0]}
{"wire":[306,0,304,0]}
{"wire":[306,1,305,0]}
{"wire":[309,0,1825,0]}
{"wire":[309,1,303,0]}
{"wire":[321,0,286,0]}
{"wire":[321,1,320,0]}
{"wire":[337,0,336,0]}
{"wire":[354,0,353,0]}
{"wire":[354,1,1847,0]}
{"wire":[368,0,367,0]}
{"wire":[401,0,398,0]}
{"wire":[401,1,400,0]}
{"wire":[432,0,1888,0]}
{"wire":[432,1,431,0]}
{"wire":[434,0,421,0]}
{"wire":[434,1,1890,0]}
{"wire":[465,0,1903,0]}
{"wire":[465,1,464,0]}
{"wire":[804,0,770,0]}
{"wire":[804,1,803,0]}
{"wire":[806,0,2074,0]}
{"wire":[806,1,2075,0]}
{"wire":[835,0,833,0]}
{"wire":[835,1,2089,0]}
{"wire":[835,2,834,0]}
{"wire":[837,0,836,0]}
{"wire":[837,1,815,0]}
{"wire":[849,0,6,0]}
{"wire":[849,1,848,0]}
{"wire":[849,2,2097,0]}
{"wire":[865,0,861,0]}
{"wire":[865,1,864,0]}
{"wire":[866,0,2104,0]}
{"wire":[866,1,2105,0]}
{"wire":[882,0,2113,0]}
{"wire":[882,1,881,0]}
{"wire":[898,0,895,0]}
{"wire":[898,1,897,0]}
{"wire":[915,0,2127,0]}
{"wire":[915,1,914,0]}
{"wire":[929,0,5,0]}
{"wire":[929,1,928,0]}
{"wire":[960,0,959,0]}
{"wire":[960,1,2154,0]}
{"wire":[962,0,2156,0]}
{"wire":[962,1,961,0]}
{"wire":[993,0,2169,0]}
{"wire":[993,1,992,0]}
{"wire":[1297,0,1298,0]}
{"wire":[1297,1,1299,0]}
{"wire":[1297,2,1296,0]}
{"wire":[1297,3,1262,0]}
{"wire":[1297,4,1262,0]}
{"wire":[1330,0,1329,0]}
{"wire":[1330,1,1327,0]}
{"wire":[1342,0,1341,0]}
{"wire":[1360,0,1358,0]}
{"wire":[1360,1,1359,0]}
{"wire":[1363,0,2355,0]}
{"wire":[1363,1,1357,0]}
{"wire":[1375,0,1340,0]}
{"wire":[1375,1,1374,0]}
{"wire":[1391,0,1390,0]}
{"wire":[1408,0,1407,0]}
{"wire":[1408,1,2377,0]}
{"wire":[1422,0,1421,0]}
{"wire":[1455,0,1452,0]}
{"wire":[1455,1,1454,0]}
{"wire":[1486,0,2418,0]}
{"wire":[1486,1,1485,0]}
{"wire":[1488,0,1475,0]}
{"wire":[1488,1,2420,0]}
{"wire":[1519,0,2433,0]}
{"wire":[1519,1,1518,0]}
{"wire":[1863,0,386,0]}
{"wire":[2393,0,1440,0]}
{"wire":[277,0,243,0]}
{"wire":[277,1,276,0]}
{"wire":[279,0,1809,0]}
{"wire":[279,1,1810,0]}
{"wire":[308,0,306,0]}
{"wire":[308,1,1824,0]}
{"wire":[308,2,307,0]}
{"wire":[310,0,309,0]}
{"wire":[310,1,288,0]}
{"wire":[322,0,6,0]}
{"wire":[322,1,321,0]}
{"wire":[322,2,1832,0]}
{"wire":[338,0,334,0]}
{"wire":[338,1,337,0]}
{"wire":[339,0,1839,0]}
{"wire":[339,1,1840,0]}
{"wire":[355,0,1848,0]}
{"wire":[355,1,354,0]}
{"wire":[371,0,368,0]}
{"wire":[371,1,370,0]}
{"wire":[388,0,1862,0]}
{"wire":[388,1,387,0]}
{"wire":[402,0,5,0]}
{"wire":[402,1,401,0]}
{"wire":[433,0,432,0]}
{"wire":[433,1,1889,0]}
{"wire":[435,0,1891,0]}
{"wire":[435,1,434,0]}
{"wire":[466,0,1904,0]}
{"wire":[466,1,465,0]}
{"wire":[805,0,806,0]}
{"wire":[805,1,807,0]}
{"wire":[805,2,804,0]}
{"wire":[805,3,770,0]}
{"wire":[805,4,770,0]}
{"wire":[838,0,837,0]}
{"wire":[838,1,835,0]}
{"wire":[850,0,849,0]}
{"wire":[868,0,866,0]}
{"wire":[868,1,867,0]}
{"wire":[871,0,2107,0]}
{"wire":[871,1,865,0]}
{"wire":[883,0,848,0]}
{"wire":[883,1,882,0]}
{"wire":[899,0,898,0]}
{"wire":[916,0,915,0]}
{"wire":[916,1,2129,0]}
{"wire":[930,0,929,0]}
{"wire":[963,0,960,0]}
{"wire":[963,1,962,0]}
{"wire":[994,0,2170,0]}
{"wire":[994,1,993,0]}
{"wire":[996,0,983,0]}
{"wire":[996,1,2172,0]}
{"wire":[1027,0,2185,0]}
{"wire":[1027,1,1026,0]}
{"wire":[1331,0,1297,0]}
{"wire":[1331,1,1330,0]}
{"wire":[1333,0,2339,0]}
{"wire":[1333,1,2340,0]}
{"wire":[1362,0,1360,0]}
{"wire":[1362,1,2354,0]}
{"wire":[1362,2,1361,0]}
{"wire":[1364,0,1363,0]}
{"wire":[1364,1,1342,0]}
{"wire":[1376,0,6,0]}
{"wire":[1376,1,1375,0]}
{"wire":[1376,2,2362,0]}
{"wire":[1392,0,1388,0]}
{"wire":[1392,1,1391,0]}
{"wire":[1393,0,2369,0]}
{"wire":[1393,1,2370,0]}
{"wire":[1409,0,2378,0]}
{"wire":[1409,1,1408,0]}
{"wire":[1425,0,1422,0]}
{"wire":[1425,1,1424,0]}
{"wire":[1442,0,2392,0]}
{"wire":[1442,1,1441,0]}
{"wire":[1456,0,5,0]}
{"wire":[1456,1,1455,0]}
{"wire":[1487,0,1486,0]}
{"wire":[1487,1,2419,0]}
{"wire":[1489,0,2421,0]}
{"wire":[1489,1,1488,0]}
{"wire":[1520,0,2434,0]}
{"wire":[1520,1,1519,0]}
{"wire":[2145,0,948,0]}
{"wire":[278,0,279,0]}
{"wire":[278,1,280,0]}
{"wire":[278,2,277,0]}
{"wire":[278,3,243,0]}
{"wire":[278,4,243,0]}
{"wire":[311,0,310,0]}
{"wire":[311,1,308,0]}
{"wire":[323,0,322,0]}
{"wire":[341,0,339,0]}
{"wire":[341,1,340,0]}
{"wire":[344,0,1842,0]}
{"wire":[344,1,338,0]}
{"wire":[356,0,321,0]}
{"wire":[356,1,355,0]}
{"wire":[372,0,371,0]}
{"wire":[389,0,388,0]}
{"wire":[389,1,1864,0]}
{"wire":[403,0,402,0]}
{"wire":[436,0,433,0]}
{"wire":[436,1,435,0]}
{"wire":[467,0,1905,0]}
{"wire":[467,1,466,0]}
{"wire":[469,0,456,0]}
{"wire":[469,1,1907,0]}
{"wire":[500,0,1920,0]}
{"wire":[500,1,499,0]}
{"wire":[839,0,805,0]}
{"wire":[839,1,838,0]}
{"wire":[841,0,2091,0]}
{"wire":[841,1,2092,0]}
{"wire":[870,0,868,0]}
{"wire":[870,1,2106,0]}
{"wire":[870,2,869,0]}
{"wire":[872,0,871,0]}
{"wire":[872,1,850,0]}
{"wire":[884,0,6,0]}
{"wire":[884,1,883,0]}
{"wire":[884,2,2114,0]}
{"wire":[900,0,896,0]}
{"wire":[900,1,899,0]}
{"wire":[901,0,2121,0]}
{"wire":[901,1,2122,0]}
{"wire":[917,0,2130,0]}
{"wire":[917,1,916,0]}
{"wire":[933,0,930,0]}
{"wire":[933,1,932,0]}
{"wire":[950,0,2144,0]}
{"wire":[950,1,949,0]}
{"wire":[964,0,5,0]}
{"wire":[964,1,963,0]}
{"wire":[995,0,994,0]}
{"wire":[995,1,2171,0]}
{"wire":[997,0,2173,0]}
{"wire":[997,1,996,0]}
{"wire":[1028,0,2186,0]}
{"wire":[1028,1,1027,0]}
{"wire":[1332,0,1333,0]}
{"wire":[1332,1,1334,0]}
{"wire":[1332,2,1331,0]}
{"wire":[1332,3,1297,0]}
{"wire":[1332,4,1297,0]}
{"wire":[1365,0,1364,0]}
{"wire":[1365,1,1362,0]}
{"wire":[1377,0,1376,0]}
{"wire":[1395,0,1393,0]}
{"wire":[1395,1,1394,0]}
{"wire":[1398,0,2372,0]}
{"wire":[1398,1,1392,0]}
{"wire":[1410,0,1375,0]}
{"wire":[1410,1,1409,0]}
{"wire":[1426,0,1425,0]}
{"wire":[1443,0,1442,0]}
{"wire":[1443,1,2394,0]}
{"wire":[1457,0,1456,0]}
{"wire":[1490,0,1487,0]}
{"wire":[1490,1,1489,0]}
{"wire":[1521,0,2435,0]}
{"wire":[1521,1,1520,0]}
{"wire":[1523,0,1510,0]}
{"wire":[1523,1,2437,0]}
{"wire":[1554,0,2450,0]}
{"wire":[1554,1,1553,0]}
{"wire":[1880,0,421,0]}
{"wire":[2410,0,1475,0]}
{"wire":[312,0,278,0]}
{"wire":[312,1,311,0]}
{"wire":[314,0,1826,0]}
{"wire":[314,1,1827,0]}
{"wire":[343,0,341,0]}
{"wire":[343,1,1841,0]}
{"wire":[343,2,342,0]}
{"wire":[345,0,344,0]}
{"wire":[345,1,323,0]}
{"wire":[357,0,6,0]}
{"wire":[357,1,356,0]}
{"wire":[357,2,1849,0]}
{"wire":[373,0,369,0]}
{"wire":[373,1,372,0]}
{"wire":[374,0,1856,0]}
{"wire":[374,1,1857,0]}
{"wire":[390,0,1865,0]}
{"wire":[390,1,389,0]}
{"wire":[406,0,403,0]}
{"wire":[406,1,405,0]}
{"wire":[423,0,1879,0]}
{"wire":[423,1,422,0]}
{"wire":[437,0,5,0]}
{"wire":[437,1,436,0]}
{"wire":[468,0,467,0]}
{"wire":[468,1,1906,0]}
{"wire":[470,0,1908,0]}
{"wire":[470,1,469,0]}
{"wire":[501,0,1921,0]}
{"wire":[501,1,500,0]}
{"wire":[840,0,841,0]}
{"wire":[840,1,842,0]}
{"wire":[840,2,839,0]}
{"wire":[840,3,805,0]}
{"wire":[840,4,805,0]}
{"wire":[873,0,872,0]}
{"wire":[873,1,870,0]}
{"wire":[885,0,884,0]}
{"wire":[903,0,901,0]}
{"wire":[903,1,902,0]}
{"wire":[906,0,2124,0]}
{"wire":[906,1,900,0]}
{"wire":[918,0,883,0]}
{"wire":[918,1,917,0]}
{"wire":[934,0,933,0]}
{"wire":[951,0,950,0]}
{"wire":[951,1,2146,0]}
{"wire":[965,0,964,0]}
{"wire":[998,0,995,0]}
{"wire":[998,1,997,0]}
{"wire":[1029,0,2187,0]}
{"wire":[1029,1,1028,0]}
{"wire":[1031,0,1018,0]}
{"wire":[1031,1,2189,0]}
{"wire":[1062,0,2202,0]}
{"wire":[1062,1,1061,0]}
{"wire":[1366,0,1332,0]}
{"wire":[1366,1,1365,0]}
{"wire":[1368,0,2356,0]}
{"wire":[1368,1,2357,0]}
{"wire":[1397,0,1395,0]}
{"wire":[1397,1,2371,0]}
{"wire":[1397,2,1396,0]}
{"wire":[1399,0,1398,0]}
{"wire":[1399,1,1377,0]}
{"wire":[1411,0,6,0]}
{"wire":[1411,1,1410,0]}
{"wire":[1411,2,2379,0]}
{"wire":[1427,0,1423,0]}
{"wire":[1427,1,1426,0]}
{"wire":[1428,0,2386,0]}
{"wire":[1428,1,2387,0]}
{"wire":[1444,0,2395,0]}
{"wire":[1444,1,1443,0]}
{"wire":[1460,0,1457,0]}
{"wire":[1460,1,1459,0]}
{"wire":[1477,0,2409,0]}
{"wire":[1477,1,1476,0]}
{"wire":[1491,0,5,0]}
{"wire":[1491,1,1490,0]}
{"wire":[1522,0,1521,0]}
{"wire":[1522,1,2436,0]}
{"wire":[1524,0,2438,0]}
{"wire":[1524,1,1523,0]}
{"wire":[1555,0,2451,0]}
{"wire":[1555,1,1554,0]}
{"wire":[2148,0,918,0]}
{"wire":[2164,0,983,0]}
{"wire":[313,0,314,0]}
{"wire":[313,1,315,0]}
{"wire":[313,2,312,0]}
{"wire":[313,3,278,0]}
{"wire":[313,4,278,0]}
{"wire":[346,0,345,0]}
{"wire":[346,1,343,0]}
{"wire":[358,0,357,0]}
{"wire":[376,0,374,0]}
{"wire":[376,1,375,0]}
{"wire":[379,0,1859,0]}
{"wire":[379,1,373,0]}
{"wire":[391,0,356,0]}
{"wire":[391,1,390,0]}
{"wire":[407,0,406,0]}
{"wire":[424,0,423,0]}
{"wire":[424,1,1881,0]}
{"wire":[438,0,437,0]}
{"wire":[471,0,468,0]}
{"wire":[471,1,470,0]}
{"wire":[502,0,1922,0]}
{"wire":[502,1,501,0]}
{"wire":[504,0,491,0]}
{"wire":[504,1,1924,0]}
{"wire":[535,0,1937,0]}
{"wire":[535,1,534,0]}
{"wire":[874,0,840,0]}
{"wire":[874,1,873,0]}
{"wire":[876,0,2108,0]}
{"wire":[876,1,2109,0]}
{"wire":[905,0,903,0]}
{"wire":[905,1,2123,0]}
{"wire":[905,2,904,0]}
{"wire":[907,0,906,0]}
{"wire":[907,1,885,0]}
{"wire":[919,0,6,0]}
{"wire":[919,1,918,0]}
{"wire":[919,2,2131,0]}
{"wire":[935,0,931,0]}
{"wire":[935,1,934,0]}
{"wire":[936,0,2138,0]}
{"wire":[936,1,2139,0]}
{"wire":[952,0,2147,0]}
{"wire":[952,1,951,0]}
{"wire":[968,0,965,0]}
{"wire":[968,1,967,0]}
{"wire":[985,0,2163,0]}
{"wire":[985,1,984,0]}
{"wire":[999,0,5,0]}
{"wire":[999,1,998,0]}
{"wire":[1030,0,1029,0]}
{"wire":[1030,1,2188,0]}
{"wire":[1032,0,2190,0]}
{"wire":[1032,1,1031,0]}
{"wire":[1063,0,2203,0]}
{"wire":[1063,1,1062,0]}
{"wire":[1367,0,1368,0]}
{"wire":[1367,1,1369,0]}
{"wire":[1367,2,1366,0]}
{"wire":[1367,3,1332,0]}
{"wire":[1367,4,1332,0]}
{"wire":[1400,0,1399,0]}
{"wire":[1400,1,1397,0]}
{"wire":[1412,0,1411,0]}
{"wire":[1430,0,1428,0]}
{"wire":[1430,1,1429,0]}
{"wire":[1433,0,2389,0]}
{"wire":[1433,1,1427,0]}
{"wire":[1445,0,1410,0]}
{"wire":[1445,1,1444,0]}
{"wire":[1461,0,1460,0]}
{"wire":[1478,0,1477,0]}
{"wire":[1478,1,2411,0]}
{"wire":[1492,0,1491,0]}
{"wire":[1525,0,1522,0]}
{"wire":[1525,1,1524,0]}
{"wire":[1556,0,2452,0]}
{"wire":[1556,1,1555,0]}
{"wire":[1558,0,1545,0]}
{"wire":[1558,1,2454,0]}
{"wire":[1589,0,2467,0]}
{"wire":[1589,1,1588,0]}
{"wire":[1883,0,391,0]}
{"wire":[1899,0,456,0]}
{"wire":[2413,0,1445,0]}
{"wire":[2429,0,1510,0]}
{"wire":[347,0,313,0]}
{"wire":[347,1,346,0]}
{"wire":[349,0,1843,0]}
{"wire":[349,1,1844,0]}
{"wire":[378,0,376,0]}
{"wire":[378,1,1858,0]}
{"wire":[378,2,377,0]}
{"wire":[380,0,379,0]}
{"wire":[380,1,358,0]}
{"wire":[392,0,6,0]}
{"wire":[392,1,391,0]}
{"wire":[392,2,1866,0]}
{"wire":[408,0,404,0]}
{"wire":[408,1,407,0]}
{"wire":[409,0,1873,0]}
{"wire":[409,1,1874,0]}
{"wire":[425,0,1882,0]}
{"wire":[425,1,424,0]}
{"wire":[441,0,438,0]}
{"wire":[441,1,440,0]}
{"wire":[458,0,1898,0]}
{"wire":[458,1,457,0]}
{"wire":[472,0,5,0]}
{"wire":[472,1,471,0]}
{"wire":[503,0,502,0]}
{"wire":[503,1,1923,0]}
{"wire":[505,0,1925,0]}
{"wire":[505,1,504,0]}
{"wire":[536,0,1938,0]}
{"wire":[536,1,535,0]}
{"wire":[875,0,876,0]}
{"wire":[875,1,877,0]}
{"wire":[875,2,874,0]}
{"wire":[875,3,840,0]}
{"wire":[875,4,840,0]}
{"wire":[908,0,907,0]}
{"wire":[908,1,905,0]}
{"wire":[920,0,919,0]}
{"wire":[938,0,936,0]}
{"wire":[938,1,937,0]}
{"wire":[941,0,2141,0]}
{"wire":[941,1,935,0]}
{"wire":[953,0,2149,0]}
{"wire":[953,1,952,0]}
{"wire":[969,0,968,0]}
{"wire":[986,0,985,0]}
{"wire":[986,1,2165,0]}
{"wire":[1000,0,999,0]}
{"wire":[1033,0,1030,0]}
{"wire":[1033,1,1032,0]}
{"wire":[1064,0,2204,0]}
{"wire":[1064,1,1063,0]}
{"wire":[1066,0,1053,0]}
{"wire":[1066,1,2206,0]}
{"wire":[1097,0,2219,0]}
{"wire":[1097,1,1096,0]}
{"wire":[1401,0,1367,0]}
{"wire":[1401,1,1400,0]}
{"wire":[1403,0,2373,0]}
{"wire":[1403,1,2374,0]}
{"wire":[1432,0,1430,0]}
{"wire":[1432,1,2388,0]}
{"wire":[1432,2,1431,0]}
{"wire":[1434,0,1433,0]}
{"wire":[1434,1,1412,0]}
{"wire":[1446,0,6,0]}
{"wire":[1446,1,1445,0]}
{"wire":[1446,2,2396,0]}
{"wire":[1462,0,1458,0]}
{"wire":[1462,1,1461,0]}
{"wire":[1463,0,2403,0]}
{"wire":[1463,1,2404,0]}
{"wire":[1479,0,2412,0]}
{"wire":[1479,1,1478,0]}
{"wire":[1495,0,1492,0]}
{"wire":[1495,1,1494,0]}
{"wire":[1512,0,2428,0]}
{"wire":[1512,1,1511,0]}
{"wire":[1526,0,5,0]}
{"wire":[1526,1,1525,0]}
{"wire":[1557,0,1556,0]}
{"wire":[1557,1,2453,0]}
{"wire":[1559,0,2455,0]}
{"wire":[1559,1,1558,0]}
{"wire":[1590,0,2468,0]}
{"wire":[1590,1,1589,0]}
{"wire":[2181,0,1018,0]}
{"wire":[348,0,349,0]}
{"wire":[348,1,350,0]}
{"wire":[348,2,347,0]}
{"wire":[348,3,313,0]}
{"wire":[348,4,313,0]}
{"wire":[381,0,380,0]}
{"wire":[381,1,378,0]}
{"wire":[393,0,392,0]}
{"wire":[411,0,409,0]}
{"wire":[411,1,410,0]}
{"wire":[414,0,1876,0]}
{"wire":[414,1,408,0]}
{"wire":[426,0,1884,0]}
{"wire":[426,1,425,0]}
{"wire":[442,0,441,0]}
{"wire":[459,0,458,0]}
{"wire":[459,1,1900,0]}
{"wire":[473,0,472,0]}
{"wire":[506,0,503,0]}
{"wire":[506,1,505,0]}
{"wire":[537,0,1939,0]}
{"wire":[537,1,536,0]}
{"wire":[539,0,526,0]}
{"wire":[539,1,1941,0]}
{"wire":[570,0,1954,0]}
{"wire":[570,1,569,0]}
{"wire":[909,0,875,0]}
{"wire":[909,1,908,0]}
{"wire":[911,0,2125,0]}
{"wire":[911,1,2126,0]}
{"wire":[940,0,938,0]}
{"wire":[940,1,2140,0]}
{"wire":[940,2,939,0]}
{"wire":[942,0,941,0]}
{"wire":[942,1,920,0]}
{"wire":[954,0,6,0]}
{"wire":[954,1,953,0]}
{"wire":[954,2,2150,0]}
{"wire":[970,0,966,0]}
{"wire":[970,1,969,0]}
{"wire":[971,0,2157,0]}
{"wire":[971,1,2158,0]}
{"wire":[987,0,2166,0]}
{"wire":[987,1,986,0]}
{"wire":[1003,0,1000,0]}
{"wire":[1003,1,1002,0]}
{"wire":[1020,0,2180,0]}
{"wire":[1020,1,1019,0]}
{"wire":[1034,0,5,0]}
{"wire":[1034,1,1033,0]}
{"wire":[1065,0,1064,0]}
{"wire":[1065,1,2205,0]}
{"wire":[1067,0,2207,0]}
{"wire":[1067,1,1066,0]}
{"wire":[1098,0,2220,0]}
{"wire":[1098,1,1097,0]}
{"wire":[1402,0,1403,0]}
{"wire":[1402,1,1404,0]}
{"wire":[1402,2,1401,0]}
{"wire":[1402,3,1367,0]}
{"wire":[1402,4,1367,0]}
{"wire":[1435,0,1434,0]}
{"wire":[1435,1,1432,0]}
{"wire":[1447,0,1446,0]}
{"wire":[1465,0,1463,0]}
{"wire":[1465,1,1464,0]}
{"wire":[1468,0,2406,0]}
{"wire":[1468,1,1462,0]}
{"wire":[1480,0,2414,0]}
{"wire":[1480,1,1479,0]}
{"wire":[1496,0,1495,0]}
{"wire":[1513,0,1512,0]}
{"wire":[1513,1,2430,0]}
{"wire":[1527,0,1526,0]}
{"wire":[1560,0,1557,0]}
{"wire":[1560,1,1559,0]}
{"wire":[1591,0,2469,0]}
{"wire":[1591,1,1590,0]}
{"wire":[1593,0,1580,0]}
{"wire":[1593,1,2471,0]}
{"wire":[1624,0,2484,0]}
{"wire":[1624,1,1623,0]}
{"wire":[1916,0,491,0]}
{"wire":[2446,0,1545,0]}
{"wire":[382,0,348,0]}
{"wire":[382,1,381,0]}
{"wire":[384,0,1860,0]}
{"wire":[384,1,1861,0]}
{"wire":[413,0,411,0]}
{"wire":[413,1,1875,0]}
{"wire":[413,2,412,0]}
{"wire":[415,0,414,0]}
{"wire":[415,1,393,0]}
{"wire":[427,0,6,0]}
{"wire":[427,1,426,0]}
{"wire":[427,2,1885,0]}
{"wire":[443,0,439,0]}
{"wire":[443,1,442,0]}
{"wire":[444,0,1892,0]}
{"wire":[444,1,1893,0]}
{"wire":[460,0,1901,0]}
{"wire":[460,1,459,0]}
{"wire":[476,0,473,0]}
{"wire":[476,1,475,0]}
{"wire":[493,0,1915,0]}
{"wire":[493,1,492,0]}
{"wire":[507,0,5,0]}
{"wire":[507,1,506,0]}
{"wire":[538,0,537,0]}
{"wire":[538,1,1940,0]}
{"wire":[540,0,1942,0]}
{"wire":[540,1,539,0]}
{"wire":[571,0,1955,0]}
{"wire":[571,1,570,0]}
{"wire":[910,0,911,0]}
{"wire":[910,1,912,0]}
{"wire":[910,2,909,0]}
{"wire":[910,3,875,0]}
{"wire":[910,4,875,0]}
{"wire":[943,0,942,0]}
{"wire":[943,1,940,0]}
{"wire":[955,0,954,0]}
{"wire":[973,0,971,0]}
{"wire":[973,1,972,0]}
{"wire":[976,0,2160,0]}
{"wire":[976,1,970,0]}
{"wire":[988,0,953,0]}
{"wire":[988,1,987,0]}
{"wire":[1004,0,1003,0]}
{"wire":[1021,0,1020,0]}
{"wire":[1021,1,2182,0]}
{"wire":[1035,0,1034,0]}
{"wire":[1068,0,1065,0]}
{"wire":[1068,1,1067,0]}
{"wire":[1099,0,2221,0]}
{"wire":[1099,1,1098,0]}
{"wire":[1101,0,1088,0]}
{"wire":[1101,1,2223,0]}
{"wire":[1436,0,1402,0]}
{"wire":[1436,1,1435,0]}
{"wire":[1438,0,2390,0]}
{"wire":[1438,1,2391,0]}
{"wire":[1467,0,1465,0]}
{"wire":[1467,1,2405,0]}
{"wire":[1467,2,1466,0]}
{"wire":[1469,0,1468,0]}
{"wire":[1469,1,1447,0]}
{"wire":[1481,0,6,0]}
{"wire":[1481,1,1480,0]}
{"wire":[1481,2,2415,0]}
{"wire":[1497,0,1493,0]}
{"wire":[1497,1,1496,0]}
{"wire":[1498,0,2422,0]}
{"wire":[1498,1,2423,0]}
{"wire":[1514,0,2431,0]}
{"wire":[1514,1,1513,0]}
{"wire":[1530,0,1527,0]}
{"wire":[1530,1,1529,0]}
{"wire":[1547,0,2445,0]}
{"wire":[1547,1,1546,0]}
{"wire":[1561,0,5,0]}
{"wire":[1561,1,1560,0]}
{"wire":[1592,0,1591,0]}
{"wire":[1592,1,2470,0]}
{"wire":[1594,0,2472,0]}
{"wire":[1594,1,1593,0]}
{"wire":[1625,0,2485,0]}
{"wire":[1625,1,1624,0]}
{"wire":[2198,0,1053,0]}
{"wire":[383,0,384,0]}
{"wire":[383,1,385,0]}
{"wire":[383,2,382,0]}
{"wire":[383,3,348,0]}
{"wire":[383,4,348,0]}
{"wire":[416,0,415,0]}
{"wire":[416,1,413,0]}
{"wire":[428,0,427,0]}
{"wire":[446,0,444,0]}
{"wire":[446,1,445,0]}
{"wire":[449,0,1895,0]}
{"wire":[449,1,443,0]}
{"wire":[461,0,426,0]}
{"wire":[461,1,460,0]}
{"wire":[477,0,476,0]}
{"wire":[494,0,493,0]}
{"wire":[494,1,1917,0]}
{"wire":[508,0,507,0]}
{"wire":[541,0,538,0]}
{"wire":[541,1,540,0]}
{"wire":[572,0,1956,0]}
{"wire":[572,1,571,0]}
{"wire":[574,0,561,0]}
{"wire":[574,1,1958,0]}
{"wire":[944,0,910,0]}
{"wire":[944,1,943,0]}
{"wire":[946,0,2142,0]}
{"wire":[946,1,2143,0]}
{"wire":[975,0,973,0]}
{"wire":[975,1,2159,0]}
{"wire":[975,2,974,0]}
{"wire":[977,0,976,0]}
{"wire":[977,1,955,0]}
{"wire":[989,0,6,0]}
{"wire":[989,1,988,0]}
{"wire":[989,2,2167,0]}
{"wire":[1005,0,1001,0]}
{"wire":[1005,1,1004,0]}
{"wire":[1006,0,2174,0]}
{"wire":[1006,1,2175,0]}
{"wire":[1022,0,2183,0]}
{"wire":[1022,1,1021,0]}
{"wire":[1038,0,1035,0]}
{"wire":[1038,1,1037,0]}
{"wire":[1055,0,2197,0]}
{"wire":[1055,1,1054,0]}
{"wire":[1069,0,5,0]}
{"wire":[1069,1,1068,0]}
{"wire":[1100,0,1099,0]}
{"wire":[1100,1,2222,0]}
{"wire":[1102,0,2224,0]}
{"wire":[1102,1,1101,0]}
{"wire":[1437,0,1438,0]}
{"wire":[1437,1,1439,0]}
{"wire":[1437,2,1436,0]}
{"wire":[1437,3,1402,0]}
{"wire":[1437,4,1402,0]}
{"wire":[1470,0,1469,0]}
{"wire":[1470,1,1467,0]}
{"wire":[1482,0,1481,0]}
{"wire":[1500,0,1498,0]}
{"wire":[1500,1,1499,0]}
{"wire":[1503,0,2425,0]}
{"wire":[1503,1,1497,0]}
{"wire":[1515,0,1480,0]}
{"wire":[1515,1,1514,0]}
{"wire":[1531,0,1530,0]}
{"wire":[1548,0,1547,0]}
{"wire":[1548,1,2447,0]}
{"wire":[1562,0,1561,0]}
{"wire":[1595,0,1592,0]}
{"wire":[1595,1,1594,0]}
{"wire":[1626,0,2486,0]}
{"wire":[1626,1,1625,0]}
{"wire":[1628,0,1615,0]}
{"wire":[1628,1,2488,0]}
{"wire":[1933,0,526,0]}
{"wire":[2463,0,1580,0]}
{"wire":[417,0,383,0]}
{"wire":[417,1,416,0]}
{"wire":[419,0,1877,0]}
{"wire":[419,1,1878,0]}
{"wire":[448,0,446,0]}
{"wire":[448,1,1894,0]}
{"wire":[448,2,447,0]}
{"wire":[450,0,449,0]}
{"wire":[450,1,428,0]}
{"wire":[462,0,6,0]}
{"wire":[462,1,461,0]}
{"wire":[462,2,1902,0]}
{"wire":[478,0,474,0]}
{"wire":[478,1,477,0]}
{"wire":[479,0,1909,0]}
{"wire":[479,1,1910,0]}
{"wire":[495,0,1918,0]}
{"wire":[495,1,494,0]}
{"wire":[511,0,508,0]}
{"wire":[511,1,510,0]}
{"wire":[528,0,1932,0]}
{"wire":[528,1,527,0]}
{"wire":[542,0,5,0]}
{"wire":[542,1,541,0]}
{"wire":[573,0,572,0]}
{"wire":[573,1,1957,0]}
{"wire":[575,0,1959,0]}
{"wire":[575,1,574,0]}
{"wire":[945,0,946,0]}
{"wire":[945,1,947,0]}
{"wire":[945,2,944,0]}
{"wire":[945,3,910,0]}
{"wire":[945,4,910,0]}
{"wire":[978,0,977,0]}
{"wire":[978,1,975,0]}
{"wire":[990,0,989,0]}
{"wire":[1008,0,1006,0]}
{"wire":[1008,1,1007,0]}
{"wire":[1011,0,2177,0]}
{"wire":[1011,1,1005,0]}
{"wire":[1023,0,988,0]}
{"wire":[1023,1,1022,0]}
{"wire":[1039,0,1038,0]}
{"wire":[1056,0,1055,0]}
{"wire":[1056,1,2199,0]}
{"wire":[1070,0,1069,0]}
{"wire":[1103,0,1100,0]}
{"wire":[1103,1,1102,0]}
{"wire":[1471,0,1437,0]}
{"wire":[1471,1,1470,0]}
{"wire":[1473,0,2407,0]}
{"wire":[1473,1,2408,0]}
{"wire":[1502,0,1500,0]}
{"wire":[1502,1,2424,0]}
{"wire":[1502,2,1501,0]}
{"wire":[1504,0,1503,0]}
{"wire":[1504,1,1482,0]}
{"wire":[1516,0,6,0]}
{"wire":[1516,1,1515,0]}
{"wire":[1516,2,2432,0]}
{"wire":[1532,0,1528,0]}
{"wire":[1532,1,1531,0]}
{"wire":[1533,0,2439,0]}
{"wire":[1533,1,2440,0]}
{"wire":[1549,0,2448,0]}
{"wire":[1549,1,1548,0]}
{"wire":[1565,0,1562,0]}
{"wire":[1565,1,1564,0]}
{"wire":[1582,0,2462,0]}
{"wire":[1582,1,1581,0]}
{"wire":[1596,0,5,0]}
{"wire":[1596,1,1595,0]}
{"wire":[1627,0,1626,0]}
{"wire":[1627,1,2487,0]}
{"wire":[1629,0,2489,0]}
{"wire":[1629,1,1628,0]}
{"wire":[2215,0,1088,0]}
{"wire":[418,0,419,0]}
{"wire":[418,1,420,0]}
{"wire":[418,2,417,0]}
{"wire":[418,3,383,0]}
{"wire":[418,4,383,0]}
{"wire":[451,0,450,0]}
{"wire":[451,1,448,0]}
{"wire":[463,0,462,0]}
{"wire":[481,0,479,0]}
{"wire":[481,1,480,0]}
{"wire":[484,0,1912,0]}
{"wire":[484,1,478,0]}
{"wire":[496,0,461,0]}
{"wire":[496,1,495,0]}
{"wire":[512,0,511,0]}
{"wire":[529,0,528,0]}
{"wire":[529,1,1934,0]}
{"wire":[543,0,542,0]}
{"wire":[576,0,573,0]}
{"wire":[576,1,575,0]}
{"wire":[979,0,945,0]}
{"wire":[979,1,978,0]}
{"wire":[981,0,2161,0]}
{"wire":[981,1,2162,0]}
{"wire":[1010,0,1008,0]}
{"wire":[1010,1,2176,0]}
{"wire":[1010,2,1009,0]}
{"wire":[1012,0,1011,0]}
{"wire":[1012,1,990,0]}
{"wire":[1024,0,6,0]}
{"wire":[1024,1,1023,0]}
{"wire":[1024,2,2184,0]}
{"wire":[1040,0,1036,0]}
{"wire":[1040,1,1039,0]}
{"wire":[1041,0,2191,0]}
{"wire":[1041,1,2192,0]}
{"wire":[1057,0,2200,0]}
{"wire":[1057,1,1056,0]}
{"wire":[1073,0,1070,0]}
{"wire":[1073,1,1072,0]}
{"wire":[1090,0,2214,0]}
{"wire":[1090,1,1089,0]}
{"wire":[1104,0,5,0]}
{"wire":[1104,1,1103,0]}
{"wire":[1472,0,1473,0]}
{"wire":[1472,1,1474,0]}
{"wire":[1472,2,1471,0]}
{"wire":[1472,3,1437,0]}
{"wire":[1472,4,1437,0]}
{"wire":[1505,0,1504,0]}
{"wire":[1505,1,1502,0]}
{"wire":[1517,0,1516,0]}
{"wire":[1535,0,1533,0]}
{"wire":[1535,1,1534,0]}
{"wire":[1538,0,2442,0]}
{"wire":[1538,1,1532,0]}
{"wire":[1550,0,1515,0]}
{"wire":[1550,1,1549,0]}
{"wire":[1566,0,1565,0]}
{"wire":[1583,0,1582,0]}
{"wire":[1583,1,2464,0]}
{"wire":[1597,0,1596,0]}
{"wire":[1630,0,1627,0]}
{"wire":[1630,1,1629,0]}
{"wire":[1950,0,561,0]}
{"wire":[2480,0,1615,0]}
{"wire":[452,0,418,0]}
{"wire":[452,1,451,0]}
{"wire":[454,0,1896,0]}
{"wire":[454,1,1897,0]}
{"wire":[483,0,481,0]}
{"wire":[483,1,1911,0]}
{"wire":[483,2,482,0]}
{"wire":[485,0,484,0]}
{"wire":[485,1,463,0]}
{"wire":[497,0,6,0]}
{"wire":[497,1,496,0]}
{"wire":[497,2,1919,0]}
{"wire":[513,0,509,0]}
{"wire":[513,1,512,0]}
{"wire":[514,0,1926,0]}
{"wire":[514,1,1927,0]}
{"wire":[530,0,1935,0]}
{"wire":[530,1,529,0]}
{"wire":[546,0,543,0]}
{"wire":[546,1,545,0]}
{"wire":[563,0,1949,0]}
{"wire":[563,1,562,0]}
{"wire":[577,0,5,0]}
{"wire":[577,1,576,0]}
{"wire":[980,0,981,0]}
{"wire":[980,1,982,0]}
{"wire":[980,2,979,0]}
{"wire":[980,3,945,0]}
{"wire":[980,4,945,0]}
{"wire":[1013,0,1012,0]}
{"wire":[1013,1,1010,0]}
{"wire":[1025,0,1024,0]}
{"wire":[1043,0,1041,0]}
{"wire":[1043,1,1042,0]}
{"wire":[1046,0,2194,0]}
{"wire":[1046,1,1040,0]}
{"wire":[1058,0,1023,0]}
{"wire":[1058,1,1057,0]}
{"wire":[1074,0,1073,0]}
{"wire":[1091,0,1090,0]}
{"wire":[1091,1,2216,0]}
{"wire":[1105,0,1104,0]}
{"wire":[1506,0,1472,0]}
{"wire":[1506,1,1505,0]}
{"wire":[1508,0,2426,0]}
{"wire":[1508,1,2427,0]}
{"wire":[1537,0,1535,0]}
{"wire":[1537,1,2441,0]}
{"wire":[1537,2,1536,0]}
{"wire":[1539,0,1538,0]}
{"wire":[1539,1,1517,0]}
{"wire":[1551,0,6,0]}
{"wire":[1551,1,1550,0]}
{"wire":[1551,2,2449,0]}
{"wire":[1567,0,1563,0]}
{"wire":[1567,1,1566,0]}
{"wire":[1568,0,2456,0]}
{"wire":[1568,1,2457,0]}
{"wire":[1584,0,2465,0]}
{"wire":[1584,1,1583,0]}
{"wire":[1600,0,1597,0]}
{"wire":[1600,1,1599,0]}
{"wire":[1617,0,2479,0]}
{"wire":[1617,1,1616,0]}
{"wire":[1631,0,5,0]}
{"wire":[1631,1,1630,0]}
{"wire":[453,0,454,0]}
{"wire":[453,1,455,0]}
{"wire":[453,2,452,0]}
{"wire":[453,3,418,0]}
{"wire":[453,4,418,0]}
{"wire":[486,0,485,0]}
{"wire":[486,1,483,0]}
{"wire":[498,0,497,0]}
{"wire":[516,0,514,0]}
{"wire":[516,1,515,0]}
{"wire":[519,0,1929,0]}
{"wire":[519,1,513,0]}
{"wire":[531,0,496,0]}
{"wire":[531,1,530,0]}
{"wire":[547,0,546,0]}
{"wire":[564,0,563,0]}
{"wire":[564,1,1951,0]}
{"wire":[578,0,577,0]}
{"wire":[1014,0,980,0]}
{"wire":[1014,1,1013,0]}
{"wire":[1016,0,2178,0]}
{"wire":[1016,1,2179,0]}
{"wire":[1045,0,1043,0]}
{"wire":[1045,1,2193,0]}
{"wire":[1045,2,1044,0]}
{"wire":[1047,0,1046,0]}
{"wire":[1047,1,1025,0]}
{"wire":[1059,0,6,0]}
{"wire":[1059,1,1058,0]}
{"wire":[1059,2,2201,0]}
{"wire":[1075,0,1071,0]}
{"wire":[1075,1,1074,0]}
{"wire":[1076,0,2208,0]}
{"wire":[1076,1,2209,0]}
{"wire":[1092,0,2217,0]}
{"wire":[1092,1,1091,0]}
{"wire":[1108,0,1105,0]}
{"wire":[1108,1,1107,0]}
{"wire":[1507,0,1508,0]}
{"wire":[1507,1,1509,0]}
{"wire":[1507,2,1506,0]}
{"wire":[1507,3,1472,0]}
{"wire":[1507,4,1472,0]}
{"wire":[1540,0,1539,0]}
{"wire":[1540,1,1537,0]}
{"wire":[1552,0,1551,0]}
{"wire":[1570,0,1568,0]}
{"wire":[1570,1,1569,0]}
{"wire":[1573,0,2459,0]}
{"wire":[1573,1,1567,0]}
{"wire":[1585,0,1550,0]}
{"wire":[1585,1,1584,0]}
{"wire":[1601,0,1600,0]}
{"wire":[1618,0,1617,0]}
{"wire":[1618,1,2481,0]}
{"wire":[1632,0,1631,0]}
{"wire":[487,0,453,0]}
{"wire":[487,1,486,0]}
{"wire":[489,0,1913,0]}
{"wire":[489,1,1914,0]}
{"wire":[518,0,516,0]}
{"wire":[518,1,1928,0]}
{"wire":[518,2,517,0]}
{"wire":[520,0,519,0]}
{"wire":[520,1,498,0]}
{"wire":[532,0,6,0]}
{"wire":[532,1,531,0]}
{"wire":[532,2,1936,0]}
{"wire":[548,0,544,0]}
{"wire":[548,1,547,0]}
{"wire":[549,0,1943,0]}
{"wire":[549,1,1944,0]}
{"wire":[565,0,1952,0]}
{"wire":[565,1,564,0]}
{"wire":[581,0,578,0]}
{"wire":[581,1,580,0]}
{"wire":[1015,0,1016,0]}
{"wire":[1015,1,1017,0]}
{"wire":[1015,2,1014,0]}
{"wire":[1015,3,980,0]}
{"wire":[1015,4,980,0]}
{"wire":[1048,0,1047,0]}
{"wire":[1048,1,1045,0]}
{"wire":[1060,0,1059,0]}
{"wire":[1078,0,1076,0]}
{"wire":[1078,1,1077,0]}
{"wire":[1081,0,2211,0]}
{"wire":[1081,1,1075,0]}
{"wire":[1093,0,1058,0]}
{"wire":[1093,1,1092,0]}
{"wire":[1109,0,1108,0]}
{"wire":[1541,0,1507,0]}
{"wire":[1541,1,1540,0]}
{"wire":[1543,0,2443,0]}
{"wire":[1543,1,2444,0]}
{"wire":[1572,0,1570,0]}
{"wire":[1572,1,2458,0]}
{"wire":[1572,2,1571,0]}
{"wire":[1574,0,1573,0]}
{"wire":[1574,1,1552,0]}
{"wire":[1586,0,6,0]}
{"wire":[1586,1,1585,0]}
{"wire":[1586,2,2466,0]}
{"wire":[1602,0,1598,0]}
{"wire":[1602,1,1601,0]}
{"wire":[1603,0,2473,0]}
{"wire":[1603,1,2474,0]}
{"wire":[1619,0,2482,0]}
{"wire":[1619,1,1618,0]}
{"wire":[1635,0,1632,0]}
{"wire":[1635,1,1634,0]}
{"wire":[488,0,489,0]}
{"wire":[488,1,490,0]}
{"wire":[488,2,487,0]}
{"wire":[488,3,453,0]}
{"wire":[488,4,453,0]}
{"wire":[521,0,520,0]}
{"wire":[521,1,518,0]}
{"wire":[533,0,532,0]}
{"wire":[551,0,549,0]}
{"wire":[551,1,550,0]}
{"wire":[554,0,1946,0]}
{"wire":[554,1,548,0]}
{"wire":[566,0,531,0]}
{"wire":[566,1,565,0]}
{"wire":[582,0,581,0]}
{"wire":[1049,0,1015,0]}
{"wire":[1049,1,1048,0]}
{"wire":[1051,0,2195,0]}
{"wire":[1051,1,2196,0]}
{"wire":[1080,0,1078,0]}
{"wire":[1080,1,2210,0]}
{"wire":[1080,2,1079,0]}
{"wire":[1082,0,1081,0]}
{"wire":[1082,1,1060,0]}
{"wire":[1094,0,6,0]}
{"wire":[1094,1,1093,0]}
{"wire":[1094,2,2218,0]}
{"wire":[1110,0,1106,0]}
{"wire":[1110,1,1109,0]}
{"wire":[1111,0,2225,0]}
{"wire":[1111,1,2226,0]}
{"wire":[1542,0,1543,0]}
{"wire":[1542,1,1544,0]}
{"wire":[1542,2,1541,0]}
{"wire":[1542,3,1507,0]}
{"wire":[1542,4,1507,0]}
{"wire":[1575,0,1574,0]}
{"wire":[1575,1,1572,0]}
{"wire":[1587,0,1586,0]}
{"wire":[1605,0,1603,0]}
{"wire":[1605,1,1604,0]}
{"wire":[1608,0,2476,0]}
{"wire":[1608,1,1602,0]}
{"wire":[1620,0,1585,0]}
{"wire":[1620,1,1619,0]}
{"wire":[1636,0,1635,0]}
{"wire":[522,0,488,0]}
{"wire":[522,1,521,0]}
{"wire":[524,0,1930,0]}
{"wire":[524,1,1931,0]}
{"wire":[553,0,551,0]}
{"wire":[553,1,1945,0]}
{"wire":[553,2,552,0]}
{"wire":[555,0,554,0]}
{"wire":[555,1,533,0]}
{"wire":[567,0,6,0]}
{"wire":[567,1,566,0]}
{"wire":[567,2,1953,0]}
{"wire":[583,0,579,0]}
{"wire":[583,1,582,0]}
{"wire":[584,0,1960,0]}
{"wire":[584,1,1961,0]}
{"wire":[1050,0,1051,0]}
{"wire":[1050,1,1052,0]}
{"wire":[1050,2,1049,0]}
{"wire":[1050,3,1015,0]}
{"wire":[1050,4,1015,0]}
{"wire":[1083,0,1082,0]}
{"wire":[1083,1,1080,0]}
{"wire":[1095,0,1094,0]}
{"wire":[1113,0,1111,0]}
{"wire":[1113,1,1112,0]}
{"wire":[1116,0,2228,0]}
{"wire":[1116,1,1110,0]}
{"wire":[1576,0,1542,0]}
{"wire":[1576,1,1575,0]}
{"wire":[1578,0,2460,0]}
{"wire":[1578,1,2461,0]}
{"wire":[1607,0,1605,0]}
{"wire":[1607,1,2475,0]}
{"wire":[1607,2,1606,0]}
{"wire":[1609,0,1608,0]}
{"wire":[1609,1,1587,0]}
{"wire":[1621,0,6,0]}
{"wire":[1621,1,1620,0]}
{"wire":[1621,2,2483,0]}
{"wire":[1637,0,1633,0]}
{"wire":[1637,1,1636,0]}
{"wire":[1638,0,2490,0]}
{"wire":[1638,1,2491,0]}
{"wire":[523,0,524,0]}
{"wire":[523,1,525,0]}
{"wire":[523,2,522,0]}
{"wire":[523,3,488,0]}
{"wire":[523,4,488,0]}
{"wire":[556,0,555,0]}
{"wire":[556,1,553,0]}
{"wire":[568,0,567,0]}
{"wire":[586,0,584,0]}
{"wire":[586,1,585,0]}
{"wire":[589,0,1963,0]}
{"wire":[589,1,583,0]}
{"wire":[1084,0,1050,0]}
{"wire":[1084,1,1083,0]}
{"wire":[1086,0,2212,0]}
{"wire":[1086,1,2213,0]}
{"wire":[1115,0,1113,0]}
{"wire":[1115,1,2227,0]}
{"wire":[1115,2,1114,0]}
{"wire":[1117,0,1116,0]}
{"wire":[1117,1,1095,0]}
{"wire":[1577,0,1578,0]}
{"wire":[1577,1,1579,0]}
{"wire":[1577,2,1576,0]}
{"wire":[1577,3,1542,0]}
{"wire":[1577,4,1542,0]}
{"wire":[1610,0,1609,0]}
{"wire":[1610,1,1607,0]}
{"wire":[1622,0,1621,0]}
{"wire":[1640,0,1638,0]}
{"wire":[1640,1,1639,0]}
{"wire":[1643,0,2493,0]}
{"wire":[1643,1,1637,0]}
{"wire":[557,0,523,0]}
{"wire":[557,1,556,0]}
{"wire":[559,0,1947,0]}
{"wire":[559,1,1948,0]}
{"wire":[588,0,586,0]}
{"wire":[588,1,1962,0]}
{"wire":[588,2,587,0]}
{"wire":[590,0,589,0]}
{"wire":[590,1,568,0]}
{"wire":[1085,0,1086,0]}
{"wire":[1085,1,1087,0]}
{"wire":[1085,2,1084,0]}
{"wire":[1085,3,1050,0]}
{"wire":[1085,4,1050,0]}
{"wire":[1118,0,1117,0]}
{"wire":[1118,1,1115,0]}
{"wire":[1611,0,1577,0]}
{"wire":[1611,1,1610,0]}
{"wire":[1613,0,2477,0]}
{"wire":[1613,1,2478,0]}
{"wire":[1642,0,1640,0]}
{"wire":[1642,1,2492,0]}
{"wire":[1642,2,1641,0]}
{"wire":[1644,0,1643,0]}
{"wire":[1644,1,1622,0]}
{"wire":[1681,0,2,0]}
{"wire":[1720,0,18,0]}
{"wire":[558,0,559,0]}
{"wire":[558,1,560,0]}
{"wire":[558,2,557,0]}
{"wire":[558,3,523,0]}
{"wire":[558,4,523,0]}
{"wire":[591,0,590,0]}
{"wire":[591,1,588,0]}
{"wire":[1119,0,1085,0]}
{"wire":[1119,1,1118,0]}
{"wire":[1121,0,2229,0]}
{"wire":[1121,1,2230,0]}
{"wire":[1612,0,1613,0]}
{"wire":[1612,1,1614,0]}
{"wire":[1612,2,1611,0]}
{"wire":[1612,3,1577,0]}
{"wire":[1612,4,1577,0]}
{"wire":[1645,0,1644,0]}
{"wire":[1645,1,1642,0]}
{"wire":[592,0,558,0]}
{"wire":[592,1,591,0]}
{"wire":[594,0,1964,0]}
{"wire":[594,1,1965,0]}
{"wire":[1120,0,1121,0]}
{"wire":[1120,1,1122,0]}
{"wire":[1120,2,1119,0]}
{"wire":[1120,3,1085,0]}
{"wire":[1120,4,1085,0]}
{"wire":[1646,0,1612,0]}
{"wire":[1646,1,1645,0]}
{"wire":[1648,0,2494,0]}
{"wire":[1648,1,2495,0]}
{"wire":[1654,2,4,0]}
{"wire":[2496,0,9,0]}
{"wire":[593,0,594,0]}
{"wire":[593,1,595,0]}
{"wire":[593,2,592,0]}
{"wire":[593,3,558,0]}
{"wire":[593,4,558,0]}
{"wire":[1647,0,1648,0]}
{"wire":[1647,1,1649,0]}
{"wire":[1647,2,1646,0]}
{"wire":[1647,3,1612,0]}
{"wire":[1647,4,1612,0]}
{"wire":[1650,0,593,0]}
{"wire":[1650,1,1120,0]}
{"wire":[1655,0,4,0]}
{"wire":[1655,1,1654,0]}
{"wire":[1651,0,593,0]}
{"wire":[1651,1,1650,0]}
{"wire":[1652,0,1651,0]}
{"wire":[1652,1,1647,0]}
{"wire":[1656,0,1655,0]}
{"wire":[1657,0,2497,0]}
{"wire":[1653,0,1651,0]}
{"wire":[1653,1,1652,0]}
{"wire":[1658,0,1656,0]}
{"wire":[1658,1,1657,0]}
{"wire":[1659,0,1653,0]}
{"wire":[1659,1,1658,0]}
{"wire":[1660,0,1659,0]}
{"wire":[1661,0,1659,0]}
{"wire":[1662,0,1659,0]}
{"wire":[1664,0,8,0]}
{"wire":[1664,1,3,0]}
{"wire":[1663,0,1660,0]}
{"wire":[1663,1,1661,0]}
{"wire":[1663,2,1662,0]}
{"wire":[1663,3,2501,0]}
{"wire":[1665,0,1664,0]}
{"wire":[0,0,1665,0]}
{"wire":[0,1,1663,0]}
ASEEND*/
//CHKSM=2CB8EE700BA18147269C68DD21E0D83719E2DE8A