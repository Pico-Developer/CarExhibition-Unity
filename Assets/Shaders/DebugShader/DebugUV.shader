Shader "Debug/DebugUV"
{
    Properties
    {
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 baseUV : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata input)
            {
                v2f output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                output.uv.xy = input.baseUV;

                return output;
            }


            float4 frag (v2f input) : SV_Target
            {
                return float4(input.uv, 0, 1);
            }
            ENDHLSL
        }
        
    }
}
