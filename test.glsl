#version 330 core

out vec4 FragColor;

in vec2 TexCoords;
in vec3 Normal;
in vec3 FragPos;

uniform vec3 viewPos;
uniform sampler2D texture1;
uniform sampler2D scratchTexture;
uniform sampler2D dirtTexture;
uniform vec3 lightPos;
uniform vec3 lightColor;

float CalculateAmbientLight(float ambientStrength)
{
    return ambientStrength;
}

float CalculateDiffuseLight(vec3 normal, vec3 lightDir)
{
    float diff = max(dot(normal, lightDir), 0.0);
    return diff;
}

float CalculateSpecularLight(vec3 viewDir, vec3 lightDir, vec3 normal, float shininess)
{
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    return spec;
}

void main()
{
    vec3 ambientColor = vec3(0.1, 0.1, 0.1);
    vec3 diffuseColor = vec3(0.7, 0.7, 0.7);
    vec3 specularColor = vec3(1.0, 1.0, 1.0);
    float shininess = 32.0;

    vec3 lightDir = normalize(lightPos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 norm = normalize(Normal);

    float ambient = CalculateAmbientLight(ambientColor.r);
    float diff = CalculateDiffuseLight(norm, lightDir) * diffuseColor.r;
    float spec = CalculateSpecularLight(viewDir, lightDir, norm, shininess) * specularColor.r;

    vec3 lighting = (ambient + diff + spec) * lightColor;

    vec4 baseTexture = texture(texture1, TexCoords);
    vec4 scratchTextureColor = texture(scratchTexture, TexCoords);
    vec4 dirtTextureColor = texture(dirtTexture, TexCoords);

    vec4 finalColor = baseTexture * vec4(lighting, 1.0) + scratchTextureColor * 0.2 + dirtTextureColor * 0.3;
    FragColor = vec4(finalColor.rgb, 1.0);
}
