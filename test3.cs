using System;
using System.Numerics;

public enum CameraMode
{
    Follow,
    Static,
    Cinematic
}

public class Camera
{
    public Vector2 Position { get; private set; }
    public float Rotation { get; private set; }
    public float Zoom { get; private set; }
    public CameraMode Mode { get; private set; }

    private Vector2 targetPosition;
    private float targetRotation;
    private float targetZoom;

    private float shakeIntensity;
    private float shakeDuration;
    private float shakeTime;

    private Vector2 boundariesMin;
    private Vector2 boundariesMax;

    public Camera(Vector2 initialPosition, Vector2 minBoundaries, Vector2 maxBoundaries)
    {
        Position = initialPosition;
        Rotation = 0f;
        Zoom = 1f;
        Mode = CameraMode.Follow;
        boundariesMin = minBoundaries;
        boundariesMax = maxBoundaries;
        targetPosition = initialPosition;
        targetRotation = 0f;
        targetZoom = 1f;
        shakeIntensity = 0f;
        shakeDuration = 0f;
        shakeTime = 0f;
    }

    public void Update(float deltaTime, Vector2 inputDirection, float rotationInput, float zoomInput)
    {
        if (Mode == CameraMode.Follow)
        {
            targetPosition += inputDirection * 300f * deltaTime;
            targetRotation += rotationInput * 0.1f * deltaTime;
            targetZoom += zoomInput * 0.1f * deltaTime;

            ClampPosition();
        }

        ApplyShake(deltaTime);

        Position = Vector2.Lerp(Position, targetPosition + GetShakeOffset(), 0.1f);
        Rotation = MathHelper.LerpAngle(Rotation, targetRotation, 0.1f);
        Zoom = MathHelper.Lerp(Zoom, targetZoom, 0.1f);
    }

    public void SetShake(float intensity, float duration)
    {
        shakeIntensity = intensity;
        shakeDuration = duration;
        shakeTime = 0f;
    }

    public Matrix4x4 GetViewMatrix()
    {
        Matrix4x4 translation = Matrix4x4.CreateTranslation(new Vector3(-Position, 0));
        Matrix4x4 rotation = Matrix4x4.CreateRotationZ(Rotation);
        Matrix4x4 zoom = Matrix4x4.CreateScale(new Vector3(Zoom, Zoom, 1));
        return zoom * rotation * translation;
    }

    private void ClampPosition()
    {
        targetPosition.X = Math.Clamp(targetPosition.X, boundariesMin.X, boundariesMax.X);
        targetPosition.Y = Math.Clamp(targetPosition.Y, boundariesMin.Y, boundariesMax.Y);
    }

    private Vector2 GetShakeOffset()
    {
        if (shakeTime < shakeDuration)
        {
            shakeTime += (float)0.016; // Assuming a fixed update rate
            float offsetX = (float)((shakeIntensity * 2) * (new Random().NextDouble() - 0.5));
            float offsetY = (float)((shakeIntensity * 2) * (new Random().NextDouble() - 0.5));
            return new Vector2(offsetX, offsetY);
        }
        return Vector2.Zero;
    }

    private void ApplyShake(float deltaTime)
    {
        if (shakeTime >= shakeDuration) return;
        shakeIntensity -= (float)(shakeDuration * 0.1);
        if (shakeIntensity < 0) shakeIntensity = 0;
    }
}

public static class MathHelper
{
    public static float Lerp(float start, float end, float t)
    {
        return start + (end - start) * t;
    }

    public static float LerpAngle(float start, float end, float t)
    {
        float delta = end - start;
        while (delta > MathF.PI) delta -= MathF.PI * 2;
        while (delta < -MathF.PI) delta += MathF.PI * 2;
        return start + delta * t;
    }
}

public class Game
{
    private Camera camera;

    public Game()
    {
        camera = new Camera(new Vector2(0, 0), new Vector2(-100, -100), new Vector2(100, 100));
    }

    public void Update(float deltaTime, Vector2 inputDirection, float rotationInput, float zoomInput)
    {
        camera.Update(deltaTime, inputDirection, rotationInput, zoomInput);
        if (SomeConditionForShake()) camera.SetShake(5f, 0.5f);
        Render();
    }

    private bool SomeConditionForShake()
    {
        return new Random().NextDouble() < 0.1; // Random shake condition
    }

    private void Render()
    {
        Matrix4x4 viewMatrix = camera.GetViewMatrix();
        Console.WriteLine($"Camera Position: {camera.Position}, Rotation: {camera.Rotation}, Zoom: {camera.Zoom}");
        Console.WriteLine($"View Matrix: {viewMatrix}");
    }
}

class Program
{
    static void Main(string[] args)
    {
        Game game = new Game();
        float deltaTime = 0.016f;
        Vector2 inputDirection = new Vector2(1, 0);
        float rotationInput = 0.1f;
        float zoomInput = -0.05f;

        for (int i = 0; i < 60; i++)
        {
            game.Update(deltaTime, inputDirection, rotationInput, zoomInput);
            inputDirection = Vector2.Zero;
            rotationInput = 0f;
            zoomInput = 0f;
        }
    }
}
