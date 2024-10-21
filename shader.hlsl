#include "MathUtils.hlsli"

static const int   MAX_MARCHING_STEPS = 255;
static const float MIN_DIST = 0.1;
static const float MAX_DIST = 50.0; 
static const float EPSILON  = 0.003;

cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

cbuffer CameraTrackingBuffer : register(b1)
{
    float3 cameraPosition;
    float padding;
}

cbuffer ElapsedTimeBuffer : register(b2)
{
    float time;
    float3 padding2;
}

cbuffer LightBuffer : register(b3)
{
    float3 waterColor;
    float waterDepth;
}

struct PS_INPUT
{
    float4 pos : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

struct Ray
{
    float3 o; // origin 
    float3 d; // direction 
};

struct HitObject
{
    int id;
    float d;
};

/* Sample noise to create surface waves */
float SurfaceSDF(float2 p)
{
    float surfaceHeight = 0.0;
    float amplitude = 0.2;
    float frequency = 0.6;
    for (int i = 0; i < 4; i++)
    {
        float a = noise(float3(p * frequency + float2(1.0, 1.0) * (time + 1.0) * 0.8, 1.0));
        a -= noise(float3(p * frequency + float2(-2.0, -0.8) * time * 0.5, 1.0));
        surfaceHeight += amplitude * a;
        amplitude *= 0.8;
        frequency *= 3.0;
    }
    return clamp(0.05 + surfaceHeight * 0.2, 0.0, 0.5);
}

/* Sample noise to create terrain */
float FloorSDF(float3 p)
{
    float terrainHeight = 0.0;
    float amplitude = 0.5;
    float frequency = 0.6;
    for (int i = 0; i < 8; i++)
    {
        terrainHeight += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    // Calculate the distance to the floor of the terrain
    float distToFloor = p.y + (terrainHeight * 1.13 + 2.5);
    return distToFloor;
}

/** 
 * Signed distance functions for implicitly modeling a wobbly bubble
 */ 
float BubbleSDF(float3 p, float t)
{
    /* Animation based on 
    https://www.shadertoy.com/view/WtfyWj */
    
    float maxDepth = 4.2;
    float progress = pow(min(frac(t * 0.01) * 4.5, 1.0), 2.0);
    float depth = maxDepth * (0.8 - progress * progress);
    
    float r = lerp(0.01, 0.09, progress);
    float d = 2.0 - smoothstep(0.0, 1.0, min(progress * 5.0, 1.0)) * 0.3;
    
    // Apply noise function to make the bubble wobbly
    float3 offset = float3(0.0, 0.0, 0.0);
    offset.x = noise(p * 0.8 + float3(t * 0.5, 0.0, 0.0)) * 0.2;
    offset.y = noise(p * 0.6 + float3(0.0, t * 0.5, 0.0)) * 0.2;
    offset.z = noise(p * 0.7 + float3(0.0, 0.0, t * 0.5)) * 0.2;
    p += offset;
    
    return sqrt(dot(p + float3(d, depth, -1.0 + 0.2 * progress * sin(progress * 10.0)),
    p + float3(d, depth, -1.0 + 0.2 * progress * sin(progress * 10.0)))) - r;
}

float CylinderSDF(float3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return sqrt(dot(p, p)) - r;
}

/** 
* Signed distance functions for implicitly modeling plants
* Based on https://www.shadertoy.com/view/WtfyWj
**/ 
float PlantSDF(float3 p, float h)
{
    float r = 0.04 * -(p.y + 2.5) - 0.005 * pow(sin(p.y * 10.0), 4.0);
    p.z += sin(time * 0.5 + h) * pow(0.2 * (p.y + 5.6), 3.0);
    return CylinderSDF(p + float3(0.0, 5.7, 0.0), 5.0 * h, r);
}

float PlantsSDF(float3 p)
{
    float3 dd = float3(-0.3, -0.5, -0.5);
    // Make multiple copies, each one displaced and rotated.
    float d = 1e10;
    for (int i = 0; i < 8; i++)
    {
        d = min(d, min(PlantSDF(p, 0.0), min(PlantSDF(p + dd.xyx, 5.0), PlantSDF(p + dd, 3.0))));
        p.x -= 0.01;
        p.z -= 0.06;
        p.xz = mul(p.xz, rot(0.7));
    }
    return d;
}

/**
 * Signed distance functions for implicitly modeling a coral object 
 * Based on https://www.shadertoy.com/view/XsfGR8
 **/
float CoralSDF(float3 p)
{
    float3 zn = float3(p.xyz);
    float radius = 0.0;
    float hit = 0.0;
    float n = 12; //9;
    float d = 2.0;
    for (int i = 0; i < 12; i++) //18
    {
        radius = sqrt(dot(zn, zn));
        if (radius > 2.0)
        {
            hit = 0.5 * log(radius) * radius / d;
        }
        else
        {
            float rado = pow(radius, 8.0);
            float theta = atan2(length(zn.xy), zn.z);
            float phi = atan2(zn.y, zn.x);
            d = pow(radius, 7.0) * 7.0 * d + 1.0;

            float sint = sin(theta * n);
            zn.x = rado * sint * cos(phi * n);
            zn.y = rado * sint * sin(phi * n);
            zn.z = rado * cos(theta * n);
            zn += p;
        }
    }
    return hit;
}

/**
 * Signed distance function describing the scene.
 * Based on https://www.shadertoy.com/view/WtfyWj
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float2 SceneSDF(float3 p)
{
    float3 pp = p;
    pp.xz = mul(pp.xz, rot(-.5));
    
    float d = -p.y - SurfaceSDF(p.xz);
    float t = time * 0.6;
    d += (0.5 + 0.5 * (sin(p.z * 0.2 + t) + sin((p.z + p.x) * 0.1 + t * 2.0))) * 0.4;
    
    return min(float2(d, 1.5),
           min(float2(FloorSDF (p), 3.5),
           min(float2(PlantsSDF(p - float3(0.0, 0.0, 0.0)), 5.5),
           min(float2(PlantsSDF(p - float3(1.0, 0.0, -0.5)), 5.5),
           min(float2(CoralSDF(p - float3(-4.0, -2.4, 1.0)), 7.5),
           min(float2(PlantsSDF(p - float3(-2.5, 0.0, -1.3)), 8.5),
           min(float2(CoralSDF(p - float3(-2.0, -2.8, -2.8)), 6.5),
           min(float2(BubbleSDF(pp, time - 0.8), 4.5),
               float2(BubbleSDF(pp, time), 4.5)))))))));
}

/**
 * Adv. effects:
 * Caustics, God Rays and Ambient Occlusion
 * 
 * Caustics based on https://www.shadertoy.com/view/WdByRR 
 * 
 * God rays and Ambient Occlusion 
 * based on https://www.shadertoy.com/view/WtfyWj
 */
float Caustics(float3 p)
{
    return abs(noise(p + fmod(time * 0.5, 40.0) * 2.0) - noise(p + float3(4.0, 0.0, 4.0) + fmod(time * 0.5, 40.0) * 1.0));
}

float GodRays(float3 p, float3 lightPos)
{
    float3 lightDir = normalize(lightPos - p);
    float3 sp = p + lightDir * -p.y;
    float f = 1.0 - clamp(SurfaceSDF(sp.xz) * 10.0, 0.0, 1.0);
    f *= 1.0 - length(lightDir.xz);
    return smoothstep(0.2, 1.0, f * 0.7);
}

float CastLightBeam(float3 ro, float3 rd, float3 light, float hitDist)
{
    // March through the scene, accumulating god rays.
    float3 p = ro;
    float3 st = rd * hitDist / 96.0;
    float god = 0.0;
    for (int i = 0; i < 96; i++)
    {
        float distFromGodLight = 1.0 - GodRays(p, light);
        god += GodRays(p, light);
        p += st;
    }
    god /= 96.0;
    return smoothstep(0.0, 1.0, min(god, 1.0));
}

float AmbientOcclusion(float3 p, float3 n)
{
    const float dist = 0.5;
    return smoothstep(0.0, 1.0, 1.0 - (dist - SceneSDF(p + n * dist).x));
}

float3 EstimateNormal(float3 p)
{
    float2 e = float2(1.0, -1.0) * 0.0025;
    return normalize(e.xyy * SceneSDF(p + e.xyy).x +
					 e.yyx * SceneSDF(p + e.yyx).x +
					 e.yxy * SceneSDF(p + e.yxy).x +
					 e.xxx * SceneSDF(p + e.xxx).x);
}

/* Ray Marching*/
HitObject RayMarching(Ray ray, float start, float end)
{
    HitObject object;
    
    object.id = 0;
    float depth = start;
    float outside = 1.0; // Tracks inside and outside of bubble (for refraction)
    
    for (float i = 0.0; i < MAX_MARCHING_STEPS; i++)
    {
        float2 dist = SceneSDF(ray.o + depth * ray.d);
        
        if (dist.x < EPSILON)
        {
            if (dist.y == 4.5)
            {
                // Bubble refraction based on https://www.shadertoy.com/view/WtfyWj
                ray.d = refract(ray.d, EstimateNormal(ray.o + depth * ray.d) * sign(outside), 1.0);
                outside *= -1.0;
                continue;
            }
            object.d = depth;
            object.id = int(dist.y);
            
            return object;
        }
        depth += dist.x;
        if (depth >= end)
        {
            object.d = end;
            return object;
        }
    }
    object.d = end;
    return object;
}

/* Lighting, Shadows and Visual Effects */
float3 Shading(HitObject hObj, float3 n, float3 p, float3 l)
{
    float3 texColor = float3(0.15, 0.25, 0.6);

    if (hObj.id == 1) // Sea
    {
        n.y = -n.y;
    }
    else
    {
        if (hObj.id == 3)  // Sand
        {
            texColor += float3(0.1, 0.1, 0.0);
        }
        else if (hObj.id == 6) // Coral back
        {
            texColor += float3(1.12, 0.25, .15) * 0.7;
        }
        else if (hObj.id == 7) // Coral  front
        {
            texColor += float3(1.32, 0.35, .15);
        }
        else if (hObj.id == 5) // Plant
        {
            texColor += float3(0.0, 0.2, 0.0);
        }
        else if (hObj.id == 8) // Plant
        {
            texColor += float3(0.0, 0.2, 0.0);
        }
            
        texColor += smoothstep(0.0, 1.0, (1.0 - Caustics(p * 0.5)) * 0.4); // Caustics
        texColor *= 0.4 + 0.6 * GodRays(p, l); // God light
        texColor *= AmbientOcclusion(p, n); // Ambient occlusion
            
        float3 lightDir = normalize(l - p);
        float s1 = max(0.0, SceneSDF(p + lightDir * 0.25).x / 0.25);
        float s2 = max(0.0, SceneSDF(p + lightDir).x);
        texColor *= clamp((s1 + s2) * 0.5, 0.0, 1.0); // Shadows
    }
    
    return texColor;
}
/**
 * Phong Illumination:
 * Based on https://www.shadertoy.com/view/lt33z7
 */  

/**
 * Lighting contribution of a single point light source via Phong illumination.
 * 
 * The float3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
float3 PhongContribForLight(float3 k_d, float3 k_s, float alpha, float3 p, float3 eye, float3 lightPos, float3 lightIntensity)
{
    float3 N = EstimateNormal(p);
    float3 L = normalize(lightPos - p);
    float3 V = normalize(eye - p);
    float3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0)
    {
        // Light not visible from this point on the surface
        return float3(0.0, 0.0, 0.0);
    }
    
    if (dotRV < 0.0)
    {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}
/**
 * Lighting via Phong illumination.
 * 
 * The float3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
float3 PhongIllumination(float3 k_a, float3 k_d, float3 k_s, float alpha, float3 p, float3 eye)
{
    const float3 ambientLight = 0.5 * float3(0.1, 0.1, 0.1);
    float3 color = ambientLight * k_a;
    float3 lightPos = float3(-1.0, 10.0, 1.0); // Refactor from buffer
    float3 lightIntensity = float3(0.1, 0.1, 0.1);
    color += PhongContribForLight(k_d, k_s, alpha, p, eye, lightPos, lightIntensity);
    return color;
}

/* Render Scene and Postprocessing */
void Render(Ray ray, out float4 fragColor, in float2 fragCoord)
{
    HitObject hObj = RayMarching(ray, MIN_DIST, MAX_DIST);
    float3 lightPos = float3(-1.0, 10.0, 1.0);
 
    float3 pixelColor = waterColor;
    
    float3 p = ray.o + hObj.d * ray.d;
    if (hObj.id > 0)
    {
        float3 n = EstimateNormal(p);
        float3 texColor = Shading(hObj, n, p, lightPos);
        
        // Lighting
        float shininess = 10.0;
        float3 K_a = float3(0.1, 0.1, 0.1);
        float3 K_d = float3(0.2, 0.2, 0.2);
        float3 K_s = float3(0.2, 0.2, 0.2);
        pixelColor = PhongIllumination(K_a, K_d, K_s, shininess, p, hObj.d) + texColor; // review //hObj.d -> ray.o or ray.d
    }
    
    // Post processing
    
    // Fog
    float fog = clamp(pow(hObj.d / MAX_DIST * waterDepth, 1.5), 0.0, 1.0);
    pixelColor = lerp(pixelColor, waterColor, fog);
        
    // God rays
    pixelColor = lerp(pixelColor, float3(0.15, 0.25, 0.3) * 12.0, CastLightBeam(ray.o, ray.d, lightPos, hObj.d));
    
    // Gamma correction
    pixelColor = pow(pixelColor, float3(0.4545, 0.4545, 0.4545));
    
    fragColor = float4(pixelColor, 1.0);
}

float4 main(PS_INPUT input) : SV_Target
{
    // Specify primary ray 
    Ray ray;

    // Set eye position
    ray.o = float3(-2.0, -1.8, 5.0);

    // Set ray direction in view space 
    float dist2Imageplane = 1.0;
    float3 viewDir = float3(input.canvasXY, -dist2Imageplane);
    viewDir = normalize(viewDir);

    // Transform viewDir using the inverse view matrix
    float4x4 viewTrans = transpose(view);
    ray.d = viewDir.x * viewTrans._11_12_13 + viewDir.y * viewTrans._21_22_23 
        + viewDir.z * viewTrans._31_32_33;
    
    float4 fragColor;
    
    // Render
    Render(ray, fragColor, input.pos.xy);

    return fragColor;
}
