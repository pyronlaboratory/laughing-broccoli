using System;
using System.Collections.Generic;

public enum GameObjectType
{
    Player,
    Enemy,
    Item,
    Obstacle
}

public abstract class GameObject
{
    public string Name { get; private set; }
    public GameObjectType Type { get; private set; }
    public bool IsActive { get; set; }

    protected GameObject(string name, GameObjectType type)
    {
        Name = name;
        Type = type;
        IsActive = true;
    }

    public abstract void Update(float deltaTime);
    
    public virtual void Render()
    {
        Console.WriteLine($"{Name} is being rendered.");
    }
}

public class TransformComponent
{
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public float Rotation { get; set; }

    public TransformComponent(float x, float y)
    {
        PositionX = x;
        PositionY = y;
        Rotation = 0f;
    }

    public void Translate(float deltaX, float deltaY)
    {
        PositionX += deltaX;
        PositionY += deltaY;
    }
}

public class Player : GameObject
{
    private TransformComponent transform;

    public Player(string name, float startX, float startY) : base(name, GameObjectType.Player)
    {
        transform = new TransformComponent(startX, startY);
    }

    public override void Update(float deltaTime)
    {
        Console.WriteLine($"{Name} is updating its position.");
        transform.Translate(1.0f * deltaTime, 0f);
    }

    public override void Render()
    {
        base.Render();
        Console.WriteLine($"Player Position: ({transform.PositionX}, {transform.PositionY})");
    }
}

public class Enemy : GameObject
{
    private TransformComponent transform;

    public Enemy(string name, float startX, float startY) : base(name, GameObjectType.Enemy)
    {
        transform = new TransformComponent(startX, startY);
    }

    public override void Update(float deltaTime)
    {
        Console.WriteLine($"{Name} is updating its position.");
        transform.Translate(-0.5f * deltaTime, 0f);
    }

    public override void Render()
    {
        base.Render();
        Console.WriteLine($"Enemy Position: ({transform.PositionX}, {transform.PositionY})");
    }
}

public class GameObjectManager
{
    private List<GameObject> gameObjects;

    public GameObjectManager()
    {
        gameObjects = new List<GameObject>();
    }

    public void AddGameObject(GameObject gameObject)
    {
        gameObjects.Add(gameObject);
        Console.WriteLine($"{gameObject.Name} has been added to the game.");
    }

    public void UpdateAll(float deltaTime)
    {
        foreach (var gameObject in gameObjects)
        {
            if (gameObject.IsActive)
            {
                gameObject.Update(deltaTime);
            }
        }
    }

    public void RenderAll()
    {
        foreach (var gameObject in gameObjects)
        {
            if (gameObject.IsActive)
            {
                gameObject.Render();
            }
        }
    }
}

class Program
{
    static void Main(string[] args)
    {
        GameObjectManager manager = new GameObjectManager();

        Player player = new Player("Hero", 0f, 0f);
        Enemy enemy = new Enemy("Goblin", 10f, 0f);

        manager.AddGameObject(player);
        manager.AddGameObject(enemy);

        float deltaTime = 0.016f;
        for (int i = 0; i < 60; i++)
        {
            manager.UpdateAll(deltaTime);
            manager.RenderAll();
        }
    }
}
