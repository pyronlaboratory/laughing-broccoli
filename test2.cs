using System;
using System.Numerics;

public class Camera
{
    public Vector2 Position { get; private set; }
    public float Rotation { get; private set; }
    public float Zoom { get; private set; }
    public float Speed { get; set; }
    public float RotationSpeed { get; set; }
    public float ZoomSpeed { get; set; }
    
    private Vector2 targetPosition;
    private float targetRotation;
    private float targetZoom;

    public Camera(Vector2 initialPosition)
    {
        Position = initialPosition;
        Rotation = 0f;
        Zoom = 1f;
        Speed = 300f;
        RotationSpeed = 0.1f;
        ZoomSpeed = 0.1f;
        targetPosition = initialPosition;
        targetRotation = 0f;
        targetZoom = 1f;
    }

    public void Update(float deltaTime, Vector2 inputDirection, float rotationInput, float zoomInput)
    {
        targetPosition += inputDirection * Speed * deltaTime;
        targetRotation += rotationInput * RotationSpeed * deltaTime;
        targetZoom += zoomInput * ZoomSpeed * deltaTime;

        Position = Vector2.Lerp(Position, targetPosition, 0.1f);
        Rotation = MathHelper.LerpAngle(Rotation, targetRotation, 0.1f);
        Zoom = MathHelper.Lerp(Zoom, targetZoom, 0.1f);
    }

    public Matrix4x4 GetViewMatrix()
    {
        Matrix4x4 translation = Matrix4x4.CreateTranslation(new Vector3(-Position, 0));
        Matrix4x4 rotation = Matrix4x4.CreateRotationZ(Rotation);
        Matrix4x4 zoom = Matrix4x4.CreateScale(new Vector3(Zoom, Zoom, 1));

        return zoom * rotation * translation;
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
        camera = new Camera(new Vector2(0, 0));
    }

    public void Update(float deltaTime, Vector2 inputDirection, float rotationInput, float zoomInput)
    {
        camera.Update(deltaTime, inputDirection, rotationInput, zoomInput);
        Render();
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
