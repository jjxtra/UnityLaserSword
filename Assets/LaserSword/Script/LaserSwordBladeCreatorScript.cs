// LaserSword for Unity
// (c) 2016 Digital Ruby, LLC
// http://www.digitalruby.com

using UnityEngine;
using System.Collections.Generic;

namespace DigitalRuby.LaserSword
{
    [ExecuteInEditMode]
    public class LaserSwordBladeCreatorScript : MonoBehaviour
    {
        public MeshFilter MeshFilter;

        [Tooltip("The length of the blade.")]
        [Range(0.1f, 16.0f)]
        public float BladeHeight = 2.73f;
        
        [Tooltip("The bottom radius.")]
        [Range(0.01f, 4.0f)]
        public float BottomRadius = 0.05f;

        [Tooltip("The top radius.")]
        [Range(0.0f, 4.0f)]
        public float TopRadius = 0.04f;

        [Tooltip("What percent of the blade is the tip?")]
        [Range(0.0f, 1.0f)]
        public float BladeTipPercent = 0.025f;

        [Tooltip("What percent of the TopRadius should the end of the tip radius be? 0 for a single point.")]
        [Range(0.0f, 4.0f)]
        public float BladeTipRadiusPercent = 0.0f;

        [Range(4, 64)]
        public int NumberOfSides = 32;

        private const int numberOfHeightSegments = 1;
        private const float twoPI = Mathf.PI * 2f;

#if UNITY_EDITOR

        [Tooltip("Click to generate mesh asset")]
        public bool CreateMeshAsset;

        private Vector3[] CreateVertices()
        {
            int capVerticesCount = NumberOfSides + 1;

            // bottom + top + sides
            Vector3[] vertices = new Vector3[capVerticesCount + capVerticesCount + NumberOfSides * numberOfHeightSegments * 2 + 2];
            int vert = 0;

            // Bottom cap
            vertices[vert++] = new Vector3(0f, 0f, 0f);
            while (vert <= NumberOfSides)
            {
                float rad = (float)vert / NumberOfSides * twoPI;
                vertices[vert] = new Vector3(Mathf.Cos(rad) * BottomRadius, 0f, Mathf.Sin(rad) * BottomRadius);
                vert++;
            }

            // Top cap
            vertices[vert++] = new Vector3(0f, BladeHeight, 0f);
            while (vert <= NumberOfSides * 2 + 1)
            {
                float rad = (float)(vert - NumberOfSides - 1) / NumberOfSides * twoPI;
                vertices[vert] = new Vector3(Mathf.Cos(rad) * TopRadius, BladeHeight, Mathf.Sin(rad) * TopRadius);
                vert++;
            }

            // Sides
            int v = 0;
            while (vert <= vertices.Length - 4)
            {
                float rad = (float)v / NumberOfSides * twoPI;
                vertices[vert] = new Vector3(Mathf.Cos(rad) * TopRadius, BladeHeight, Mathf.Sin(rad) * TopRadius);
                vertices[vert + 1] = new Vector3(Mathf.Cos(rad) * BottomRadius, 0, Mathf.Sin(rad) * BottomRadius);
                vert += 2;
                v++;
            }
            vertices[vert] = vertices[NumberOfSides * 2 + 2];
            vertices[vert + 1] = vertices[NumberOfSides * 2 + 3];

            return vertices;
        }

        private Vector3[] CreateNormals(Vector3[] vertices)
        {
            // bottom + top + sides
            Vector3[] normals = new Vector3[vertices.Length];
            int vert = 0;

            // Bottom cap
            while (vert <= NumberOfSides)
            {
                normals[vert++] = Vector3.down;
            }

            // Top cap
            while (vert <= NumberOfSides * 2 + 1)
            {
                normals[vert++] = Vector3.up;
            }

            // Sides
            int v = 0;
            while (vert <= vertices.Length - 4)
            {
                float rad = (float)v / (float)NumberOfSides * twoPI;
                float cos = Mathf.Cos(rad);
                float sin = Mathf.Sin(rad);

                normals[vert] = new Vector3(cos, 0f, sin);
                normals[vert + 1] = normals[vert];

                vert += 2;
                v++;
            }
            normals[vert] = normals[NumberOfSides * 2 + 2];
            normals[vert + 1] = normals[NumberOfSides * 2 + 3];

            return normals;
        }

        private Vector2[] CreateUVs(Vector3[] vertices)
        {
            Vector2[] uvs = new Vector2[vertices.Length];

            // Bottom cap
            int u = 0;
            uvs[u++] = new Vector2(0.5f, 0.5f);
            while (u <= NumberOfSides)
            {
                float rad = (float)u / NumberOfSides * twoPI;
                uvs[u] = new Vector2(Mathf.Cos(rad) * .5f + .5f, Mathf.Sin(rad) * .5f + .5f);
                u++;
            }

            // Top cap
            uvs[u++] = new Vector2(0.5f, 0.5f);
            while (u <= NumberOfSides * 2 + 1)
            {
                float rad = (float)u / NumberOfSides * twoPI;
                uvs[u] = new Vector2(Mathf.Cos(rad) * .5f + .5f, Mathf.Sin(rad) * .5f + .5f);
                u++;
            }

            // Sides
            int u_sides = 0;
            while (u <= uvs.Length - 4)
            {
                float t = (float)u_sides / NumberOfSides;
                uvs[u] = new Vector3(t, 1f);
                uvs[u + 1] = new Vector3(t, 0f);
                u += 2;
                u_sides++;
            }
            uvs[u] = new Vector2(1f, 1f);
            uvs[u + 1] = new Vector2(1f, 0f);

            return uvs;
        }

