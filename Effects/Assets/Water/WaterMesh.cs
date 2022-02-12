using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class Wave
{
    public float m_phase; //相位
    public float m_amp;   //振幅
    public float m_length;//波长
    public float m_freq;  //频率
    public Vector2 m_dir; //方向
    public float m_totalTime;  //总时间
    public float m_elapseTime;  //流逝时间
};

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class WaterMesh : MonoBehaviour
{
    [Range(0,20)]
    public int m_gridSize = 10;
    public float m_scale = 1.0f;

    //参数,波长
    public Vector2 m_wind; //风速
    public float m_ampMax; //振幅最大值
    public float m_lengthInit;
    public float m_lengthDelt;
    public float m_fadeSpeed; //衰减速度,是负数
    public float m_passTime; //流逝的时间
    
    //过程变量
    private Wave[] m_waves;
    private int m_updateCount;

    private Mesh m_mesh;
    private Material m_material;
    private Vector3[] m_vertices;
    private Vector2[] m_uv;
    private Vector4[] m_tangents;
    private int m_verticesCount = 0;

    // Start is called before the first frame update
    void Start()
    {
        m_mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = m_mesh;
        m_mesh.name = "Custom Water Mesh";

        CreateMesh();

        m_waves = new Wave[4];
        for(int i = 0; i < 4; ++i)
        {
            CreateWave(i);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if( IsVerticesCountChanged() )
        {
            CreateMesh();

            for(int i = 0; i < 4; ++i)
            {
                CreateWave(i);
            }
        }
        // else
        // {
        //     float dt = 0;
        //     for(int i = 0; i < 4; ++i)
        //     {
        //         UpdateWave(i, dt); //生成t时刻的函数.
        //     }
        // }

        SendParamsToShader();
    }

    void UpdateMeshVertices()
    {
        int xSize = m_gridSize;
        int ySize = m_gridSize;
        Vector4 tangent = new Vector4(1f, 0f, 0f, -1f);
        for (int i = 0,y = 0; y <= ySize; y++) {
			for (int x = 0; x <= xSize; x++, i++) {
                Vector2 p = new Vector2((float)x/xSize, (float)y/ySize);
                float xx = -m_scale + p.x * 2.0f*m_scale;
                float yy = -m_scale + p.y * 2.0f*m_scale;
                // float amp = CalculateAmp(xx, yy);
				m_vertices[i] = new Vector3(xx,0,yy);
            }
		}
        m_mesh.vertices = m_vertices;
    }

    void UpdateWave(int i, float dt)
    {
        Wave w = m_waves[i];
        w.m_elapseTime += dt;
        if(w.m_elapseTime > w.m_totalTime)
        {
            w.m_elapseTime -= w.m_totalTime;
        }
        float p = w.m_elapseTime/w.m_totalTime;
        if(p > 0.5)
        {
            p = 1 - p;
        }
        p *= 2;
        
        float speed = 1.0f/Mathf.Sqrt(w.m_length);
        w.m_phase += speed*dt;
        w.m_phase = Mathf.PingPong(w.m_phase, 2.0f*3.14f);        
        w.m_amp = w.m_length * m_ampMax * p;
    }

    void CreateWave(int i)
    {
        Wave w = new Wave();
        w.m_phase = Random01() * 3.14f * 2.0f;
        w.m_length = m_lengthInit + Random01() * m_lengthDelt; //波长
        w.m_amp = w.m_length * m_ampMax; //假设正比于波长和风的强度
        w.m_freq = 3.14f * 2.0f / w.m_length; //频率
        w.m_dir = m_wind.normalized; //风的方向
        w.m_totalTime = 2;
        w.m_elapseTime = 0;

        //该风方向上的偏移
        float angle = 15.0f * 3.14f / 180.0f * (Random01()*2.0f - 1.0f);
        float sinX = Mathf.Sin(angle);
        float cosX = Mathf.Cos(angle);
        float x = w.m_dir.x;
        float y = w.m_dir.y;

        w.m_dir.x = x*cosX + y*sinX;
        w.m_dir.y = x*(-sinX) + y*cosX;
        m_waves[i] = w;
    }

    void SendParamsToShader()
    {
        m_material = GetComponent<MeshRenderer>().material;

        Vector4 amp = new Vector4(m_waves[0].m_amp, m_waves[1].m_amp, m_waves[2].m_amp, m_waves[3].m_amp);
        Vector4 freq = new Vector4(m_waves[0].m_freq, m_waves[1].m_freq, m_waves[2].m_freq, m_waves[3].m_freq);
        Vector4 length = new Vector4(m_waves[0].m_length, m_waves[1].m_length, m_waves[2].m_length, m_waves[3].m_length);
        Vector4 phase = new Vector4(m_waves[0].m_phase, m_waves[1].m_phase, m_waves[2].m_phase, m_waves[3].m_phase);
        Vector4 dirX = new Vector4(m_waves[0].m_dir.x, m_waves[1].m_dir.x, m_waves[2].m_dir.x, m_waves[3].m_dir.x);
        Vector4 dirY = new Vector4(m_waves[0].m_dir.y, m_waves[1].m_dir.y, m_waves[2].m_dir.y, m_waves[3].m_dir.y);

        // Debug.Log(amp);
        // Debug.Log(m_ampMax);
        // y = A * sin( 2*pi/l * (x-v*t) )

        m_material.SetVector("_Amp", amp);
        m_material.SetVector("_Freq", freq);
        m_material.SetVector("_Length", length);
        m_material.SetVector("_Phase", phase);
        m_material.SetVector("_DirX", dirX);
        m_material.SetVector("_DirY", dirY);
    }
    
    bool IsVerticesCountChanged()
    {
        if( m_verticesCount == (m_gridSize+1)*(m_gridSize+1) )
        {
            return false;
        }

        return true;
    }

    void CreateMesh()
    {
        m_verticesCount = (m_gridSize+1)*(m_gridSize+1);
        m_vertices = new Vector3[m_verticesCount];
        m_uv = new Vector2[m_verticesCount];
        m_tangents = new Vector4[m_verticesCount];

        SetMeshVerticesAndUv();
        SetMeshTriangles();
        SetMeshNormal();
    }

    void SetMeshVerticesAndUv()
    {
        int xSize = m_gridSize;
        int ySize = m_gridSize;
        Vector4 tangent = new Vector4(1f, 0f, 0f, -1f);
        for (int i = 0,y = 0; y <= ySize; y++) {
			for (int x = 0; x <= xSize; x++, i++) {
                Vector2 p = new Vector2((float)x/xSize, (float)y/ySize);
                float xx = -m_scale + p.x * 2.0f*m_scale;
                float yy = -m_scale + p.y * 2.0f*m_scale;
				m_vertices[i] = new Vector3(xx,0,yy);
                // uv[i] = p;
                m_tangents[i] = tangent;
                m_uv[i] = new Vector2(x, y);
            }
		}

        m_mesh.vertices = m_vertices;
        m_mesh.uv = m_uv;
        m_mesh.tangents = m_tangents;
    }

    void SetMeshTriangles()
    {
        int xSize = m_gridSize;
        int ySize = m_gridSize;
        int[] triangles = new int[xSize*ySize*6];
        int k = 0;
        for (int j = 0; j < ySize; j++)
        {
            for (int i = 0; i < xSize; i++)
            {
                triangles[k] = j*(xSize + 1) + i;
                triangles[k+1] = (j+1)*(xSize + 1) + i;
                triangles[k+2] = j*(xSize + 1) + i + 1;
                k += 3;

                triangles[k] = j*(xSize + 1) + i + 1;
                triangles[k+1] = (j+1)*(xSize + 1) + i;
                triangles[k+2] = (j+1)*(xSize + 1) + i + 1;
                k += 3;
            }
        }

		m_mesh.triangles = triangles;
        m_mesh.RecalculateNormals();        
    }

    void SetMeshNormal()
    {
        Vector3[] normals = new Vector3[m_verticesCount];
        for (int i = 0; i < normals.Length; i++)
        {
            normals[i] = new Vector3(0, 0, -1);
        }

        m_mesh.normals = normals;
    }

    float Random01()
    {
        int v = Random.Range(0,1000);
        float f = 1.0f*v/1000.0f; 
        return f;
    }
}
