#ifndef SIMPLE_LIGHTING_COMMON_INCLUDE
#define SIMPLE_LIGHTING_COMMON_INCLUDE



// lambert 相关
float lambert(float3 normal, float3 lightDir)
{
    return dot(lightDir, normal);
}
float halfLambert(float3 normal, float3 lightDir)
{
    return dot(normal, lightDir) * 0.5 + 0.5;
}
float customLambert(float3 normal, float3 lightDir, float lambertScale)
{
    return dot(lightDir, normal) * (1 - lambertScale) + lambertScale;
}

// 高光相关
// phone 模型
float3 specularPhone(float3 lightDir, float3 viewDir, float3 normal, float phonePow)
{
    float3 reflectDir = normalize(reflect(-lightDir, normal));
    return  pow(max(0,dot(reflectDir, viewDir)), phonePow);
}
            
// blinn-phone
float3 specularBlinnPhone(float3 lightDir, float3 viewDir, float3 normal, float phonePow)
{
    float3 halfDir = normalize(viewDir + lightDir);
    
    // return  pow(max(0,dot(halfDir, normal)), phonePow);
    return  pow(saturate(dot(halfDir, normal)),phonePow);
}

// 反射 环境Cube纹理
float3 reflectionEnv(float3 viewDir, float3 normal, float reflectivity, TextureCube envCube, SamplerState state)
{
    float3 reflection = reflect(-viewDir, normal);
    float3 env = SAMPLE_TEXTURECUBE(envCube, state, reflection);
    env *= reflectivity;
    return env;
}

#endif