        private List<int> CreateTriangles(bool bottom, bool top)
        {
            int capVerticesCount = NumberOfSides + 1;
            int nbTriangles = NumberOfSides + NumberOfSides + NumberOfSides * 2;
            List<int> triangles = new List<int>(nbTriangles * 3 + 3);

            // Bottom cap
            int tri = 0;
            if (bottom)
            {
                while (tri < NumberOfSides - 1)
                {
                    triangles.Add(0);
                    triangles.Add(tri + 1);
                    triangles.Add(tri + 2);
                    tri++;
                }

                triangles.Add(0);
                triangles.Add(tri + 1);
                triangles.Add(1);
                tri++;
            }

            if (top)
            {
                // Top cap
                //tri++;
                while (tri < NumberOfSides * 2)
                {
                    triangles.Add(tri + 2);
                    triangles.Add(tri + 1);
                    triangles.Add(capVerticesCount);
                    tri++;
                }

                triangles.Add(capVerticesCount + 1);
                triangles.Add(tri + 1);
                triangles.Add(capVerticesCount);
                tri++;
                tri++;
            }

            // Sides
            while (tri <= nbTriangles)
            {
                triangles.Add(tri + 2);
                triangles.Add(tri + 1);
                triangles.Add(tri);
                tri++;

                triangles.Add(tri + 1);
                triangles.Add(tri + 2);
                triangles.Add(tri);
                tri++;
            }

            return triangles;
        }

        private Mesh CreateBladeBody()
        {
            float bladeHeight = BladeHeight;
            BladeHeight *= 1.0f - BladeTipPercent;
            Mesh mesh = new Mesh();
            mesh.name = "LaserSwordMeshBladeBody";
            Vector3[] vertices = CreateVertices();
            Vector3[] normals = CreateNormals(vertices);
            Vector2[] uvs = CreateUVs(vertices);
            List<int> triangles = CreateTriangles(true, false);
            mesh.vertices = vertices;
            mesh.normals = normals;
            mesh.uv = uvs;
            mesh.SetTriangles(triangles, 0);
            mesh.RecalculateBounds();
            BladeHeight = bladeHeight;

            return mesh;
        }

        private Mesh CreateBladeTip()
        {
            float bladeHeight = BladeHeight;
            float bottomRadius = BottomRadius;
            float topRadius = TopRadius;

            BladeHeight = BladeHeight * BladeTipPercent;
            BottomRadius = TopRadius;
            TopRadius *= BladeTipRadiusPercent;

            Mesh mesh = new Mesh();
            mesh.name = "LaserSwordMeshBladeTip";
            Vector3[] vertices = CreateVertices();
            Vector3[] normals = CreateNormals(vertices);
            Vector2[] uvs = CreateUVs(vertices);
            List<int> triangles = CreateTriangles(false, true);
            mesh.vertices = vertices;
            mesh.normals = normals;
            mesh.uv = uvs;
            mesh.SetTriangles(triangles, 0);
            mesh.RecalculateBounds();

            BladeHeight = bladeHeight;
            BottomRadius = bottomRadius;
            TopRadius = topRadius;

            return mesh;
        }

        private void RecreateBlade()
        {
            Mesh mesh = MeshFilter.sharedMesh;
            if (mesh != null)
            {
                GameObject.DestroyImmediate(mesh, true);
            }
            Mesh bladeBody = CreateBladeBody();
            Mesh bladeTip = CreateBladeTip();
            Mesh bladeMesh = new Mesh();
            bladeMesh.name = "LigthsabreMesh";
            {
                CombineInstance c1 = new CombineInstance();
                c1.mesh = bladeBody;
                c1.transform = Matrix4x4.identity;
                CombineInstance c2 = new CombineInstance();
                c2.mesh = bladeTip;
                c2.transform = Matrix4x4.TRS(new Vector3(0.0f, BladeHeight - (BladeHeight * BladeTipPercent), 0.0f), Quaternion.identity, Vector3.one);
                bladeMesh.CombineMeshes(new CombineInstance[] { c1, c2 }, true, true);
                bladeMesh.RecalculateBounds();
            }
            {
                MeshCollider c = MeshFilter.gameObject.GetComponent<MeshCollider>();
                if (c != null)
                {
                    c.sharedMesh = bladeMesh;
                }
                MeshFilter.sharedMesh = bladeMesh;
            }

            if (CreateMeshAsset)
            {
                CreateMeshAsset = false;
                string filePath = "Assets/LaserSwordMesh.mesh";
                UnityEditor.AssetDatabase.CreateAsset(Instantiate(bladeMesh), filePath);
            }
        }

        private void Start()
        {

        }

        private void Update()
        {
            RecreateBlade();
        }

#endif

    }
}