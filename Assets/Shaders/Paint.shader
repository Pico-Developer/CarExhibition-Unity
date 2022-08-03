Shader "Car/Paint_v1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (0, 0, 0, 1)
        _SpecularPow ("SpecularPow", Range(1.0, 1024.0)) = 1.0
        // 额外兰伯特补偿
        _CustomLambert ("Custombert", Range(0, 1)) = 0
        [Normal] _FlakeNormalTex ("FlakeNormalTex", 2D) = "bump" {}
        _FlakeScale ("FlakeNormalScale", Range(.0, 10.0)) = 1.0
        _FlackStrength ("FlackStrength", Range(.0, 2000)) = 500
        _ReflectionCube ("ReflectionCube", Cube) = "black" {}
        _Reflectivity ("Reflectivity", Range(.0, 1.0)) = 1.0
        _AOTex ("AOTex", 2D) = "white" {}
        _AOStrength ("AOStrength", Range(0, 1)) = 1
        // 开关是否开启多光源
        [Toggle(_AdditionalLights)] _AddLight ("AddLight", Float) = 1
        // 开关 是否使用高光
        [Toggle(_UseSpecularHightlight)] _UseSpecularHightlight ("UseSpecularHightlight", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "LightMode" = "UniversalForward"
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _AdditionalLights
            #pragma shader_feature _UseSpecularHightlight
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //光照函数库 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Comm.hlsl"

        CBUFFER_START(UnityPerMaterial)
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            SAMPLER(sampler_FlakeNormalTex);
            float4 _FlakeNormalTex_ST;
            float _FlakeScale;
            float _FlackStrength;
            SAMPLER(sampler_ReflectionCube);
            float _Reflectivity;
            SAMPLER(sampler_AOTex);
            float _AOStrength;
            float4 _BaseColor;
            float _SpecularPow;
            float _CustomLambert;
        CBUFFER_END

            TEXTURE2D(_MainTex);
            

            TEXTURE2D(_FlakeNormalTex);
            

            TEXTURECUBE(_ReflectionCube);
            
            
            TEXTURE2D(_AOTex);
            
            
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 baseUV : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                // float3 positionWS: VAR_POSITION;
                float4 uv : TEXCOORD0;
                float4 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 bitangentWS : TEXCOORD3;
            };

            v2f vert(appdata input)
            {
                v2f output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS.xyz = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS.xyz = TransformObjectToWorldDir(input.tangentOS);
                output.bitangentWS.xyz = cross(output.normalWS.xyz,output.tangentWS.xyz) * input.tangentOS.w * unity_WorldTransformParams.w;

                output.tangentWS.w = positionWS.x;
                output.bitangentWS.w = positionWS.y;
                output.normalWS.w = positionWS.z;
                
                
                //input.baseUV * baseST.xy + baseST.zw;
                output.uv.xy = TRANSFORM_TEX(input.baseUV, _MainTex);
                // output.uv.zw = TRANSFORM_TEX(input.baseUV, _FlakeNormalTex);
                output.uv.zw = input.baseUV * float2(_FlackStrength, _FlackStrength);
                
                return output;
            }

            

            float4 frag(v2f input): SV_TARGET
            {

                
                
                float3 positionWS = float3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
                float3x3 TBN = float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
                TBN = transpose(TBN);
                
                float3 normal = normalize(input.normalWS.xyz);
                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(positionWS));

                float3 ambient = light.color.xyz;

                // AO 遮挡
                float ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, input.uv.xy).x;
                ao = lerp(1.0, ao, _AOStrength);
                
                
                // flake法线
                half4 flakeNormalTex = SAMPLE_TEXTURE2D(_FlakeNormalTex, sampler_FlakeNormalTex, input.uv.zw);
                float3 flakeNormal = UnpackNormalScale(flakeNormalTex, _FlakeScale);
                // 规范化法线
                flakeNormal.z = pow((1 - pow(flakeNormal.x,2) - pow(flakeNormal.y,2)),0.5);
                flakeNormal = mul(TBN, flakeNormal);

                // 修复flake太远导致的摩尔纹问题
                // 修复远离：计算和摄像机的距离
                // 让远离摄像机的时候，逐渐隐藏Flake
                float fixFlakeMooreGrain = saturate(1 - input.positionCS.w / 3);

                // 混合法线
                normal = normalize(flakeNormal * fixFlakeMooreGrain + normal);

                // lambert
                float lamb = customLambert(normal, lightDir, _CustomLambert);

                float3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy).rgb;
                float3 diffuse = mainColor * lamb * ambient;


               
                
                float3 outColor = diffuse;
            // 是否用金属高光
            #ifdef _UseSpecularHightlight
                // Specular
                float3 specular = specularBlinnPhone(lightDir, viewDir, normal, _SpecularPow);
                specular *= ambient;
                specular *= ao;
                outColor += specular;
            #endif
                
                // 多光源
            #ifdef _AdditionalLights
                
                // 获取副光源数量
                int pixelLightCount = GetAdditionalLightsCount();
                for(int index = 0; index < pixelLightCount; index++)
                {
                    Light light = GetAdditionalLight(index, positionWS);
                    lamb = halfLambert(normal, light.direction);
                    // 副光源基础颜色
                    float3 subCol = mainColor * _BaseColor * lamb * light.color * light.distanceAttenuation * light.shadowAttenuation;
                    // float3 subCol = lamb * light.color * light.distanceAttenuation * light.shadowAttenuation;
                    
                    outColor.xyz += subCol;

                    // 是否用金属高光
                #ifdef _UseSpecularHightlight
                    // 副高光
                    float3 subSpecular = specularBlinnPhone(light.direction, viewDir, normal, _SpecularPow);
                    subSpecular *= light.color;
                    subSpecular *= ao;
                    outColor.xyz += subSpecular;
                #endif
                    
                }
            #endif

                outColor *= ao;

                outColor *= _BaseColor;

                 // 反射
                float3 env = reflectionEnv(viewDir, normal, _Reflectivity, _ReflectionCube, sampler_ReflectionCube);

                outColor += env;

                
                
                // return float4(lerp(outColor, env, _Reflectivity), 1);
                return float4(outColor, 1);
            }
            
            ENDHLSL
        }
    }
}