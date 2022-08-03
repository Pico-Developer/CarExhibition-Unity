Shader "Debug/DebugNormalsLength"
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 normal : TEXCOORD0;
            };

            v2f vert (appdata input)
            {
                v2f output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                output.normal = input.normal;

                return output;
            }


            float4 frag (v2f input) : SV_Target
            {
                return distance(input.normal, float3(0, 0, 0));
            }
            ENDHLSL
        }
        
    }
}
