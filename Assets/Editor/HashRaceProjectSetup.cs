using System.IO;
using HashRace;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class HashRaceProjectSetup
{
    private const string SceneFolder = "Assets/Scenes";
    private const string MainScenePath = "Assets/Scenes/Main.unity";

    [InitializeOnLoadMethod]
    private static void Initialize()
    {
        EditorApplication.delayCall += EnsureProjectIsReady;
    }

    [MenuItem("Hash Race/Repair First Playable Setup")]
    public static void EnsureProjectIsReady()
    {
        PlayerSettings.productName = "Hash Race";
        PlayerSettings.companyName = "1freetech";
        PlayerSettings.defaultScreenWidth = 1280;
        PlayerSettings.defaultScreenHeight = 720;
        PlayerSettings.defaultIsNativeResolution = false;
        PlayerSettings.resizableWindow = true;

        if (!AssetDatabase.IsValidFolder(SceneFolder))
        {
            AssetDatabase.CreateFolder("Assets", "Scenes");
        }

        if (!File.Exists(MainScenePath))
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            GameObject cameraObject = new GameObject("Main Camera");
            Camera camera = cameraObject.AddComponent<Camera>();
            camera.orthographic = true;
            camera.backgroundColor = new Color(0.035f, 0.045f, 0.055f, 1f);
            cameraObject.tag = "MainCamera";

            GameObject game = new GameObject("Hash Race Game");
            game.AddComponent<HashRaceGame>();

            EditorSceneManager.SaveScene(scene, MainScenePath);
        }

        EditorBuildSettings.scenes = new[]
        {
            new EditorBuildSettingsScene(MainScenePath, true)
        };

        AssetDatabase.SaveAssets();
    }
}
